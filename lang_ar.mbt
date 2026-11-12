// lang_ar.mbt — Arabic number spelling (cardinal, ordinal, year).
//
// Faithful port of upstream num2words 0.5.14 `lang_AR.py` (Taro Ogawa,
// Savoir-faire Linux, Abdullah Alhazmy). Only the integer paths are ported:
// `to_currency` raises NotImplementedError upstream for every currency code,
// so no currency function exists here.
//
// Shape of the cardinal (3-digit groups, low to high):
//   * each group is "hundreds + و + tens/teens/unit";
//   * the scale word after a group depends on the group value:
//       1            -> "ألف" / "مليون" (bare noun),
//       2            -> "ألفان" / "مليونان", or "ألفا" / "مليونا" when the
//                       whole number is exactly 2 * 10^(3k) (upstream's
//                       `arabicAppendedTwos` rule, e.g. 2000 -> "ألفا");
//       3..10        -> "آلاف" / "ملايين" (broken plural),
//       anything else -> "ألفاً" / "مليوناً" when lower groups follow,
//                       "ألف" / "مليون" when the group stands alone;
//   * lower groups are preceded by "و " ("ألف و مئتان و أربعة و ثلاثون");
//   * a group whose value is 0 contributes nothing at all.
//
// Deviations from upstream (string API instead of Python exceptions):
//   * upstream's helpers index Python lists with the raw value, so a negative
//     ordinal either wraps around the table (-1 -> "تاسع عشر") or raises
//     IndexError (below -19). This port never raises: a negative cardinal is
//     "سالب " + cardinal(abs) (upstream's `to_cardinal` produces the same
//     text) and a negative ordinal is "";
//   * magnitudes at or beyond 10^51 raise OverflowError upstream; here the
//     language simply reports them as unsupported (`supports` -> ""), like the
//     other ports in this library;
//   * upstream computes the groups through `Decimal`, whose default 28-digit
//     precision silently mangles values with more than 28 digits; this port
//     uses exact `BigInt` arithmetic.

// --- word tables -----------------------------------------------------------

///|
/// Counted masculine forms 0..19 (upstream `ARABIC_ONES`). Index 0 is never
/// read by the cardinal code; upstream leaves it empty, "صفر" is used here.
let ar_ones : Array[String] = [
  "صفر", "واحد", "اثنان", "ثلاثة", "أربعة", "خمسة", "ستة",
  "سبعة", "ثمانية", "تسعة", "عشرة", "أحد عشر", "اثنا عشر",
  "ثلاثة عشر", "أربعة عشر", "خمسة عشر", "ستة عشر", "سبعة عشر",
  "ثمانية عشر", "تسعة عشر",
]

///|
/// Feminine forms 0..19 (upstream `arabicFeminineOnes`); used for ordinals
/// 20..99, where the units digit is feminine ("إحدى و عشرون").
let ar_feminine_ones : Array[String] = [
  "", "إحدى", "اثنتان", "ثلاث", "أربع", "خمس", "ست", "سبع",
  "ثمان", "تسع", "عشر", "إحدى عشرة", "اثنتا عشرة", "ثلاث عشرة",
  "أربع عشرة", "خمس عشرة", "ست عشرة", "سبع عشرة", "ثماني عشرة",
  "تسع عشرة",
]

///|
/// Ordinals 0..19 (upstream `arabicOrdinal`).
let ar_ordinal : Array[String] = [
  "", "اول", "ثاني", "ثالث", "رابع", "خامس", "سادس", "سابع",
  "ثامن", "تاسع", "عاشر", "حادي عشر", "ثاني عشر", "ثالث عشر",
  "رابع عشر", "خامس عشر", "سادس عشر", "سابع عشر", "ثامن عشر",
  "تاسع عشر",
]

///|
/// Tens 20..90; index = tens digit - 2 (upstream `arabicTens`).
let ar_tens : Array[String] = [
  "عشرون", "ثلاثون", "أربعون", "خمسون", "ستون", "سبعون",
  "ثمانون", "تسعون",
]

///|
/// Hundreds 0..9 (upstream `arabicHundreds`); a group of exactly 200 reads
/// "مئتا" (`ar_appended_twos[0]`) instead of "مئتان".
let ar_hundreds : Array[String] = [
  "", "مائة", "مئتان", "ثلاثمائة", "أربعمائة", "خمسمائة",
  "ستمائة", "سبعمائة", "ثمانمائة", "تسعمائة",
]

