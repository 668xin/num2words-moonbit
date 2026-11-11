// lang_sv.mbt — Swedish number spelling (cardinal, ordinal).
//
// Swedish glues the morphemes of a 3-digit group into a single word
// ("tvåhundratrettiofyra") but separates a large scale group with a space
// whenever what follows is 100 or more ("etttusen tvåhundratrettiofyra").
// A sub-hundred tail is glued straight on: 1001 -> "etttusenett",
// 1000001 -> "en miljonett", while 1100 -> "etttusen etthundra".
//
// Scale words are kept in their plural base form ("miljoner", "miljarder");
// a count of one strips the "er" and prefixes "en" ("en miljon", "en
// miljard"), whereas "tusen" never takes "en" ("etttusen", "tvåtusen").
//
// Upstream num2words 0.5.14 implements only `to_cardinal` and `to_ordinal`
// for Swedish; `to_ordinal_num` and `to_year` raise NotImplementedError, so
// this port returns "" for them. Negative ordinals raise TypeError upstream,
// hence "" as well.

///|
/// Scale words, index = group power: 1 -> 10^3, 2 -> 10^6, ... 201 -> 10^603.
/// Upstream derives them from lang_EU's `gen_high_numwords` (Latin prefixes
/// followed by "iljoner" / "iljarder"), which is reproduced here.
fn sv_thousands() -> Array[String] {
  let lows : Array[String] = [
    "non", "oct", "sept", "sext", "quint", "quadr", "tr", "b", "m",
  ]
  let units : Array[String] = [
    "", "un", "duo", "tre", "quattuor", "quin", "sex", "sept", "octo", "novem",
  ]
  let tens : Array[String] = [
    "dec", "vigint", "trigint", "quadragint", "quinquagint", "sexagint", "septuagint",
    "octogint", "nonagint",
  ]
  // "cent" + the reversed units x tens product + the size prefixes "non".."m":
  // 100 entries, largest magnitude first (high_numwords order).
  let high : Array[String] = ["cent"]
  for i = tens.length() - 1; i >= 0; i = i - 1 {
    for j = units.length() - 1; j >= 0; j = j - 1 {
      high.push(units[j] + tens[i])
    }
  }
  for i = 0; i < lows.length(); i = i + 1 {
    high.push(lows[i])
  }
  // Entry k of `high` yields 10^(603 - 6k) ("...iljarder", power 201 - 2k)
  // and 10^(600 - 6k) ("...iljoner", power 200 - 2k).
  let scale : Array[String] = ["", "tusen"]
  for p = 2; p <= 201; p = p + 1 {
    if p % 2 == 0 {
      scale.push(high[(200 - p) / 2] + "iljoner")
    } else {
      scale.push(high[(201 - p) / 2] + "iljarder")
    }
  }
  scale
}

///|
pub fn lang_sv() -> Lang {
  {
    variant: Sv,
    zero: "noll",
    ones: [
      "noll", "ett", "två", "tre", "fyra", "fem", "sex", "sju", "åtta", "nio",
    ],
    teens: [
      "tio", "elva", "tolv", "tretton", "fjorton", "femton", "sexton", "sjutton",
      "arton", "nitton",
    ],
    tens: [
      "", "tio", "tjugo", "trettio", "förtio", "femtio", "sextio", "sjuttio", "åttio",
      "nittio",
    ],
    hundred: "hundra",
    thousands: sv_thousands(),
    negative: "minus",
    decimal: "komma",
    comma_sep: false,
  }
}

// --- cardinal ---------------------------------------------------------------

