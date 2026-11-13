// lang_fa.mbt — Persian number spelling (cardinal, ordinal, year, currency).
//
// Port of upstream num2words 0.5.14 `lang_FA.py`. Persian joins every spoken
// 3-digit group (and the scale words) with " و ":
//
//   1234 -> "هزار و دویست و سی و چهار"
//   123456 -> "صد و بیست و سه هزار و چهارصد و پنجاه و شش"
//
// A bare "هزار" drops its multiplier ("هزار", not "یک هزار"), 11..19 are single
// words, and the scale words stop at 10^15 ("تریلیارد"), matching upstream's
// six-entry table: magnitudes from 10^18 upwards produce "" upstream and are
// reported as unsupported here.
//
// `to_currency` always writes tomans and takes no ISO code; fractional amounts
// are spelled with their denominator ("1234.56" -> "... و پنجاه و شش صدم
// تومان", "1.5" -> "یک و نیم تومان"), exactly like upstream's `to_cardinal`.

// --- word tables ------------------------------------------------------------

///|
/// 0..19 (index 0 is only used by the decimal-digit path).
let fa_ones : Array[String] = [
  "صفر", "یک", "دو", "سه", "چهار", "پنج", "شش", "هفت", "هشت",
  "نه", "ده", "یازده", "دوازده", "سیزده", "چهارده", "پانزده",
  "شانزده", "هفده", "هجده", "نوزده",
]

///|
let fa_tens : Array[String] = [
  "", "ده", "بیست", "سی", "چهل", "پنجاه", "شصت", "هفتاد",
  "هشتاد", "نود",
]

///|
let fa_hundreds : Array[String] = [
  "", "صد", "دویست", "سیصد", "چهارصد", "پانصد", "ششصد",
  "هفتصد", "هشتصد", "نهصد",
]

///|
/// Scale suffixes (index = power of 1000, 0..5); the leading space is part of
/// upstream's table.
let fa_big : Array[String] = [
  "", " هزار", " میلیون", " میلیارد", " تریلیون", " تریلیارد",
]

///|
/// Fraction denominators by decimal position (mod 3).
let fa_frac : Array[String] = ["", "دهم", "صدم"]

///|
/// Fraction denominators by group of three decimal digits (level / 3).
let fa_frac_big : Array[String] = [
  "", "هزارم", "میلیونیم", "میلیاردیم",
]

///|
pub fn lang_fa() -> Lang {
  {
    variant: Fa,
    zero: "صفر",
    ones: fa_ones,
    teens: [
      "ده", "یازده", "دوازده", "سیزده", "چهارده", "پانزده",
      "شانزده", "هفده", "هجده", "نوزده",
    ],
    tens: fa_tens,
    hundred: "صد",
    thousands: fa_big,
    negative: "منفی",
    decimal: "ممیز",
    comma_sep: false,
  }
}

// --- cardinal ---------------------------------------------------------------

///|
/// 1..999.
fn fa3(number : Int) -> String {
  if number <= 19 {
    return fa_ones[number]
  }
  if number < 100 {
    let x = number / 10
    let y = number % 10
    if y == 0 {
      fa_tens[x]
    } else {
      fa_tens[x] + " و " + fa_ones[y]
    }
  } else {
    let x = number / 100
    let y = number % 100
    if y == 0 {
      fa_hundreds[x]
    } else {
      fa_hundreds[x] + " و " + fa3(y)
    }
  }
}

///|
/// Spell a positive integer with upstream's `cardinalPos` loop: groups low to
/// high, each non-empty group prepended to the result and joined with " و ".
/// Only the first six groups (10^0 .. 10^15) have scale words.
fn fa_pos(n : BigInt) -> String {
  let thousand = BigInt::from_int(1000)
  let mut x = n
  let mut res = ""
  for i = 0; i < fa_big.length(); i = i + 1 {
    let y = (x % thousand).to_int()
    x = x / thousand
    if y == 0 {
      continue
    }
    let mut yx = fa3(y) + fa_big[i]
    if i == 1 && y == 1 {
      yx = "هزار"
    }
    if res == "" {
      res = yx
    } else {
      res = yx + " و " + res
    }
  }
  res
}

