// num2words — command line tool.
// Converts a number (integer or decimal, optionally very large) into words.
//
//   num2words <value> [--lang en|fr|es|de|it|pt|pt_PT|ru|nl|tr|vi|zh|zh_TW|ja|ko|sv|no|da|id|pl|ar|th|fi|uk|ro|hu|he|fa|eo|cs|sk|sr|lt|az]
//                     [--to cardinal|ordinal|ordinal_num|year|currency]
//                     [--currency EUR|USD|GBP]
//
// Examples:
//   num2words 1234
//   num2words 1234 --lang fr
//   num2words 2024 --to year
//   num2words 1234.56 --lang en --to cardinal
//   num2words 1234.56 --lang en --to currency --currency USD
//   num2words 1000000000000 --lang de
//
// Imports are declared in cmd/main/moon.pkg (aliases @lib and @env).

///|
fn usage() -> Unit {
  println(
    "num2words — convert numbers to words (MoonBit port of Python num2words)",
  )
  println("")
  println("Usage:")
  println(
    "  num2words <value> [--lang en|fr|es|de|it|pt|pt_PT|ru|nl|tr|vi|zh|zh_TW|ja|ko|sv|no|da|id|pl|ar|th|fi|uk|ro|hu|he|fa|eo|cs|sk|sr|lt|az] [--to cardinal|ordinal|ordinal_num|year|currency] [--currency CODE]",
  )
  println("")
  println(
    "Languages: en, fr, es, de, it, pt (Brazil), pt_PT (Europe), ru, nl, tr, vi, zh (Simplified Chinese), zh_TW (Traditional Chinese), ja, ko, sv, no, da, id, pl, ar, th, fi, uk, ro, hu, he, fa, eo, cs, sk, sr, lt, az",
  )
  println("Modes    : cardinal (default), ordinal, ordinal_num, year, currency")
  println(
    "Currency : ISO code, default EUR (BRL for pt, TRY for tr, AZN for az, 元/XXX for zh, JPY for ja, KRW for ko, NOK for no, DKK for da, IDR for id, RON for ro, HUF for hu, ILS for he; fa writes tomans); en/ro/hu 20, fr/de 5, it/nl 4, es 171, ru 8, pt_PT 5, ja 1, ko 3, he 3, eo 5, fi 24, zh/zh_TW 17, cs 2, sk 1, sr 3, lt 6, az 1",
  )
  println("")
  println("Examples:")
  println("  num2words 1234")
  println("  num2words 1234 --lang fr")
  println("  num2words 2024 --to year")
  println("  num2words 1234.56 --lang en --to cardinal")
  println("  num2words 1234.56 --lang en --to currency --currency USD")
}

///|
/// Parse `--lang` / `--to` / `--currency` / `--help` flags plus a single
/// positional value. Returns (value, lang, to, currency, help).
fn parse_opts(argv : Array[String]) -> (String, String, String, String, Bool) {
  let mut value = ""
  let mut lang = "en"
  let mut to = "cardinal"
  let mut currency = ""
  let mut help = false
  let mut i = 1 // skip argv[0] (program name)
  while i < argv.length() {
    let a = argv[i]
    if a == "--help" || a == "-h" {
      help = true
    } else if a == "--lang" || a == "-l" {
      i = i + 1
      if i < argv.length() {
        lang = argv[i]
      }
    } else if a == "--to" || a == "-t" {
      i = i + 1
      if i < argv.length() {
        to = argv[i]
      }
    } else if a == "--currency" || a == "-c" {
      i = i + 1
      if i < argv.length() {
        currency = argv[i]
      }
    } else if value == "" {
      value = a
    }
    i = i + 1
  }
  (value, lang, to, currency, help)
}

///|
fn main {
  let (value, lang, to, currency, help) = parse_opts(@env.args())
  if help {
    usage()
    return
  }
  if value == "" {
    usage()
    return
  }
  if to == "currency" {
    // Currency takes an explicit ISO code; an empty code lets the library
    // choose the language default (EUR, or BRL for pt).
    match @lib.num2words_currency(value, lang, currency) {
      Ok(words) => println(words)
      Err(msg) => eprintln("error: " + msg)
    }
    return
  }
  // num2words_str handles integers, big integers and decimals uniformly.
  // The checked variant reports malformed input instead of aborting.
  match @lib.num2words_str_checked(value, lang, to) {
    Ok(words) => println(words)
    Err(msg) => eprintln("error: " + msg)
  }
}
