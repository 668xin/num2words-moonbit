// lang_currency.mbt — native currency mode for all seven languages.
//
// Amount semantics: the amount is a decimal *string* and the integer part is
// the major unit (12.34 = twelve euros and thirty-four cents). Upstream
// `num2words(1234, to="currency")` treats a bare int as *cents* (12.34) while
// `num2words(1234.0, ...)` treats it as 1234 units; that type-dependent quirk
// is not reproduced — see README / DIFF_REPORT.
//
// Rounding: exact decimal half-up on the third fractional digit. Upstream
// rounds through a binary float, so exact `x.xx5` inputs can differ (e.g.
// 1.005 -> upstream 1.00, here 1.01); such samples are excluded from the
// differential fixtures and the rule is documented.
//
// Languages differ in how the numeral agrees with the currency noun:
//   * es: feminine units and hundreds (una libra, doscientas libras) and the
//     apocope un/veintiún/treinta y un before the noun;
//   * ru: three plural forms plus gender (один рубль / два рубля / пять
//     рублей, одна копейка / две копейки);
//   * pt: only BRL, zero cents are omitted, and an exact multiple of 10^6
//     takes "de" (um milhão de reais).

// --- tables -----------------------------------------------------------------

///|
/// Noun forms for one currency. Russian uses the three plural forms; Spanish
/// uses `feminine` for numeral agreement, and every language selects a cent
/// form independently.
priv struct CurrencyForm {
  unit_one : String
  unit_few : String // Russian 2..4; a duplicate of `unit_many` elsewhere
  unit_many : String
  cent_one : String
  cent_few : String
  cent_many : String
  feminine : Bool
  cent_feminine : Bool
}

///|
fn currency_upper(code : String) -> String {
  let buf = StringBuilder()
  for i = 0; i < code.length(); i = i + 1 {
    let c = code[i]
    if c >= 97 && c <= 122 {
      buf.write_char((c - 32).to_char().unwrap())
    } else {
      buf.write_char(c.to_char().unwrap())
    }
  }
  buf.to_string()
}

///|
fn currency_entry(
  unit_one : String,
  unit_many : String,
  cent_one : String,
  cent_many : String,
  feminine : Bool,
) -> CurrencyForm {
  {
    unit_one,
    unit_few: unit_many,
    unit_many,
    cent_one,
    cent_few: cent_many,
    cent_many,
    feminine,
    cent_feminine: false,
  }
}

///|
fn currency_entry_ru(
  unit_one : String,
  unit_few : String,
  unit_many : String,
  cent_one : String,
  cent_few : String,
  cent_many : String,
  feminine : Bool,
  cent_feminine : Bool,
) -> CurrencyForm {
  {
    unit_one,
    unit_few,
    unit_many,
    cent_one,
    cent_few,
    cent_many,
    feminine,
    cent_feminine,
  }
}

///|
fn currency_form_en(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" => Ok(currency_entry("euro", "euro", "cent", "cents", false))
    "USD" => Ok(currency_entry("dollar", "dollars", "cent", "cents", false))
    "GBP" =>
      Ok(
        currency_entry(
          "pound sterling", "pounds sterling", "penny", "pence", false,
        ),
      )
    _ => Err(code)
  }
}

///|
fn currency_form_fr(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" => Ok(currency_entry("euro", "euros", "centime", "centimes", false))
    "USD" => Ok(currency_entry("dollar", "dollars", "cent", "cents", false))
    "GBP" => Ok(currency_entry("livre", "livres", "penny", "pence", false))
    _ => Err(code)
  }
}

///|
fn currency_form_de(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" => Ok(currency_entry("Euro", "Euro", "Cent", "Cent", false))
    "USD" => Ok(currency_entry("Dollar", "Dollar", "Cent", "Cent", false))
    "GBP" => Ok(currency_entry("Pfund", "Pfund", "Penny", "Pence", false))
    _ => Err(code)
  }
}

///|
fn currency_form_it(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" => Ok(currency_entry("euro", "euro", "centesimo", "centesimi", false))
    "USD" =>
      Ok(currency_entry("dollaro", "dollari", "centesimo", "centesimi", false))
    "GBP" => Ok(currency_entry("sterlina", "sterline", "penny", "penny", true))
    _ => Err(code)
  }
}

