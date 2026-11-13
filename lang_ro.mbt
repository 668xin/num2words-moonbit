// lang_ro.mbt — Romanian number spelling (cardinal, ordinal, year, currency).
//
// Port of upstream num2words 0.5.14 `lang_RO.py`. Instead of a hand-written
// group spelling, this file reproduces upstream's recursive
// `splitnum` + `clean` + `merge` machinery, because Romanian's output depends
// on it in non-obvious ways:
//
//   * 100 and 1000 have three forms selected by the group value
//     ("o sută", "două sute", "douăzeci de mii");
//   * the million words alternate between -ilion (no slash in the table) and
//     -iliard/e (stored with a slash), and `merge` sometimes skips the
//     inflection, so a small multiplier can leave the raw table entry in the
//     output (10^15 -> "biliard/e", 2*10^15 -> "biliard/e");
//   * `clean` re-nests the operand list for groups shaped like "hundreds +
//     sub-20", which feeds a different `side_effect` into `inflect`:
//     110000 -> "o sută zece de mii" while 11000 -> "unsprezece mii";
//   * a multiplier ending in 2 below 100 switches "doi" to "două"
//     (12000 -> "douăsprezece mii", 22000 -> "douăzeci și două de mii");
//   * `to_currency` renders the amount with the same machinery after swapping
//     the multiplier 1 for "una" ("una sută unu lei", "una mie de lei") and
//     then rewrites "unu leu"/"unu ban" to "un leu"/"un ban" and drops
//     " și zero bani".
//
// Deviations: negative ordinals raise upstream and return "" here; magnitudes
// past the highest table entry (10^39, so values from 10^42) report "" instead
// of raising OverflowError; upstream's currency `IndexError` for two-form
// code/amount pairs is replaced by a normal plural form.

// --- word tables ------------------------------------------------------------

///|
let ro_ones : Array[String] = [
  "zero", "unu", "doi", "trei", "patru", "cinci", "șase", "șapte", "opt", "nouă",
]

///|
let ro_teens : Array[String] = [
  "zece", "unsprezece", "doisprezece", "treisprezece", "paisprezece", "cincisprezece",
  "șaisprezece", "șaptesprezece", "optsprezece", "nouăsprezece",
]

///|
let ro_tens : Array[String] = [
  "", "", "douăzeci", "treizeci", "patruzeci", "cincizeci", "șaizeci", "șaptezeci",
  "optzeci", "nouăzeci",
]

///|
/// Multiplier words used in front of 100 and 1000 (`gen_numwords`).
let ro_gen : Array[String] = [
  "", "o", "două", "trei", "patru", "cinci", "șase", "șapte", "opt", "nouă",
]

///|
/// Multiplier words used in front of the million words (`gen_numwords_n`).
let ro_gen_n : Array[String] = [
  "", "un", "două", "trei", "patru", "cinci", "șase", "șapte", "opt", "nouă",
]

///|
/// Latin base of the -ilion/-iliard scale words (upstream `lang_EU` high
/// number words filtered through `lang_RO.MEGA_SUFFIX`).
let ro_bases : Array[String] = [
  "", "", "m", "m", "b", "b", "tr", "tr", "quadr", "quadr", "quint", "quint", "sext",
  "sext",
]

///|
/// Scale words for `Lang.thousands` (index = power of 1000); only the length
/// is used by `supports`.
fn ro_thousands() -> Array[String] {
  [
    "", "mie", "milion", "miliard", "bilion", "biliard", "trilion", "triliard", "quadrilion",
    "quadriliard", "quintilion", "quintiliard", "sextilion", "sextiliard",
  ]
}

///|
pub fn lang_ro() -> Lang {
  {
    variant: Ro,
    zero: "zero",
    ones: ro_ones,
    teens: ro_teens,
    tens: ro_tens,
    hundred: "sută",
    thousands: ro_thousands(),
    negative: "minus",
    decimal: "virgulă",
    comma_sep: false,
  }
}

// --- upstream merge machinery -----------------------------------------------

