// lang_hu.mbt — Hungarian number spelling (cardinal, ordinal, year, currency).
//
// Port of upstream num2words 0.5.14 `lang_HU.py`. Hungarian writes the whole
// number as one compound: below a million everything is glued together
// ("százhuszonhárom", "kétezer"), while a scale word of 10^6 and above keeps a
// hyphen between the scale phrase and the remainder ("egymillió-egy",
// "kétezer-huszonnégy"):
//
//   * 2 is "kettő" standalone and after a bare tens word ("huszonkettő"), but
//     "két" when it multiplies a scale word or follows a hundreds group
//     ("kétezer", "százkét", "kétmillió");
//   * a thousands group keeps the hyphen only when the whole number is above
//     2000 and a remainder follows (2000 -> "kétezer", 2001 ->
//     "kétezer-egy");
//   * scale words are the long-scale -illió/-illiárd series (10^12 "billió",
//     10^15 "billiárd", 10^18 "trillió").
//
// Ordinals take the cardinal and rewrite the last morpheme through a fixed
// suffix table (3 -> "harmadik", 20 -> "huszadik", 10^6 ->
// "egymilliomodik"). Negative ordinals are supported upstream
// ("mínusz első"), while `ordinal_num` rejects them.

// --- word tables ------------------------------------------------------------

///|
let hu_ones : Array[String] = [
  "nulla", "egy", "kettő", "három", "négy", "öt", "hat", "hét", "nyolc", "kilenc",
]

///|
/// 10..19.
let hu_teens : Array[String] = [
  "tíz", "tizenegy", "tizenkettő", "tizenhárom", "tizennégy", "tizenöt", "tizenhat",
  "tizenhét", "tizennyolc", "tizenkilenc",
]

///|
/// Tens 20..90 (index = tens digit).
let hu_twenties : Array[String] = [
  "", "", "húsz", "harminc", "negyven", "ötven", "hatvan", "hetven", "nyolcvan",
  "kilencven",
]

///|
/// Scale words for powers 0..13 (10^0 .. 10^39); power 1 is the bare "ezer"
/// used by `Lang.thousands`, powers 2.. are the -illió/-illiárd series.
let hu_scales : Array[String] = [
  "", "ezer", "millió", "milliárd", "billió", "billiárd", "trillió", "trilliárd",
  "quadrillió", "quadrilliárd", "quintillió", "quintilliárd", "sextillió", "sextilliárd",
]

///|
/// Order matters: the first matching suffix wins (upstream dict insertion
/// order), so "kilencven" is checked after "kilenc" but does not end with it.
let hu_partial : Array[(String, String)] = [
  ("nulla", "nullad"),
  ("egy", "egyed"),
  ("kettő", "ketted"),
  ("három", "harmad"),
  ("négy", "negyed"),
  ("öt", "ötöd"),
  ("hat", "hatod"),
  ("hét", "heted"),
  ("nyolc", "nyolcad"),
  ("kilenc", "kilenced"),
  ("tíz", "tized"),
  ("húsz", "huszad"),
  ("harminc", "harmincad"),
  ("negyven", "negyvened"),
  ("ötven", "ötvened"),
  ("hatvan", "hatvanad"),
  ("hetven", "hetvened"),
  ("nyolcvan", "nyolcvanad"),
  ("kilencven", "kilencvened"),
  ("száz", "század"),
  ("ezer", "ezred"),
  ("illió", "milliomod"),
  ("illiárd", "milliárdod"),
]

///|
pub fn lang_hu() -> Lang {
  {
    variant: Hu,
    zero: "nulla",
    ones: hu_ones,
    teens: hu_teens,
    tens: hu_twenties,
    hundred: "száz",
    thousands: hu_scales,
    negative: "mínusz",
    decimal: "egész",
    comma_sep: false,
  }
}

// --- cardinal ---------------------------------------------------------------

///|
fn hu_pow10(p : Int) -> BigInt {
  let mut r = BigInt::from_int(1)
  for i = 0; i < p; i = i + 1 {
    r = r * BigInt::from_int(10)
  }
  r
}

///|
/// Upstream `to_cardinal(value, zero=ZERO)`. `bare` is the `zero=""` mode used
/// by the hundreds/thousands/million multipliers: 0 becomes "" and 2 becomes
/// "két".
fn Lang::hu_card(self : Lang, n : BigInt, bare : Bool) -> String {
  if n == BigInt::from_int(0) {
    return if bare { "" } else { "nulla" }
  }
  if bare && n == BigInt::from_int(2) {
    return "két"
  }
  let b10 = BigInt::from_int(10)
  let b20 = BigInt::from_int(20)
  let b30 = BigInt::from_int(30)
  let b100 = BigInt::from_int(100)
  let b1000 = BigInt::from_int(1000)
  let b1000000 = BigInt::from_int(1000000)
  if n < b10 {
    return hu_ones[n.to_int()]
  }
  if n < b20 {
    return hu_teens[n.to_int() - 10]
  }
  if n < b30 {
    let u = n.to_int() - 20
    return if u == 0 { "húsz" } else { "huszon" + hu_ones[u] }
  }
  if n < b100 {
    let v = n.to_int()
    let u = v % 10
    let head = hu_twenties[v / 10]
    if u == 0 {
      head
    } else {
      head + self.hu_card(BigInt::from_int(u), false)
    }
  } else if n < b1000 {
    let v = n.to_int()
    let h = v / 100
    let r = v % 100
    let prefix = if h == 1 {
      "száz"
    } else {
      self.hu_card(BigInt::from_int(h), true) + "száz"
    }
    prefix + self.hu_card(BigInt::from_int(r), true)
  } else if n < b1000000 {
    let v = n.to_int()
    let t = v / 1000
    let r = v % 1000
    let prefix = if t == 1 {
      "ezer"
    } else {
      self.hu_card(BigInt::from_int(t), true) + "ezer"
    }
    let postfix = self.hu_card(BigInt::from_int(r), true)
    if v <= 2000 || postfix == "" {
      prefix + postfix
    } else {
      prefix + "-" + postfix
    }
  } else {
    let digits = n.to_string().length()
    let d = if digits % 3 == 0 { digits - 2 } else { digits }
    let pow = d / 3 * 3
    let exp = hu_pow10(pow)
    let rest = n % exp
    let head = self.hu_card(n / exp, true) + hu_scales[pow / 3]
    if rest == BigInt::from_int(0) {
      head
    } else {
      head + "-" + self.hu_card(rest, true)
    }
  }
}

