// lang_da.mbt — Danish number spelling (cardinal, ordinal, year, kroner).
//
// Port of upstream num2words 0.5.14 `lang_DA.py`. Danish counts the reverse of
// English ("enogtyve" = one-and-twenty) and glues the scale word onto the
// preceding group ("ettusinde", "ethundredetusind"). Upstream builds the words
// with its generic `splitnum`/`merge` pair; `da_split`/`da_merge`/`da_fold`
// reproduce that recursion (and its quirks) exactly:
//   * a leading 1 before a million-scale word becomes "en " ("en millioner");
//   * 100 and 1000 take an "et" prefix when they are the whole group
//     ("ethundrede", "ettusind"), but keep just "hundrede"/"tusind" after a
//     multiplier ("tohundrede", "titusind");
//   * " og " separates a 3-digit hundreds part from its remainder, "e og "
//     separates a thousands part, and million-scale groups are space-joined;
//   * a final unit below 10 swaps around its tens with "og" ("toogfyrre").

///|
/// Scale words, index = group power: 1 -> 10^3 ("tusind"), 2 -> 10^6
/// ("millioner"), ... 11 -> 10^33. Upstream always uses the plural form of the
/// long-scale words ("millioner", "milliarder"), even for a value of one.
let da_scale : Array[String] = [
  "", "tusind", "millioner", "milliarder", "billioner", "billiarder", "trillioner",
  "trilliarder", "quadrillioner", "quadrilliarder", "quintillioner", "quintilliarder",
]

///|
pub fn lang_da() -> Lang {
  {
    variant: Da,
    zero: "nul",
    ones: ["nul", "et", "to", "tre", "fire", "fem", "seks", "syv", "otte", "ni"],
    teens: [
      "ti", "elleve", "tolv", "tretten", "fjorten", "femten", "seksten", "sytten",
      "atten", "nitten",
    ],
    tens: [
      "", "", "tyve", "tredive", "fyrre", "halvtreds", "treds", "halvfjerds", "firs",
      "halvfems",
    ],
    hundred: "hundrede",
    thousands: da_scale,
    negative: "minus",
    decimal: "komma",
    comma_sep: false,
  }
}

///|
/// One upstream `merge` step. `ord` mirrors `self.ordflag`: when it is set, a
/// leading 1 is not rewritten to "en " before million-scale words.
fn da_merge(
  ctext0 : String,
  cnum0 : BigInt,
  ntext0 : String,
  nnum : BigInt,
  ord : Bool,
) -> (String, BigInt) {
  let one = BigInt::from_int(1)
  let ten = BigInt::from_int(10)
  let hundred = BigInt::from_int(100)
  let thousand = BigInt::from_int(1000)
  let hundred_thousand = BigInt::from_int(100000)
  let million = BigInt::from_int(1000000)
  let mut ctext = ctext0
  let cnum = cnum0
  let mut ntext = ntext0
  // `next` is rebuilt with an "et" prefix for 100/1000; upstream only reads
  // that tuple when `next` itself is returned (the leading-1 case below).
  let mut next_text = ntext0
  if nnum == hundred || nnum == thousand {
    next_text = "et" + next_text
  }
  if cnum == one {
    if nnum < million || ord {
      return (next_text, nnum)
    }
    ctext = "en"
  }
  if nnum > cnum {
    if nnum >= million {
      ctext = ctext + " "
    }
    return (ctext + ntext, cnum * nnum)
  }
  if cnum >= hundred && cnum < thousand {
    ctext = ctext + " og "
  } else if cnum >= thousand && cnum <= hundred_thousand {
    ctext = ctext + "e og "
  }
  if nnum < ten && cnum > ten && cnum < hundred {
    if nnum == one {
      ntext = "en"
    }
    // Swap so the unit leads the tens: "fire" + "og" + "tredive".
    let saved = ctext
    ctext = ntext + "og"
    ntext = saved
  } else if cnum >= million {
    ctext = ctext + " "
  }
  (ctext + ntext, cnum + nnum)
}

///|
/// Fold the parts of one `splitnum` node left to right with `da_merge`.
fn da_fold(parts : Array[(String, BigInt)], ord : Bool) -> (String, BigInt) {
  let (first_text, first_num) = parts[0]
  let mut text = first_text
  let mut num = first_num
  for i = 1; i < parts.length(); i = i + 1 {
    let (ntext, nnum) = parts[i]
    let (t, n) = da_merge(text, num, ntext, nnum, ord)
    text = t
    num = n
  }
  (text, num)
}

