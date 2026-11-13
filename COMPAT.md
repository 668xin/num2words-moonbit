# Compatibility matrix — num2words-moonbit vs upstream `num2words`

Reference: Python [`num2words`](https://github.com/savoirfairelinux/num2words)
**0.5.14** (LGPL-2.1). This document maps the two APIs call by call, records the
supported surface, and lists every known behavioural difference. Output parity
is machine-checked by **31407 recorded comparisons** (see
[DIFF_REPORT.md](DIFF_REPORT.md)); `moon test` replays them without Python.

---

## 1. API mapping

| Task | Upstream Python | This library |
| --- | --- | --- |
| integer | `num2words(1234, lang="en")` | `num2words_int(1234, "en", "cardinal")` |
| big integer | `num2words(10**40, lang="en")` | `num2words_str("1" + <40 zeros>, "en", "cardinal")` / `num2words(BigInt, ...)` |
| decimal | `num2words(1234.56, lang="en")` | `num2words_float(1234.56, "en", "cardinal")` / `num2words_str("1234.56", ...)` |
| ordinal | `num2words(21, lang="en", to="ordinal")` | `num2words_int(21, "en", "ordinal")` |
| ordinal number | `num2words(21, lang="en", to="ordinal_num")` | `num2words_int(21, "en", "ordinal_num")` |
| year | `num2words(2024, lang="en", to="year")` | `num2words_int(2024, "en", "year")` |
| currency | `num2words(1234.56, lang="en", to="currency", currency="USD")` | `num2words_currency("1234.56", "en", "USD")` |
| default currency | `currency="EUR"` | `num2words_currency(..., "")` or `to="currency"` |

Notes:

* Upstream's legacy `ordinal=True` flag is not provided; use `to="ordinal"`.
* `num2words_currency` returns `Result[String, String]`; the other entry points
  return `String` (and `num2words_str_checked` returns `Result`).
* `num2words_currency("...", lang, "")` uses the language default: **EUR**,
  **BRL** for `pt`, **TRY** for `tr`, **元/XXX** for `zh`/`zh_TW`, **JPY** for
  `ja`, **KRW** for `ko`, **NOK** for `no`, **DKK** for `da`, **IDR** for
  `id`, **RON** for `ro`, **HUF** for `hu` and **ILS** for `he` (Persian has
  no code and always writes tomans). `num2words(..., "currency")` does the same
  with the integer value treated as major units.

---

## 2. Language codes

| Upstream | This library | Notes |
| --- | --- | --- |
| `en`, `fr`, `es`, `de`, `it`, `ru`, `nl`, `tr` | same | full coverage of the modes below |
| `pt_BR` | `pt` | Brazilian Portuguese |
| `pt` (European) | `pt_PT` | European Portuguese, **not** our `pt` |
| `vi` | `vi` | cardinal and ordinal only (upstream has no year / `ordinal_num` / currency) |
| `ja`, `ko` | same | 10⁴ grouping; Japanese era years; Korean KRW/USD/JPY |
| `sv` | `sv` | cardinal and ordinal only (upstream has no year / `ordinal_num` / currency) |
| `no`, `da`, `id`, `fi` | same | cardinal, ordinal, year and one or more currencies (`fi` has 24 codes) |
| `pl` | `pl` | cardinal, ordinal, year; upstream has no currency |
| `ar`, `th`, `uk` | same | cardinal, ordinal, year; upstream has no currency |
| `ro`, `hu` | same | cardinal, ordinal, year and 20 EU currency codes (`RON`/`HUF` default) |
| `he` | `he` | cardinal, ordinal, year and ILS/EUR/USD currency |
| `fa` | `fa` | cardinal, ordinal, year and a toman-only currency mode |
| `eo` | `eo` | cardinal, ordinal, year and 5 currency codes (`EUR` default) |
| *(master only)* `lang_ZH` | `zh`, `zh_TW` | Simplified and Traditional Chinese; not present in the 0.5.14 release |
| other ~27 codes | — | not implemented |

Upstream 0.5.14 exposes **56 language codes**; this project implements **29**.
Unknown codes fall back to English here, while upstream raises
`NotImplementedError`.

---

## 3. Mode coverage

| Code | `cardinal` | `year` | `ordinal` | `ordinal_num` | `currency` |
| --- | --- | --- | --- | --- | --- |
| `en` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `fr` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `es` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `de` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `it` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `pt` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `pt_PT` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `ru` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `nl` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `tr` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `vi` | ✅ | n.a. | ✅ | n.a. | n.a. |
| `zh` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `zh_TW` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `ja` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `ko` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `sv` | ✅ | n.a. | ✅ | n.a. | n.a. |
| `no` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `da` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `id` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `pl` | ✅ | ✅ | ✅ | ✅ | n.a. |
| `ar` | ✅ | ✅ | ✅ | ✅ | n.a. |
| `th` | ✅ | ✅ | ✅ | ✅ | n.a. |
| `fi` | ✅ | ✅ | ✅ | n.a. | ✅ |
| `uk` | ✅ | ✅ | ✅ | ✅ | n.a. |
| `ro` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `hu` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `he` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `fa` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `eo` | ✅ | ✅ | ✅ | ✅ | ✅ |

✅ native and aligned; n.a. not implemented upstream (the call returns `""`
here). `year` follows upstream for every code, including the German
*-hundert* form (`1900` → *neunzehnhundert*, `2100` →
*einundzwanzighundert*), the Dutch *-honderd* form (`1900` →
*negentien honderd*), the Japanese era calendar (`2024` → *令和六年*) and the
Chinese digit-by-digit form (`2024` → *二零二四年*); Turkish, Indonesian and
Polish years are plain cardinals, and Vietnamese/Swedish have no year mode.
Korean `ordinal` reproduces upstream's `KeyError` cases (0, 100, 1000, 10000,
…) as `""`; Polish `ordinal_num` returns the digits, as upstream does.

