// lang_az.mbt — Azerbaijani number spelling (cardinal, ordinal, year, currency).
//
// Faithful port of upstream num2words 0.5.14 `lang_AZ.py`:
//   * cardinal scans the decimal string digit by digit (not by lookup
//     tables): "yüz" never takes a preceding "bir" (100, not "bir yüz") and
//     the thousands word "min" is written alone for 1000 (not "bir min"),
//     while 10^6 and above keep "bir" (1000000 -> "bir milyon");
//   * groups are read high to low, space separated: "iki yüz otuz dörd min";
//   * ordinals take a vowel-harmony suffix chosen from the last vowel of the
//     cardinal (-ıncı/-inci/-uncu/-üncü), dropping a final vowel first:
//     "iki" -> "ikinci", "altı" -> "altıncı", "yüz" -> "yüzüncü";
//   * ordinal_num is "<n>-<cı/ci/cu/cü>" using the same vowel harmony;
//   * years are the cardinal of the absolute value, with "e.ə." prefixed for
//     negative years;
//   * currency is AZN only ("manat"/"qəpik"), comma separated.
//
// Deviations (upstream reads the fractional part as an integer):
//   * decimal digits are spelled one by one here, so 1.56 is
//     "bir nöqtə beş altı" rather than "bir nöqtə əlli altı"; leading zeros
//     match upstream because both spell a zero per leading digit.

///|
/// Units 0..9.
let az_ones : Array[String] = [
  "sıfır", "bir", "iki", "üç", "dörd", "beş", "altı", "yeddi", "səkkiz",
  "doqquz",
]

///|
/// Tens 10..90 (index = tens digit).
let az_tens : Array[String] = [
  "", "on", "iyirmi", "otuz", "qırx", "əlli", "altmış", "yetmiş", "səksən",
  "doxsan",
]

///|
/// Scale words, index = group number (power of 1000): 1 -> "min",
/// 2 -> "milyon", ... up to 10^63.
let az_thousands : Array[String] = [
  "", "min", "milyon", "milyard", "trilyon", "katrilyon", "kentilyon", "sekstilyon",
  "septilyon", "oktilyon", "nonilyon", "desilyon", "undesilyon", "dodesilyon", "tredesilyon",
  "katordesilyon", "kendesilyon", "seksdesilyon", "septendesilyon", "oktodesilyon",
  "novemdesilyon", "vigintilyon",
]

///|
/// True for the nine Azerbaijani vowels.
fn az_is_vowel(ch : String) -> Bool {
  ch == "a" ||
  ch == "ı" ||
  ch == "o" ||
  ch == "u" ||
  ch == "e" ||
  ch == "ə" ||
  ch == "i" ||
  ch == "ö" ||
  ch == "ü"
}

///|
/// The last vowel of `text`, or "" when there is none.
fn az_last_vowel(text : String) -> String {
  let mut i = text.length() - 1
  while i >= 0 {
    let ch = text[i:i + 1].to_owned()
    if az_is_vowel(ch) {
      return ch
    }
    i = i - 1
  }
  ""
}

///|
/// Ordinal suffix for a final vowel: -ıncı / -inci / -uncu / -üncü.
fn az_ordinal_suffix(vowel : String) -> String {
  if vowel == "a" || vowel == "ı" {
    "ıncı"
  } else if vowel == "e" || vowel == "ə" || vowel == "i" {
    "inci"
  } else if vowel == "o" || vowel == "u" {
    "uncu"
  } else {
    "üncü"
  }
}

///|
/// Ordinal-num suffix for a final vowel: -cı / -ci / -cu / -cü.
fn az_ordinal_num_suffix(vowel : String) -> String {
  if vowel == "a" || vowel == "ı" {
    "cı"
  } else if vowel == "e" || vowel == "ə" || vowel == "i" {
    "ci"
  } else if vowel == "o" || vowel == "u" {
    "cu"
  } else {
    "cü"
  }
}

///|
/// True when `text` ends with one of the vowels (upstream `_last_vowel` guard
/// for dropping the final character before the suffix).
fn az_ends_with_vowel(text : String) -> Bool {
  if text.length() == 0 {
    return false
  }
  az_is_vowel(text[text.length() - 1:text.length()].to_owned())
}

///|
pub fn lang_az() -> Lang {
  {
    variant: Az,
    zero: "sıfır",
    ones: az_ones,
    teens: [
      "on", "on bir", "on iki", "on üç", "on dörd", "on beş", "on altı", "on yeddi",
      "on səkkiz", "on doqquz",
    ],
    tens: az_tens,
    hundred: "yüz",
    thousands: az_thousands,
    negative: "mənfi",
    decimal: "nöqtə",
    comma_sep: false,
  }
}

///|
/// Upstream `int_to_word` for a non-negative value.
fn az_int2word(n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return "sıfır"
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
    // "yüz" carries no "bir"; the multiplicand comes first.
    if n3 > 0 {
      if n3 > 1 {
        words.push(az_ones[n3])
      }
      words.push("yüz")
    }
    if n2 > 0 {
      words.push(az_tens[n2])
    }
    if n1 > 0 && !(power == 1 && n1 == 1) {
      // 1000 is "min", not "bir min": the ones digit of the thousands group
      // is skipped when it is 1. Higher groups keep "bir milyon".
      words.push(az_ones[n1])
    }
    if power > 0 {
      words.push(az_thousands[power])
    }
  }
  join_parts(words, " ")
}

///|
/// Upstream `to_cardinal`: sign, integral part, then a digit-by-digit
/// fraction after the point word.
fn Lang::cardinal_az(self : Lang, n : BigInt) -> String {
  let neg = n < BigInt::from_int(0)
  let abs_n = if neg { -n } else { n }
  if !self.supports(abs_n) {
    return ""
  }
  let body = az_int2word(abs_n)
  if neg {
    self.negative + " " + body
  } else {
    body
  }
}

///|
/// Upstream `to_ordinal`: vowel-harmony suffix, dropping a final vowel.
pub fn ordinal_az(n : BigInt) -> String {
  let cardinal = lang_az().cardinal_az(n)
  if cardinal == "" {
    return ""
  }
  let vowel = az_last_vowel(cardinal)
  if vowel == "" {
    return ""
  }
  let stem = if az_ends_with_vowel(cardinal) {
    cardinal[0:cardinal.length() - 1].to_owned()
  } else {
    cardinal
  }
  stem + az_ordinal_suffix(vowel)
}

///|
/// Upstream `to_ordinal_num`: "<n>-<suffix>", same vowel harmony.
pub fn ordinal_num_az(n : BigInt) -> String {
  let cardinal = lang_az().cardinal_az(n)
  let vowel = az_last_vowel(cardinal)
  if vowel == "" {
    return n.to_string()
  }
  n.to_string() + "-" + az_ordinal_num_suffix(vowel)
}

///|
/// Upstream `to_year`: cardinal of the absolute value, "e.ə." for BCE.
pub fn year_az(n : BigInt) -> String {
  let neg = n < BigInt::from_int(0)
  let abs_n = if neg { -n } else { n }
  let body = lang_az().cardinal_az(abs_n)
  if neg {
    "e.ə. " + body
  } else {
    body
  }
}
