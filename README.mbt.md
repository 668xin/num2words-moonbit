# 668xin/num2words-moonbit

Convert numbers into words in pure MoonBit — a port of the Python `num2words`
library. Supports English, French, Spanish and German across cardinal, ordinal,
ordinal_num, year and currency modes, with arbitrarily large integers via
`BigInt`.

## Quick start

```mbt
import "668xin/num2words-moonbit" @n2w

@n2w.num2words_int(1234, "en", "cardinal")   // "one thousand, two hundred and thirty-four"
@n2w.num2words_int(2024, "en", "year")       // "twenty twenty-four"
@n2w.num2words_str("1234.56", "en", "cardinal") // "one thousand, two hundred and thirty-four point five six"
```

## API

- `num2words(value : BigInt, lang : String, to : String) -> String`
- `num2words_int(value : Int, lang : String, to : String) -> String`
- `num2words_float(value : Double, lang : String, to : String) -> String`
- `num2words_str(value : String, lang : String, to : String) -> String`

`lang` ∈ `{"en","fr","es","de"}` (default `en`); `to` ∈
`{"cardinal","ordinal","ordinal_num","year","currency"}` (default `cardinal`).

## License

LGPL-2.1. Derived from Python `num2words` (Savoirfairelinux, LGPL-2.1).
