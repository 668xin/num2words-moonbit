// lang_is.mbt — Icelandic cardinal spelling.
//
// Faithful port of upstream num2words 0.5.14 `lang_IS.py`, which builds on the
// generic `lang_EU` split/merge engine rather than on 3-digit groups:
//   * `splitnum` decomposes the value greedily with the largest card not
//     exceeding it, then `merge` joins the pieces left to right;
//   * a lone unit in front of a hundred/thousand/scale word is skipped
//     ("eitt hundrað", not "einn eitt hundrað"), and the multiplier agrees in
//     gender: neuter before `hundrað`/`þúsund`, masculine before `-illjarður`,
//     feminine before `-illjón` ("tvö hundruð", "tvær milljónir");
//   * "og" is inserted only when the right side is a single card
//     ("tuttugu og einn", "eitt hundrað og einn") and omitted before a
//     composed right side ("eitt hundrað tuttugu og einn");
//   * scale words take their plural from the multiplier:
//     "milljónir", "milljarðar", "hundruð", "oktilljónir", ...;
//   * decimals are spelled digit by digit after "komma", and negative values
//     take the prefix "mínus ".
//
// Upstream raises NotImplementedError for ordinals, `ordinal_num`, years and
// currency, so this port returns "" for those modes (like Czech/Slovak).

///|
/// Scale words, index = group power of 1000. Its length (18) caps the
/// supported range at 10^54, matching upstream's MAXVAL.
let is_thousands : Array[String] = [
  "", "þúsund", "milljón", "milljarður", "billjón", "billjarður", "trilljón",
  "trilljarður", "kvaðrilljón", "kvaðrilljarður", "kvintilljón", "kvintilljarður",
  "sextilljón", "sextilljarður", "septilljón", "septilljarður", "oktilljón",
  "oktilljarður",
]

///|
/// Small cards (100 down to 0) in the order the upstream `cards` mapping keeps
/// them. Only values that are themselves cards allow the `og` separator.
let is_small_cards : Array[(Int, String)] = [
  (100, "hundrað"),
  (90, "níutíu"),
  (80, "áttatíu"),
  (70, "sjötíu"),
  (60, "sextíu"),
  (50, "fimmtíu"),
  (40, "fjörutíu"),
  (30, "þrjátíu"),
  (20, "tuttugu"),
  (19, "nítján"),
  (18, "átján"),
  (17, "sautján"),
  (16, "sextán"),
  (15, "fimmtán"),
  (14, "fjórtán"),
  (13, "þrettán"),
  (12, "tólf"),
  (11, "ellefu"),
  (10, "tíu"),
  (9, "níu"),
  (8, "átta"),
  (7, "sjö"),
  (6, "sex"),
  (5, "fimm"),
  (4, "fjórir"),
  (3, "þrír"),
  (2, "tveir"),
  (1, "einn"),
  (0, "núll"),
]

///|
/// The split/merge tree built by `splitnum`.
priv enum IsTree {
  IsAtom(String, BigInt)
  IsList(Array[IsTree])
}

///|
fn is_pow10(k : Int) -> BigInt {
  let ten = BigInt::from_int(10)
  let mut r = BigInt::from_int(1)
  for i = 0; i < k; i = i + 1 {
    r = r * ten
  }
  r
}

///|
/// The card table in decreasing order: 10^51 ... 10^3, then 100 down to 0.
fn is_cards() -> Array[(BigInt, String)] {
  let out : Array[(BigInt, String)] = []
  for p = 17; p >= 1; p = p - 1 {
    out.push((is_pow10(3 * p), is_thousands[p]))
  }
  for i = 0; i < is_small_cards.length(); i = i + 1 {
    let (v, t) = is_small_cards[i]
    out.push((BigInt::from_int(v), t))
  }
  out
}

///|
/// True when `s` contains `sub` as a substring.
fn is_contains(s : String, sub : String) -> Bool {
  let n = s.length()
  let m = sub.length()
  if m == 0 {
    return true
  }
  if m > n {
    return false
  }
  let mut i = 0
  while i + m <= n {
    if s[i:i + m].to_owned() == sub {
      return true
    }
    i = i + 1
  }
  false
}

///|
/// Replace every occurrence of `from` with `to`.
fn is_replace_all(s : String, from : String, to : String) -> String {
  let n = s.length()
  let m = from.length()
  if m == 0 {
    return s
  }
  let mut out = ""
  let mut i = 0
  while i < n {
    if i + m <= n && s[i:i + m].to_owned() == from {
      out = out + to
      i = i + m
    } else {
      out = out + s[i:i + 1].to_owned()
      i = i + 1
    }
  }
  out
}

///|
fn is_card_member(n : BigInt, cards : Array[(BigInt, String)]) -> Bool {
  for i = 0; i < cards.length(); i = i + 1 {
    let (v, _) = cards[i]
    if v == n {
      return true
    }
  }
  false
}

///|
/// Upstream `splitnum`: greedy decomposition into (text, value) atoms.
fn is_splitnum(
  value : BigInt,
  cards : Array[(BigInt, String)],
) -> Array[IsTree] {
  let one = BigInt::from_int(1)
  let zero = BigInt::from_int(0)
  for i = 0; i < cards.length(); i = i + 1 {
    let (elem, text) = cards[i]
    if elem > value {
      continue
    }
    let out : Array[IsTree] = []
    let (div, md) = if value == zero {
      (one, zero)
    } else {
      (value / elem, value % elem)
    }
    if div == one {
      out.push(IsAtom("einn", one))
    } else {
      out.push(IsList(is_splitnum(div, cards)))
    }
    out.push(IsAtom(text, elem))
    if md != zero {
      out.push(IsList(is_splitnum(md, cards)))
    }
    return out
  }
  []
}