///|
/// Dual scale words in the construct state ("مئتا", "ألفا", "مليونا"); index =
/// group power (upstream `arabicAppendedTwos`). Index 9 keeps upstream's
/// trailing space, which reaches the output.
let ar_appended_twos : Array[String] = [
  "مئتا", "ألفا", "مليونا", "مليارا", "تريليونا", "كوادريليونا",
  "كوينتليونا", "سكستيليونا", "سبتيليونا", "أوكتيليونا ",
  "نونيليونا", "ديسيليونا", "أندسيليونا", "دوديسيليونا",
  "تريديسيليونا", "كوادريسيليونا", "كوينتينيليونا",
]

///|
/// Dual scale words in the free state ("مئتان", "ألفان", "مليونان"); index =
/// group power (upstream `arabicTwos`). Indices 9 and 10 keep upstream's
/// trailing spaces.
let ar_twos : Array[String] = [
  "مئتان", "ألفان", "مليونان", "ملياران", "تريليونان",
  "كوادريليونان", "كوينتليونان", "سكستيليونان",
  "سبتيليونان", "أوكتيليونان ", "نونيليونان ", "ديسيليونان",
  "أندسيليونان", "دوديسيليونان", "تريديسيليونان",
  "كوادريسيليونان", "كوينتينيليونان",
]

///|
/// Singular scale words; index = group power (upstream `arabicGroup`). Index 0
/// is never read (upstream stores "مائة" there) and stays empty here.
let ar_groups : Array[String] = [
  "", "ألف", "مليون", "مليار", "تريليون", "كوادريليون",
  "كوينتليون", "سكستيليون", "سبتيليون", "أوكتيليون",
  "نونيليون", "ديسيليون", "أندسيليون", "دوديسيليون",
  "تريديسيليون", "كوادريسيليون", "كوينتينيليون",
]

///|
/// Accusative singular scale words used in front of lower groups ("ألفاً");
/// index = group power (upstream `arabicAppendedGroup`).
let ar_appended_groups : Array[String] = [
  "", "ألفاً", "مليوناً", "ملياراً", "تريليوناً", "كوادريليوناً",
  "كوينتليوناً", "سكستيليوناً", "سبتيليوناً", "أوكتيليوناً",
  "نونيليوناً", "ديسيليوناً", "أندسيليوناً", "دوديسيليوناً",
  "تريديسيليوناً", "كوادريسيليوناً", "كوينتينيليوناً",
]

///|
/// Broken plurals for group values 3..10 ("آلاف", "ملايين"); index = group
/// power (upstream `arabicPluralGroups`).
let ar_plural_groups : Array[String] = [
  "", "آلاف", "ملايين", "مليارات", "تريليونات", "كوادريليونات",
  "كوينتليونات", "سكستيليونات", "سبتيليونات", "أوكتيليونات",
  "نونيليونات", "ديسيليونات", "أندسيليونات", "دوديسيليونات",
  "تريديسيليونات", "كوادريسيليونات", "كوينتينيليونات",
]

// --- Lang descriptor --------------------------------------------------------

///|
/// `thousands` stops at power 16 (كوينتينيليون), matching upstream's
/// MAXVAL = 10^51: 17 groups, powers 0..16.
pub fn lang_ar() -> Lang {
  {
    variant: Ar,
    zero: "صفر",
    ones: [
      "صفر", "واحد", "اثنان", "ثلاثة", "أربعة", "خمسة",
      "ستة", "سبعة", "ثمانية", "تسعة",
    ],
    teens: [
      "عشرة", "أحد عشر", "اثنا عشر", "ثلاثة عشر", "أربعة عشر",
      "خمسة عشر", "ستة عشر", "سبعة عشر", "ثمانية عشر",
      "تسعة عشر",
    ],
    tens: [
      "", "عشرة", "عشرون", "ثلاثون", "أربعون", "خمسون",
      "ستون", "سبعون", "ثمانون", "تسعون",
    ],
    hundred: "مائة",
    thousands: ar_groups,
    negative: "سالب",
    decimal: "فاصلة",
    comma_sep: false,
  }
}

// --- cardinal ---------------------------------------------------------------

///|
/// True when `total` (the whole absolute number) is exactly 2 * 10^(3k) with
/// 10^(3k) > 10, i.e. upstream's `integer_value == 2 * 10**pow and pow % 3 == 0
/// and integer_value > 10` test: 2000, 2000000, 2*10^9, ...
fn ar_two_times_power(total : BigInt) -> Bool {
  if total < BigInt::from_int(11) {
    return false
  }
  let s = total.to_string()
  if (s.length() - 1) % 3 != 0 || s[0:1].to_owned() != "2" {
    return false
  }
  for i = 1; i < s.length(); i = i + 1 {
    if s[i:i + 1].to_owned() != "0" {
      return false
    }
  }
  true
}

