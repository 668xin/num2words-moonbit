// lang_vi.mbt — Vietnamese number spelling (cardinal).
//
// Vietnamese separates groups with spaces instead of glueing them, and uses
// "lẻ" before a 1-99 remainder that follows a larger group: 1001 ->
// "một nghìn lẻ một", 1100 -> "một nghìn một trăm".
//
// Upstream num2words 0.5.14 implements only `to_cardinal` for Vietnamese (and
// aliases `to_ordinal` to it); it has no `to_year`, `to_ordinal_num` or
// `to_currency`. Its negative handling is broken (-1 -> "mười chín", smaller
// values raise IndexError); this port spells negatives properly ("âm ...").
// See COMPAT.md §3.

///|
/// 0..19.
let vi_to19 : Array[String] = [
  "không", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín",
  "mười", "mười một", "mười hai", "mười ba", "mười bốn", "mười lăm",
  "mười sáu", "mười bảy", "mười tám", "mười chín",
]

///|
/// 20, 30, ... 90.
let vi_tens : Array[String] = [
  "hai mươi", "ba mươi", "bốn mươi", "năm mươi", "sáu mươi", "bảy mươi",
  "tám mươi", "chín mươi",
]

///|
/// Scale words. Index 1 -> 10^3, ... index 19 -> 10^57. Upstream keeps English
/// placeholders from "Quintillion" upward.
let vi_denom : Array[String] = [
  "", "nghìn", "triệu", "tỷ", "nghìn tỷ", "trăm nghìn tỷ", "Quintillion",
  "Sextillion", "Septillion", "Octillion", "Nonillion", "Decillion", "Undecillion",
  "Duodecillion", "Tredecillion", "Quattuordecillion", "Sexdecillion", "Septendecillion",
  "Octodecillion", "Novemdecillion",
]

///|
pub fn lang_vi() -> Lang {
  {
    variant: Vi,
    zero: "không",
    ones: [
      "không", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín",
    ],
    teens: [
      "mười", "mười một", "mười hai", "mười ba", "mười bốn", "mười lăm",
      "mười sáu", "mười bảy", "mười tám", "mười chín",
    ],
    tens: [
      "", "mười", "hai mươi", "ba mươi", "bốn mươi", "năm mươi", "sáu mươi",
      "bảy mươi", "tám mươi", "chín mươi",
    ],
    hundred: "trăm",
    thousands: vi_denom,
    negative: "âm",
    decimal: "phẩy",
    comma_sep: false,
  }
}

///|
/// 0..99. 21 -> "hai mươi mốt", 25 -> "hai mươi lăm".
fn vi_nn(v : Int) -> String {
  if v < 20 {
    return vi_to19[v]
  }
  let decade = vi_tens[(v - 20) / 10]
  let u = v % 10
  if u == 0 {
    return decade
  }
  let unit = if u == 1 { "mốt" } else if u == 5 { "lăm" } else { vi_to19[u] }
  decade + " " + unit
}

///|
/// 1..999. A sub-ten remainder after the hundreds takes "lẻ":
/// 105 -> "một trăm lẻ năm", 115 -> "một trăm mười lăm".
fn vi_nnn(v : Int) -> String {
  let rem = v / 100
  let mod = v % 100
  let mut word = ""
  if rem > 0 {
    word = vi_to19[rem] + " trăm"
    if mod > 0 {
      word = word + " "
    }
  }
  if mod > 0 && mod < 10 {
    word = if word != "" {
      word + "lẻ " + vi_nn(mod)
    } else {
      word + vi_nn(mod)
    }
  }
  if mod >= 10 {
    word = word + vi_nn(mod)
  }
  word
}

///|
fn vi_rec(val : BigInt) -> String {
  let hundred = BigInt::from_int(100)
  let thousand = BigInt::from_int(1000)
  if val < hundred {
    return vi_nn(val.to_int())
  }
  if val < thousand {
    return vi_nnn(val.to_int())
  }
  // Largest power of 1000 not exceeding `val` (1..19).
  let mut power = 1
  let mut mod = thousand
  while power < 19 && val >= mod * thousand {
    mod = mod * thousand
    power = power + 1
  }
  let lval = (val / mod).to_int()
  let r = val % mod
  let head = vi_nnn(lval) + " " + vi_denom[power]
  let mut ret = if r > BigInt::from_int(0) && r <= BigInt::from_int(99) {
    head + " lẻ"
  } else {
    head
  }
  if r > BigInt::from_int(0) {
    ret = ret + " " + vi_rec(r)
  }
  ret
}

///|
fn Lang::cardinal_vi(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  if n < BigInt::from_int(0) {
    return self.negative + " " + vi_rec(-n)
  }
  vi_rec(n)
}
