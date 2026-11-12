// lang_th.mbt — Thai number spelling (cardinal, ordinal, year).
//
// Port of upstream num2words 0.5.14 `lang_TH.py`. Thai advances its place
// words by 10^3 inside a six-digit group (สิบ, ร้อย, พัน, หมื่น, แสน) and
// repeats the group with the million word ล้าน: 1234567 ->
// "หนึ่งล้านสองแสนสามหมื่นสี่พันห้าร้อยหกสิบเจ็ด".
//
// Upstream reads the decimal digits as a string, so the เอ็ด rule (a unit 1
// that is not alone reads เอ็ด) applies whenever the digit string is longer
// than one character: 1 -> หนึ่ง but 1001 -> หนึ่งพันเอ็ด, 11 -> สิบเอ็ด and
// 21 -> ยี่สิบเอ็ด.
//
// `to_ordinal` and `to_year` just return the cardinal, and `to_ordinal_num`
// returns the number unchanged. `to_currency` raises NotImplementedError for
// every code upstream, so no currency form is exposed here (`th` is not a
// currency-supported language).

///|
/// Place words for the six digits of a group, index = digit position from the
/// right (0 -> units, 1 -> สิบ ... 5 -> แสน). Index 6 mirrors upstream's
/// `mid_numwords` entry for ล้าน; it is never reached inside a group.
let th_place : Array[String] = [
  "", "สิบ", "ร้อย", "พัน", "หมื่น", "แสน", "ล้าน",
]

///|
/// Scale words, index = power of 1000. Thai groups by 10^6, so only the table
/// length matters here (`Lang::supports` / `Lang::max_power`); the cardinal
/// algorithm does its own six-digit grouping.
let th_scale : Array[String] = [
  "", "พัน", "ล้าน", "พันล้าน", "ล้านล้าน",
  "พันล้านล้าน", "ล้านล้านล้าน", "พันล้านล้านล้าน",
  "ล้านล้านล้านล้าน",
]

///|
/// Thai word tables. The `ones` table doubles as upstream's `low_numwords`
/// (index 0 is the zero word); teens/tens are unused because the six-digit
/// place words replace them.
pub fn lang_th() -> Lang {
  {
    variant: Th,
    zero: "ศูนย์",
    ones: [
      "ศูนย์", "หนึ่ง", "สอง", "สาม", "สี่",
      "ห้า", "หก", "เจ็ด", "แปด", "เก้า",
    ],
    teens: [],
    tens: [],
    hundred: "ร้อย",
    thousands: th_scale,
    negative: "ติดลบ",
    decimal: "จุด",
    comma_sep: false,
  }
}

///|
/// Spell one six-digit group. `digits` is the length of the group's digit
/// string, leading zeros included for every group but the highest; the
/// upstream เอ็ด rule keys off `digits > 1` (so a lone 1 is หนึ่ง).
fn Lang::splitnum_th(self : Lang, value : BigInt, digits : Int) -> String {
  let multi = digits > 1
  let ten = BigInt::from_int(10)
  let mut word = ""
  let mut rest = value
  for index = 0; index < digits; index = index + 1 {
    let num = (rest % ten).to_int()
    rest = rest / ten
    if num != 0 {
      if index != 0 {
        word = th_place[index] + word
      }
      if multi && num == 1 && index == 0 {
        word = word + "เอ็ด"
      } else if index == 1 && num == 2 {
        word = "ยี่" + word
      } else if index != 1 || num != 1 {
        word = self.ones[num] + word
      }
    } else if index == 0 && !multi {
      word = self.zero
    }
  }
  word
}

///|
/// Split `n` (> 0) into six-digit groups, low to high. The highest group keeps
/// its natural digit count while every lower group counts six digits (its
/// leading zeros are significant for the เอ็ด rule), mirroring upstream
/// `splitbyx` followed by its string reversal.
fn split_six_th(n : BigInt) -> Array[(BigInt, Int)] {
  let million = BigInt::from_int(1000000)
  let zero = BigInt::from_int(0)
  let groups : Array[(BigInt, Int)] = []
  let mut rest = n
  while rest > zero {
    let chunk = rest % million
    rest = rest / million
    let digits = if rest > zero { 6 } else { chunk.to_string().length() }
    groups.push((chunk, digits))
  }
  groups
}

///|
/// Thai cardinal. Consecutive six-digit groups are joined by ล้าน, and each
/// group is spelled with the หลัก place words (with เอ็ด for a non-alone unit
/// 1). Upstream places the negative prefix directly before the words.
fn Lang::cardinal_th(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  let neg = n < BigInt::from_int(0)
  let m = if neg { -n } else { n }
  let groups = split_six_th(m)
  let mut out = ""
  for i = groups.length() - 1; i >= 0; i = i - 1 {
    let (value, digits) = groups[i]
    if i < groups.length() - 1 {
      out = out + "ล้าน"
    }
    out = out + self.splitnum_th(value, digits)
  }
  if neg {
    self.negative + out
  } else {
    out
  }
}

///|
/// Upstream `to_ordinal` is the cardinal (negatives included: -5 ->
/// "ติดลบห้า").
pub fn ordinal_th(n : BigInt) -> String {
  lang_th().cardinal_th(n)
}

///|
/// Upstream `to_ordinal_num` returns the number itself; in this string API a
/// negative value has no ordinal form and yields "".
pub fn ordinal_num_th(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return ""
  }
  n.to_string()
}

///|
/// Upstream `to_year` is the cardinal, so a year reads exactly like the number.
pub fn year_th(n : BigInt) -> String {
  lang_th().cardinal_th(n)
}
