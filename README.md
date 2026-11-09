# num2words-moonbit

[![CI](https://github.com/668xin/num2words-moonbit/actions/workflows/ci.yml/badge.svg)](https://github.com/668xin/num2words-moonbit/actions/workflows/ci.yml)
[![License: LGPL-2.1](https://img.shields.io/badge/License-LGPL--2.1-blue.svg)](LICENSE)

**Convert numbers into words — in pure [MoonBit](https://www.moonbitlang.com/).**

`num2words-moonbit` is a from-scratch MoonBit implementation of the classic
*number → words* library. It spells out integers (of arbitrary size via
`BigInt`), decimals, ordinals, years and currency amounts in **English,
French, Spanish, German, Italian, Portuguese (Brazilian and European) and
Russian**; currency is native for all eight language codes (EUR by default,
BRL for `pt`).

This project was built for the **MoonBit September Hackathon 2026**. It ports
the well-known Python [`num2words`](https://github.com/savoirfairelinux/num2words)
tool into MoonBit, filling a gap in the MoonBit ecosystem (there was no
general-purpose multilingual number-to-words package on
[mooncakes.io](https://mooncakes.io) at the time of writing).

---

## Features

- **8 language codes**: English (`en`), French (`fr`), Spanish (`es`), German
  (`de`), Italian (`it`), Portuguese (`pt` Brazilian, `pt_PT` European), Russian
  (`ru`).
- **6 output modes**:
  - `cardinal` — `1234` → *one thousand, two hundred and thirty-four*
  - `ordinal` — `1` → *first*, `21` → *twenty-first*
  - `ordinal_num` — `1` → *1st*, `21` → *21st*
  - `year` — `2024` → *twenty twenty-four*, `1900` → *nineteen hundred*
  - `currency` — `1234.56` → *one thousand, two hundred and thirty-four euro,
    fifty-six cents* (default EUR; `pt` defaults to BRL)
  - `cardinal` with decimals — `1234.56` → *… point five six*
- **`BigInt`-backed integers** (no 64-bit ceiling; bounded by each language's
  scale table).
- **Zero dependencies** beyond the MoonBit core.
- A small **command-line tool** for ad-hoc conversions.
- **Differential-tested against upstream `num2words`**: 7796 recorded
  comparisons across the 8 language codes — see [DIFF_REPORT.md](DIFF_REPORT.md).

---

## Install

Add it to your `moon.mod` (requires the MoonBit toolchain ≥ 0.1.20260921).
Version **0.1.0** is published on mooncakes.io:

```bash
moon add 668xin/num2words-moonbit
```

Then import it in your package:

```mbt
import "668xin/num2words-moonbit" @n2w
```

---

## Usage

### Library

```mbt
import "668xin/num2words-moonbit" @n2w

// integers / big integers
@n2w.num2words_int(1234, "en", "cardinal")
// => "one thousand, two hundred and thirty-four"

@n2w.num2words(BigInt::from_string("1000000000000"), "de", "cardinal")
// => "eine Billion"

// ordinals
@n2w.num2words_int(21, "en", "ordinal")      // "twenty-first"
@n2w.num2words_int(21, "en", "ordinal_num")  // "21st"

// years
@n2w.num2words_int(2024, "en", "year")       // "twenty twenty-four"
@n2w.num2words_int(1900, "en", "year")       // "nineteen hundred"

// currency (default EUR; `pt` defaults to BRL, explicit ISO code)
@n2w.num2words_int(1234, "en", "currency")
// => "one thousand, two hundred and thirty-four euro, zero cents"
@n2w.num2words_currency("1234.56", "de", "USD")
// => Ok("eintausendzweihundertvierunddreißig Dollar und sechsundfünfzig Cent")
@n2w.num2words_currency("2.02", "ru", "RUB")
// => Ok("два рубля, две копейки")

// decimals, passed as a string
@n2w.num2words_str("1234.56", "en", "cardinal")
// => "one thousand, two hundred and thirty-four point five six"
```

### API surface

| Function | Signature | Notes |
| --- | --- | --- |
| `get_lang` | `(code : String) -> Lang` | `"en"\|"fr"\|"es"\|"de"\|"it"\|"pt"\|"pt_PT"\|"ru"`, default `en` |
| `num2words` | `(value : BigInt, lang : String, to : String) -> String` | core entry point |
| `num2words_int` | `(value : Int, lang : String, to : String) -> String` | convenience |
| `num2words_float` | `(value : Double, lang : String, to : String) -> String` | decimal literal |
| `num2words_str` | `(value : String, lang : String, to : String) -> String` | integer/bigint/decimal string; `""` on malformed input |
| `num2words_str_checked` | `(value : String, lang : String, to : String) -> Result[String, String]` | `Ok(words)` / `Err(message)` |
| `num2words_currency` | `(amount : String, lang : String, code : String) -> Result[String, String]` | ISO code (`""` = language default); per-language code sets, `Ok` / `Err` |
| `is_valid_number` | `(value : String) -> Bool` | validates before conversion |

`lang` and `to` are positional (no defaults): use `""`/`"en"`/`"cardinal"`
explicitly.

---

## Input handling, boundaries and limitations

### Accepted input

The string entry points accept exactly:

```
-?digits            e.g. "1234", "-42", "007"
-?digits.digits     e.g. "1234.56", "-0.5"
```

Everything else is **rejected**: `""`, `"-"`, `"."`, `".5"`, `"5."`,
`"1.2.3"`, `"12a"`, `"abc"`, `"--5"`, `"1,234"`.

### Behaviour on invalid input

`BigInt::from_string` aborts on malformed input, so the library validates
first:

| API | Invalid input behaviour |
| --- | --- |
| `num2words_str` | returns `""` — never aborts |
| `num2words_str_checked` | returns `Err("invalid number: <input>")` |
| CLI | prints `error: invalid number: <input>` |

```mbt
@n2w.is_valid_number("12a")           // false
@n2w.num2words_str("abc", "en", "cardinal")   // ""
@n2w.num2words_str_checked("abc", "en", "cardinal")
// Err("invalid number: abc")
```

```bash
$ moon run cmd/main -- 1.2.3
error: invalid number: 1.2.3
```

### Supported magnitude

Scale-word tables are finite, so each language has a ceiling. Values past it
are **reported, never crashed**:

| Language | Largest spellable | Example |
| --- | --- | --- |
| `en` | 10³³ (10^33) | `10^33` → *one decillion* |
| `fr` | 10³⁰ | `10^30` → *un sextillion* |
| `es`, `de` | 10²⁴ | — |
| `it`, `pt` | 10²¹ | `10^21` → *un triliardo* / *um sextilhão* |
| `pt_PT` | 10²⁴ | `10^24` → *um quatrilião* |
| `ru` | 10³³ | `10^33` → *один дециллион* |

```mbt
@n2w.num2words_str_checked("1" + <36 zeros>, "en", "cardinal")
// Err("magnitude out of supported range: 1000...")
@n2w.num2words_str("1" + <36 zeros>, "en", "cardinal")   // ""
```

```bash
$ moon run cmd/main -- 1000000000000000000000000000000000000
error: magnitude out of supported range: 1000000000000000000000000000000000000
```

`Lang::max_power()` returns the highest power of 1000 a language supports.

### Known limitations

- **8 language codes** (`en`, `fr`, `es`, `de`, `it`, `pt`, `pt_PT`, `ru`).
  More are planned; see the per-language extension layout above.
- **Magnitudes are bounded** by each language's scale-word table — see
  *Supported magnitude* above. "Arbitrarily large" is **not** claimed.
- **Published as `0.1.0`** on mooncakes.io; later releases need a version bump
  and a new `moon publish`.
- **Portuguese has both variants**: `pt` is Brazilian (`dezesseis`, short scale
  *bilhão* = 10⁹) and `pt_PT` is European (`dezasseis`, long scale *mil milhões*
  = 10⁹, *bilião* = 10¹²).
- **`ordinal` / `ordinal_num` are native for all eight language codes** and
  machine-checked against upstream (including its quirks, e.g. Spanish
  *décimoprimero*, the empty `es`/`pt` ordinal of `0`, and the European
  Portuguese long-scale *milésimo milionésimo*). Negative values return `""`
  (upstream raises `TypeError`), except Italian (*meno terzo*).
- **`currency` is native for all eight language codes with the complete
  upstream code sets**: `en` 11 codes, `fr`/`de`/`it` 4 each, `es` 20, `ru` 6,
  `pt` 1 (BRL) and `pt_PT` 5. Codes valid upstream but not for a language
  return `""` (`Err` from `num2words_str_checked` / `num2words_currency`).
- **Currency amounts are decimal strings** (`num2words_currency`), and the
  integer part is the major unit. Upstream's type-dependent quirk (a bare
  Python `int` is read as *cents*) is deliberately not reproduced.
- **Currency rounding** is exact decimal half-up at the third fractional digit.
  Upstream rounds through a binary float, so exact `x.xx5` amounts can differ
  (`1.005` → here *one euro, one cent*; upstream *one euro, zero cents*).
- **Upstream currency quirks are preserved**: Spanish leaves `quinientos`
  masculine, Russian applies the feminine form to every group (*одна миллион*),
  both Portuguese variants omit zero cents (*um real*) and add *de* after exact
  10⁶ multiples (*um milhão de reais*), and `pt_PT` GBP always spells zero
  cents (*um libra e zero pence*).
- **Fractional digits are spelled one by one** (`1234.56` → *… point five
  six*), not as a fractional number.
- **Decimals are not rounded in `cardinal` mode.** The digits you pass in are
  the digits spelled; only `currency` rounds to cents.
- **No reverse conversion** (`words → number`) is provided yet.
- **No performance benchmark** has been published — no performance claims are
  made.
- Leading zeros are ignored (`"007"` → *seven*); `"-0"` → *zero*.

### Command-line tool

```bash
moon run cmd/main -- 1234
moon run cmd/main -- 1234 --lang fr
moon run cmd/main -- 2024 --to year
moon run cmd/main -- 1234.56 --lang en --to cardinal
moon run cmd/main -- 1000000000000 --lang de
moon run cmd/main -- 1234.56 --lang en --to currency --currency USD
moon run cmd/main -- 1000000000 --lang pt_PT
moon run cmd/main -- --help
```

```
num2words <value> [--lang en|fr|es|de|it|pt|pt_PT|ru] [--to cardinal|ordinal|ordinal_num|year|currency] [--currency CODE]
```

### Runnable example

```bash
moon run examples
```

The `examples/` package exercises every mode, all eight language codes, two
currency conversions and the error path.

---

## Comparison with upstream num2words

The reference implementation is the Python
[`num2words`](https://github.com/savoirfairelinux/num2words) library, version
**0.5.14** (LGPL-2.1). Cardinal parity for the eight shared language codes, year
parity for English, Italian, Portuguese (both variants) and Russian, and ordinal
/ `ordinal_num` / currency parity for all eight are machine-checked by
**7796 recorded comparisons**; see [DIFF_REPORT.md](DIFF_REPORT.md) for the
method and results, and [COMPAT.md](COMPAT.md) for a call-by-call mapping,
currency-code coverage and the known gaps.

Upstream implements all five output modes for each of these eight language
codes. This project's coverage is:

| Mode | `en` | `fr` | `es` | `de` | `it` | `pt` | `pt_PT` | `ru` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `cardinal` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `year` | ✅ | ⚠️ | ⚠️ | ⚠️ | ✅ | ✅ | ✅ | ✅ |
| `ordinal` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `ordinal_num` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `currency` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Legend: ✅ native and aligned with upstream · ⚠️ native but a different year
convention.

### Per-language differences

| Language | Upstream | This project | Differences |
| --- | --- | --- | --- |
| `en` | `en` | `en` | Cardinal, year, ordinal and `ordinal_num` aligned; currency aligned (11 codes, EUR default) |
| `fr` | `fr` | `fr` | Years read as digit pairs (`2024` → *vingt vingt-quatre*) instead of upstream's full cardinal (*deux mille vingt-quatre*); ordinal and currency aligned (4 codes) |
| `es` | `es` | `es` | Long scale aligned (`10⁹` → *mil millones*); years read as pairs (*veinte veinticuatro*); ordinal and currency aligned (20 codes, including the *quinientos* quirk) |
| `de` | `de` | `de` | `1000` → *eintausend* (aligned); years read as pairs without *-hundert* (*zwanzig vierundzwanzig*); ordinal and currency aligned (4 codes) |
| `it` | `it` | `it` | Accent on *tré* only on the final word (*centoventitremila* vs *centoventitré*); upstream's `…dicotto` typo is not reproduced; ordinal and currency aligned (4 codes), with negative currency supported where upstream crashes |
| `pt` | `pt_BR` | `pt` (Brazilian) | Matches upstream `pt_BR` vocabulary (*dezesseis*, *bilhão*); scale groups are separated by spaces, upstream `pt_BR` writes a comma (*mil, duzentos*); ordinal and currency aligned (BRL only, zero cents omitted) |
| `pt_PT` | `pt` (European) | `pt_PT` | European vocabulary (*dezasseis*, *dezanove*); long scale (*mil milhões* = 10⁹, *bilião* = 10¹²); ordinal and currency aligned (EUR/USD/GBP/CAD/AUD; GBP keeps zero *pence*) |
| `ru` | `ru` | `ru` | Cardinal and ordinal aligned (three plural forms, feminine *одна тысяча*); currency aligned (6 codes, gender + plural forms) |

### Other differences

- **Breadth.** Upstream exposes ~55 language codes (including regional
  variants); this project covers eight language codes, each as one `lang_xx.mbt`
  file.
- **Ordinals.** Native for all eight language codes and machine-checked against
  upstream.
- **Currency.** Native for all eight language codes with upstream's complete
  code sets (55 language/code pairs); see [COMPAT.md](COMPAT.md) §4.
- **Scale ceilings.** Both sides use a finite scale-word table, but the
  ceilings differ; see [Supported magnitude](#supported-magnitude) for ours.
- **Input handling.** Upstream raises exceptions on malformed numbers; this
  library validates first and returns `""` (`num2words_str`) or
  `Err(message)` (`num2words_str_checked`).
- **Runtime and API.** Upstream is Python; this is pure MoonBit with no
  dependencies, `BigInt` input, positional `(value, lang, to)` arguments and no
  defaults.
- **Decimals.** Fractional digits are spelled one by one and are never rounded.

---

## Architecture

The library is split into a small core engine and one module per language:

| File | Responsibility |
| --- | --- |
| `base.mbt` | `Lang` descriptor, 3-digit grouping (`group3`), shared join logic, English rules + dispatch |
| `lang_fr.mbt` | French (vigesimal: *soixante-dix*, *quatre-vingts*) |
| `lang_es.mbt` | Spanish (*veintiuno*, *cien/ciento*, *un millón*) |
| `lang_de.mbt` | German (closed compounds: *einundvierzig*, *eintausendzweihundert…*) |
| `lang_it.mbt` | Italian (vowel elision: *ventuno*, *ventotto*, *centotto*; *ventitré*) |
| `lang_pt.mbt` | Portuguese, Brazilian (*cem*/*cento*, *vinte e um*, *mil e cem*) |
| `lang_pt_pt.mbt` | Portuguese, European (*dezasseis*, long scale *mil milhões*, *bilião*) |
| `lang_ru.mbt` | Russian (three plural forms, feminine *одна тысяча*, *две тысячи*) |
| `lang_ordinal.mbt` | ordinals and `ordinal_num` for the seven non-English language codes |
| `lang_currency.mbt` | currency tables and formatting (all eight language codes; per-language code sets, gender and plural rules) |
| `examples/` | runnable demo (`moon run examples`) |
| `benchmarks/` | `moon bench` microbenchmarks |
| `num2words-moonbit.mbt` | public API + per-mode dispatch |
| `cmd/main/main.mbt` | CLI built on `@env.args()` |
| `tools/gen_fixtures.py` | regenerates the differential fixtures from upstream `num2words` |
| `diff_fixtures_wbtest.mbt` | generated fixtures + differential tests (7796 comparisons) |

Each language is described declaratively by a `Lang` struct (ones, teens, tens,
hundreds, scale words, conjunctions, negative word, decimal word), and a few
small per-language functions (`below100_*`, `triple_*`, `cardinal_*`) encode
the language-specific grammar. This keeps adding a new language to a single
self-contained file.

---

## Performance

Native release-mode microbenchmarks (`moon bench --release benchmarks`) on
AMD Ryzen 5 5600H, Windows 11, MoonBit 0.1.20260921:

| Benchmark | Mean ± σ |
| --- | --- |
| `cardinal` en `1234` | 3.6 µs ± 0.06 |
| `cardinal` en 15 digits | 12.2 µs ± 0.07 |
| `cardinal` fr `1234` | 3.9 µs ± 0.34 |
| `cardinal` ru `1234` | 3.5 µs ± 0.05 |
| `ordinal` es `2024` | 5.3 µs ± 0.08 |
| `currency` en USD `1234.56` | 8.7 µs ± 0.08 |

The figures include string allocation and are indicative only; they are not a
cross-language comparison. Regenerate them with
`moon bench --release benchmarks`.

---

## Development

```bash
moon test          # 76 tests, including 7796 differential comparisons
moon build         # build the library + CLI
moon run cmd/main -- 1234 --lang en

# regenerate the differential fixtures (requires Python + upstream num2words)
pip install num2words==0.5.14
python tools/gen_fixtures.py
```

The differential run and its documented comparison rules (Italian accents,
Portuguese punctuation and long scale, currency rounding and int semantics) are
described in [DIFF_REPORT.md](DIFF_REPORT.md).

---

## Acknowledgements

This is a **port** of the Python
[`num2words`](https://github.com/savoirfairelinux/num2words) library
(Savoirfairelinux, **LGPL-2.1**). The language coverage, spelling rules and
overall design are derived from that project; the implementation is written
from scratch in MoonBit. We thank the upstream authors for their work.

## License

[LGPL-2.1](LICENSE) © 2026 668xin
