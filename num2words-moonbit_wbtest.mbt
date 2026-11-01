// Whitebox tests for num2words-moonbit.
// Compiled inside the package, so no `import` is needed and every top-level
// function (including the per-language helpers) is in scope directly.
// Run with `moon test` from the project root.

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

test "en cardinal groups" {
  assert_eq(num2words_int(1000001, "en", "cardinal"), "one million, one")
  assert_eq(
    num2words_int(1234567, "en", "cardinal"),
    "one million, two hundred and thirty-four thousand, five hundred and sixty-seven",
  )
  assert_eq(
    num2words(BigInt::from_string("1000000000"), "en", "cardinal"),
    "one billion",
  )
}

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

test "en year" {
  assert_eq(year_en(BigInt::from_int(2024)), "twenty twenty-four")
  assert_eq(year_en(BigInt::from_int(1984)), "nineteen eighty-four")
  assert_eq(year_en(BigInt::from_int(2000)), "two thousand")
  assert_eq(year_en(BigInt::from_int(1900)), "nineteen hundred")
}

test "en currency" {
  assert_eq(
    currency_en(BigInt::from_int(1234), BigInt::from_int(0)),
    "one thousand, two hundred and thirty-four dollars",
  )
  assert_eq(
    currency_en(BigInt::from_int(1234), BigInt::from_int(56)),
    "one thousand, two hundred and thirty-four dollars and fifty-six cents",
  )
}

test "en float" {
  assert_eq(
    num2words_float(1234.56, "en", "cardinal"),
    "one thousand, two hundred and thirty-four point five six",
  )
}

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
  assert_eq(num2words_int(1234, "fr", "cardinal"), "mille deux cent trente-quatre")
  assert_eq(num2words_int(-42, "fr", "cardinal"), "moins quarante-deux")
}

test "fr year" {
  assert_eq(year_fr(BigInt::from_int(2024)), "vingt vingt-quatre")
}

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
}

test "es year" {
  assert_eq(year_es(BigInt::from_int(2024)), "veinte veinticuatro")
}

test "de cardinal" {
  assert_eq(num2words_int(42, "de", "cardinal"), "zweiundvierzig")
  assert_eq(num2words_int(21, "de", "cardinal"), "einundzwanzig")
  assert_eq(num2words_int(100, "de", "cardinal"), "einhundert")
  assert_eq(num2words_int(101, "de", "cardinal"), "einhunderteins")
  assert_eq(num2words_int(200, "de", "cardinal"), "zweihundert")
  assert_eq(num2words_int(1000, "de", "cardinal"), "tausend")
  assert_eq(num2words_int(2000, "de", "cardinal"), "zweitausend")
  assert_eq(num2words_int(1000000, "de", "cardinal"), "eine Million")
  assert_eq(
    num2words_int(1234, "de", "cardinal"),
    "tausendzweihundertvierunddreißig",
  )
}

test "de year" {
  assert_eq(year_de(BigInt::from_int(2024)), "zwanzig vierundzwanzig")
}

test "decimal string input" {
  assert_eq(
    num2words_str("1234.56", "en", "cardinal"),
    "one thousand, two hundred and thirty-four point five six",
  )
  assert_eq(num2words_str("1000000", "de", "cardinal"), "eine Million")
  assert_eq(num2words_str("-42", "en", "cardinal"), "minus forty-two")
}

// --- M1: validation and boundaries ------------------------------------------

test "input validation accepts well-formed numbers" {
  assert_eq(is_valid_number("0"), true)
  assert_eq(is_valid_number("1234"), true)
  assert_eq(is_valid_number("007"), true)
  assert_eq(is_valid_number("-42"), true)
  assert_eq(is_valid_number("1234.56"), true)
  assert_eq(is_valid_number("-0.5"), true)
  assert_eq(is_valid_number("1000000000000000000000"), true)
}

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

test "malformed input returns empty string instead of aborting" {
  assert_eq(num2words_str("abc", "en", "cardinal"), "")
  assert_eq(num2words_str("1.2.3", "en", "cardinal"), "")
  assert_eq(num2words_str("", "en", "cardinal"), "")
  assert_eq(num2words_str("-", "en", "cardinal"), "")
}

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
  assert_eq(num2words_int(0, "en", "currency"), "zero dollars")
  assert_eq(num2words_int(-1, "en", "ordinal"), "minus first")
}

// --- M1: path consistency ---------------------------------------------------
// The Int / BigInt / String entry points must agree on the same value; this is
// the invariant that guards against divergence between the parsing paths.

test "path consistency: string and int agree" {
  let samples = [0, 1, 9, 10, 21, 42, 100, 101, 999, 1000, 1234, 1000000, 1234567]
  for i = 0; i < samples.length(); i = i + 1 {
    let n = samples[i]
    assert_eq(
      num2words_str(n.to_string(), "en", "cardinal"),
      num2words_int(n, "en", "cardinal"),
    )
  }
}

test "path consistency: string and int agree in every language" {
  let langs = ["en", "fr", "es", "de"]
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
