// Whitebox tests for num2words-moonbit.
// Compiled inside the package, so no `import` is needed and every top-level
// function (including the per-language helpers) is in scope directly.
// Run with `moon test` from the project root.

///|
test "en cardinal basics" {
  assert_eq(num2words_int(0, "en", "cardinal"), "zero")
  assert_eq(num2words_int(1, "en", "cardinal"), "one")
  assert_eq(num2words_int(42, "en", "cardinal"), "forty-two")
  assert_eq(num2words_int(100, "en", "cardinal"), "one hundred")
  assert_eq(num2words_int(101, "en", "cardinal"), "one hundred and one")
  assert_eq(num2words_int(110, "en", "cardinal"), "one hundred and ten")
  assert_eq(
    num2words_int(1234, "en", "cardinal"),
    "one thousand, two hundred and thirty-four",
  )
  assert_eq(num2words_int(-42, "en", "cardinal"), "minus forty-two")
}

///|
test "en cardinal groups" {
  assert_eq(num2words_int(1000001, "en", "cardinal"), "one million and one")
  assert_eq(num2words_int(1001, "en", "cardinal"), "one thousand and one")
  assert_eq(
    num2words_int(2024, "en", "cardinal"),
    "two thousand and twenty-four",
  )
  assert_eq(
    num2words_int(1234567, "en", "cardinal"),
    "one million, two hundred and thirty-four thousand, five hundred and sixty-seven",
  )
  assert_eq(
    num2words(BigInt::from_string("1000000000"), "en", "cardinal"),
    "one billion",
  )
}

///|
test "en ordinal" {
  assert_eq(ordinal_en(BigInt::from_int(1)), "first")
  assert_eq(ordinal_en(BigInt::from_int(2)), "second")
  assert_eq(ordinal_en(BigInt::from_int(3)), "third")
  assert_eq(ordinal_en(BigInt::from_int(4)), "fourth")
  assert_eq(ordinal_en(BigInt::from_int(11)), "eleventh")
  assert_eq(ordinal_en(BigInt::from_int(12)), "twelfth")
  assert_eq(ordinal_en(BigInt::from_int(21)), "twenty-first")
  assert_eq(ordinal_en(BigInt::from_int(100)), "one hundredth")
  assert_eq(ordinal_en(BigInt::from_int(101)), "one hundred and first")
  // scale ordinals beyond the common table (10^21)
  assert_eq(
    ordinal_en(BigInt::from_string("1000000000000000000000")),
    "one sextillionth",
  )
}

///|
test "en ordinal_num" {
  assert_eq(ordinal_num_en(BigInt::from_int(1)), "1st")
  assert_eq(ordinal_num_en(BigInt::from_int(2)), "2nd")
  assert_eq(ordinal_num_en(BigInt::from_int(3)), "3rd")
  assert_eq(ordinal_num_en(BigInt::from_int(4)), "4th")
  assert_eq(ordinal_num_en(BigInt::from_int(11)), "11th")
  assert_eq(ordinal_num_en(BigInt::from_int(12)), "12th")
  assert_eq(ordinal_num_en(BigInt::from_int(13)), "13th")
  assert_eq(ordinal_num_en(BigInt::from_int(21)), "21st")
}

///|
test "en year" {
  assert_eq(year_en(BigInt::from_int(2024)), "twenty twenty-four")
  assert_eq(year_en(BigInt::from_int(1984)), "nineteen eighty-four")
  assert_eq(year_en(BigInt::from_int(2000)), "two thousand")
  assert_eq(year_en(BigInt::from_int(1900)), "nineteen hundred")
  // years ending in 01..09 keep the cardinal "thousand and" form
  assert_eq(year_en(BigInt::from_int(1001)), "one thousand and one")
  assert_eq(year_en(BigInt::from_int(2001)), "two thousand and one")
  assert_eq(year_en(BigInt::from_int(3009)), "three thousand and nine")
  // a low part below ten takes the upstream "oh-" prefix
  assert_eq(year_en(BigInt::from_int(1904)), "nineteen oh-four")
  assert_eq(year_en(BigInt::from_int(1104)), "eleven oh-four")
  // sub-thousand years are read in hundreds, like upstream
  assert_eq(year_en(BigInt::from_int(101)), "one oh-one")
  assert_eq(year_en(BigInt::from_int(999)), "nine ninety-nine")
  // negative years take the upstream "BC" suffix
  assert_eq(year_en(BigInt::from_int(-44)), "forty-four BC")
  assert_eq(year_en(BigInt::from_int(-1900)), "nineteen hundred BC")
  assert_eq(year_en(BigInt::from_int(-2001)), "two thousand and one BC")
}

///|
fn currency_ok(amount : String, lang : String, code : String) -> String {
  match num2words_currency(amount, lang, code) {
    Ok(words) => words
    Err(msg) => "ERR: " + msg
  }
}

///|
test "currency: en/fr/de/it align with upstream" {
  // English: default EUR, invariant "euro", cents always spelled.
  assert_eq(
    currency_ok("1234.56", "en", "EUR"),
    "one thousand, two hundred and thirty-four euro, fifty-six cents",
  )
  assert_eq(currency_ok("0", "en", ""), "zero euro, zero cents")
  assert_eq(currency_ok("1.01", "en", "USD"), "one dollar, one cent")
  assert_eq(currency_ok("1.01", "en", "GBP"), "one pound sterling, one penny")
  // French: "et" separator, plural also used for zero.
  assert_eq(
    currency_ok("1234.56", "fr", "EUR"),
    "mille deux cent trente-quatre euros et cinquante-six centimes",
  )
  assert_eq(currency_ok("0", "fr", "EUR"), "zéro euros et zéro centimes")
  // German: capitalised nouns, "ein" instead of "eins".
  assert_eq(currency_ok("1", "de", "EUR"), "ein Euro und null Cent")
  assert_eq(currency_ok("101", "de", "EUR"), "einhundertein Euro und null Cent")
  assert_eq(
    currency_ok("1234.56", "de", "EUR"),
    "eintausendzweihundertvierunddreißig Euro und sechsundfünfzig Cent",
  )
  // Italian: apocope before the noun, feminine GBP unit.
  assert_eq(currency_ok("21", "it", "EUR"), "ventun euro e zero centesimi")
  assert_eq(currency_ok("1", "it", "GBP"), "una sterlina e zero penny")
  assert_eq(
    currency_ok("1234.56", "it", "EUR"),
    "milleduecentotrentaquattro euro e cinquantasei centesimi",
  )
}

///|
test "currency: rounding and signs" {
  // Exact decimal half-up on the third fractional digit.
  assert_eq(currency_ok("1.999", "en", "EUR"), "two euro, zero cents")
  assert_eq(
    currency_ok("1234.567", "en", "EUR"),
    "one thousand, two hundred and thirty-four euro, fifty-seven cents",
  )
  assert_eq(currency_ok("99.999", "en", "EUR"), "one hundred euro, zero cents")
  assert_eq(currency_ok("0.005", "en", "EUR"), "zero euro, one cent")
  // Deliberate difference from upstream's binary-float rounding: exact 1.005
  // rounds up here, while upstream yields one euro and zero cents.
  assert_eq(currency_ok("1.005", "en", "EUR"), "one euro, one cent")
  // The sign is dropped when the rounded amount is exactly zero.
  assert_eq(currency_ok("-0.001", "en", "EUR"), "zero euro, zero cents")
  assert_eq(currency_ok("-0.005", "en", "EUR"), "minus zero euro, one cent")
  assert_eq(currency_ok("-3.5", "en", "EUR"), "minus three euro, fifty cents")
  // Upstream crashes on negative Italian currency; this project supports it
  // like Italian ordinals ("meno ...").
  assert_eq(
    currency_ok("-3.5", "it", "EUR"),
    "meno tre euro e cinquanta centesimi",
  )
}

///|
test "currency: Spanish gender agreement" {
  assert_eq(currency_ok("1.01", "es", "GBP"), "una libra con un penique")
  assert_eq(
    currency_ok("21.21", "es", "GBP"),
    "veintiuna libras con veintiún peniques",
  )
  assert_eq(
    currency_ok("31", "es", "GBP"),
    "treinta y una libras con cero peniques",
  )
  assert_eq(
    currency_ok("200", "es", "GBP"),
    "doscientas libras con cero peniques",
  )
  assert_eq(
    currency_ok("300", "es", "GBP"),
    "trescientas libras con cero peniques",
  )
  // Upstream keeps "quinientos" masculine, unlike doscientas/trescientas.
  assert_eq(
    currency_ok("500", "es", "GBP"),
    "quinientos libras con cero peniques",
  )
  assert_eq(
    currency_ok("21000", "es", "EUR"),
    "veintiún mil euros con cero céntimos",
  )
  assert_eq(
    currency_ok("1000001", "es", "GBP"),
    "un millón una libras con cero peniques",
  )
  assert_eq(
    currency_ok("1234.56", "es", "EUR"),
    "mil doscientos treinta y cuatro euros con cincuenta y seis céntimos",
  )
  // Upstream's irregular CNY cent pair.
  assert_eq(currency_ok("2.02", "es", "CNY"), "dos yuanes con dos jiaos")
}

///|
test "currency: Russian gender and plural forms" {
  assert_eq(
    currency_ok("1.01", "ru", "RUB"),
    "один рубль, одна копейка",
  )
  assert_eq(
    currency_ok("2.02", "ru", "RUB"),
    "два рубля, две копейки",
  )
  assert_eq(
    currency_ok("5.05", "ru", "RUB"),
    "пять рублей, пять копеек",
  )
  assert_eq(
    currency_ok("11.11", "ru", "RUB"),
    "одиннадцать рублей, одиннадцать копеек",
  )
  assert_eq(
    currency_ok("21.21", "ru", "RUB"),
    "двадцать один рубль, двадцать одна копейка",
  )
  assert_eq(
    currency_ok("22.22", "ru", "RUB"),
    "двадцать два рубля, двадцать две копейки",
  )
  assert_eq(
    currency_ok("2.02", "ru", "UAH"),
    "две гривны, две копейки",
  )
  assert_eq(
    currency_ok("2000", "ru", "RUB"),
    "две тысячи рублей, ноль копеек",
  )
  // Upstream applies the feminine form to every group ("одна миллион").
  assert_eq(
    currency_ok("1000000", "ru", "UAH"),
    "одна миллион гривен, ноль копеек",
  )
  assert_eq(
    currency_ok("2000000", "ru", "UAH"),
    "две миллиона гривен, ноль копеек",
  )
  // Upstream's "слотых" typo is normalised to "злотых".
  assert_eq(
    currency_ok("2.02", "ru", "PLN"),
    "два польских злотых, два гроша",
  )
  assert_eq(
    currency_ok("2.02", "ru", "KZT"),
    "два тенге, два тиына",
  )
}

