# Differential test report — num2words-moonbit vs upstream num2words

This report records the differential test run that checks our MoonBit output
against the upstream Python [`num2words`](https://github.com/savoirfairelinux/num2words)
library (LGPL-2.1). Only upstream **output strings** are used, never its source
code.

- Upstream version: **num2words 0.5.14**
- Upstream languages used: `en`, `fr`, `es`, `de`, `it`, `pt_BR`, `ru`
- Samples per language: **551** (`0..500` plus 51 multi-scale / signed values)
- Total comparisons: **3857** (7 × 551)
- MoonBit test suite: **37 tests, 37 passed, 0 failed**

Run `moon test` from the project root to replay every comparison.

---

## 1. Method

1. `tools/gen_fixtures.py` calls upstream `num2words` for each sample and writes
   the expected strings to `diff_fixtures_wbtest.mbt`.
2. The generated MoonBit test feeds the same input strings through our public
   `num2words_str(value, lang, "cardinal")` entry point and asserts equality.
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

---

## 2. Results

| Language | Samples | Passed | Comparison |
| --- | --- | --- | --- |
| `en` | 551 | 551 | verbatim |
| `fr` | 551 | 551 | verbatim |
| `es` | 551 | 551 | verbatim |
| `de` | 551 | 551 | verbatim |
| `it` | 551 | 551 | accents ignored (see §4) |
| `pt` | 551 | 551 | upstream `pt_BR`, commas ignored (see §4) |
| `ru` | 551 | 551 | verbatim |

All 3857 comparisons pass under the two documented comparison rules in §4.

---

## 3. Defects found and fixed during this milestone

The differential run exposed real divergences; all but the two documented
orthographic rules were fixed in the implementation rather than papered over.

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

Notes on the fixes:

- **English group joining:** the conjunction `and` is now used only before the
  final units group below 100 (`one thousand and one`); other groups keep the
  comma (`one million, one thousand`).
- **Spanish long scale:** `mil millones` is already a scale phrase, so it never
  takes a preceding `un`.
- **German thousand:** a group value of 1 is spelled `eintausend`
  (`eintausendeinhundert`, `eintausendeins`), matching standard German.
- **Italian:** the accent on `tre` is applied only to the final word of the
  whole number (`ventitré`, `milletré`) and removed when a morpheme follows
  (`centoventitremila`). Million-scale groups are joined with `e`
  (`un milione e uno`).

---

## 4. Deliberate comparison rules

Two upstream behaviours are normalised instead of copied, because our output is
intentionally different (and, in the Italian case, more regular):

1. **Italian accents.** Upstream 0.5.14 applies the `tré` accent
   inconsistently: `23 → ventitré` but `123 → centoventitre`. Our rule is
   orthographically consistent: the accent survives only on the final word.
   Comparisons therefore strip the accent (`é → e`). Upstream also spells
   `118/218/318/418` as `…dicotto`; that typo is normalised to `diciotto`.
2. **Portuguese.** Our implementation is the **Brazilian variant**, so fixtures
   are generated with upstream `pt_BR` (`dezesseis`, `bilhão` = 10⁹), not the
   European `pt`. Upstream `pt_BR` separates scale groups with a comma
   (`mil, duzentos`); Portuguese usage and our output use a plain space, so
   commas are removed before comparing.

No other comparison rule is applied: `en`, `fr`, `es`, `de` and `ru` are
compared byte-for-byte.

---

## 5. Reproduce

```bash
pip install num2words==0.5.14
python tools/gen_fixtures.py   # rewrites diff_fixtures_wbtest.mbt
moon test                      # replays all 3857 comparisons
```
