// lang_cs.mbt — Czech number spelling (cardinal, year, currency).
//
// Faithful port of upstream num2words 0.5.14 `lang_CS.py`:
//   * cardinal: 3-digit groups, high to low; each group is "hundreds +
//     tens/teens + unit", then a scale word. Hundreds 2..9 are written solid
//     ("dvěstě", "třista", "pětset"), not as "dvě stě";
//   * a lone 1 in a non-final group drops the unit word, so 1000 is "tisíc"
//     and 1000000 is "milion" (not "jedna tisíc");
//   * the scale word inflects by the group value using upstream's
//     `pluralize`: 1 -> "tisíc"/"milion"; 2..4 (not 12..14, 112..114, ...)
//     -> "tisíce"/"miliony"; everything else -> "tisíc"/"milionů";
//   * words are separated by single spaces.
//
// Upstream has no `to_ordinal` (raises NotImplementedError), so `ordinal_cs`
// returns "". `to_ordinal_num` falls through to the integer itself, and
// `to_year` is the plain cardinal.
//
// Deviations (upstream raises instead of returning a string):
//   * negative cardinals raise ValueError upstream; here they read
//     "mínus <abs>".

///|
/// Hundreds 1..9. Upstream writes the compound hundreds solid.
let cs_hundreds : Array[String] = [
  "", "sto", "dvěstě", "třista", "čtyřista", "pětset", "šestset", "sedmset",
  "osmset", "devětset",
]

///|
/// Tens 20..90 (index = tens digit). Index 1 is unused: teens come from
/// `Lang.teens`.
let cs_twenties : Array[String] = [
  "", "", "dvacet", "třicet", "čtyřicet", "padesát", "šedesát", "sedmdesát",
  "osmdesát", "devadesát",
]

///|
/// Scale words, form 0 (one): index = power of 1000, 1 -> thousand.
let cs_thousands_one : Array[String] = [
  "", "tisíc", "milion", "miliarda", "bilion", "biliarda", "trilion", "triliarda",
  "kvadrilion", "kvadriliarda", "quintillion",
]

///|
/// Scale words, form 1 (few: 2..4 excluding 12..14).
let cs_thousands_few : Array[String] = [
  "", "tisíce", "miliony", "miliardy", "biliony", "biliardy", "triliony", "triliardy",
  "kvadriliony", "kvadriliardy", "quintilliony",
]

///|
/// Scale words, form 2 (many). "tisíc" is invariant.
let cs_thousands_many : Array[String] = [
  "", "tisíc", "milionů", "miliard", "bilionů", "biliard", "trilionů", "triliard",
  "kvadrilionů", "kvadriliard", "quintillionů",
]

///|
/// Upstream `pluralize`: 0 = one, 1 = few (2..4), 2 = many.
fn cs_form(n : Int) -> Int {
  if n == 1 {
    return 0
  }
  let m10 = n % 10
  let m100 = n % 100
  if m10 > 1 && m10 < 5 && (m100 < 10 || m100 > 20) {
    return 1
  }
  2
}

///|
fn cs_scale(power : Int, form : Int) -> String {
  if form == 0 {
    cs_thousands_one[power]
  } else if form == 1 {
    cs_thousands_few[power]
  } else {
    cs_thousands_many[power]
  }
}

///|
pub fn lang_cs() -> Lang {
  {
    variant: Cs,
    zero: "nula",
    ones: [
      "nula", "jedna", "dva", "tři", "čtyři", "pět", "šest", "sedm", "osm",
      "devět",
    ],
    teens: [
      "deset", "jedenáct", "dvanáct", "třináct", "čtrnáct", "patnáct", "šestnáct",
      "sedmnáct", "osmnáct", "devatenáct",
    ],
    tens: [
      "", "deset", "dvacet", "třicet", "čtyřicet", "padesát", "šedesát", "sedmdesát",
      "osmdesát", "devadesát",
    ],
    hundred: "sto",
    thousands: cs_thousands_one,
    negative: "mínus",
    decimal: "celá",
    comma_sep: false,
  }
}

///|
/// Upstream `_int2word` for the absolute value, plus the negative prefix that
/// upstream lacks (it raises ValueError on '-').
fn Lang::cardinal_cs(self : Lang, n : BigInt) -> String {
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
    if n3 > 0 {
      words.push(cs_hundreds[n3])
    }
    if n2 > 1 {
      words.push(cs_twenties[n2])
    }
    if n2 == 1 {
      words.push(self.teens[n1])
    } else if n1 > 0 && !(power > 0 && x == 1) {
      // A lone "jedna" before a scale word is dropped: 1000 -> "tisíc".
      words.push(self.ones[n1])
    }
    if power > 0 {
      words.push(cs_scale(power, cs_form(x)))
    }
  }
  let joined = join_parts(words, " ")
  if neg {
    self.negative + " " + joined
  } else {
    joined
  }
}

///|
/// Upstream `to_ordinal` raises NotImplementedError; the string API returns "".
pub fn ordinal_cs(_n : BigInt) -> String {
  ""
}

///|
/// Upstream `to_ordinal_num` falls through to the integer itself.
pub fn ordinal_num_cs(n : BigInt) -> String {
  n.to_string()
}

///|
/// Upstream `to_year` is the plain cardinal.
pub fn year_cs(n : BigInt) -> String {
  lang_cs().cardinal_cs(n)
}
