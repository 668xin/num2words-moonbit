// num2words-moonbit.mbt — public API and dispatch.
//
// Port of the Python `num2words` library (LGPL-2.1). See README / base.mbt header
// for attribution. Acknowledged upstream: https://github.com/savoirfairelinux/num2words
//
// API: `num2words(value, lang, to)` where `value` is a BigInt (or use the
// `num2words_int` / `num2words_float` convenience wrappers), `lang` is
// "en" | "fr" | "es" | "de" | "it" | "pt" | "pt_PT" | "ru" | "nl" | "tr" | "vi"
// | "zh" | "zh_TW" | "ja" | "ko" | "sv" | "no" | "da" | "id" | "pl" | "ar" | "th"
// | "fi" | "uk",
// and `to` is "cardinal" (default), "ordinal", "ordinal_num", "year" or
// "currency".
//
// Currency takes a decimal amount string and an ISO-4217 code through
// `num2words_currency`; the `to = "currency"` dispatch path uses the language
// default code (EUR, BRL for `pt`, TRY for `tr`, 元/XXX for Chinese, JPY for
// Japanese, KRW for Korean, NOK for Norwegian, DKK for Danish, IDR for
// Indonesian; Finnish accepts its 24-code upstream set).

// --- input validation -------------------------------------------------------
//
// `BigInt::from_string` aborts on malformed input, so every string entry point
// validates first. Accepted grammar: `-?\d+` or `-?\d+\.\d+`.

///|
/// True when `s` is non-empty and made only of ASCII digits.
fn all_digits(s : String) -> Bool {
  if s.length() == 0 {
    return false
  }
  for i = 0; i < s.length(); i = i + 1 {
    if !"0123456789".contains(s[i:i + 1].to_owned()) {
      return false
    }
  }
  true
}

///|
/// True for an integer literal: an optional leading `-` followed by digits.
fn is_int_part(s : String) -> Bool {
  let body = if s.length() > 0 && s[0:1].to_owned() == "-" {
    s[1:s.length()].to_owned()
  } else {
    s
  }
  all_digits(body)
}

///|
/// Validate a decimal/integer string before it reaches `BigInt`.
///
/// Accepted: `1234`, `-42`, `007`, `1234.56`
/// Rejected: `""`, `"-"`, `"5."`, `".5"`, `"1.2.3"`, `"12a"`, `"abc"`, `"--5"`
pub fn is_valid_number(s : String) -> Bool {
  let parts = s.split(".").map(fn(w) { w.to_owned() }).collect()
  if parts.length() > 2 {
    return false
  }
  if !is_int_part(parts[0]) {
    return false
  }
  if parts.length() == 2 {
    if !all_digits(parts[1]) {
      return false
    }
  }
  true
}

///|
/// Position of the single-character string `target` inside `s`, or -1.
fn index_of_char(s : String, target : String) -> Int {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i:i + 1].to_owned() == target {
      return i
    }
  }
  -1
}

///|
/// Parse the (signed) exponent digits of a scientific-notation string.
fn parse_exp_int(s : String) -> Int {
  let mut neg = false
  let mut i = 0
  if s.length() > 0 && s[0:1].to_owned() == "+" {
    i = 1
  } else if s.length() > 0 && s[0:1].to_owned() == "-" {
    neg = true
    i = 1
  }
  let mut v = 0
  while i < s.length() {
    v = v * 10 + BigInt::from_string(s[i:i + 1].to_owned()).to_int()
    i = i + 1
  }
  if neg {
    -v
  } else {
    v
  }
}