Currency is native for every code; the exact ISO-code coverage differs — see §4.

---

## 4. Currency code coverage

| Code | Upstream codes | Implemented here | Missing |
| --- | --- | --- | --- |
| `en` | 20: EUR, USD, GBP, RUB, CAD, AUD, INR, SEK, NOK, PLN, MXN, BYN, EEK, HUF, ISK, LTL, LVL, RON, SAR, UZS | all 20 | — |
| `fr` | 5: EUR, USD, GBP, CNY, FRF | all 5 | — |
| `de` | 5: EUR, USD, GBP, CNY, DEM | all 5 | — |
| `it` | 4: EUR, USD, GBP, CNY | all 4 | — |
| `es` | 171: the complete upstream 0.5.14 table (EUR, USD, GBP, RUB, JPY, CNY, CHF, CAD, AUD, BRL, INR, KRW, SEK, NOK, PLN, UAH, KZT, TRY, MXN, ZAR and 151 more) | all 171 | — |
| `ru` | 8: EUR, USD, RUB, PLN, UAH, KZT, BYN, UZS | all 8 | — |
| `pt` | 5: EUR, USD, GBP, CAD, AUD | all 5 | — |
| `pt_BR` | BRL (upstream `to_currency` takes no code argument) | BRL | — |
| `nl` | 4: EUR, GBP, USD, CNY | all 4 | — |
| `tr` | TRY only (upstream `to_currency` takes no code argument) | TRY | — |
| `ja` | JPY only; any fractional amount raises | JPY | — |
| `ko` | 3: KRW, USD, JPY (KRW/JPY reject cents) | all 3 | — |
| `no` | NOK only | NOK | — |
| `da` | DKK only (upstream `to_currency` takes no code argument) | DKK | — |
| `id` | IDR only (upstream `to_currency` takes no code argument) | IDR | — |
| `zh` | 17 (master): XXX, CNY, NTD, HKD, MOP, SGD, MYR, USD, EUR, GBP, JPY, CHF, CAD, AUD, NZD, THB, KRW | all 17 | — |
| `zh_TW` | same 17 (Traditional names) | all 17 | — |
| `fi` | 24: BRL, CHF, CNY, EUR, FIM, INR, JPY, KRW, KPW, MXN, RUB, TRY, ZAR, DKK, ISK, NOK, SEK, AUD, CAD, HKD, NZD, SGD, USD, GBP | all 24 | — |
| `ro` | 20: AUD, BYN, CAD, EEK, EUR, GBP, LTL, LVL, USD, RUB, SEK, NOK, PLN, MXN, RON, INR, HUF, ISK, UZS, SAR | all 20 (upstream raises for many two-form code/amount pairs, see §7) | — |
| `hu` | the same 20 EU codes | all 20 | — |
| `he` | 3: ILS, EUR, USD | all 3 | — |
| `eo` | 5: EUR, USD, FRF, GBP, CNY | all 5 | — |
| `fa` | tomans only (upstream `to_currency` takes no code argument) | tomans | — |
| `vi`, `sv`, `pl`, `ar`, `th`, `uk` | none (upstream has no `to_currency`) | — | n.a. |