///|
/// Upstream's card table, ordered from the largest key down to 0. Each entry
/// is (value, word); the giga scale words keep the "/e" slash because
/// upstream's table does.
fn ro_cards() -> Array[(BigInt, String)] {
  let cards : Array[(BigInt, String)] = []
  let thousand = BigInt::from_int(1000)
  let mut key = BigInt::from_int(1)
  for i = 0; i < 39; i = i + 1 {
    key = key * BigInt::from_int(10)
  }
  for p = 13; p >= 2; p = p - 1 {
    let base = ro_bases[p]
    let word = if p % 2 == 0 { base + "ilion" } else { base + "iliard/e" }
    cards.push((key, word))
    key = key / thousand
  }
  cards.push((BigInt::from_int(1000), "mie/i"))
  cards.push((BigInt::from_int(100), "sută/e"))
  for d = 9; d >= 3; d = d - 1 {
    cards.push((BigInt::from_int(d * 10), ro_tens[d]))
  }
  cards.push((BigInt::from_int(20), ro_tens[2]))
  for v = 19; v >= 11; v = v - 1 {
    cards.push((BigInt::from_int(v), ro_teens[v - 10]))
  }
  cards.push((BigInt::from_int(10), "zece"))
  for v = 9; v >= 0; v = v - 1 {
    cards.push((BigInt::from_int(v), ro_ones[v]))
  }
  cards
}

///|
/// Intermediate value of upstream's `splitnum`/`clean` recursion: either a
/// (word, number) token or a nested list.
priv enum RoNode {
  Tok(String, BigInt)
  Lst(Array[RoNode])
}

///|
/// Upstream `pluralize` for the scale nouns (0 = one, 1 = 1..19 and zero,
/// 2 = everything else). The argument can be a large product of groups.
fn ro_plural_big(n : BigInt) -> Int {
  if n == BigInt::from_int(1) {
    return 0
  }
  let m = n % BigInt::from_int(100)
  if n == BigInt::from_int(0) ||
    (m > BigInt::from_int(0) && m < BigInt::from_int(20)) {
    1
  } else {
    2
  }
}

///|
/// The four keys of upstream `numwords_inflections`; only those trigger the
/// multiplier branch of `merge`.
fn ro_infl_has(rnum : BigInt) -> Bool {
  rnum == BigInt::from_int(100) ||
  rnum == BigInt::from_int(1000) ||
  rnum == BigInt::from_int(1000000) ||
  rnum == BigInt::from_int(1000000000)
}

///|
fn ro_replace(s : String, from : String, to : String) -> String {
  join_parts(split_to_array(s, from), to)
}

///|
/// Upstream `inflect(value, text, side_effect)`: pick one of the slash-separated
/// forms and, for a multiplier above 1, switch a million word to its
/// "-ilioane"/"-iliarde" form.
fn ro_inflect(_value : BigInt, text : String, side : BigInt) -> String {
  let parts = split_to_array(text, "/")
  let mut result = parts[0]
  if parts.length() > 1 {
    let stem = parts[0][0:parts[0].length() - 1].to_owned() + parts[1]
    result = match ro_plural_big(side) {
      0 => parts[0]
      1 => stem
      _ => "de " + stem
    }
  }
  if side > BigInt::from_int(1) && ends_with(result, "ilion") {
    result = result[0:result.length() - 5].to_owned() + "ilioane"
  } else if side > BigInt::from_int(1) && ends_with(result, "iliare") {
    result = result[0:result.length() - 6].to_owned() + "iliarde"
  }
  result
}

///|
/// Upstream `merge(lpair, rpair)`; `una` switches the `gen_numwords[1]`
/// multiplier to "una" (used by `to_currency`).
fn ro_merge(
  ltext : String,
  lnum : BigInt,
  rtext : String,
  rnum : BigInt,
  una : Bool,
) -> RoNode {
  let one = BigInt::from_int(1)
  let ten = BigInt::from_int(10)
  let hundred = BigInt::from_int(100)
  let mut rtext_i = ro_inflect(rnum, rtext, lnum)
  if lnum >= one && lnum < ten {
    if !ro_infl_has(rnum) {
      return Tok(rtext, rnum)
    }
    rtext_i = ro_inflect(lnum * rnum, rtext, lnum)
    let idx = lnum.to_int()
    let word = if rnum == hundred || rnum == BigInt::from_int(1000) {
      if idx == 1 && una {
        "una"
      } else {
        ro_gen[idx]
      }
    } else {
      ro_gen_n[idx]
    }
    Tok(word + " " + rtext_i, rnum)
  } else if lnum > ten && lnum < hundred {
    if lnum % ten == BigInt::from_int(0) {
      if ro_infl_has(rnum) {
        rtext_i = ro_inflect(lnum * rnum, rtext, lnum)
        Tok(ltext + " " + rtext_i, lnum * rnum)
      } else {
        Tok(ltext + " și " + rtext, lnum + rnum)
      }
    } else {
      rtext_i = ro_inflect(lnum * rnum, rtext, lnum)
      let ltext_i = if lnum % ten == BigInt::from_int(2) {
        ro_replace(ltext, "doi", "două")
      } else {
        ltext
      }
      Tok(ltext_i + " " + rtext_i, lnum * rnum)
    }
  } else {
    if ro_infl_has(rnum) {
      rtext_i = ro_inflect(lnum * rnum, rtext, lnum)
    }
    Tok(ltext + " " + rtext_i, lnum * rnum)
  }
}

