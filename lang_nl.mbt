// lang_nl.mbt — Dutch number spelling (cardinal, year).
//
// Dutch writes compounds as a single word: 21 -> "eenentwintig",
// 1234 -> "duizendtweehonderdvierendertig". A space appears only around scale
// words of a million and above ("een miljoen", "twee miljard"), matching
// upstream num2words `lang_NL`.
//
// "een" is the attributive form used inside compounds and before scale words;
// the standalone 1 keeps its accents ("één").

///|
/// Build the Dutch scale-word table (index = power of 1000) the same way
/// upstream does: the high words come from Latin roots,
///   high = ["zend"] + reversed(unit x ten) + lows
/// where high[i] maps to 10^(603-6i) + "iljard" and 10^(600-6i) + "iljoen".
fn nl_make_thousands() -> Array[String] {
  let tens = [
    "dez", "vigint", "trigint", "quadragint", "quinquagint", "sexagint", "septuagint",
    "oktogint", "nonagint",
  ]
  let units = [
    "", "un", "duo", "tre", "quattuor", "quin", "sex", "sept", "okto", "novem",
  ]
  let lows = ["non", "okt", "sept", "sext", "quint", "quadr", "tr", "b", "m"]
  let high : Array[String] = ["zend"]
  for ti = tens.length() - 1; ti >= 0; ti = ti - 1 {
    for ui = units.length() - 1; ui >= 0; ui = ui - 1 {
      high.push(units[ui] + tens[ti])
    }
  }
  for i = 0; i < lows.length(); i = i + 1 {
    high.push(lows[i])
  }
  let table : Array[String] = ["", "duizend"]
  for p = 2; p <= 201; p = p + 1 {
    // Even powers take "iljoen", odd powers "iljard".
    let idx = if p % 2 == 0 { 100 - p / 2 } else { (603 - 3 * p) / 6 }
    let suffix = if p % 2 == 0 { "iljoen" } else { "iljard" }
    table.push(high[idx] + suffix)
  }
  table
}

///|
let nl_thousands : Array[String] = nl_make_thousands()

///|
pub fn lang_nl() -> Lang {
  {
    variant: Nl,
    zero: "nul",
    ones: [
      "nul", "één", "twee", "drie", "vier", "vijf", "zes", "zeven", "acht", "negen",
    ],
    teens: [
      "tien", "elf", "twaalf", "dertien", "veertien", "vijftien", "zestien", "zeventien",
      "achttien", "negentien",
    ],
    tens: [
      "", "tien", "twintig", "dertig", "veertig", "vijftig", "zestig", "zeventig",
      "tachtig", "negentig",
    ],
    hundred: "honderd",
    thousands: nl_thousands,
    negative: "min",
    decimal: "komma",
    comma_sep: false,
  }
}

///|
/// 1..99. The tens/units pair is reversed and joined with "en" (or "ën" after
/// a word ending in "e"): 21 -> "eenentwintig", 22 -> "tweeëntwintig".
fn Lang::below100_nl(self : Lang, r : Int) -> String {
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
  let unit = if u == 1 { "een" } else { self.ones[u] }
  let sep = if ends_with(unit, "e") { "ën" } else { "en" }
  unit + sep + self.tens[d]
}

///|
/// 1..999, always written as one word: 100 -> "honderd", 101 ->
/// "honderdéén", 200 -> "tweehonderd".
fn Lang::triple_nl(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_nl(r)
  }
  let prefix = if h == 1 { "honderd" } else { self.ones[h] + "honderd" }
  if r == 0 {
    return prefix
  }
  prefix + self.below100_nl(r)
}

///|
fn Lang::cardinal_nl(self : Lang, n : BigInt) -> String {
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
  let powers : Array[Int] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    let word = if power == 0 {
      self.triple_nl(t)
    } else if power == 1 {
      // "duizend" attaches directly and swallows a group value of 1:
      // 1000 -> "duizend", 2000 -> "tweeduizend".
      let stem = if t == 1 { "" } else { self.triple_nl(t) }
      stem + "duizend"
    } else {
      // Million and above are separate words; a group value of 1 is "een".
      let stem = if t == 1 { "een" } else { self.triple_nl(t) }
      stem + " " + self.thousands[power]
    }
    parts.push(word)
    powers.push(power)
  }
  let mut joined = ""
  for i = 0; i < parts.length(); i = i + 1 {
    // A space follows a million-or-larger group; everything below is glued.
    if i > 0 && powers[i - 1] >= 2 {
      joined = joined + " "
    }
    joined = joined + parts[i]
  }
  if neg {
    self.negative + " " + joined
  } else {
    joined
  }
}

///|
/// Python floor division / modulo for a positive divisor (upstream uses
/// `val // 100` and `% 10`, whose results differ from truncation for negatives).
fn nl_floor_div(a : BigInt, b : BigInt) -> BigInt {
  let q = a / b
  let r = a % b
  let zero = BigInt::from_int(0)
  if r != zero && (r < zero) != (b < zero) {
    q - BigInt::from_int(1)
  } else {
    q
  }
}

///|
fn nl_floor_mod(a : BigInt, b : BigInt) -> BigInt {
  a - nl_floor_div(a, b) * b
}

///|
/// Dutch years read as "nineteen hundred" for most values, but stay cardinal
/// when the hundreds digit is 0: 1900 -> "negentien honderd", 2024 ->
/// "tweeduizendvierentwintig", 1001 -> "duizendéén".
pub fn year_nl(n : BigInt) -> String {
  let hundred = BigInt::from_int(100)
  let high = nl_floor_div(n, hundred)
  if nl_floor_mod(high, BigInt::from_int(10)) == BigInt::from_int(0) {
    return lang_nl().cardinal_nl(n)
  }
  let low = nl_floor_mod(n, hundred)
  let head = lang_nl().cardinal_nl(high) + " honderd"
  if low == BigInt::from_int(0) {
    head
  } else {
    head + " " + lang_nl().cardinal_nl(low)
  }
}
