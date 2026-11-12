# Differential test report — num2words-moonbit vs upstream num2words

This report records the differential test run that checks our MoonBit output
against the upstream Python [`num2words`](https://github.com/savoirfairelinux/num2words)
library (LGPL-2.1). Only upstream **output strings** are used, never its source
code.

- Upstream version: **num2words 0.5.14** (Chinese: upstream master `lang_ZH.py`,
  vendored in `tools/upstream_lang_ZH_master.py`, because 0.5.14 has no Chinese)
- Upstream languages used: `en`, `fr`, `es`, `de`, `it`, `pt_BR`, `pt`, `ru`,
  `nl`, `tr`, `vi`, `ja`, `ko`, `sv`, `no`, `da`, `id`, `pl`, `ar`, `th`,
  `fi`, `uk`, plus `lang_ZH` (master) for `zh`/`zh_TW`
- Cardinal samples per language: **551** (`0..500` plus 50 multi-scale / signed
  values); Vietnamese and Polish use **547** (negative samples excluded —
  upstream's negative handling is broken); Arabic, Finnish and Ukrainian use
  **551** for the same reason (negatives skipped, zeros and positives match)
- Year samples: **25** each for most language codes that implement `to_year`,
  plus **6 negative years** for `en`/`pt`/`pt_PT`/`ko`/`id`/`ar`/`th`/`fi`/
  `uk`/`zh`/`zh_TW` (**31** each); Japanese uses **24** (years before 645 are
  rejected upstream); Vietnamese and Swedish have no `to_year`
- Ordinal samples per language: **249** (dense `0..200` plus
  hundreds/thousands/scale boundaries; Portuguese drops the `10^18` sample that
  upstream rejects, Korean drops its `KeyError` cases, Polish drops 0 and its
  `IndexError` cases, Ukrainian drops its one rejected sample), `ordinal_num`:
  **11** per language (Vietnamese, Swedish and Finnish upstream have no
  `ordinal_num`)
- Currency samples: **6222** total — **340** for `en` (20 codes × 17 amounts),
  **85** each for `fr`/`de` (5 × 17), **68** for `nl` (4 × 17), **60** for `it`
  (4 × 17 minus its 8 rejected negative samples), **4446** for `es` (171 × 26),
  **208** for `ru` (8 × 26), **26** for `pt`, **130** for `pt_PT` (26 × 5),
  **13** for `tr` (clean amounts only, see §4), **7** for `ja`, **27** for `ko`,
  **11** for `no`, **10** each for `da`/`id`, **288** for `fi` (24 codes × 12
  amounts) and **204** each for `zh`/`zh_TW` (17 codes × 12 amounts)
- Total comparisons: **26217** (13216 cardinal + 615 year + 5933 ordinal
  + 231 ordinal_num + 6222 currency)
- MoonBit test suite: **183 tests, 183 passed, 0 failed**

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
| Years | `101, 999, 1000, 1001, 1010, 1100, 1104, 1500, 1900, 1904, 1984, 1999, 2000, 2001, 2004, 2009, 2010, 2023, 2024, 2100, 2134, 3000, 3001, 9999, 12345` |
| Scales | `2345, 3000, 5000, 9999, 10000, 11000, 12000, 21000, 22000, 25000` |
| Large | `100000, 100001, 123000, 123456, 999999, 1000000, 1000001, 1000021, 1000100, 1001000, 1100000, 1234567, 2000000, 5000000, 10^9, 2×10^9, 10^12` |
| Signed | `-1, -42, -1000, -123456` |

Year samples (every code that implements it upstream): `101, 999, 1000, 1001,
1010, 1100, 1104, 1500, 1900, 1904, 1984, 1999, 2000, 2001, 2004, 2009, 2010,
2023, 2024, 2100, 2134, 3000, 3001, 9999, 12345`, plus the negative years
`-1, -44, -156, -1000, -1900, -2001` for `en`/`pt`/`pt_PT`/`ko`/`id`/`ar`/
`th`/`fi`/`uk`/`zh`/`zh_TW` (§4 rule 7 explains why `de`/`nl` are excluded). German uses upstream's
*-hundert* form for 1100–9999 (`1900` → *neunzehnhundert*, `101` →
*einshunderteins*), Dutch its *-honderd* form (`1900` → *negentien honderd*),
Japanese its era calendar (`2024` → *令和六年*), Chinese reads the year digit by
digit (*二零二四年*); Turkish, Indonesian and Polish years are plain cardinals,
English uses the `oh-` form for a low part below ten and `BC` for negative
years.

Currency samples: `en` uses its 20 codes, `fr`/`de` their 5 and `it`/`nl`
their 4 codes with the 17 amounts `0, 0.01, 0.5, 1, 2, 21, 28, 81, 101, 1000,
1001, 1234.56, 999.99, 1.999, 1234.567, -3.5, -1.999`; `es` uses 26 amounts ×
its complete upstream set of 171 codes, `ru` 26 × 8, `pt` 26 × `BRL` and
`pt_PT` 26 × 5, adding `5, 11, 22, 25, 100, 200, 500, 2000, 21000, 1000000,
1000001, 2000000`. `tr` uses 13 amounts that are
free of upstream's float truncation, `ja` 7 integral amounts, `ko` 27
KRW/USD/JPY samples, `no` 11, `da`/`id` 10 each, `fi` 288 (24 codes × 12
amounts) and `zh`/`zh_TW` 12 amounts × 17 master codes. Amounts are passed to
upstream as floats, so its type-dependent int-as-cents quirk does not apply.

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
| `nl` | 551 | 551 | verbatim |
| `tr` | 551 | 551 | verbatim |
| `vi` | 547 | 547 | verbatim (negative samples excluded, see §4) |
| `ja` | 551 | 551 | verbatim |
| `ko` | 551 | 551 | verbatim |
| `sv` | 551 | 551 | verbatim |
| `no` | 551 | 551 | verbatim |
| `da` | 551 | 551 | verbatim |
| `id` | 551 | 551 | verbatim |
| `pl` | 547 | 547 | verbatim (negative samples excluded, see §4) |
| `zh` | 551 | 551 | upstream master `lang_ZH`, Simplified characters (see §4) |
| `zh_TW` | 551 | 551 | upstream master `lang_ZH`, verbatim |
| `ar` | 551 | 551 | verbatim (negatives skipped; dual/plural scale forms) |
| `th` | 551 | 551 | verbatim (10^6 groups, เอ็ด rule) |
| `fi` | 551 | 551 | verbatim (negatives skipped) |
| `uk` | 551 | 551 | verbatim (negatives skipped; three-way plurals) |

| Language | Year samples | Passed | Comparison |
| --- | --- | --- | --- |
| `en` | 31 | 31 | verbatim, including `BC` and the `oh-` form (`1904` → *nineteen oh-four*) |
| `fr` | 25 | 25 | verbatim |
| `es` | 25 | 25 | verbatim |
| `de` | 25 | 25 | verbatim (*-hundert* form; `101` → *einshunderteins*) |
| `it` | 25 | 25 | accents ignored |
| `pt` | 31 | 31 | upstream `pt_BR`, commas ignored; *antes de Cristo* |
| `pt_PT` | 31 | 31 | upstream `pt`, commas ignored; *antes de Cristo* |
| `ru` | 25 | 25 | verbatim |
| `nl` | 25 | 25 | verbatim (*-honderd* form; negatives excluded, see §4) |
| `tr` | 25 | 25 | verbatim (cardinal) |
| `ja` | 24 | 24 | era calendar (`2024` → *令和六年*); years before 645 skipped |
| `ko` | 31 | 31 | verbatim (including *기원전* for negative years) |
| `no` | 25 | 25 | verbatim (*-hundre* split) |
| `da` | 25 | 25 | verbatim (*-hundrede* split) |
| `id` | 31 | 31 | cardinal (including `min` for negative years) |
| `pl` | 25 | 25 | cardinal |
| `zh` | 31 | 31 | digit by digit, *公元前* for negative years |
| `zh_TW` | 31 | 31 | digit by digit, *公元前* for negative years |
| `ar` | 31 | 31 | cardinal, *سالب* for negative years |
| `th` | 31 | 31 | cardinal, *ติดลบ* for negative years |
| `fi` | 31 | 31 | space-free cardinal, *ennen ajanlaskun alkua* for negative years |
| `uk` | 31 | 31 | cardinal, *мінус* for negative years |

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
| `nl` | 249 | 11 | 260 | verbatim |
| `tr` | 249 | 11 | 260 | verbatim (10^18 keeps *kentilyon*) |
| `vi` | 249 | 0 | 249 | verbatim (ordinal = cardinal; no `ordinal_num` upstream) |
| `ja` | 249 | 11 | 260 | verbatim (`…番目`) |
| `ko` | 214 | 11 | 225 | native counters; upstream `KeyError` cases skipped |
| `sv` | 249 | 0 | 249 | verbatim (no `ordinal_num` upstream) |
| `no` | 249 | 11 | 260 | verbatim (`N.` ordinal numbers) |
| `da` | 249 | 11 | 260 | verbatim (`N.te` / `N.en` / `N.ende`) |
| `id` | 249 | 11 | 260 | verbatim (`ke…` / `ke-N`) |
| `pl` | 244 | 11 | 255 | verbatim; 0 and upstream `IndexError` cases skipped |
| `zh` | 249 | 11 | 260 | verbatim (第… / 第N) |
| `zh_TW` | 249 | 11 | 260 | verbatim (第…萬 / 第N) |
| `ar` | 249 | 11 | 260 | verbatim (gender-aware ordinals) |
| `th` | 249 | 11 | 260 | verbatim (ordinal = cardinal; digits) |
| `fi` | 249 | 0 | 249 | verbatim (no `ordinal_num` upstream) |
| `uk` | 248 | 11 | 259 | verbatim (one rejected sample skipped) |

| Language | Currency samples | Passed | Comparison |
| --- | --- | --- | --- |
| `en` | 340 | 340 | verbatim (20 codes) |
| `fr` | 85 | 85 | verbatim (5 codes) |
| `de` | 85 | 85 | verbatim (5 codes) |
| `it` | 60 | 60 | verbatim (4 codes; negative amounts excluded, see §4) |
| `es` | 4446 | 4446 | verbatim (171 codes; upstream quirks included, e.g. masculine *quinientos*, double-space *lek*) |
| `ru` | 208 | 208 | verbatim (8 codes); PLN paucal typo normalised (see §4) |
| `pt` | 26 | 26 | upstream `pt_BR`, commas ignored (see §4) |
| `pt_PT` | 130 | 130 | upstream `pt`, commas ignored; GBP zero *pence* (see §4) |
| `nl` | 68 | 68 | verbatim (4 codes; invariant nouns) |
| `tr` | 13 | 13 | verbatim (TRY only; clean amounts, see §4) |
| `ja` | 7 | 7 | verbatim (JPY only; integral amounts) |
| `ko` | 27 | 27 | verbatim (KRW/USD/JPY; KRW/JPY cents rejected) |
| `no` | 11 | 11 | verbatim (NOK; zero øre omitted) |
| `da` | 10 | 10 | verbatim (DKK; `float2tuple` quirks, see §4) |
| `id` | 10 | 10 | verbatim (IDR; `koma` rendering, see §4) |
| `zh` | 204 | 204 | upstream master, Simplified characters (see §4) |
| `zh_TW` | 204 | 204 | upstream master, verbatim (元/角/分) |
| `fi` | 288 | 288 | verbatim (24 codes × 12 amounts) |

All **26217** comparisons pass under the documented comparison rules in §4.

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
| 13 | `zh` | `-123456` | `负十二万…` | `负一十二万…` (upstream strips `一十` only without a sign prefix) |
| 14 | `zh_TW` (ordinal) | `10000` | `第一万` | `第一萬` (traditional tables used for ordinals) |
| 15 | `ko` (ordinal) | `123456` | `삼천사백쉰여섯` | `삼천사백 쉰여섯` (upstream joins the `백` fragments with `백 `) |
| 16 | `da` (currency) | `0.5` | `halvtreds øre` | `fem øre` (upstream splits the raw float via `float2tuple`) |
| 17 | `es` | `4440376435` | `cuatro mil millones cuatrocientos…` | `cuatro mil cuatrocientos cuarenta millones…` (10^9 + 10^6 form one long-scale phrase) |
| 18 | `pt_PT` | `600990392858037` | `… biliões e novecentos e noventa mil e trezentos…` | `… biliões novecentos e noventa mil trezentos…` (all occurrences removed after the regex matches) |
| 19 | `pt` | `743147310600031` | `… milhões e seiscentos mil…` | `… milhões seiscentos mil…` (Brazilian removes only the first occurrence per scale word) |
| 20 | `it` | `786790526496` | `… miliardi e … milioni e …` | `… miliardi, … milioni e …` (comma when the remainder itself contains ` e `) |
| 21 | `tr` | `591170` | `beşyüzdoksanbirbinyüzyetmiş` | `beşyüzdoksanbinyüzyetmiş` (leading thousands group drops its trailing `bir` when it has hundreds and the number continues) |

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
- **Year mode (all languages):** `fr`/`es` previously used a pair-reading
  convention; they now use the upstream cardinal reading, and German follows
  upstream's *-hundert* form for 1100–9999. All ten codes that implement
  `to_year` upstream are now in the year differential set.
- **Currency (M3c-1/M3c-2/M3d):** the previous English-only currency mode
  always used USD, could only express whole units, and was bypassed by the
  decimal entry points (`num2words_str("1234.56", "en", "currency")` spelled
  `… point five six`). It is replaced by native formatting for ten language
  codes with each language's complete upstream code set, covered by 5461
  differential comparisons. The `pt_PT` fixtures also pinned two variant
  differences found during this step: long-scale ordinal separators
  (`milésimo milionésimo`) and zero *pence* for GBP.
- **Default currency dispatch (M4):** `to="currency"` and
  `num2words_str_checked(..., "currency")` used to pass a hard-coded `EUR`,
  which silently dropped `pt`'s BRL default. Both now resolve the language
  default (`BRL` for `pt`, `TRY` for `tr`, `EUR` otherwise), pinned by the
  tests in `num2words-moonbit_wbtest.mbt`.
- **M4 — three new languages:** Dutch (`nl`), Turkish (`tr`) and Vietnamese
  (`vi`) were added with 6057 cardinal, 190 year, 2737 ordinal, 110
  `ordinal_num` and 5461 currency comparisons. No implementation defect was
  found in the existing languages during this step; the new-language
  algorithms were iterated against the differential fixtures (notably Dutch
  *duizend* swallowing a group value of 1, and Turkish ordinals over the last
  morpheme).
- **M5 — complete currency code sets:** the remaining upstream language/code
  pairs were filled in — `en` 11 → 20, `fr` 4 → 5 (`FRF`), `de` 4 → 5 (`DEM`),
  `es` 20 → 171 (the complete upstream table) and `ru` 6 → 8 — bringing
  coverage from 60 to 224 pairs. The Spanish additions replicate upstream
  verbatim, including its irregular data (`ALL` singular `lek ` keeps a
  trailing space, `MAD` is `un dírham` but `dos dirhams`, `ZRZ` pairs a
  `likuta` singular with a `makuta` plural, and `ISK` uses the unrelated
  `eyrir`/`aurar` pair).
- **M6 — CJK, Scandinavian, Slavic and Southeast Asian expansion:** nine new
  codes were added — `zh`, `zh_TW`, `ja`, `ko`, `sv`, `no`, `da`, `id`, `pl` —
  bringing the project to **20 language codes**, **265 currency pairs** and
  **22573 comparisons**. This milestone introduced `group4` (10⁴ scale words),
  the Japanese era table, the Chinese `元/角/分` renderer and the Danish
  `float2tuple` currency split; the defects found while aligning them are rows
  13–16 above.
- **M7 — randomized audit:** a 1,799-assertion randomized differential sweep
  across all twenty languages (random magnitudes, ordinals, years and currency
  amounts) found the long-scale, post-processing and Turkish defects in rows
  17–21. They are fixed and pinned by regression assertions in
  `num2words-moonbit_wbtest.mbt`. The same sweep also led to rejecting unknown
  language/mode names explicitly (`""` / `Err(...)`) instead of falling back to
  English/`cardinal`.
- **M8 — Arabic, Thai, Finnish and Ukrainian:** four more full-mode language
  codes were added (`ar`, `th`, `fi`, `uk`), bringing the project to
  **24 language codes**, **289 currency pairs** and **26217 comparisons**.
  Arabic contributes dual/plural scale forms and gender-aware ordinals, Thai
  its 10^6 grouping, Finnish its partitive compounds plus 24 currency codes,
  and Ukrainian its three-way plurals. A 2142-assertion randomized differential
  sweep across all 24 languages found no further mismatch.

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
4. **Vietnamese and Polish negatives.** Upstream 0.5.14 reads Vietnamese `-1`
   as `mười chín` and raises `IndexError` for smaller negatives; Polish raises
   `ValueError` for any negative input. The negative cardinal samples are
   excluded from both fixtures. This project spells them (`âm bốn mươi hai`,
   `minus czterdzieści dwa`). Vietnamese and Swedish `year`, `ordinal_num` and
   `currency` are absent upstream (`AttributeError`) and are not part of the
   fixtures either.
5. **Turkish currency.** Upstream's `to_currency` takes no ISO code, truncates
   cents through `int(val * 100)` and returns `bedelsiz` for any amount below
   one lira. Only clean amounts (no third decimal, at least one lira) are
   compared; the zero amount coincides (`bedelsiz`). Everything else follows
   the exact-decimal rule in item 3.
6. **Decimals.** Fractional digits are spelled one by one here, while `tr`/`vi`
   upstream read the last two digits as a number (`12.34` → *otuz dört* /
   *ba mươi bốn*). Chinese/Japanese join the point without spaces (`零点五`),
   Korean spaces it (`점 오`), and the other languages insert a space before
   each digit. Decimal cardinals are therefore not part of the fixtures
   (this also applies to the earlier languages). Three further consequences of
   upstream's `Decimal` pipeline are not reproduced, because this project
   spells the digits exactly as given:
   * a trailing fractional zero is spoken here but dropped upstream
     (`1.10` → *one point one zero* here, *one point one* upstream);
   * `0.0` → *zero point zero* here, *zero* upstream;
   * a negative amount keeps its sign here (`-0.5` → *minus zero point five*),
     while upstream loses it (*zero point five*; likewise for Japanese,
     Korean and Chinese floats).
7. **Negative years.** English appends `BC`, Portuguese `antes de Cristo` and
   Chinese `公元前`, exactly as upstream (`-44` → *forty-four BC* /
   *quarenta e quatro antes de Cristo* / *公元前四四年*); German and Dutch
   upstream apply `//`/`%` to the negative value and emit nonsense (`-1` →
   *minuseinshundertneunundneunzig* / *min één honderd negenennegentig*), so
   those two spell a clean *minus* / *min* followed by the year here and are
   excluded from the year fixtures. Japanese era years below 645 and negative
   years raise upstream and return `""` here. All other languages match
   upstream (`moins`, `menos`, `meno`, `минус`, `eksi`, `기원전`, `min`).
8. **Chinese source.** Upstream 0.5.14 has no Chinese module. `zh_TW` is
   compared verbatim against the `lang_ZH.py` on upstream master (vendored in
   `tools/upstream_lang_ZH_master.py`); `zh` is the same output passed through
   a Traditional-to-Simplified character table (萬→万, 億→亿, 負→负, 點→点, …)
   plus the corresponding currency names. The grammar is identical.
9. **Danish and Indonesian currency.** Danish upstream calls `to_splitnum` on
   the raw float, so `0.5` → *fem øre* (not fifty) and `0` → `""`; Indonesian
   spells `<cardinal> koma nol rupiah` for integers and the fractional digits
   after `koma` otherwise. Both are reproduced and compared verbatim. Japanese
   rejects any fractional JPY amount (fixtures use integral amounts); Korean
   KRW/JPY reject cents, while USD always spells them.

No other comparison rule is applied: cardinal output for `en`, `fr`, `es`,
`de`, `ru`, `nl`, `tr`, `ja`, `ko`, `sv`, `no`, `da`, `id` and `zh_TW` is
compared byte-for-byte (and `vi`/`pl` after excluding their broken negatives),
and so are years for positive values; the currency and negative-year rules
above only affect the cases they name.

---

## 5. Reproduce

```bash
pip install num2words==0.5.14
python tools/gen_fixtures.py   # rewrites diff_fixtures_wbtest.mbt
moon test                      # replays all 26217 comparisons
```
