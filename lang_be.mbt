// lang_be.mbt — Belarusian number spelling (cardinal, ordinal, year, currency).
//
// Faithful port of upstream num2words 0.5.14 `lang_BE.py`:
//   * cardinal: 3-digit groups, high to low, space-separated;
//   * the unit word agrees with the noun's gender: the units group takes the
//     caller's gender ("адзін"/"адна"), the thousands group is always
//     feminine ("адна тысяча", "дзве тысячы") and higher groups are
//     masculine ("адзін мільён");
//   * every scale word has three plural forms selected by the group value:
//       1     -> "тысяча" / "мільён"
//       2..4  -> "тысячы" / "мільёны"   (but not 11..14)
//       0, 5+ -> "тысяч"  / "мільёнаў"
//   * ordinals rewrite the last spoken word ("дваццаць першы"), fuse a whole
//     trailing group with its scale word into one word when the number ends in
//     000 ("двухтысячны"), and carry several upstream quirks, notably that
//     both 70 and 80 become "сямідзясяты";
//   * years are the plain cardinal (negative years keep the "мінус" prefix);
//   * `to_ordinal_num` falls through to the integer itself.
//
// Deviation (upstream reads the fractional part as an integer):
//   * decimal digits are spelled one by one here, so 1.56 is
//     "адзін коска пяць шэсць" rather than "адзін коска пяцьдзясят шэсць";
//     leading zeros match upstream because both spell a zero per digit.

///|
/// Masculine units 0..9 (the default gender).
let be_ones_m : Array[String] = [
  "нуль", "адзін", "два", "тры", "чатыры", "пяць", "шэсць",
  "сем", "восем", "дзевяць",
]

///|
/// Feminine units 0..9 ("адна", "дзве").
let be_ones_f : Array[String] = [
  "нуль", "адна", "дзве", "тры", "чатыры", "пяць", "шэсць",
  "сем", "восем", "дзевяць",
]

///|
/// Neuter units 0..9 ("адно").
let be_ones_n : Array[String] = [
  "нуль", "адно", "два", "тры", "чатыры", "пяць", "шэсць",
  "сем", "восем", "дзевяць",
]

///|
/// 10..19 (index = units digit).
let be_teens : Array[String] = [
  "дзесяць", "адзінаццаць", "дванаццаць", "трынаццаць",
  "чатырнаццаць", "пятнаццаць", "шаснаццаць", "сямнаццаць",
  "васямнаццаць", "дзевятнаццаць",
]

///|
/// Tens 20..90 (index = tens digit).
let be_twenties : Array[String] = [
  "", "", "дваццаць", "трыццаць", "сорак", "пяцьдзясят",
  "шэсцьдзясят", "семдзесят", "восемдзесят", "дзевяноста",
]

///|
/// Hundreds 1..9.
let be_hundreds : Array[String] = [
  "", "сто", "дзвесце", "трыста", "чатырыста", "пяцьсот",
  "шэсцьсот", "семсот", "восемсот", "дзевяцьсот",
]

///|
/// Scale words for a group value of 1. Index = group power.
let be_scale_one : Array[String] = [
  "", "тысяча", "мільён", "мільярд", "трыльён", "квадрыльён",
  "квінтыльён", "секстыльён", "сэптыльён", "актыльён",
  "нанільён",
]

///|
/// Scale words for a group value of 2..4 (but not 11..14).
let be_scale_few : Array[String] = [
  "", "тысячы", "мільёны", "мільярды", "трыльёны", "квадрыльёны",
  "квінтыльёны", "секстыльёны", "сэптыльёны", "актыльёны",
  "нанільёны",
]

///|
/// Scale words for every other group value (0, 5..20, 25..30, ...). Its length
/// also caps the supported range (10^30).
let be_scale_many : Array[String] = [
  "", "тысяч", "мільёнаў", "мільярдаў", "трыльёнаў",
  "квадрыльёнаў", "квінтыльёнаў", "секстыльёнаў",
  "сэптыльёнаў", "актыльёнаў", "нанільёнаў",
]

///|
/// Ordinal stems for the words that have an irregular form.
let be_ords : Array[(String, String)] = [
  ("нуль", "нулявы"),
  ("адзін", "першы"),
  ("два", "другі"),
  ("тры", "трэці"),
  ("чатыры", "чацвёрты"),
  ("пяць", "пяты"),
  ("шэсць", "шосты"),
  ("сем", "сёмы"),
  ("восем", "восьмы"),
  ("дзевяць", "дзявяты"),
  ("сто", "соты"),
  ("тысяча", "тысячны"),
]

