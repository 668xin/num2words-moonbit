// lang_ordinal.mbt — ordinal ("second") and ordinal_num ("2nd") for the six
// non-English languages, ported to match upstream num2words 0.5.14 output
// exactly (including its quirks; see DIFF_REPORT.md).
//
// Upstream raises TypeError for negative ordinals in every language except
// Italian (which prefixes "meno "). Our string API has no exceptions, so the
// negative case returns "" for those languages instead of crashing.

// --- shared helpers ---------------------------------------------------------

///|
/// True when `s` ends with the exact code-unit suffix `suf`.
fn ends_with(s : String, suf : String) -> Bool {
  if s.length() < suf.length() {
    return false
  }
  s[s.length() - suf.length():s.length()].to_owned() == suf
}

///|
/// Drop the last code unit of `s` (all ordinals touched here are BMP-only).
fn drop_last_char(s : String) -> String {
  s[0:s.length() - 1].to_owned()
}

///|
/// Trim leading/trailing spaces (upstream calls Python's `str.strip()`).
fn trim_spaces(s : String) -> String {
  let mut a = 0
  let mut b = s.length()
  while a < b && s[a:a + 1].to_owned() == " " {
    a = a + 1
  }
  while b > a && s[b - 1:b].to_owned() == " " {
    b = b - 1
  }
  s[a:b].to_owned()
}

///|
/// Lowercase ASCII letters only (German umlauts are already lowercase in the
/// cardinal tables; only scale words start uppercase).
fn lower_ascii(s : String) -> String {
  let buf = StringBuilder()
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c >= 65 && c <= 90 {
      buf.write_char((c + 32).to_char().unwrap())
    } else {
      buf.write_char(c.to_char().unwrap())
    }
  }
  buf.to_string()
}

// --- French -----------------------------------------------------------------
//
// Upstream: 1 -> "premier"; otherwise take the cardinal, replace a trailing
// "cinq"/"neuf", else drop a trailing "e" and append "ième".
// ordinal_num: "1er", everything else "<n>me".

///|
pub fn ordinal_fr(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  if n == BigInt::from_int(1) {
    return "premier"
  }
  let mut word = lang_fr().cardinal_fr(n)
  if ends_with(word, "cinq") {
    word = word[0:word.length() - 4].to_owned() + "cinquième"
  } else if ends_with(word, "neuf") {
    word = word[0:word.length() - 4].to_owned() + "neuvième"
  } else {
    if ends_with(word, "e") {
      word = drop_last_char(word)
    }
    word = word + "ième"
  }
  word
}

///|
pub fn ordinal_num_fr(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  if n == BigInt::from_int(1) {
    "1er"
  } else {
    n.to_string() + "me"
  }
}

// --- German -----------------------------------------------------------------
//
// Upstream: lowercase the cardinal, apply the first matching suffix rewrite,
// append "te", then fix up "eintausendste"/"einhundertste" and million words.

///|
fn de_ord_rewrite(word : String) -> String {
  // Insertion-ordered, first match wins (Python dict semantics).
  if ends_with(word, "eins") {
    return word[0:word.length() - 4].to_owned() + "ers"
  }
  if ends_with(word, "drei") {
    return word[0:word.length() - 4].to_owned() + "drit"
  }
  if ends_with(word, "acht") {
    return word[0:word.length() - 4].to_owned() + "ach"
  }
  if ends_with(word, "sieben") {
    return word[0:word.length() - 6].to_owned() + "sieb"
  }
  if ends_with(word, "ig") {
    return word[0:word.length() - 2].to_owned() + "igs"
  }
  if ends_with(word, "ert") {
    return word[0:word.length() - 3].to_owned() + "erts"
  }
  if ends_with(word, "end") {
    return word[0:word.length() - 3].to_owned() + "ends"
  }
  if ends_with(word, "ion") {
    return word[0:word.length() - 3].to_owned() + "ions"
  }
  if ends_with(word, "nen") {
    return word[0:word.length() - 3].to_owned() + "ns"
  }
  if ends_with(word, "rde") {
    return word[0:word.length() - 3].to_owned() + "rds"
  }
  if ends_with(word, "rden") {
    return word[0:word.length() - 4].to_owned() + "rds"
  }
  word
}