///|
/// Upstream `splitnum` for a positive value: pick the largest card not greater
/// than the value, spell the multiplier (a bare "et" for 1), append the card's
/// word, then the remainder. Each sub-result is merged before the next part.
fn Lang::da_split(self : Lang, value : BigInt, ord : Bool) -> (String, BigInt) {
  let one = BigInt::from_int(1)
  let ten = BigInt::from_int(10)
  let hundred = BigInt::from_int(100)
  let thousand = BigInt::from_int(1000)
  let zero = BigInt::from_int(0)
  let parts : Array[(String, BigInt)] = []
  if value >= thousand {
    // Largest power of 1000 not exceeding the value.
    let mut power = 1
    let mut scale = thousand
    while power + 1 < self.thousands.length() && scale * thousand <= value {
      scale = scale * thousand
      power = power + 1
    }
    let div = value / scale
    let rem = value % scale
    if div == one {
      parts.push(("et", one))
    } else {
      parts.push(self.da_split(div, ord))
    }
    parts.push((self.thousands[power], scale))
    if rem != zero {
      parts.push(self.da_split(rem, ord))
    }
  } else if value >= hundred {
    let div = value / hundred
    let rem = value % hundred
    if div == one {
      parts.push(("et", one))
    } else {
      parts.push(self.da_split(div, ord))
    }
    parts.push(("hundrede", hundred))
    if rem != zero {
      parts.push(self.da_split(rem, ord))
    }
  } else if value >= ten {
    let d = value.to_int() / 10
    if d >= 2 {
      // 20..99: the tens card is always the leading part here (div == 1).
      let card = BigInt::from_int(d * 10)
      let rem = value - card
      parts.push(("et", one))
      parts.push((self.tens[d], card))
      if rem != zero {
        parts.push(self.da_split(rem, ord))
      }
    } else {
      parts.push(("et", one))
      parts.push((self.teens[value.to_int() - 10], value))
    }
  } else {
    parts.push(("et", one))
    parts.push((self.ones[value.to_int()], value))
  }
  da_fold(parts, ord)
}

///|
/// Spell `n`, optionally with upstream's `ordflag` behaviour (a leading 1 is
/// kept as "et" before million-scale words, e.g. "millioner" for 10^6).
fn Lang::cardinal_da_impl(self : Lang, n : BigInt, ord : Bool) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let value = if neg { -n } else { n }
  let (text, _) = self.da_split(value, ord)
  if neg {
    self.negative + " " + text
  } else {
    text
  }
}

///|
fn Lang::cardinal_da(self : Lang, n : BigInt) -> String {
  self.cardinal_da_impl(n, false)
}

// --- ordinals ---------------------------------------------------------------

///|
/// Suffix rewrites applied to the cardinal, in upstream's insertion order
/// (first match wins and stops the scan).
let da_ords : Array[(String, String)] = [
  ("nul", "nul"),
  ("et", "første"),
  ("to", "anden"),
  ("tre", "tredje"),
  ("fire", "fjerde"),
  ("fem", "femte"),
  ("seks", "sjette"),
  ("syv", "syvende"),
  ("otte", "ottende"),
  ("ni", "niende"),
  ("ti", "tiende"),
  ("elleve", "ellevte"),
  ("tolv", "tolvte"),
  ("tretten", "trett"),
  ("fjorten", "fjort"),
  ("femten", "femt"),
  ("seksten", "sekst"),
  ("sytten", "sytt"),
  ("atten", "att"),
  ("nitten", "nitt"),
  ("tyve", "tyv"),
]

///|
/// Upstream `to_ordinal`: spell the cardinal with `ordflag` set, rewrite one
/// matching suffix, then append "te" for 30..39 and multiples of 100 and
/// "ende" for remainders above 12.
pub fn ordinal_da(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises TypeError for negative ordinals.
    return ""
  }
  let l = lang_da()
  if !l.supports(n) {
    return ""
  }
  let mut outword = l.cardinal_da_impl(n, true)
  for i = 0; i < da_ords.length(); i = i + 1 {
    let (suffix, repl) = da_ords[i]
    if ends_with(outword, suffix) {
      outword = outword[0:outword.length() - suffix.length()].to_owned() + repl
      break
    }
  }
  let r = (n % BigInt::from_int(100)).to_int()
  if (r >= 30 && r <= 39) || r == 0 {
    outword = outword + "te"
  } else if r > 12 {
    outword = outword + "ende"
  }
  outword
}