///|
/// Genitive stems used in front of "соты" and to ordinalise the preceding word.
let be_ords_adjective : Array[(String, String)] = [
  ("адзін", "адна"),
  ("адна", "адна"),
  ("дзве", "двух"),
  ("тры", "трох"),
  ("чатыры", "чатырох"),
  ("пяць", "пяці"),
  ("шэсць", "шасці"),
  ("сем", "сямі"),
  ("восем", "васьмі"),
  ("дзевяць", "дзевяцi"),
  ("сто", "ста"),
]

///|
/// Genitive tens used when a trailing scale group is fused into one word.
let be_twenties_ord : Array[(String, String)] = [
  ("дваццаць", "дваццаці"),
  ("трыццаць", "трыццаці"),
  ("сорак", "сарака"),
  ("пяцьдзясят", "пяцідзясяці"),
  ("шэсцьдзясят", "шaсцідзясяці"),
  ("семдзесят", "сямідзесяці"),
  ("восемдзесят", "васьмідзесяці"),
  ("дзевяноста", "дзевяноста"),
]

///|
/// True when `s` contains `sub` as a substring.
fn be_contains(s : String, sub : String) -> Bool {
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
fn be_replace_all(s : String, from : String, to : String) -> String {
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
/// Index of the last occurrence of `sub` in `s`, or -1.
fn be_rfind(s : String, sub : String) -> Int {
  let n = s.length()
  let m = sub.length()
  if m > n {
    return -1
  }
  let mut i = n - m
  while i >= 0 {
    if s[i:i + m].to_owned() == sub {
      return i
    }
    i = i - 1
  }
  -1
}

///|
/// Look up an exact key in a small table, or `""` when it is absent (no table
/// value is ever empty, so `""` is a safe "not found" marker).
fn be_lookup(table : Array[(String, String)], key : String) -> String {
  for i = 0; i < table.length(); i = i + 1 {
    let (k, v) = table[i]
    if k == key {
      return v
    }
  }
  ""
}

///|
pub fn lang_be() -> Lang {
  {
    variant: Be,
    zero: "нуль",
    ones: be_ones_m,
    teens: be_teens,
    tens: be_twenties,
    hundred: "сто",
    thousands: be_scale_many,
    negative: "мінус",
    decimal: "коска",
    comma_sep: false,
  }
}

///|
/// Pick the plural form of a scale word: 0 = one, 1 = few (2..4), 2 = many.
fn be_form(n : Int) -> Int {
  let m100 = n % 100
  if m100 < 10 || m100 > 20 {
    let m10 = n % 10
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
fn be_scale(power : Int, form : Int) -> String {
  if form == 0 {
    be_scale_one[power]
  } else if form == 1 {
    be_scale_few[power]
  } else {
    be_scale_many[power]
  }
}

///|
/// The unit word for a group: 0 = masculine, 1 = feminine, 2 = neuter.
fn be_unit(gender : Int, u : Int) -> String {
  if gender == 1 {
    be_ones_f[u]
  } else if gender == 2 {
    be_ones_n[u]
  } else {
    be_ones_m[u]
  }
}

///|
/// Upstream `_int2word`, with the caller's gender applied to the units group.
fn cardinal_be_gendered(l : Lang, n : BigInt, gender : Int) -> String {
  let neg = n < BigInt::from_int(0)
  let abs_n = if neg { -n } else { n }
  if abs_n == BigInt::from_int(0) {
    return l.zero
  }
  if !l.supports(abs_n) {
    return ""
  }
  let groups = group3(abs_n)
  let words : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let x = triple.to_int()
    if x == 0 {
      continue
    }
    let n1 = x % 10
    let n2 = x / 10 % 10
    let n3 = x / 100
    if n3 > 0 {
      words.push(be_hundreds[n3])
    }
    if n2 > 1 {
      words.push(be_twenties[n2])
    }
    if n2 == 1 {
      words.push(be_teens[n1])
    } else if n1 > 0 {
      // Thousands are feminine, higher groups masculine.
      let g = if power == 0 { gender } else if power == 1 { 1 } else { 0 }
      words.push(be_unit(g, n1))
    }
    if power > 0 {
      words.push(be_scale(power, be_form(x)))
    }
  }
  let joined = join_parts(words, " ")
  if neg {
    l.negative + " " + joined
  } else {
    joined
  }
}

///|
fn Lang::cardinal_be(self : Lang, n : BigInt) -> String {
  cardinal_be_gendered(self, n, 0)
}

// ---------------------------------------------------------------------
// Ordinal
// ---------------------------------------------------------------------

///|
/// Rewrite the final word when it is not one of the irregular forms.
fn be_ord_fallback(w : String) -> String {
  let len = w.length()
  let stem = if len >= 3 { w[0:len - 3].to_owned() } else { "" }
  let stem_adj = be_lookup(be_ords_adjective, stem)
  if stem_adj != "" {
    return stem_adj + "соты"
  }
  if len >= 7 && w[len - 7:len].to_owned() == "дзесяць" {
    return "дзясяты"
  }
  if len >= 9 && w[len - 9:len].to_owned() == "семдзесят" {
    return "сямідзясяты"
  }
  let last = w[len - 1:len].to_owned()
  let second_last = if len >= 2 { w[len - 2:len - 1].to_owned() } else { "" }
  if last == "ь" || second_last == "ц" {
    return w[0:len - 2].to_owned() + "ты"
  }
  if last == "к" {
    return be_replace_all(w, "о", "а") + "авы"
  }
  if second_last == "ч" || last == "ч" {
    let mut x = w
    if second_last == "ч" {
      x = w[0:len - 1].to_owned() + "ны"
    }
    let lx = x.length()
    if x[lx - 1:lx].to_owned() == "ч" {
      x = x + "ны"
    }
    return x
  }
  if last == "н" || second_last == "н" {
    return w[0:be_rfind(w, "н") + 1].to_owned() + "ны"
  }
  if len >= 3 && w[len - 3:len].to_owned() == "наў" {
    return w[0:be_rfind(w, "н") + 1].to_owned() + "ны"
  }
  if last == "д" || second_last == "д" {
    return w[0:be_rfind(w, "д") + 1].to_owned() + "ны"
  }
  w
}

///|
/// Replace every genitive-ten word that survived into the last word, so the
/// fused form reads "дваццацідвухтысячны".
fn be_twenties_ord_rewrite(w : String) -> String {
  for i = 0; i < be_twenties_ord.length(); i = i + 1 {
    let (from, to) = be_twenties_ord[i]
    if be_contains(w, from) {
      return be_replace_all(w, from, to)
    }
  }
  w
}

///|
/// True when `w` contains a nominative scale word, which triggers the fused
/// one-word ordinal ("двухтысячны").
fn be_has_scale_word(w : String) -> Bool {
  for i = 0; i < be_scale_one.length(); i = i + 1 {
    let s = be_scale_one[i]
    if s != "" && be_contains(w, s) {
      return true
    }
  }
  false
}

///|
pub fn ordinal_be(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises TypeError for negative ordinals.
    return ""
  }
  let card = lang_be().cardinal_be(n)
  if card == "" {
    return ""
  }
  let outwords = split_to_array(card, " ")
  let count = outwords.length()
  let mut lastword = lower_ascii(outwords[count - 1])
  if count > 1 {
    let idx = count - 2
    let w = outwords[idx]
    let adj = be_lookup(be_ords_adjective, w)
    if adj != "" {
      outwords[idx] = adj
    } else if w == "дзесяць" {
      // "дзесяць" -> "дзесяці"
      outwords[idx] = w[0:w.length() - 1].to_owned() + "і"
    }
  }
  if count == 3 {
    let w = outwords[0]
    if w == "адзін" || w == "адна" {
      outwords[0] = ""
    }
  }
  let ord = be_lookup(be_ords, lastword)
  lastword = if ord != "" { ord } else { be_ord_fallback(lastword) }
  outwords[count - 1] = lastword
  let mut words = outwords
  if words.length() == 2 && be_contains(words[0], "адна") {
    // "адна тысяча": the "адна" is dropped instead of ordinalised.
    words = [words[1]]
  }
  if words.length() > 1 {
    let last = words[words.length() - 1]
    if be_has_scale_word(last) || be_contains(last, "тысяч") {
      let mut fused = ""
      for i = 0; i < words.length(); i = i + 1 {
        fused = fused + be_twenties_ord_rewrite(words[i])
      }
      words = [fused]
    }
  }
  trim_spaces(join_parts(words, " "))
}

///|
/// Upstream `to_ordinal_num` falls through to the integer itself.
pub fn ordinal_num_be(n : BigInt) -> String {
  n.to_string()
}

///|
/// Upstream `to_year` is the plain cardinal.
pub fn year_be(n : BigInt) -> String {
  lang_be().cardinal_be(n)
}
