# 668xin/num2words-moonbit

Convert numbers into words in pure MoonBit — a port of the Python `num2words`
library. Supports 29 language codes: English, French, Spanish, German, Italian,
Portuguese (Brazilian `pt` and European `pt_PT`), Russian, Dutch, Turkish,
Vietnamese, Simplified/Traditional Chinese, Japanese, Korean, Swedish,
Norwegian, Danish, Indonesian, Polish, Arabic, Thai, Finnish, Ukrainian,
Romanian, Hungarian, Hebrew, Persian and Esperanto
across cardinal, ordinal, ordinal_num, year and currency modes where upstream
implements them, with `BigInt` for large integers. Currency is native for 23 of
them, each with its upstream ISO code set (EUR by default, BRL for `pt`, TRY
for `tr`, 元/`XXX` for `zh`, JPY for `ja`, KRW for `ko`, NOK for `no`, DKK for
`da`, IDR for `id`, RON for `ro`, HUF for `hu`, ILS for `he`, 24 codes for
`fi`; Persian writes tomans and takes no code).

## Quick start

```bash
moon add 668xin/num2words-moonbit
```

> The published `0.1.0` predates this rework (seven language codes); the
> 29-language, 338-currency-entry version in the repository is pending release
> as `0.1.1`.

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

`lang` ∈ `{"en","fr","es","de","it","pt","pt_PT","ru","nl","tr","vi","zh","zh_TW","ja","ko","sv","no","da","id","pl","ar","th","fi","uk","ro","hu","he","fa","eo"}`
(default `en`); `to` ∈ `{"cardinal","ordinal","ordinal_num","year","currency"}`
(default `cardinal`). Currency codes are language-dependent: `en` has 20,
`fr`/`de` 5 each, `it`/`nl` 4 each, `es` 171, `ru` 8, `pt` only `BRL`,
`pt_PT` 5, `tr` only `TRY`, `ja` only `JPY`, `ko` 3 (KRW/USD/JPY), `no` only
`NOK`, `da` only `DKK`, `id` only `IDR`, `fi` 24, `ro`/`hu` 20 each,
`he` 3 (ILS/EUR/USD), `eo` 5, and `zh`/`zh_TW` 17 (including `XXX` for plain
元); Persian writes tomans and accepts no code. The empty code `""` selects the
language default. Vietnamese and Swedish implement cardinal/ordinal only;
Polish, Arabic, Thai and Ukrainian have no currency mode, and Finnish has no
`ordinal_num`, matching upstream.

## License

LGPL-2.1. Derived from Python `num2words` (Savoirfairelinux, LGPL-2.1).