///|
fn Lang::cardinal_fa(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let v = if neg { -n } else { n }
  let words = fa_pos(v)
  if neg {
    self.negative + " " + words
  } else {
    words
  }
}

// --- ordinal ----------------------------------------------------------------

///|
/// Upstream `to_ordinal`: append "م", except that a word ending in "سه" becomes
/// "سوم" ("سه" -> "سوم", "سی" -> "سیم").
pub fn ordinal_fa(n : BigInt) -> String {
  let word = lang_fa().cardinal_fa(n)
  if word == "" {
    return ""
  }
  if word.length() >= 2 &&
    word[word.length() - 1:word.length()].to_owned() == "ه" &&
    word[word.length() - 2:word.length() - 1].to_owned() == "س" {
    return word[0:word.length() - 1].to_owned() + "وم"
  }
  word + "م"
}

///|
/// Upstream `to_ordinal_num` is "<n>م" (negatives included).
pub fn ordinal_num_fa(n : BigInt) -> String {
  n.to_string() + "م"
}

// --- year -------------------------------------------------------------------

///|
/// Upstream `to_year` is the cardinal (negative years keep "منفی").
pub fn year_fa(n : BigInt) -> String {
  lang_fa().cardinal_fa(n)
}

// --- currency ---------------------------------------------------------------

///|
fn fa_all_zeros(s : String) -> Bool {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i:i + 1].to_owned() != "0" {
      return false
    }
  }
  true
}

///|
/// Upstream `fractional(number, level)`: 5 reads "نیم", everything else gets
/// its denominator word ("دهم", "صدم", "هزارم", ...).
fn fa_fractional(number : Int, level : Int) -> Result[String, String] {
  if number == 5 {
    return Ok("نیم")
  }
  let ld3 = level / 3
  let lm3 = level % 3
  if ld3 >= fa_frac_big.length() {
    return Err("decimal precision not supported for fa: " + level.to_string())
  }
  let mut ltext = fa_frac[lm3]
  if fa_frac_big[ld3] != "" {
    if ltext != "" {
      ltext = ltext + " "
    }
    ltext = ltext + fa_frac_big[ld3]
  }
  Ok(fa_pos(BigInt::from_int(number)) + " " + ltext)
}

///|
/// Persian currency: `to_cardinal(amount)` followed by "تومان". The amount is
/// read straight from the decimal string (no rounding), so fractions keep the
/// denominator spelling upstream produces.
fn currency_fa(amount : String) -> Result[String, String] {
  if !is_valid_number(amount) {
    return Err("invalid number: " + amount)
  }
  let neg = amount.length() > 0 && amount[0:1].to_owned() == "-"
  let body = if neg { amount[1:amount.length()].to_owned() } else { amount }
  let parts = body.split(".").map(fn(w) { w.to_owned() }).collect()
  let int_part = BigInt::from_string(parts[0])
  let l = lang_fa()
  if !l.supports(int_part) {
    return Err("magnitude out of supported range: " + int_part.to_string())
  }
  let mut core = ""
  if parts.length() < 2 || fa_all_zeros(parts[1]) {
    core = if int_part == BigInt::from_int(0) {
      l.zero
    } else {
      fa_pos(int_part)
    }
  } else {
    let frac = parts[1]
    let level = frac.length()
    let frac_value = BigInt::from_string(frac).to_int()
    if frac_value == 0 {
      core = if int_part == BigInt::from_int(0) {
        l.zero
      } else {
        fa_pos(int_part)
      }
    } else if frac_value == 5 {
      core = if int_part == BigInt::from_int(0) {
        "نیم"
      } else {
        fa_pos(int_part) + " و نیم"
      }
    } else {
      let frac_words = match fa_fractional(frac_value, level) {
        Err(msg) => return Err(msg)
        Ok(w) => w
      }
      core = if int_part == BigInt::from_int(0) {
        frac_words
      } else {
        fa_pos(int_part) + " و " + frac_words
      }
    }
  }
  if neg {
    core = "منفی " + core
  }
  Ok(core + " تومان")
}
