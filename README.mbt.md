# 668xin/num2words-moonbit

Convert numbers into words in pure MoonBit — a port of the Python `num2words`
library. Supports English, French, Spanish, German, Italian, Portuguese
(Brazilian `pt` and European `pt_PT`), Russian, Dutch, Turkish and Vietnamese
across cardinal, ordinal, ordinal_num, year and currency modes, with `BigInt`
for large integers. Currency is native for the ten language codes that
implement it upstream, each with its upstream ISO code set (EUR by default,
BRL for `pt`, TRY for `tr`).

## Quick start

```bash
moon add 668xin/num2words-moonbit
```

```mbt nocheck
import "668xin/num2words-moonbit" @n2w

@n2w.num2words_int(1234, "en", "cardinal")   // "one thousand, two hundred and thirty-four"
@n2w.num2words_int(2024, "en", "year")       // "twenty twenty-four"
@n2w.num2words_str("1234.56", "en", "cardinal") // "one thousand, two hundred and thirty-four point five six"
@n2w.num2words_int(1000, "ru", "cardinal")   // "одна тысяча"
@n2w.num2words_int(21, "nl", "ordinal")      // "eenentwintigste"
@n2w.num2words_int(1234, "tr", "cardinal")   // "binikiyüzotuzdört"
@n2w.num2words_int(1001, "vi", "cardinal")   // "một nghìn lẻ một"
@n2w.num2words_currency("1234.56", "en", "EUR")
// Ok("one thousand, two hundred and thirty-four euro, fifty-six cents")
```

## API

- `num2words(value : BigInt, lang : String, to : String) -> String`
- `num2words_int(value : Int, lang : String, to : String) -> String`
- `num2words_float(value : Double, lang : String, to : String) -> String`
- `num2words_str(value : String, lang : String, to : String) -> String`
- `num2words_currency(amount : String, lang : String, code : String) -> Result[String, String]`

`lang` ∈ `{"en","fr","es","de","it","pt","pt_PT","ru","nl","tr","vi"}` (default
`en`); `to` ∈ `{"cardinal","ordinal","ordinal_num","year","currency"}`
(default `cardinal`). Currency codes are language-dependent: `en` has 11
(EUR/USD/GBP/RUB/CAD/AUD/INR/SEK/NOK/PLN/MXN), `fr`/`de`/`it`/`nl` have 4
(EUR/USD/GBP/CNY), `es` 20, `ru` 6, `pt` only `BRL`, `pt_PT` 5
(EUR/USD/GBP/CAD/AUD), and `tr` only `TRY`. The empty code `""` selects the
language default (EUR, BRL for `pt`, TRY for `tr`). Vietnamese implements
cardinal and ordinal only, matching upstream.

## License

LGPL-2.1. Derived from Python `num2words` (Savoirfairelinux, LGPL-2.1).
