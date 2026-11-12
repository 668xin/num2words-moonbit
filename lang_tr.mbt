// lang_tr.mbt — Turkish number spelling (cardinal, ordinal, year).
//
// Turkish writes the whole number as one word: 1234 -> "binikiyüzotuzdört".
// A group value of 1 in the thousands position drops "bir" ("bin", "binyüz"),
// while a million and above keep it ("birmilyon").
//
// Upstream provides no year-specific reading (`to_year` falls through to the
// cardinal) and a single hard-coded lira/kuruş currency.

///|
/// Scale words, index = group power: 1 -> 10^3 .. 6 -> 10^18.
let tr_scale : Array[String] = [
  "", "bin", "milyon", "milyar", "trilyon", "katrilyon", "kentilyon",
]

///|
pub fn lang_tr() -> Lang {
  {
    variant: Tr,
    zero: "sıfır",
    ones: [
      "sıfır", "bir", "iki", "üç", "dört", "beş", "altı", "yedi", "sekiz",
      "dokuz",
    ],
    teens: [
      "on", "onbir", "oniki", "onüç", "ondört", "onbeş", "onaltı", "onyedi",
      "onsekiz", "ondokuz",
    ],
    tens: [
      "", "on", "yirmi", "otuz", "kırk", "elli", "altmış", "yetmiş", "seksen",
      "doksan",
    ],
    hundred: "yüz",
    thousands: tr_scale,
    negative: "eksi",
    decimal: "virgül",
    comma_sep: false,
  }
}

///|
/// Spell one 3-digit group (1..999) plus its scale word, all concatenated.
/// `bir` is omitted only for a lone 1 in the thousands position.
fn Lang::group_tr(self : Lang, t : Int, power : Int) -> String {
  let mut out = ""
  let h = t / 100
  let r = t % 100
  let ten = r / 10
  let one = r % 10
  if h > 0 {
    out = out + (if h == 1 { "yüz" } else { self.ones[h] + "yüz" })
  }
  if ten > 0 {
    out = out + self.tens[ten]
  }
  if one > 0 && !(power == 1 && t == 1) {
    out = out + self.ones[one]
  }
  if power > 0 {
    out = out + tr_scale[power]
  }
  out
}

///|
/// True when any group from `from` onwards is non-zero.
fn tr_has_lower_nonzero(groups : Array[(BigInt, Int)], from : Int) -> Bool {
  for i = from; i < groups.length(); i = i + 1 {
    let (triple, _) = groups[i]
    if triple != BigInt::from_int(0) {
      return true
    }
  }
  false
}

///|
/// Upstream drops the trailing "bir" of the leading thousands group when that
/// group also has a hundreds digit and the number continues:
/// 591170 -> "beşyüzdoksanbinyüzyetmiş" but 591000 -> "beşyüzdoksanbirbin".
fn tr_top_thousands_drop(
  groups : Array[(BigInt, Int)],
  i : Int,
  power : Int,
  t : Int,
) -> Bool {
  i == 0 &&
  power == 1 &&
  t / 100 > 0 &&
  t % 10 == 1 &&
  tr_has_lower_nonzero(groups, 1)
}

///|
fn Lang::cardinal_tr(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  let groups = group3(n)
  let mut out = ""
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    let tt = if tr_top_thousands_drop(groups, i, power, t) { t - 1 } else { t }
    out = out + self.group_tr(tt, power)
  }
  if neg {
    self.negative + out
  } else {
    out
  }
}

// --- ordinals ---------------------------------------------------------------

///|
let tr_ord_ones : Array[String] = [
  "", "birinci", "ikinci", "üçüncü", "dördüncü", "beşinci", "altıncı",
  "yedinci", "sekizinci", "dokuzuncu",
]

///|
let tr_ord_tens : Array[String] = [
  "", "onuncu", "yirminci", "otuzuncu", "kırkıncı", "ellinci", "altmışıncı",
  "yetmişinci", "sekseninci", "doksanıncı",
]

///|
/// Ordinal scale words. Upstream's 10^18 entry lacks the "-uncu" suffix
/// ("kentilyon" rather than "kentilyonuncu"); that quirk is preserved.
let tr_ord_scale : Array[String] = [
  "", "bininci", "milyonuncu", "milyarıncı", "trilyonuncu", "katrilyonuncu", "kentilyon",
]

///|
/// Ordinal form of the final group: only the last spoken morpheme changes
/// (1000 -> "bininci", 1001 -> "binbirinci", 2000 -> "ikibininci").
fn Lang::group_ordinal_tr(self : Lang, t : Int, power : Int) -> String {
  let h = t / 100
  let r = t % 100
  let ten = r / 10
  let one = r % 10
  let mut out = ""
  if power > 0 {
    // The scale word becomes ordinal; the digits stay cardinal.
    if h > 0 {
      out = out + (if h == 1 { "yüz" } else { self.ones[h] + "yüz" })
    }
    if ten > 0 {
      out = out + self.tens[ten]
    }
    if one > 0 && !(power == 1 && t == 1) {
      out = out + self.ones[one]
    }
    return out + tr_ord_scale[power]
  }
  if one > 0 {
    if h > 0 {
      out = out + (if h == 1 { "yüz" } else { self.ones[h] + "yüz" })
    }
    if ten > 0 {
      out = out + self.tens[ten]
    }
    out + tr_ord_ones[one]
  } else if ten > 0 {
    if h > 0 {
      out = out + (if h == 1 { "yüz" } else { self.ones[h] + "yüz" })
    }
    out + tr_ord_tens[ten]
  } else if h > 0 {
    // A bare multiple of 100: the "yüz" itself becomes ordinal.
    if h == 1 {
      "yüzüncü"
    } else {
      self.ones[h] + "yüzüncü"
    }
  } else {
    out
  }
}

///|
pub fn ordinal_tr(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  if n == BigInt::from_int(0) {
    return "sıfırıncı"
  }
  let groups = group3(n)
  let mut last = 0
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, _) = groups[i]
    if triple != BigInt::from_int(0) {
      last = i
    }
  }
  let l = lang_tr()
  let mut out = ""
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    let tt = if tr_top_thousands_drop(groups, i, power, t) { t - 1 } else { t }
    if i == last {
      out = out + l.group_ordinal_tr(tt, power)
    } else {
      out = out + l.group_tr(tt, power)
    }
  }
  out
}

///|
/// Upstream appends the last four characters of the ordinal word:
/// 1 -> "1inci", 3 -> "3üncü", 100 -> "100üncü".
pub fn ordinal_num_tr(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  let word = ordinal_tr(n)
  let k = if word.length() >= 4 { 4 } else { word.length() }
  n.to_string() + word[word.length() - k:word.length()].to_owned()
}

///|
/// Turkish has no year-specific reading upstream; a year is a cardinal.
pub fn year_tr(n : BigInt) -> String {
  lang_tr().cardinal_tr(n)
}
