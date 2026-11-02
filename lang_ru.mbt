// lang_ru.mbt — Russian number spelling (cardinal, year).
//
// Russian quirks handled here:
//   * every scale word has three plural forms selected by the group value:
//       1      -> "тысяча" / "миллион"
//       2..4   -> "тысячи" / "миллиона"   (but not 11..14)
//       0, 5+  -> "тысяч" / "миллионов"
//     so 1000 -> "одна тысяча", 2000 -> "две тысячи", 5000 -> "пять тысяч";
//   * "тысяча" is feminine, so the preceding number uses "одна" / "две"
//     instead of "один" / "два"; scale words from million up are masculine;
//   * groups are separated by a single space and no commas are written.

// Scale words for a group value of 1. Index = group power.

///|
let ru_scale_one : Array[String] = [
  "", "тысяча", "миллион", "миллиард", "триллион", "квадриллион",
  "квинтиллион", "секстиллион", "септиллион", "октиллион",
  "нониллион", "дециллион",
]

// Scale words for a group value of 2..4 (but not 11..14).

///|
let ru_scale_few : Array[String] = [
  "", "тысячи", "миллиона", "миллиарда", "триллиона",
  "квадриллиона", "квинтиллиона", "секстиллиона",
  "септиллиона", "октиллиона", "нониллиона", "дециллиона",
]

// Scale words for every other group value (0, 5..20, 25..30, ...).

///|
let ru_scale_many : Array[String] = [
  "", "тысяч", "миллионов", "миллиардов", "триллионов",
  "квадриллионов", "квинтиллионов", "секстиллионов",
  "септиллионов", "октиллионов", "нониллионов",
  "дециллионов",
]

// Hundreds: 1 -> "сто", 2 -> "двести", ... 9 -> "девятьсот".

///|
let ru_hundreds : Array[String] = [
  "", "сто", "двести", "триста", "четыреста", "пятьсот",
  "шестьсот", "семьсот", "восемьсот", "девятьсот",
]

///|
pub fn lang_ru() -> Lang {
  {
    variant: Ru,
    zero: "ноль",
    ones: [
      "ноль", "один", "два", "три", "четыре", "пять", "шесть",
      "семь", "восемь", "девять",
    ],
    teens: [
      "десять", "одиннадцать", "двенадцать", "тринадцать",
      "четырнадцать", "пятнадцать", "шестнадцать",
      "семнадцать", "восемнадцать", "девятнадцать",
    ],
    tens: [
      "", "десять", "двадцать", "тридцать", "сорок", "пятьдесят",
      "шестьдесят", "семьдесят", "восемьдесят", "девяносто",
    ],
    hundred: "сто",
    thousands: ru_scale_many,
    negative: "минус",
    decimal: "запятая",
    comma_sep: false,
  }
}

///|
/// The unit word, honouring grammatical gender: "один"/"одна",
/// "два"/"две"; 3..9 are gender-neutral.
fn ru_unit(l : Lang, u : Int, feminine : Bool) -> String {
  if feminine {
    if u == 1 {
      return "одна"
    }
    if u == 2 {
      return "две"
    }
  }
  l.ones[u]
}

///|
fn Lang::below100_ru(self : Lang, r : Int, feminine : Bool) -> String {
  if r < 10 {
    return ru_unit(self, r, feminine)
  }
  if r < 20 {
    return self.teens[r - 10]
  }
  let d = r / 10
  let u = r % 10
  if u == 0 {
    return self.tens[d]
  }
  self.tens[d] + " " + ru_unit(self, u, feminine)
}

///|
fn Lang::triple_ru(self : Lang, t : Int, feminine : Bool) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_ru(r, feminine)
  }
  if r == 0 {
    return ru_hundreds[h]
  }
  ru_hundreds[h] + " " + self.below100_ru(r, feminine)
}

///|
/// Pick the plural form of a scale word: 1 = one, 2 = few (2..4),
/// 3 = many (everything else, including 11..14).
fn ru_form(n : Int) -> Int {
  let m100 = n % 100
  if m100 >= 11 && m100 <= 14 {
    return 3
  }
  let m10 = n % 10
  if m10 == 1 {
    return 1
  }
  if m10 >= 2 && m10 <= 4 {
    return 2
  }
  3
}

///|
fn ru_scale(power : Int, form : Int) -> String {
  if form == 1 {
    ru_scale_one[power]
  } else if form == 2 {
    ru_scale_few[power]
  } else {
    ru_scale_many[power]
  }
}

///|
fn Lang::cardinal_ru(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  let groups = group3(n)
  let parts : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    // "тысяча" is feminine: 1 -> "одна тысяча", 2 -> "две тысячи".
    let feminine = power == 1
    let mut s = self.triple_ru(t, feminine)
    if power > 0 {
      s = s + " " + ru_scale(power, ru_form(t))
    }
    parts.push(s)
  }
  let joined = join_parts(parts, " ")
  if neg {
    self.negative + " " + joined
  } else {
    joined
  }
}

///|
/// Russian years are read as a plain cardinal ("2024" ->
/// "две тысячи двадцать четыре"), so this delegates to `cardinal_ru`.
pub fn year_ru(n : BigInt) -> String {
  lang_ru().cardinal_ru(n)
}
