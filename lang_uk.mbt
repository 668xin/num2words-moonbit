// lang_uk.mbt — Ukrainian number spelling (cardinal, ordinal, year).
//
// Faithful port of upstream num2words 0.5.14 `lang_UK.py` with its default
// grammar (nominative case, masculine gender):
//   * 3-digit groups, high to low; every group is "hundreds + tens/teens +
//     unit", then a scale word;
//   * every scale word has three plural forms selected by the group value:
//       1      -> "тисяча" / "мільйон"
//       2..4   -> "тисячі" / "мільйони"   (but not 11..14)
//       0, 5+  -> "тисяч" / "мільйонів"
//     so 1000 -> "одна тисяча", 2000 -> "дві тисячі", 5000 -> "п'ять тисяч";
//   * "тисяча" is feminine, so the unit of the thousands group uses
//     "одна" / "дві" instead of "один" / "два" (21000 ->
//     "двадцять одна тисяча"); millions and above are masculine;
//   * words are separated by single spaces and no commas are written;
//   * ordinals ordinalise only the lowest non-zero group, while the higher
//     groups stay cardinal (1234 -> "одна тисяча двісті тридцять четвертий").
//     A trailing run of zero groups merges into one fused word together with
//     the scale suffix (2000 -> "двохтисячний", 100000 -> "стотисячний").
//
// Deviations (upstream raises instead of returning a string):
//   * 0 -> "нуль" and negative input -> "мінус " + cardinal(abs(n)) (upstream
//     spells these the same way in `to_cardinal`, but its ordinal path raises);
//   * ordinal 0 raises IndexError upstream (the fragment list becomes empty);
//     here it returns "";
//   * ordinals at 10^33 and above raise KeyError upstream (the scale tables
//     stop at 10^30); here "" is returned;
//   * `to_ordinal_num` is inherited from the base class upstream and falls
//     through to the number itself (21 -> "21"), exactly like Russian and
//     Polish; no "-й" suffix is produced.

// --- cardinal tables --------------------------------------------------------
//
// Upstream stores hundred/tens/unit/scale words as six case variants; only the
// nominative (index 0) is needed here because the public API has no case
// parameter.

///|
let uk_ones : Array[String] = [
  "нуль", "один", "два", "три", "чотири", "п'ять", "шість",
  "сім", "вісім", "дев'ять",
]

///|
let uk_teens : Array[String] = [
  "десять", "одинадцять", "дванадцять", "тринадцять",
  "чотирнадцять", "п'ятнадцять", "шістнадцять",
  "сімнадцять", "вісімнадцять", "дев'ятнадцять",
]

///|
/// Tens 20..90 (index = tens digit). Index 1 is unused: teens come from
/// `Lang.teens`.
let uk_twenties : Array[String] = [
  "", "", "двадцять", "тридцять", "сорок", "п'ятдесят",
  "шістдесят", "сімдесят", "вісімдесят", "дев'яносто",
]

///|
/// Hundreds: 1 -> "сто", 2 -> "двісті", ... 9 -> "дев'ятсот".
let uk_hundreds : Array[String] = [
  "", "сто", "двісті", "триста", "чотириста", "п'ятсот",
  "шістсот", "сімсот", "вісімсот", "дев'ятсот",
]

// --- scale words ------------------------------------------------------------
//
// Index = group power (1 -> 10^3, 2 -> 10^6, ...). "тисяча" is irregular,
// powers 2..10 are "мільйон", "мільярд", "трильйон", ... plus a plural ending.

///|
/// Scale words for a group value of 1.
let uk_scale_one : Array[String] = [
  "", "тисяча", "мільйон", "мільярд", "трильйон", "квадрильйон",
  "квінтильйон", "секстильйон", "септильйон", "октильйон",
  "нонільйон",
]

///|
/// Scale words for a group value of 2..4 (but not 11..14).
let uk_scale_few : Array[String] = [
  "", "тисячі", "мільйони", "мільярди", "трильйони",
  "квадрильйони", "квінтильйони", "секстильйони",
  "септильйони", "октильйони", "нонільйони",
]

///|
/// Scale words for every other group value (0, 5..20, 25..30, ...).
let uk_scale_many : Array[String] = [
  "", "тисяч", "мільйонів", "мільярдів", "трильйонів",
  "квадрильйонів", "квінтильйонів", "секстильйонів",
  "септильйонів", "октильйонів", "нонільйонів",
]

///|
/// Pick the plural form of a scale word: 0 = one, 1 = few (2..4),
/// 2 = many (everything else, including 11..14 and 0).
fn uk_form(x : Int) -> Int {
  let m100 = x % 100
  if m100 < 10 || m100 > 20 {
    let m10 = x % 10
    if m10 == 1 {
      return 0
    }
    if m10 > 1 && m10 < 5 {
      return 1
    }
  }
  2
}