Coverage is **337 of 337 upstream language/code pairs** (Chinese measured
against upstream master, which is the only upstream source for `lang_ZH`).
Unsupported codes (and codes that are valid upstream but not for a given
language) return `Err("currency code not supported for ...")` (or `""` from the
non-`Result` entry points), while upstream raises `NotImplementedError` or
`TypeError`.

Dutch keeps every currency noun invariant (`twee euro`, `twee cent`,
`twee penny`) because upstream's `pluralize` always returns the singular.
Turkish writes one word with no separator and omits the kuruş part when it is
zero (`onikiliraotuzdörtkuruş`, `birlira`); an exact zero amount is
`bedelsiz`. Chinese writes the currency name first and uses
*元/角/分* (`人民币一千二百三十四元五角六分`, `零元零五分`); Japanese omits
cents entirely (`千円`) and rejects fractions; Korean removes group spaces
before the unit and always spells USD cents (`일달러 영센트`), while KRW/JPY
reject cents; Norwegian omits zero øre (`en krone`), Danish reproduces the
`float2tuple` split (`0.5` → `fem øre`, zero → `""`), and Indonesian renders
the amount as a decimal `koma` phrase (`satu koma nol rupiah`). Romanian applies
the *una* multiplier and rewrites `unu leu`/`unu ban` (`una mie de lei`,
`un leu`), dropping `și zero bani`; Hungarian joins the two halves with a comma
(`ezer forint, nulla fillér`); Hebrew moves the noun before a count of one and
uses the construct state for two (`שקל אחד`, `שני שקלים`); Esperanto joins with
*kaj* (`du eŭroj kaj nul centimo`); Persian spells fractions with their
denominator (`1234.56` → *… و پنجاه و شش صدم تومان*).

---

## 5. Magnitude ceilings

Measured on 0.5.14 (values above the ceiling raise in Python, return `""` /
`Err` here):

| Code | Upstream | This library |
| --- | --- | --- |
| `en` | at least 10^40 (*ten duodecillion*) | 10^33 |
| `fr` | at least 10^40 | 10^30 |
| `es` | 10^26 (10^27 → `OverflowError`) | 10^24 |
| `de` | at least 10^40 | 10^24 |
| `it` | at least 10^40 | 10^21 |
| `pt` | 10^26 (10^27 → `OverflowError`) | 10^21 |
| `pt_BR` | 10^17 (10^18 → `OverflowError`) | 10^21 (our `pt`) |
| `pt_PT` | 10^26 | 10^24 |
| `ru` | 10^32 (10^33 → `KeyError`) | 10^33 |
| `nl` | 10^603 | 10^603 |
| `tr` | 10^20 (10^21 → `OverflowError`) | 10^18 scale word, values below 10^21 |
| `vi` | 10^59 in principle, but float formatting breaks above 10^18 | 10^57 scale word, values below 10^60 |
| `zh`, `zh_TW` | master module: 10^72 (10^76 → error) | 10^72 |
| `ja` | 10^48 (10^52 → `OverflowError`) | 10^48 |
| `ko` | 10^68 (10^72 → `OverflowError`) | 10^68 |
| `sv` | 10^603 | 10^603 |
| `no`, `da`, `id` | 10^603 in principle | 10^33 |
| `pl` | 10^63 (higher powers → `KeyError`) | 10^63 |
| `ar` | 10^51 | 10^48 |
| `th` | no explicit ceiling in `to_cardinal` | 10^24 (10^6 groups) |
| `fi` | 10^603 | 10^600 |
| `uk` | 10^33 | 10^30 |
| `ro` | 10^549 (upper scale table) | 10^41 (values below 10^42) |
| `hu` | 10^549 | 10^41 (values below 10^42) |
| `he` | 10^65 (10^66 → `OverflowError`) | 10^65 (values below 10^66) |
| `fa` | 10^17 (10^18 → empty output) | 10^17 (values below 10^18) |
| `eo` | 10^549 | 10^41 (values below 10^42) |

