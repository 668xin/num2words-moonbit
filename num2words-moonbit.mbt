// num2words-moonbit.mbt — public API and dispatch.
//
// Port of the Python `num2words` library (MIT). See README / base.mbt header
// for attribution. Acknowledged upstream: https://github.com/savoirfairelinux/num2words
//
// API: `num2words(value, lang, to)` where `value` is a BigInt (or use the
// `num2words_int` / `num2words_float` convenience wrappers), `lang` is
// "en" | "fr" | "es" | "de", and `to` is "cardinal" (default), "ordinal",
// "ordinal_num", "year" or "currency".

/// Resolve a language code to its `Lang` descriptor.
pub fn get_lang(code : String) -> Lang {
  match code {
    "en" => lang_en()
    "fr" => lang_fr()
    "es" => lang_es()
    "de" => lang_de()
    _ => lang_en()
  }
}

fn ordinal_for(l : Lang, value : BigInt) -> String {
  match l.variant {
    En => ordinal_en(value)
    _ => l.cardinal(value)
  }
}

fn ordinal_num_for(l : Lang, value : BigInt) -> String {
  match l.variant {
    En => ordinal_num_en(value)
    _ => l.cardinal(value) + "."
  }
}

fn year_for(l : Lang, value : BigInt) -> String {
  match l.variant {
    En => year_en(value)
    Fr => year_fr(value)
    Es => year_es(value)
    De => year_de(value)
  }
}

fn currency_for(l : Lang, value : BigInt) -> String {
  match l.variant {
    En => currency_en(value, BigInt::from_int(0))
    _ => l.cardinal(value)
  }
}

/// Spell a big integer.
pub fn num2words(value : BigInt, lang : String, to : String) -> String {
  let l = get_lang(lang)
  match to {
    "cardinal" => l.cardinal(value)
    "ordinal" => ordinal_for(l, value)
    "ordinal_num" => ordinal_num_for(l, value)
    "year" => year_for(l, value)
    "currency" => currency_for(l, value)
    _ => l.cardinal(value)
  }
}

/// Convenience wrapper for `Int` values.
pub fn num2words_int(value : Int, lang : String, to : String) -> String {
  num2words(BigInt::from_int(value), lang, to)
}

/// Spell a decimal number: integer part in words, fractional digits spelled
/// out one by one after the decimal word (e.g. 1234.56 -> "... point five six").
pub fn num2words_float(value : Double, lang : String, _to : String) -> String {
  let l = get_lang(lang)
  let s = value.to_string()
  let parts = s.split(".").map(fn (w) { w.to_owned() }).collect()
  let int_part = BigInt::from_string(parts[0])
  let mut out = l.cardinal(int_part)
  if parts.length() > 1 {
    out = out + " " + l.decimal
    let frac = parts[1]
    for i = 0; i < frac.length(); i = i + 1 {
      let d = BigInt::from_string(frac[i : i + 1].to_owned()).to_int()
      out = out + " " + l.ones[d]
    }
  }
  out
}

/// Spell a number given directly as a decimal/integer string, e.g.
/// `num2words_str("1234.56", "en", "cardinal")` ->
/// "one thousand, two hundred and thirty-four point five six".
/// Integer and arbitrarily large values are supported via `BigInt`.
pub fn num2words_str(value : String, lang : String, to : String) -> String {
  let l = get_lang(lang)
  let parts = value.split(".").map(fn (w) { w.to_owned() }).collect()
  if parts.length() > 1 {
    let int_part = BigInt::from_string(parts[0])
    let mut out = l.cardinal(int_part)
    out = out + " " + l.decimal
    let frac = parts[1]
    for i = 0; i < frac.length(); i = i + 1 {
      let d = BigInt::from_string(frac[i : i + 1].to_owned()).to_int()
      out = out + " " + l.ones[d]
    }
    out
  } else {
    num2words(BigInt::from_string(value), lang, to)
  }
}
