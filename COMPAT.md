# Compatibility matrix — num2words-moonbit vs upstream `num2words`

Reference: Python [`num2words`](https://github.com/savoirfairelinux/num2words)
**0.5.14** (LGPL-2.1). This document maps the two APIs call by call, records the
supported surface, and lists every known behavioural difference. Output parity
is machine-checked by **14555 recorded comparisons** (see
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
  **BRL** for `pt` or **TRY** for `tr`. `num2words(..., "currency")` does the
  same with the integer value treated as major units.

---

## 2. Language codes

| Upstream | This library | Notes |
| --- | --- | --- |
| `en`, `fr`, `es`, `de`, `it`, `ru`, `nl`, `tr` | same | full coverage of the modes below |
| `pt_BR` | `pt` | Brazilian Portuguese |
| `pt` (European) | `pt_PT` | European Portuguese, **not** our `pt` |
| `vi` | `vi` | cardinal and ordinal only (upstream has no year / `ordinal_num` / currency) |
| other 45 codes | — | not implemented |

Upstream exposes **56 language codes**; this project implements **11**. Unknown
codes fall back to English here, while upstream raises `NotImplementedError`.

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

✅ native and aligned; n.a. not implemented upstream (the call returns `""`
here). `year` follows upstream for every code, including the German
*-hundert* form (`1900` → *neunzehnhundert*, `2100` →
*einundzwanzighundert*) and the Dutch *-honderd* form (`1900` →
*negentien honderd*); Turkish years are plain cardinals and Vietnamese has no
year mode.

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
| `vi` | none (upstream has no `to_currency`) | — | n.a. |

Coverage is **224 of 224 upstream language/code pairs**. Unsupported codes (and
codes that are valid upstream but not for a given language) return
`Err("currency code not supported for ...")` (or `""` from the non-`Result`
entry points), while upstream raises `NotImplementedError` or `TypeError`.

Dutch keeps every currency noun invariant (`twee euro`, `twee cent`,
`twee penny`) because upstream's `pluralize` always returns the singular.
Turkish writes one word with no separator and omits the kuruş part when it is
zero (`onikiliraotuzdörtkuruş`, `birlira`); an exact zero amount is
`bedelsiz`.

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

Ceilings differ in both directions: this project is more conservative for
`en`/`fr`/`es`/`de`/`it`/`pt_PT`/`tr`, but accepts larger values than upstream
for `pt_BR` and `ru`. Values past the ceiling return `""`
(`Err("magnitude out of supported range: ...")` from
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
| unknown language | `NotImplementedError` | silently falls back to English |
| unknown mode | `NotImplementedError` | silently falls back to `cardinal` |
| out-of-range | may raise | `""` or `Err("magnitude out of supported range: ...")` |
| negative ordinal | `TypeError` | `""` (Italian: `meno ...`) |
| unsupported currency code | `NotImplementedError` | `Err(...)` / `""` |
| mode absent upstream (`vi` year / `ordinal_num` / currency) | `AttributeError` | `""` / `Err(...)` |
| negative cardinal (`vi`) | broken (`-1` → *mười chín*, smaller values raise) | `"âm ..."` |
| return type | `str` (or `int` for `it`/`ru` `ordinal_num`) | `String` / `Result[String, String]` |

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
    differential fixtures.

Everything else — cardinals, years, ordinals and `ordinal_num` for the codes
that implement them, and currency for the codes listed in §4 — matches upstream
byte-for-byte (after the normalisations above).

---

## 8. Verification

```bash
moon test          # 102 tests, 14555 differential comparisons
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

* The other 45 upstream language codes.
* Reverse conversion (`words → number`).
* Performance benchmarks (no performance claims are made).
* Publication to mooncakes.io.
