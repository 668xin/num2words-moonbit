# num2words-moonbit

[![CI](https://github.com/668xin/num2words-moonbit/actions/workflows/ci.yml/badge.svg)](https://github.com/668xin/num2words-moonbit/actions/workflows/ci.yml)
[![License: LGPL-2.1](https://img.shields.io/badge/License-LGPL--2.1-blue.svg)](LICENSE)

**Convert numbers into words — in pure [MoonBit](https://www.moonbitlang.com/).**

`num2words-moonbit` is a from-scratch MoonBit implementation of the classic
*number → words* library. It spells out integers (of arbitrary size via
`BigInt`), decimals, ordinals, years and currency amounts in **English,
French, Spanish, German, Italian, Portuguese and Russian**.

This project was built for the **MoonBit September Hackathon 2026**. It ports
the well-known Python [`num2words`](https://github.com/savoirfairelinux/num2words)
tool into MoonBit, filling a gap in the MoonBit ecosystem (there was no
general-purpose multilingual number-to-words package on
[mooncakes.io](https://mooncakes.io) at the time of writing).

---

## Features

- **7 languages**: English (`en`), French (`fr`), Spanish (`es`), German (`de`),
  Italian (`it`), Portuguese (`pt`, Brazilian variant), Russian (`ru`).
- **6 output modes**:
  - `cardinal` — `1234` → *one thousand, two hundred and thirty-four*
  - `ordinal` — `1` → *first*, `21` → *twenty-first*
  - `ordinal_num` — `1` → *1st*, `21` → *21st*
  - `year` — `2024` → *twenty twenty-four*, `1900` → *nineteen hundred*
  - `currency` — `1234.56` → *one thousand, two hundred and thirty-four
    dollars and fifty-six cents*
  - `cardinal` with decimals — `1234.56` → *… point five six*
- **Arbitrarily large integers** via `BigInt` (no 64-bit ceiling).
- **Zero dependencies** beyond the MoonBit core.
- A small **command-line tool** for ad-hoc conversions.
- **Differential-tested against upstream `num2words`**: 3933 recorded
  comparisons across the 7 languages — see [DIFF_REPORT.md](DIFF_REPORT.md).

---

## Install

Add it to your `moon.mod` (requires the MoonBit toolchain ≥ 0.1.20260921):

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

// currency (English only; others fall back to cardinal)
@n2w.num2words_int(1234, "en", "currency")   // "one thousand, two hundred and thirty-four dollars"

// decimals, passed as a string
@n2w.num2words_str("1234.56", "en", "cardinal")
// => "one thousand, two hundred and thirty-four point five six"
```

### API surface

| Function | Signature | Notes |
| --- | --- | --- |
| `get_lang` | `(code : String) -> Lang` | `"en"\|"fr"\|"es"\|"de"\|"it"\|"pt"\|"ru"`, default `en` |
| `num2words` | `(value : BigInt, lang : String, to : String) -> String` | core entry point |
| `num2words_int` | `(value : Int, lang : String, to : String) -> String` | convenience |
| `num2words_float` | `(value : Double, lang : String, to : String) -> String` | decimal literal |
| `num2words_str` | `(value : String, lang : String, to : String) -> String` | integer/bigint/decimal string; `""` on malformed input |
| `num2words_str_checked` | `(value : String, lang : String, to : String) -> Result[String, String]` | `Ok(words)` / `Err(message)` |
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

- **7 languages** (`en`, `fr`, `es`, `de`, `it`, `pt`, `ru`). More are planned;
  see the per-language extension layout above.
- **Magnitudes are bounded** by each language's scale-word table — see
  *Supported magnitude* above. "Arbitrarily large" is **not** claimed.
- **Not yet published to mooncakes.io**, so `moon add 668xin/num2words-moonbit`
  does not resolve yet; use the public repository as a git dependency.
- **Portuguese is the Brazilian variant** (`dezesseis`, short scale
  *bilhão* = 10⁹). European Portuguese forms (`dezasseis`, *mil milhões*)
  are not provided.
- **Only English has ordinals / `ordinal_num` / currency.** For the other six
  languages those modes fall back to `cardinal` (`ordinal_num` appends `.`).
- **`currency` is English-only.** Other languages fall back to `cardinal`.
- **Fractional digits are spelled one by one** (`1234.56` → *… point five
  six*), not as a fractional number.
- **Decimals are not rounded.** The digits you pass in are the digits spelled.
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
moon run cmd/main -- --help
```

```
num2words <value> [--lang en|fr|es|de|it|pt|ru] [--to cardinal|ordinal|ordinal_num|year|currency]
```

---

## Comparison with upstream num2words

The reference implementation is the Python
[`num2words`](https://github.com/savoirfairelinux/num2words) library, version
**0.5.14** (LGPL-2.1). Cardinal parity for the seven shared languages, plus
year parity for English, Italian, Portuguese and Russian, is machine-checked by
3933 recorded comparisons; see [DIFF_REPORT.md](DIFF_REPORT.md) for the method
and results.

Upstream implements all five output modes for each of these seven languages.
This project's coverage is:

| Mode | `en` | `fr` | `es` | `de` | `it` | `pt` | `ru` |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `cardinal` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `year` | ✅ | ⚠️ | ⚠️ | ⚠️ | ✅ | ✅ | ✅ |
| `ordinal` | ✅ | ↩ | ↩ | ↩ | ↩ | ↩ | ↩ |
| `ordinal_num` | ✅ | ↩ | ↩ | ↩ | ↩ | ↩ | ↩ |
| `currency` | ✅ | ↩ | ↩ | ↩ | ↩ | ↩ | ↩ |

Legend: ✅ native and aligned with upstream · ⚠️ native but a different year
convention · ↩ falls back to `cardinal`.

### Per-language differences

| Language | Upstream | This project | Differences |
| --- | --- | --- | --- |
| `en` | `en` | `en` | Cardinal and year convention aligned; `currency` is **USD** while upstream defaults to **EUR** |
| `fr` | `fr` | `fr` | Years read as digit pairs (`2024` → *vingt vingt-quatre*) instead of upstream's full cardinal (*deux mille vingt-quatre*); ordinal/currency fall back |
| `es` | `es` | `es` | Long scale aligned (`10⁹` → *mil millones*); years read as pairs (*veinte veinticuatro*); ordinal/currency fall back |
| `de` | `de` | `de` | `1000` → *eintausend* (aligned); years read as pairs without *-hundert* (*zwanzig vierundzwanzig*); ordinal/currency fall back |
| `it` | `it` | `it` | Accent on *tré* only on the final word (*centoventitremila* vs *centoventitré*); upstream's `…dicotto` typo is not reproduced; ordinal/currency fall back |
| `pt` | `pt` (European) + `pt_BR` | `pt` (Brazilian) | Matches upstream `pt_BR` vocabulary (*dezesseis*, *bilhão*); scale groups are separated by spaces, upstream `pt_BR` writes a comma (*mil, duzentos*) |
| `ru` | `ru` | `ru` | Cardinal aligned (three plural forms, feminine *одна тысяча*); ordinal/currency fall back |

### Other differences

- **Breadth.** Upstream exposes ~55 language codes (including regional
  variants); this project covers seven, each as one `lang_xx.mbt` file.
- **Ordinals and currency.** Upstream implements them per language; here only
  English does, and the other languages explicitly fall back to `cardinal`.
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
| `lang_ru.mbt` | Russian (three plural forms, feminine *одна тысяча*, *две тысячи*) |
| `num2words-moonbit.mbt` | public API + per-mode dispatch |
| `cmd/main/main.mbt` | CLI built on `@env.args()` |
| `tools/gen_fixtures.py` | regenerates the differential fixtures from upstream `num2words` |
| `diff_fixtures_wbtest.mbt` | generated fixtures + differential tests (3933 comparisons) |

Each language is described declaratively by a `Lang` struct (ones, teens, tens,
hundreds, scale words, conjunctions, negative word, decimal word), and a few
small per-language functions (`below100_*`, `triple_*`, `cardinal_*`) encode
the language-specific grammar. This keeps adding a new language to a single
self-contained file.

---

## Development

```bash
moon test          # 42 tests, including 3933 differential comparisons
moon build         # build the library + CLI
moon run cmd/main -- 1234 --lang en

# regenerate the differential fixtures (requires Python + upstream num2words)
pip install num2words==0.5.14
python tools/gen_fixtures.py
```

The differential run and its two documented comparison rules (Italian accents,
Brazilian Portuguese punctuation) are described in [DIFF_REPORT.md](DIFF_REPORT.md).

---

## Acknowledgements

This is a **port** of the Python
[`num2words`](https://github.com/savoirfairelinux/num2words) library
(Savoirfairelinux, **LGPL-2.1**). The language coverage, spelling rules and
overall design are derived from that project; the implementation is written
from scratch in MoonBit. We thank the upstream authors for their work.

## License

[LGPL-2.1](LICENSE) © 2026 668xin