///|
pub fn ordinal_de(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  let word = de_ord_rewrite(lower_ascii(lang_de().cardinal_de(n)))
  let mut res = word + "te"
  // "tausendste"/"hundertste" are preferred over "eintausendste"/...
  if res == "eintausendste" || res == "einhundertste" {
    res = res[3:res.length()].to_owned()
  }
  // Ordinals on -illion/-illiarde words: no "eine"/space before them.
  if ends_with(res, "illionste") || ends_with(res, "illiardste") {
    if res.length() > 5 && res[0:5].to_owned() == "eine " {
      res = res[5:res.length()].to_owned()
    } else {
      // Remove the space directly before the final million word.
      let mut sp = res.length() - 1
      while sp >= 0 && res[sp:sp + 1].to_owned() != " " {
        sp = sp - 1
      }
      if sp > 0 {
        res = res[0:sp].to_owned() + res[sp + 1:res.length()].to_owned()
      }
    }
  }
  res
}

///|
pub fn ordinal_num_de(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    ""
  } else {
    n.to_string() + "."
  }
}

// --- Italian ----------------------------------------------------------------
//
// Upstream: <20 uses a word table; compounds ending in 3 drop the accent and
// take "eesimo", ending in 6 take "esimo", everything else drops the final
// vowel ("mil" gains an extra "l"). Negatives are supported ("meno terzo").
// ordinal_num falls through to upstream's plain str(value).

///|
let it_ordinal_words : Array[String] = [
  "zero", "primo", "secondo", "terzo", "quarto", "quinto", "sesto", "settimo", "ottavo",
  "nono", "decimo", "undicesimo", "dodicesimo", "tredicesimo", "quattordicesimo",
  "quindicesimo", "sedicesimo", "diciassettesimo", "diciottesimo", "diciannovesimo",
]

///|
pub fn ordinal_it(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return "meno " + ordinal_it(-n)
  }
  let hundred = BigInt::from_int(100)
  let tens = n % hundred
  let ten = BigInt::from_int(10)
  let twenty = BigInt::from_int(20)
  let is_outside_teens = !(ten < tens && tens < twenty)
  if n < twenty {
    return it_ordinal_words[n.to_int()]
  }
  let three = BigInt::from_int(3)
  let six = BigInt::from_int(6)
  if is_outside_teens && tens % ten == three {
    // tens % 10 == 3: drop the accented final vowel, add "eesimo".
    return drop_last_char(lang_it().cardinal_it(n)) + "eesimo"
  }
  if is_outside_teens && tens % ten == six {
    return lang_it().cardinal_it(n) + "esimo"
  }
  let mut string = drop_last_char(lang_it().cardinal_it(n))
  if ends_with(string, "mil") {
    string = string + "l"
  }
  string + "esimo"
}

///|
pub fn ordinal_num_it(n : BigInt) -> String {
  n.to_string()
}

// --- Spanish ----------------------------------------------------------------
//
// Faithful port of upstream's recursion, quirks included:
//   * 0 -> "" (empty string),
//   * 11/12 concatenate without a space ("décimoprimero"),
//   * >= 10^18 falls back to the cardinal.
// ordinal_num: "<n>º".

///|
fn es_ord_stem_small(v : Int) -> String {
  match v {
    1 => "primer"
    2 => "segund"
    3 => "tercer"
    4 => "cuart"
    5 => "quint"
    6 => "sext"
    7 => "séptim"
    8 => "octav"
    9 => "noven"
    _ => "décim"
  }
}

///|
fn es_ord_stem_tens(d : Int) -> String {
  match d {
    2 => "vigésim"
    3 => "trigésim"
    4 => "quadragésim"
    5 => "quincuagésim"
    6 => "sexagésim"
    7 => "septuagésim"
    8 => "octogésim"
    _ => "nonagésim"
  }
}

///|
fn es_ord_stem_hundreds(d : Int) -> String {
  match d {
    1 => "centésim"
    2 => "ducentésim"
    3 => "tricentésim"
    4 => "cuadrigentésim"
    5 => "quingentésim"
    6 => "sexcentésim"
    7 => "septigentésim"
    8 => "octigentésim"
    _ => "noningentésim"
  }
}

///|
/// Scale stems for 10^(3k), k = 1..5 (1e3 .. 1e15).
fn es_ord_stem_scale(k : Int) -> String {
  match k {
    1 => "milésim"
    2 => "millonésim"
    3 => "billonésim"
    4 => "trillonésim"
    _ => "cuadrillonésim"
  }
}

