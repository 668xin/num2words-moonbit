// lang_pt.mbt — Portuguese number spelling (cardinal, year). Brazilian variant.
//
// Portuguese quirks handled here:
//   * the conjunction "e" links tens to units ("vinte e um") and hundreds to
//     the remainder ("cento e um", "duzentos e trinta e quatro");
//   * 100 is "cem" on its own but "cento" when a remainder follows;
//   * 200..900 use dedicated plural forms ("duzentos", "trezentos", ...);
//   * between scale groups, "e" appears only when the following group is
//     below 100 or an exact multiple of 100:
//       1001  -> "mil e um"        1100 -> "mil e cem"
//       1234  -> "mil duzentos e trinta e quatro"
//   * short scale: mil (10^3), milhao (10^6), bilhao (10^9), trilhao (10^12).

// Scale words for a group value of exactly 1. Index = group power.

///|
let pt_scale_sing : Array[String] = [
  "", "mil", "milhão", "bilhão", "trilhão", "quatrilhão", "quintilhão", "sextilhão",
]

// Scale words for group values >= 2. Index = group power.

///|
let pt_scale_plur : Array[String] = [
  "", "mil", "milhões", "bilhões", "trilhões", "quatrilhões", "quintilhões",
  "sextilhões",
]

// Hundreds: 2 -> "duzentos", 3 -> "trezentos", ... 9 -> "novecentos".

///|
let pt_hundreds : Array[String] = [
  "", "", "duzentos", "trezentos", "quatrocentos", "quinhentos", "seiscentos", "setecentos",
  "oitocentos", "novecentos",
]

///|
pub fn lang_pt() -> Lang {
  {
    variant: Pt,
    zero: "zero",
    ones: [
      "zero", "um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove",
    ],
    teens: [
      "dez", "onze", "doze", "treze", "catorze", "quinze", "dezesseis", "dezessete",
      "dezoito", "dezenove",
    ],
    tens: [
      "", "dez", "vinte", "trinta", "quarenta", "cinquenta", "sessenta", "setenta",
      "oitenta", "noventa",
    ],
    hundred: "cento",
    thousands: pt_scale_plur,
    negative: "menos",
    decimal: "vírgula",
    comma_sep: false,
  }
}

///|
fn Lang::below100_pt(self : Lang, r : Int) -> String {
  if r < 10 {
    return self.ones[r]
  }
  if r < 20 {
    return self.teens[r - 10]
  }
  let d = r / 10
  let u = r % 10
  if u == 0 {
    return self.tens[d]
  }
  // 21 -> "vinte e um", 32 -> "trinta e dois"
  return self.tens[d] + " e " + self.ones[u]
}

///|
fn Lang::triple_pt(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_pt(r)
  }
  if h == 1 {
    // 100 -> "cem", 101 -> "cento e um", 110 -> "cento e dez"
    if r == 0 {
      return "cem"
    }
    return "cento e " + self.below100_pt(r)
  }
  if r == 0 {
    return pt_hundreds[h]
  }
  // 234 -> "duzentos e trinta e quatro"
  return pt_hundreds[h] + " e " + self.below100_pt(r)
}

///|
fn pt_find_from(s : String, sub : String, from : Int) -> Int {
  let n = s.length()
  let m = sub.length()
  let mut i = from
  while i + m <= n {
    if s[i:i + m].to_owned() == sub {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn pt_replace_all(s : String, old : String, new : String) -> String {
  join_parts(split_to_array(s, old), new)
}

///|
fn pt_replace_first(s : String, old : String, new : String) -> String {
  let idx = pt_find_from(s, old, 0)
  if idx < 0 {
    s
  } else {
    s[0:idx].to_owned() + new + s[idx + old.length():s.length()].to_owned()
  }
}

///|
/// A word matched by upstream's `\w*entos?` (the hundreds words, excluding
/// the standalone "cem").
fn pt_is_hundreds_token(t : String) -> Bool {
  t == "cento" ||
  t == "duzentos" ||
  t == "trezentos" ||
  t == "quatrocentos" ||
  t == "quinhentos" ||
  t == "seiscentos" ||
  t == "setecentos" ||
  t == "oitocentos" ||
  t == "novecentos"
}

///|
/// Upstream's post-processing regex:
/// `.*<ext> e \w*entos? (?=.*e)` — a scale word followed by " e ", a hundreds
/// word, and at least one more "e" later.
fn pt_has_scale_e(s : String, ext : String) -> Bool {
  let marker = ext + " e "
  let mut from = 0
  while true {
    let idx = pt_find_from(s, marker, from)
    if idx < 0 {
      break
    }
    let after = idx + marker.length()
    let rest = s[after:s.length()].to_owned()
    let mut end = 0
    while end < rest.length() && rest[end:end + 1].to_owned() != " " {
      end = end + 1
    }
    let token = rest[0:end].to_owned()
    if pt_is_hundreds_token(token) {
      let tail = rest[end:rest.length()].to_owned()
      if tail.contains("e") {
        return true
      }
    }
    from = after
  }
  false
}

///|
/// Remove the "e" that upstream's post-processing drops. European Portuguese
/// removes every occurrence of `<ext> e` once the regex matches; Brazilian
/// Portuguese removes only the first.
fn pt_postprocess(s : String, european : Bool) -> String {
  let exts : Array[String] = if european {
    [
      "mil", "milhão", "milhões", "mil milhões", "bilião", "biliões", "mil biliões",
    ]
  } else {
    [
      "mil", "milhão", "milhões", "bilhão", "bilhões", "trilhão", "trilhões",
      "quatrilhão", "quatrilhões",
    ]
  }
  let mut out = s
  for i = 0; i < exts.length(); i = i + 1 {
    let ext = exts[i]
    if pt_has_scale_e(out, ext) {
      let old = ext + " e"
      out = if european {
        pt_replace_all(out, old, ext)
      } else {
        pt_replace_first(out, old, ext)
      }
    }
  }
  out
}

///|
fn Lang::cardinal_pt(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  let groups = group3(n)
  let texts : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    let mut s = self.triple_pt(t)
    if power > 0 {
      if power == 1 {
        // 1000 -> "mil"; 2000 -> "dois mil"
        s = if t == 1 { "mil" } else { s + " mil" }
      } else if t == 1 {
        // 1000000 -> "um milhão"
        s = "um " + pt_scale_sing[power]
      } else {
        // 2000000 -> "dois milhões"
        s = s + " " + pt_scale_plur[power]
      }
    }
    texts.push(s)
  }
  let joined = pt_postprocess(join_parts(texts, " e "), false)
  if neg {
    "menos " + joined
  } else {
    joined
  }
}

///|
/// Portuguese years are read as a plain cardinal ("2024" ->
/// "dois mil e vinte e quatro"), so this delegates to `cardinal_pt`.

///|
/// Upstream reads a negative year as `<year> antes de Cristo`.
pub fn year_pt(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return lang_pt().cardinal_pt(-n) + " antes de Cristo"
  }
  lang_pt().cardinal_pt(n)
}
