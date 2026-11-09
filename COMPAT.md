# Compatibility matrix — num2words-moonbit vs upstream `num2words`

Reference: Python [`num2words`](https://github.com/savoirfairelinux/num2words)
**0.5.14** (LGPL-2.1). This document maps the two APIs call by call, records the
supported surface, and lists every known behavioural difference. Output parity
is machine-checked by **7611 recorded comparisons** (see
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
* `num2words_currency("...", lang, "")` uses the language default: **EUR**, or
  **BRL** for `pt`. `num2words(..., "currency")` does the same with the integer
  value treated as major units.

---

## 2. Language codes

| Upstream | This library | Notes |
| --- | --- | --- |
| `en`, `fr`, `es`, `de`, `it`, `ru` | same | full coverage of the modes below |
| `pt_BR` | `pt` | Brazilian Portuguese |
| `pt` (European) | `pt_PT` | European Portuguese, **not** our `pt` |
| other 48 codes | — | not implemented |

Upstream exposes **56 language codes**; this project implements **8**. Unknown
codes fall back to English here, while upstream raises `NotImplementedError`.

---

## 3. Mode coverage

| Code | `cardinal` | `year` | `ordinal` | `ordinal_num` | `currency` |
| --- | --- | --- | --- | --- | --- |
| `en` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `fr` | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| `es` | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| `de` | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| `it` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `pt` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `pt_PT` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `ru` | ✅ | ✅ | ✅ | ✅ | ✅ |

✅ native and aligned · ⚠️ native but a different year convention: `fr`, `es`
and `de` read years as digit pairs (`2024` → *vingt vingt-quatre*, *veinte
veinticuatro*, *zwanzig vierundzwanzig*) instead of the upstream cardinal
reading. All other modes follow upstream.

Currency is native for every code; the exact ISO-code coverage differs — see §4.

---

## 4. Currency code coverage

| Code | Upstream codes | Implemented here | Missing |
| --- | --- | --- | --- |
| `en` | 11: EUR, USD, GBP, RUB, CAD, AUD, INR, SEK, NOK, PLN, MXN | EUR, USD, GBP | RUB, CAD, AUD, INR, SEK, NOK, PLN, MXN |
| `fr` | 4: EUR, USD, GBP, CNY | EUR, USD, GBP | CNY |
| `de` | 4: EUR, USD, GBP, CNY | EUR, USD, GBP | CNY |
| `it` | 4: EUR, USD, GBP, CNY | EUR, USD, GBP | CNY |
| `es` | 20: EUR, USD, GBP, RUB, JPY, CNY, CHF, CAD, AUD, BRL, INR, KRW, SEK, NOK, PLN, UAH, KZT, TRY, MXN, ZAR | all 20 | — |
| `ru` | 6: EUR, USD, RUB, PLN, UAH, KZT | all 6 | — |
| `pt` | 5: EUR, USD, GBP, CAD, AUD | all 5 | — |
| `pt_BR` | BRL (upstream `to_currency` takes no code argument) | BRL | — |

Coverage is **44 of 55 upstream language/code pairs**. Unsupported codes return
`Err("currency code not supported for ...")` (or `""` from the non-`Result`
entry points), while upstream raises `NotImplementedError`.

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

Ceilings differ in both directions: this project is more conservative for
`en`/`fr`/`es`/`de`/`it`/`pt_PT`, but accepts larger values than upstream for
`pt_BR` and `ru`. Values past the ceiling return `""` (`Err("magnitude out of
supported range: ...")` from `num2words_str_checked`); upstream raises
`OverflowError`, `KeyError` or `IndexError`.

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
7. **Currency code coverage.** `en`/`fr`/`de`/`it` implement the three common
   codes (EUR/USD/GBP) rather than their full upstream sets — see §4.
8. **Year reading for `fr`/`es`/`de`** — see §3.
9. **Unknown language / mode / out-of-range** return a value instead of raising
   — see §6.

Everything else — cardinals for all eight codes, years for `en`/`it`/`pt`/
`pt_PT`/`ru`, ordinals and `ordinal_num` for all eight, and currency for the
codes listed in §4 — matches upstream byte-for-byte (after the normalisations
above).

---

## 8. Verification

```bash
moon test          # 75 tests, 7611 differential comparisons
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

* Remaining 11 upstream currency language/code pairs (see §4).
* The other 48 upstream language codes.
* Reverse conversion (`words → number`).
* Performance benchmarks (no performance claims are made).
* Publication to mooncakes.io.
