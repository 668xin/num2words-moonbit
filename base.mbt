// base.mbt — core engine for num2words-moonbit
//
// An independent reimplementation in MoonBit of the ideas behind the Python
// `num2words` library (https://github.com/savoirfairelinux/num2words, LGPL-2.1).
// It spells integers / years / ordinals / currency amounts in multiple
// languages. The upstream project is acknowledged in README.md.
//
// Design:
//   - `BigInt` is used throughout so arbitrarily large integers are supported.
//   - Each language is described by a `Lang` value (word tables + a `Variant`
//     tag). The heavy lifting (splitting into 3-digit groups) is shared; the
//     per-language quirks live in the cardinal_* helpers.

pub enum Variant {
  En
  Fr
  Es
  De
  It
  Pt
}

/// Word tables + behaviour flags for one language.
pub struct Lang {
  variant : Variant
  zero : String
  ones : Array[String] // 0..9
  teens : Array[String] // 10..19  (index = value - 10)
  tens : Array[String] // 10,20,..90 (index = d)
  hundred : String // prefix base, e.g. "hundred" / "cent" / "hundert"
  thousands : Array[String] // index = group power: 1->"thousand", 2->"million"...
  negative : String
  decimal : String
  comma_sep : Bool
}

/// Split `n` (>0) into 3-digit groups from low to high, return high-to-low.
pub fn group3(n : BigInt) -> Array[(BigInt, Int)] {
  let low : Array[(BigInt, Int)] = []
  let mut x = n
  let mut power = 0
  while x != BigInt::from_int(0) {
    low.push((x % BigInt::from_int(1000), power))
    x = x / BigInt::from_int(1000)
    power = power + 1
  }
  let res : Array[(BigInt, Int)] = []
  for i = low.length() - 1; i >= 0; i = i - 1 {
    res.push(low[i])
  }
  res
}

fn join_parts(arr : Array[String], sep : String) -> String {
  let mut s = ""
  for i = 0; i < arr.length(); i = i + 1 {
    if i > 0 {
      s = s + sep
    }
    s = s + arr[i]
  }
  s
}

fn split_to_array(s : String, sep : String) -> Array[String] {
  s.split(sep).map(fn (w) { w.to_owned() }).collect()
}

fn split_hyphen(word : String) -> (String, String) {
  let n = word.length()
  for i = 0; i < n; i = i + 1 {
    if word[i : i + 1].to_owned() == "-" {
      return (word[0:i].to_owned(), word[i + 1 : n].to_owned())
    }
  }
  (word, "")
}

// =====================================================================
// English
// =====================================================================

pub fn lang_en() -> Lang {
  {
    variant: En,
    zero: "zero",
    ones: [
      "zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
      "nine",
    ],
    teens: [
      "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
      "seventeen", "eighteen", "nineteen",
    ],
    tens: [
      "", "ten", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
      "eighty", "ninety",
    ],
    hundred: "hundred",
    thousands: [
      "", "thousand", "million", "billion", "trillion", "quadrillion",
      "quintillion", "sextillion", "septillion", "octillion", "nonillion",
      "decillion",
    ],
    negative: "minus",
    decimal: "point",
    comma_sep: true,
  }
}

fn Lang::below100_en(self : Lang, r : Int) -> String {
  if r < 10 {
    return self.ones[r]
  }
  if r < 20 {
    return self.teens[r - 10]
  }
  let d = r / 10
  let u = r % 10
  if u == 0 {
    return self.tens[d]
  }
  self.tens[d] + "-" + self.ones[u]
}

fn Lang::triple_en(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_en(r)
  }
  let hs = (if h == 1 { "one" } else { self.ones[h] }) + " " + self.hundred
  if r == 0 {
    return hs
  }
  hs + " and " + self.below100_en(r)
}

fn Lang::cardinal_en(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  let groups = group3(n)
  let parts : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    let mut s = self.triple_en(t)
    if power > 0 {
      s = s + " " + self.thousands[power]
    }
    parts.push(s)
  }
  let joined = join_parts(parts, ", ")
  if neg {
    self.negative + " " + joined
  } else {
    joined
  }
}

// ---------------------------------------------------------------------
// English ordinal ("first", "second", ...)
// ---------------------------------------------------------------------

pub fn ordinal_en(n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return "zeroth"
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  let card = lang_en().cardinal_en(n)
  let words = split_to_array(card, " ")
  let last_idx = words.length() - 1
  words[last_idx] = ordinalize(words[last_idx])
  let joined = join_parts(words, " ")
  if neg {
    "minus " + joined
  } else {
    joined
  }
}

fn ordinalize(word : String) -> String {
  let (left, right) = split_hyphen(word)
  if right == "" {
    ordinalize_simple(word)
  } else {
    left + "-" + ordinalize_simple(right)
  }
}

