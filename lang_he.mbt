// lang_he.mbt — Hebrew number spelling (cardinal, ordinal, year, currency).
//
// Port of upstream num2words 0.5.14 `lang_HE.py` (which postdates the classic
// European modules and has its own grammar):
//
//   * 3-digit groups are spoken high to low; a group >= 11 takes its scale word
//     ("מאה עשרים ושלושה אלף"), while a single-digit group 1..9 uses the
//     construct form before the scale ("שלושת אלפים", "שני מיליון");
//   * the conjunction "ו" is prefixed to the last word of every spoken group
//     except the first ("אלף ואחת", "עשרים ואחת") — this also applies across
//     scales ("מיליון ואחת");
//   * the default gender is feminine, which changes the units ("אחת", "שתיים")
//     and the tens ("עשרה" vs "עשר"); thousands and above use masculine forms;
//   * ordinals use the ordinal unit table for 1..10 ("ראשון", "עשירי") and the
//     masculine cardinal otherwise, with the definite article "ה" prefixed
//     from 11 upwards ("האחד עשר", "המאה"); `ordinal_num` is the plain number.
//
// Currency selects the noun gender per code (ILS: masculine shekel, feminine
// agora) and uses the construct state when the amount is exactly 2
// ("שני שקלים", "שתי אגורות").

// --- word tables ------------------------------------------------------------
//
// Every unit row holds the upstream eight forms:
//   feminine free, masculine free, feminine construct, masculine construct,
//   ordinal feminine singular, ordinal masculine singular,
//   ordinal feminine plural, ordinal masculine plural.

///|
let he_ones : Array[Array[String]] = [
  [],
  [
    "אחת", "אחד", "אחת", "אחד", "ראשונה", "ראשון", "ראשונות",
    "ראשונים",
  ],
  [
    "שתיים", "שניים", "שתי", "שני", "שנייה", "שני", "שניות",
    "שניים",
  ],
  [
    "שלוש", "שלושה", "שלוש", "שלושת", "שלישית", "שלישי",
    "שלישיות", "שלישיים",
  ],
  [
    "ארבע", "ארבעה", "ארבע", "ארבעת", "רביעית", "רביעי",
    "רביעיות", "רביעיים",
  ],
  [
    "חמש", "חמישה", "חמש", "חמשת", "חמישית", "חמישי", "חמישיות",
    "חמישיים",
  ],
  [
    "שש", "שישה", "שש", "ששת", "שישית", "שישי", "שישיות",
    "שישיים",
  ],
  [
    "שבע", "שבעה", "שבע", "שבעת", "שביעית", "שביעי", "שביעיות",
    "שביעיים",
  ],
  [
    "שמונה", "שמונה", "שמונה", "שמונת", "שמינית", "שמיני",
    "שמיניות", "שמיניים",
  ],
  [
    "תשע", "תשעה", "תשע", "תשעת", "תשיעית", "תשיעי", "תשיעיות",
    "תשיעיים",
  ],
]

///|
/// Index 0 = 10 (eight forms), 1 = the teen tens word ("עשרה"/"עשר"),
/// 2 = 12 ("שתים עשרה"/"שנים עשר").
let he_tens : Array[Array[String]] = [
  [
    "עשר", "עשרה", "עשר", "עשרת", "עשירית", "עשירי", "עשיריות",
    "עשיריים",
  ],
  ["עשרה", "עשר"],
  ["שתים עשרה", "שנים עשר"],
]

///|
/// 20..90 (index = tens digit).
let he_twenties : Array[String] = [
  "", "", "עשרים", "שלושים", "ארבעים", "חמישים", "שישים",
  "שבעים", "שמונים", "תשעים",
]

///|
/// 100 / 200 / 300+ (index = hundreds digit); entry 1 also stores the
/// construct "מאת" (used for a construct 100 in currency).
let he_hundreds : Array[Array[String]] = [
  [],
  ["מאה", "מאת"],
  ["מאתיים"],
  ["מאות"],
]

///|
/// 1000 / 2000 / 3000+ (index = thousands digit); entry 3 stores the free
/// plural "אלפים" and its construct "אלפי".
let he_thousands_forms : Array[Array[String]] = [
  [],
  ["אלף"],
  ["אלפיים"],
  ["אלפים", "אלפי"],
]

