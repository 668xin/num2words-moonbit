// lang_currency.mbt — native currency mode for all supported languages.
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
/// Same as `currency_entry` but lets the cent noun pick its own gender
/// (e.g. Spanish `EGP`: una libra / una piastra).
fn currency_entry_es(
  unit_one : String,
  unit_many : String,
  cent_one : String,
  cent_many : String,
  feminine : Bool,
  cent_feminine : Bool,
) -> CurrencyForm {
  {
    unit_one,
    unit_few: unit_many,
    unit_many,
    cent_one,
    cent_few: cent_many,
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
    "RUB" => Ok(currency_entry("rouble", "roubles", "kopek", "kopeks", false))
    "CAD" => Ok(currency_entry("dollar", "dollars", "cent", "cents", false))
    "AUD" => Ok(currency_entry("dollar", "dollars", "cent", "cents", false))
    "INR" => Ok(currency_entry("rupee", "rupees", "paisa", "paise", false))
    "SEK" => Ok(currency_entry("krona", "kronor", "öre", "öre", false))
    "NOK" => Ok(currency_entry("krone", "kroner", "øre", "øre", false))
    "PLN" => Ok(currency_entry("zloty", "zlotys", "grosz", "groszy", false))
    "MXN" => Ok(currency_entry("peso", "pesos", "cent", "cents", false))
    "BYN" => Ok(currency_entry("rouble", "roubles", "kopek", "kopeks", false))
    "EEK" => Ok(currency_entry("kroon", "kroons", "sent", "senti", false))
    "HUF" => Ok(currency_entry("forint", "forint", "fillér", "fillér", false))
    "ISK" => Ok(currency_entry("króna", "krónur", "aur", "aurar", false))
    "LTL" => Ok(currency_entry("litas", "litas", "cent", "cents", false))
    "LVL" => Ok(currency_entry("lat", "lats", "santim", "santims", false))
    "RON" => Ok(currency_entry("leu", "lei", "ban", "bani", false))
    "SAR" =>
      Ok(
        currency_entry(
          "saudi riyal", "saudi riyals", "halalah", "halalas", false,
        ),
      )
    "UZS" => Ok(currency_entry("sum", "sums", "tiyin", "tiyins", false))
    _ => Err(code)
  }
}

///|
fn currency_form_fr(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" => Ok(currency_entry("euro", "euros", "centime", "centimes", false))
    "USD" => Ok(currency_entry("dollar", "dollars", "cent", "cents", false))
    "GBP" => Ok(currency_entry("livre", "livres", "penny", "pence", false))
    "CNY" => Ok(currency_entry("yuan", "yuans", "fen", "jiaos", false))
    "FRF" => Ok(currency_entry("franc", "francs", "centime", "centimes", false))
    _ => Err(code)
  }
}