///|
test "currency: Brazilian Portuguese" {
  assert_eq(currency_ok("0", "pt", "BRL"), "zero reais")
  assert_eq(currency_ok("1", "pt", "BRL"), "um real")
  assert_eq(currency_ok("0.01", "pt", "BRL"), "zero reais e um centavo")
  assert_eq(
    currency_ok("1234.56", "pt", "BRL"),
    "mil duzentos e trinta e quatro reais e cinquenta e seis centavos",
  )
  // Zero cents are omitted; exact 10^6 multiples take "de".
  assert_eq(currency_ok("1000000", "pt", ""), "um milhão de reais")
  assert_eq(currency_ok("2000000", "pt", "BRL"), "dois milhões de reais")
  assert_eq(currency_ok("1000001", "pt", "BRL"), "um milhão e um reais")
  assert_eq(
    currency_ok("1234567", "pt", "BRL"),
    "um milhão duzentos e trinta e quatro mil quinhentos e sessenta e sete reais",
  )
  assert_eq(currency_ok("1.999", "pt", "BRL"), "dois reais")
  assert_eq(
    currency_ok("-3.5", "pt", "BRL"),
    "menos três reais e cinquenta centavos",
  )
}

///|
test "pt_PT: long scale, teens and currency" {
  // European vocabulary.
  assert_eq(num2words_int(16, "pt_PT", "cardinal"), "dezasseis")
  assert_eq(num2words_int(17, "pt_PT", "cardinal"), "dezassete")
  assert_eq(num2words_int(19, "pt_PT", "cardinal"), "dezanove")
  // Long scale: 10^9 is "mil milhões", 10^12 is "bilião".
  assert_eq(num2words_int(1000000000, "pt_PT", "cardinal"), "mil milhões")
  assert_eq(num2words_int(2000000000, "pt_PT", "cardinal"), "dois mil milhões")
  assert_eq(num2words_str("1000000000000", "pt_PT", "cardinal"), "um bilião")
  assert_eq(
    num2words_str("1000000000000000", "pt_PT", "cardinal"),
    "mil biliões",
  )
  assert_eq(
    num2words_str("1000000000000000000000000", "pt_PT", "cardinal"),
    "um quatrilião",
  )
  assert_eq(num2words_int(1000001, "pt_PT", "cardinal"), "um milhão e um")
  assert_eq(
    num2words_int(1234567, "pt_PT", "cardinal"),
    "um milhão duzentos e trinta e quatro mil quinhentos e sessenta e sete",
  )
  // European Portuguese removes every "e" per scale word once the regex
  // matches, and composes long-scale pairs.
  assert_eq(
    num2words_str("600990392858037", "pt_PT", "cardinal"),
    "seiscentos biliões novecentos e noventa mil trezentos e noventa e dois milhões oitocentos e cinquenta e oito mil trinta e sete",
  )
  assert_eq(
    num2words_str("4440376435", "pt_PT", "cardinal"),
    "quatro mil quatrocentos e quarenta milhões trezentos e setenta e seis mil quatrocentos e trinta e cinco",
  )
  assert_eq(
    num2words_str("310600031", "pt_PT", "cardinal"),
    "trezentos e dez milhões seiscentos mil e trinta e um",
  )
  assert_eq(
    num2words_str("1000001234", "pt_PT", "cardinal"),
    "mil milhões e mil duzentos e trinta e quatro",
  )
  assert_eq(
    num2words_str("2500000", "pt_PT", "cardinal"),
    "dois milhões e quinhentos mil",
  )
  // The scale table stops at 10^24 (upstream raises OverflowError at 10^27).
  assert_eq(
    num2words_str("1000000000000000000000000000", "pt_PT", "cardinal"),
    "",
  )
  // Year and ordinals are shared with the Brazilian variant.
  assert_eq(num2words_int(2024, "pt_PT", "year"), "dois mil e vinte e quatro")
  assert_eq(num2words_int(21, "pt_PT", "ordinal"), "vigésimo primeiro")
  assert_eq(num2words_int(21, "pt_PT", "ordinal_num"), "21º")
  // Currency: EUR default, "cêntimo(s)", zero cents omitted.
  assert_eq(currency_ok("1.01", "pt_PT", "EUR"), "um euro e um cêntimo")
  assert_eq(currency_ok("2.02", "pt_PT", "GBP"), "dois libras e dois pence")
  assert_eq(
    currency_ok("1234.56", "pt_PT", "EUR"),
    "mil duzentos e trinta e quatro euros e cinquenta e seis cêntimos",
  )
  assert_eq(currency_ok("1000000", "pt_PT", ""), "um milhão de euros")
  assert_eq(currency_ok("1000001", "pt_PT", "EUR"), "um milhão e um euros")
  assert_eq(currency_ok("0", "pt_PT", "EUR"), "zero euros")
  assert_eq(
    num2words_currency("1", "pt_PT", "BRL"),
    Err("currency code not supported for pt_PT: BRL"),
  )
}

///|
test "currency: remaining upstream codes" {
  assert_eq(currency_ok("1.01", "en", "RUB"), "one rouble, one kopek")
  assert_eq(currency_ok("2.02", "en", "INR"), "two rupees, two paise")
  assert_eq(currency_ok("2.02", "en", "SEK"), "two kronor, two öre")
  assert_eq(currency_ok("2.02", "en", "NOK"), "two kroner, two øre")
  assert_eq(currency_ok("2.02", "en", "PLN"), "two zlotys, two groszy")
  assert_eq(currency_ok("2.02", "en", "MXN"), "two pesos, two cents")
  assert_eq(currency_ok("2.02", "en", "CAD"), "two dollars, two cents")
  assert_eq(currency_ok("1.01", "en", "AUD"), "one dollar, one cent")
  assert_eq(currency_ok("1.01", "fr", "CNY"), "un yuan et un fen")
  assert_eq(currency_ok("2.02", "fr", "CNY"), "deux yuans et deux jiaos")
  assert_eq(currency_ok("1.01", "de", "CNY"), "ein Yuan und ein Jiao")
  assert_eq(currency_ok("2.02", "de", "CNY"), "zwei Yuan und zwei Fen")
  assert_eq(currency_ok("2.02", "it", "CNY"), "due yuan e due fen")
}

///|
test "currency: rejected input" {
  assert_eq(num2words_currency("abc", "en", "EUR"), Err("invalid number: abc"))
  assert_eq(
    num2words_currency("1", "xx", "EUR"),
    Err("currency not implemented for language: xx"),
  )
  assert_eq(
    num2words_currency("1", "en", "JPY"),
    Err("currency code not supported for en: JPY"),
  )
  assert_eq(
    num2words_currency("1", "pt", "USD"),
    Err("currency code not supported for pt: USD"),
  )
  // The non-Result entry points turn the error into "".
  assert_eq(num2words_str("1", "xx", "currency"), "")
  assert_eq(num2words_str("abc", "en", "currency"), "")
  // An amount past the scale table is reported, not crashed.
  assert_eq(
    num2words_currency("1" + "0".repeat(36), "en", "EUR"),
    Err(
      "magnitude out of supported range: 1000000000000000000000000000000000000",
    ),
  )
  assert_eq(num2words_str("1" + "0".repeat(36), "en", "currency"), "")
  // Codes are case-insensitive and "" selects the language default.
  assert_eq(currency_ok("1", "en", "usd"), "one dollar, zero cents")
  assert_eq(currency_ok("1", "pt", ""), "um real")
}

///|
test "currency: dispatch paths agree" {
  let want = "one thousand, two hundred and thirty-four euro, fifty-six cents"
  assert_eq(num2words_str("1234.56", "en", "currency"), want)
  assert_eq(num2words_float(1234.56, "en", "currency"), want)
  assert_eq(num2words_str_checked("1234.56", "en", "currency"), Ok(want))
  // Integers are major units here (upstream's int-as-cents quirk is not
  // reproduced).
  assert_eq(
    num2words_int(1234, "en", "currency"),
    "one thousand, two hundred and thirty-four euro, zero cents",
  )
}

///|
test "en float" {
  assert_eq(
    num2words_float(1234.56, "en", "cardinal"),
    "one thousand, two hundred and thirty-four point five six",
  )
}

///|
test "fr cardinal" {
  assert_eq(num2words_int(42, "fr", "cardinal"), "quarante-deux")
  assert_eq(num2words_int(70, "fr", "cardinal"), "soixante-dix")
  assert_eq(num2words_int(71, "fr", "cardinal"), "soixante et onze")
  assert_eq(num2words_int(80, "fr", "cardinal"), "quatre-vingts")
  assert_eq(num2words_int(81, "fr", "cardinal"), "quatre-vingt-un")
  assert_eq(num2words_int(90, "fr", "cardinal"), "quatre-vingt-dix")
  assert_eq(num2words_int(99, "fr", "cardinal"), "quatre-vingt-dix-neuf")
  assert_eq(num2words_int(100, "fr", "cardinal"), "cent")
  assert_eq(num2words_int(200, "fr", "cardinal"), "deux cents")
  assert_eq(num2words_int(1000, "fr", "cardinal"), "mille")
  assert_eq(num2words_int(2000, "fr", "cardinal"), "deux mille")
  assert_eq(num2words_int(1000000, "fr", "cardinal"), "un million")
  assert_eq(
    num2words_int(1234, "fr", "cardinal"),
    "mille deux cent trente-quatre",
  )
  assert_eq(num2words_int(-42, "fr", "cardinal"), "moins quarante-deux")
}

///|
test "fr year" {
  assert_eq(year_fr(BigInt::from_int(2024)), "deux mille vingt-quatre")
  assert_eq(year_fr(BigInt::from_int(1900)), "mille neuf cents")
}

