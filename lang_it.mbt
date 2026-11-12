// lang_it.mbt — Italian number spelling (cardinal, year).
//
// Italian quirks handled here:
//   * the tens word drops its final vowel before "uno" and "otto"
//     (venti + uno -> "ventuno", trenta + otto -> "trentotto");
//   * "tre" takes an accent when it ends a compound ("ventitré");
//   * "cento" elides its final vowel before "otto" ("centotto"), but keeps it
//     before other vowel-initial units ("centouno");
//   * scale words: "mila" attaches to the preceding word ("duemila") while
//     million-and-above are separate words ("due milioni").

// Scale words for a group value of exactly 1. Index = group power:
// 1 -> 10^3, 2 -> 10^6, 3 -> 10^9, 4 -> 10^12 ...

///|
let it_scale_sing : Array[String] = [
  "", "mille", "milione", "miliardo", "bilione", "biliardo", "trilione", "triliardo",
]

// Scale words for group values >= 2. Index = group power.

///|
let it_scale_plur : Array[String] = [
  "", "mila", "milioni", "miliardi", "bilioni", "biliardi", "trilioni", "triliardi",
]

// Hundreds: 2 -> "duecento", 3 -> "trecento", ... 9 -> "novecento".

///|
let it_hundreds : Array[String] = [
  "", "", "duecento", "trecento", "quattrocento", "cinquecento", "seicento", "settecento",
  "ottocento", "novecento",
]

// Units as they appear inside a compound. "tre" stays unaccented while a
// further morpheme follows ("ventitremila"); the accent is restored on the
// final word by `it_accent_final` ("ventitré").

///|
let it_units_compound : Array[String] = [
  "", "uno", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove",
]

///|
pub fn lang_it() -> Lang {
  {
    variant: It,
    zero: "zero",
    ones: [
      "zero", "uno", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove",
    ],
    teens: [
      "dieci", "undici", "dodici", "tredici", "quattordici", "quindici", "sedici",
      "diciassette", "diciotto", "diciannove",
    ],
    tens: [
      "", "dieci", "venti", "trenta", "quaranta", "cinquanta", "sessanta", "settanta",
      "ottanta", "novanta",
    ],
    hundred: "cento",
    thousands: it_scale_plur,
    negative: "meno",
    decimal: "virgola",
    comma_sep: false,
  }
}

///|
/// Drop the final vowel of a tens/hundreds word (venti -> "vent").
fn it_truncate(w : String) -> String {
  if w.length() == 0 {
    return w
  }
  w[0:w.length() - 1].to_owned()
}

///|
/// Restore the accent on a final "tre" glued to a preceding morpheme:
/// "ventitre" -> "ventitré", "milletre" -> "milletré". A standalone "tre"
/// (3, or after a space) stays unaccented.
fn it_accent_final(s : String) -> String {
  let n = s.length()
  if n > 3 && s[n - 3:n].to_owned() == "tre" && s[n - 4:n - 3].to_owned() != " " {
    s[0:n - 3].to_owned() + "tré"
  } else {
    s
  }
}

///|
fn Lang::below100_it(self : Lang, r : Int) -> String {
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
  if u == 1 || u == 8 {
    // venti + uno -> "ventuno"; trenta + otto -> "trentotto"
    return it_truncate(self.tens[d]) + it_units_compound[u]
  }
  // tre carries an accent in final position: 23 -> "ventitré"
  return self.tens[d] + it_units_compound[u]
}

///|
fn Lang::triple_it(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_it(r)
  }
  let prefix = if h == 1 { "cento" } else { it_hundreds[h] }
  if r == 0 {
    return prefix
  }
  let low = self.below100_it(r)
  // The final vowel of "...cento" is dropped when the following part starts
  // with "o": 108 -> "centotto", 180 -> "centottanta", 208 -> "duecentotto".
  // It is kept before other vowels: 101 -> "centouno", 111 -> "centoundici".
  if low[0:1].to_owned() == "o" {
    return it_truncate(prefix) + low
  }
  return prefix + low
}

///|
/// Speak 0..999999 ("mille", "duemilatrecentoquarantacinque").
fn Lang::it_below_million(self : Lang, n : Int) -> String {
  if n < 1000 {
    return self.triple_it(n)
  }
  let thousands = n / 1000
  let rest = n % 1000
  let head = if thousands == 1 {
    "mille"
  } else {
    self.triple_it(thousands) + "mila"
  }
  if rest == 0 {
    head
  } else {
    head + self.triple_it(rest)
  }
}

///|
/// Recursive long-scale composition, mirroring upstream
/// `big_number_to_cardinal`: the separator before the remaining lower part is
/// ", " when that part itself contains the conjunction " e " (`un miliardo,
/// duecentotrentaquattro milioni e ...`) and " e " otherwise (`un bilione e un
/// miliardo`).
fn Lang::cardinal_it_raw(self : Lang, n : BigInt) -> String {
  let million = BigInt::from_int(1000000)
  if n < million {
    return self.it_below_million(n.to_int())
  }
  let digits = n.to_string()
  let len = digits.length()
  let predigits = if len % 3 == 0 { 3 } else { len % 3 }
  let multiplier = BigInt::from_string(digits[0:predigits].to_owned())
  let exponent = BigInt::from_string(digits[predigits:len].to_owned())
  let power = (len - predigits) / 3
  let one = BigInt::from_int(1)
  let prefix = if multiplier == one {
    "un "
  } else {
    self.cardinal_it_raw(multiplier)
  }
  let infix = if multiplier == one {
    it_scale_sing[power]
  } else {
    " " + it_scale_plur[power]
  }
  if exponent == BigInt::from_int(0) {
    return prefix + infix
  }
  let postfix = self.cardinal_it_raw(exponent)
  let sep = if postfix.contains(" e ") { ", " } else { " e " }
  prefix + infix + sep + postfix
}

///|
fn Lang::cardinal_it(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let abs_n = if neg { -n } else { n }
  let joined = it_accent_final(self.cardinal_it_raw(abs_n))
  if neg {
    "meno " + joined
  } else {
    joined
  }
}

///|
/// Italian years are read as a plain cardinal ("2024" ->
/// "duemilaventiquattro"), so this simply delegates to `cardinal_it`.
pub fn year_it(n : BigInt) -> String {
  lang_it().cardinal_it(n)
}
