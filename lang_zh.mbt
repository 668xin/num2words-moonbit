// lang_zh.mbt — Chinese number spelling (Simplified `zh`, Traditional `zh_TW`).
//
// Chinese (like Japanese and Korean) advances its scale words by 10^4, not
// 10^3: 12345 -> 一万二千三百四十五. A `零` is inserted when a group below
// 1000 follows a higher group (10001 -> 一万零一), and a leading `一十` drops
// its `一` (10 -> 十, 100000 -> 十万).
//
// Upstream num2words 0.5.14 has no Chinese module; this implementation follows
// the `lang_ZH.py` added on upstream master after 0.5.14 (traditional
// characters) and provides the Simplified variant alongside it. Both share
// the same grammar; only the word tables differ. See COMPAT.md §3.
//
// Supported modes: cardinal, ordinal (第…), ordinal_num (第123), year
// (digit-by-digit, 二零二四年) and currency (元/角/分).

///|
/// Scale words, index = power of 10^4 (1 -> 10^4). Simplified forms.
let zh_scale_simpl : Array[String] = [
  "", "万", "亿", "兆", "京", "垓", "秭", "穰", "沟", "涧", "正", "载",
  "极", "恒河沙", "阿僧祇", "那由他", "不可思议", "无量", "不可说",
]

///|
/// Scale words, index = power of 10^4. Traditional forms (upstream master).
let zh_scale_trad : Array[String] = [
  "", "萬", "億", "兆", "京", "垓", "秭", "穣", "溝", "澗", "正", "載",
  "極", "恆河沙", "阿僧祇", "那由他", "不可思議", "無量", "不可說",
]

///|
/// Place words for the four digits of a group, most significant first.
fn zh_place(i : Int) -> String {
  if i == 0 {
    "千"
  } else if i == 1 {
    "百"
  } else if i == 2 {
    "十"
  } else {
    ""
  }
}

///|
/// Simplified Chinese word tables.
pub fn lang_zh() -> Lang {
  {
    variant: Zh,
    zero: "零",
    ones: ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"],
    teens: [],
    tens: [],
    hundred: "百",
    thousands: zh_scale_simpl,
    negative: "负",
    decimal: "点",
    comma_sep: false,
  }
}

///|
/// Traditional Chinese word tables.
pub fn lang_zh_tw() -> Lang {
  {
    variant: ZhTw,
    zero: "零",
    ones: ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"],
    teens: [],
    tens: [],
    hundred: "百",
    thousands: zh_scale_trad,
    negative: "負",
    decimal: "點",
    comma_sep: false,
  }
}

///|
/// Spell a 1..9999 group. `drop_leading_one` removes the `一` of a leading
/// `一十` (10 -> 十); zeros between spoken digits collapse to a single `零`.
fn Lang::zh_group_under_10000(
  self : Lang,
  g : Int,
  drop_leading_one : Bool,
) -> String {
  let digits : Array[Int] = [g / 1000, g / 100 % 10, g / 10 % 10, g % 10]
  let mut out = ""
  let mut started = false
  let mut gap = false
  for i = 0; i < 4; i = i + 1 {
    let d = digits[i]
    if d == 0 {
      if started {
        gap = true
      }
      continue
    }
    if gap {
      out = out + self.ones[0]
      gap = false
    }
    let omit_one = drop_leading_one && !started && i == 2 && d == 1
    if omit_one {
      out = out + zh_place(i)
    } else {
      out = out + self.ones[d] + zh_place(i)
    }
    started = true
  }
  out
}

///|
fn cardinal_zh_impl(l : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return l.zero
  }
  if !l.supports(n) {
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
    // A gap below 1000 in the current group needs a spoken `零`
    // (一万零一 / 一万零一百), while a gap of a whole 万 group does not
    // (一亿一千).
    if !first && g < 1000 {
      out = out + l.ones[0]
    }
    // Upstream strips a leading `一十` only after the whole output has been
    // assembled, so a negative number keeps it (负一十二万...).
    out = out + l.zh_group_under_10000(g, first && !neg)
    if power > 0 {
      out = out + l.thousands[power]
    }
    first = false
  }
  if neg {
    l.negative + out
  } else {
    out
  }
}

///|
fn Lang::cardinal_zh(self : Lang, n : BigInt) -> String {
  cardinal_zh_impl(self, n)
}

///|
fn Lang::cardinal_zh_tw(self : Lang, n : BigInt) -> String {
  cardinal_zh_impl(self, n)
}

// --- ordinals ---------------------------------------------------------------

///|
/// `第` + cardinal: 1 -> 第一, 10 -> 第十, 101 -> 第一百零一.
pub fn ordinal_zh(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  "第" + lang_zh().cardinal_zh(n)
}

///|
/// Traditional-Chinese ordinal (第… with 萬/億/兆).
pub fn ordinal_zh_tw(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  "第" + lang_zh_tw().cardinal_zh_tw(n)
}

///|
/// `第` + the digits themselves: 1 -> 第1, 1234 -> 第1234.
pub fn ordinal_num_zh(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  "第" + n.to_string()
}

///|
/// Years are read digit by digit: 2024 -> 二零二四年, -44 -> 公元前四四年.
pub fn year_zh(n : BigInt) -> String {
  let neg = n < BigInt::from_int(0)
  let abs_n = if neg { -n } else { n }
  let digits = abs_n.to_string()
  let l = lang_zh()
  let mut out = if neg { "公元前" } else { "" }
  for i = 0; i < digits.length(); i = i + 1 {
    let d = BigInt::from_string(digits[i:i + 1].to_owned()).to_int()
    out = out + l.ones[d]
  }
  out + "年"
}