///|
fn es_ord_rec(v : BigInt) -> String {
  let b0 = BigInt::from_int(0)
  let b10 = BigInt::from_int(10)
  let b12 = BigInt::from_int(12)
  let b100 = BigInt::from_int(100)
  let b1000 = BigInt::from_int(1000)
  let raw = if v == b0 {
    ""
  } else if v <= b10 {
    es_ord_stem_small(v.to_int()) + "o"
  } else if v <= b12 {
    // Upstream has no space here: "décimoprimero".
    "décimo" + es_ord_rec(v - b10)
  } else if v <= b100 {
    let dec = v / b10 * b10
    let stem = if dec == b10 {
      "décim"
    } else if dec == b100 {
      "centésim"
    } else {
      es_ord_stem_tens((dec / b10).to_int())
    }
    stem + "o" + " " + es_ord_rec(v - dec)
  } else if v <= b1000 {
    let cen = v / b100 * b100
    let stem = if cen == b1000 {
      "milésim"
    } else {
      es_ord_stem_hundreds((cen / b100).to_int())
    }
    stem + "o" + " " + es_ord_rec(v - cen)
  } else if v < BigInt::from_string("1000000000000000000") {
    // Largest 1000^k <= v, k capped at 5 (1e15).
    let mut dec = b1000
    let mut k = 1
    while k < 5 && v >= dec * b1000 {
      dec = dec * b1000
      k = k + 1
    }
    let high = v / dec
    let low = v % dec
    let card = if high == BigInt::from_int(1) {
      ""
    } else {
      lang_es().cardinal_es(high)
    }
    card + es_ord_stem_scale(k) + "o" + " " + es_ord_rec(low)
  } else {
    // >= 1e18: upstream falls back to the cardinal.
    lang_es().cardinal_es(v)
  }
  trim_spaces(raw)
}

///|
pub fn ordinal_es(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  es_ord_rec(n)
}

///|
pub fn ordinal_num_es(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    ""
  } else {
    n.to_string() + "º"
  }
}

// --- Portuguese (pt_BR / pt_PT share ordinals) ------------------------------
//
// Upstream walks the decimal digits right-to-left, appending per-position
// ordinal words and scale separators, then collapses whitespace and drops a
// leading "primeiro " (the "primeiro milésimo" quirk). 0 -> "". Digits at
// position >= 18 have no separator table upstream (it would raise), so we
// return "".

///|
fn pt_ord_digit(pos : Int, d : Int) -> String {
  match pos {
    0 =>
      match d {
        1 => "primeiro"
        2 => "segundo"
        3 => "terceiro"
        4 => "quarto"
        5 => "quinto"
        6 => "sexto"
        7 => "sétimo"
        8 => "oitavo"
        9 => "nono"
        _ => ""
      }
    1 =>
      match d {
        1 => "décimo"
        2 => "vigésimo"
        3 => "trigésimo"
        4 => "quadragésimo"
        5 => "quinquagésimo"
        6 => "sexagésimo"
        7 => "septuagésimo"
        8 => "octogésimo"
        9 => "nonagésimo"
        _ => ""
      }
    _ =>
      match d {
        1 => "centésimo"
        2 => "ducentésimo"
        3 => "tricentésimo"
        4 => "quadrigentésimo"
        5 => "quingentésimo"
        6 => "seiscentésimo"
        7 => "septigentésimo"
        8 => "octigentésimo"
        9 => "nongentésimo"
        _ => ""
      }
  }
}

///|
fn pt_thousand_separator(idx : Int) -> String {
  match idx {
    3 => "milésimo"
    6 => "milionésimo"
    9 => "bilionésimo"
    12 => "trilionésimo"
    15 => "quadrilionésimo"
    _ => ""
  }
}

///|
pub fn ordinal_pt(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  let digits = n.to_string()
  let result : Array[String] = []
  let mut separator = ""
  let mut idx = 0
  let mut i = digits.length() - 1
  while i >= 0 {
    let d = digits[i].to_int() - 48
    if idx > 0 && idx % 3 == 0 {
      if idx > 15 {
        // Upstream would raise KeyError; treat as unsupported.
        return ""
      }
      separator = pt_thousand_separator(idx)
    }
    if d != 0 && separator != "" {
      result.push(separator)
      separator = ""
    }
    result.push(pt_ord_digit(idx % 3, d))
    idx = idx + 1
    i = i - 1
  }
  let rev : Array[String] = []
  for j = 0; j < result.length(); j = j + 1 {
    rev.push(result[result.length() - 1 - j])
  }
  let parts : Array[String] = []
  for j = 0; j < rev.length(); j = j + 1 {
    if rev[j] != "" {
      parts.push(rev[j])
    }
  }
  let mut out = join_parts(parts, " ")
  if parts.length() > 0 && parts[0] == "primeiro" && digits != "1" {
    out = out[9:out.length()].to_owned()
  }
  out
}

