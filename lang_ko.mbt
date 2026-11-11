// lang_ko.mbt — Korean number spelling (cardinal, ordinal, year).
//
// Korean groups digits by 10^4 and separates groups with a space:
// 12345 -> "만 이천삼백사십오". `일` is dropped before a leading 십/백/천 and
// before a lone 만 (10000 -> 만), but kept before 억/조 (10^8 -> 일억).
//
// Ordinals reuse the native counters (한/두/세 ... 열/스물/서른 ...) and
// reproduce upstream's quirks: values whose last word is a bare hundred,
// 천, 만 or an unsupported morpheme raise KeyError upstream and return ""
// here (100, 1000, 10000, 1100, ...).
//
// Ported from num2words 0.5.14 lang_KO.py.

///|
let ko_scale : Array[String] = [
  "", "만", "억", "조", "경", "해", "자", "양", "구", "간", "정", "재",
  "극", "항하사", "아승기", "나유타", "불가사의", "무량대수",
]

///|
pub fn lang_ko() -> Lang {
  {
    variant: Ko,
    zero: "영",
    ones: ["영", "일", "이", "삼", "사", "오", "육", "칠", "팔", "구"],
    teens: [],
    tens: [],
    hundred: "백",
    thousands: ko_scale,
    negative: "마이너스",
    decimal: "점",
    comma_sep: false,
  }
}

///|
/// Spell a 1..9999 group, omitting a leading `일` before 십/백/천.
fn Lang::ko_group_under_10000(self : Lang, g : Int) -> String {
  let th = g / 1000
  let hu = g / 100 % 10
  let te = g / 10 % 10
  let on = g % 10
  let mut out = ""
  if th > 0 {
    if th > 1 {
      out = out + self.ones[th]
    }
    out = out + "천"
  }
  if hu > 0 {
    if hu > 1 {
      out = out + self.ones[hu]
    }
    out = out + "백"
  }
  if te > 0 {
    if te > 1 {
      out = out + self.ones[te]
    }
    out = out + "십"
  }
  if on > 0 {
    out = out + self.ones[on]
  }
  out
}

///|
fn Lang::cardinal_ko(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let abs_n = if neg { -n } else { n }
  let groups = group4(abs_n)
  let mut out = ""
  let mut first = true
  for i = 0; i < groups.length(); i = i + 1 {
    let (raw, power) = groups[i]
    let g = raw.to_int()
    if g == 0 {
      continue
    }
    if !first {
      out = out + " "
    }
    // 10000 reads 만, not 일만; 억 and above keep the 일 (일억).
    if !(power == 1 && g == 1) {
      out = out + self.ko_group_under_10000(g)
    }
    if power > 0 {
      out = out + self.thousands[power]
    }
    first = false
  }
  if neg {
    self.negative + " " + out
  } else {
    out
  }
}

// --- ordinals ---------------------------------------------------------------

///|
/// Native-counter morphemes used by upstream's ordinal rewrite.
fn ko_ord_word(w : String) -> String? {
  match w {
    "일" => Some("한")
    "이" => Some("두")
    "삼" => Some("세")
    "사" => Some("네")
    "오" => Some("다섯")
    "육" => Some("여섯")
    "칠" => Some("일곱")
    "팔" => Some("여덟")
    "구" => Some("아홉")
    "십" => Some("열")
    "이십" => Some("스물")
    "삼십" => Some("서른")
    "사십" => Some("마흔")
    "오십" => Some("쉰")
    "육십" => Some("예순")
    "칠십" => Some("일흔")
    "팔십" => Some("여든")
    "구십" => Some("아흔")
    _ => None
  }
}

///|
fn ko_replace(s : String, from : String, to : String) -> String {
  join_parts(split_to_array(s, from), to)
}

///|
/// 1 -> 첫 번째, 11 -> 열한 번째, 101 -> 백 한 번째. Values upstream cannot
/// rewrite (100, 1000, 10000, 1100, ...) return "".
pub fn ordinal_ko(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  if n == BigInt::from_int(1) {
    return "첫 번째"
  }
  let card = lang_ko().cardinal_ko(n)
  if card == "" {
    return ""
  }
  let outwords = split_to_array(card, " ")
  let last = outwords.length() - 1
  let parts = split_to_array(outwords[last], "백")
  let tail = parts[parts.length() - 1]
  let new_tail = if tail.contains("십") {
    let bits = split_to_array(tail, "십")
    let first = match ko_ord_word(bits[0] + "십") {
      Some(w) => w
      None => return ""
    }
    let mut joined = ko_replace(first, "스무", "스물")
    // Upstream wraps the second morpheme in try/except KeyError: an unknown
    // tail is left unchanged rather than aborting.
    joined = joined +
      (match ko_ord_word(bits[1]) {
        Some(w) => w
        None => bits[1]
      })
    for i = 2; i < bits.length(); i = i + 1 {
      joined = joined + "십" + bits[i]
    }
    joined
  } else {
    match ko_ord_word(tail) {
      Some(w) => w
      None => return ""
    }
  }
  parts[parts.length() - 1] = new_tail
  outwords[last] = join_parts(parts, "백 ")
  join_parts(outwords, " ") + " 번째"
}

///|
/// `N 번째`: 1 -> 1 번째.
pub fn ordinal_num_ko(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  n.to_string() + " 번째"
}

///|
/// 2024 -> 이천이십사년, -44 -> 기원전 사십사년.
pub fn year_ko(n : BigInt) -> String {
  let l = lang_ko()
  if n < BigInt::from_int(0) {
    "기원전 " + l.cardinal_ko(-n) + "년"
  } else {
    l.cardinal_ko(n) + "년"
  }
}
