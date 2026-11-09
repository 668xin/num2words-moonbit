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
  assert_eq(year_fr(BigInt::from_int(2024)), "vingt vingt-quatre")
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
}

///|
test "es year" {
  assert_eq(year_es(BigInt::from_int(2024)), "veinte veinticuatro")
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
  assert_eq(year_de(BigInt::from_int(2024)), "zwanzig vierundzwanzig")
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
  // "e" after a scale group only when the next group is < 100 or a multiple
  // of 100
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
  let langs = ["en", "fr", "es", "de", "it", "pt", "ru"]
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