///|
fn uk_scale(power : Int, form : Int) -> String {
  if form == 0 {
    uk_scale_one[power]
  } else if form == 1 {
    uk_scale_few[power]
  } else {
    uk_scale_many[power]
  }
}

///|
/// The unit word, honouring grammatical gender: "один"/"одна",
/// "два"/"дві"; 3..9 are gender-neutral.
fn uk_unit(l : Lang, u : Int, feminine : Bool) -> String {
  if feminine {
    if u == 1 {
      return "одна"
    }
    if u == 2 {
      return "дві"
    }
  }
  l.ones[u]
}

///|
fn Lang::below100_uk(self : Lang, r : Int, feminine : Bool) -> String {
  if r < 10 {
    return uk_unit(self, r, feminine)
  }
  if r < 20 {
    return self.teens[r - 10]
  }
  let d = r / 10
  let u = r % 10
  if u == 0 {
    return self.tens[d]
  }
  self.tens[d] + " " + uk_unit(self, u, feminine)
}

///|
fn Lang::triple_uk(self : Lang, t : Int, feminine : Bool) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_uk(r, feminine)
  }
  if r == 0 {
    return uk_hundreds[h]
  }
  uk_hundreds[h] + " " + self.below100_uk(r, feminine)
}

// --- ordinal tables ---------------------------------------------------------
//
// Upstream pairs every ordinal word with a combining stem (index 1) that is
// used when the group is followed by a scale suffix: "сотий" but "стотисячний",
// "другий" but "двохтисячний".

///|
let uk_ones_ord : Array[String] = [
  "", "перший", "другий", "третій", "четвертий", "п'ятий",
  "шостий", "сьомий", "восьмий", "дев'ятий", "десятий",
  "одинадцятий", "дванадцятий", "тринадцятий", "чотирнадцятий",
  "п'ятнадцятий", "шістнадцятий", "сімнадцятий",
  "вісімнадцятий", "дев'ятнадцятий",
]

///|
let uk_ones_ord_stem : Array[String] = [
  "", "одно", "двох", "трьох", "чотирьох", "п'яти", "шести",
  "семи", "восьми", "дев'яти", "десяти", "одинадцяти",
  "дванадцяти", "тринадцяти", "чотирнадцяти", "п'ятнадцяти",
  "шістнадцяти", "сімнадцяти", "вісімнадцяти", "дев'ятнадцяти",
]

///|
let uk_twenties_ord : Array[String] = [
  "", "", "двадцятий", "тридцятий", "сороковий", "п'ятдесятий",
  "шістдесятий", "сімдесятий", "вісімдесятий", "дев'яностий",
]

///|
let uk_twenties_ord_stem : Array[String] = [
  "", "", "двадцяти", "тридцяти", "сорока", "п'ятдесяти",
  "шістдесяти", "сімдесяти", "вісімдесяти", "дев'яности",
]

///|
let uk_hundreds_ord : Array[String] = [
  "", "сотий", "двохсотий", "трьохсотий", "чотирьохсотий",
  "п'ятисотий", "шестисотий", "семисотий", "восьмисотий",
  "дев'ятисотий",
]

///|
let uk_hundreds_ord_stem : Array[String] = [
  "", "сто", "двохсот", "трьохсот", "чотирьохсот", "п'ятсот",
  "шістсот", "сімсот", "вісімсот", "дев'ятсот",
]

///|
/// Ordinal scale suffixes: 1 -> "тисячний", 2 -> "мільйонний", ...
let uk_prefixes_ordinal : Array[String] = [
  "", "тисячний", "мільйонний", "мільярдний", "трильйонний",
  "квадрильйонний", "квінтильйонний", "секстильйонний",
  "септильйонний", "октильйонний", "нонільйонний",
]

// --- Lang descriptor --------------------------------------------------------

///|
pub fn lang_uk() -> Lang {
  {
    variant: Uk,
    zero: "нуль",
    ones: uk_ones,
    teens: uk_teens,
    tens: uk_twenties,
    hundred: "сто",
    thousands: uk_scale_many,
    negative: "мінус",
    decimal: "кома",
    comma_sep: false,
  }
}

// --- cardinal ---------------------------------------------------------------

///|
/// Upstream `_int2word` for the nominative case. The thousands group is spoken
/// with feminine unit words, all other groups with masculine ones.
fn Lang::cardinal_uk(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  let groups = group3(n)
  let words : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let x = triple.to_int()
    if x == 0 {
      continue
    }
    // "тисяча" is feminine: 1 -> "одна тисяча", 2 -> "дві тисячі".
    let mut s = self.triple_uk(x, power == 1)
    if power > 0 {
      s = s + " " + uk_scale(power, uk_form(x))
    }
    words.push(s)
  }
  let joined = join_parts(words, " ")
  if neg {
    self.negative + " " + joined
  } else {
    joined
  }
}