///|
pub fn ordinal_num_pt(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    ""
  } else {
    n.to_string() + "º"
  }
}

// --- Russian ----------------------------------------------------------------
//
// Port of upstream lang_RU._int2word(cardinal=False) with the default
// grammar (nominative, singular, masculine, animate). Two modes:
//
//   * normal chunk: hundreds/tens/ones ordinalised only when they are the
//     last spoken part, otherwise cardinal; scale words stay nominative;
//   * fused chunk (when the number ends in 000): the whole group is written
//     with genitive forms and glued to the scale ordinal into ONE word
//     ("двухтысячный", "двадцатиоднотысячный").

///|
fn ru_ones_n(o : Int) -> String {
  match o {
    1 => "один"
    2 => "два"
    3 => "три"
    4 => "четыре"
    5 => "пять"
    6 => "шесть"
    7 => "семь"
    8 => "восемь"
    _ => "девять"
  }
}

///|
fn ru_ones_f(o : Int) -> String {
  match o {
    1 => "одна"
    2 => "две"
    3 => "три"
    4 => "четыре"
    5 => "пять"
    6 => "шесть"
    7 => "семь"
    8 => "восемь"
    _ => "девять"
  }
}

///|
fn ru_ones_g(o : Int) -> String {
  match o {
    1 => "одного"
    2 => "двух"
    3 => "трёх"
    4 => "четырёх"
    5 => "пяти"
    6 => "шести"
    7 => "семи"
    8 => "восьми"
    _ => "девяти"
  }
}

///|
fn ru_ones_ord(o : Int) -> String {
  match o {
    0 => "нулевой"
    1 => "первый"
    2 => "второй"
    3 => "третий"
    4 => "четвёртый"
    5 => "пятый"
    6 => "шестой"
    7 => "седьмой"
    8 => "восьмой"
    _ => "девятый"
  }
}

///|
fn ru_tens_g(o : Int) -> String {
  match o {
    0 => "десяти"
    1 => "одиннадцати"
    2 => "двенадцати"
    3 => "тринадцати"
    4 => "четырнадцати"
    5 => "пятнадцати"
    6 => "шестнадцати"
    7 => "семнадцати"
    8 => "восемнадцати"
    _ => "девятнадцати"
  }
}

///|
fn ru_tens_ord(o : Int) -> String {
  match o {
    0 => "десятый"
    1 => "одиннадцатый"
    2 => "двенадцатый"
    3 => "тринадцатый"
    4 => "четырнадцатый"
    5 => "пятнадцатый"
    6 => "шестнадцатый"
    7 => "семнадцатый"
    8 => "восемнадцатый"
    _ => "девятнадцатый"
  }
}

///|
fn ru_twenties_n(t : Int) -> String {
  match t {
    2 => "двадцать"
    3 => "тридцать"
    4 => "сорок"
    5 => "пятьдесят"
    6 => "шестьдесят"
    7 => "семьдесят"
    8 => "восемьдесят"
    _ => "девяносто"
  }
}

///|
fn ru_twenties_g(t : Int) -> String {
  match t {
    2 => "двадцати"
    3 => "тридцати"
    4 => "сорока"
    5 => "пятидесяти"
    6 => "шестидесяти"
    7 => "семидесяти"
    8 => "восьмидесяти"
    _ => "девяноста"
  }
}

///|
fn ru_twenties_ord(t : Int) -> String {
  match t {
    2 => "двадцатый"
    3 => "тридцатый"
    4 => "сороковой"
    5 => "пятидесятый"
    6 => "шестидесятый"
    7 => "семидесятый"
    8 => "восьмидесятый"
    _ => "девяностый"
  }
}

///|
fn ru_hundreds_n(h : Int) -> String {
  match h {
    1 => "сто"
    2 => "двести"
    3 => "триста"
    4 => "четыреста"
    5 => "пятьсот"
    6 => "шестьсот"
    7 => "семьсот"
    8 => "восемьсот"
    _ => "девятьсот"
  }
}

///|
fn ru_hundreds_g(h : Int) -> String {
  match h {
    1 => "сто"
    2 => "двухсот"
    3 => "трёхсот"
    4 => "четырёхсот"
    5 => "пятисот"
    6 => "шестисот"
    7 => "семисот"
    8 => "восьмисот"
    _ => "девятисот"
  }
}

///|
fn ru_hundreds_ord(h : Int) -> String {
  match h {
    1 => "сотый"
    2 => "двухсотый"
    3 => "трёхсотый"
    4 => "четырёхсотый"
    5 => "пятисотый"
    6 => "шестисотый"
    7 => "семисотый"
    8 => "восьмисотый"
    _ => "девятисотый"
  }
}

