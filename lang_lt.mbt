// lang_lt.mbt — Lithuanian number spelling (cardinal, year, currency).
//
// Faithful port of upstream num2words 0.5.14 `lang_LT.py`:
//   * cardinal: 3-digit groups, high to low, space-separated;
//   * the hundred noun agrees in number: 1 -> "šimtas", 2..9 -> "šimtai"
//     ("du šimtai", "devyni šimtai");
//   * feminine units are used for a sub-thousand value when the caller asks
//     for feminine agreement (Lithuanian currency cents in RUB take
//     "viena kapeika" / "dvi kapeikos"); ordinary cardinals are masculine;
//   * the scale word inflects by the group value: ...1 -> "tūkstantis"/
//     "milijonas"; ...2..9 -> "tūkstančiai"/"milijonai"; 0 and 10..19 ->
//     "tūkstančių"/"milijonų".
//
// Upstream has no `to_ordinal` (raises NotImplementedError), so `ordinal_lt`
// returns "". `to_ordinal_num` falls through to the integer itself, and
// `to_year` is the plain cardinal.

///|
/// Feminine units (used for RUB cents).
let lt_ones_feminine : Array[String] = [
  "nulis", "viena", "dvi", "trys", "keturios", "penkios", "šešios", "septynios",
  "aštuonios", "devynios",
]

///|
/// Tens 20..90 (index = tens digit). Index 1 is unused: teens come from
/// `Lang.teens`.
let lt_twenties : Array[String] = [
  "", "", "dvidešimt", "trisdešimt", "keturiasdešimt", "penkiasdešimt", "šešiasdešimt",
  "septyniasdešimt", "aštuoniasdešimt", "devyniasdešimt",
]

///|
/// Scale words, form 0 (one): index = power of 1000.
let lt_thousands_one : Array[String] = [
  "", "tūkstantis", "milijonas", "milijardas", "trilijonas", "kvadrilijonas", "kvintilijonas",
  "sikstilijonas", "septilijonas", "oktilijonas", "naintilijonas",
]

///|
/// Scale words, form 1 (2..9).
let lt_thousands_few : Array[String] = [
  "", "tūkstančiai", "milijonai", "milijardai", "trilijonai", "kvadrilijonai",
  "kvintilijonai", "sikstilijonai", "septilijonai", "oktilijonai", "naintilijonai",
]

///|
/// Scale words, form 2 (0 and 10..19).
let lt_thousands_many : Array[String] = [
  "", "tūkstančių", "milijonų", "milijardų", "trilijonų", "kvadrilijonų",
  "kvintilijonų", "sikstilijonų", "septilijonų", "oktilijonų", "naintilijonų",
]

///|
/// Upstream `pluralize` reads only the last two digits of `n`:
/// 0 or 10..19 -> many, ...1 -> one, everything else -> few.
fn lt_form(n : Int) -> Int {
  let n1 = n % 10
  let n2 = n / 10 % 10
  if n2 == 1 || n1 == 0 || n == 0 {
    return 2
  }
  if n1 == 1 {
    return 0
  }
  1
}

///|
fn lt_scale(power : Int, form : Int) -> String {
  if form == 0 {
    lt_thousands_one[power]
  } else if form == 1 {
    lt_thousands_few[power]
  } else {
    lt_thousands_many[power]
  }
}

///|
pub fn lang_lt() -> Lang {
  {
    variant: Lt,
    zero: "nulis",
    ones: [
      "nulis", "vienas", "du", "trys", "keturi", "penki", "šeši", "septyni", "aštuoni",
      "devyni",
    ],
    teens: [
      "dešimt", "vienuolika", "dvylika", "trylika", "keturiolika", "penkiolika",
      "šešiolika", "septyniolika", "aštuoniolika", "devyniolika",
    ],
    tens: [
      "", "dešimt", "dvidešimt", "trisdešimt", "keturiasdešimt", "penkiasdešimt",
      "šešiasdešimt", "septyniasdešimt", "aštuoniasdešimt", "devyniasdešimt",
    ],
    hundred: "šimtas",
    thousands: lt_thousands_one,
    negative: "minus",
    decimal: "kablelis",
    comma_sep: false,
  }
}

///|
/// Upstream `_int2word`, with the optional feminine agreement used for RUB
/// cents.
fn cardinal_lt_gendered(l : Lang, n : BigInt, feminine : Bool) -> String {
  let neg = n < BigInt::from_int(0)
  let abs_n = if neg { -n } else { n }
  if !l.supports(abs_n) {
    return ""
  }
  if abs_n == BigInt::from_int(0) {
    return l.zero
  }
  let groups = group3(abs_n)
  let words : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let x = triple.to_int()
    if x == 0 {
      continue
    }
    let n1 = x % 10
    let n2 = x / 10 % 10
    let n3 = x / 100
    if n3 > 0 {
      words.push(l.ones[n3])
      if n3 > 1 {
        words.push("šimtai")
      } else {
        words.push("šimtas")
      }
    }
    if n2 > 1 {
      words.push(lt_twenties[n2])
    }
    if n2 == 1 {
      words.push(l.teens[n1])
    } else if n1 > 0 {
      // Upstream's guard also tests `i == 1`, which can never hold because
      // `n < 1000` has no second group; it is kept for fidelity.
      if (power == 1 || (feminine && power == 0)) &&
        abs_n < BigInt::from_int(1000) {
        words.push(lt_ones_feminine[n1])
      } else {
        words.push(l.ones[n1])
      }
    }
    if power > 0 {
      words.push(lt_scale(power, lt_form(x)))
    }
  }
  let joined = join_parts(words, " ")
  if neg {
    l.negative + " " + joined
  } else {
    joined
  }
}

///|
fn Lang::cardinal_lt(self : Lang, n : BigInt) -> String {
  cardinal_lt_gendered(self, n, false)
}

///|
/// Upstream `to_ordinal` raises NotImplementedError; the string API returns "".
pub fn ordinal_lt(_n : BigInt) -> String {
  ""
}

///|
/// Upstream `to_ordinal_num` falls through to the integer itself.
pub fn ordinal_num_lt(n : BigInt) -> String {
  n.to_string()
}

///|
/// Upstream `to_year` is the plain cardinal.
pub fn year_lt(n : BigInt) -> String {
  cardinal_lt_gendered(lang_lt(), n, false)
}