Ceilings differ in both directions: this project is more conservative for
`en`/`fr`/`es`/`de`/`it`/`pt_PT`/`tr` and for `no`/`da`/`id` (10^33), but
accepts larger values than upstream for `pt_BR` and `ru`. Values past the
ceiling return `""` (`Err("magnitude out of supported range: ...")` from
`num2words_str_checked`); upstream raises `OverflowError`, `KeyError` or
`IndexError`.

---

## 6. Input, return and error behaviour

| Aspect | Upstream | This library |
| --- | --- | --- |
| numeric strings | accepted (`num2words("123")`) | accepted by `num2words_str`; grammar is stricter (`-?\d+(\.\d+)?`) |
| integer type | Python `int` (arbitrary precision) | `BigInt` |
| decimal type | `float` / `Decimal` | decimal string; no binary-float conversion |
| invalid number | `decimal.InvalidOperation` | `""` or `Err("invalid number: ...")` |
| unknown language | `NotImplementedError` | `""` / `Err("unknown language: ...")` |
| unknown mode | `NotImplementedError` | `""` / `Err("unknown mode: ...")` |
| out-of-range | may raise | `""` or `Err("magnitude out of supported range: ...")` |
| negative ordinal | `TypeError` (Hungarian/Persian: supported) | `""` (Italian: `meno ...`; Hungarian: `mínusz ...`; Persian: `منفی ...`) |
| unsupported currency code | `NotImplementedError` | `Err(...)` / `""` |
| unknown language in `num2words_currency` | `NotImplementedError` | `Err("currency not implemented for language: ...")` |
| mode absent upstream (`vi`/`sv` year / `ordinal_num` / currency, `pl`/`ar`/`th`/`uk` currency, `fi` `ordinal_num`) | `AttributeError` / `NotImplementedError` | `""` / `Err(...)` |
| negative cardinal (`vi`, `pl`, `ar`, `uk`) | broken (Vietnamese `-1` → *mười chín*; Polish/Ukrainian raise; Arabic indexes from the end) | `"âm ..."` / `"minus ..."` / `"سالب ..."` / `"мінус ..."` |
| return type | `str` (or `int` for `it`/`ru`/`pl` `ordinal_num`) | `String` / `Result[String, String]` |

The CLI prints `error: <message>` to **stderr** and still exits 0 (the MoonBit
core library has no exit-code API; see README).

---

## 7. Documented output differences

These are deliberate and recorded in [DIFF_REPORT.md](DIFF_REPORT.md) §4.

1. **Italian accents.** Upstream accents `tré` inconsistently; here it is
   accented only on the final word. Upstream's `118 → centodicotto` typo is not
   reproduced.
2. **Brazilian Portuguese punctuation.** Upstream `pt_BR` writes a comma between
   scale groups (`mil, duzentos`); this project uses a plain space.
3. **Currency amount semantics.** Upstream reads a bare Python `int` as *cents*
   (`1234` → 12.34); this project treats the integer part as major units.
   Currency fixtures therefore pass floats to upstream.
4. **Currency rounding.** Exact decimal half-up on the third fractional digit
   here; upstream rounds through a binary float (`1.005` → 1.00 upstream,
   1.01 here).
5. **Negative currency in Italian.** Upstream 0.5.14 raises `AttributeError`;
   this project returns `meno ...`.
6. **Russian PLN.** Upstream's paucal form contains the typo `слотых`; this
   project writes `злотых` (normalised in the fixtures).
7. **Unknown language / mode / out-of-range** return a value instead of raising
   — see §6.
8. **Vietnamese negatives.** Upstream 0.5.14 reads `-1` as *mười chín* and
   raises `IndexError` for smaller negatives; this project spells them
   (`âm bốn mươi hai`). Vietnamese `year`, `ordinal_num` and `currency` do not
   exist upstream and return `""` / `Err` here.
9. **Turkish currency.** Upstream has one hard-coded lira/kuruş pair, treats any
   amount below one lira as `bedelsiz`, and truncates the cents through a binary
   float. This project exposes only `TRY`, uses the same zero amount
   (`bedelsiz`) and otherwise applies the documented exact-decimal rounding.
