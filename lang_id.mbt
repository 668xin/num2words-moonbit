// lang_id.mbt — Indonesian number spelling (cardinal, ordinal, year, rupiah).
//
// Port of upstream num2words 0.5.14 `lang_ID.py`. Numbers are built from
// 3-digit groups with a few fused forms: 10 "sepuluh", 11 "sebelas" and
// 12..19 "<unit> belas", 100 "seratus", and a lone 1 in the thousands group
// "seribu". Fractions are read digit by digit after "koma" ("1234.56" ->
// "... koma lima enam"); the library models that through the (units, cents)
// currency input.

///|
/// Scale words, index = group power: 1 -> 10^3 ("ribu") ... 11 -> 10^33
/// ("desiliun"). Upstream refuses values at or above 10^36.
let id_scale : Array[String] = [
  "", "ribu", "juta", "miliar", "triliun", "kuadriliun", "kuantiliun", "sekstiliun",
  "septiliun", "oktiliun", "noniliun", "desiliun",
]

///|
pub fn lang_id() -> Lang {
  {
    variant: Id,
    zero: "nol",
    ones: [
      "nol", "satu", "dua", "tiga", "empat", "lima", "enam", "tujuh", "delapan",
      "sembilan",
    ],
    teens: [
      "sepuluh", "sebelas", "dua belas", "tiga belas", "empat belas", "lima belas",
      "enam belas", "tujuh belas", "delapan belas", "sembilan belas",
    ],
    tens: [
      "", "sepuluh", "dua puluh", "tiga puluh", "empat puluh", "lima puluh", "enam puluh",
      "tujuh puluh", "delapan puluh", "sembilan puluh",
    ],
    hundred: "ratus",
    thousands: id_scale,
    negative: "min",
    decimal: "koma",
    comma_sep: false,
  }
}

///|
/// Spell one 3-digit group (0..999): 100 -> "seratus", 110 -> "seratus
/// sepuluh", 111 -> "seratus sebelas", 1000's "1" -> "satu". Returns "" for
/// an all-zero group so the caller can drop it together with its scale word.
fn Lang::group_id(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  let parts : Array[String] = []
  if h == 1 {
    parts.push("seratus")
  } else if h > 1 {
    parts.push(self.ones[h])
    parts.push("ratus")
  }
  if r > 0 {
    if r < 10 {
      parts.push(self.ones[r])
    } else if r < 20 {
      parts.push(self.teens[r - 10])
    } else {
      let d = r / 10
      let u = r % 10
      parts.push(self.tens[d])
      if u > 0 {
        parts.push(self.ones[u])
      }
    }
  }
  join_parts(parts, " ")
}

///|
fn Lang::cardinal_id(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let m = if neg { -n } else { n }
  let groups = group3(m)
  let count = groups.length()
  let words : Array[String] = []
  let mut start = 0
  // Exactly two groups whose leading group is 1: 1000..1999 reads "seribu".
  if count == 2 {
    let (triple, _) = groups[0]
    if triple == BigInt::from_int(1) {
      words.push("seribu")
      start = 1
    }
  }
  for i = start; i < count; i = i + 1 {
    let (triple, _) = groups[i]
    let spelling = self.group_id(triple.to_int())
    if spelling == "" {
      continue
    }
    words.push(spelling)
    if i < count - 1 {
      words.push(id_scale[count - 1 - i])
    }
  }
  let body = join_parts(words, " ")
  if neg {
    self.negative + " " + body
  } else {
    body
  }
}

///|
/// Upstream prefixes "ke" and special-cases the sole word "satu" -> "pertama"
/// (so 1 -> "pertama", 0 -> "kenol", 20 -> "kedua puluh").
pub fn ordinal_id(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises TypeError for negative ordinals.
    return ""
  }
  let card = lang_id().cardinal_id(n)
  if card == "satu" {
    "pertama"
  } else {
    "ke" + card
  }
}

///|
pub fn ordinal_num_id(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises TypeError for negative ordinals.
    return ""
  }
  "ke-" + n.to_string()
}

///|
/// Indonesian has no year-specific reading upstream; a year is a cardinal.
pub fn year_id(n : BigInt) -> String {
  lang_id().cardinal_id(n)
}

///|
/// Rupiah amounts: upstream `to_currency` takes no code and spells the float
/// value followed by "rupiah", so zero cents read "koma nol" and a fraction is
/// spelled digit by digit ("1234.56" -> "... koma lima enam rupiah").
fn currency_id(
  units : BigInt,
  cents : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  if code != "IDR" {
    return Err("currency code not supported for id: " + code)
  }
  let l = lang_id()
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let mut out = l.cardinal_id(units) + " " + l.decimal
  if cents == BigInt::from_int(0) {
    // An exact amount reads as "<cardinal> koma nol" (upstream spells the
    // float 1.0 digit by digit).
    out = out + " " + l.ones[0]
  } else {
    // Cents are the two fractional digits with trailing zeros dropped, as in
    // Python's str(float): 0.5 -> "lima", 0.05 -> "nol lima", 0.56 -> "lima
    // enam".
    let c = cents.to_int()
    let hi = c / 10
    let lo = c % 10
    if lo == 0 {
      out = out + " " + l.ones[hi]
    } else {
      out = out + " " + l.ones[hi] + " " + l.ones[lo]
    }
  }
  out = out + " rupiah"
  let nonzero = units > BigInt::from_int(0) || cents > BigInt::from_int(0)
  if neg && nonzero {
    Ok(l.negative + " " + out)
  } else {
    Ok(out)
  }
}