///|
test "es cardinal" {
  assert_eq(num2words_int(42, "es", "cardinal"), "cuarenta y dos")
  assert_eq(num2words_int(21, "es", "cardinal"), "veintiuno")
  assert_eq(num2words_int(100, "es", "cardinal"), "cien")
  assert_eq(num2words_int(101, "es", "cardinal"), "ciento uno")
  assert_eq(num2words_int(200, "es", "cardinal"), "doscientos")
  assert_eq(num2words_int(1000, "es", "cardinal"), "mil")
  assert_eq(num2words_int(2000, "es", "cardinal"), "dos mil")
  assert_eq(num2words_int(1000000, "es", "cardinal"), "un millón")
  assert_eq(
    num2words_int(1234, "es", "cardinal"),
    "mil doscientos treinta y cuatro",
  )
  // long scale: 10^9 is "mil millones", never "un mil millones"
  assert_eq(
    num2words(BigInt::from_string("1000000000"), "es", "cardinal"),
    "mil millones",
  )
  assert_eq(
    num2words(BigInt::from_string("2000000000"), "es", "cardinal"),
    "dos mil millones",
  )
  // The 10^9 and 10^6 groups form one long-scale phrase.
  assert_eq(
    num2words_str("4440376435", "es", "cardinal"),
    "cuatro mil cuatrocientos cuarenta millones trescientos setenta y seis mil cuatrocientos treinta y cinco",
  )
  assert_eq(
    num2words_str("21000000000", "es", "cardinal"),
    "veintiuno mil millones",
  )
  assert_eq(num2words_str("1001000000", "es", "cardinal"), "mil uno millones")
  assert_eq(
    num2words_str("1001000000000", "es", "cardinal"),
    "un billón mil millones",
  )
}

///|
test "es year" {
  assert_eq(year_es(BigInt::from_int(2024)), "dos mil veinticuatro")
  assert_eq(year_es(BigInt::from_int(1900)), "mil novecientos")
}

///|
test "de cardinal" {
  assert_eq(num2words_int(42, "de", "cardinal"), "zweiundvierzig")
  assert_eq(num2words_int(21, "de", "cardinal"), "einundzwanzig")
  assert_eq(num2words_int(100, "de", "cardinal"), "einhundert")
  assert_eq(num2words_int(101, "de", "cardinal"), "einhunderteins")
  assert_eq(num2words_int(200, "de", "cardinal"), "zweihundert")
  assert_eq(num2words_int(1000, "de", "cardinal"), "eintausend")
  assert_eq(num2words_int(1001, "de", "cardinal"), "eintausendeins")
  assert_eq(num2words_int(2000, "de", "cardinal"), "zweitausend")
  assert_eq(num2words_int(1000000, "de", "cardinal"), "eine Million")
  assert_eq(
    num2words_int(1234, "de", "cardinal"),
    "eintausendzweihundertvierunddreißig",
  )
}

///|
test "de year" {
  assert_eq(year_de(BigInt::from_int(2024)), "zweitausendvierundzwanzig")
  assert_eq(year_de(BigInt::from_int(1900)), "neunzehnhundert")
  assert_eq(year_de(BigInt::from_int(2100)), "einundzwanzighundert")
  assert_eq(year_de(BigInt::from_int(1000)), "eintausend")
  // the hundreds morpheme keeps the cardinal head: 101 -> "einshunderteins"
  assert_eq(year_de(BigInt::from_int(101)), "einshunderteins")
  assert_eq(year_de(BigInt::from_int(1101)), "elfhunderteins")
  // upstream emits nonsense for negative years; we spell "minus <year>"
  assert_eq(year_de(BigInt::from_int(-44)), "minus vierundvierzig")
}

///|
test "it cardinal" {
  assert_eq(num2words_int(0, "it", "cardinal"), "zero")
  assert_eq(num2words_int(1, "it", "cardinal"), "uno")
  assert_eq(num2words_int(8, "it", "cardinal"), "otto")
  assert_eq(num2words_int(20, "it", "cardinal"), "venti")
  // tens drop their final vowel before "uno" and "otto"
  assert_eq(num2words_int(21, "it", "cardinal"), "ventuno")
  assert_eq(num2words_int(22, "it", "cardinal"), "ventidue")
  assert_eq(num2words_int(23, "it", "cardinal"), "ventitré")
  assert_eq(num2words_int(28, "it", "cardinal"), "ventotto")
  // the accent only survives on the final word of the whole number
  assert_eq(num2words_int(123, "it", "cardinal"), "centoventitré")
  assert_eq(num2words_int(123000, "it", "cardinal"), "centoventitremila")
  assert_eq(num2words_int(1003, "it", "cardinal"), "milletré")
  assert_eq(num2words_int(1000023, "it", "cardinal"), "un milione e ventitré")
  assert_eq(num2words_int(1000003, "it", "cardinal"), "un milione e tre")
  assert_eq(num2words_int(31, "it", "cardinal"), "trentuno")
  assert_eq(num2words_int(33, "it", "cardinal"), "trentatré")
  assert_eq(num2words_int(38, "it", "cardinal"), "trentotto")
  assert_eq(num2words_int(45, "it", "cardinal"), "quarantacinque")
  // hundreds: "cento" elides its final vowel before an "o"-initial part
  assert_eq(num2words_int(100, "it", "cardinal"), "cento")
  assert_eq(num2words_int(101, "it", "cardinal"), "centouno")
  assert_eq(num2words_int(108, "it", "cardinal"), "centotto")
  assert_eq(num2words_int(110, "it", "cardinal"), "centodieci")
  assert_eq(num2words_int(111, "it", "cardinal"), "centoundici")
  assert_eq(num2words_int(118, "it", "cardinal"), "centodiciotto")
  assert_eq(num2words_int(180, "it", "cardinal"), "centottanta")
  assert_eq(num2words_int(181, "it", "cardinal"), "centottantuno")
  assert_eq(num2words_int(200, "it", "cardinal"), "duecento")
  assert_eq(num2words_int(201, "it", "cardinal"), "duecentouno")
  assert_eq(num2words_int(208, "it", "cardinal"), "duecentotto")
  assert_eq(num2words_int(245, "it", "cardinal"), "duecentoquarantacinque")
  // "mille"/"mila" attach; million-and-above are separate words
  assert_eq(num2words_int(1000, "it", "cardinal"), "mille")
  assert_eq(num2words_int(1001, "it", "cardinal"), "milleuno")
  assert_eq(num2words_int(2000, "it", "cardinal"), "duemila")
  assert_eq(
    num2words_int(2345, "it", "cardinal"),
    "duemilatrecentoquarantacinque",
  )
  assert_eq(num2words_int(21000, "it", "cardinal"), "ventunomila")
  assert_eq(num2words_int(1000000, "it", "cardinal"), "un milione")
  assert_eq(num2words_int(1000001, "it", "cardinal"), "un milione e uno")
  assert_eq(
    num2words_int(1234567, "it", "cardinal"),
    "un milione e duecentotrentaquattromilacinquecentosessantasette",
  )
  // Multi-scale groups: a comma follows miliardi/bilioni when the rest itself
  // contains " e "; otherwise the conjunction is used.
  assert_eq(
    num2words_str("786790526496", "it", "cardinal"),
    "settecentottantasei miliardi, settecentonovanta milioni e cinquecentoventiseimilaquattrocentonovantasei",
  )
  assert_eq(
    num2words_str("1234567890", "it", "cardinal"),
    "un miliardo, duecentotrentaquattro milioni e cinquecentosessantasettemilaottocentonovanta",
  )
  assert_eq(
    num2words_str("2000001000", "it", "cardinal"),
    "due miliardi e mille",
  )
  assert_eq(
    num2words_str("1001000000000", "it", "cardinal"),
    "un bilione e un miliardo",
  )
  assert_eq(num2words_int(2000000, "it", "cardinal"), "due milioni")
  // 10^12 does not fit in Int, so it goes through the BigInt entry point
  assert_eq(
    num2words(BigInt::from_string("1000000000000"), "it", "cardinal"),
    "un bilione",
  )
  assert_eq(num2words_int(-42, "it", "cardinal"), "meno quarantadue")
}

///|
test "pt cardinal" {
  assert_eq(num2words_int(0, "pt", "cardinal"), "zero")
  assert_eq(num2words_int(1, "pt", "cardinal"), "um")
  assert_eq(num2words_int(15, "pt", "cardinal"), "quinze")
  assert_eq(num2words_int(16, "pt", "cardinal"), "dezesseis")
  assert_eq(num2words_int(20, "pt", "cardinal"), "vinte")
  // "e" links tens to units
  assert_eq(num2words_int(21, "pt", "cardinal"), "vinte e um")
  assert_eq(num2words_int(30, "pt", "cardinal"), "trinta")
  assert_eq(num2words_int(32, "pt", "cardinal"), "trinta e dois")
  // 100 is "cem" alone but "cento" when a remainder follows
  assert_eq(num2words_int(100, "pt", "cardinal"), "cem")
  assert_eq(num2words_int(101, "pt", "cardinal"), "cento e um")
  assert_eq(num2words_int(110, "pt", "cardinal"), "cento e dez")
  assert_eq(num2words_int(115, "pt", "cardinal"), "cento e quinze")
  assert_eq(num2words_int(200, "pt", "cardinal"), "duzentos")
  assert_eq(num2words_int(201, "pt", "cardinal"), "duzentos e um")
  assert_eq(num2words_int(234, "pt", "cardinal"), "duzentos e trinta e quatro")
  assert_eq(num2words_int(900, "pt", "cardinal"), "novecentos")
  assert_eq(num2words_int(999, "pt", "cardinal"), "novecentos e noventa e nove")
  // "e" after a scale group is removed when the next part starts with a
  // hundreds word and the number continues (upstream's regex post-processing).
  assert_eq(num2words_int(1000, "pt", "cardinal"), "mil")
  assert_eq(num2words_int(1001, "pt", "cardinal"), "mil e um")
  assert_eq(num2words_int(1100, "pt", "cardinal"), "mil e cem")
  assert_eq(num2words_int(1200, "pt", "cardinal"), "mil e duzentos")
  assert_eq(
    num2words_int(1234, "pt", "cardinal"),
    "mil duzentos e trinta e quatro",
  )
  assert_eq(num2words_int(2000, "pt", "cardinal"), "dois mil")
  assert_eq(num2words_int(21000, "pt", "cardinal"), "vinte e um mil")
  assert_eq(num2words_int(1000000, "pt", "cardinal"), "um milhão")
  assert_eq(num2words_int(2000000, "pt", "cardinal"), "dois milhões")
  assert_eq(num2words_int(1000001, "pt", "cardinal"), "um milhão e um")
  assert_eq(num2words_int(1000100, "pt", "cardinal"), "um milhão e cem")
  assert_eq(
    num2words_int(1234567, "pt", "cardinal"),
    "um milhão duzentos e trinta e quatro mil quinhentos e sessenta e sete",
  )
  // Brazilian Portuguese removes only the first "e" per scale word.
  assert_eq(
    num2words_str("743147310600031", "pt", "cardinal"),
    "setecentos e quarenta e três trilhões cento e quarenta e sete bilhões trezentos e dez milhões seiscentos mil e trinta e um",
  )
  assert_eq(
    num2words_str("310600031", "pt", "cardinal"),
    "trezentos e dez milhões seiscentos mil e trinta e um",
  )
  assert_eq(
    num2words_str("1000001234", "pt", "cardinal"),
    "um bilhão e mil duzentos e trinta e quatro",
  )
  assert_eq(
    num2words_str("2500000", "pt", "cardinal"),
    "dois milhões e quinhentos mil",
  )
  // 10^9 and 10^12 need the BigInt entry point
  assert_eq(
    num2words(BigInt::from_string("1000000000"), "pt", "cardinal"),
    "um bilhão",
  )
  assert_eq(
    num2words(BigInt::from_string("1000000000000"), "pt", "cardinal"),
    "um trilhão",
  )
  assert_eq(num2words_int(-42, "pt", "cardinal"), "menos quarenta e dois")
}