///|
/// Million-scale nouns, index = group power - 1 (1 -> 10^6). Each entry is
/// (singular, construct/plural): "מיליון" / "מיליוני".
let he_large : Array[Array[String]] = [
  [],
  ["מיליון", "מיליוני"],
  ["מיליארד", "מיליארדי"],
  ["טריליון", "טריליוני"],
  ["קוודריליון", "קוודריליוני"],
  ["קווינטיליון", "קווינטיליוני"],
  ["סקסטיליון", "סקסטיליוני"],
  ["ספטיליון", "ספטיליוני"],
  ["אוקטיליון", "אוקטיליוני"],
  ["נוניליון", "נוניליוני"],
  ["דסיליון", "דסיליוני"],
  ["אונדסיליון", "אונדסיליוני"],
  ["דואודסיליון", "דואודסיליוני"],
  ["טרדסיליון", "טרדסיליוני"],
  ["קווטואורדסיליון", "קווטואורדסיליוני"],
  ["קווינדסיליון", "קווינדסיליוני"],
  ["סקסדסיליון", "סקסדסיליוני"],
  ["ספטנדסיליון", "ספטנדסיליוני"],
  ["אוקטודסיליון", "אוקטודסיליוני"],
  ["נובמדסיליון", "נובמדסיליוני"],
  ["ויגינטיליון", "ויגינטיליוני"],
]

///|
/// `thousands` only has to be long enough for `supports`: 22 entries cover
/// powers 0..21, i.e. everything below upstream's 10^66 limit.
fn he_thousands() -> Array[String] {
  let out : Array[String] = [""]
  out.push("אלף")
  for i = 1; i < he_large.length(); i = i + 1 {
    out.push(he_large[i][0])
  }
  out
}

///|
pub fn lang_he() -> Lang {
  {
    variant: He,
    zero: "אפס",
    ones: [
      "אפס", "אחת", "שתיים", "שלוש", "ארבע", "חמש", "שש",
      "שבע", "שמונה", "תשע",
    ],
    teens: [
      "עשר", "אחת עשרה", "שתים עשרה", "שלוש עשרה", "ארבע עשרה",
      "חמש עשרה", "שש עשרה", "שבע עשרה", "שמונה עשרה",
      "תשע עשרה",
    ],
    tens: [
      "", "עשר", "עשרים", "שלושים", "ארבעים", "חמישים",
      "שישים", "שבעים", "שמונים", "תשעים",
    ],
    hundred: "מאה",
    thousands: he_thousands(),
    negative: "מינוס",
    decimal: "נקודה",
    comma_sep: false,
  }
}

// --- cardinal ---------------------------------------------------------------

///|
fn he_mod_pow1000(n : BigInt, i : Int) -> Bool {
  let mut m = BigInt::from_int(1)
  for k = 0; k < i; k = k + 1 {
    m = m * BigInt::from_int(1000)
  }
  n % m == BigInt::from_int(0)
}

///|
/// Upstream `chunk2word`. `i` is the group power, `x` its value (1..999),
/// `n` the whole absolute number. Returns the words contributed by this group.
fn he_chunk(
  n : BigInt,
  i : Int,
  x : Int,
  gender_m : Bool,
  construct : Bool,
  ordinal : Bool,
) -> Array[String] {
  let words : Array[String] = []
  let n1 = x % 10
  let n2 = x / 10 % 10
  let n3 = x / 100
  if n3 > 0 {
    if construct && n == BigInt::from_int(100) {
      words.push(he_hundreds[n3][1])
    } else if n3 <= 2 {
      words.push(he_hundreds[n3][0])
    } else {
      words.push(he_ones[n3][0] + " " + he_hundreds[3][0])
    }
  }
  if n2 > 1 {
    words.push(he_twenties[n2])
  }
  if i == 0 || x >= 11 {
    let male = gender_m || i > 0
    let mi = if male { 1 } else { 0 }
    let cop = if n < BigInt::from_int(11) {
      (if construct && i == 0 { 2 } else { 0 }) + (if ordinal { 4 } else { 0 })
    } else {
      0
    }
    if n2 == 1 {
      if n1 == 0 {
        words.push(he_tens[0][mi + cop])
      } else if n1 == 2 {
        words.push(he_tens[2][mi])
      } else {
        words.push(he_ones[n1][mi] + " " + he_tens[1][mi])
      }
    } else if n1 > 0 {
      words.push(he_ones[n1][mi + cop])
    }
  }
  let cl = construct && he_mod_pow1000(n, i)
  let cli = if cl { 1 } else { 0 }
  if i == 1 {
    if x >= 11 {
      words[words.length() - 1] = words[words.length() - 1] + " " + "אלף"
    } else if n1 == 0 {
      // Unreachable in practice: groups of value 0 are skipped by the caller.
      words.push(he_tens[0][3] + " " + he_thousands_forms[3][cli])
    } else if n1 <= 2 {
      words.push(he_thousands_forms[n1][0])
    } else {
      words.push(he_ones[n1][3] + " " + he_thousands_forms[3][cli])
    }
  } else if i > 1 {
    if x >= 11 {
      words[words.length() - 1] = words[words.length() - 1] +
        " " +
        he_large[i - 1][cli]
    } else if n1 == 0 {
      words.push(he_tens[0][1 + 2 * cli] + " " + he_large[i - 1][cli])
    } else if n1 == 1 {
      words.push(he_large[i - 1][0])
    } else {
      let idx = if cl || x == 2 { 3 } else { 1 }
      words.push(he_ones[n1][idx] + " " + he_large[i - 1][cli])
    }
  }
  words
}