///|
/// Spanish currency forms. Upstream supports 20 codes here; `CNY` keeps its
/// irregular "un fen / dos jiaos" pair and `UAH` is treated as masculine.
fn currency_form_es(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" => Ok(currency_entry("euro", "euros", "céntimo", "céntimos", false))
    "USD" =>
      Ok(currency_entry("dólar", "dólares", "centavo", "centavos", false))
    "GBP" => Ok(currency_entry("libra", "libras", "penique", "peniques", true))
    "RUB" => Ok(currency_entry("rublo", "rublos", "kopeyka", "kopeykas", false))
    "JPY" => Ok(currency_entry("yen", "yenes", "sen", "sen", false))
    "CNY" => Ok(currency_entry("yuan", "yuanes", "fen", "jiaos", false))
    "CHF" =>
      Ok(currency_entry("franco", "francos", "céntimo", "céntimos", false))
    "CAD" =>
      Ok(currency_entry("dólar", "dólares", "centavo", "centavos", false))
    "AUD" =>
      Ok(currency_entry("dólar", "dólares", "centavo", "centavos", false))
    "BRL" => Ok(currency_entry("real", "reales", "centavo", "centavos", false))
    "INR" => Ok(currency_entry("rupia", "rupias", "paisa", "paisas", true))
    "KRW" => Ok(currency_entry("won", "wones", "jeon", "jeon", false))
    "SEK" => Ok(currency_entry("corona", "coronas", "öre", "öre", true))
    "NOK" => Ok(currency_entry("corona", "coronas", "øre", "øre", true))
    "PLN" => Ok(currency_entry("zloty", "zlotys", "grosz", "groszy", false))
    "UAH" =>
      Ok(currency_entry("hryvnia", "hryvnias", "kopiyka", "kopiykas", false))
    "KZT" => Ok(currency_entry("tenge", "tenges", "tïın", "tïın", false))
    "TRY" => Ok(currency_entry("lira", "liras", "kuruş", "kuruş", true))
    "MXN" => Ok(currency_entry("peso", "pesos", "centavo", "centavos", false))
    "ZAR" => Ok(currency_entry("rand", "rands", "céntimo", "céntimos", false))
    _ => Err(code)
  }
}

///|
/// Russian currency forms. Upstream supports six codes and declines both the
/// unit and the cent noun. `PLN` carries its adjective ("польский злотый");
/// upstream's 2..4 form contains a typo ("слотых"), which is normalised to
/// "злотых" here (see DIFF_REPORT).
fn currency_form_ru(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" =>
      Ok(
        currency_entry_ru(
          "евро", "евро", "евро", "цент", "цента", "центов",
          false, false,
        ),
      )
    "USD" =>
      Ok(
        currency_entry_ru(
          "доллар", "доллара", "долларов", "цент", "цента",
          "центов", false, false,
        ),
      )
    "RUB" =>
      Ok(
        currency_entry_ru(
          "рубль", "рубля", "рублей", "копейка", "копейки",
          "копеек", false, true,
        ),
      )
    "PLN" =>
      Ok(
        currency_entry_ru(
          "польский злотый", "польских злотых", "польских злотых",
          "грош", "гроша", "грошей", false, false,
        ),
      )
    "UAH" =>
      Ok(
        currency_entry_ru(
          "гривна", "гривны", "гривен", "копейка", "копейки",
          "копеек", true, true,
        ),
      )
    "KZT" =>
      Ok(
        currency_entry_ru(
          "тенге", "тенге", "тенге", "тиын", "тиына", "тиынов",
          false, false,
        ),
      )
    _ => Err(code)
  }
}

///|
/// Brazilian Portuguese only has BRL (upstream's `pt_BR.to_currency` takes no
/// currency code, and it is the only variant this project implements).
fn currency_form_pt(code : String) -> Result[CurrencyForm, String] {
  match code {
    "BRL" => Ok(currency_entry("real", "reais", "centavo", "centavos", false))
    _ => Err(code)
  }
}

///|
/// European Portuguese supports EUR/USD/GBP/CAD/AUD, always in "cêntimo(s)".
/// Upstream uses the masculine article with "libra" ("um libra") and the
/// singular "péni" (plural "pence"); both are preserved.
fn currency_form_pt_pt(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" => Ok(currency_entry("euro", "euros", "cêntimo", "cêntimos", false))
    "USD" =>
      Ok(currency_entry("dólar", "dólares", "cêntimo", "cêntimos", false))
    "GBP" => Ok(currency_entry("libra", "libras", "péni", "pence", false))
    "CAD" =>
      Ok(currency_entry("dólar", "dólares", "cêntimo", "cêntimos", false))
    "AUD" =>
      Ok(currency_entry("dólar", "dólares", "cêntimo", "cêntimos", false))
    _ => Err(code)
  }
}

