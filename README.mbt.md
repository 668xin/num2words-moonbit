# 668xin/num2words-moonbit

Convert numbers into words in pure MoonBit — a port of the Python `num2words`
library. Supports English, French, Spanish, German, Italian, Portuguese and
Russian across cardinal, ordinal, ordinal_num, year and currency modes, with
`BigInt` for large integers. Currency is native for all seven languages with
each language's upstream ISO code set (EUR by default, BRL for `pt`).

## Quick start

```mbt nocheck
import "668xin/num2words-moonbit" @n2w

@n2w.num2words_int(1234, "en", "cardinal")   // "one thousand, two hundred and thirty-four"
@n2w.num2words_int(2024, "en", "year")       // "twenty twenty-four"
@n2w.num2words_str("1234.56", "en", "cardinal") // "one thousand, two hundred and thirty-four point five six"
@n2w.num2words_int(1000, "ru", "cardinal")   // "одна тысяча"
@n2w.num2words_currency("1234.56", "en", "EUR")
// Ok("one thousand, two hundred and thirty-four euro, fifty-six cents")
```

## API

- `num2words(value : BigInt, lang : String, to : String) -> String`
- `num2words_int(value : Int, lang : String, to : String) -> String`
- `num2words_float(value : Double, lang : String, to : String) -> String`
- `num2words_str(value : String, lang : String, to : String) -> String`
- `num2words_currency(amount : String, lang : String, code : String) -> Result[String, String]`

`lang` ∈ `{"en","fr","es","de","it","pt","ru"}` (default `en`); `to` ∈
`{"cardinal","ordinal","ordinal_num","year","currency"}` (default `cardinal`).
Currency codes are language-dependent: `en`/`fr`/`de`/`it` take `EUR`/`USD`/
`GBP`, `es` takes 20 codes, `ru` takes 6, and `pt` accepts only `BRL`. The
empty code `""` selects the language default (EUR, or BRL for `pt`).

## License

LGPL-2.1. Derived from Python `num2words` (Savoirfairelinux, LGPL-2.1).