///|
fn Lang::cardinal_hu(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let v = if neg { -n } else { n }
  let words = self.hu_card(v, false)
  if neg {
    self.negative + " " + words
  } else {
    words
  }
}

// --- ordinal ----------------------------------------------------------------

///|
/// Upstream `to_ordinal`: 1 -> "első", 2 -> "második", otherwise the cardinal
/// with its last morpheme rewritten then "ik" appended.
pub fn ordinal_hu(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return "mínusz " + ordinal_hu(-n)
  }
  if n == BigInt::from_int(1) {
    return "első"
  }
  if n == BigInt::from_int(2) {
    return "második"
  }
  if !lang_hu().supports(n) {
    return ""
  }
  let mut out = lang_hu().cardinal_hu(n)
  for i = 0; i < hu_partial.length(); i = i + 1 {
    let (suffix, repl) = hu_partial[i]
    if ends_with(out, suffix) {
      out = out[0:out.length() - suffix.length()].to_owned() + repl
      break
    }
  }
  out + "ik"
}

///|
/// Upstream `to_ordinal_num` is "<n>." and rejects negative input.
pub fn ordinal_num_hu(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    ""
  } else {
    n.to_string() + "."
  }
}

// --- year -------------------------------------------------------------------

///|
/// Upstream `to_year`: negative years take the "i. e. " (időszámítás előtt)
/// prefix and use the absolute value.
pub fn year_hu(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    "i. e. " + lang_hu().cardinal_hu(-n)
  } else {
    lang_hu().cardinal_hu(n)
  }
}

// --- currency ---------------------------------------------------------------

///|
/// Noun forms for the 20 EU codes upstream's Hungarian converter accepts:
/// (unit one/many, cent one/many).
fn hu_currency_forms(
  code : String,
) -> Result[(String, String, String, String), String] {
  match code {
    "AUD" => Ok(("dollar", "dollars", "cent", "cents"))
    "BYN" => Ok(("rouble", "roubles", "kopek", "kopeks"))
    "CAD" => Ok(("dollar", "dollars", "cent", "cents"))
    "EEK" => Ok(("kroon", "kroons", "sent", "senti"))
    "EUR" => Ok(("euro", "euro", "cent", "cents"))
    "GBP" => Ok(("pound sterling", "pounds sterling", "penny", "pence"))
    "LTL" => Ok(("litas", "litas", "cent", "cents"))
    "LVL" => Ok(("lat", "lats", "santim", "santims"))
    "USD" => Ok(("dollar", "dollars", "cent", "cents"))
    "RUB" => Ok(("rouble", "roubles", "kopek", "kopeks"))
    "SEK" => Ok(("krona", "kronor", "öre", "öre"))
    "NOK" => Ok(("krone", "kroner", "øre", "øre"))
    "PLN" => Ok(("zloty", "zlotys", "grosz", "groszy"))
    "MXN" => Ok(("peso", "pesos", "cent", "cents"))
    "RON" => Ok(("leu", "lei", "ban", "bani"))
    "INR" => Ok(("rupee", "rupees", "paisa", "paise"))
    "HUF" => Ok(("forint", "forint", "fillér", "fillér"))
    "ISK" => Ok(("króna", "krónur", "aur", "aurar"))
    "UZS" => Ok(("sum", "sums", "tiyin", "tiyins"))
    "SAR" => Ok(("saudi riyal", "saudi riyals", "halalah", "halalas"))
    _ => Err(code)
  }
}

///|
/// Hungarian currency spelling ("<units> forint, <cents> fillér"); upstream
/// uses the comma separator and the singular noun only after 1.
fn currency_hu(
  units : BigInt,
  cents : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  let l = lang_hu()
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let (u1, u2, c1, c2) = match hu_currency_forms(code) {
    Err(c) => return Err("currency code not supported for hu: " + c)
    Ok(forms) => forms
  }
  let unit = if units == BigInt::from_int(1) { u1 } else { u2 }
  let cent = if cents == BigInt::from_int(1) { c1 } else { c2 }
  let body = l.cardinal_hu(units) +
    " " +
    unit +
    ", " +
    l.cardinal_hu(cents) +
    " " +
    cent
  if neg {
    Ok("mínusz " + body)
  } else {
    Ok(body)
  }
}
