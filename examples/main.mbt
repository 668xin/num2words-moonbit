// examples/main.mbt — runnable demo of the public API.
//
//   moon run examples
//
// Covers every output mode and every language code (including both Portuguese
// variants) plus a currency conversion with an explicit ISO code.

///|
fn main {
  println("== cardinal ==")
  println(@lib.num2words_int(1234, "en", "cardinal"))
  println(@lib.num2words_int(1234, "fr", "cardinal"))
  println(@lib.num2words_int(1234, "es", "cardinal"))
  println(@lib.num2words_int(1234, "de", "cardinal"))
  println(@lib.num2words_int(1234, "it", "cardinal"))
  println(@lib.num2words_int(1234, "pt", "cardinal"))
  println(@lib.num2words_int(1234, "pt_PT", "cardinal"))
  println(@lib.num2words_int(1234, "ru", "cardinal"))
  println(@lib.num2words_int(1234, "nl", "cardinal"))
  println(@lib.num2words_int(1234, "tr", "cardinal"))
  println(@lib.num2words_int(1234, "vi", "cardinal"))
  println(@lib.num2words_int(1234, "zh", "cardinal"))
  println(@lib.num2words_int(1234, "zh_TW", "cardinal"))
  println(@lib.num2words_int(1234, "ja", "cardinal"))
  println(@lib.num2words_int(1234, "ko", "cardinal"))
  println(@lib.num2words_int(1234, "sv", "cardinal"))
  println(@lib.num2words_int(1234, "no", "cardinal"))
  println(@lib.num2words_int(1234, "da", "cardinal"))
  println(@lib.num2words_int(1234, "id", "cardinal"))
  println(@lib.num2words_int(1234, "pl", "cardinal"))

  println("")
  println("== other modes (en) ==")
  println(@lib.num2words_int(21, "en", "ordinal"))
  println(@lib.num2words_int(21, "en", "ordinal_num"))
  println(@lib.num2words_int(2024, "en", "year"))
  println(@lib.num2words_str("1234.56", "en", "cardinal"))

  println("")
  println("== currency ==")
  match @lib.num2words_currency("1234.56", "en", "USD") {
    Ok(words) => println(words)
    Err(msg) => println("error: " + msg)
  }
  match @lib.num2words_currency("2.02", "ru", "RUB") {
    Ok(words) => println(words)
    Err(msg) => println("error: " + msg)
  }
  match @lib.num2words_currency("1000000", "pt_PT", "EUR") {
    Ok(words) => println(words)
    Err(msg) => println("error: " + msg)
  }
  match @lib.num2words_currency("1234.56", "zh", "CNY") {
    Ok(words) => println(words)
    Err(msg) => println("error: " + msg)
  }
  match @lib.num2words_currency("1000", "ja", "JPY") {
    Ok(words) => println(words)
    Err(msg) => println("error: " + msg)
  }
  match @lib.num2words_currency("1234.56", "ko", "USD") {
    Ok(words) => println(words)
    Err(msg) => println("error: " + msg)
  }

  println("")
  println("== boundary ==")
  match @lib.num2words_str_checked("abc", "en", "cardinal") {
    Ok(words) => println(words)
    Err(msg) => println("error: " + msg)
  }
}
