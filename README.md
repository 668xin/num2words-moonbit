# num2words-moonbit

[![CI](https://github.com/668xin/num2words-moonbit/actions/workflows/ci.yml/badge.svg)](https://github.com/668xin/num2words-moonbit/actions/workflows/ci.yml)
[![License: LGPL-2.1](https://img.shields.io/badge/License-LGPL--2.1-blue.svg)](LICENSE)

**Convert numbers into words — in pure [MoonBit](https://www.moonbitlang.com/).**

`num2words-moonbit` is a from-scratch MoonBit implementation of the classic
*number → words* library. It spells out integers (of arbitrary size via
`BigInt`), decimals, ordinals, years and currency amounts in **29 language
codes**: English, French, Spanish, German, Italian, Portuguese (Brazilian and
European), Russian, Dutch, Turkish, Vietnamese, Simplified/Traditional Chinese,
Japanese, Korean, Swedish, Norwegian, Danish, Indonesian, Polish, Arabic, Thai,
Finnish, Ukrainian, Romanian, Hungarian, Hebrew, Persian and Esperanto.
Currency is native for 23 of them, using upstream's ISO code sets (EUR by
default, BRL for `pt`, TRY for `tr`, 元/`XXX` for `zh`, JPY for `ja`, KRW for
`ko`, NOK for `no`, DKK for `da`, IDR for `id`, RON for `ro`, HUF for `hu`,
ILS for `he`, 24 codes for `fi`; Persian writes tomans and takes no code).

This project was built for the **MoonBit September Hackathon 2026**. It ports
the well-known Python [`num2words`](https://github.com/savoirfairelinux/num2words)
tool into MoonBit, filling a gap in the MoonBit ecosystem (there was no
general-purpose multilingual number-to-words package on
[mooncakes.io](https://mooncakes.io) at the time of writing).

---

## Features

- **29 language codes**: English (`en`), French (`fr`), Spanish (`es`), German
  (`de`), Italian (`it`), Portuguese (`pt` Brazilian, `pt_PT` European), Russian
  (`ru`), Dutch (`nl`), Turkish (`tr`), Vietnamese (`vi`), Simplified Chinese
  (`zh`), Traditional Chinese (`zh_TW`), Japanese (`ja`), Korean (`ko`),
  Swedish (`sv`), Norwegian (`no`), Danish (`da`), Indonesian (`id`), Polish
  (`pl`), Arabic (`ar`), Thai (`th`), Finnish (`fi`), Ukrainian (`uk`),
  Romanian (`ro`), Hungarian (`hu`), Hebrew (`he`), Persian (`fa`) and
  Esperanto (`eo`).
- **5 output modes plus decimals**:
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
- **Differential-tested against upstream `num2words`**: 31407 recorded
  comparisons across the 29 language codes — see [DIFF_REPORT.md](DIFF_REPORT.md).

---

## Install

Add it to your `moon.mod` (requires the MoonBit toolchain ≥ 0.1.20260921).

The latest published release is **0.1.0**, which **predates this rework** (it
covers the original seven language codes). The version in this repository —
29 language codes and 338 currency entries (337 ISO-code pairs plus Persian's
code-less toman mode) — will be released as **0.1.1**; until then, depend on the
repository checkout if you need the new languages.

```bash
moon add 668xin/num2words-moonbit   # resolves to 0.1.0
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
| `get_lang` | `(code : String) -> Lang` | `"en"\|"fr"\|"es"\|"de"\|"it"\|"pt"\|"pt_PT"\|"ru"\|"nl"\|"tr"\|"vi"\|"zh"\|"zh_TW"\|"ja"\|"ko"\|"sv"\|"no"\|"da"\|"id"\|"pl"\|"ar"\|"th"\|"fi"\|"uk"\|"ro"\|"hu"\|"he"\|"fa"\|"eo"`, default `en` |
| `num2words` | `(value : BigInt, lang : String, to : String) -> String` | core entry point |
| `num2words_int` | `(value : Int, lang : String, to : String) -> String` | convenience |
| `num2words_float` | `(value : Double, lang : String, to : String) -> String` | decimal literal |
| `num2words_str` | `(value : String, lang : String, to : String) -> String` | integer/bigint/decimal string; `""` on malformed input |
| `num2words_str_checked` | `(value : String, lang : String, to : String) -> Result[String, String]` | `Ok(words)` / `Err(message)` |
| `num2words_currency` | `(amount : String, lang : String, code : String) -> Result[String, String]` | ISO code (`""` = language default); per-language code sets, `Ok` / `Err` |
| `is_valid_number` | `(value : String) -> Bool` | validates before conversion |

`lang` and `to` are positional (no defaults): use `""`/`"en"`/`"cardinal"`
explicitly. `get_lang` is the lenient resolver (unknown codes fall back to
English) used for direct table access; the conversion entry points reject
unknown codes and modes instead.

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

### Unknown language or mode

Conversion entry points do **not** silently fall back to English or
`cardinal`:

| API | Unknown `lang` / `to` |
| --- | --- |
| `num2words`, `num2words_int`, `num2words_float`, `num2words_str` | returns `""` |
| `num2words_str_checked` | `Err("unknown language: <code>")` / `Err("unknown mode: <mode>")` |
| CLI | prints the error to stderr |

`get_lang("zz")` still returns the English descriptor so callers who only need
word tables keep the historical lenient behaviour.

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
| `nl` | 10⁶⁰³ | `10^603` → *een zendiljard* |
| `tr` | 10¹⁸ (values below 10²¹) | `10^18` → *birkentilyon* |
| `vi` | 10⁵⁷ (values below 10⁶⁰) | `10^18` → *một Quintillion* |
| `zh`, `zh_TW` | 10⁷² (values below 10⁷⁶) | `10^72` → *一不可说* / *一不可說* |
| `ja` | 10⁴⁸ (values below 10⁵²) | `10^48` → *一極* |
| `ko` | 10⁶⁸ (values below 10⁷²) | `10^68` → *일무량대수* |
| `sv` | 10⁶⁰³ | `10^603` → *en centiljard* |
| `no`, `da`, `id` | 10³³ | — |
| `pl` | 10⁶³ | `10^63` → *decyliard* |
| `ar` | 10⁴⁸ | `10^48` → *كوينتينيليون* |
| `th` | 10²⁴ | `10^24` → *หนึ่งล้านล้านล้านล้าน* |
| `fi` | 10⁶⁰⁰ | `10^600` → *sentiljoona* |
| `uk` | 10³⁰ | `10^30` → *один нонільйон* |
| `ro` | 10⁴¹ (values below 10⁴²) | `10^15` → *biliard/e* (upstream quirk) |
| `hu` | 10⁴¹ (values below 10⁴²) | `10^18` → *egytrillió* |
| `he` | 10⁶⁵ (values below 10⁶⁶) | `10^18` → *קווינטיליון* |
| `fa` | 10¹⁷ (values below 10¹⁸) | `10^12` → *یک تریلیون* |
| `eo` | 10⁴¹ (values below 10⁴²) | `10^18` → *unu triliono* |

```mbt
@n2w.num2words_str_checked("1" + <36 zeros>, "en", "cardinal")
// Err("magnitude out of supported range: 1000...")
@n2w.num2words_str("1" + <36 zeros>, "en", "cardinal")   // ""
```

```bash
$ moon run cmd/main -- 1000000000000000000000000000000000000
error: magnitude out of supported range: 1000000000000000000000000000000000000
```

`Lang::max_power()` returns the highest group power a language supports: a
power of 1000 for most languages, and of 10⁴ for Chinese, Japanese and Korean.

### Known limitations

- **29 language codes** (`en`, `fr`, `es`, `de`, `it`, `pt`, `pt_PT`, `ru`,
  `nl`, `tr`, `vi`, `zh`, `zh_TW`, `ja`, `ko`, `sv`, `no`, `da`, `id`, `pl`,
  `ar`, `th`, `fi`, `uk`, `ro`, `hu`, `he`, `fa`, `eo`). Every mode upstream
  implements is ported and machine-checked; modes upstream does not implement
  (`vi`/`sv` year/`ordinal_num`/currency, `pl`/`ar`/`th`/`uk` currency, `fi`
  `ordinal_num`) return `""` / `Err`. Upstream's other ~27 language codes are
  out of scope (see [COMPAT.md](COMPAT.md)).
- **Magnitudes are bounded** by each language's scale-word table — see
  *Supported magnitude* above. "Arbitrarily large" is **not** claimed.
- **Release status**: mooncakes.io carries `0.1.0`, which predates this rework
  (seven language codes); the 29-language, 338-currency-entry version in this
  repository is pending release as `0.1.1`.
- **Chinese is post-0.5.14**: upstream 0.5.14 has no Chinese module, so `zh`
  (Simplified) and `zh_TW` (Traditional) follow the `lang_ZH.py` added on
  upstream master, including its 元/角/分 currency split. `zh` maps the
  Traditional output to Simplified characters; the grammar is identical.
- **CJK grouping advances by 10⁴** (`万`/`億`/`兆`, `만`/`억`/`조`) instead of
  10³. Japanese omits `一` before 十/百/千 (`1001` → *千一*), Korean separates
  10⁴ groups with a space (*만 이천삼백사십오*), and Chinese inserts one `零`
  for a gap below 1000 (*一万零一*) while dropping it at a whole-`万`
  boundary (*一亿一千*).
- **Portuguese has both variants**: `pt` is Brazilian (`dezesseis`, short scale
  *bilhão* = 10⁹) and `pt_PT` is European (`dezasseis`, long scale *mil milhões*
  = 10⁹, *bilião* = 10¹²).
- **Vietnamese, Polish, Arabic and Ukrainian negatives are fixed, not
  copied**: upstream 0.5.14 reads `-1` in Vietnamese as *mười chín*, raises in
  Polish/Ukrainian and indexes Arabic tables from the end. This project spells
  them properly (*âm bốn mươi hai*, *minus czterdzieści dwa*, *سالب اثنان و
  أربعون*, *мінус сорок два*). Ukrainian `0` (upstream `IndexError`) is *нуль*.
- **Negative years**: `en` appends `BC`, `pt`/`pt_PT` *antes de Cristo*,
  `ro` *î.Hr.*, `hu` prefixes *i. e.*, `zh`/`zh_TW` *公元前*, `ar`/`th`/`uk`/
  `he`/`fa`/`eo` prefix their negative word and `fi` appends *ennen ajanlaskun
  alkua*; Japanese returns `""` (era calendar, upstream raises below 645).
  German and Dutch upstream compute the hundreds split on the negative value
  and emit nonsense (`-1` → *minuseinshundertneunundneunzig*); this project
  writes *minus eins* / *min één* instead.
- **Japanese years use the era calendar** (`645` → *大化元年*, `2024` →
  *令和六年*, with later eras winning when two start in the same year:
  `749` → *天平勝宝元年*). Years before 645 and negative years return `""`.
- **English years use the `oh-` form** for a low part below ten (`1904` →
  *nineteen oh-four*), like upstream, and fall back to the cardinal for `00XX`,
  `X00X` and five-digit years.
- **Turkish currency is a single lira/kuruş pair** upstream (its
  `to_currency` accepts no ISO code); only `TRY` is exposed here, and an exact
  zero amount is *bedelsiz*.
- **`ordinal` / `ordinal_num` are native for all language codes where upstream
  implements them** and machine-checked against upstream (including its quirks,
  e.g. Spanish *décimoprimero*, the empty `es`/`pt` ordinal of `0`, the
  European Portuguese long-scale *milésimo milionésimo*, Turkish's missing
  *-uncu* on `10^18`, Korean's `KeyError` on 0/100/1000/10000 and Swedish's
  suffix table). Negative values return `""` (upstream raises `TypeError`),
  except Italian (*meno terzo*), Hungarian (*mínusz első*) and Persian
  (*منفی یکم*); Hebrew, Romanian and Esperanto negative ordinals return `""`
  but their `ordinal_num` is the plain number (`-1` → *-1*) like Russian and
  Polish. Vietnamese and Swedish `ordinal` are the cardinal / native ordinal as
  upstream defines them; their `ordinal_num` is absent upstream and returns
  `""` here.
- **`currency` is native for 23 language codes with upstream's complete code
  sets**: `en` 20, `fr`/`de` 5 each, `it`/`nl` 4 each, `es` 171, `ru` 8,
  `pt` 1 (BRL), `pt_PT` 5, `tr` 1 (TRY), `ja` 1 (JPY, no fractions), `ko` 3
  (KRW/USD/JPY), `no` 1 (NOK), `da` 1 (DKK), `id` 1 (IDR), `fi` 24,
  `zh`/`zh_TW` 17 (incl. `XXX` for plain 元), `ro`/`hu` 20 each (the EU set),
  `he` 3 (ILS/EUR/USD), `eo` 5, and `fa` 1 (tomans, no ISO code). Vietnamese,
  Swedish, Polish, Arabic, Thai and Ukrainian have no currency mode upstream.
  Codes valid upstream but not for a language return `""` (`Err` from
  `num2words_str_checked` / `num2words_currency`).
- **Currency amounts are decimal strings** (`num2words_currency`), and the
  integer part is the major unit. Upstream's type-dependent quirk (a bare
  Python `int` is read as *cents*) is deliberately not reproduced.
- **Currency rounding** is exact decimal half-up at the third fractional digit.
  Upstream rounds through a binary float, so exact `x.xx5` amounts can differ
  (`1.005` → here *one euro, one cent*; upstream *one euro, zero cents*).
- **Upstream currency quirks are preserved**: Spanish leaves `quinientos`
  masculine, Russian applies the feminine form to every group (*одна миллион*),
  both Portuguese variants omit zero cents (*um real*) and add *de* after exact
  10⁶ multiples (*um milhão de reais*), `pt_PT` GBP always spells zero cents
  (*um libra e zero pence*), Danish splits through `float2tuple` (`0.5` →
  *fem øre*, not fifty) and returns `""` for zero, Indonesian appends
  *… koma nol rupiah* to integers, and Chinese places the currency name before
  the amount (*人民币一千二百三十四元五角六分*). Romanian rewrites *unu leu* to
  *un leu* and drops *și zero bani* (*una sută unu lei*, *una mie de lei*);
  Hungarian joins with a comma (*ezer forint, nulla fillér*); Hebrew moves the
  noun before a count of one and uses the construct state for two (*שקל אחד*,
  *שני שקלים*); Esperanto uses *kaj* and the plural for anything above one
  (*du eŭroj kaj nul centimo*). Upstream's Romanian converter raises
  `IndexError` for many two-form codes and amounts; this port keeps the plural
  form instead of failing.
- **Fractional digits are spelled one by one** (`1234.56` → *… point five
  six*), not as a fractional number — except Persian currency, where upstream
  writes the denominator (*1.5* → *یک و نیم*, *1234.56* → *… و پنجاه و شش
  صدم*), which is reproduced exactly. Hungarian and Persian cardinal decimals
  use the generic point/digit form rather than upstream's own fraction grammar.
- **Decimals are not rounded in `cardinal` mode.** The digits you pass in are
  the digits spelled; only `currency` rounds to cents. Upstream normalises the
  input through `Decimal`, which this project does not: `1.10` → *one point one
  zero* here (*one point one* upstream), `0.0` → *zero point zero* here (*zero*
  upstream), and `-0.5` keeps its sign (*minus zero point five*) where upstream
  drops it (*zero point five*).
- **No reverse conversion** (`words → number`) is provided yet.
- **Performance figures are a single-machine microbenchmark** (see
  [Performance](#performance)); they are not a cross-platform or cross-language
  claim.
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
num2words <value> [--lang en|fr|es|de|it|pt|pt_PT|ru|nl|tr|vi|zh|zh_TW|ja|ko|sv|no|da|id|pl|ar|th|fi|uk|ro|hu|he|fa|eo] [--to cardinal|ordinal|ordinal_num|year|currency] [--currency CODE]
```

Conversion errors are written to **stderr** as `error: <message>`. The process
still exits with status 0: the MoonBit core library exposes no exit-code API,
and adding a dependency for it was not worth it for a demo CLI — check stderr
rather than `$?`.

### Runnable example

```bash
moon run examples
```

The `examples/` package exercises every mode, all twenty-nine language codes,
seven currency conversions and the error path.

---

## Comparison with upstream num2words

The reference implementation is the Python
[`num2words`](https://github.com/savoirfairelinux/num2words) library, version
**0.5.14** (LGPL-2.1). Cardinal, year, ordinal, `ordinal_num` and currency
parity for all twenty-nine language codes are machine-checked by
**31407 recorded comparisons**; see [DIFF_REPORT.md](DIFF_REPORT.md) for the
method and results, and [COMPAT.md](COMPAT.md) for a call-by-call mapping,
currency-code coverage and the known gaps.

Upstream implements all five output modes for most of these language codes; a
few have narrower upstream surfaces (Vietnamese and Swedish: no year,
`ordinal_num` or currency; Polish, Arabic, Thai and Ukrainian: no currency;
Finnish: no `ordinal_num`). This project's coverage is:

| Mode | Languages |
| --- | --- |
| `cardinal` | all 29 |
| `year` | `en` `fr` `es` `de` `it` `pt` `pt_PT` `ru` `nl` `tr` `zh` `zh_TW` `ja` `ko` `no` `da` `id` `pl` `ar` `th` `fi` `uk` `ro` `hu` `he` `fa` `eo` (27; `vi`/`sv` n.a.) |
| `ordinal` | all 29 |
| `ordinal_num` | `en` `fr` `es` `de` `it` `pt` `pt_PT` `ru` `nl` `tr` `zh` `zh_TW` `ja` `ko` `no` `da` `id` `pl` `ar` `th` `uk` `ro` `hu` `he` `fa` `eo` (26; `vi`/`sv`/`fi` n.a.) |
| `currency` | `en` `fr` `es` `de` `it` `pt` `pt_PT` `ru` `nl` `tr` `zh` `zh_TW` `ja` `ko` `no` `da` `id` `fi` `ro` `hu` `he` `fa` `eo` (23; `vi`/`sv`/`pl`/`ar`/`th`/`uk` n.a.) |

n.a. = not implemented by upstream for that language (the call returns `""`
here).

### Per-language differences

| Language | Upstream | This project | Differences |
| --- | --- | --- | --- |
| `en` | `en` | `en` | Cardinal, year, ordinal and `ordinal_num` aligned; currency aligned (20 codes, EUR default) |
| `fr` | `fr` | `fr` | Cardinal, year, ordinal and currency aligned (5 codes) |
| `es` | `es` | `es` | Long scale aligned (`10⁹` → *mil millones*); ordinal and currency aligned (171 codes, the complete upstream set, including the *quinientos* quirk) |
| `de` | `de` | `de` | `1000` → *eintausend* (aligned); year uses the upstream *-hundert* form (`1900` → *neunzehnhundert*); ordinal and currency aligned (5 codes) |
| `it` | `it` | `it` | Accent on *tré* only on the final word (*centoventitremila* vs *centoventitré*); upstream's `…dicotto` typo is not reproduced; ordinal and currency aligned (4 codes), with negative currency supported where upstream crashes |
| `pt` | `pt_BR` | `pt` (Brazilian) | Matches upstream `pt_BR` vocabulary (*dezesseis*, *bilhão*); scale groups are separated by spaces, upstream `pt_BR` writes a comma (*mil, duzentos*); ordinal and currency aligned (BRL only, zero cents omitted) |
| `pt_PT` | `pt` (European) | `pt_PT` | European vocabulary (*dezasseis*, *dezanove*); long scale (*mil milhões* = 10⁹, *bilião* = 10¹²); ordinal and currency aligned (EUR/USD/GBP/CAD/AUD; GBP keeps zero *pence*) |
| `ru` | `ru` | `ru` | Cardinal and ordinal aligned (three plural forms, feminine *одна тысяча*); currency aligned (8 codes, gender + plural forms) |
| `nl` | `nl` | `nl` | Closed compounds aligned (*eenentwintig*, *duizendtweehonderd…*); year uses *-honderd* (`1900` → *negentien honderd*); ordinal suffix rules and currency aligned (4 codes, nouns invariant) |
| `tr` | `tr` | `tr` | One-word compounds aligned (*binikiyüzotuzdört*); ordinal replaces only the final morpheme; year is the cardinal; currency is the single lira/kuruş pair (TRY) |
| `vi` | `vi` | `vi` | Cardinal and ordinal (= cardinal) aligned; negatives are fixed here (upstream returns *mười chín* for `-1` and raises for smaller values); upstream has no year, `ordinal_num` or currency |
| `zh` | master `lang_ZH` | `zh` (Simplified) | 10⁴ grouping (*一万二千三百四十五*), one `零` for gaps (*一万零一*), leading `一十` → *十*; years digit by digit (*二零二四年*); ordinal *第…*; currency *元角分*. Simplified characters map the upstream Traditional output (not in 0.5.14) |
| `zh_TW` | master `lang_ZH` | `zh_TW` (Traditional) | Same grammar as `zh` with upstream's Traditional tables (*萬*/*億*/*負*/*點*, *人民幣*) |
| `ja` | `ja` | `ja` | 10⁴ grouping; no zero insertion (*1001* → *千一*); era-calendar years (*2024* → *令和六年*); ordinal *…番目*; JPY only, fractions rejected |
| `ko` | `ko` | `ko` | 10⁴ groups separated by a space (*만 이천삼백사십오*); native-counter ordinals (*열한 번째*) with upstream's `KeyError` cases returning `""`; KRW/USD/JPY currency |
| `sv` | `sv` | `sv` | Cardinal and ordinal aligned (*tjugoett*, *tjugoförsta*); upstream has no year, `ordinal_num` or currency |
| `no` | `no` | `no` | Cardinal, ordinal (*tjueførste*, quirk *trettførste*), `N.` ordinal numbers, years and NOK currency aligned |
| `da` | `da` | `da` | Cardinal (*enogtyve*, quirk *en millioner*), ordinals, years and the kr/øre currency split (including `float2tuple` and empty zero) aligned |
| `id` | `id` | `id` | Cardinal, `ke…` ordinals, year = cardinal, and the *… koma nol rupiah* currency aligned |
| `pl` | `pl` | `pl` | Cardinal and real ordinals (*dwudziesty pierwszy*) aligned; year is the cardinal, `ordinal_num` is the digits; upstream has no currency; negatives are fixed here |
| `ar` | `ar` | `ar` | Dual/plural scale forms (*ألفان*, *ثلاثة آلاف*), gender-aware ordinals; year = cardinal; upstream has no currency; negative input is fixed here |
| `th` | `th` | `th` | 10⁶ grouping (*ล้าน*) with the เอ็ด rule (*สิบเอ็ด*, *หนึ่งร้อยเอ็ด*); ordinal and year = cardinal; `ordinal_num` = digits; no currency |
| `fi` | `fi` | `fi` | Concatenated compounds with partitive scale forms (*kaksisataa*, *kaksituhatta*); real ordinals; year is the space-free cardinal (negative years append *ennen ajanlaskun alkua*); 24 currency codes |
| `uk` | `uk` | `uk` | Three-way plural and feminine thousands (*одна тисяча*, *дві тисячі*, *п'ять тисяч*), real ordinals; year = cardinal; upstream has no currency; 0 and negatives are fixed here |
| `ro` | `ro` | `ro` | Three-way scale inflection (*două sute*, *douăzeci de mii*, *un milion*), the *doi* → *două* multiplier switch and upstream's raw *biliard/e* quirk; *al …lea* ordinals; year is the cardinal with *î.Hr.* for negative years; RON default with 20 codes |
| `hu` | `hu` | `hu` | Single-word compounds (*százhuszonháromezer-négyszázötvenhat*), *kettő*/*két* alternation and the 2001+ hyphen; suffix-table ordinals (*huszonkettedik*); *i. e.* for negative years; HUF default with 20 codes and a comma separator |
| `he` | `he` | `he` | Feminine default with masculine thousands/millions, the *ו* conjunction on every group after the first, construct forms for 2 and before scales; definite-article ordinals (*האחד עשר*); ILS/EUR/USD with noun gender and construct state |
| `fa` | `fa` | `fa` | *و*-joined groups and the bare *هزار*; ordinal *-م* with *سه* → *سوم*; year = cardinal; tomans only, with denominator words for fractions (*نیم*, *صدم*, *هزارم*) |
| `eo` | `eo` | `eo` | Closed hundreds (*ducent*), plural *-j* on multiplied scale words (*du milionoj*) and the exact-100 concatenation (*milcent*); suffix-rewrite ordinals (*dudeka*, *unu miliona*); EUR default with 5 codes and *kaj* |

### Other differences

- **Breadth.** Upstream exposes ~56 language codes (including regional
  variants); this project covers 29 language codes, each as one
  `lang_xx.mbt` file, including all three CJK languages, Arabic, Thai,
  Finnish, Ukrainian, Romanian, Hungarian, Hebrew, Persian, Esperanto and the
  major Scandinavian, Slavic and Southeast Asian languages.
- **Ordinals.** Native for every language where upstream implements them, and
  machine-checked against upstream.
- **Currency.** Native for 23 language codes with upstream's complete code
  sets (337 ISO-code pairs, 338 entries including Persian's code-less toman
  mode); see [COMPAT.md](COMPAT.md) §4.
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
| `base.mbt` | `Lang` descriptor, 3-digit grouping (`group3`) and 4-digit CJK grouping (`group4`), shared join logic, English rules + dispatch |
| `lang_fr.mbt` | French (vigesimal: *soixante-dix*, *quatre-vingts*) |
| `lang_es.mbt` | Spanish (*veintiuno*, *cien/ciento*, *un millón*) |
| `lang_de.mbt` | German (closed compounds: *einundvierzig*, *eintausendzweihundert…*) |
| `lang_it.mbt` | Italian (vowel elision: *ventuno*, *ventotto*, *centotto*; *ventitré*) |
| `lang_pt.mbt` | Portuguese, Brazilian (*cem*/*cento*, *vinte e um*, *mil e cem*) |
| `lang_pt_pt.mbt` | Portuguese, European (*dezasseis*, long scale *mil milhões*, *bilião*) |
| `lang_ru.mbt` | Russian (three plural forms, feminine *одна тысяча*, *две тысячи*) |
| `lang_nl.mbt` | Dutch (closed compounds *eenentwintig*; generated *-iljoen*/*-iljard* scale table) |
| `lang_tr.mbt` | Turkish (single-word compounds; ordinal forms; lira/kuruş currency) |
| `lang_vi.mbt` | Vietnamese (space-separated groups, *lẻ* before a sub-100 remainder) |
| `lang_zh.mbt` | Chinese, Simplified and Traditional (10⁴ groups, `零` stuffing, *元角分*) |
| `lang_ja.mbt` | Japanese (10⁴ groups, no zero insertion, era-calendar years, JPY) |
| `lang_ko.mbt` | Korean (10⁴ groups separated by spaces, native-counter ordinals, KRW/USD/JPY) |
| `lang_sv.mbt` | Swedish (closed compounds, suffix-table ordinals) |
| `lang_no.mbt` | Norwegian (space-separated groups, *og* conjunction, NOK) |
| `lang_da.mbt` | Danish (inverted tens *enogtyve*, kr/øre currency) |
| `lang_id.mbt` | Indonesian (*seratus*/*seribu*, `ke…` ordinals, rupiah) |
| `lang_pl.mbt` | Polish (three-way plural scale words, real ordinals) |
| `lang_ar.mbt` | Arabic (dual/plural scale forms, gender-aware ordinals) |
| `lang_th.mbt` | Thai (10⁶ grouping, the เอ็ด rule) |
| `lang_fi.mbt` | Finnish (concatenated compounds, partitive scale forms, 24 currency codes) |
| `lang_uk.mbt` | Ukrainian (three-way plurals, feminine thousands, real ordinals) |
| `lang_ro.mbt` | Romanian (three-way scale inflection, *una* multiplier, *al …lea* ordinals) |
| `lang_hu.mbt` | Hungarian (single-word compounds, *kettő*/*két*, suffix-table ordinals) |
| `lang_he.mbt` | Hebrew (feminine/masculine agreement, construct state, *ו* conjunction) |
| `lang_fa.mbt` | Persian (*و*-joined groups, bare *هزار*, toman currency) |
| `lang_eo.mbt` | Esperanto (closed hundreds, *-j* plurals, exact-100 concatenation) |
| `lang_ordinal.mbt` | ordinals and `ordinal_num` for the non-English language codes |
| `lang_currency.mbt` | currency tables and formatting (23 language codes; per-language code sets, gender and plural rules) |
| `examples/` | runnable demo (`moon run examples`) |
| `benchmarks/` | `moon bench` microbenchmarks |
| `num2words-moonbit.mbt` | public API + per-mode dispatch |
| `cmd/main/main.mbt` | CLI built on `@env.args()` |
| `tools/gen_fixtures.py` | regenerates the differential fixtures from upstream `num2words` |
| `diff_fixtures_wbtest.mbt` | generated fixtures + differential tests (31407 comparisons) |

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
moon test          # 213 tests, including 31407 differential comparisons
moon build         # build the library + CLI
moon run cmd/main -- 1234 --lang en

# regenerate the differential fixtures (requires Python + upstream num2words)
pip install num2words==0.5.14
python tools/gen_fixtures.py
```

The differential run and its documented comparison rules (Italian accents,
Portuguese punctuation and long scale, Simplified Chinese character mapping,
currency rounding and int semantics) are described in
[DIFF_REPORT.md](DIFF_REPORT.md).

---

## Acknowledgements

This is a **port** of the Python
[`num2words`](https://github.com/savoirfairelinux/num2words) library
(Savoirfairelinux, **LGPL-2.1**). The language coverage, spelling rules and
overall design are derived from that project; the implementation is written
from scratch in MoonBit. We thank the upstream authors for their work.

## License

[LGPL-2.1](LICENSE) © 2026 668xin