///|
fn currency_supported_lang(lang : String) -> Bool {
  lang == "en" ||
  lang == "fr" ||
  lang == "de" ||
  lang == "it" ||
  lang == "es" ||
  lang == "pt" ||
  lang == "pt_PT" ||
  lang == "ru"
}

///|
fn currency_default_code(lang : String) -> String {
  if lang == "pt" {
    "BRL"
  } else {
    "EUR"
  }
}

///|
fn currency_form(lang : String, code : String) -> Result[CurrencyForm, String] {
  match lang {
    "en" => currency_form_en(code)
    "fr" => currency_form_fr(code)
    "de" => currency_form_de(code)
    "it" => currency_form_it(code)
    "es" => currency_form_es(code)
    "pt" => currency_form_pt(code)
    "pt_PT" => currency_form_pt_pt(code)
    "ru" => currency_form_ru(code)
    _ => Err(code)
  }
}

// --- amount parsing ---------------------------------------------------------

///|
fn currency_digit(s : String, i : Int) -> Int {
  s[i].to_int() - 48
}

///|
/// Parse `-?\d+(\.\d+)?` into (major units, cents 0..99, negative), rounding
/// the fraction half-up at the third digit.
fn parse_currency_amount(
  amount : String,
) -> Result[(BigInt, BigInt, Bool), String] {
  if !is_valid_number(amount) {
    return Err("invalid number: " + amount)
  }
  let neg = amount.length() > 0 && amount[0:1].to_owned() == "-"
  let body = if neg { amount[1:amount.length()].to_owned() } else { amount }
  let parts = body.split(".").map(fn(w) { w.to_owned() }).collect()
  let mut units = BigInt::from_string(parts[0])
  let mut cents = BigInt::from_int(0)
  if parts.length() > 1 {
    let frac = parts[1]
    let d0 = if frac.length() > 0 { currency_digit(frac, 0) } else { 0 }
    let d1 = if frac.length() > 1 { currency_digit(frac, 1) } else { 0 }
    cents = BigInt::from_int(d0 * 10 + d1)
    if frac.length() > 2 && currency_digit(frac, 2) >= 5 {
      cents = cents + BigInt::from_int(1)
    }
    if cents == BigInt::from_int(100) {
      cents = BigInt::from_int(0)
      units = units + BigInt::from_int(1)
    }
  }
  Ok((units, cents, neg))
}

// --- rendering --------------------------------------------------------------

///|
fn currency_pick(
  one : String,
  few : String,
  many : String,
  idx : Int,
) -> String {
  if idx == 0 {
    one
  } else if idx == 1 {
    few
  } else {
    many
  }
}

///|
/// 0 = one, 1 = few (Russian 2..4), 2 = many. Languages other than Russian
/// only distinguish one from the rest (zero uses the plural).
fn currency_form_index(lang : String, n : BigInt) -> Int {
  if lang == "ru" {
    let form = ru_form((n % BigInt::from_int(100)).to_int())
    if form == 1 {
      0
    } else if form == 2 {
      1
    } else {
      2
    }
  } else if n == BigInt::from_int(1) {
    0
  } else {
    2
  }
}

///|
/// Spanish numeral agreement before the currency noun: 1 -> un/una,
/// 21/31/... -> veintiún/veintiuna or ... y un/una, and the hundreds take
/// their feminine form. Upstream leaves "quinientos" masculine, which is
/// preserved here.
fn es_currency_num(n : BigInt, feminine : Bool) -> String {
  let card = get_lang("es").cardinal(n)
  let tokens = card.split(" ").map(fn(w) { w.to_owned() }).collect()
  let out : Array[String] = []
  for i = 0; i < tokens.length(); i = i + 1 {
    let t = tokens[i]
    let mapped = if t == "veintiuno" {
      if feminine {
        "veintiuna"
      } else {
        "veintiún"
      }
    } else if t == "uno" {
      if feminine {
        "una"
      } else {
        "un"
      }
    } else if feminine && t == "doscientos" {
      "doscientas"
    } else if feminine && t == "trescientos" {
      "trescientas"
    } else if feminine && t == "cuatrocientos" {
      "cuatrocientas"
    } else if feminine && t == "seiscientos" {
      "seiscientas"
    } else if feminine && t == "setecientos" {
      "setecientas"
    } else if feminine && t == "ochocientos" {
      "ochocientas"
    } else if feminine && t == "novecientos" {
      "novecientas"
    } else {
      t
    }
    out.push(mapped)
  }
  join_parts(out, " ")
}