///|
test "pt year" {
  assert_eq(year_pt(BigInt::from_int(2024)), "dois mil e vinte e quatro")
  assert_eq(
    year_pt(BigInt::from_int(1984)),
    "mil novecentos e oitenta e quatro",
  )
  // negative years take the upstream "antes de Cristo" suffix
  assert_eq(year_pt(BigInt::from_int(-44)), "quarenta e quatro antes de Cristo")
  assert_eq(
    year_pt_pt(BigInt::from_int(-44)),
    "quarenta e quatro antes de Cristo",
  )
}

///|
test "it year" {
  assert_eq(year_it(BigInt::from_int(2024)), "duemilaventiquattro")
  assert_eq(year_it(BigInt::from_int(1984)), "millenovecentottantaquattro")
}

///|
test "ru cardinal" {
  assert_eq(num2words_int(0, "ru", "cardinal"), "ноль")
  assert_eq(num2words_int(1, "ru", "cardinal"), "один")
  assert_eq(num2words_int(2, "ru", "cardinal"), "два")
  assert_eq(num2words_int(10, "ru", "cardinal"), "десять")
  assert_eq(num2words_int(11, "ru", "cardinal"), "одиннадцать")
  assert_eq(num2words_int(21, "ru", "cardinal"), "двадцать один")
  assert_eq(num2words_int(42, "ru", "cardinal"), "сорок два")
  assert_eq(
    num2words_int(99, "ru", "cardinal"),
    "девяносто девять",
  )
  assert_eq(num2words_int(100, "ru", "cardinal"), "сто")
  assert_eq(num2words_int(101, "ru", "cardinal"), "сто один")
  assert_eq(num2words_int(200, "ru", "cardinal"), "двести")
  assert_eq(
    num2words_int(999, "ru", "cardinal"),
    "девятьсот девяносто девять",
  )
  // "тысяча" is feminine and takes three plural forms
  assert_eq(num2words_int(1000, "ru", "cardinal"), "одна тысяча")
  assert_eq(num2words_int(2000, "ru", "cardinal"), "две тысячи")
  assert_eq(num2words_int(5000, "ru", "cardinal"), "пять тысяч")
  assert_eq(
    num2words_int(21000, "ru", "cardinal"),
    "двадцать одна тысяча",
  )
  assert_eq(
    num2words_int(22000, "ru", "cardinal"),
    "двадцать две тысячи",
  )
  assert_eq(
    num2words_int(25000, "ru", "cardinal"),
    "двадцать пять тысяч",
  )
  assert_eq(
    num2words_int(1234, "ru", "cardinal"),
    "одна тысяча двести тридцать четыре",
  )
  // 11..14 take the "many" form even though they end in 1..4
  assert_eq(
    num2words_int(11000, "ru", "cardinal"),
    "одиннадцать тысяч",
  )
  assert_eq(
    num2words_int(12000, "ru", "cardinal"),
    "двенадцать тысяч",
  )
  assert_eq(
    num2words_int(14000, "ru", "cardinal"),
    "четырнадцать тысяч",
  )
  assert_eq(num2words_int(1000000, "ru", "cardinal"), "один миллион")
  assert_eq(num2words_int(2000000, "ru", "cardinal"), "два миллиона")
  assert_eq(
    num2words_int(5000000, "ru", "cardinal"),
    "пять миллионов",
  )
  assert_eq(
    num2words_int(1000001, "ru", "cardinal"),
    "один миллион один",
  )
  assert_eq(
    num2words_int(1234567, "ru", "cardinal"),
    "один миллион двести тридцать четыре тысячи пятьсот шестьдесят семь",
  )
  assert_eq(
    num2words(BigInt::from_string("1000000000"), "ru", "cardinal"),
    "один миллиард",
  )
  assert_eq(
    num2words(BigInt::from_string("1000000000000"), "ru", "cardinal"),
    "один триллион",
  )
  assert_eq(
    num2words_int(-42, "ru", "cardinal"),
    "минус сорок два",
  )
}

///|
test "ru year" {
  assert_eq(
    year_ru(BigInt::from_int(2024)),
    "две тысячи двадцать четыре",
  )
  assert_eq(
    year_ru(BigInt::from_int(1984)),
    "одна тысяча девятьсот восемьдесят четыре",
  )
}

///|
test "decimal string input" {
  assert_eq(
    num2words_str("1234.56", "en", "cardinal"),
    "one thousand, two hundred and thirty-four point five six",
  )
  assert_eq(num2words_str("1000000", "de", "cardinal"), "eine Million")
  assert_eq(num2words_str("-42", "en", "cardinal"), "minus forty-two")
}

// --- M1: validation and boundaries ------------------------------------------

///|
test "input validation accepts well-formed numbers" {
  assert_eq(is_valid_number("0"), true)
  assert_eq(is_valid_number("1234"), true)
  assert_eq(is_valid_number("007"), true)
  assert_eq(is_valid_number("-42"), true)
  assert_eq(is_valid_number("1234.56"), true)
  assert_eq(is_valid_number("-0.5"), true)
  assert_eq(is_valid_number("1000000000000000000000"), true)
}

///|
test "input validation rejects malformed numbers" {
  assert_eq(is_valid_number(""), false)
  assert_eq(is_valid_number("-"), false)
  assert_eq(is_valid_number("."), false)
  assert_eq(is_valid_number(".5"), false)
  assert_eq(is_valid_number("5."), false)
  assert_eq(is_valid_number("1.2.3"), false)
  assert_eq(is_valid_number("12a"), false)
  assert_eq(is_valid_number("abc"), false)
  assert_eq(is_valid_number("--5"), false)
  assert_eq(is_valid_number("1,234"), false)
}

///|
test "malformed input returns empty string instead of aborting" {
  assert_eq(num2words_str("abc", "en", "cardinal"), "")
  assert_eq(num2words_str("1.2.3", "en", "cardinal"), "")
  assert_eq(num2words_str("", "en", "cardinal"), "")
  assert_eq(num2words_str("-", "en", "cardinal"), "")
}

///|
test "checked API reports success and failure" {
  assert_eq(
    num2words_str_checked("abc", "en", "cardinal"),
    Err("invalid number: abc"),
  )
  assert_eq(
    num2words_str_checked("1234", "en", "cardinal"),
    Ok("one thousand, two hundred and thirty-four"),
  )
  // Unknown language / mode must not silently fall back to English.
  assert_eq(num2words_int(42, "zz", "cardinal"), "")
  assert_eq(num2words_str("42", "fr-FR", "cardinal"), "")
  assert_eq(num2words_float(1.5, "zz", "cardinal"), "")
  assert_eq(
    num2words_str_checked("42", "zz", "cardinal"),
    Err("unknown language: zz"),
  )
  assert_eq(num2words_str("42", "en", "foo"), "")
  assert_eq(num2words_str_checked("42", "en", "foo"), Err("unknown mode: foo"))
  // A known language without a mode still reports its upstream boundary.
  assert_eq(num2words_str("1", "sv", "currency"), "")
  // `get_lang` remains the lenient resolver for direct callers.
  assert_eq(get_lang("zz").cardinal(BigInt::from_int(1)), "one")
}

///|
test "boundaries" {
  assert_eq(num2words_str("0", "en", "cardinal"), "zero")
  assert_eq(num2words_str("-0", "en", "cardinal"), "zero")
  assert_eq(num2words_str("007", "en", "cardinal"), "seven")
  assert_eq(num2words_str("1.50", "en", "cardinal"), "one point five zero")
  assert_eq(num2words_str("0.0", "en", "cardinal"), "zero point zero")
  assert_eq(
    num2words_str("1000000000000000000000", "en", "cardinal"),
    "one sextillion",
  )
  assert_eq(num2words_int(0, "en", "ordinal"), "zeroth")
  assert_eq(num2words_int(0, "en", "ordinal_num"), "0th")
  assert_eq(num2words_int(0, "en", "year"), "zero")
  assert_eq(num2words_int(0, "en", "currency"), "zero euro, zero cents")
  // Upstream raises TypeError for negative ordinals; we return "".
  assert_eq(num2words_int(-1, "en", "ordinal"), "")
  assert_eq(num2words_int(-1, "en", "ordinal_num"), "")
  // Italian is the one language upstream supports for negative ordinals.
  assert_eq(num2words_int(-3, "it", "ordinal"), "meno terzo")
}

// --- M1: path consistency ---------------------------------------------------
// The Int / BigInt / String entry points must agree on the same value; this is
// the invariant that guards against divergence between the parsing paths.

///|
test "path consistency: string and int agree" {
  let samples = [
    0, 1, 9, 10, 21, 42, 100, 101, 999, 1000, 1234, 1000000, 1234567,
  ]
  for i = 0; i < samples.length(); i = i + 1 {
    let n = samples[i]
    assert_eq(
      num2words_str(n.to_string(), "en", "cardinal"),
      num2words_int(n, "en", "cardinal"),
    )
  }
}

///|
test "path consistency: string and int agree in every language" {
  let langs = [
    "en", "fr", "es", "de", "it", "pt", "pt_PT", "ru", "nl", "tr", "vi", "zh", "zh_TW",
    "ja", "ko", "sv", "no", "da", "id", "pl", "ar", "th", "fi", "uk",
  ]
  let samples = [0, 21, 100, 1234, 1000000]
  for li = 0; li < langs.length(); li = li + 1 {
    for si = 0; si < samples.length(); si = si + 1 {
      let n = samples[si]
      assert_eq(
        num2words_str(n.to_string(), langs[li], "cardinal"),
        num2words_int(n, langs[li], "cardinal"),
      )
    }
  }
}

// --- supported magnitude ----------------------------------------------------
// Scale-word tables are finite, so each language has a ceiling. Values past
// it must be reported, never crash by indexing off the end of the table.