///|
/// Upstream `splitnum(value)` for a positive value: the greedy decomposition
/// into (word, number) tokens and nested lists.
fn ro_split(value : BigInt) -> Array[RoNode] {
  let cards = ro_cards()
  let one = BigInt::from_int(1)
  for i = 0; i < cards.length(); i = i + 1 {
    let (elem, word) = cards[i]
    if elem > value {
      continue
    }
    let div = value / elem
    let mod = value % elem
    let out : Array[RoNode] = []
    if div == one {
      out.push(Tok("unu", one))
    } else {
      out.push(Lst(ro_split(div)))
    }
    out.push(Tok(word, elem))
    if mod != BigInt::from_int(0) {
      out.push(Lst(ro_split(mod)))
    }
    return out
  }
  [Tok("zero", BigInt::from_int(0))]
}

///|
/// Upstream `clean(val)`, whose list flattening is observable: a list with
/// three or more elements re-nests the tail, which later changes the
/// `side_effect` passed to `inflect`.
fn ro_clean(val : Array[RoNode], una : Bool) -> RoNode {
  let mut current = val
  while current.length() != 1 {
    let out : Array[RoNode] = []
    match (current[0], current[1]) {
      (Tok(lw, ln), Tok(rw, rn)) => {
        out.push(ro_merge(lw, ln, rw, rn, una))
        if current.length() > 2 {
          let tail : Array[RoNode] = []
          for k = 2; k < current.length(); k = k + 1 {
            tail.push(current[k])
          }
          out.push(Lst(tail))
        }
      }
      _ =>
        for k = 0; k < current.length(); k = k + 1 {
          match current[k] {
            Lst(inner) =>
              if inner.length() == 1 {
                out.push(inner[0])
              } else {
                out.push(ro_clean(inner, una))
              }
            _ => out.push(current[k])
          }
        }
    }
    current = out
  }
  match current[0] {
    Tok(_, _) => current[0]
    Lst(inner) => ro_clean(inner, una)
  }
}

///|
/// Spell one non-negative value with upstream's recursion. `una` selects the
/// currency multiplier mode.
fn ro_card_with(n : BigInt, una : Bool) -> String {
  if n == BigInt::from_int(0) {
    return "zero"
  }
  match ro_clean(ro_split(n), una) {
    Tok(w, _) => w
    Lst(inner) =>
      match ro_clean(inner, una) {
        Tok(w, _) => w
        Lst(_) => ""
      }
  }
}

///|
fn Lang::cardinal_ro(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let v = if neg { -n } else { n }
  let words = ro_card_with(v, false)
  if neg {
    self.negative + " " + words
  } else {
    words
  }
}

///|
/// Cardinal with the currency multiplier mode (upstream swaps `gen_numwords[1]`
/// for "una" during `to_currency`). Only called by `currency_ro`.
fn Lang::cardinal_ro_currency(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  ro_card_with(n, true)
}

// --- ordinal ----------------------------------------------------------------

///|
/// Upstream `to_ordinal`: 1 -> "primul", otherwise "al <cardinal>lea"
/// (2 -> "al doilea", 100 -> "al o sutălea").
pub fn ordinal_ro(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream `verify_ordinal` raises TypeError.
    return ""
  }
  if n == BigInt::from_int(1) {
    return "primul"
  }
  if !lang_ro().supports(n) {
    return ""
  }
  "al " + lang_ro().cardinal_ro(n) + "lea"
}