///|
/// 0..99: 20 -> "tjugo", 21 -> "tjugoett", 42 -> "förtiotvå".
fn Lang::sv_below100(self : Lang, r : Int) -> String {
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
/// 1..999. The hundreds morpheme takes the cardinal unit, so 1 is "ett":
/// 100 -> "etthundra", 101 -> "etthundraett". The remainder is glued on.
fn Lang::sv_below1000(self : Lang, x : Int) -> String {
  if x < 100 {
    return self.sv_below100(x)
  }
  let h = x / 100
  let r = x % 100
  let head = self.ones[h] + self.hundred
  if r == 0 {
    head
  } else {
    head + self.sv_below100(r)
  }
}

///|
/// Mirrors upstream `merge`: a leading group of one becomes "en miljon" /
/// "en miljard" (but "etttusen"), a larger count keeps the plural scale word
/// ("två miljoner", "tvåtusen"), and the tail is glued when it is below 100.
fn Lang::sv_rec(self : Lang, v : BigInt) -> String {
  if v < BigInt::from_int(100) {
    return self.sv_below100(v.to_int())
  }
  if v < BigInt::from_int(1000) {
    return self.sv_below1000(v.to_int())
  }
  let groups = group3(v)
  let (triple, power) = groups[0]
  let head = triple.to_int()
  let mut elem = BigInt::from_int(1)
  for i = 0; i < power; i = i + 1 {
    elem = elem * BigInt::from_int(1000)
  }
  let rest = v % elem
  let scale = self.thousands[power]
  let mut left = ""
  if head == 1 {
    if power == 1 {
      left = "etttusen"
    } else {
      // "en " + the plural scale word minus its "er" ("en miljon").
      let k = scale.length()
      left = "en " + scale[0:k - 2].to_owned()
    }
  } else {
    let head_word = self.sv_below1000(head)
    if power == 1 {
      left = head_word + scale
    } else {
      left = head_word + " " + scale
    }
  }
  if rest == BigInt::from_int(0) {
    return left
  }
  let tail = self.sv_rec(rest)
  if rest < BigInt::from_int(100) {
    left + tail
  } else {
    left + " " + tail
  }
}

///|
fn Lang::cardinal_sv(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  if n < BigInt::from_int(0) {
    return self.negative + " " + self.sv_rec(-n)
  }
  self.sv_rec(n)
}

// --- ordinals ---------------------------------------------------------------

///|
/// Upstream `ords` table. The last 4 or 3 characters of the final word are
/// looked up here; "tjugo" is unreachable through those suffixes (20 becomes
/// "tjugo" + "de"), but it is kept to mirror the source table.
fn sv_ord_word(k : String) -> String? {
  match k {
    "noll" => Some("nollte")
    "ett" => Some("första")
    "två" => Some("andra")
    "tre" => Some("tredje")
    "fyra" => Some("fjärde")
    "fem" => Some("femte")
    "sex" => Some("sjätte")
    "sju" => Some("sjunde")
    "åtta" => Some("åttonde")
    "nio" => Some("nionde")
    "tio" => Some("tionde")
    "elva" => Some("elfte")
    "tolv" => Some("tolfte")
    "tjugo" => Some("tjugonde")
    _ => None
  }
}

///|
/// Rewrite the last word: try its 4-character ending, then its 3-character
/// ending, and otherwise append "de" (100 -> "etthundrade", 1000 ->
/// "etttusende").
fn sv_ordinalize(w : String) -> String {
  let n = w.length()
  if n >= 4 {
    match sv_ord_word(w[n - 4:n].to_owned()) {
      Some(e) => return w[0:n - 4].to_owned() + e
      None => ()
    }
  }
  if n >= 3 {
    match sv_ord_word(w[n - 3:n].to_owned()) {
      Some(e) => return w[0:n - 3].to_owned() + e
      None => ()
    }
  }
  w + "de"
}

///|
pub fn ordinal_sv(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises TypeError for negative ordinals.
    return ""
  }
  let card = lang_sv().cardinal_sv(n)
  if card == "" {
    return ""
  }
  let words = split_to_array(card, " ")
  let last = words.length() - 1
  words[last] = sv_ordinalize(words[last])
  join_parts(words, " ")
}

///|
/// Upstream raises NotImplementedError for Swedish `ordinal_num`.
pub fn ordinal_num_sv(_n : BigInt) -> String {
  ""
}

///|
/// Upstream raises NotImplementedError for Swedish `year`.
pub fn year_sv(_n : BigInt) -> String {
  ""
}