///|
fn zeros(n : Int) -> String {
  let mut s = ""
  for i = 0; i < n; i = i + 1 {
    s = s + "0"
  }
  s
}

///|
test "magnitude within the scale table" {
  assert_eq(num2words_str("1" + zeros(33), "en", "cardinal"), "one decillion")
  assert_eq(num2words_str("1" + zeros(30), "fr", "cardinal"), "un sextillion")
  assert_eq(num2words_str("1" + zeros(21), "it", "cardinal"), "un triliardo")
  assert_eq(num2words_str("1" + zeros(21), "pt", "cardinal"), "um sextilhão")
  assert_eq(
    num2words_str("1" + zeros(33), "ru", "cardinal"),
    "один дециллион",
  )
  assert_eq(lang_en().max_power(), 11)
}

///|
test "magnitude beyond the scale table is reported, not crashed" {
  let too_big = "1" + zeros(36)
  assert_eq(num2words_str(too_big, "en", "cardinal"), "")
  assert_eq(
    num2words_str_checked(too_big, "en", "cardinal"),
    Err("magnitude out of supported range: " + too_big),
  )
  // Italian and Portuguese tables stop at 10^21
  assert_eq(num2words_str("1" + zeros(24), "it", "cardinal"), "")
  assert_eq(num2words_str("1" + zeros(24), "pt", "cardinal"), "")
  assert_eq(num2words_str("1" + zeros(36), "ru", "cardinal"), "")
}

///|
test "path consistency: string and float agree" {
  assert_eq(
    num2words_str("1234.56", "en", "cardinal"),
    num2words_float(1234.56, "en", "cardinal"),
  )
  assert_eq(
    num2words_str("0.5", "en", "cardinal"),
    num2words_float(0.5, "en", "cardinal"),
  )
}

///|
test "float scientific notation, negative zero and decimal magnitude guard" {
  // `Double::to_string` switches to scientific notation at 10^21 / 10^-6;
  // these must be expanded rather than handed to `BigInt::from_string`.
  assert_eq(num2words_float(1.0e21, "en", "cardinal"), "one sextillion")
  assert_eq(
    num2words_float(1.5e21, "en", "cardinal"),
    "one sextillion, five hundred quintillion",
  )
  assert_eq(
    num2words_float(1.0e-7, "en", "cardinal"),
    "zero point zero zero zero zero zero zero one",
  )
  assert_eq(num2words_float(1.0e33, "en", "cardinal"), "one decillion")
  // Beyond the scale table and non-finite values -> "" instead of aborting.
  assert_eq(num2words_float(1.0e36, "en", "cardinal"), "")
  // Negative decimals below one keep their sign.
  assert_eq(num2words_float(-0.5, "en", "cardinal"), "minus zero point five")
  assert_eq(num2words_str("-0.5", "en", "cardinal"), "minus zero point five")
  // Out-of-range integer part in a decimal string -> "" (no " point ..." leak).
  assert_eq(num2words_str("1" + zeros(36) + ".5", "en", "cardinal"), "")
}

// --- Dutch ------------------------------------------------------------------

///|
test "nl cardinal" {
  assert_eq(num2words_int(0, "nl", "cardinal"), "nul")
  assert_eq(num2words_int(1, "nl", "cardinal"), "één")
  assert_eq(num2words_int(16, "nl", "cardinal"), "zestien")
  // tens and units are reversed and glued: 21 -> eenentwintig, 22 -> tweeëntwintig
  assert_eq(num2words_int(21, "nl", "cardinal"), "eenentwintig")
  assert_eq(num2words_int(22, "nl", "cardinal"), "tweeëntwintig")
  assert_eq(num2words_int(100, "nl", "cardinal"), "honderd")
  assert_eq(num2words_int(101, "nl", "cardinal"), "honderdéén")
  assert_eq(num2words_int(1000, "nl", "cardinal"), "duizend")
  assert_eq(num2words_int(1001, "nl", "cardinal"), "duizendéén")
  assert_eq(num2words_int(1100, "nl", "cardinal"), "duizendhonderd")
  assert_eq(
    num2words_int(1234, "nl", "cardinal"),
    "duizendtweehonderdvierendertig",
  )
  // Spaces appear only around million-and-above scale words.
  assert_eq(num2words_int(1000000, "nl", "cardinal"), "een miljoen")
  assert_eq(num2words_int(1000001, "nl", "cardinal"), "een miljoen één")
  assert_eq(num2words_int(1001000, "nl", "cardinal"), "een miljoen duizend")
  assert_eq(
    num2words_int(123456789, "nl", "cardinal"),
    "honderddrieëntwintig miljoen vierhonderdzesenvijftigduizendzevenhonderdnegenentachtig",
  )
  assert_eq(num2words_int(-42, "nl", "cardinal"), "min tweeënveertig")
  assert_eq(
    num2words(BigInt::from_string("1000000000000000"), "nl", "cardinal"),
    "een biljard",
  )
}

///|
test "nl year" {
  assert_eq(num2words_int(2024, "nl", "year"), "tweeduizendvierentwintig")
  assert_eq(num2words_int(1900, "nl", "year"), "negentien honderd")
  assert_eq(num2words_int(1100, "nl", "year"), "elf honderd")
  assert_eq(num2words_int(1001, "nl", "year"), "duizendéén")
  assert_eq(num2words_int(100, "nl", "year"), "één honderd")
  // Upstream emits "min één honderd zesenvijftig" here (its `//`/`%` run on the
  // negative value); we spell a clean "min <year>", like `de`.
  assert_eq(num2words_int(-44, "nl", "year"), "min vierenveertig")
}

///|
test "nl ordinal and ordinal_num" {
  assert_eq(num2words_int(0, "nl", "ordinal"), "nulde")
  assert_eq(num2words_int(1, "nl", "ordinal"), "eerste")
  assert_eq(num2words_int(2, "nl", "ordinal"), "tweede")
  assert_eq(num2words_int(3, "nl", "ordinal"), "derde")
  assert_eq(num2words_int(8, "nl", "ordinal"), "achtste")
  assert_eq(num2words_int(20, "nl", "ordinal"), "twintigste")
  assert_eq(num2words_int(21, "nl", "ordinal"), "eenentwintigste")
  assert_eq(num2words_int(100, "nl", "ordinal"), "honderdste")
  assert_eq(num2words_int(101, "nl", "ordinal"), "honderdeerste")
  assert_eq(num2words_int(1000, "nl", "ordinal"), "duizendste")
  assert_eq(num2words_int(1000000, "nl", "ordinal"), "een miljoenste")
  assert_eq(num2words_int(21, "nl", "ordinal_num"), "21e")
  assert_eq(num2words_int(-1, "nl", "ordinal"), "")
}

///|
test "nl currency and magnitude" {
  assert_eq(currency_ok("1.01", "nl", "EUR"), "één euro, één cent")
  assert_eq(currency_ok("2.02", "nl", "USD"), "twee dollar, twee cent")
  // Dutch keeps every noun singular, even after a plural numeral.
  assert_eq(currency_ok("2.02", "nl", "GBP"), "twee pond, twee penny")
  assert_eq(currency_ok("12.34", "nl", "CNY"), "twaalf yuan, vierendertig jiao")
  assert_eq(currency_ok("0", "nl", ""), "nul euro, nul cent")
  assert_eq(currency_ok("12.34", "nl", ""), "twaalf euro, vierendertig cent")
  assert_eq(lang_nl().max_power(), 201)
  assert_eq(num2words_str("1" + zeros(603), "nl", "cardinal"), "een zendiljard")
  assert_eq(num2words_str("1" + zeros(606), "nl", "cardinal"), "")
}

// --- Turkish ----------------------------------------------------------------

///|
test "tr cardinal" {
  assert_eq(num2words_int(0, "tr", "cardinal"), "sıfır")
  assert_eq(num2words_int(21, "tr", "cardinal"), "yirmibir")
  assert_eq(num2words_int(100, "tr", "cardinal"), "yüz")
  assert_eq(num2words_int(101, "tr", "cardinal"), "yüzbir")
  // A lone thousands group drops "bir"; one million keeps it.
  assert_eq(num2words_int(1000, "tr", "cardinal"), "bin")
  assert_eq(num2words_int(1001, "tr", "cardinal"), "binbir")
  assert_eq(num2words_int(1100, "tr", "cardinal"), "binyüz")
  assert_eq(num2words_int(1234, "tr", "cardinal"), "binikiyüzotuzdört")
  assert_eq(num2words_int(1000000, "tr", "cardinal"), "birmilyon")
  assert_eq(num2words_int(1001000, "tr", "cardinal"), "birmilyonbin")
  assert_eq(
    num2words_int(123456789, "tr", "cardinal"),
    "yüzyirmiüçmilyondörtyüzellialtıbinyediyüzseksendokuz",
  )
  // The leading thousands group drops its trailing "bir" when it has hundreds
  // and the number continues; a two-digit group keeps it.
  assert_eq(
    num2words_int(591170, "tr", "cardinal"),
    "beşyüzdoksanbinyüzyetmiş",
  )
  assert_eq(num2words_int(591000, "tr", "cardinal"), "beşyüzdoksanbirbin")
  assert_eq(num2words_int(101170, "tr", "cardinal"), "yüzbinyüzyetmiş")
  assert_eq(num2words_int(21170, "tr", "cardinal"), "yirmibirbinyüzyetmiş")
  assert_eq(num2words_int(-42, "tr", "cardinal"), "eksikırkiki")
}

///|
test "tr ordinal and ordinal_num" {
  assert_eq(num2words_int(0, "tr", "ordinal"), "sıfırıncı")
  assert_eq(num2words_int(1, "tr", "ordinal"), "birinci")
  assert_eq(num2words_int(3, "tr", "ordinal"), "üçüncü")
  assert_eq(num2words_int(10, "tr", "ordinal"), "onuncu")
  assert_eq(num2words_int(23, "tr", "ordinal"), "yirmiüçüncü")
  assert_eq(num2words_int(100, "tr", "ordinal"), "yüzüncü")
  assert_eq(num2words_int(200, "tr", "ordinal"), "ikiyüzüncü")
  assert_eq(num2words_int(1000, "tr", "ordinal"), "bininci")
  assert_eq(num2words_int(1001, "tr", "ordinal"), "binbirinci")
  assert_eq(num2words_int(2000, "tr", "ordinal"), "ikibininci")
  assert_eq(num2words_int(1000000, "tr", "ordinal"), "birmilyonuncu")
  assert_eq(
    num2words_int(591170, "tr", "ordinal"),
    "beşyüzdoksanbinyüzyetmişinci",
  )
  // Upstream's 10^18 ordinal entry lacks the "-uncu" suffix.
  assert_eq(
    num2words(BigInt::from_string("1000000000000000000"), "tr", "ordinal"),
    "birkentilyon",
  )
  assert_eq(num2words_int(1, "tr", "ordinal_num"), "1inci")
  assert_eq(num2words_int(3, "tr", "ordinal_num"), "3üncü")
  assert_eq(num2words_int(100, "tr", "ordinal_num"), "100üncü")
  assert_eq(num2words_int(-1, "tr", "ordinal"), "")
}