///|
/// Upstream `to_ordinal_num`: 1 -> "1-ul", otherwise "al <n>-lea".
pub fn ordinal_num_ro(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  if n == BigInt::from_int(1) {
    return "1-ul"
  }
  "al " + n.to_string() + "-lea"
}

// --- year -------------------------------------------------------------------

///|
/// Upstream `to_year` is the plain cardinal; negative years lose the "minus"
/// word and take the era suffix "î.Hr." instead (-44 -> "patruzeci și patru
/// î.Hr.").
pub fn year_ro(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    lang_ro().cardinal_ro(-n) + " î.Hr."
  } else {
    lang_ro().cardinal_ro(n)
  }
}

// --- currency ---------------------------------------------------------------

///|
/// Noun forms for the 20 EU codes upstream's Romanian converter accepts.
/// Every tuple is (unit one/few/many, cent one/few/many); two-form codes repeat
/// the plural in the last slot.
fn ro_currency_forms(
  code : String,
) -> Result[(String, String, String, String, String, String), String] {
  match code {
    "AUD" => Ok(("dollar", "dollars", "dollars", "cent", "cents", "cents"))
    "BYN" => Ok(("rouble", "roubles", "roubles", "kopek", "kopeks", "kopeks"))
    "CAD" => Ok(("dollar", "dollars", "dollars", "cent", "cents", "cents"))
    "EEK" => Ok(("kroon", "kroons", "kroons", "sent", "senti", "senti"))
    "EUR" => Ok(("euro", "euro", "euro", "cent", "cents", "cents"))
    "GBP" =>
      Ok(
        (
          "pound sterling", "pounds sterling", "pounds sterling", "penny", "pence",
          "pence",
        ),
      )
    "LTL" => Ok(("litas", "litas", "litas", "cent", "cents", "cents"))
    "LVL" => Ok(("lat", "lats", "lats", "santim", "santims", "santims"))
    "USD" => Ok(("dollar", "dollars", "dollars", "cent", "cents", "cents"))
    "RUB" => Ok(("rouble", "roubles", "roubles", "kopek", "kopeks", "kopeks"))
    "SEK" => Ok(("krona", "kronor", "kronor", "öre", "öre", "öre"))
    "NOK" => Ok(("krone", "kroner", "kroner", "øre", "øre", "øre"))
    "PLN" => Ok(("zloty", "zlotys", "zlotu", "grosz", "groszy", "groszy"))
    "MXN" => Ok(("peso", "pesos", "pesos", "cent", "cents", "cents"))
    "RON" => Ok(("leu", "lei", "de lei", "ban", "bani", "de bani"))
    "INR" => Ok(("rupee", "rupees", "rupees", "paisa", "paise", "paise"))
    "HUF" => Ok(("forint", "forint", "forint", "fillér", "fillér", "fillér"))
    "ISK" => Ok(("króna", "krónur", "krónur", "aur", "aurar", "aurar"))
    "UZS" => Ok(("sum", "sums", "sums", "tiyin", "tiyins", "tiyins"))
    "SAR" =>
      Ok(
        (
          "saudi riyal", "saudi riyals", "saudi riyals", "halalah", "halalas", "halalas",
        ),
      )
    _ => Err(code)
  }
}

///|
fn ro_currency_pick(
  one : String,
  few : String,
  many : String,
  idx : Int,
) -> String {
  if idx == 0 {
    one
  } else if idx == 1 {
    few
  } else {
    many
  }
}

///|
/// Romanian currency spelling ("<units> lei și <cents> bani"), with upstream's
/// "una"-multiplier mode and its three post-processing replacements.
fn currency_ro(
  units : BigInt,
  cents : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  let l = lang_ro()
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let (u1, u2, u3, c1, c2, c3) = match ro_currency_forms(code) {
    Err(c) => return Err("currency code not supported for ro: " + c)
    Ok(forms) => forms
  }
  let unit = ro_currency_pick(u1, u2, u3, ro_plural_big(units))
  let cent = ro_currency_pick(c1, c2, c3, ro_plural_big(cents))
  let mut out = l.cardinal_ro_currency(units) +
    " " +
    unit +
    " și " +
    l.cardinal_ro_currency(cents) +
    " " +
    cent
  out = ro_replace(out, "unu leu", "un leu")
  out = ro_replace(out, "unu ban", "un ban")
  out = ro_replace(out, " și zero bani", "")
  if neg {
    Ok("minus " + out)
  } else {
    Ok(out)
  }
}
