// lang_sr.mbt — Serbian number spelling (cardinal, year, currency).
//
// Faithful port of upstream num2words 0.5.14 `lang_SR.py`:
//   * cardinal: 3-digit groups, high to low; each group is "hundreds +
//     tens/teens + unit", then a scale word; words are space-separated;
//   * the unit agrees in gender: `jedan/jedna`, `dva/dve`. The thousand noun
//     "hiljada" is feminine, so 1 and 2 read "jedna hiljada" / "dve hiljade";
//     currency nouns pass their own gender down (`jedna rublja`);
//   * 10^9 is "bilion" (not "miliarda"), 10^12 "trilion";
//   * the scale word inflects by the group value using upstream's
//     `pluralize`: ...1 -> "hiljada"/"milion"; ...2..4 -> "hiljade"/
//     "miliona"; everything else -> "hiljada"/"miliona".
//
// Upstream has no `to_ordinal` (raises NotImplementedError), so `ordinal_sr`
// returns "". `to_ordinal_num` falls through to the integer itself, and
// `to_year` is the plain cardinal.

///|
/// Units, masculine (index 0) and feminine (index 1).
let sr_ones_masc : Array[String] = [
  "nula", "jedan", "dva", "tri", "četiri", "pet", "šest", "sedam", "osam", "devet",
]

///|
let sr_ones_fem : Array[String] = [
  "nula", "jedna", "dve", "tri", "četiri", "pet", "šest", "sedam", "osam", "devet",
]

///|
let sr_teens : Array[String] = [
  "deset", "jedanaest", "dvanaest", "trinaest", "četrnaest", "petnaest", "šesnaest",
  "sedamnaest", "osamnaest", "devetnaest",
]

///|
let sr_twenties : Array[String] = [
  "", "", "dvadeset", "trideset", "četrdeset", "pedeset", "šezdeset", "sedamdeset",
  "osamdeset", "devedeset",
]

///|
/// Hundreds 1..9. Note the irregular 6 ("šesto", not "šeststo").
let sr_hundreds : Array[String] = [
  "", "sto", "dvesta", "trista", "četristo", "petsto", "šesto", "sedamsto", "osamsto",
  "devetsto",
]

///|
/// Scale words, form 0 (one): index = power of 1000.
let sr_scale_one : Array[String] = [
  "", "hiljada", "milion", "bilion", "trilion", "kvadrilion", "kvintilion", "sekstilion",
  "septilion", "oktilion", "nonilion",
]

///|
/// Scale words, form 1 (2..4 excluding 12..14, ...).
let sr_scale_few : Array[String] = [
  "", "hiljade", "miliona", "biliona", "triliona", "kvadriliona", "kvintiliona",
  "sekstiliona", "septiliona", "oktiliona", "noniliona",
]

///|
/// Scale words, form 2 (everything else). Only "hiljada" differs from form 0.
let sr_scale_many : Array[String] = [
  "", "hiljada", "miliona", "biliona", "triliona", "kvadriliona", "kvintiliona",
  "sekstiliona", "septiliona", "oktiliona", "noniliona",
]

///|
/// Upstream `pluralize`: 0 = one, 1 = few (2..4), 2 = many.
fn sr_form(n : Int) -> Int {
  let m10 = n % 10
  let m100 = n % 100
  if m100 < 10 || m100 > 20 {
    if m10 == 1 {
      return 0
    }
    if m10 > 1 && m10 < 5 {
      return 1
    }
  }
  2
}

///|
fn sr_scale(power : Int, form : Int) -> String {
  if form == 0 {
    sr_scale_one[power]
  } else if form == 1 {
    sr_scale_few[power]
  } else {
    sr_scale_many[power]
  }
}

///|
pub fn lang_sr() -> Lang {
  {
    variant: Sr,
    zero: "nula",
    ones: sr_ones_masc,
    teens: sr_teens,
    tens: [
      "", "deset", "dvadeset", "trideset", "četrdeset", "pedeset", "šezdeset",
      "sedamdeset", "osamdeset", "devedeset",
    ],
    hundred: "sto",
    thousands: sr_scale_one,
    negative: "minus",
    decimal: "zapeta",
    comma_sep: false,
  }
}

///|
/// Upstream `_int2word`, with the optional feminine agreement used by
/// "hiljada" and by feminine currency nouns.
fn cardinal_sr_gendered(l : Lang, n : BigInt, feminine : Bool) -> String {
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  if !l.supports(n) {
    return ""
  }
  if n == BigInt::from_int(0) {
    return l.zero
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
      words.push(sr_hundreds[n3])
    }
    if n2 > 1 {
      words.push(sr_twenties[n2])
    }
    if n2 == 1 {
      words.push(sr_teens[n1])
    } else if n1 > 0 {
      // "hiljada" is feminine; every other scale noun is masculine.
      let is_feminine = feminine || power == 1
      words.push(if is_feminine { sr_ones_fem[n1] } else { sr_ones_masc[n1] })
    }
    if power > 0 && x != 0 {
      words.push(sr_scale(power, sr_form(x)))
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
fn Lang::cardinal_sr(self : Lang, n : BigInt) -> String {
  cardinal_sr_gendered(self, n, false)
}

///|
/// Upstream `to_ordinal` raises NotImplementedError; the string API returns "".
pub fn ordinal_sr(_n : BigInt) -> String {
  ""
}

///|
/// Upstream `to_ordinal_num` falls through to the integer itself.
pub fn ordinal_num_sr(n : BigInt) -> String {
  n.to_string()
}

///|
/// Upstream `to_year` is the plain cardinal.
pub fn year_sr(n : BigInt) -> String {
  cardinal_sr_gendered(lang_sr(), n, false)
}