///|
test "tr year and currency" {
  // No year-specific reading: a year is a cardinal.
  assert_eq(num2words_int(2024, "tr", "year"), "ikibinyirmidört")
  assert_eq(num2words_int(1900, "tr", "year"), "bindokuzyüz")
  assert_eq(currency_ok("0", "tr", ""), "bedelsiz")
  assert_eq(currency_ok("1", "tr", ""), "birlira")
  assert_eq(currency_ok("12.34", "tr", "TRY"), "onikiliraotuzdörtkuruş")
  assert_eq(currency_ok("1.5", "tr", "TRY"), "birliraellikuruş")
  assert_eq(currency_ok("-3.5", "tr", "TRY"), "eksiüçliraellikuruş")
  assert_eq(
    num2words_currency("1", "tr", "USD"),
    Err("currency code not supported for tr: USD"),
  )
}

// --- Vietnamese -------------------------------------------------------------

///|
test "vi cardinal" {
  assert_eq(num2words_int(0, "vi", "cardinal"), "không")
  assert_eq(num2words_int(21, "vi", "cardinal"), "hai mươi mốt")
  assert_eq(num2words_int(25, "vi", "cardinal"), "hai mươi lăm")
  assert_eq(num2words_int(105, "vi", "cardinal"), "một trăm lẻ năm")
  assert_eq(num2words_int(1001, "vi", "cardinal"), "một nghìn lẻ một")
  assert_eq(num2words_int(1010, "vi", "cardinal"), "một nghìn lẻ mười")
  assert_eq(num2words_int(1100, "vi", "cardinal"), "một nghìn một trăm")
  assert_eq(
    num2words_int(1234, "vi", "cardinal"),
    "một nghìn hai trăm ba mươi bốn",
  )
  assert_eq(
    num2words_int(123456789, "vi", "cardinal"),
    "một trăm hai mươi ba triệu bốn trăm năm mươi sáu nghìn bảy trăm tám mươi chín",
  )
  assert_eq(
    num2words(BigInt::from_string("1000000000000"), "vi", "cardinal"),
    "một nghìn tỷ",
  )
  assert_eq(
    num2words(BigInt::from_string("1000000000000000000"), "vi", "cardinal"),
    "một Quintillion",
  )
  // Upstream's negative handling is broken; this port spells it properly.
  assert_eq(num2words_int(-42, "vi", "cardinal"), "âm bốn mươi hai")
  assert_eq(num2words_str("1" + zeros(59), "vi", "cardinal").length() > 0, true)
  assert_eq(num2words_str("1" + zeros(60), "vi", "cardinal"), "")
}

///|
test "vi ordinal aliases cardinal; year/ordinal_num/currency are absent" {
  assert_eq(num2words_int(21, "vi", "ordinal"), "hai mươi mốt")
  assert_eq(num2words_int(105, "vi", "ordinal"), "một trăm lẻ năm")
  assert_eq(num2words_int(21, "vi", "ordinal_num"), "")
  assert_eq(num2words_int(2024, "vi", "year"), "")
  assert_eq(
    num2words_currency("1", "vi", "EUR"),
    Err("currency not implemented for language: vi"),
  )
}

// --- default currency codes -------------------------------------------------

///|
test "currency: language defaults" {
  // The to="currency" dispatch used to force EUR, which lost pt's BRL default.
  assert_eq(num2words_str("1", "pt", "currency"), "um real")
  assert_eq(num2words_str("1", "nl", "currency"), "één euro, nul cent")
  assert_eq(num2words_str("1", "tr", "currency"), "birlira")
  assert_eq(num2words_str_checked("1", "tr", "currency"), Ok("birlira"))
  // CJK defaults: plain 元 for Chinese (upstream master's "XXX"), yen/won.
  assert_eq(num2words_str("1", "zh", "currency"), "一元")
  assert_eq(num2words_str("1", "zh_TW", "currency"), "一元")
  assert_eq(num2words_str("1", "ja", "currency"), "一円")
  assert_eq(num2words_str("1", "ko", "currency"), "일원")
}

// --- Chinese ----------------------------------------------------------------
// The grammar advances by 10^4, speaks one 零 for a gap below 1000 and drops
// the 一 of a leading 一十. Upstream 0.5.14 has no Chinese module; these
// expectations follow upstream master's lang_ZH.py (see COMPAT.md §3).

///|
test "zh cardinal" {
  assert_eq(num2words_int(0, "zh", "cardinal"), "零")
  assert_eq(num2words_int(9, "zh", "cardinal"), "九")
  assert_eq(num2words_int(10, "zh", "cardinal"), "十")
  assert_eq(num2words_int(11, "zh", "cardinal"), "十一")
  assert_eq(num2words_int(19, "zh", "cardinal"), "十九")
  assert_eq(num2words_int(20, "zh", "cardinal"), "二十")
  assert_eq(num2words_int(101, "zh", "cardinal"), "一百零一")
  assert_eq(num2words_int(110, "zh", "cardinal"), "一百一十")
  assert_eq(num2words_int(1001, "zh", "cardinal"), "一千零一")
  assert_eq(num2words_int(1010, "zh", "cardinal"), "一千零一十")
  assert_eq(num2words_int(1100, "zh", "cardinal"), "一千一百")
  assert_eq(num2words_int(10000, "zh", "cardinal"), "一万")
  assert_eq(num2words_int(10001, "zh", "cardinal"), "一万零一")
  assert_eq(num2words_int(10010, "zh", "cardinal"), "一万零一十")
  assert_eq(num2words_int(10100, "zh", "cardinal"), "一万零一百")
  assert_eq(num2words_int(11000, "zh", "cardinal"), "一万一千")
  assert_eq(num2words_int(100000, "zh", "cardinal"), "十万")
  assert_eq(num2words_int(1000000, "zh", "cardinal"), "一百万")
  assert_eq(
    num2words_int(12345678, "zh", "cardinal"),
    "一千二百三十四万五千六百七十八",
  )
  assert_eq(num2words_int(100000000, "zh", "cardinal"), "一亿")
  assert_eq(num2words_str("1000000000000", "zh", "cardinal"), "一兆")
  assert_eq(num2words_int(-42, "zh", "cardinal"), "负四十二")
  // 10^72 is the last scale word (不可说); 10^76 is past the table.
  assert_eq(num2words_str("1" + zeros(72), "zh", "cardinal"), "一不可说")
  assert_eq(num2words_str("1" + zeros(76), "zh", "cardinal"), "")
  assert_eq(lang_zh().max_power(), 18)
}

///|
test "zh_TW cardinal uses traditional characters" {
  assert_eq(num2words_int(1234, "zh_TW", "cardinal"), "一千二百三十四")
  assert_eq(num2words_int(10000, "zh_TW", "cardinal"), "一萬")
  assert_eq(num2words_int(100000000, "zh_TW", "cardinal"), "一億")
  assert_eq(num2words_int(-1, "zh_TW", "cardinal"), "負一")
  assert_eq(num2words_str("1" + zeros(72), "zh_TW", "cardinal"), "一不可說")
}

///|
test "zh ordinal, ordinal_num and year" {
  assert_eq(num2words_int(0, "zh", "ordinal"), "第零")
  assert_eq(num2words_int(10, "zh", "ordinal"), "第十")
  assert_eq(num2words_int(101, "zh", "ordinal"), "第一百零一")
  assert_eq(num2words_int(1234, "zh", "ordinal"), "第一千二百三十四")
  assert_eq(num2words_int(1234, "zh", "ordinal_num"), "第1234")
  assert_eq(num2words_int(-1, "zh", "ordinal"), "")
  assert_eq(num2words_int(-1, "zh", "ordinal_num"), "")
  assert_eq(num2words_int(2024, "zh", "year"), "二零二四年")
  assert_eq(num2words_int(0, "zh", "year"), "零年")
  assert_eq(num2words_int(-44, "zh", "year"), "公元前四四年")
}

///|
test "zh float and currency" {
  assert_eq(
    num2words_str("1234.56", "zh", "cardinal"),
    "一千二百三十四点五六",
  )
  assert_eq(num2words_str("-0.5", "zh", "cardinal"), "负零点五")
  assert_eq(
    num2words_currency("1234.56", "zh", ""),
    Ok("一千二百三十四元五角六分"),
  )
  assert_eq(
    num2words_currency("1234.56", "zh", "CNY"),
    Ok("人民币一千二百三十四元五角六分"),
  )
  assert_eq(num2words_currency("0.05", "zh", "XXX"), Ok("零元零五分"))
  assert_eq(num2words_currency("0.5", "zh", "USD"), Ok("美元零元五角"))
  assert_eq(
    num2words_currency("-3.5", "zh", "USD"),
    Ok("美元负三元五角"),
  )
  assert_eq(
    num2words_currency("1", "zh", "ABC"),
    Err("currency code not supported for zh: ABC"),
  )
  assert_eq(
    num2words_currency("1234.56", "zh_TW", "CNY"),
    Ok("人民幣一千二百三十四元五角六分"),
  )
}

// --- Japanese ---------------------------------------------------------------

///|
test "ja cardinal" {
  assert_eq(num2words_int(0, "ja", "cardinal"), "零")
  assert_eq(num2words_int(10, "ja", "cardinal"), "十")
  assert_eq(num2words_int(11, "ja", "cardinal"), "十一")
  assert_eq(num2words_int(100, "ja", "cardinal"), "百")
  assert_eq(num2words_int(101, "ja", "cardinal"), "百一")
  assert_eq(num2words_int(110, "ja", "cardinal"), "百十")
  assert_eq(num2words_int(1000, "ja", "cardinal"), "千")
  assert_eq(num2words_int(1001, "ja", "cardinal"), "千一")
  assert_eq(num2words_int(1010, "ja", "cardinal"), "千十")
  assert_eq(num2words_int(1100, "ja", "cardinal"), "千百")
  assert_eq(num2words_int(10000, "ja", "cardinal"), "一万")
  assert_eq(num2words_int(10001, "ja", "cardinal"), "一万一")
  assert_eq(
    num2words_int(12345, "ja", "cardinal"),
    "一万二千三百四十五",
  )
  assert_eq(num2words_int(100000, "ja", "cardinal"), "十万")
  assert_eq(num2words_int(100000000, "ja", "cardinal"), "一億")
  assert_eq(num2words_str("1000000000000", "ja", "cardinal"), "一兆")
  assert_eq(num2words_int(-42, "ja", "cardinal"), "マイナス四十二")
  assert_eq(num2words_str("1" + zeros(48), "ja", "cardinal"), "一極")
  assert_eq(num2words_str("1" + zeros(52), "ja", "cardinal"), "")
  assert_eq(lang_ja().max_power(), 12)
}

