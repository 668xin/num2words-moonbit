// lang_eo.mbt — Esperanto number spelling (cardinal, ordinal, year, currency).
//
// Port of upstream num2words 0.5.14 `lang_EO.py`. Esperanto builds one word up
// to the hundreds ("ducent", "tridek kvar") and separates scale groups with a
// space ("du mil", "cent dudek tri milionoj"):
//
//   * a multiplier of 1 is silent before 100 and 1000 ("cent", "mil") but is
//     written before the million words ("unu miliono");
//   * million-scale nouns take the plural ending -j when multiplied
//     ("du milionoj", "dudek miliardoj");
//   * a group of exactly 100 attaches to the preceding scale phrase without a
//     space ("milcent", "unu milionocent"); other groups keep the space.
//
// Ordinals take the cardinal and replace the final morpheme ("du" -> "dua",
// "dek" -> "deka", "cent" -> "centa"). `to_year` is the cardinal.

// --- word tables ------------------------------------------------------------

///|
let eo_ones : Array[String] = [
  "nul", "unu", "du", "tri", "kvar", "kvin", "ses", "sep", "ok", "naŭ",
]

///|
let eo_tens : Array[String] = [
  "", "dek", "dudek", "tridek", "kvardek", "kvindek", "sesdek", "sepdek", "okdek",
  "naŭdek",
]

///|
/// Latin base of the -iliono/-iliardo scale words.
let eo_bases : Array[String] = [
  "", "", "m", "m", "b", "b", "tr", "tr", "kvadr", "kvadr", "kvint", "kvint", "seks",
  "seks",
]

///|
/// Scale words for `Lang.thousands` (index = power of 1000); only the length
/// is used by `supports`.
fn eo_thousands() -> Array[String] {
  [
    "", "mil", "miliono", "miliardo", "biliono", "biliardo", "triliono", "triliardo",
    "kvadriliono", "kvadriliardo", "kvintiliono", "kvintiliardo", "seksiliono", "seksiliardo",
  ]
}

///|
pub fn lang_eo() -> Lang {
  {
    variant: Eo,
    zero: "nul",
    ones: eo_ones,
    teens: [
      "dek", "dek unu", "dek du", "dek tri", "dek kvar", "dek kvin", "dek ses", "dek sep",
      "dek ok", "dek naŭ",
    ],
    tens: eo_tens,
    hundred: "cent",
    thousands: eo_thousands(),
    negative: "minus",
    decimal: "komo",
    comma_sep: false,
  }
}

// --- cardinal ---------------------------------------------------------------

///|
fn eo_below100(r : Int) -> String {
  if r < 10 {
    return eo_ones[r]
  }
  if r == 10 {
    return "dek"
  }
  if r < 20 {
    return "dek " + eo_ones[r - 10]
  }
  let d = r / 10
  let u = r % 10
  if u == 0 {
    eo_tens[d]
  } else {
    eo_tens[d] + " " + eo_ones[u]
  }
}

///|
fn eo_below1000(x : Int) -> String {
  let h = x / 100
  let r = x % 100
  let mut text = ""
  if h > 0 {
    text = if h == 1 { "cent" } else { eo_ones[h] + "cent" }
  }
  if r > 0 {
    if text != "" {
      text = text + " "
    }
    text = text + eo_below100(r)
  }
  text
}

///|
fn eo_scale(power : Int, x : Int) -> String {
  let base = eo_bases[power]
  let word = base + (if power % 2 == 0 { "iliono" } else { "iliardo" })
  if x == 1 {
    word
  } else {
    word + "j"
  }
}

///|
fn eo_group(x : Int, power : Int) -> String {
  if power == 0 {
    return eo_below1000(x)
  }
  if power == 1 {
    if x == 1 {
      return "mil"
    }
    return eo_below1000(x) + " mil"
  }
  let mult = if x == 1 { "unu" } else { eo_below1000(x) }
  mult + " " + eo_scale(power, x)
}

