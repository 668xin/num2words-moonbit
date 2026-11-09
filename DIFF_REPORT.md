# Differential test report — num2words-moonbit vs upstream num2words

This report records the differential test run that checks our MoonBit output
against the upstream Python [`num2words`](https://github.com/savoirfairelinux/num2words)
library (LGPL-2.1). Only upstream **output strings** are used, never its source
code.

- Upstream version: **num2words 0.5.14**
- Upstream languages used: `en`, `fr`, `es`, `de`, `it`, `pt_BR`, `pt`, `ru`
- Cardinal samples per language: **551** (`0..500` plus 51 multi-scale / signed values)
- Year samples: **19** each for `en`, `it`, `pt`, `pt_PT`, `ru`
- Ordinal samples per language: **249** (dense `0..200` plus
  hundreds/thousands/scale boundaries; Portuguese drops the `10^18` sample
  that upstream rejects), `ordinal_num`: **11** per language
- Currency samples: **1215** total — **187** for `en` (11 codes × 17 amounts),
  **68** each for `fr`/`de` (4 × 17), **60** for `it` (4 × 17 minus its 8
  rejected negative samples), **520** for `es` (26 × 20), **156** for `ru`
  (26 × 6), **26** for `pt` and **130** for `pt_PT` (26 × 5)
- Total comparisons: **7796** (4408 cardinal + 95 year + 1990 ordinal
  + 88 ordinal_num + 1215 currency)
- MoonBit test suite: **76 tests, 76 passed, 0 failed**

Run `moon test` from the project root to replay every comparison.

---

## 1. Method

1. `tools/gen_fixtures.py` calls upstream `num2words` for each sample and writes
   the expected strings to `diff_fixtures_wbtest.mbt`.
2. The generated MoonBit test feeds the same input strings through our public
   entry points (`num2words_str(value, lang, "cardinal" | "year" | "ordinal"
   | "ordinal_num")`, and `num2words_currency(amount, lang, code)`) and asserts
   equality.
3. Fixtures are committed, so CI and reviewers do not need Python: `moon test`
   replays the recorded expectations on every platform.

Sample set:

| Range | Values |
| --- | --- |
| Dense | `0..500` |
| Hundreds | `600, 700, 800, 900` |
| Boundaries | `999, 1000, 1001, 1003, 1010, 1023, 1100, 1111` |
| Years | `1234, 1900, 1999, 2000, 2003, 2023, 2024` |
| Scales | `2345, 3000, 5000, 9999, 10000, 11000, 12000, 21000, 22000, 25000` |
| Large | `100000, 100001, 123000, 123456, 999999, 1000000, 1000001, 1000021, 1000100, 1001000, 1100000, 1234567, 2000000, 5000000, 10^9, 2×10^9, 10^12` |
| Signed | `-1, -42, -1000, -123456` |

Year samples (`en`, `it`, `pt`, `pt_PT`, `ru` only): `1000, 1001, 1010, 1100,
1500, 1900, 1984, 1999, 2000, 2001, 2009, 2010, 2023, 2024, 2100, 2134, 3000,
3001, 9999`.

Currency samples: `en` uses its 11 codes and `fr`/`de`/`it` their 4 codes with
the 17 amounts `0, 0.01, 0.5, 1, 2, 21, 28, 81, 101, 1000, 1001, 1234.56,
999.99, 1.999, 1234.567, -3.5, -1.999`; `es` uses 26 amounts × 20 codes, `ru`
26 × 6, `pt` 26 × `BRL` and `pt_PT` 26 × 5, adding `5, 11, 22, 25, 100, 200,
500, 2000, 21000, 1000000, 1000001, 2000000`. Amounts are passed to upstream as
floats, so its type-dependent int-as-cents quirk does not apply.

---

## 2. Results

| Language | Cardinal samples | Passed | Comparison |
| --- | --- | --- | --- |
| `en` | 551 | 551 | verbatim |
| `fr` | 551 | 551 | verbatim |
| `es` | 551 | 551 | verbatim |
| `de` | 551 | 551 | verbatim |
| `it` | 551 | 551 | accents ignored (see §4) |
| `pt` | 551 | 551 | upstream `pt_BR`, commas ignored (see §4) |
| `pt_PT` | 551 | 551 | upstream `pt`, commas ignored (see §4) |
| `ru` | 551 | 551 | verbatim |

| Language | Year samples | Passed | Comparison |
| --- | --- | --- | --- |
| `en` | 19 | 19 | verbatim |
| `it` | 19 | 19 | accents ignored |
| `pt` | 19 | 19 | upstream `pt_BR`, commas ignored |
| `pt_PT` | 19 | 19 | upstream `pt`, commas ignored |
| `ru` | 19 | 19 | verbatim |

| Language | Ordinal samples | `ordinal_num` | Passed | Comparison |
| --- | --- | --- | --- | --- |
| `en` | 249 | 11 | 260 | verbatim |
| `fr` | 249 | 11 | 260 | verbatim |
| `es` | 249 | 11 | 260 | verbatim (incl. upstream quirks, see §4) |
| `de` | 249 | 11 | 260 | verbatim |
| `it` | 249 | 11 | 260 | accents ignored; `dicottesimo` typo normalised |
| `pt` | 248 | 11 | 259 | upstream `pt_BR`; `10^18` sample skipped (upstream raises) |
| `pt_PT` | 248 | 11 | 259 | upstream `pt`; long-scale separators; `10^18` skipped |
| `ru` | 249 | 11 | 260 | verbatim |

| Language | Currency samples | Passed | Comparison |
| --- | --- | --- | --- |
| `en` | 187 | 187 | verbatim (11 codes) |
| `fr` | 68 | 68 | verbatim (4 codes) |
| `de` | 68 | 68 | verbatim (4 codes) |
| `it` | 60 | 60 | verbatim (4 codes; negative amounts excluded, see §4) |
| `es` | 520 | 520 | verbatim (upstream quirks included, e.g. masculine *quinientos*) |
| `ru` | 156 | 156 | verbatim; PLN paucal typo normalised (see §4) |
| `pt` | 26 | 26 | upstream `pt_BR`, commas ignored (see §4) |
| `pt_PT` | 130 | 130 | upstream `pt`, commas ignored; GBP zero *pence* (see §4) |

All 7796 comparisons pass under the documented comparison rules in §4.
French, Spanish and German years use this project's pair-reading convention
instead of the upstream cardinal reading and are therefore not part of the
differential set (they are documented in the README comparison table).

### Ordinal comparison rules

Ordinals are compared verbatim, replicating upstream behaviour **including
its quirks**:

* `es`: `0` → `""` (empty string); 11/12 concatenate without a space
  (`décimoprimero`); `>= 10^18` falls back to the cardinal.
* `pt`: `0` → `""`; digits at position >= 18 have no separator table
  upstream (it would raise), so our output is `""` there too.
* `pt_PT`: same walker as `pt`, but long-scale separators: 10^9 →
  `milésimo milionésimo`, 10^12 → `bilionésimo`, 10^15 →
  `milésimo bilionésimo`; `>= 10^18` is unsupported.
* `it`: upstream 0.5.14 spells 118/218/... as `centodicottesimo` (typo);
  normalised to `diciottesimo` like the cardinal `dicotto` case. Accents
  are ignored as for cardinals. Negatives are supported (`meno terzo`).
* `en`/`fr`/`es`/`de`/`pt`/`pt_PT`/`ru`: negative ordinals return `""`
  (upstream raises `TypeError`); `ordinal_num` for `it`/`ru` is the plain
  number (upstream returns the int itself).
* `fr` cardinal fix found by ordinal comparison: `cents`/`vingts` drop the
  plural `s` before `mille` (`trois cent mille`, `quatre-vingt mille`).

---

## 3. Defects found and fixed during this milestone

The differential run exposed real divergences; all but the documented rules in
§4 were fixed in the implementation rather than papered over.

| # | Language | Input | Before | After / upstream |
| --- | --- | --- | --- | --- |
| 1 | `en` | `1001` | `one thousand, one` | `one thousand and one` |
| 2 | `en` | `2024` | `two thousand, twenty-four` | `two thousand and twenty-four` |
| 3 | `en` | `1000001` | `one million, one` | `one million and one` |
| 4 | `es` | `10^9` | `un mil millones` | `mil millones` |
| 5 | `es` | `2×10^9` | `dos mil millones` | `dos mil millones` (unchanged, now pinned) |
| 6 | `de` | `1000` | `tausend` | `eintausend` |
| 7 | `de` | `1100` | `tausendeinhundert` | `eintausendeinhundert` |
| 8 | `it` | `123456` | `centoventitrémila…` | `centoventitremila…` |
| 9 | `it` | `1000001` | `un milione uno` | `un milione e uno` |
| 10 | `it` | `1234567` | `un milione duecento…` | `un milione e duecento…` |
| 11 | `en` (year) | `2001` | `twenty one` | `two thousand and one` |
| 12 | `en` (year) | `1001`, `3009` | `ten one`, `thirty nine` | `one thousand and one`, `three thousand and nine` |

Notes on the fixes:

- **English group joining:** the conjunction `and` is now used only before the
  final units group below 100 (`one thousand and one`); other groups keep the
  comma (`one million, one thousand`).
- **English years:** years ending in `01..09` keep the cardinal form
  (`2001` → `two thousand and one`, not `twenty one`).
- **Spanish long scale:** `mil millones` is already a scale phrase, so it never
  takes a preceding `un`.
- **German thousand:** a group value of 1 is spelled `eintausend`
  (`eintausendeinhundert`, `eintausendeins`), matching standard German.
- **Italian:** the accent on `tre` is applied only to the final word of the
  whole number (`ventitré`, `milletré`) and removed when a morpheme follows
  (`centoventitremila`). Million-scale groups are joined with `e`
  (`un milione e uno`).
- **Currency (M3c-1/M3c-2/M3d):** the previous English-only currency mode
  always used USD, could only express whole units, and was bypassed by the
  decimal entry points (`num2words_str("1234.56", "en", "currency")` spelled
  `… point five six`). It is replaced by native formatting for all eight
  language codes with each language's complete upstream code set, covered by
  1215 differential comparisons. The `pt_PT` fixtures also pinned two variant
  differences found during this step: long-scale ordinal separators
  (`milésimo milionésimo`) and zero *pence* for GBP.

---

## 4. Deliberate comparison rules

The upstream behaviours below are normalised or excluded instead of copied,
because our output is intentionally different (and, in the Italian case, more
regular):

1. **Italian accents.** Upstream 0.5.14 applies the `tré` accent
   inconsistently: `23 → ventitré` but `123 → centoventitre`. Our rule is
   orthographically consistent: the accent survives only on the final word.
   Comparisons therefore strip the accent (`é → e`). Upstream also spells
   `118/218/318/418` as `…dicotto`; that typo is normalised to `diciotto`.
2. **Portuguese.** Our implementation has both variants: `pt` is the
   **Brazilian** one and `pt_PT` the **European** one. Fixtures are generated
   with upstream `pt_BR` for `pt` (`dezesseis`, `bilhão` = 10⁹) and upstream
   `pt` for `pt_PT` (`dezasseis`, `mil milhões` = 10⁹, `bilião` = 10¹²).
   Upstream `pt_BR` separates scale groups with a comma (`mil, duzentos`);
   Portuguese usage and our output use a plain space, so commas are removed
   before comparing. `pt_PT` ordinal long-scale separators and GBP zero
   *pence* are compared verbatim.
3. **Currency.** Amounts are passed to upstream as floats
   (`num2words(1234.56, ...)`), because upstream reads a bare Python `int` as
   *cents* (`1234` → 12.34); this project treats the integer part as the major
   unit. `pt_BR` accepts no currency code upstream, so only `BRL` is compared
   (and its commas are stripped as for cardinals). Rounding is exact decimal
   half-up on the third digit, while upstream rounds through a binary float, so
   exact `x.xx5` amounts (e.g. `1.005`) are excluded. Italian negative amounts
   are supported here (`meno …`) but excluded because upstream 0.5.14 raises
   `AttributeError`. Upstream's Russian PLN paucal typo (`слотых`) is
   normalised to `злотых`. Everything else — including the Spanish
   masculine *quinientos* and the Russian feminine *одна миллион* — is
   compared verbatim.

No other comparison rule is applied: cardinal/year/ordinal output for `en`,
`fr`, `es`, `de` and `ru` is compared byte-for-byte; the currency rules above
only affect the cases they name.

---

## 5. Reproduce

```bash
pip install num2words==0.5.14
python tools/gen_fixtures.py   # rewrites diff_fixtures_wbtest.mbt
moon test                      # replays all 7796 comparisons
```