///|
/// Spell the major/cents amount before the currency nouns. German drops the
/// final `s` of `eins` (`ein Euro`, `einhundertein`); Italian apocopates
/// `uno` (`un euro`, `ventun euro`) and agrees with feminine units; Spanish
/// and Russian agree with the noun's gender.
fn currency_num(lang : String, n : BigInt, feminine : Bool) -> String {
  let card = get_lang(lang).cardinal(n)
  if lang == "de" {
    if ends_with(card, "eins") {
      return card[0:card.length() - 4].to_owned() + "ein"
    }
    return card
  }
  if lang == "it" {
    if n == BigInt::from_int(1) {
      return if feminine { "una" } else { "un" }
    }
    if ends_with(card, "uno") {
      return card[0:card.length() - 3].to_owned() + "un"
    }
    return card
  }
  if lang == "es" {
    return es_currency_num(n, feminine)
  }
  if lang == "ru" {
    return get_lang("ru").cardinal_ru_gendered(n, feminine)
  }
  card
}

///|
fn currency_join(
  lang : String,
  left : String,
  unit : String,
  right : String,
  cent : String,
) -> String {
  match lang {
    "en" => left + " " + unit + ", " + right + " " + cent
    "fr" => left + " " + unit + " et " + right + " " + cent
    "de" => left + " " + unit + " und " + right + " " + cent
    "it" => left + " " + unit + " e " + right + " " + cent
    "es" => left + " " + unit + " con " + right + " " + cent
    "ru" => left + " " + unit + ", " + right + " " + cent
    _ => ""
  }
}

///|
/// Spell a currency amount. `code` is an ISO-4217 code (case-insensitive) or
/// `""` for the language default (EUR, or BRL for `pt`).
///
/// Supported code sets match upstream for `es`/`ru`/`pt`/`pt_PT`; the other
/// four currently cover EUR/USD/GBP, a subset of upstream's 11/4/4/4 codes
/// (see COMPAT.md).
///
/// Returns `Err` for malformed amounts, unsupported languages or codes, and
/// amounts past the language's scale table.
pub fn num2words_currency(
  amount : String,
  lang : String,
  code : String,
) -> Result[String, String] {
  match parse_currency_amount(amount) {
    Err(msg) => Err(msg)
    Ok((units, cents, neg)) => {
      if !currency_supported_lang(lang) {
        return Err("currency not implemented for language: " + lang)
      }
      let resolved = if code == "" {
        currency_default_code(lang)
      } else {
        currency_upper(code)
      }
      match currency_form(lang, resolved) {
        Err(c) => Err("currency code not supported for " + lang + ": " + c)
        Ok(form) => {
          let l = get_lang(lang)
          if !l.supports(units) {
            return Err("magnitude out of supported range: " + amount)
          }
          let unit = currency_pick(
            form.unit_one,
            form.unit_few,
            form.unit_many,
            currency_form_index(lang, units),
          )
          let cent = currency_pick(
            form.cent_one,
            form.cent_few,
            form.cent_many,
            currency_form_index(lang, cents),
          )
          let left = currency_num(lang, units, form.feminine)
          let right = currency_num(lang, cents, form.cent_feminine)
          // pt/pt_PT normally omit zero cents, but European Portuguese GBP
          // always spells them ("um libra e zero pence").
          let show_zero_cents = if lang == "pt" {
            false
          } else if lang == "pt_PT" {
            resolved == "GBP"
          } else {
            true
          }
          let core = if lang == "pt" || lang == "pt_PT" {
            // pt/pt_PT omit zero cents and use "de" for exact 10^6 multiples.
            let million = BigInt::from_int(1000000)
            let exact_million = units >= million &&
              units % million == BigInt::from_int(0)
            let mut phrase = if exact_million {
              left + " de " + unit
            } else {
              left + " " + unit
            }
            if cents > BigInt::from_int(0) || show_zero_cents {
              phrase = phrase + " e " + right + " " + cent
            }
            phrase
          } else {
            currency_join(lang, left, unit, right, cent)
          }
          // Upstream omits the sign when the rounded amount is exactly zero.
          let nonzero = units > BigInt::from_int(0) ||
            cents > BigInt::from_int(0)
          if neg && nonzero {
            Ok(l.negative + " " + core)
          } else {
            Ok(core)
          }
        }
      }
    }
  }
}