///|
fn ru_thousands_ord(i : Int) -> String {
  match i {
    1 => "тысячный"
    2 => "миллионный"
    3 => "миллиардный"
    4 => "триллионный"
    5 => "квадриллионный"
    6 => "квинтиллионный"
    7 => "секстиллионный"
    8 => "септиллионный"
    9 => "октиллионный"
    _ => "нониллионный"
  }
}

///|
fn ru_chunk_ordinal(
  h : Int,
  t : Int,
  o : Int,
  chunk_num : Int,
) -> Array[String] {
  let words : Array[String] = []
  if h > 0 {
    if t == 0 && o == 0 {
      words.push(ru_hundreds_ord(h))
    } else {
      words.push(ru_hundreds_n(h))
    }
  }
  if t > 1 {
    if o == 0 {
      words.push(ru_twenties_ord(t))
    } else {
      words.push(ru_twenties_n(t))
    }
  }
  if t == 1 {
    words.push(ru_tens_ord(o))
  } else if o > 0 {
    if chunk_num == 0 {
      words.push(ru_ones_ord(o))
    } else if chunk_num > 0 && o == 1 && h == 0 && t == 0 {
      // "тысяча первый": the "одна" disappears.
    } else if chunk_num == 1 {
      // Thousands are feminine.
      words.push(ru_ones_f(o))
    } else {
      words.push(ru_ones_n(o))
    }
  }
  words
}

///|
fn ru_chunk_ordinal_join(
  h : Int,
  t : Int,
  o : Int,
  chunk_num : Int,
) -> Array[String] {
  let words : Array[String] = []
  if h > 1 {
    words.push(ru_hundreds_g(h))
  } else if h == 1 {
    // "сто", not "ста".
    words.push("сто")
  }
  if t == 9 {
    // "девяносто", not "девяноста".
    words.push("девяносто")
  } else if t > 1 {
    words.push(ru_twenties_g(t))
  }
  if t == 1 {
    words.push(ru_tens_g(o))
  } else if o > 0 {
    if chunk_num == 0 {
      words.push(ru_ones_ord(o))
    } else if chunk_num > 0 && o == 1 && t != 1 {
      if t == 0 && h == 0 {
        // "тысячный", "миллионный": the "один" disappears.
      } else {
        words.push("одно")
      }
    } else {
      words.push(ru_ones_g(o))
    }
  }
  words
}

///|
pub fn ordinal_ru(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  if n == BigInt::from_int(0) {
    return "нулевой"
  }
  // Split into groups of 3 from the right (most significant first).
  let rev_chunks : Array[Int] = []
  let b1000 = BigInt::from_int(1000)
  let mut v = n
  while v > BigInt::from_int(0) {
    rev_chunks.push((v % b1000).to_int())
    v = v / b1000
  }
  let chunks : Array[Int] = []
  for idx = 0; idx < rev_chunks.length(); idx = idx + 1 {
    chunks.push(rev_chunks[rev_chunks.length() - 1 - idx])
  }
  let count = chunks.length()
  // Upstream's scale tables stop at 10^30; beyond that the ordinal would
  // raise, so we report "".
  if count - 1 > 10 {
    return ""
  }
  let ord_join = chunks[count - 1] == 0
  let mut max_nonzero = 0
  for i = 0; i < count; i = i + 1 {
    if chunks[i] != 0 {
      max_nonzero = i
    }
  }
  let rightest_nonzero_i = count - 1 - max_nonzero
  let words : Array[String] = []
  for idx = 0; idx < count; idx = idx + 1 {
    let x = chunks[idx]
    let i = count - 1 - idx
    if x == 0 {
      continue
    }
    let h = x / 100
    let t = x / 10 % 10
    let o = x % 10
    if !(ord_join && rightest_nonzero_i == i) {
      let chunk_words = ru_chunk_ordinal(h, t, o, i)
      for w in chunk_words {
        words.push(w)
      }
      if i > 0 {
        words.push(ru_scale(i, ru_form(x)))
      }
    } else {
      let chunk_words = ru_chunk_ordinal_join(h, t, o, i)
      let mut joined = ""
      for w in chunk_words {
        joined = joined + w
      }
      if i > 0 {
        joined = joined + ru_thousands_ord(i)
      }
      words.push(joined)
    }
  }
  join_parts(words, " ")
}

///|
pub fn ordinal_num_ru(n : BigInt) -> String {
  n.to_string()
}