///|
/// Upstream `int2word`: chunk words joined by spaces, with "ו" prefixed to the
/// last word of every group after the first, and the definite article "ה" for
/// ordinals from 11 upwards.
fn Lang::he_int2word(
  self : Lang,
  n : BigInt,
  gender_m : Bool,
  construct : Bool,
  ordinal : Bool,
) -> String {
  if n == BigInt::from_int(0) {
    return if ordinal { "ה" + self.zero } else { self.zero }
  }
  let groups = group3(n)
  let words : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let x = triple.to_int()
    if x == 0 {
      continue
    }
    let chunk = he_chunk(n, power, x, gender_m, construct, ordinal)
    for j = 0; j < chunk.length(); j = j + 1 {
      words.push(chunk[j])
    }
    if words.length() > 1 {
      let last = words.length() - 1
      words[last] = "ו" + words[last]
    }
  }
  if ordinal && n >= BigInt::from_int(11) {
    words[0] = "ה" + words[0]
  }
  join_parts(words, " ")
}

///|
/// Hebrew cardinal with the default feminine gender.
fn Lang::cardinal_he(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let v = if neg { -n } else { n }
  let words = self.he_int2word(v, false, false, false)
  if neg {
    self.negative + " " + words
  } else {
    words
  }
}

// --- ordinal ----------------------------------------------------------------

///|
/// Upstream `to_ordinal(value, gender='m')`: 1..10 use the ordinal table,
/// everything else the masculine cardinal; "ה" is prefixed from 11 upwards.
pub fn ordinal_he(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  if !lang_he().supports(n) {
    return ""
  }
  lang_he().he_int2word(n, true, false, true)
}

///|
/// Upstream inherits the base `to_ordinal_num`, which returns the value itself
/// (21 -> "21", -1 -> "-1").
pub fn ordinal_num_he(n : BigInt) -> String {
  n.to_string()
}

// --- year -------------------------------------------------------------------

///|
/// Upstream inherits `to_year`, i.e. the feminine cardinal (1900 ->
/// "אלף ותשע מאות").
pub fn year_he(n : BigInt) -> String {
  lang_he().cardinal_he(n)
}

// --- currency ---------------------------------------------------------------

///|
/// Hebrew currency forms: (unit singular/plural, cent singular/plural, unit
/// masculine?, cent masculine?).
fn he_currency_forms(
  code : String,
) -> Result[(String, String, String, String, Bool, Bool), String] {
  match code {
    "ILS" =>
      Ok(("שקל", "שקלים", "אגורה", "אגורות", true, false))
    "EUR" => Ok(("אירו", "אירו", "סנט", "סנטים", true, true))
    "USD" =>
      Ok(("דולר", "דולרים", "סנט", "סנטים", true, true))
    _ => Err(code)
  }
}

///|
/// Hebrew currency: "<amount> <unit> ו<amount> <cent>", with the noun moved
/// before a count of exactly 1 ("שקל אחד", "אגורה אחת") and the construct
/// state used for a count of exactly 2 ("שני שקלים", "שתי אגורות").
fn currency_he(
  units : BigInt,
  cents : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  let l = lang_he()
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let (u1, u2, c1, c2, g1, g2) = match he_currency_forms(code) {
    Err(c) => return Err("currency code not supported for he: " + c)
    Ok(forms) => forms
  }
  let one = BigInt::from_int(1)
  let two = BigInt::from_int(2)
  let mut money = l.he_int2word(units, g1, units == two, false)
  let mut unit = if units == one { u1 } else { u2 }
  if units == one {
    let tmp = money
    money = unit
    unit = tmp
  }
  let mut cent_words = l.he_int2word(cents, g2, cents == two, false)
  let mut cent = if cents == one { c1 } else { c2 }
  if cents == one {
    let tmp = cent_words
    cent_words = cent
    cent = tmp
  }
  let body = money + " " + unit + " ו" + cent_words + " " + cent
  if neg {
    Ok("מינוס " + body)
  } else {
    Ok(body)
  }
}