///|
/// Upstream `pluralize`: a multiplier ending in 1 (but not 11) keeps the
/// singular noun; every other multiplier pluralises it.
fn is_pluralize(n : BigInt, noun : String) -> String {
  let ten = BigInt::from_int(10)
  let hundred = BigInt::from_int(100)
  if n % ten == BigInt::from_int(1) && n % hundred != BigInt::from_int(11) {
    return noun
  }
  if is_contains(noun, "illjarður") {
    return is_replace_all(noun, "illjarður", "illjarðar")
  }
  if is_contains(noun, "illjón") {
    return is_replace_all(noun, "illjón", "illjónir")
  }
  if noun == "hundrað" {
    return "hundruð"
  }
  noun
}

///|
/// Upstream `genderize`: the four gendered numerals agree with the following
/// noun. Neuter for hundrað/þúsund, masculine for -illjarður, feminine for
/// -illjón.
fn is_genderize(adj : String, noun : String) -> String {
  let words = split_to_array(adj, " ")
  let last = words[words.length() - 1]
  let mut masculine = ""
  let mut feminine = ""
  let mut neuter = ""
  if last == "einn" {
    masculine = "einn"
    feminine = "ein"
    neuter = "eitt"
  } else if last == "tveir" {
    masculine = "tveir"
    feminine = "tvær"
    neuter = "tvö"
  } else if last == "þrír" {
    masculine = "þrír"
    feminine = "þrjár"
    neuter = "þrjú"
  } else if last == "fjórir" {
    masculine = "fjórir"
    feminine = "fjórar"
    neuter = "fjögur"
  } else {
    return adj
  }
  let repl = if is_contains(noun, "hund") || is_contains(noun, "þús") {
    neuter
  } else if is_contains(noun, "illjarð") {
    masculine
  } else if is_contains(noun, "illjón") {
    feminine
  } else {
    masculine
  }
  is_replace_all(adj, last, repl)
}

///|
/// Upstream `merge`.
fn is_merge(
  ltext : String,
  lnum : BigInt,
  rtext : String,
  rnum : BigInt,
  cards : Array[(BigInt, String)],
) -> (String, BigInt) {
  let one = BigInt::from_int(1)
  if lnum == one && rnum < BigInt::from_int(100) {
    (rtext, rnum)
  } else if lnum < rnum {
    let r2 = is_pluralize(lnum, rtext)
    let l2 = is_genderize(ltext, r2)
    (l2 + " " + r2, lnum * rnum)
  } else if lnum > rnum && is_card_member(rnum, cards) {
    let r2 = is_pluralize(lnum, rtext)
    let l2 = is_genderize(ltext, r2)
    (l2 + " og " + r2, lnum + rnum)
  } else {
    (ltext + " " + rtext, lnum + rnum)
  }
}

///|
/// Upstream `clean`: fold the split tree left to right with `merge`.
fn is_clean(
  val : Array[IsTree],
  cards : Array[(BigInt, String)],
) -> (String, BigInt) {
  let mut cur = val
  while cur.length() != 1 {
    let out : Array[IsTree] = []
    let both_atoms = match (cur[0], cur[1]) {
      (IsAtom(_, _), IsAtom(_, _)) => true
      _ => false
    }
    if both_atoms {
      let (lt, ln) = match cur[0] {
        IsAtom(t, n) => (t, n)
        _ => ("", BigInt::from_int(0))
      }
      let (rt, rn) = match cur[1] {
        IsAtom(t, n) => (t, n)
        _ => ("", BigInt::from_int(0))
      }
      let (t, n) = is_merge(lt, ln, rt, rn, cards)
      out.push(IsAtom(t, n))
      for i = 2; i < cur.length(); i = i + 1 {
        out.push(cur[i])
      }
    } else {
      for i = 0; i < cur.length(); i = i + 1 {
        match cur[i] {
          IsList(inner) =>
            if inner.length() == 1 {
              out.push(inner[0])
            } else {
              let (t, n) = is_clean(inner, cards)
              out.push(IsAtom(t, n))
            }
          _ => out.push(cur[i])
        }
      }
    }
    cur = out
  }
  match cur[0] {
    IsAtom(t, n) => (t, n)
    _ => ("", BigInt::from_int(0))
  }
}

///|
pub fn lang_is() -> Lang {
  {
    variant: Is,
    zero: "núll",
    ones: [
      "núll", "einn", "tveir", "þrír", "fjórir", "fimm", "sex", "sjö", "átta",
      "níu",
    ],
    teens: [
      "tíu", "ellefu", "tólf", "þrettán", "fjórtán", "fimmtán", "sextán",
      "sautján", "átján", "nítján",
    ],
    tens: [
      "", "tíu", "tuttugu", "þrjátíu", "fjörutíu", "fimmtíu", "sextíu", "sjötíu",
      "áttatíu", "níutíu",
    ],
    hundred: "hundrað",
    thousands: is_thousands,
    negative: "mínus",
    decimal: "komma",
    comma_sep: false,
  }
}

///|
fn Lang::cardinal_is(self : Lang, n : BigInt) -> String {
  let neg = n < BigInt::from_int(0)
  let abs_n = if neg { -n } else { n }
  if abs_n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(abs_n) {
    return ""
  }
  let cards = is_cards()
  let (text, _) = is_clean(is_splitnum(abs_n, cards), cards)
  if neg {
    self.negative + " " + text
  } else {
    text
  }
}