///|
/// Expand a `Double` rendered in scientific notation (e.g. `1e+21`, `1e-7`,
/// `1.5e+21`) into a plain decimal string. Values already in plain form are
/// returned unchanged. `Double::to_string` switches to scientific notation for
/// magnitudes at or above 10^21 and below 10^-6; passing that form straight to
/// `BigInt::from_string` would abort, so it is expanded first.
fn expand_scientific(s : String) -> String {
  let e_pos = index_of_char(s, "e")
  let e_pos_upper = index_of_char(s, "E")
  let pos = if e_pos >= 0 { e_pos } else { e_pos_upper }
  if pos < 0 {
    return s
  }
  let mantissa = s[0:pos].to_owned()
  let exp = parse_exp_int(s[pos + 1:s.length()].to_owned())
  let neg = mantissa.length() > 0 && mantissa[0:1].to_owned() == "-"
  let body = if neg {
    mantissa[1:mantissa.length()].to_owned()
  } else {
    mantissa
  }
  let dot = index_of_char(body, ".")
  let int_len = if dot >= 0 { dot } else { body.length() }
  let digits = if dot >= 0 {
    body[0:dot].to_owned() + body[dot + 1:body.length()].to_owned()
  } else {
    body
  }
  let point = int_len + exp
  let mut out = ""
  if point <= 0 {
    out = "0."
    for i = point; i < 0; i = i + 1 {
      out = out + "0"
    }
    out = out + digits
  } else if point >= digits.length() {
    out = digits
    for i = digits.length(); i < point; i = i + 1 {
      out = out + "0"
    }
  } else {
    out = digits[0:point].to_owned() +
      "." +
      digits[point:digits.length()].to_owned()
  }
  if neg {
    "-" + out
  } else {
    out
  }
}

///|
/// Negative prefix for a whole phrase. Chinese and Japanese attach it without
/// a space (负一 / マイナス一); Korean and the other languages use a space.
fn negative_prefix(l : Lang) -> String {
  match l.variant {
    Zh | ZhTw | Ja => l.negative
    _ => l.negative + " "
  }
}

///|
/// Spell the fractional digits of a decimal: `"5"` -> `" point five"`.
fn decimal_tail(l : Lang, frac : String) -> String {
  match l.variant {
    // CJK (except Korean) writes the point and digits without spaces: 零点五.
    Zh | ZhTw | Ja => {
      let mut out = l.decimal
      for i = 0; i < frac.length(); i = i + 1 {
        let d = BigInt::from_string(frac[i:i + 1].to_owned()).to_int()
        out = out + l.ones[d]
      }
      out
    }
    // Korean spaces the point and every digit: 천이백삼십사 점 오 육.
    _ => {
      let mut out = " " + l.decimal
      for i = 0; i < frac.length(); i = i + 1 {
        let d = BigInt::from_string(frac[i:i + 1].to_owned()).to_int()
        out = out + " " + l.ones[d]
      }
      out
    }
  }
}

///|
/// True for a language code implemented by this library. The lenient
/// `get_lang` still falls back to English for direct callers, but the
/// conversion entry points reject unknown codes instead of silently
/// producing English words.
fn known_lang(code : String) -> Bool {
  match code {
    "en"
    | "fr"
    | "es"
    | "de"
    | "it"
    | "pt"
    | "pt_PT"
    | "ru"
    | "nl"
    | "tr"
    | "vi"
    | "zh"
    | "zh_TW"
    | "ja"
    | "ko"
    | "sv"
    | "no"
    | "da"
    | "id"
    | "pl"
    | "ar"
    | "th"
    | "fi"
    | "uk" => true
    _ => false
  }
}

///|
/// True for one of the five output modes.
fn known_mode(to : String) -> Bool {
  match to {
    "cardinal" | "ordinal" | "ordinal_num" | "year" | "currency" => true
    _ => false
  }
}

///|
/// Resolve a language code to its `Lang` descriptor.
pub fn get_lang(code : String) -> Lang {
  match code {
    "en" => lang_en()
    "fr" => lang_fr()
    "es" => lang_es()
    "de" => lang_de()
    "it" => lang_it()
    "pt" => lang_pt()
    "pt_PT" => lang_pt_pt()
    "ru" => lang_ru()
    "nl" => lang_nl()
    "tr" => lang_tr()
    "vi" => lang_vi()
    "zh" => lang_zh()
    "zh_TW" => lang_zh_tw()
    "ja" => lang_ja()
    "ko" => lang_ko()
    "sv" => lang_sv()
    "no" => lang_no()
    "da" => lang_da()
    "id" => lang_id()
    "pl" => lang_pl()
    "ar" => lang_ar()
    "th" => lang_th()
    "fi" => lang_fi()
    "uk" => lang_uk()
    _ => lang_en()
  }
}