///|
test "ja ordinal and era year" {
  assert_eq(num2words_int(21, "ja", "ordinal"), "二十一番目")
  assert_eq(num2words_int(0, "ja", "ordinal"), "零番目")
  assert_eq(num2words_int(21, "ja", "ordinal_num"), "21番目")
  assert_eq(num2words_int(-1, "ja", "ordinal"), "")
  assert_eq(num2words_int(-1, "ja", "ordinal_num"), "")
  assert_eq(num2words_int(645, "ja", "year"), "大化元年")
  assert_eq(num2words_int(749, "ja", "year"), "天平勝宝元年")
  assert_eq(num2words_int(2019, "ja", "year"), "令和元年")
  assert_eq(num2words_int(2024, "ja", "year"), "令和六年")
  // Before the first era upstream raises; this API returns "".
  assert_eq(num2words_int(644, "ja", "year"), "")
  assert_eq(num2words_int(-1, "ja", "year"), "")
}

///|
test "ja float and currency" {
  assert_eq(
    num2words_str("1234.56", "ja", "cardinal"),
    "千二百三十四点五六",
  )
  assert_eq(num2words_str("-0.5", "ja", "cardinal"), "マイナス零点五")
  assert_eq(num2words_currency("1000", "ja", "JPY"), Ok("千円"))
  assert_eq(num2words_currency("-3", "ja", "JPY"), Ok("マイナス三円"))
  assert_eq(
    num2words_currency("1234.56", "ja", "JPY"),
    Err("decimals not supported for JPY"),
  )
  assert_eq(
    num2words_currency("1", "ja", "USD"),
    Err("currency code not supported for ja: USD"),
  )
}

// --- Korean -----------------------------------------------------------------

///|
test "ko cardinal" {
  assert_eq(num2words_int(0, "ko", "cardinal"), "영")
  assert_eq(num2words_int(10, "ko", "cardinal"), "십")
  assert_eq(num2words_int(21, "ko", "cardinal"), "이십일")
  assert_eq(num2words_int(100, "ko", "cardinal"), "백")
  assert_eq(num2words_int(101, "ko", "cardinal"), "백일")
  assert_eq(num2words_int(1000, "ko", "cardinal"), "천")
  assert_eq(num2words_int(1100, "ko", "cardinal"), "천백")
  assert_eq(num2words_int(10000, "ko", "cardinal"), "만")
  assert_eq(num2words_int(10001, "ko", "cardinal"), "만 일")
  assert_eq(num2words_int(10010, "ko", "cardinal"), "만 십")
  assert_eq(num2words_int(12345, "ko", "cardinal"), "만 이천삼백사십오")
  assert_eq(
    num2words_int(12345678, "ko", "cardinal"),
    "천이백삼십사만 오천육백칠십팔",
  )
  assert_eq(num2words_int(100000000, "ko", "cardinal"), "일억")
  assert_eq(num2words_int(100000001, "ko", "cardinal"), "일억 일")
  assert_eq(num2words_int(-42, "ko", "cardinal"), "마이너스 사십이")
  assert_eq(num2words_str("1" + zeros(68), "ko", "cardinal"), "일무량대수")
  assert_eq(num2words_str("1" + zeros(72), "ko", "cardinal"), "")
  assert_eq(lang_ko().max_power(), 17)
}

///|
test "ko ordinal and year" {
  assert_eq(num2words_int(1, "ko", "ordinal"), "첫 번째")
  assert_eq(num2words_int(2, "ko", "ordinal"), "두 번째")
  assert_eq(num2words_int(11, "ko", "ordinal"), "열한 번째")
  assert_eq(num2words_int(20, "ko", "ordinal"), "스물 번째")
  assert_eq(num2words_int(21, "ko", "ordinal"), "스물한 번째")
  assert_eq(num2words_int(101, "ko", "ordinal"), "백 한 번째")
  assert_eq(
    num2words_int(123456, "ko", "ordinal"),
    "십이만 삼천사백 쉰여섯 번째",
  )
  // Upstream raises KeyError for these; the string API returns "".
  assert_eq(num2words_int(0, "ko", "ordinal"), "")
  assert_eq(num2words_int(100, "ko", "ordinal"), "")
  assert_eq(num2words_int(1000, "ko", "ordinal"), "")
  assert_eq(num2words_int(10000, "ko", "ordinal"), "")
  assert_eq(num2words_int(21, "ko", "ordinal_num"), "21 번째")
  assert_eq(num2words_int(-1, "ko", "ordinal"), "")
  assert_eq(num2words_int(-1, "ko", "ordinal_num"), "")
  assert_eq(num2words_int(2024, "ko", "year"), "이천이십사년")
  assert_eq(num2words_int(700, "ko", "year"), "칠백년")
  assert_eq(num2words_int(-44, "ko", "year"), "기원전 사십사년")
}

///|
test "ko float and currency" {
  assert_eq(
    num2words_str("1234.56", "ko", "cardinal"),
    "천이백삼십사 점 오 육",
  )
  assert_eq(num2words_str("-0.5", "ko", "cardinal"), "마이너스 영 점 오")
  assert_eq(num2words_currency("1000", "ko", "KRW"), Ok("천원"))
  assert_eq(num2words_currency("1", "ko", "USD"), Ok("일달러 영센트"))
  assert_eq(
    num2words_currency("1234.56", "ko", "USD"),
    Ok("천이백삼십사달러 오십육센트"),
  )
  assert_eq(
    num2words_currency("-3.5", "ko", "USD"),
    Ok("마이너스 삼달러 오십센트"),
  )
  assert_eq(
    num2words_currency("1234.56", "ko", "KRW"),
    Err("decimals not supported for KRW"),
  )
  assert_eq(
    num2words_currency("1", "ko", "EUR"),
    Err("currency code not supported for ko: EUR"),
  )
}

// --- Swedish ----------------------------------------------------------------

///|
test "sv cardinal and ordinal" {
  assert_eq(num2words_int(0, "sv", "cardinal"), "noll")
  assert_eq(num2words_int(21, "sv", "cardinal"), "tjugoett")
  assert_eq(num2words_int(100, "sv", "cardinal"), "etthundra")
  assert_eq(num2words_int(1001, "sv", "cardinal"), "etttusenett")
  assert_eq(num2words_int(1000000, "sv", "cardinal"), "en miljon")
  assert_eq(
    num2words_int(1234, "sv", "cardinal"),
    "etttusen tvåhundratrettiofyra",
  )
  assert_eq(num2words_int(-42, "sv", "cardinal"), "minus förtiotvå")
  assert_eq(
    num2words_str("1000000000000000000", "sv", "cardinal"),
    "en triljon",
  )
  assert_eq(num2words_int(1, "sv", "ordinal"), "första")
  assert_eq(num2words_int(21, "sv", "ordinal"), "tjugoförsta")
  assert_eq(num2words_int(100, "sv", "ordinal"), "etthundrade")
  // Upstream leaves these three modes unimplemented.
  assert_eq(num2words_int(21, "sv", "ordinal_num"), "")
  assert_eq(num2words_int(2024, "sv", "year"), "")
  assert_eq(
    num2words_currency("1", "sv", "SEK"),
    Err("currency not implemented for language: sv"),
  )
}

// --- Norwegian --------------------------------------------------------------

///|
test "no cardinal, ordinal and year" {
  assert_eq(num2words_int(100, "no", "cardinal"), "en hundre")
  assert_eq(num2words_int(101, "no", "cardinal"), "en hundre og en")
  assert_eq(
    num2words_int(1234, "no", "cardinal"),
    "en tusen to hundre og trettifire",
  )
  assert_eq(num2words_int(1000000, "no", "cardinal"), "en million")
  assert_eq(num2words_int(21, "no", "ordinal"), "tjueførste")
  // Upstream has no "tretten" entry in ords_pl, so 13 -> "trettførste".
  assert_eq(num2words_int(13, "no", "ordinal"), "trettførste")
  assert_eq(num2words_int(21, "no", "ordinal_num"), "21.")
  assert_eq(num2words_int(1900, "no", "year"), "nitten hundre")
  assert_eq(num2words_int(2024, "no", "year"), "to tusen og tjuefire")
}

///|
test "no currency" {
  assert_eq(num2words_currency("1", "no", ""), Ok("en krone"))
  assert_eq(num2words_currency("2", "no", "NOK"), Ok("to kroner"))
  assert_eq(num2words_currency("0", "no", "NOK"), Ok("null kroner"))
  assert_eq(
    num2words_currency("1234.56", "no", "NOK"),
    Ok("en tusen to hundre og trettifire kroner og femtiseks øre"),
  )
  assert_eq(
    num2words_currency("-3.5", "no", "NOK"),
    Ok("minus tre kroner og femti øre"),
  )
  assert_eq(
    num2words_currency("1", "no", "EUR"),
    Err("currency code not supported for no: EUR"),
  )
}

// --- Danish -----------------------------------------------------------------

///|
test "da cardinal, ordinal and year" {
  assert_eq(num2words_int(21, "da", "cardinal"), "enogtyve")
  assert_eq(num2words_int(1001, "da", "cardinal"), "ettusinde og et")
  assert_eq(num2words_int(1000000, "da", "cardinal"), "en millioner")
  assert_eq(
    num2words_int(1234, "da", "cardinal"),
    "ettusinde og tohundrede og fireogtredive",
  )
  assert_eq(num2words_int(-42, "da", "cardinal"), "minus toogfyrre")
  assert_eq(num2words_int(2, "da", "ordinal"), "anden")
  assert_eq(num2words_int(100, "da", "ordinal"), "ethundredete")
  assert_eq(num2words_int(2, "da", "ordinal_num"), "2en")
  assert_eq(num2words_int(3, "da", "ordinal_num"), "3ende")
  assert_eq(num2words_int(1900, "da", "year"), "nitten hundrede")
  assert_eq(num2words_int(2024, "da", "year"), "totusinde og fireogtyve")
}

