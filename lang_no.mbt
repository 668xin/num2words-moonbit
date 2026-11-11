// lang_no.mbt — Norwegian number spelling (cardinal, ordinal, year, NOK).
//
// Port of upstream num2words 0.5.14 `lang_NO.py`. The grammar comes from
// upstream's `splitnum`/`merge` pair:
//   * 1 is "en" everywhere, including before "hundre" and "tusen" ("en
//     hundre", "en tusen"); a unit below 20 is glued to its tens ("tjueen").
//   * A 3-digit group speaks its hundreds part and its remainder joined by
//     "og" ("en hundre og en", "ni hundre og nittini").
//   * Groups are separated by a space, except that a remaining group below
//     100 is introduced by "og" ("en tusen og en", "en million og en"). A
//     group that carries a scale word is never introduced by "og", even when
//     its own value is 1 ("en million en tusen").
//   * The scale is the long scale. Upstream composes it from "m" + "illard"
//     etc., so 10^9 is "millard" (single "i") while 10^12 is "billion".

///|
/// Scale words, index = group power: 1 -> 10^3 ("tusen") ... 11 -> 10^33
/// ("quintillard"). Upstream supports far larger values; this table matches
/// the range of the other languages in this project.
let no_scale : Array[String] = [
  "", "tusen", "million", "millard", "billion", "billard", "trillion", "trillard",
  "quadrillion", "quadrillard", "quintillion", "quintillard",
]

///|
pub fn lang_no() -> Lang {
  {
    variant: No,
    zero: "null",
    ones: [
      "null", "en", "to", "tre", "fire", "fem", "seks", "syv", "åtte", "ni",
    ],
    teens: [
      "ti", "elleve", "tolv", "tretten", "fjorten", "femten", "seksten", "sytten",
      "atten", "nitten",
    ],
    tens: [
      "", "ti", "tjue", "tretti", "førti", "femti", "seksti", "sytti", "åtti",
      "nitti",
    ],
    hundred: "hundre",
    thousands: no_scale,
    negative: "minus",
    decimal: "komma",
    comma_sep: false,
  }
}

///|
/// Spell 1..99: tens and units are concatenated without a space, the teens
/// use their own table.
fn Lang::below100_no(self : Lang, r : Int) -> String {
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
  self.tens[d] + self.ones[u]
}

///|
/// Spell one 3-digit group (1..999): the hundreds part keeps "en" for 1
/// ("en hundre"), and a non-zero remainder follows " og ".
fn Lang::triple_no(self : Lang, t : Int) -> String {
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_no(r)
  }
  let head = self.ones[h] + " " + self.hundred
  if r == 0 {
    head
  } else {
    head + " og " + self.below100_no(r)
  }
}

///|
fn Lang::cardinal_no(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let m = if neg { -n } else { n }
  let groups = group3(m)
  let parts : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    let mut s = self.triple_no(t)
    if power > 0 {
      s = s + " " + self.thousands[power]
    }
    // Only a bare units group below 100 is joined with "og".
    if parts.length() > 0 && power == 0 && t < 100 {
      s = "og " + s
    }
    parts.push(s)
  }
  let body = join_parts(parts, " ")
  if neg {
    self.negative + " " + body
  } else {
    body
  }
}

// --- ordinals ---------------------------------------------------------------

///|
/// Suffix rewrites applied to the cardinal, first match wins (upstream's
/// insertion-ordered `ords_pl` dict). "tretten" is deliberately absent, so
/// 13 becomes "trettførste" via the single-word table below.
let no_ord_pl : Array[(String, String)] = [
  ("to", "andre"),
  ("tre", "tredje"),
  ("fire", "fjerde"),
  ("fem", "femte"),
  ("seks", "sjette"),
  ("syv", "syvende"),
  ("åtte", "åttende"),
  ("ni", "niende"),
  ("ti", "tiende"),
  ("elleve", "ellevte"),
  ("tolv", "tolvte"),
  ("fjorten", "fjortende"),
  ("femten", "femtende"),
  ("seksten", "sekstende"),
  ("sytten", "syttende"),
  ("atten", "attende"),
  ("nitten", "nittende"),
  ("tjue", "tjuende"),
  ("hundre", "hundrede"),
  ("tusen", "tusende"),
  ("million", "millionte"),
]