///|
/// Spell one 3-digit group (`group` in 0..999). `level` is the group's power of
/// 1000, `total` the whole absolute number (needed by the dual-scale rule), and
/// `feminine` selects the feminine unit words for the lowest group.
///
/// Upstream's `hundreds == 0` branches never fire: `hundreds` there is the
/// `Decimal` quotient `1/100 = 0.01`, which is never equal to 0, so those
/// branches are omitted instead of being transliterated.
fn ar_group_words(
  group : Int,
  level : Int,
  total : BigInt,
  feminine : Bool,
) -> String {
  let tens = group % 100
  let hundreds = group / 100
  let unit_words = if feminine && level == 0 {
    ar_feminine_ones
  } else {
    ar_ones
  }
  let mut ret = ""
  if hundreds > 0 {
    if tens == 0 && hundreds == 2 {
      ret = ar_appended_twos[0]
    } else {
      ret = ar_hundreds[hundreds]
      if ret != "" && tens != 0 {
        ret = ret + " و "
      }
    }
  }
  if tens > 0 {
    if tens < 20 {
      if tens == 2 && hundreds == 0 && level > 0 {
        ret = if ar_two_times_power(total) {
          ar_appended_twos[level]
        } else {
          ar_twos[level]
        }
      } else if tens == 1 && level > 0 {
        ret = ret + ar_groups[level]
      } else {
        ret = ret + unit_words[tens]
      }
    } else {
      let ones = tens % 10
      let tens_idx = tens / 10 - 2
      if ones > 0 {
        ret = ret + unit_words[ones]
      }
      if ret != "" && ones != 0 {
        ret = ret + " و "
      }
      ret = ret + ar_tens[tens_idx]
    }
  }
  ret
}

///|
/// Spell `n` (> 0, within range) as a space-separated phrase.
///
/// Groups are visited low to high. Each non-empty group prepends its own words,
/// after the accumulated phrase has been given the appropriate scale word and,
/// where needed, the conjunction "و ".
fn ar_spell(n : BigInt, feminine_units : Bool) -> String {
  let thousand = BigInt::from_int(1000)
  let mut ret = ""
  let mut group = 0
  let mut temp = n
  while temp > BigInt::from_int(0) {
    let value = (temp % thousand).to_int()
    temp = temp / thousand
    let desc = ar_group_words(value, group, n, feminine_units)
    if desc != "" {
      if group > 0 {
        if ret != "" {
          ret = "و " + ret
        }
        // Values 1 and 2 carry their scale word inside `desc` ("ألف",
        // "ألفان", "ألفا").
        if value != 2 && value != 1 {
          if value % 100 != 1 {
            if value >= 3 && value <= 10 {
              ret = ar_plural_groups[group] + " " + ret
            } else if ret != "" {
              ret = ar_appended_groups[group] + " " + ret
            } else {
              ret = ar_groups[group] + " " + ret
            }
          } else {
            ret = ar_groups[group] + " " + ret
          }
        }
      }
      ret = desc + " " + ret
    }
    group = group + 1
  }
  trim_spaces(ret)
}

///|
/// Cardinal spelling of an integer.
///
/// Deviation: upstream's helpers index Python lists with the raw value, which
/// raises IndexError for negative input (its ordinal path does; `to_cardinal`
/// itself only manages to avoid it by taking the absolute value first). This
/// port never raises: negative cardinals read "سالب " + cardinal(abs) and
/// negative ordinals return "".
fn Lang::cardinal_ar(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let total = if neg { -n } else { n }
  let words = ar_spell(total, false)
  if neg {
    "سالب " + words
  } else {
    words
  }
}

// --- ordinal ----------------------------------------------------------------

///|
/// Ordinal spelling: 0..19 come from the ordinal table ("اول", "حادي عشر"),
/// 20..99 use the feminine units with the cardinal scale ("إحدى و عشرون"), and
/// everything above reads like the cardinal. Negative input returns "".
pub fn ordinal_ar(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream wraps around the Python list for -19..-1 and raises IndexError
    // below that; this port returns "" instead of a bogus word.
    return ""
  }
  if n < BigInt::from_int(20) {
    return ar_ordinal[n.to_int()]
  }
  if !lang_ar().supports(n) {
    return ""
  }
  ar_spell(n, n < BigInt::from_int(100))
}

///|
/// Upstream `to_ordinal_num` is `to_ordinal(...).strip()`, so no numeric suffix
/// is written: 21 -> "إحدى و عشرون".
pub fn ordinal_num_ar(n : BigInt) -> String {
  ordinal_ar(n)
}

///|
/// Upstream `to_year` returns the cardinal spelling (2024 -> "ألفان و ...").
pub fn year_ar(n : BigInt) -> String {
  lang_ar().cardinal_ar(n)
}