///|
test "da currency follows float2tuple quirks" {
  // 0.5 is (0, 5) upstream, not fifty øre; zero is empty; 101 slices to
  // "en undrede og et kr".
  assert_eq(num2words_currency("0", "da", "DKK"), Ok(""))
  assert_eq(num2words_currency("1", "da", ""), Ok("en kr"))
  assert_eq(num2words_currency("0.5", "da", "DKK"), Ok("fem øre"))
  assert_eq(num2words_currency("101", "da", "DKK"), Ok("en undrede og et kr"))
  assert_eq(
    num2words_currency("1234.56", "da", "DKK"),
    Ok("ettusinde og tohundrede og fireogtredive kr og seksoghalvtreds øre"),
  )
  assert_eq(
    num2words_currency("-3.5", "da", "DKK"),
    Ok("minus tre kr og fem øre"),
  )
  assert_eq(
    num2words_currency("1", "da", "EUR"),
    Err("currency code not supported for da: EUR"),
  )
}

// --- Indonesian -------------------------------------------------------------

///|
test "id cardinal, ordinal, year and currency" {
  assert_eq(num2words_int(11, "id", "cardinal"), "sebelas")
  assert_eq(num2words_int(100, "id", "cardinal"), "seratus")
  assert_eq(num2words_int(1000, "id", "cardinal"), "seribu")
  assert_eq(
    num2words_int(1234, "id", "cardinal"),
    "seribu dua ratus tiga puluh empat",
  )
  assert_eq(num2words_int(-42, "id", "cardinal"), "min empat puluh dua")
  assert_eq(num2words_int(1, "id", "ordinal"), "pertama")
  assert_eq(num2words_int(2, "id", "ordinal"), "kedua")
  assert_eq(num2words_int(21, "id", "ordinal"), "kedua puluh satu")
  assert_eq(num2words_int(21, "id", "ordinal_num"), "ke-21")
  assert_eq(num2words_int(2024, "id", "year"), "dua ribu dua puluh empat")
  assert_eq(num2words_currency("1", "id", ""), Ok("satu koma nol rupiah"))
  assert_eq(
    num2words_currency("1234.56", "id", "IDR"),
    Ok("seribu dua ratus tiga puluh empat koma lima enam rupiah"),
  )
  assert_eq(num2words_currency("0.5", "id", "IDR"), Ok("nol koma lima rupiah"))
  assert_eq(
    num2words_currency("0.05", "id", "IDR"),
    Ok("nol koma nol lima rupiah"),
  )
  assert_eq(
    num2words_currency("-3.5", "id", "IDR"),
    Ok("min tiga koma lima rupiah"),
  )
  assert_eq(
    num2words_currency("1", "id", "EUR"),
    Err("currency code not supported for id: EUR"),
  )
}

// --- Polish -----------------------------------------------------------------

///|
test "pl cardinal, ordinal and year" {
  assert_eq(num2words_int(21, "pl", "cardinal"), "dwadzieścia jeden")
  assert_eq(num2words_int(10000, "pl", "cardinal"), "dziesięć tysięcy")
  assert_eq(num2words_int(1000000, "pl", "cardinal"), "milion")
  assert_eq(
    num2words_int(1234567, "pl", "cardinal"),
    "milion dwieście trzydzieści cztery tysiące pięćset sześćdziesiąt siedem",
  )
  // Upstream raises for negative input; this port spells it cleanly.
  assert_eq(num2words_int(-42, "pl", "cardinal"), "minus czterdzieści dwa")
  assert_eq(num2words_int(1, "pl", "ordinal"), "pierwszy")
  assert_eq(num2words_int(21, "pl", "ordinal"), "dwudziesty pierwszy")
  assert_eq(num2words_int(100, "pl", "ordinal"), "setny")
  assert_eq(
    num2words_int(1234, "pl", "ordinal"),
    "tysiąc dwieście trzydziesty czwarty",
  )
  assert_eq(num2words_int(1234, "pl", "ordinal_num"), "1234")
  assert_eq(
    num2words_int(2024, "pl", "year"),
    "dwa tysiące dwadzieścia cztery",
  )
  assert_eq(
    num2words_currency("1", "pl", "PLN"),
    Err("currency not implemented for language: pl"),
  )
}

// --- Arabic -----------------------------------------------------------------

///|
test "ar cardinal, ordinal and year" {
  assert_eq(num2words_int(0, "ar", "cardinal"), "صفر")
  assert_eq(num2words_int(1, "ar", "cardinal"), "واحد")
  assert_eq(num2words_int(21, "ar", "cardinal"), "واحد و عشرون")
  assert_eq(num2words_int(2000, "ar", "cardinal"), "ألفا")
  assert_eq(num2words_int(3000, "ar", "cardinal"), "ثلاثة آلاف")
  assert_eq(
    num2words_int(1234, "ar", "cardinal"),
    "ألف و مئتان و أربعة و ثلاثون",
  )
  assert_eq(num2words_int(1, "ar", "ordinal"), "اول")
  assert_eq(num2words_int(21, "ar", "ordinal"), "إحدى و عشرون")
  assert_eq(num2words_int(21, "ar", "ordinal_num"), "إحدى و عشرون")
  assert_eq(
    num2words_int(2024, "ar", "year"),
    "ألفان و أربعة و عشرون",
  )
  assert_eq(
    num2words_currency("1", "ar", "SAR"),
    Err("currency not implemented for language: ar"),
  )
}

// --- Thai -------------------------------------------------------------------

///|
test "th cardinal, ordinal and year" {
  assert_eq(num2words_int(0, "th", "cardinal"), "ศูนย์")
  assert_eq(num2words_int(11, "th", "cardinal"), "สิบเอ็ด")
  assert_eq(
    num2words_int(21, "th", "cardinal"),
    "ยี่สิบเอ็ด",
  )
  assert_eq(
    num2words_int(101, "th", "cardinal"),
    "หนึ่งร้อยเอ็ด",
  )
  assert_eq(
    num2words_int(1001, "th", "cardinal"),
    "หนึ่งพันเอ็ด",
  )
  assert_eq(
    num2words_int(1234, "th", "cardinal"),
    "หนึ่งพันสองร้อยสามสิบสี่",
  )
  assert_eq(
    num2words_int(-42, "th", "cardinal"),
    "ติดลบสี่สิบสอง",
  )
  assert_eq(
    num2words_int(21, "th", "ordinal"),
    "ยี่สิบเอ็ด",
  )
  assert_eq(num2words_int(21, "th", "ordinal_num"), "21")
  assert_eq(
    num2words_int(2024, "th", "year"),
    "สองพันยี่สิบสี่",
  )
  assert_eq(
    num2words_currency("1", "th", "THB"),
    Err("currency not implemented for language: th"),
  )
}

// --- Finnish ----------------------------------------------------------------

///|
test "fi cardinal, ordinal and year" {
  assert_eq(num2words_int(0, "fi", "cardinal"), "nolla")
  assert_eq(num2words_int(21, "fi", "cardinal"), "kaksikymmentäyksi")
  assert_eq(num2words_int(100, "fi", "cardinal"), "sata")
  assert_eq(num2words_int(101, "fi", "cardinal"), "satayksi")
  assert_eq(num2words_int(1000, "fi", "cardinal"), "tuhat")
  assert_eq(
    num2words_int(1234, "fi", "cardinal"),
    "tuhat kaksisataakolmekymmentäneljä",
  )
  assert_eq(num2words_int(-42, "fi", "cardinal"), "miinus neljäkymmentäkaksi")
  assert_eq(num2words_int(1, "fi", "ordinal"), "ensimmäinen")
  assert_eq(num2words_int(21, "fi", "ordinal"), "kahdeskymmenesensimmäinen")
  assert_eq(num2words_int(1000, "fi", "ordinal"), "tuhannes")
  assert_eq(
    num2words_int(1234, "fi", "ordinal"),
    "tuhannes kahdessadaskolmaskymmenesneljäs",
  )
  // Upstream has no ordinal_num for Finnish.
  assert_eq(num2words_int(21, "fi", "ordinal_num"), "")
  assert_eq(
    num2words_int(2024, "fi", "year"),
    "kaksituhattakaksikymmentäneljä",
  )
  assert_eq(num2words_int(-3, "fi", "year"), "kolme ennen ajanlaskun alkua")
}

///|
test "fi currency" {
  assert_eq(
    num2words_currency("1.5", "fi", "EUR"),
    Ok("yksi euro ja viisikymmentä senttiä"),
  )
  assert_eq(
    num2words_currency("1234.56", "fi", "EUR"),
    Ok(
      "tuhat kaksisataakolmekymmentäneljä euroa ja viisikymmentäkuusi senttiä",
    ),
  )
  assert_eq(
    num2words_currency("-3.5", "fi", "EUR"),
    Ok("miinus kolme euroa ja viisikymmentä senttiä"),
  )
  assert_eq(
    num2words_currency("1", "fi", "XYZ"),
    Err("currency code not supported for fi: XYZ"),
  )
}

// --- Ukrainian --------------------------------------------------------------

///|
test "uk cardinal, ordinal and year" {
  assert_eq(num2words_int(0, "uk", "cardinal"), "нуль")
  assert_eq(num2words_int(21, "uk", "cardinal"), "двадцять один")
  assert_eq(num2words_int(1000, "uk", "cardinal"), "одна тисяча")
  assert_eq(num2words_int(2000, "uk", "cardinal"), "дві тисячі")
  assert_eq(num2words_int(5000, "uk", "cardinal"), "п'ять тисяч")
  assert_eq(
    num2words_int(1234, "uk", "cardinal"),
    "одна тисяча двісті тридцять чотири",
  )
  assert_eq(
    num2words_int(-42, "uk", "cardinal"),
    "мінус сорок два",
  )
  assert_eq(num2words_int(1, "uk", "ordinal"), "перший")
  assert_eq(num2words_int(21, "uk", "ordinal"), "двадцять перший")
  assert_eq(num2words_int(1000, "uk", "ordinal"), "тисячний")
  assert_eq(num2words_int(100000, "uk", "ordinal"), "стотисячний")
  assert_eq(
    num2words_int(1234, "uk", "ordinal"),
    "одна тисяча двісті тридцять четвертий",
  )
  assert_eq(num2words_int(1234, "uk", "ordinal_num"), "1234")
  assert_eq(
    num2words_int(2024, "uk", "year"),
    "дві тисячі двадцять чотири",
  )
  assert_eq(
    num2words_currency("1", "uk", "UAH"),
    Err("currency not implemented for language: uk"),
  )
}
