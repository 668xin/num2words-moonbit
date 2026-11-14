#!/usr/bin/env python3
"""Generate differential-test fixtures from the upstream Python num2words.

Usage:
    pip install num2words
    python tools/gen_fixtures.py

Writes ``diff_fixtures_wbtest.mbt`` in the project root. The MoonBit test then
replays the same inputs through our implementation and compares the output.

Notes
-----
* Portuguese is generated with upstream ``pt_BR`` (our implementation targets
  the Brazilian variant). Upstream separates scale groups with a comma, so
  commas are stripped on both sides when comparing (see ``DIFF_REPORT.md``).
* Italian is compared with accents stripped, because upstream applies the
  "tré" accent inconsistently inside compounds (e.g. ``centoventitre`` while
  standalone ``ventitré``). Our output follows standard orthography. Upstream
  0.5.14 also spells 118/218/... as ``centodicotto`` instead of
  ``centodiciotto``; that typo is normalised away (see ``DIFF_REPORT.md``).
* Everything else is compared verbatim.
* Chinese has no module in the 0.5.14 release: `zh` (Simplified) and `zh_TW`
  (Traditional) are compared against the `lang_ZH.py` vendored in
  ``tools/upstream_lang_ZH_master.py`` (upstream master). The Simplified
  fixture is produced by character-mapping the Traditional output.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from num2words import num2words
    from num2words import lang_ES
    from upstream_lang_ZH_master import Num2Word_ZH
except ImportError:
    sys.exit("num2words is not installed: pip install num2words")

ZH_MASTER = Num2Word_ZH()

# Traditional -> Simplified for the characters used by lang_ZH (digits and
# place words are identical, so only the scale/currency characters matter).
ZH_TO_SIMPLIFIED = str.maketrans({
    "萬": "万", "億": "亿", "負": "负", "點": "点", "溝": "沟", "澗": "涧",
    "載": "载", "極": "极", "恆": "恒", "議": "议", "無": "无", "說": "说",
    "幣": "币", "門": "门", "馬": "马", "來": "来", "亞": "亚", "歐": "欧",
    "鎊": "镑", "紐": "纽", "蘭": "兰", "韓": "韩", "銖": "铢", "臺": "台",
    "灣": "湾", "穣": "穰",
})


def zh_out(text: str, ours: str) -> str:
    return text if ours == "zh_TW" else text.translate(ZH_TO_SIMPLIFIED)


def expected(ours: str, upstream: str, n: int, to: str) -> str:
    """Expected upstream output for one language/mode/value."""
    if ours in ("zh", "zh_TW"):
        if to == "cardinal":
            raw = ZH_MASTER.to_cardinal(n)
        elif to == "year":
            raw = ZH_MASTER.to_year(n)
        elif to == "ordinal":
            raw = ZH_MASTER.to_ordinal(n)
        elif to == "ordinal_num":
            raw = ZH_MASTER.to_ordinal_num(n)
        else:
            raise ValueError(to)
        return zh_out(raw, ours)
    return num2words(n, lang=upstream, to=to)


def expected_currency(
    ours: str, upstream: str, amount: str, code: str
) -> str:
    if ours in ("zh", "zh_TW"):
        return zh_out(
            ZH_MASTER.to_currency(float(amount), currency=code), ours
        )
    # Persian `to_currency` takes only the value (no ISO code).
    if upstream == "fa":
        return num2words(float(amount), lang=upstream, to="currency")
    if upstream in ("pt_BR", "tr", "da", "id"):
        return num2words(float(amount), lang=upstream, to="currency")
    return num2words(
        float(amount), lang=upstream, to="currency", currency=code
    )

# Upstream language code -> our language code.
LANGS = {
    "en": "en",
    "fr": "fr",
    "es": "es",
    "de": "de",
    "it": "it",
    "pt_BR": "pt",
    "pt": "pt_PT",
    "ru": "ru",
    "nl": "nl",
    "tr": "tr",
    "vi": "vi",
    "ja": "ja",
    "ko": "ko",
    "sv": "sv",
    "no": "no",
    "da": "da",
    "id": "id",
    "pl": "pl",
    "ar": "ar",
    "th": "th",
    "fi": "fi",
    "uk": "uk",
    "ro": "ro",
    "hu": "hu",
    "he": "he",
    "fa": "fa",
    "eo": "eo",
    "cs": "cs",
    "sk": "sk",
    "sr": "sr",
    "lt": "lt",
    # No 0.5.14 module: generated through the vendored upstream master module.
    "zh": "zh",
    "zh_TW": "zh_TW",
}

SAMPLES = list(range(0, 501)) + [
    600, 700, 800, 900, 999,
    1000, 1001, 1003, 1010, 1023, 1100, 1111, 1234, 1900, 1999,
    2000, 2003, 2023, 2024, 2345, 3000,
    5000, 9999, 10000, 11000, 12000, 21000, 22000, 25000,
    100000, 100001, 123000, 123456, 999999,
    1000000, 1000001, 1000021, 1000100, 1001000, 1100000, 1234567,
    2000000, 5000000,
    1000000000, 2000000000, 1000000000000,
    -1, -42, -1000, -123456,
]

# Year mode is compared for all eight language codes. German uses upstream's
# "hundert" form between 1100 and 9999 (1900 -> neunzehnhundert).
YEAR_LANGS = {
    "en": "en",
    "fr": "fr",
    "es": "es",
    "de": "de",
    "it": "it",
    "pt_BR": "pt",
    "pt": "pt_PT",
    "ru": "ru",
    "nl": "nl",
    "tr": "tr",
    "ja": "ja",
    "ko": "ko",
    "no": "no",
    "da": "da",
    "id": "id",
    "pl": "pl",
    "ar": "ar",
    "th": "th",
    "fi": "fi",
    "uk": "uk",
    "ro": "ro",
    "hu": "hu",
    "he": "he",
    "fa": "fa",
    "eo": "eo",
    "cs": "cs",
    "sk": "sk",
    "sr": "sr",
    "lt": "lt",
    "zh": "zh",
    "zh_TW": "zh_TW",
}

YEAR_SAMPLES = [
    101, 999, 1000, 1001, 1010, 1100, 1104, 1500, 1900, 1904, 1984, 1999,
    2000, 2001, 2004, 2009, 2010, 2023, 2024, 2100, 2134, 3000, 3001, 9999,
    12345,
]

# Negative years: English appends "BC", Portuguese "antes de Cristo". German
# and Dutch upstream emit mangled output for negative years (e.g. -1 ->
# "minuseinshundertneunundneunzig"), so they are excluded here and covered by
# a handwritten whitebox test that pins the clean "minus/min" form.
YEAR_BC_LANGS = {
    "en": "en",
    "pt_BR": "pt",
    "pt": "pt_PT",
    "ko": "ko",
    "id": "id",
    "ar": "ar",
    "th": "th",
    "fi": "fi",
    "uk": "uk",
    "ro": "ro",
    "hu": "hu",
    "he": "he",
    "fa": "fa",
    "eo": "eo",
    "sr": "sr",
    "lt": "lt",
    "zh": "zh",
    "zh_TW": "zh_TW",
}
YEAR_BC_SAMPLES = [-1, -44, -156, -1000, -1900, -2001]

# Ordinal samples: dense through 200, then selected hundreds/thousands and
# scale boundaries. Values whose ordinal upstream rejects (negatives, and
# Portuguese digits past position 15) are skipped by the generator.
ORD_SAMPLES = list(range(0, 201)) + [
    300, 400, 500, 600, 700, 800, 900, 999,
    1000, 1001, 1010, 1023, 1100, 1111, 1234, 1999,
    2000, 2001, 2024, 3000, 5000, 9999,
    10000, 11000, 12000, 20000, 21000, 22000, 25000, 40000, 90000,
    100000, 110000, 123456, 300000, 900000,
    1000000, 1000001, 1000021, 1100000, 2000000, 21000000, 1234567,
    1000000000, 2000000000,
    1000000000000,
    10**15, 10**18,
]

ORDNUM_SAMPLES = [0, 1, 2, 3, 4, 11, 21, 100, 101, 1000, 12345]

# Currency mode: every language with the code set upstream supports. Amounts
# are passed to upstream as floats so the int-as-cents quirk does not apply;
# exact third-digit "5" samples (e.g. 1.005) are excluded because upstream
# rounds through a binary float while this project rounds the exact decimal.
CURRENCY_LANGS = {
    "en": "en",
    "fr": "fr",
    "de": "de",
    "it": "it",
    "es": "es",
    "ru": "ru",
    "pt_BR": "pt",
    "pt": "pt_PT",
    "nl": "nl",
    "tr": "tr",
    "ja": "ja",
    "ko": "ko",
    "no": "no",
    "da": "da",
    "id": "id",
    "zh": "zh",
    "zh_TW": "zh_TW",
    # Finnish is the only one of the four with a currency mode.
    "fi": "fi",
    "ro": "ro",
    "hu": "hu",
    "he": "he",
    "eo": "eo",
    "fa": "fa",
    "cs": "cs",
    "sk": "sk",
    "sr": "sr",
    "lt": "lt",
}
CURRENCY_CODES = {
    "en": [
        "EUR", "USD", "GBP", "RUB", "CAD", "AUD", "INR", "SEK", "NOK", "PLN",
        "MXN", "BYN", "EEK", "HUF", "ISK", "LTL", "LVL", "RON", "SAR", "UZS",
    ],
    "fr": ["EUR", "USD", "GBP", "CNY", "FRF"],
    "de": ["EUR", "USD", "GBP", "CNY", "DEM"],
    "it": ["EUR", "USD", "GBP", "CNY"],
    # Spanish: the complete upstream 0.5.14 set (171 codes).
    "es": sorted(lang_ES.Num2Word_ES.CURRENCY_FORMS.keys()),
    "ru": ["EUR", "USD", "RUB", "PLN", "UAH", "KZT", "BYN", "UZS"],
    "pt_BR": ["BRL"],
    "pt": ["EUR", "USD", "GBP", "CAD", "AUD"],
    "nl": ["EUR", "GBP", "USD", "CNY"],
    "tr": ["TRY"],
    "ja": ["JPY"],
    "ko": ["KRW", "USD", "JPY"],
    "no": ["NOK"],
    "da": ["DKK"],
    "id": ["IDR"],
    "fi": [
        "BRL", "CHF", "CNY", "EUR", "FIM", "INR", "JPY", "KRW", "KPW",
        "MXN", "RUB", "TRY", "ZAR", "DKK", "ISK", "NOK", "SEK", "AUD",
        "CAD", "HKD", "NZD", "SGD", "USD", "GBP",
    ],
    # Chinese: every code upstream master's lang_ZH implements (incl. XXX).
    "zh": sorted(ZH_MASTER.CURRENCY_FORMS.keys()),
    "zh_TW": sorted(ZH_MASTER.CURRENCY_FORMS.keys()),
    # Romanian / Hungarian use the 20-code EU set.
    "ro": [
        "AUD", "BYN", "CAD", "EEK", "EUR", "GBP", "LTL", "LVL", "USD",
        "RUB", "SEK", "NOK", "PLN", "MXN", "RON", "INR", "HUF", "ISK",
        "UZS", "SAR",
    ],
    "hu": [
        "AUD", "BYN", "CAD", "EEK", "EUR", "GBP", "LTL", "LVL", "USD",
        "RUB", "SEK", "NOK", "PLN", "MXN", "RON", "INR", "HUF", "ISK",
        "UZS", "SAR",
    ],
    "he": ["ILS", "EUR", "USD"],
    "eo": ["EUR", "USD", "FRF", "GBP", "CNY"],
    # Persian has no currency parameter; the empty code selects the default.
    "fa": [""],
    "cs": ["CZK", "EUR"],
    "sk": ["EUR"],
    "sr": ["RUB", "EUR", "RSD"],
    "lt": ["LTL", "EUR", "USD", "GBP", "PLN", "RUB"],
}
CURRENCY_SAMPLES_BASIC = [
    "0", "0.01", "0.5", "1", "2", "21", "28", "81", "101", "1000", "1001",
    "1234.56", "999.99", "1.999", "1234.567", "-3.5", "-1.999",
]
CURRENCY_SAMPLES_FULL = [
    "0", "0.01", "0.5", "1", "2", "5", "11", "21", "22", "25", "100", "101",
    "200", "500", "1000", "2000", "21000", "1000000", "1000001", "2000000",
    "1234.56", "999.99", "1.999", "1234.567", "-3.5", "-1.999",
]
CURRENCY_SAMPLES = {
    "en": CURRENCY_SAMPLES_BASIC,
    "fr": CURRENCY_SAMPLES_BASIC,
    "de": CURRENCY_SAMPLES_BASIC,
    "it": CURRENCY_SAMPLES_BASIC,
    "es": CURRENCY_SAMPLES_FULL,
    "ru": CURRENCY_SAMPLES_FULL,
    "pt_BR": CURRENCY_SAMPLES_FULL,
    "pt": CURRENCY_SAMPLES_FULL,
    "nl": CURRENCY_SAMPLES_BASIC,
    # Turkish upstream truncates through `int(val * 100)` and returns
    # "bedelsiz" for any amount below one lira, so only clean amounts are
    # comparable (see DIFF_REPORT.md §4).
    "tr": [
        "0", "1", "2", "21", "28", "81", "101", "1000", "1001",
        "12.34", "1234.56", "1.5", "-3.5",
    ],
    # Japanese rejects any fractional amount; negative integers are fine.
    "ja": ["0", "1", "2", "21", "101", "1000", "-3"],
    # Korean KRW/JPY reject cents (those combinations are skipped by the
    # generator); USD always spells the cent part, even when it is zero.
    "ko": [
        "0", "1", "2", "5", "11", "21", "101", "1000",
        "1234.56", "0.5", "-3.5",
    ],
    "zh": [
        "0", "0.01", "0.05", "0.5", "1", "3", "21", "101", "1000",
        "1234.56", "-3.5", "-0.5",
    ],
    "zh_TW": [
        "0", "0.01", "0.05", "0.5", "1", "3", "21", "101", "1000",
        "1234.56", "-3.5", "-0.5",
    ],
    "no": [
        "0", "0.01", "0.5", "1", "2", "21", "101", "1000",
        "1234.56", "-3.5", "-0.5",
    ],
    "da": [
        "0", "0.01", "0.5", "1", "2", "21", "101", "1000",
        "1234.56", "-3.5",
    ],
    "id": [
        "0", "0.01", "0.5", "1", "2", "21", "101", "1000",
        "1234.56", "-3.5",
    ],
    "fi": [
        "0", "0.01", "0.5", "1", "1.5", "2", "21", "101", "1000",
        "1234.56", "-3.5", "-0.5",
    ],
    "ro": CURRENCY_SAMPLES_FULL,
    "hu": CURRENCY_SAMPLES_FULL,
    "he": CURRENCY_SAMPLES_FULL,
    "eo": CURRENCY_SAMPLES_FULL,
    "fa": CURRENCY_SAMPLES_FULL,
    "cs": CURRENCY_SAMPLES_FULL,
    "sk": CURRENCY_SAMPLES_FULL,
    "sr": CURRENCY_SAMPLES_FULL,
    "lt": CURRENCY_SAMPLES_FULL,
}

OUT = "diff_fixtures_wbtest.mbt"

HEADER = '''// Generated by tools/gen_fixtures.py — do not edit by hand.
//
// Differential-test fixtures: expected values come from the upstream Python
// `num2words` library (LGPL-2.1, https://github.com/savoirfairelinux/num2words).
// Regenerate with `python tools/gen_fixtures.py` (requires `pip install num2words`).
//
// Comparison rules (see DIFF_REPORT.md):
//   * en/fr/es/de/ru: verbatim;
//   * it: accents are ignored (`tré` vs `tre`) — upstream is inconsistent
//     inside compounds, our output follows standard orthography; upstream's
//     `dicotto` typo for 118/218/... is normalised to `diciotto`;
//   * pt: compared against upstream `pt_BR`, ignoring commas — upstream
//     separates scale groups with a comma, ours follows Portuguese usage;
//   * zh: compared against upstream master's lang_ZH.py (0.5.14 has no
//     Chinese); `zh` is the Simplified variant of the same grammar and is
//     produced by character mapping, `zh_TW` is Traditional verbatim.
//
// Year mode is additionally compared for all languages that implement it
// upstream (en/fr/es/de/it/pt/pt_PT/ru/nl/tr/ja/ko/zh; Vietnamese has no
// `to_year`). Currency mode is compared for every language with the complete
// code set each upstream language implements (en: 20 codes; fr/de: 5;
// it/nl: 4; es: 171; ru: 8; pt: BRL only; pt_PT: 5; tr: TRY only; ja: JPY;
// ko: KRW/USD/JPY; zh/zh_TW: the 17 master codes incl. XXX). Upstream int
// inputs are avoided (they are read as cents), Turkish amounts must be free of
// float truncation, Japanese amounts must be integral, Korean KRW/JPY amounts
// must be free of cents, and Italian negative amounts are skipped (upstream
// raises AttributeError). Exact `x.xx5` amounts are excluded because this
// project rounds the exact decimal, upstream rounds a float. Upstream's
// Russian PLN typo "слотых" is normalised to "злотых"; pt commas are stripped.

'''


def normalize(lang: str, text: str) -> str:
    if lang == "it":
        return (text.replace("é", "e")
                    .replace("dicottesimo", "diciottesimo")
                    .replace("dicotto", "diciotto"))
    if lang in ("pt", "pt_PT"):
        return text.replace(",", "")
    if lang == "ru":
        # Upstream's PLN paucal form contains a typo ("слотых").
        return text.replace("слотых", "злотых")
    return text


def mbt_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main() -> None:
    blocks = [HEADER]
    counts = {}
    for upstream, ours in LANGS.items():
        # Upstream's Vietnamese negative handling is broken (-1 -> "mười chín",
        # smaller values raise IndexError); this project spells "âm ...".
        samples = SAMPLES if ours != "vi" else [n for n in SAMPLES if n >= 0]
        entries = []
        for n in samples:
            try:
                want = normalize(
                    ours, expected(ours, upstream, n, "cardinal")
                )
            except Exception:
                # Polish upstream raises on negative input; this port fixes it
                # and documents the deviation (see DIFF_REPORT.md).
                continue
            entries.append((str(n), want))
        counts[ours] = len(entries)
        blocks.append("///|\nlet diff_%s : Array[(String, String)] = [\n" % ours)
        for value, want in entries:
            blocks.append("  (%s, %s),\n" % (mbt_string(value), mbt_string(want)))
        blocks.append("]\n\n")

    blocks.append("///|\nfn diff_strip_accents(s : String) -> String {\n"
                  "  let flat = join_parts(s.split(\"é\").map(fn(w) { w.to_owned() }).collect(), \"e\")\n"
                  "  let step = join_parts(flat.split(\"dicottesimo\").map(fn(w) { w.to_owned() }).collect(), \"diciottesimo\")\n"
                  "  join_parts(step.split(\"dicotto\").map(fn(w) { w.to_owned() }).collect(), \"diciotto\")\n}\n\n")
    blocks.append("///|\nfn diff_strip_commas(s : String) -> String {\n"
                  "  join_parts(s.split(\",\").map(fn(w) { w.to_owned() }).collect(), \"\")\n}\n\n")

    normalize_call = {
        "it": "diff_strip_accents",
        "pt": "diff_strip_commas",
    }
    for _, ours in LANGS.items():
        blocks.append('///|\ntest "differential: %s matches upstream num2words" {\n' % ours)
        blocks.append("  for i = 0; i < diff_%s.length(); i = i + 1 {\n" % ours)
        blocks.append("    let (value, want) = diff_%s[i]\n" % ours)
        if ours in normalize_call:
            actual = "%s(num2words_str(value, \"%s\", \"cardinal\"))" % (normalize_call[ours], ours)
        else:
            actual = 'num2words_str(value, "%s", "cardinal")' % ours
        blocks.append("    assert_eq(%s, want)\n" % actual)
        blocks.append("  }\n}\n\n")

    year_counts = {}
    for upstream, ours in YEAR_LANGS.items():
        samples = YEAR_SAMPLES + (
            YEAR_BC_SAMPLES if ours in YEAR_BC_LANGS.values() else []
        )
        entries = []
        for y in samples:
            try:
                want = normalize(ours, expected(ours, upstream, y, "year"))
            except Exception:
                # Japanese rejects years before 645 (era calendar).
                continue
            entries.append((str(y), want))
        year_counts[ours] = len(entries)
        blocks.append("///|\nlet diff_year_%s : Array[(String, String)] = [\n" % ours)
        for value, want in entries:
            blocks.append("  (%s, %s),\n" % (mbt_string(value), mbt_string(want)))
        blocks.append("]\n\n")

    for ours in YEAR_LANGS.values():
        blocks.append('///|\ntest "differential: %s year matches upstream num2words" {\n' % ours)
        blocks.append("  for i = 0; i < diff_year_%s.length(); i = i + 1 {\n" % ours)
        blocks.append("    let (value, want) = diff_year_%s[i]\n" % ours)
        if ours in normalize_call:
            actual = "%s(num2words_str(value, \"%s\", \"year\"))" % (normalize_call[ours], ours)
        else:
            actual = 'num2words_str(value, "%s", "year")' % ours
        blocks.append("    assert_eq(%s, want)\n" % actual)
        blocks.append("  }\n}\n\n")

    ord_counts = {}
    ordnum_counts = {}
    for upstream, ours in LANGS.items():
        ord_entries = []
        for n in ORD_SAMPLES:
            try:
                want = normalize(ours, expected(ours, upstream, n, "ordinal"))
            except Exception:
                continue
            ord_entries.append((str(n), want))
        ordnum_entries = []
        for n in ORDNUM_SAMPLES:
            try:
                # it/ru ordinal_num returns the int itself upstream; str() it.
                want = normalize(
                    ours, str(expected(ours, upstream, n, "ordinal_num"))
                )
            except Exception:
                continue
            ordnum_entries.append((str(n), want))
        ord_counts[ours] = len(ord_entries)
        ordnum_counts[ours] = len(ordnum_entries)
        blocks.append("///|\nlet diff_ord_%s : Array[(String, String)] = [\n" % ours)
        for value, want in ord_entries:
            blocks.append("  (%s, %s),\n" % (mbt_string(value), mbt_string(want)))
        blocks.append("]\n\n")
        blocks.append("///|\nlet diff_ordnum_%s : Array[(String, String)] = [\n" % ours)
        for value, want in ordnum_entries:
            blocks.append("  (%s, %s),\n" % (mbt_string(value), mbt_string(want)))
        blocks.append("]\n\n")

    for ours in LANGS.values():
        blocks.append('///|\ntest "differential: %s ordinal matches upstream num2words" {\n' % ours)
        blocks.append("  for i = 0; i < diff_ord_%s.length(); i = i + 1 {\n" % ours)
        blocks.append("    let (value, want) = diff_ord_%s[i]\n" % ours)
        if ours in normalize_call:
            actual = "%s(num2words_str(value, \"%s\", \"ordinal\"))" % (normalize_call[ours], ours)
        else:
            actual = 'num2words_str(value, "%s", "ordinal")' % ours
        blocks.append("    assert_eq(%s, want)\n" % actual)
        blocks.append("  }\n}\n\n")
        blocks.append('///|\ntest "differential: %s ordinal_num matches upstream num2words" {\n' % ours)
        blocks.append("  for i = 0; i < diff_ordnum_%s.length(); i = i + 1 {\n" % ours)
        blocks.append("    let (value, want) = diff_ordnum_%s[i]\n" % ours)
        if ours in normalize_call:
            actual = "%s(num2words_str(value, \"%s\", \"ordinal_num\"))" % (normalize_call[ours], ours)
        else:
            actual = 'num2words_str(value, "%s", "ordinal_num")' % ours
        blocks.append("    assert_eq(%s, want)\n" % actual)
        blocks.append("  }\n}\n\n")

    currency_counts = {}
    for upstream, ours in CURRENCY_LANGS.items():
        entries = []
        for code in CURRENCY_CODES[upstream]:
            for amount in CURRENCY_SAMPLES[upstream]:
                try:
                    want = normalize(
                        ours, expected_currency(ours, upstream, amount, code)
                    )
                except Exception:
                    continue
                entries.append((amount, code, want))
        currency_counts[ours] = len(entries)
        blocks.append(
            "///|\nlet diff_currency_%s : Array[(String, String, String)] = [\n" % ours
        )
        for amount, code, want in entries:
            blocks.append(
                "  (%s, %s, %s),\n"
                % (mbt_string(amount), mbt_string(code), mbt_string(want))
            )
        blocks.append("]\n\n")

    blocks.append(
        "///|\nfn diff_currency_ok(r : Result[String, String]) -> String {\n"
        "  match r {\n"
        "    Ok(s) => s\n"
        '    Err(e) => "ERR: " + e\n'
        "  }\n}\n\n"
    )
    for ours in CURRENCY_LANGS.values():
        blocks.append('///|\ntest "differential: %s currency matches upstream num2words" {\n' % ours)
        blocks.append("  for i = 0; i < diff_currency_%s.length(); i = i + 1 {\n" % ours)
        blocks.append("    let (amount, code, want) = diff_currency_%s[i]\n" % ours)
        blocks.append(
            '    assert_eq(diff_currency_ok(num2words_currency(amount, "%s", code)), want)\n'
            % ours
        )
        blocks.append("  }\n}\n\n")

    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("".join(blocks))
    print("wrote %s: cardinal %s; year %s; ordinal %s; ordinal_num %s; currency %s" % (
        OUT,
        ", ".join("%s=%d" % kv for kv in counts.items()),
        ", ".join("%s=%d" % kv for kv in year_counts.items()),
        ", ".join("%s=%d" % kv for kv in ord_counts.items()),
        ", ".join("%s=%d" % kv for kv in ordnum_counts.items()),
        ", ".join("%s=%d" % kv for kv in currency_counts.items()),
    ))


if __name__ == "__main__":
    main()