///|
fn currency_form_de(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" => Ok(currency_entry("Euro", "Euro", "Cent", "Cent", false))
    "USD" => Ok(currency_entry("Dollar", "Dollar", "Cent", "Cent", false))
    "GBP" => Ok(currency_entry("Pfund", "Pfund", "Penny", "Pence", false))
    "CNY" => Ok(currency_entry("Yuan", "Yuan", "Jiao", "Fen", false))
    "DEM" => Ok(currency_entry("Mark", "Mark", "Pfennig", "Pfennig", false))
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
    "CNY" => Ok(currency_entry("yuan", "yuan", "fen", "fen", false))
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
    "AED" =>
      Ok(currency_entry_es("dirham", "dirhams", "fils", "fils", false, false))
    "AFN" =>
      Ok(currency_entry_es("afghani", "afghanis", "pul", "puls", false, false))
    "ALL" =>
      Ok(
        currency_entry_es("lek ", "leke", "qindarkë", "qindarka", false, false),
      )
    "AMD" =>
      Ok(currency_entry_es("dram", "drams", "luma", "lumas", false, false))
    "ANG" =>
      Ok(
        currency_entry_es(
          "florín", "florines", "centavo", "centavos", false, false,
        ),
      )
    "AOA" =>
      Ok(
        currency_entry_es(
          "kwanza", "kwanzas", "céntimo", "céntimos", false, false,
        ),
      )
    "ARS" =>
      Ok(
        currency_entry_es("peso", "pesos", "centavo", "centavos", false, false),
      )
    "AWG" =>
      Ok(
        currency_entry_es(
          "florín", "florines", "centavo", "centavos", false, false,
        ),
      )
    "AZN" =>
      Ok(currency_entry_es("manat", "manat", "qəpik", "qəpik", false, false))
    "BBD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "centavo", "centavos", false, false,
        ),
      )
    "BDT" =>
      Ok(currency_entry_es("taka", "takas", "paisa", "paisas", false, false))
    "BGN" =>
      Ok(currency_entry_es("lev", "leva", "stotinka", "stotinki", false, false))
    "BHD" =>
      Ok(currency_entry_es("dinar", "dinares", "fils", "fils", false, false))
    "BIF" =>
      Ok(
        currency_entry_es(
          "franco", "francos", "céntimo", "céntimos", false, false,
        ),
      )
    "BMD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "centavo", "centavos", false, false,
        ),
      )
    "BND" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "centavo", "centavos", false, false,
        ),
      )
    "BOB" =>
      Ok(
        currency_entry_es(
          "boliviano", "bolivianos", "centavo", "centavos", false, false,
        ),
      )
    "BSD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "centavo", "centavos", false, false,
        ),
      )
    "BTN" =>
      Ok(
        currency_entry_es(
          "ngultrum", "ngultrum", "chetrum", "chetrum", false, false,
        ),
      )
    "BWP" =>
      Ok(currency_entry_es("pula", "pulas", "thebe", "thebes", false, false))
    "BYN" =>
      Ok(
        currency_entry_es("rublo", "rublos", "kópek", "kópeks", false, false),
      )
    "BYR" =>
      Ok(
        currency_entry_es("rublo", "rublos", "kópek", "kópeks", false, false),
      )
    "BZD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "CDF" =>
      Ok(
        currency_entry_es(
          "franco", "francos", "céntimo", "céntimos", false, false,
        ),
      )
    "CLP" =>
      Ok(
        currency_entry_es("peso", "pesos", "centavo", "centavos", false, false),
      )
    "COP" =>
      Ok(
        currency_entry_es("peso", "pesos", "centavo", "centavos", false, false),
      )
    "CRC" =>
      Ok(
        currency_entry_es(
          "colón", "colones", "centavo", "centavos", false, false,
        ),
      )
    "CUP" =>
      Ok(
        currency_entry_es("peso", "pesos", "centavo", "centavos", false, false),
      )
    "CVE" =>
      Ok(
        currency_entry_es(
          "escudo", "escudos", "centavo", "centavos", false, false,
        ),
      )
    "CYP" =>
      Ok(
        currency_entry_es(
          "libra", "libras", "céntimo", "céntimos", true, false,
        ),
      )
    "CZK" =>
      Ok(
        currency_entry_es(
          "corona", "coronas", "haléř", "haléř", true, false,
        ),
      )
    "DJF" =>
      Ok(
        currency_entry_es(
          "franco", "francos", "céntimo", "céntimos", false, false,
        ),
      )
    "DKK" =>
      Ok(currency_entry_es("corona", "coronas", "øre", "øre", true, false))
    "DOP" =>
      Ok(
        currency_entry_es("peso", "pesos", "centavo", "centavos", false, false),
      )
    "DZD" =>
      Ok(
        currency_entry_es(
          "dinar", "dinares", "céntimo", "céntimos", false, false,
        ),
      )
    "ECS" =>
      Ok(
        currency_entry_es(
          "sucre", "sucres", "centavo", "centavos", false, false,
        ),
      )
    "EGP" =>
      Ok(
        currency_entry_es("libra", "libras", "piastra", "piastras", true, true),
      )
    "ERN" =>
      Ok(
        currency_entry_es(
          "nakfa", "nakfas", "céntimo", "céntimos", false, false,
        ),
      )
    "ESP" =>
      Ok(
        currency_entry_es(
          "peseta", "pesetas", "céntimo", "céntimos", true, false,
        ),
      )
    "ETB" =>
      Ok(
        currency_entry_es(
          "birr", "birrs", "céntimo", "céntimos", false, false,
        ),
      )
    "FJD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "centavo", "centavos", false, false,
        ),
      )
    "FKP" =>
      Ok(
        currency_entry_es("libra", "libras", "penique", "peniques", true, false),
      )
    "FRF" =>
      Ok(
        currency_entry_es(
          "franco", "francos", "céntimo", "céntimos", false, false,
        ),
      )
    "GEL" =>
      Ok(currency_entry_es("lari", "laris", "tetri", "tetris", false, false))
    "GHS" =>
      Ok(currency_entry_es("cedi", "cedis", "pesewa", "pesewas", false, false))
    "GIP" =>
      Ok(
        currency_entry_es("libra", "libras", "penique", "peniques", true, false),
      )
    "GMD" =>
      Ok(
        currency_entry_es("dalasi", "dalasis", "butut", "bututs", false, false),
      )
    "GNF" =>
      Ok(
        currency_entry_es(
          "franco", "francos", "céntimo", "céntimos", false, false,
        ),
      )
    "GTQ" =>
      Ok(
        currency_entry_es(
          "quetzal", "quetzales", "centavo", "centavos", false, false,
        ),
      )
    "GYD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "centavo", "centavos", false, false,
        ),
      )
    "HKD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "centavo", "centavos", false, false,
        ),
      )
    "HNL" =>
      Ok(
        currency_entry_es(
          "lempira", "lempiras", "centavo", "centavos", false, false,
        ),
      )
    "HRK" =>
      Ok(currency_entry_es("kuna", "kunas", "lipa", "lipas", false, false))
    "HTG" =>
      Ok(
        currency_entry_es(
          "gourde", "gourdes", "céntimo", "céntimos", false, false,
        ),
      )
    "HUF" =>
      Ok(
        currency_entry_es(
          "florín", "florines", "fillér", "fillér", false, false,
        ),
      )
    "IDR" =>
      Ok(
        currency_entry_es(
          "rupia", "rupias", "céntimo", "céntimos", true, false,
        ),
      )
    "ILS" =>
      Ok(
        currency_entry_es(
          "séquel", "séqueles", "agora", "agoras", false, false,
        ),
      )
    "IQD" =>
      Ok(currency_entry_es("dinar", "dinares", "fils", "fils", false, false))
    "IRR" =>
      Ok(currency_entry_es("rial", "riales", "dinar", "dinares", false, false))
    "ISK" =>
      Ok(currency_entry_es("corona", "coronas", "eyrir", "aurar", true, false))
    "ITL" =>
      Ok(
        currency_entry_es("lira", "liras", "céntimo", "céntimos", true, false),
      )
    "JMD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "JOD" =>
      Ok(
        currency_entry_es(
          "dinar", "dinares", "piastra", "piastras", false, true,
        ),
      )
    "KES" =>
      Ok(
        currency_entry_es(
          "chelín", "chelines", "céntimo", "céntimos", false, false,
        ),
      )
    "KGS" => Ok(currency_entry_es("som", "som", "tyiyn", "tyiyn", false, false))
    "KHR" =>
      Ok(
        currency_entry_es(
          "riel", "rieles", "céntimo", "céntimos", false, false,
        ),
      )
    "KMF" =>
      Ok(
        currency_entry_es(
          "franco", "francos", "céntimo", "céntimos", false, false,
        ),
      )
    "KPW" => Ok(currency_entry_es("won", "wones", "chon", "chon", false, false))
    "KWD" =>
      Ok(currency_entry_es("dinar", "dinares", "fils", "fils", false, false))
    "KYD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "LAK" => Ok(currency_entry_es("kip", "kips", "att", "att", false, false))
    "LBP" =>
      Ok(
        currency_entry_es("libra", "libras", "piastra", "piastras", true, true),
      )
    "LKR" =>
      Ok(
        currency_entry_es(
          "rupia", "rupias", "céntimo", "céntimos", true, false,
        ),
      )
    "LRD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "LSL" =>
      Ok(
        currency_entry_es(
          "loti", "lotis", "céntimo", "céntimos", false, false,
        ),
      )
    "LTL" =>
      Ok(
        currency_entry_es(
          "lita", "litas", "céntimo", "céntimos", false, false,
        ),
      )
    "LVL" =>
      Ok(
        currency_entry_es("lat", "lats", "céntimo", "céntimos", false, false),
      )
    "LYD" =>
      Ok(
        currency_entry_es(
          "dinar", "dinares", "dírham", "dírhams", false, false,
        ),
      )
    "MAD" =>
      Ok(
        currency_entry_es(
          "dírham", "dirhams", "céntimo", "céntimos", false, false,
        ),
      )
    "MDL" => Ok(currency_entry_es("leu", "lei", "ban", "bani", false, false))
    "MGA" =>
      Ok(
        currency_entry_es(
          "ariary", "ariaris", "iraimbilanja", "iraimbilanja", false, false,
        ),
      )
    "MKD" =>
      Ok(currency_entry_es("denar", "denares", "deni", "denis", false, false))
    "MMK" => Ok(currency_entry_es("kiat", "kiats", "pya", "pyas", false, false))
    "MNT" =>
      Ok(
        currency_entry_es(
          "tugrik", "tugriks", "möngö", "möngö", false, false,
        ),
      )
    "MOP" =>
      Ok(currency_entry_es("pataca", "patacas", "avo", "avos", false, false))
    "MRO" =>
      Ok(
        currency_entry_es(
          "ouguiya", "ouguiyas", "khoums", "khoums", false, false,
        ),
      )
    "MRU" =>
      Ok(
        currency_entry_es(
          "ouguiya", "ouguiyas", "khoums", "khoums", false, false,
        ),
      )
    "MUR" =>
      Ok(
        currency_entry_es(
          "rupia", "rupias", "céntimo", "céntimos", true, false,
        ),
      )
    "MVR" =>
      Ok(
        currency_entry_es("rufiyaa", "rufiyaas", "laari", "laari", false, false),
      )
    "MWK" =>
      Ok(
        currency_entry_es(
          "kuacha", "kuachas", "tambala", "tambalas", false, false,
        ),
      )
    "MYR" =>
      Ok(
        currency_entry_es(
          "ringgit", "ringgit", "céntimo", "céntimos", false, false,
        ),
      )
    "MZN" =>
      Ok(
        currency_entry_es(
          "metical", "metical", "centavo", "centavos", false, false,
        ),
      )
    "NAD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "NGN" =>
      Ok(currency_entry_es("naira", "nairas", "kobo", "kobo", false, false))
    "NIO" =>
      Ok(
        currency_entry_es(
          "córdoba", "córdobas", "centavo", "centavos", false, false,
        ),
      )
    "NPR" =>
      Ok(currency_entry_es("rupia", "rupias", "paisa", "paisas", true, false))
    "NZD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "centavo", "centavos", false, false,
        ),
      )
    "OMR" =>
      Ok(currency_entry_es("rial", "riales", "baisa", "baisa", false, false))
    "PAB" =>
      Ok(
        currency_entry_es(
          "balboa", "balboas", "centésimo", "centésimos", false, false,
        ),
      )
    "PEN" =>
      Ok(
        currency_entry_es("sol", "soles", "céntimo", "céntimos", false, false),
      )
    "PGK" =>
      Ok(currency_entry_es("kina", "kinas", "toea", "toea", false, false))
    "PHP" =>
      Ok(
        currency_entry_es("peso", "pesos", "centavo", "centavos", false, false),
      )
    "PKR" =>
      Ok(currency_entry_es("rupia", "rupias", "paisa", "paisas", true, false))
    "PLZ" =>
      Ok(currency_entry_es("zloty", "zlotys", "grosz", "groszy", false, false))
    "PYG" =>
      Ok(
        currency_entry_es(
          "guaraní", "guaranís", "céntimo", "céntimos", false, false,
        ),
      )
    "QAR" =>
      Ok(
        currency_entry_es("rial", "riales", "dírham", "dírhams", false, false),
      )
    "QTQ" =>
      Ok(
        currency_entry_es(
          "quetzal", "quetzales", "centavo", "centavos", false, false,
        ),
      )
    "RON" => Ok(currency_entry_es("leu", "leus", "ban", "bani", false, false))
    "RSD" =>
      Ok(currency_entry_es("dinar", "dinares", "para", "para", false, false))
    "RUR" =>
      Ok(currency_entry_es("rublo", "rublos", "kopek", "kopeks", false, false))
    "RWF" =>
      Ok(
        currency_entry_es(
          "franco", "francos", "céntimo", "céntimos", false, false,
        ),
      )
    "SAR" =>
      Ok(
        currency_entry_es("riyal", "riales", "halala", "halalas", false, false),
      )
    "SBD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "SCR" =>
      Ok(
        currency_entry_es(
          "rupia", "rupias", "céntimo", "céntimos", true, false,
        ),
      )
    "SDG" =>
      Ok(
        currency_entry_es("libra", "libras", "piastra", "piastras", true, true),
      )
    "SGD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "SHP" =>
      Ok(
        currency_entry_es("libra", "libras", "penique", "peniques", true, false),
      )
    "SKK" =>
      Ok(
        currency_entry_es("corona", "coronas", "halier", "haliers", true, false),
      )
    "SLL" =>
      Ok(
        currency_entry_es(
          "leona", "leonas", "céntimo", "céntimos", true, false,
        ),
      )
    "SRD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "SSP" =>
      Ok(
        currency_entry_es("libra", "libras", "piastra", "piastras", true, true),
      )
    "STD" =>
      Ok(
        currency_entry_es(
          "dobra", "dobras", "céntimo", "céntimos", false, false,
        ),
      )
    "SVC" =>
      Ok(
        currency_entry_es(
          "colón", "colones", "centavo", "centavos", false, false,
        ),
      )
    "SYP" =>
      Ok(
        currency_entry_es("libra", "libras", "piastra", "piastras", true, true),
      )
    "SZL" =>
      Ok(
        currency_entry_es(
          "lilangeni", "emalangeni", "céntimo", "céntimos", false, false,
        ),
      )
    "THB" =>
      Ok(currency_entry_es("baht", "bahts", "satang", "satang", false, false))
    "TJS" =>
      Ok(
        currency_entry_es(
          "somoni", "somonis", "dirame", "dirames", false, false,
        ),
      )
    "TMT" =>
      Ok(currency_entry_es("manat", "manat", "tenge", "tenge", false, false))
    "TND" =>
      Ok(
        currency_entry_es(
          "dinar", "dinares", "milésimo", "milésimos", false, false,
        ),
      )
    "TOP" =>
      Ok(
        currency_entry_es(
          "paanga", "paangas", "céntimo", "céntimos", false, false,
        ),
      )
    "TTD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "TWD" =>
      Ok(
        currency_entry_es(
          "nuevo dólar", "nuevos dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "TZS" =>
      Ok(
        currency_entry_es(
          "chelín", "chelines", "céntimo", "céntimos", false, false,
        ),
      )
    "UAG" =>
      Ok(
        currency_entry_es(
          "hryvnia", "hryvnias", "kopiyka", "kopiykas", false, false,
        ),
      )
    "UGX" =>
      Ok(
        currency_entry_es(
          "chelín", "chelines", "céntimo", "céntimos", false, false,
        ),
      )
    "UYU" =>
      Ok(
        currency_entry_es(
          "peso", "pesos", "centésimo", "centésimos", false, false,
        ),
      )
    "UZS" => Ok(currency_entry_es("sum", "sum", "tiyin", "tiyin", false, false))
    "VEF" =>
      Ok(
        currency_entry_es(
          "bolívar fuerte", "bolívares fuertes", "céntimo", "céntimos", false,
          false,
        ),
      )
    "VES" =>
      Ok(
        currency_entry_es(
          "bolívar", "bolívares", "céntimo", "céntimos", false, false,
        ),
      )
    "VND" => Ok(currency_entry_es("dong", "dongs", "xu", "xu", false, false))
    "VUV" =>
      Ok(currency_entry_es("vatu", "vatu", "nenhum", "nenhum", false, false))
    "WST" =>
      Ok(currency_entry_es("tala", "tala", "centavo", "centavos", false, false))
    "XAF" =>
      Ok(
        currency_entry_es(
          "franco CFA", "francos CFA", "céntimo", "céntimos", false, false,
        ),
      )
    "XCD" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
    "XOF" =>
      Ok(
        currency_entry_es(
          "franco CFA", "francos CFA", "céntimo", "céntimos", false, false,
        ),
      )
    "XPF" =>
      Ok(
        currency_entry_es(
          "franco CFP", "francos CFP", "céntimo", "céntimos", false, false,
        ),
      )
    "YER" =>
      Ok(currency_entry_es("rial", "riales", "fils", "fils", false, false))
    "YUM" =>
      Ok(currency_entry_es("dinar", "dinares", "para", "para", false, false))
    "ZMW" =>
      Ok(currency_entry_es("kwacha", "kwachas", "ngwee", "ngwee", false, false))
    "ZRZ" =>
      Ok(currency_entry_es("zaire", "zaires", "likuta", "makuta", false, false))
    "ZWL" =>
      Ok(
        currency_entry_es(
          "dólar", "dólares", "céntimo", "céntimos", false, false,
        ),
      )
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
    "BYN" =>
      Ok(
        currency_entry_ru(
          "белорусский рубль", "белорусских рубля",
          "белорусских рублей", "копейка", "копейки",
          "копеек", false, true,
        ),
      )
    "UZS" =>
      Ok(
        currency_entry_ru(
          "сум", "сума", "сумов", "тийин", "тийина", "тийинов",
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
/// Dutch currency forms. Upstream's `pluralize` always returns the singular
/// form, so both the unit and the cent noun are invariant ("twee euro",
/// "twee cent", "twee penny").
fn currency_form_nl(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" => Ok(currency_entry("euro", "euro", "cent", "cent", false))
    "GBP" => Ok(currency_entry("pond", "pond", "penny", "penny", false))
    "USD" => Ok(currency_entry("dollar", "dollar", "cent", "cent", false))
    "CNY" => Ok(currency_entry("yuan", "yuan", "jiao", "jiao", false))
    _ => Err(code)
  }
}

///|
/// Turkish has a single hard-coded currency pair upstream (`to_currency`
/// accepts no code and always uses lira/kuruş), so only TRY is exposed.
fn currency_form_tr(code : String) -> Result[CurrencyForm, String] {
  match code {
    "TRY" => Ok(currency_entry("lira", "lira", "kuruş", "kuruş", false))
    _ => Err(code)
  }
}

///|
/// Czech currency forms: CZK and EUR.
fn currency_form_cs(code : String) -> Result[CurrencyForm, String] {
  match code {
    "CZK" =>
      Ok(
        currency_entry_ru(
          "koruna", "koruny", "korun", "halíř", "halíře", "haléřů", false,
          false,
        ),
      )
    "EUR" =>
      Ok(
        currency_entry_ru(
          "euro", "euro", "euro", "cent", "centy", "centů", false, false,
        ),
      )
    _ => Err(code)
  }
}

///|
/// Slovak only implements EUR upstream.
fn currency_form_sk(code : String) -> Result[CurrencyForm, String] {
  match code {
    "EUR" =>
      Ok(
        currency_entry_ru(
          "euro", "eurá", "eur", "cent", "centy", "centov", false, false,
        ),
      )
    _ => Err(code)
  }
}

///|
/// Serbian currency forms: RUB, EUR and RSD. `rublja`/`kopejka`/`para` are
/// feminine, `evro`/`cent`/`dinar` masculine.
fn currency_form_sr(code : String) -> Result[CurrencyForm, String] {
  match code {
    "RUB" =>
      Ok(
        currency_entry_ru(
          "rublja", "rublje", "rublji", "kopejka", "kopejke", "kopejki", true, true,
        ),
      )
    "EUR" =>
      Ok(
        currency_entry_ru(
          "evro", "evra", "evra", "cent", "centa", "centi", false, false,
        ),
      )
    "RSD" =>
      Ok(
        currency_entry_ru(
          "dinar", "dinara", "dinara", "para", "pare", "para", false, true,
        ),
      )
    _ => Err(code)
  }
}

///|
/// Lithuanian currency forms. RUB cents take feminine numerals ("viena
/// kapeika"), everything else is masculine.
fn currency_form_lt(code : String) -> Result[CurrencyForm, String] {
  match code {
    "LTL" =>
      Ok(
        currency_entry_ru(
          "litas", "litai", "litų", "centas", "centai", "centų", false, false,
        ),
      )
    "EUR" =>
      Ok(
        currency_entry_ru(
          "euras", "eurai", "eurų", "centas", "centai", "centų", false, false,
        ),
      )
    "USD" =>
      Ok(
        currency_entry_ru(
          "doleris", "doleriai", "dolerių", "centas", "centai", "centų", false,
          false,
        ),
      )
    "GBP" =>
      Ok(
        currency_entry_ru(
          "svaras sterlingų", "svarai sterlingų", "svarų sterlingų", "pensas",
          "pensai", "pensų", false, false,
        ),
      )
    "PLN" =>
      Ok(
        currency_entry_ru(
          "zlotas", "zlotai", "zlotų", "grašis", "grašiai", "grašių", false,
          false,
        ),
      )
    "RUB" =>
      Ok(
        currency_entry_ru(
          "rublis", "rubliai", "rublių", "kapeika", "kapeikos", "kapeikų", false,
          true,
        ),
      )
    _ => Err(code)
  }
}

///|
/// Azerbaijani implements AZN only.
fn currency_form_az(code : String) -> Result[CurrencyForm, String] {
  match code {
    "AZN" => Ok(currency_entry("manat", "manat", "qəpik", "qəpik", false))
    _ => Err(code)
  }
}

///|
/// Belarusian: the unit noun is feminine for UAH (грыўна) and the cent noun
/// is feminine for RUB / BYN / UAH (капейка), which the two gender flags
/// express. EUR/KZT nouns are invariant across forms.
fn currency_form_be(code : String) -> Result[CurrencyForm, String] {
  match code {
    "RUB" =>
      Ok(
        currency_entry_ru(
          "расійскі рубель", "расійскія рублі", "расійскіх рублёў",
          "капейка", "капейкі", "капеек", false, true,
        ),
      )
    "EUR" =>
      Ok(
        currency_entry_ru(
          "еўра", "еўра", "еўра", "цэнт", "цэнты", "цэнтаў",
          false, false,
        ),
      )
    "USD" =>
      Ok(
        currency_entry_ru(
          "долар", "долары", "долараў", "цэнт", "цэнты",
          "цэнтаў", false, false,
        ),
      )
    "UAH" =>
      Ok(
        currency_entry_ru(
          "грыўна", "грыўны", "грыўнаў", "капейка", "капейкі",
          "капеек", true, true,
        ),
      )
    "KZT" =>
      Ok(
        currency_entry_ru(
          "тэнге", "тэнге", "тэнге", "тыйін", "тыйіны",
          "тыйінаў", false, false,
        ),
      )
    "BYN" =>
      Ok(
        currency_entry_ru(
          "беларускі рубель", "беларускія рублі", "беларускіх рублёў",
          "капейка", "капейкі", "капеек", false, true,
        ),
      )
    "UZS" =>
      Ok(
        currency_entry_ru(
          "сум", "сумы", "сумаў", "тыйін", "тыйіны", "тыйінаў",
          false, false,
        ),
      )
    "PLN" =>
      Ok(
        currency_entry_ru(
          "злоты", "злотых", "злотых", "грош", "грошы",
          "грошаў", false, false,
        ),
      )
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
  lang == "ru" ||
  lang == "nl" ||
  lang == "tr" ||
  lang == "zh" ||
  lang == "zh_TW" ||
  lang == "ja" ||
  lang == "ko" ||
  lang == "no" ||
  lang == "da" ||
  lang == "id" ||
  lang == "fi" ||
  lang == "ro" ||
  lang == "hu" ||
  lang == "he" ||
  lang == "fa" ||
  lang == "eo" ||
  lang == "cs" ||
  lang == "sk" ||
  lang == "sr" ||
  lang == "lt" ||
  lang == "az" ||
  lang == "be"
}

///|
fn currency_default_code(lang : String) -> String {
  if lang == "pt" {
    "BRL"
  } else if lang == "tr" {
    "TRY"
  } else if lang == "zh" || lang == "zh_TW" {
    // Upstream master's Chinese `to_currency` defaults to "XXX" (plain 元).
    "XXX"
  } else if lang == "ja" {
    "JPY"
  } else if lang == "ko" {
    "KRW"
  } else if lang == "no" {
    "NOK"
  } else if lang == "da" {
    "DKK"
  } else if lang == "id" {
    "IDR"
  } else if lang == "ro" {
    "RON"
  } else if lang == "hu" {
    "HUF"
  } else if lang == "he" {
    "ILS"
  } else if lang == "az" {
    "AZN"
  } else if lang == "fa" {
    // Persian `to_currency` takes no code; the value is only used by the
    // documentation and ignored by `currency_fa`.
    "IRR"
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
    "nl" => currency_form_nl(code)
    "tr" => currency_form_tr(code)
    "cs" => currency_form_cs(code)
    "sk" => currency_form_sk(code)
    "sr" => currency_form_sr(code)
    "lt" => currency_form_lt(code)
    "az" => currency_form_az(code)
    "be" => currency_form_be(code)
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
/// 0 = one, 1 = few (Slavic/Baltic 2..4), 2 = many. Languages without a
/// distinct paucal form only distinguish one from the rest (zero uses the
/// plural).
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
  } else if lang == "cs" {
    // 1 -> one; 2..4 (not 12..14, 112..114, ...) -> few; else many.
    if n == BigInt::from_int(1) {
      0
    } else {
      let m10 = (n % BigInt::from_int(10)).to_int()
      let m100 = (n % BigInt::from_int(100)).to_int()
      if m10 > 1 && m10 < 5 && (m100 < 10 || m100 > 20) {
        1
      } else {
        2
      }
    }
  } else if lang == "sk" {
    // 1 -> one; 2..4 -> few; everything else (incl. 21) -> many.
    if n == BigInt::from_int(1) {
      0
    } else if n > BigInt::from_int(1) && n < BigInt::from_int(5) {
      1
    } else {
      2
    }
  } else if lang == "sr" || lang == "be" {
    // ...1 -> one; ...2..4 (not 12..14, 112..114, ...) -> few; else many.
    let m10 = (n % BigInt::from_int(10)).to_int()
    let m100 = (n % BigInt::from_int(100)).to_int()
    if m100 < 10 || m100 > 20 {
      if m10 == 1 {
        0
      } else if m10 > 1 && m10 < 5 {
        1
      } else {
        2
      }
    } else {
      2
    }
  } else if lang == "lt" {
    // ...1 -> one; ...2..9 -> few; 0 and 10..19 -> many.
    let n1 = (n % BigInt::from_int(10)).to_int()
    let n2 = (n / BigInt::from_int(10) % BigInt::from_int(10)).to_int()
    if n2 == 1 || n1 == 0 || n == BigInt::from_int(0) {
      2
    } else if n1 == 1 {
      0
    } else {
      1
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
  if lang == "sr" {
    return cardinal_sr_gendered(get_lang("sr"), n, feminine)
  }
  if lang == "lt" {
    return cardinal_lt_gendered(get_lang("lt"), n, feminine)
  }
  if lang == "be" {
    return cardinal_be_gendered(get_lang("be"), n, if feminine { 1 } else { 0 })
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
    "nl" => left + " " + unit + ", " + right + " " + cent
    "cs" => left + " " + unit + ", " + right + " " + cent
    "sk" => left + " " + unit + ", " + right + " " + cent
    "sr" => left + " " + unit + ", " + right + " " + cent
    "lt" => left + " " + unit + ", " + right + " " + cent
    "az" => left + " " + unit + ", " + right + " " + cent
    "be" => left + " " + unit + ", " + right + " " + cent
    _ => ""
  }
}

// --- CJK currency -----------------------------------------------------------
//
// Chinese, Japanese and Korean do not inflect the currency noun, so they use
// their own renderers instead of `CurrencyForm`. Chinese is ported from
// upstream master's `lang_ZH.py` (the module postdates 0.5.14); Japanese and
// Korean follow 0.5.14.

///|
/// True when the decimal string carries a non-zero fractional digit
/// (`1.004` -> true). Japanese refuses any fraction, even one that would round
/// to zero cents.
fn currency_fraction_nonzero(amount : String) -> Bool {
  let parts = amount.split(".").map(fn(w) { w.to_owned() }).collect()
  if parts.length() < 2 {
    return false
  }
  let frac = parts[1]
  for i = 0; i < frac.length(); i = i + 1 {
    if frac[i:i + 1].to_owned() != "0" {
      return true
    }
  }
  false
}

///|
/// Chinese currency name (the prefix before the amount). `XXX` has none.
fn currency_zh_name(
  code : String,
  traditional : Bool,
) -> Result[String, String] {
  match code {
    "XXX" => Ok("")
    "CNY" => Ok(if traditional { "人民幣" } else { "人民币" })
    "NTD" => Ok(if traditional { "新台幣" } else { "新台币" })
    "HKD" => Ok(if traditional { "港幣" } else { "港币" })
    "MOP" => Ok(if traditional { "澳門幣" } else { "澳门币" })
    "SGD" => Ok("新加坡元")
    "MYR" =>
      Ok(if traditional { "馬來西亞令吉" } else { "马来西亚令吉" })
    "USD" => Ok("美元")
    "EUR" => Ok(if traditional { "歐元" } else { "欧元" })
    "GBP" => Ok(if traditional { "英鎊" } else { "英镑" })
    "JPY" => Ok("日元")
    "CHF" => Ok("瑞士法郎")
    "CAD" => Ok("加元")
    "AUD" => Ok(if traditional { "澳幣" } else { "澳币" })
    "NZD" => Ok(if traditional { "紐西蘭元" } else { "纽西兰元" })
    "THB" => Ok(if traditional { "泰銖" } else { "泰铢" })
    "KRW" => Ok(if traditional { "韓元" } else { "韩元" })
    _ => Err(code)
  }
}

///|
/// `角`/`分` tail: 5 -> 零五分, 50 -> 五角, 56 -> 五角六分.
fn currency_zh_cents(l : Lang, cents : BigInt) -> String {
  if cents == BigInt::from_int(0) {
    return ""
  }
  let c = cents.to_int()
  let jiao = c / 10
  let fen = c % 10
  let mut out = l.ones[jiao]
  if jiao > 0 {
    out = out + "角"
  }
  if fen > 0 {
    out = out + l.ones[fen] + "分"
  }
  out
}

///|
fn currency_zh(
  units : BigInt,
  cents : BigInt,
  neg : Bool,
  lang : String,
  code : String,
) -> Result[String, String] {
  let traditional = lang == "zh_TW"
  let l = get_lang(lang)
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  match currency_zh_name(code, traditional) {
    Err(c) => Err("currency code not supported for " + lang + ": " + c)
    Ok(name) => {
      let nonzero = units > BigInt::from_int(0) || cents > BigInt::from_int(0)
      let sign = if neg && nonzero { l.negative } else { "" }
      Ok(name + sign + l.cardinal(units) + "元" + currency_zh_cents(l, cents))
    }
  }
}

///|
/// Japanese only knows JPY and rejects every fractional amount.
fn currency_ja(
  amount : String,
  units : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  if code != "JPY" {
    return Err("currency code not supported for ja: " + code)
  }
  if currency_fraction_nonzero(amount) {
    return Err("decimals not supported for " + code)
  }
  let l = get_lang("ja")
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let sign = if neg && units > BigInt::from_int(0) { l.negative } else { "" }
  Ok(sign + l.cardinal(units) + "円")
}

///|
/// Korean knows KRW/JPY (no cents) and USD (원/달러/엔, with 센트).
fn currency_ko(
  units : BigInt,
  cents : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  let (unit, cent) = match code {
    "KRW" => ("원", "")
    "USD" => ("달러", "센트")
    "JPY" => ("엔", "")
    _ => return Err("currency code not supported for ko: " + code)
  }
  if cents != BigInt::from_int(0) && cent == "" {
    return Err("decimals not supported for " + code)
  }
  let l = get_lang("ko")
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let nonzero = units > BigInt::from_int(0) || cents > BigInt::from_int(0)
  let sign = if neg && nonzero { l.negative + " " } else { "" }
  let mut body = join_parts(split_to_array(l.cardinal(units), " "), "") + unit
  if cent != "" {
    body = body + " " + l.cardinal(cents) + cent
  }
  Ok(sign + body)
}

///|
/// Spell a currency amount. `code` is an ISO-4217 code (case-insensitive) or
/// `""` for the language default (EUR, or BRL for `pt`).
///
/// Supported code sets match upstream for every language (see COMPAT.md §4).
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
      // Persian `to_currency` accepts no ISO code and reads the amount as a
      // decimal (fractions keep their denominator words), so it is handled
      // before the generic rounding path.
      if lang == "fa" {
        if code != "" {
          return Err("currency code not supported for fa: " + code)
        }
        return currency_fa(amount)
      }
      let resolved = if code == "" {
        currency_default_code(lang)
      } else {
        currency_upper(code)
      }
      // Languages whose currency grammar does not fit `CurrencyForm`:
      // Romanian uses a three-way scale inflection plus the "una" multiplier,
      // Hungarian and Esperanto only distinguish one-from-many, and Hebrew
      // needs per-code gender and the construct state.
      if lang == "ro" {
        return currency_ro(units, cents, neg, resolved)
      }
      if lang == "hu" {
        return currency_hu(units, cents, neg, resolved)
      }
      if lang == "he" {
        return currency_he(units, cents, neg, resolved)
      }
      if lang == "eo" {
        return currency_eo(units, cents, neg, resolved)
      }
      // CJK languages use dedicated renderers: no plural/gender agreement and
      // their own decimal-unit rules (元/角/分, JPY without cents, KRW/USD).
      if lang == "zh" || lang == "zh_TW" {
        return currency_zh(units, cents, neg, lang, resolved)
      }
      if lang == "ja" {
        return currency_ja(amount, units, neg, resolved)
      }
      if lang == "ko" {
        return currency_ko(units, cents, neg, resolved)
      }
      if lang == "no" {
        return currency_no(units, cents, neg, resolved)
      }
      if lang == "da" {
        return currency_da(amount, units, cents, neg, resolved)
      }
      if lang == "id" {
        return currency_id(units, cents, neg, resolved)
      }
      if lang == "fi" {
        return currency_fi(units, cents, neg, resolved)
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
          let nonzero = units > BigInt::from_int(0) ||
            cents > BigInt::from_int(0)
          // Turkish writes one word, drops the kuruş part when it is zero, and
          // says "bedelsiz" for an exact zero amount (upstream's behaviour).
          if lang == "tr" {
            if !nonzero {
              return Ok("bedelsiz")
            }
            let mut phrase = left + unit
            if cents > BigInt::from_int(0) {
              phrase = phrase + right + cent
            }
            if neg {
              return Ok("eksi" + phrase)
            }
            return Ok(phrase)
          }
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