10. **Decimals.** Fractional digits are spelled one by one here
    (`12.34` → *… virgül üç dört* / *… phẩy ba bốn* in `tr`/`vi`), while
    upstream reads the last two decimal digits as a number (*otuz dört*,
    *ba mươi bốn*). Decimal comparisons are therefore not part of the
    differential fixtures. Upstream's `Decimal` also normalises the input, which
    this project does not: `1.10` → *one point one zero* here (*one point one*
    upstream), `0.0` → *zero point zero* here (*zero* upstream), and `-0.5`
    keeps its sign here (*minus zero point five*) while upstream drops it
    (*zero point five*).
11. **Negative years.** `en` ends with `BC`, `pt`/`pt_PT` with
    `antes de Cristo`, `ro` with `î.Hr.`, `hu` starts with `i. e.` and
    `zh`/`zh_TW` start with `公元前`, matching upstream.
    German and Dutch upstream compute the hundreds split on the negative value
    and produce nonsense (`-1` → *minuseinshundertneunundneunzig*,
    *min één honderd negenennegentig*); here they spell `minus` / `min`
    followed by the year (`minus eins`, `min één`). Japanese era years before
    645 and negative years raise upstream and return `""` here.
    `fr`/`es`/`it`/`ru`/`tr`/`he`/`fa`/`eo` match upstream
    (`moins`/`menos`/`meno`/`минус`/`eksi`/`מינוס`/`منفی`/`minus`).
12. **Chinese source.** Upstream 0.5.14 has no Chinese module. `zh_TW` matches
    the `lang_ZH.py` on upstream master byte-for-byte; `zh` is the same
    grammar and word tables rendered in Simplified characters (the fixtures map
    the Traditional output through a character table).
13. **Polish negatives.** Upstream raises `ValueError` for any negative input;
    this project returns `minus <cardinal of abs>`.
14. **CJK decimal formatting.** Chinese and Japanese join the point and digits
    without spaces (`零点五`, `千二百三十四点五六`); Korean spaces them
    (`천이백삼십사 점 오 육`). Negative decimals keep their sign here, while
    upstream drops it for Japanese/Korean/Chinese floats.
15. **Danish and Indonesian currency.** Danish splits the amount through
    upstream's `float2tuple` (`0.5` → `fem øre`, `0` → `""`); Indonesian
    spells integers as `<cardinal> koma nol rupiah` and fractions digit by
    digit. Both quirks are reproduced and pinned by fixtures.
16. **Arabic, Thai, Finnish and Ukrainian.** Arabic keeps the dual/plural
    scale forms and gender-aware ordinals; Thai uses 10^6 grouping with the
    เอ็ด rule; Finnish concatenates compounds below a million, removes spaces
    in `to_year` and appends *ennen ajanlaskun alkua* for negative years;
    Ukrainian has three-way plurals and feminine thousands. Upstream breaks on
    Arabic/Ukrainian negatives and Ukrainian zero, and has no currency for
    Arabic/Thai/Ukrainian or `ordinal_num` for Finnish; this project fills
    those gaps and documents them.
17. **Romanian, Hungarian, Hebrew, Persian and Esperanto.** Romanian keeps the
    three-way scale inflection and upstream's raw `biliard/e` quirk; Hungarian
    the *kettő*/*két* alternation and the 2001+ hyphen; Hebrew the feminine
    default, the *ו* conjunction and construct forms; Persian the bare *هزار*
    and denominator fractions; Esperanto closed hundreds and *-j* plurals.
    Upstream's Romanian `to_currency` raises `IndexError` for most two-form
    code/amount pairs (its `pluralize` returns a third form those tuples do not
    have); this project keeps the plural form instead. Hungarian and Persian
    negative ordinals are supported upstream and here, while their
    `ordinal_num` rejects negatives (`""` here). Persian has no ISO currency
    parameter, so an explicit code returns `Err` here.

Everything else — cardinals, positive years, ordinals and `ordinal_num` for the
codes that implement them, and currency for the codes listed in §4 — matches
upstream byte-for-byte (after the normalisations above).

---

## 8. Verification

```bash
moon test          # 213 tests, 31407 differential comparisons
moon build         # library + CLI
```

CI runs `moon test` on ubuntu, macOS and Windows. The fixtures are committed, so
reviewers do not need Python; regenerate them with:

```bash
pip install num2words==0.5.14
python tools/gen_fixtures.py
```

---

## 9. Not implemented / roadmap

* The other ~27 upstream language codes.
* Reverse conversion (`words → number`).
