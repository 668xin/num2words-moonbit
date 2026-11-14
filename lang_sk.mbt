// lang_sk.mbt — Slovak number spelling (cardinal, year, currency).
//
// Faithful port of upstream num2words 0.5.14 `lang_SK.py`:
//   * cardinal: 3-digit groups, high to low. Within a group every word is
//     glued together without spaces ("dvestotridsaťštyri"); a scale word at
//     power 2 or above is preceded by one space ("sto miliónov"), while the
//     thousands group stays glued ("dvetisíc");
//   * groups are joined with a space except for the last one, which is glued
//     to its predecessor: 123456 -> "stodvadsaťtritisícštyristopäťdesiatšesť";
//   * a lone 1 in a non-final group drops the unit word (1000 -> "tisíc");
//   * `dva` becomes `dve` before a feminine scale word (thousand and the odd
//     powers 3, 5, 7, 9): 2000 -> "dvetisíc", 2e9 -> "dve miliardy";
//   * the scale word inflects by the group value: 1 -> "tisíc"/"milión";
//     0 < n < 5 -> "eurá"/"milióny"; everything else -> "miliónov".
//
// Upstream has no `to_ordinal` (raises NotImplementedError), so `ordinal_sk`
// returns "". `to_ordinal_num` falls through to the integer itself, and
// `to_year` is the plain cardinal.
//
// Deviations (upstream raises instead of returning a string):
//   * negative cardinals raise ValueError upstream; here they read
//     "mínus <abs>".

///|
/// Hundreds 1..9. Upstream writes them solid ("dvesto", "tristo").
let sk_hundreds : Array[String] = [
  "", "sto", "dvesto", "tristo", "štyristo", "päťsto", "šesťsto", "sedemsto",
  "osemsto", "deväťsto",
]

///|
/// Tens 20..90 (index = tens digit). Index 1 is unused: teens come from
/// `Lang.teens`.
let sk_twenties : Array[String] = [
  "", "", "dvadsať", "tridsať", "štyridsať", "päťdesiat", "šesťdesiat", "sedemdesiat",
  "osemdesiat", "deväťdesiat",
]

///|
/// Feminine unit forms, used for `dva` before a feminine scale word.
let sk_ones_feminine : Array[String] = [
  "nula", "jeden", "dve", "tri", "štyri", "päť", "šesť", "sedem", "osem", "deväť",
]

///|
/// Scale words, form 0 (one): index = power of 1000, 1 -> thousand.
let sk_thousands_one : Array[String] = [
  "", "tisíc", "milión", "miliarda", "bilión", "biliarda", "trilión", "triliarda",
  "kvadrilión", "kvadriliarda", "kvintilión",
]

///|
/// Scale words, form 1 (0 < n < 5).
let sk_thousands_few : Array[String] = [
  "", "tisíc", "milióny", "miliardy", "bilióny", "biliardy", "trilióny", "triliardy",
  "kvadrilióny", "kvadriliardy", "kvintillióny",
]

///|
/// Scale words, form 2 (everything else). "tisíc" is invariant.
let sk_thousands_many : Array[String] = [
  "", "tisíc", "miliónov", "miliárd", "biliónov", "biliárd", "triliónov", "triliárd",
  "kvadriliónov", "kvadriliárd", "kvintiliónov",
]

///|
/// Upstream `pluralize`: 0 = one, 1 = few (0 < n < 5), 2 = many.
fn sk_form(n : Int) -> Int {
  if n == 1 {
    return 0
  }
  if n > 0 && n < 5 {
    return 1
  }
  2
}

///|
fn sk_scale(power : Int, form : Int) -> String {
  if form == 0 {
    sk_thousands_one[power]
  } else if form == 1 {
    sk_thousands_few[power]
  } else {
    sk_thousands_many[power]
  }
}

///|
/// True for the powers where upstream's `dva` takes the feminine "dve":
/// thousands (1) and the odd higher powers (3, 5, 7, 9).
fn sk_feminine_power(power : Int) -> Bool {
  power == 1 || power == 3 || power == 5 || power == 7 || power == 9
}

///|
pub fn lang_sk() -> Lang {
  {
    variant: Sk,
    zero: "nula",
    ones: [
      "nula", "jeden", "dva", "tri", "štyri", "päť", "šesť", "sedem", "osem",
      "deväť",
    ],
    teens: [
      "desať", "jedenásť", "dvanásť", "trinásť", "štrnásť", "pätnásť",
      "šestnásť", "sedemnásť", "osemnásť", "devätnásť",
    ],
    tens: [
      "", "desať", "dvadsať", "tridsať", "štyridsať", "päťdesiat", "šesťdesiat",
      "sedemdesiat", "osemdesiat", "deväťdesiat",
    ],
    hundred: "sto",
    thousands: sk_thousands_one,
    negative: "mínus",
    decimal: "celých",
    comma_sep: false,
  }
}

///|
/// Upstream `_int2word`, plus the negative prefix upstream lacks.
fn Lang::cardinal_sk(self : Lang, n : BigInt) -> String {
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  if !self.supports(n) {
    return ""
  }
  if n == BigInt::from_int(0) {
    return self.zero
  }
  let groups = group3(n)
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
    let chunk : Array[String] = []
    if n3 > 0 {
      chunk.push(sk_hundreds[n3])
    }
    if n2 > 1 {
      chunk.push(sk_twenties[n2])
    }
    if n2 == 1 {
      chunk.push(self.teens[n1])
    } else if n1 > 0 && !(power > 0 && x == 1) {
      // "dve" before a feminine scale word, "jeden" is dropped before one.
      if n2 == 0 && n3 == 0 && n1 == 2 && sk_feminine_power(power) {
        chunk.push(sk_ones_feminine[n1])
      } else {
        chunk.push(self.ones[n1])
      }
    }
    if power > 1 && chunk.length() > 0 {
      chunk.push(" ")
    }
    if power > 0 {
      chunk.push(sk_scale(power, sk_form(x)))
    }
    words.push(join_parts(chunk, ""))
  }
  // Upstream joins all groups but the last with a space, and glues the last
  // one onto its predecessor.
  let mut joined = ""
  for i = 0; i < words.length(); i = i + 1 {
    if i > 0 && i < words.length() - 1 {
      joined = joined + " "
    }
    joined = joined + words[i]
  }
  if neg {
    self.negative + " " + joined
  } else {
    joined
  }
}

///|
/// Upstream `to_ordinal` raises NotImplementedError; the string API returns "".
pub fn ordinal_sk(_n : BigInt) -> String {
  ""
}

///|
/// Upstream `to_ordinal_num` falls through to the integer itself.
pub fn ordinal_num_sk(n : BigInt) -> String {
  n.to_string()
}

///|
/// Upstream `to_year` is the plain cardinal.
pub fn year_sk(n : BigInt) -> String {
  lang_sk().cardinal_sk(n)
}