fn ordinalize_simple(w : String) -> String {
  match w {
    "one" => "first"
    "two" => "second"
    "three" => "third"
    "five" => "fifth"
    "eight" => "eighth"
    "nine" => "ninth"
    "twelve" => "twelfth"
    "twenty" => "twentieth"
    "thirty" => "thirtieth"
    "forty" => "fortieth"
    "fifty" => "fiftieth"
    "sixty" => "sixtieth"
    "seventy" => "seventieth"
    "eighty" => "eightieth"
    "ninety" => "ninetieth"
    "hundred" => "hundredth"
    "thousand" => "thousandth"
    "million" => "millionth"
    "billion" => "billionth"
    "trillion" => "trillionth"
    "quadrillion" => "quadrillionth"
    "quintillion" => "quintillionth"
    "sextillion" => "sextillionth"
    "septillion" => "septillionth"
    "octillion" => "octillionth"
    "nonillion" => "nonillionth"
    "decillion" => "decillionth"
    _ => w + "th"
  }
}

/// Ordinal number with numeric suffix: 1 -> "1st", 2 -> "2nd", 12 -> "12th".
pub fn ordinal_num_en(n : BigInt) -> String {
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  let s = n.to_string()
  let last = if s.length() >= 2 { s[s.length() - 2 : s.length()].to_owned() } else { s }
  let suffix = if last == "11" || last == "12" || last == "13" {
    "th"
  } else {
    match s[s.length() - 1 : s.length()].to_owned() {
      "1" => "st"
      "2" => "nd"
      "3" => "rd"
      _ => "th"
    }
  }
  let base = n.to_string() + suffix
  if neg {
    "minus " + base
  } else {
    base
  }
}

// ---------------------------------------------------------------------
// English year ("2024" -> "twenty twenty-four")
// ---------------------------------------------------------------------

pub fn year_en(n : BigInt) -> String {
  if n < BigInt::from_int(1000) || n > BigInt::from_int(9999) {
    return lang_en().cardinal_en(n)
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  if n % BigInt::from_int(1000) == BigInt::from_int(0) {
    // 2000 -> "two thousand"
    return lang_en().cardinal_en(n)
  }
  let s = n.to_string()
  let first = BigInt::from_string(s[0:2].to_owned()).to_int()
  let second = BigInt::from_string(s[2:4].to_owned()).to_int()
  if second == 0 {
    // 1900 -> "nineteen hundred"
    return lang_en().cardinal_en(BigInt::from_int(first)) + " hundred"
  }
  let a = lang_en().cardinal_en(BigInt::from_int(first))
  let b = lang_en().cardinal_en(BigInt::from_int(second))
  if neg {
    "minus " + a + " " + b
  } else {
    a + " " + b
  }
}

// ---------------------------------------------------------------------
// English currency ($1234.56 -> "one thousand two hundred thirty-four
// dollars and fifty-six cents")
// ---------------------------------------------------------------------

pub fn currency_en(dollars : BigInt, cents : BigInt) -> String {
  if dollars == BigInt::from_int(0) && cents == BigInt::from_int(0) {
    return "zero dollars"
  }
  let neg = dollars < BigInt::from_int(0) || cents < BigInt::from_int(0)
  let dollars = if dollars < BigInt::from_int(0) { -dollars } else { dollars }
  let cents = if cents < BigInt::from_int(0) { -cents } else { cents }
  let dword = if dollars == BigInt::from_int(1) { "dollar" } else { "dollars" }
  let mut s = lang_en().cardinal_en(dollars) + " " + dword
  if cents > BigInt::from_int(0) {
    let cword = if cents == BigInt::from_int(1) { "cent" } else { "cents" }
    s = s + " and " + lang_en().cardinal_en(cents) + " " + cword
  }
  if neg {
    "minus " + s
  } else {
    s
  }
}

// =====================================================================
// Dispatch
// =====================================================================

/// True when the magnitude of `n` fits inside the language's scale-word
/// table. Scale tables are finite, so every language has a maximum supported
/// power; values beyond it are reported as unsupported instead of indexing
/// past the table (which would abort).
pub fn Lang::supports(self : Lang, n : BigInt) -> Bool {
  let x = if n < BigInt::from_int(0) { -n } else { n }
  if x == BigInt::from_int(0) {
    return true
  }
  let groups = group3(x)
  let (_, top_power) = groups[0]
  top_power < self.thousands.length()
}

/// Highest power of 1000 the language can spell (e.g. English: 11 -> 10^33).
pub fn Lang::max_power(self : Lang) -> Int {
  self.thousands.length() - 1
}

pub fn Lang::cardinal(self : Lang, n : BigInt) -> String {
  match self.variant {
    En => self.cardinal_en(n)
    Fr => self.cardinal_fr(n)
    Es => self.cardinal_es(n)
    De => self.cardinal_de(n)
    It => self.cardinal_it(n)
    Pt => self.cardinal_pt(n)
  }
}