///|
/// Upstream rewrites one plural suffix, then the singular "en" -> "første".
/// 0 -> "null", 1 -> "første", 21 -> "tjueførste",
/// 100 -> "en hundrede", 1234 -> "en tusen to hundre og trettifjerde".
pub fn ordinal_no(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises TypeError for negative ordinals.
    return ""
  }
  let mut word = lang_no().cardinal_no(n)
  for i = 0; i < no_ord_pl.length(); i = i + 1 {
    let (suffix, repl) = no_ord_pl[i]
    if ends_with(word, suffix) {
      word = word[0:word.length() - suffix.length()].to_owned() + repl
      break
    }
  }
  if ends_with(word, "en") {
    word = word[0:word.length() - 2].to_owned() + "første"
  }
  word
}

///|
/// Upstream `to_ordinal_num` is `str(value) + "."`.
pub fn ordinal_num_no(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises TypeError for negative ordinals.
    return ""
  }
  n.to_string() + "."
}

// --- years ------------------------------------------------------------------

///|
/// Python-style floor division and modulo (the divisor is positive, so only a
/// negative dividend needs the quotient adjusted down and the remainder up).
fn no_floor_divmod(n : BigInt, d : BigInt) -> (BigInt, BigInt) {
  let neg = n < BigInt::from_int(0)
  let a = if neg { -n } else { n }
  let q = a / d
  let r = a % d
  if neg && r != BigInt::from_int(0) {
    (-q - BigInt::from_int(1), d - r)
  } else if neg {
    (-q, r)
  } else {
    (q, r)
  }
}

///|
/// Upstream `to_year`: when the tens digit of the hundreds part is zero the
/// plain cardinal is used ("2010" -> "to tusen og ti"); otherwise the number
/// is split at 100 and the low part follows "hundre og" ("1900" ->
/// "nitten hundre", "1999" -> "nitten hundre og nittini").
///
/// Negative years reproduce upstream's floor-division arithmetic, which
/// yields "minus en hundre og femtiseks" for -44.
pub fn year_no(n : BigInt) -> String {
  let l = lang_no()
  let hundred = BigInt::from_int(100)
  let (high, low) = no_floor_divmod(n, hundred)
  if high % BigInt::from_int(10) == BigInt::from_int(0) {
    return l.cardinal_no(n)
  }
  let parts : Array[String] = []
  if high != BigInt::from_int(0) {
    parts.push(l.cardinal_no(high))
    parts.push("hundre")
    if low != BigInt::from_int(0) {
      parts.push("og")
    }
  }
  if low != BigInt::from_int(0) {
    parts.push(l.cardinal_no(low))
  }
  join_parts(parts, " ")
}

// --- currency ---------------------------------------------------------------

///|
/// NOK amounts. Upstream spells "<units> krone/kroner og <cents> øre" and
/// then deletes " og null øre", so zero cents are dropped entirely
/// ("1234.56" -> "... kroner og femtiseks øre", "1000" -> "... kroner").
/// Only the default code "NOK" exists upstream.
fn currency_no(
  units : BigInt,
  cents : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  if code != "NOK" {
    return Err("currency code not supported for no: " + code)
  }
  let l = lang_no()
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let unit = if units == BigInt::from_int(1) { "krone" } else { "kroner" }
  let mut body = l.cardinal_no(units) + " " + unit
  if cents != BigInt::from_int(0) {
    body = body + " og " + l.cardinal_no(cents) + " øre"
  }
  let nonzero = units > BigInt::from_int(0) || cents > BigInt::from_int(0)
  let sign = if neg && nonzero { l.negative + " " } else { "" }
  Ok(sign + body)
}