///|
fn Lang::cardinal_eo(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let v = if neg { -n } else { n }
  let groups = group3(v)
  let words : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let x = triple.to_int()
    if x == 0 {
      continue
    }
    let text = eo_group(x, power)
    // Upstream's `merge` concatenates when the right operand is exactly 100:
    // 1100 -> "milcent", 1000100 -> "unu milionocent".
    if words.length() > 0 && power == 0 && x == 100 {
      let last = words.length() - 1
      words[last] = words[last] + text
    } else {
      words.push(text)
    }
  }
  let out = join_parts(words, " ")
  if neg {
    self.negative + " " + out
  } else {
    out
  }
}

// --- ordinal ----------------------------------------------------------------

///|
/// Insertion-ordered suffix rewrite (upstream `self.ords`), first match wins.
let eo_ords : Array[(String, String)] = [
  ("unu", "unua"),
  ("du", "dua"),
  ("tri", "tria"),
  ("kvar", "kvara"),
  ("kvin", "kvina"),
  ("ses", "sesa"),
  ("sep", "sepa"),
  ("ok", "oka"),
  ("naŭ", "naŭa"),
  ("dek", "deka"),
]

///|
pub fn ordinal_eo(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream `verify_ordinal` raises TypeError.
    return ""
  }
  if !lang_eo().supports(n) {
    return ""
  }
  let word = lang_eo().cardinal_eo(n)
  for i = 0; i < eo_ords.length(); i = i + 1 {
    let (suffix, repl) = eo_ords[i]
    if ends_with(word, suffix) {
      return word[0:word.length() - suffix.length()].to_owned() + repl
    }
  }
  if ends_with(word, "o") {
    word[0:word.length() - 1].to_owned() + "a"
  } else if ends_with(word, "oj") {
    word[0:word.length() - 2].to_owned() + "a"
  } else {
    word + "a"
  }
}

///|
/// Upstream `to_ordinal_num` is "<n>a".
pub fn ordinal_num_eo(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    ""
  } else {
    n.to_string() + "a"
  }
}

// --- year -------------------------------------------------------------------

///|
/// Upstream inherits `to_year` from the base class, which is the cardinal
/// (negative years keep "minus").
pub fn year_eo(n : BigInt) -> String {
  lang_eo().cardinal_eo(n)
}

// --- currency ---------------------------------------------------------------

///|
/// Upstream's five codes: (unit one/many, cent one/many).
fn eo_currency_forms(
  code : String,
) -> Result[(String, String, String, String), String] {
  match code {
    "EUR" => Ok(("eŭro", "eŭroj", "centimo", "centimoj"))
    "USD" => Ok(("dolaro", "dolaroj", "cendo", "cendoj"))
    "FRF" => Ok(("franko", "frankoj", "centimo", "centimoj"))
    "GBP" => Ok(("pundo", "pundoj", "penco", "pencoj"))
    "CNY" => Ok(("juano", "juanoj", "feno", "fenoj"))
    _ => Err(code)
  }
}

///|
/// Esperanto currency spelling ("nul eŭro kaj nul centimo"); the singular noun
/// is used for 0 and 1, the plural for everything else.
fn currency_eo(
  units : BigInt,
  cents : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  let l = lang_eo()
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let (u1, u2, c1, c2) = match eo_currency_forms(code) {
    Err(c) => return Err("currency code not supported for eo: " + c)
    Ok(forms) => forms
  }
  let one = BigInt::from_int(1)
  let unit = if units <= one { u1 } else { u2 }
  let cent = if cents <= one { c1 } else { c2 }
  let body = l.cardinal_eo(units) +
    " " +
    unit +
    " kaj " +
    l.cardinal_eo(cents) +
    " " +
    cent
  if neg {
    Ok("minus " + body)
  } else {
    Ok(body)
  }
}