// --- ordinal ----------------------------------------------------------------

///|
/// Upstream `last_fragment_to_ordinal`: turn the lowest non-zero group into
/// ordinal words. `level` is 0 for the units group and 1 when the group is
/// followed by a scale suffix (the fused form uses combining stems).
fn uk_last_fragment(last : Int, level : Int) -> Array[String] {
  let words : Array[String] = []
  let n1 = last % 10
  let n2 = last / 10 % 10
  let n3 = last / 100
  let last_two = n2 * 10 + n1
  if level == 1 && last == 1 {
    // "тисячний", "мільйонний": the leading unit word disappears. The early
    // return is safe because `last == 1` implies `last_two == 1`.
    return words
  }
  if last_two == 0 {
    // Trailing zeros: the hundreds digit becomes the ordinal word itself
    // ("сотий" / "стотисячний").
    if level == 0 {
      words.push(uk_hundreds_ord[n3])
    } else {
      words.push(uk_hundreds_ord_stem[n3])
    }
  } else if last_two < 20 {
    if level == 0 {
      if n3 > 0 {
        words.push(uk_hundreds[n3])
      }
      words.push(uk_ones_ord[last_two])
    } else {
      let mut s = ""
      if n3 > 0 {
        s = s + uk_hundreds_ord_stem[n3]
      }
      s = s + uk_ones_ord_stem[last_two]
      words.push(s)
    }
  } else if last_two % 10 == 0 {
    if level == 0 {
      if n3 > 0 {
        words.push(uk_hundreds[n3])
      }
      words.push(uk_twenties_ord[n2])
    } else {
      let mut s = ""
      if n3 > 0 {
        s = s + uk_hundreds_ord_stem[n3]
      }
      s = s + uk_twenties_ord_stem[n2]
      words.push(s)
    }
  } else if level == 0 {
    if n3 > 0 {
      words.push(uk_hundreds[n3])
    }
    words.push(uk_twenties[n2])
    words.push(uk_ones_ord[n1])
  } else {
    let mut s = ""
    if n3 > 0 {
      s = s + uk_hundreds_ord_stem[n3]
    }
    s = s + uk_twenties_ord_stem[n2]
    s = s + uk_ones_ord_stem[n1]
    words.push(s)
  }
  words
}

///|
/// Upstream `to_ordinal`: only the lowest non-zero group is ordinalised; the
/// groups above it stay cardinal and form one prefix phrase.
pub fn ordinal_uk(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream `verify_ordinal` raises TypeError for negative input.
    return ""
  }
  if n == BigInt::from_int(0) {
    // Upstream raises IndexError for 0 (the fragment list becomes empty).
    return ""
  }
  let l = lang_uk()
  if !l.supports(n) {
    return ""
  }
  let groups = group3(n)
  let zero = BigInt::from_int(0)
  // `level` is the number of trailing zero groups; `idx` points at the lowest
  // non-zero group. `groups[0]` is never zero, so the scan always stops.
  let mut level = 0
  let mut idx = groups.length() - 1
  let mut scanning = true
  while scanning && idx > 0 {
    let (g, _) = groups[idx]
    if g == zero {
      level = level + 1
      idx = idx - 1
    } else {
      scanning = false
    }
  }
  if level >= uk_prefixes_ordinal.length() {
    // The scale-suffix table stops at 10^30; upstream raises KeyError.
    return ""
  }
  let (last_group, _) = groups[idx]
  let last = last_group.to_int()
  let words : Array[String] = []
  if idx > 0 {
    // pre_part = n - last * 1000^level: the groups above `last`.
    let b1000 = BigInt::from_int(1000)
    let mut scale_hi = BigInt::from_int(1)
    for k = 0; k < level; k = k + 1 {
      scale_hi = scale_hi * b1000
    }
    words.push(l.cardinal_uk(n - last_group * scale_hi))
  }
  let frag_level = if level == 0 { 0 } else { 1 }
  let frag_words = uk_last_fragment(last, frag_level)
  for w in frag_words {
    words.push(w)
  }
  let mut output = join_parts(words, " ")
  if last == 1 && level > 0 && output != "" {
    // "один мільйон тисячний": a space separates prefix and scale suffix.
    output = output + " "
  }
  if level > 0 {
    output = output + uk_prefixes_ordinal[level]
  }
  output
}

///|
/// Upstream `Num2Word_UK` inherits `to_ordinal_num` from the base class, which
/// returns the number itself (21 -> "21"); Russian and Polish behave the same.
pub fn ordinal_num_uk(n : BigInt) -> String {
  n.to_string()
}

///|
/// Upstream `to_year` is the plain cardinal (2024 -> "дві тисячі двадцять
/// чотири"); negative years read "мінус ...".
pub fn year_uk(n : BigInt) -> String {
  lang_uk().cardinal_uk(n)
}
