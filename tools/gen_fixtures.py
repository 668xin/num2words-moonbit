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
"""

import sys

try:
    from num2words import num2words
    from num2words import lang_ES
except ImportError:
    sys.exit("num2words is not installed: pip install num2words")

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
}

YEAR_SAMPLES = [
    1000, 1001, 1010, 1100, 1500, 1900, 1984, 1999, 2000, 2001, 2009,
    2010, 2023, 2024, 2100, 2134, 3000, 3001, 9999,
]

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
//     separates scale groups with a comma, ours follows Portuguese usage.
//
// Year mode is additionally compared for all languages that implement it
// upstream (en/fr/es/de/it/pt/pt_PT/ru/nl/tr; Vietnamese has no `to_year`).
// Currency mode is compared for every language with the code set each
// upstream language implements (en/fr/de/it: EUR/USD/GBP; es: 20 codes;
// ru: 6 codes; pt: BRL only; nl: 4 codes; tr: TRY only). Upstream int inputs
// are avoided (they are read as cents), Turkish amounts must be free of
// float truncation, and Italian negative amounts are skipped (upstream raises
// AttributeError). Exact `x.xx5` amounts are excluded because this project
// rounds the exact decimal, upstream rounds a float. Upstream's Russian PLN
// typo "слотых" is normalised to "злотых"; pt commas are stripped.

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
        entries = [
            (str(n), normalize(ours, num2words(n, lang=upstream)))
            for n in samples
        ]
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
        entries = [
            (str(y), normalize(ours, num2words(y, lang=upstream, to="year")))
            for y in YEAR_SAMPLES
        ]
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
                want = normalize(ours, num2words(n, lang=upstream, to="ordinal"))
            except Exception:
                continue
            ord_entries.append((str(n), want))
        ordnum_entries = []
        for n in ORDNUM_SAMPLES:
            try:
                # it/ru ordinal_num returns the int itself upstream; str() it.
                want = normalize(ours, str(num2words(n, lang=upstream, to="ordinal_num")))
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
                    # pt_BR's and tr's to_currency take no currency code.
                    if upstream in ("pt_BR", "tr"):
                        raw = num2words(
                            float(amount), lang=upstream, to="currency"
                        )
                    else:
                        raw = num2words(
                            float(amount), lang=upstream, to="currency", currency=code
                        )
                    want = normalize(ours, raw)
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