///|
/// Upstream `to_ordinal_num`: "te" for 30..39, 0, 1, 5, 6, 11 and 12; "en" for
/// 2; "ende" for everything else ("0te", "2en", "3ende", "21ende").
pub fn ordinal_num_da(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises TypeError for negative ordinals.
    return ""
  }
  let r = (n % BigInt::from_int(100)).to_int()
  let suffix = if (r >= 30 && r <= 39) ||
    r == 0 ||
    r == 1 ||
    r == 5 ||
    r == 6 ||
    r == 11 ||
    r == 12 {
    "te"
  } else if r == 2 {
    "en"
  } else {
    "ende"
  }
  n.to_string() + suffix
}

// --- years ------------------------------------------------------------------

///|
/// Python-style floor division/modulo for a positive divisor (a negative
/// dividend rounds the quotient down and the remainder up).
fn da_floor_divmod(n : BigInt, d : BigInt) -> (BigInt, BigInt) {
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
/// Upstream `to_year`: 1 -> "en"; when the hundreds part is a multiple of ten
/// the plain cardinal is used ("2010" -> "totusinde og ti"); otherwise the
/// number is split at 100 and the low part follows "hundrede" ("1900" ->
/// "nitten hundrede", "1999" -> "nitten hundrede nioghalvfems").
///
/// Negative years keep upstream's floor-division arithmetic (-44 ->
/// "minus et hundrede seksoghalvtreds").
pub fn year_da(n : BigInt) -> String {
  if n == BigInt::from_int(1) {
    return "en"
  }
  let l = lang_da()
  let ten = BigInt::from_int(10)
  let (high, low) = da_floor_divmod(n, BigInt::from_int(100))
  if high % ten == BigInt::from_int(0) {
    return l.cardinal_da(n)
  }
  let mut s = l.cardinal_da(high) + " hundrede"
  if low != BigInt::from_int(0) {
    s = s + " " + l.cardinal_da(low)
  }
  s
}

// --- currency ---------------------------------------------------------------

///|
/// DKK amounts. Upstream `to_currency` takes no currency code and always uses
/// "kr"/"øre"; it also applies an "en " prefix (slicing off the first three
/// characters of the cardinal) when `val // 100 == 1` or `val == 1`. That
/// slice is why 100 says "en undrede kr" and 101 "en undrede og et kr".
///
/// The minus sign comes from the cardinal of the major units, so an amount
/// below one unit loses it upstream (-0.5 -> "fem øre"); that is preserved.
fn currency_da(
  amount : String,
  units : BigInt,
  _cents : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  if code != "DKK" {
    return Err("currency code not supported for da: " + code)
  }
  let l = lang_da()
  let zero = BigInt::from_int(0)
  let one = BigInt::from_int(1)
  let hundred = BigInt::from_int(100)
  // Upstream calls to_splitnum on the raw float, so it splits through
  // float2tuple: 1234.56 -> (1234, 56) but 0.5 -> (0, 5) and 0.05 -> (0, 5).
  // Reproduce that by reading the decimal string directly (trailing zeros are
  // dropped, as Python's str(float) would).
  let body = if neg { amount[1:amount.length()].to_owned() } else { amount }
  let parts = split_to_array(body, ".")
  let high_abs = BigInt::from_string(parts[0])
  let high = if neg { -high_abs } else { high_abs }
  let mut frac = if parts.length() > 1 { parts[1] } else { "" }
  let mut end = frac.length()
  while end > 0 && frac[end - 1:end].to_owned() == "0" {
    end = end - 1
  }
  frac = frac[0:end].to_owned()
  let low = if frac.length() == 0 { zero } else { BigInt::from_string(frac) }
  if !l.supports(high_abs) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let mut out = ""
  if high != zero {
    out = l.cardinal_da(high)
    if low != zero {
      out = out + " kr og "
    } else {
      out = out + " kr"
    }
  }
  if low != zero {
    out = out + l.cardinal_da(low) + " øre"
  }
  let quotient = high / hundred
  if quotient == one || (high == one && low == zero) {
    out = "en " + out[3:out.length()].to_owned()
  }
  Ok(out)
}