///|
/// Upstream raises TypeError for negative ordinals in every language except
/// Italian ("meno ..."); our string API returns "" for those instead.
fn ordinal_for(l : Lang, value : BigInt) -> String {
  match l.variant {
    En => ordinal_en(value)
    Fr => ordinal_fr(value)
    Es => ordinal_es(value)
    De => ordinal_de(value)
    It => ordinal_it(value)
    Pt => ordinal_pt(value)
    PtPt => ordinal_pt_pt(value)
    Ru => ordinal_ru(value)
    Nl => ordinal_nl(value)
    Tr => ordinal_tr(value)
    Vi => ordinal_vi(value)
    Zh => ordinal_zh(value)
    ZhTw => ordinal_zh_tw(value)
    Ja => ordinal_ja(value)
    Ko => ordinal_ko(value)
    Sv => ordinal_sv(value)
    No => ordinal_no(value)
    Da => ordinal_da(value)
    Id => ordinal_id(value)
    Pl => ordinal_pl(value)
    Ar => ordinal_ar(value)
    Th => ordinal_th(value)
    Fi => ordinal_fi(value)
    Uk => ordinal_uk(value)
  }
}

///|
/// ordinal_num formats: en "21st", fr "21me"/"1er", es/pt "21º", de "21.",
/// it/ru plain "21" (upstream falls through to str(value)).
fn ordinal_num_for(l : Lang, value : BigInt) -> String {
  match l.variant {
    En => ordinal_num_en(value)
    Fr => ordinal_num_fr(value)
    Es => ordinal_num_es(value)
    De => ordinal_num_de(value)
    It => ordinal_num_it(value)
    Pt => ordinal_num_pt(value)
    PtPt => ordinal_num_pt(value)
    Ru => ordinal_num_ru(value)
    Nl => ordinal_num_nl(value)
    Tr => ordinal_num_tr(value)
    Vi => ordinal_num_vi(value)
    Zh => ordinal_num_zh(value)
    ZhTw => ordinal_num_zh(value)
    Ja => ordinal_num_ja(value)
    Ko => ordinal_num_ko(value)
    Sv => ordinal_num_sv(value)
    No => ordinal_num_no(value)
    Da => ordinal_num_da(value)
    Id => ordinal_num_id(value)
    Pl => ordinal_num_pl(value)
    Ar => ordinal_num_ar(value)
    Th => ordinal_num_th(value)
    Fi => ordinal_num_fi(value)
    Uk => ordinal_num_uk(value)
  }
}

///|
fn year_for(l : Lang, value : BigInt) -> String {
  match l.variant {
    En => year_en(value)
    Fr => year_fr(value)
    Es => year_es(value)
    De => year_de(value)
    It => year_it(value)
    Pt => year_pt(value)
    PtPt => year_pt_pt(value)
    Ru => year_ru(value)
    Nl => year_nl(value)
    Tr => year_tr(value)
    // Vietnamese has no `to_year` upstream (AttributeError).
    Vi => ""
    Zh => year_zh(value)
    ZhTw => year_zh(value)
    Ja => year_ja(value)
    Ko => year_ko(value)
    Sv => year_sv(value)
    No => year_no(value)
    Da => year_da(value)
    Id => year_id(value)
    Pl => year_pl(value)
    Ar => year_ar(value)
    Th => year_th(value)
    Fi => year_fi(value)
    Uk => year_uk(value)
  }
}

///|
/// Currency spelling with the language default code (EUR, BRL for `pt`, TRY
/// for `tr`); `""` when the language or the amount is not supported.
fn currency_string(amount : String, lang : String) -> String {
  match num2words_currency(amount, lang, "") {
    Ok(words) => words
    Err(_) => ""
  }
}

///|
/// Spell a big integer.
pub fn num2words(value : BigInt, lang : String, to : String) -> String {
  if !known_lang(lang) || !known_mode(to) {
    return ""
  }
  let l = get_lang(lang)
  if !l.supports(value) {
    // Beyond the language's scale-word table: report as unsupported rather
    // than indexing past the end of the table.
    return ""
  }
  match to {
    "cardinal" => l.cardinal(value)
    "ordinal" => ordinal_for(l, value)
    "ordinal_num" => ordinal_num_for(l, value)
    "year" => year_for(l, value)
    "currency" => currency_string(value.to_string(), lang)
    _ => l.cardinal(value)
  }
}

