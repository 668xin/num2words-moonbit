// lang_de.mbt — German number spelling (cardinal, year).
//
// German word order reverses the teens/tens: 41 = "einundvierzig"
// (one-and-forty). The unit "1" is "eins" when it stands alone as the final
// word, but "ein" when it leads "und" (einund...).

// Long-scale scale words. Index = group power.

///|
let de_scale_sing : Array[String] = [
  "", "tausend", "Million", "Milliarde", "Billion", "Billiarde", "Trillion", "Trilliarde",
  "Quadrillion",
]

///|
let de_scale_plur : Array[String] = [
  "", "tausend", "Millionen", "Milliarden", "Billionen", "Billiarden", "Trillionen",
  "Trilliarden", "Quadrillionen",
]

///|
pub fn lang_de() -> Lang {
  {
    variant: De,
    zero: "null",
    ones: [
      "null", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht",
      "neun",
    ],
    teens: [
      "zehn", "elf", "zwölf", "dreizehn", "vierzehn", "fünfzehn", "sechzehn", "siebzehn",
      "achtzehn", "neunzehn",
    ],
    tens: [
      "", "zehn", "zwanzig", "dreißig", "vierzig", "fünfzig", "sechzig", "siebzig",
      "achtzig", "neunzig",
    ],
    hundred: "hundert",
    thousands: de_scale_plur,
    negative: "minus",
    decimal: "Komma",
    comma_sep: false,
  }
}

///|
fn Lang::de_unit(self : Lang, u : Int) -> String {
  if u == 1 {
    "ein"
  } else {
    self.ones[u]
  }
}

///|
fn Lang::below100_de(self : Lang, r : Int) -> String {
  if r < 10 {
    // final unit "1" reads "eins"
    return if r == 1 { "eins" } else { self.ones[r] }
  }
  if r < 20 {
    return self.teens[r - 10]
  }
  let d = r / 10
  let u = r % 10
  if u == 0 {
    return self.tens[d]
  }
  return self.de_unit(u) + "und" + self.tens[d]
}

///|
fn Lang::triple_de(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_de(r)
  }
  let hprefix = if h == 1 { "ein" } else { self.ones[h] }
  let hs = hprefix + "hundert"
  if r == 0 {
    return hs
  }
  return hs + self.below100_de(r)
}

///|
fn Lang::cardinal_de(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  let groups = group3(n)
  let words : Array[String] = []
  let powers : Array[Int] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    let mut s = self.triple_de(t)
    if power > 0 {
      if power == 1 {
        if t == 1 {
          s = "eintausend"
        } else {
          s = s + "tausend"
        }
      } else if t == 1 {
        s = "eine " + de_scale_sing[power]
      } else {
        s = s + " " + de_scale_plur[power]
      }
    }
    words.push(s)
    powers.push(power)
  }
  let mut out = ""
  for k = 0; k < words.length(); k = k + 1 {
    if k == 0 {
      out = words[k]
    } else {
      let prev = powers[k - 1]
      let cur = powers[k]
      if cur >= 2 || prev >= 2 {
        out = out + " " + words[k]
      } else {
        out = out + words[k]
      }
    }
  }
  if neg {
    "minus " + out
  } else {
    out
  }
}

///|
/// German years follow upstream: below 1100 and whenever the hundreds part is
/// a multiple of ten (1000, 2000, 3000, 10000, ...) the cardinal is used;
/// otherwise the last two digits are split off and the first part is followed
/// by "hundert" ("1900" -> "neunzehnhundert", "2100" ->
/// "einundzwanzighundert").
pub fn year_de(n : BigInt) -> String {
  let l = lang_de()
  if n < BigInt::from_int(0) || n < BigInt::from_int(1100) {
    return l.cardinal_de(n)
  }
  let high = n / BigInt::from_int(100)
  let low = n % BigInt::from_int(100)
  if high % BigInt::from_int(10) == BigInt::from_int(0) {
    return l.cardinal_de(n)
  }
  let mut s = l.cardinal_de(high) + "hundert"
  if low > BigInt::from_int(0) {
    s = s + l.cardinal_de(low)
  }
  s
}