///|
/// Convenience wrapper for `Int` values.
pub fn num2words_int(value : Int, lang : String, to : String) -> String {
  num2words(BigInt::from_int(value), lang, to)
}

///|
/// Spell a decimal number: integer part in words, fractional digits spelled
/// out one by one after the decimal word (e.g. 1234.56 -> "... point five six").
///
/// Scientific-notation values (very large or very small doubles) are expanded
/// to a plain decimal first. Values too large for the language's scale table,
/// and non-finite values (`NaN` / infinity), return `""` instead of aborting.
/// With `to = "currency"` the amount is rendered with the default code (EUR).
pub fn num2words_float(value : Double, lang : String, to : String) -> String {
  if !known_lang(lang) || !known_mode(to) {
    return ""
  }
  let s = expand_scientific(value.to_string())
  if to == "currency" {
    return currency_string(s, lang)
  }
  let l = get_lang(lang)
  if !is_valid_number(s) {
    return ""
  }
  let neg = s.length() > 0 && s[0:1].to_owned() == "-"
  let parts = s.split(".").map(fn(w) { w.to_owned() }).collect()
  let int_part = BigInt::from_string(parts[0])
  if !l.supports(int_part) {
    return ""
  }
  let mut out = l.cardinal(int_part)
  if parts.length() > 1 {
    out = out + decimal_tail(l, parts[1])
    // `-0` is normalised to zero by `BigInt`, so restore the minus sign for
    // negative values below one (e.g. -0.5 -> "minus zero point five").
    if neg && int_part == BigInt::from_int(0) {
      out = negative_prefix(l) + out
    }
  }
  out
}

///|
/// Spell a number given directly as a decimal/integer string, e.g.
/// `num2words_str("1234.56", "en", "cardinal")` ->
/// "one thousand, two hundred and thirty-four point five six".
/// Integer and arbitrarily large values are supported via `BigInt`.
///
/// Malformed input returns `""` instead of aborting; use
/// `num2words_str_checked` when the caller needs to tell the two apart.
pub fn num2words_str(value : String, lang : String, to : String) -> String {
  if !known_lang(lang) || !known_mode(to) {
    return ""
  }
  if to == "currency" {
    return currency_string(value, lang)
  }
  if !is_valid_number(value) {
    return ""
  }
  let l = get_lang(lang)
  let parts = value.split(".").map(fn(w) { w.to_owned() }).collect()
  if parts.length() > 1 {
    let int_part = BigInt::from_string(parts[0])
    if !l.supports(int_part) {
      // An out-of-range integer part must yield "" as a whole; spelling the
      // decimal tail on its own would leak " point five" and friends.
      return ""
    }
    let mut out = l.cardinal(int_part) + decimal_tail(l, parts[1])
    // Restore the sign for negative values below one (e.g. -0.5).
    let neg = value.length() > 0 && value[0:1].to_owned() == "-"
    if neg && int_part == BigInt::from_int(0) {
      out = negative_prefix(l) + out
    }
    out
  } else {
    num2words(BigInt::from_string(value), lang, to)
  }
}

///|
/// Same as `num2words_str`, but rejects bad input explicitly:
/// `Ok(words)` on success, `Err(message)` when `value` is either malformed
/// (`Err("invalid number: ...")`) or larger than the language's scale-word
/// table (`Err("magnitude out of supported range: ...")`). Currency mode also
/// reports unsupported languages through `Err`.
pub fn num2words_str_checked(
  value : String,
  lang : String,
  to : String,
) -> Result[String, String] {
  if !known_lang(lang) {
    return Err("unknown language: " + lang)
  }
  if !known_mode(to) {
    return Err("unknown mode: " + to)
  }
  if to == "currency" {
    return num2words_currency(value, lang, "")
  }
  if !is_valid_number(value) {
    return Err("invalid number: " + value)
  }
  let l = get_lang(lang)
  let int_part = value.split(".").map(fn(w) { w.to_owned() }).collect()[0]
  if !l.supports(BigInt::from_string(int_part)) {
    return Err("magnitude out of supported range: " + value)
  }
  Ok(num2words_str(value, lang, to))
}
