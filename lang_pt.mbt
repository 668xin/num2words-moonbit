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
let pt_scale_sing : Array[String] = [
  "", "mil", "milhão", "bilhão", "trilhão", "quatrilhão", "quintilhão",
  "sextilhão",
]

// Scale words for group values >= 2. Index = group power.
let pt_scale_plur : Array[String] = [
  "", "mil", "milhões", "bilhões", "trilhões", "quatrilhões", "quintilhões",
  "sextilhões",
]

// Hundreds: 2 -> "duzentos", 3 -> "trezentos", ... 9 -> "novecentos".
let pt_hundreds : Array[String] = [
  "", "", "duzentos", "trezentos", "quatrocentos", "quinhentos",
  "seiscentos", "setecentos", "oitocentos", "novecentos",
]

pub fn lang_pt() -> Lang {
  {
    variant: Pt,
    zero: "zero",
    ones: [
      "zero", "um", "dois", "três", "quatro", "cinco", "seis", "sete",
      "oito", "nove",
    ],
    teens: [
      "dez", "onze", "doze", "treze", "catorze", "quinze", "dezesseis",
      "dezessete", "dezoito", "dezenove",
    ],
    tens: [
      "", "dez", "vinte", "trinta", "quarenta", "cinquenta", "sessenta",
      "setenta", "oitenta", "noventa",
    ],
    hundred: "cento",
    thousands: pt_scale_plur,
    negative: "menos",
    decimal: "vírgula",
    comma_sep: false,
  }
}

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

/// "e" joins a scale group to the next one when the next group is below 100
/// or an exact multiple of 100 ("mil e um", "mil e cem"); otherwise a plain
/// space is used ("mil duzentos e trinta e quatro").
fn pt_group_sep(next_triple : Int) -> String {
  if next_triple < 100 || next_triple % 100 == 0 {
    " e "
  } else {
    " "
  }
}

fn Lang::cardinal_pt(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  let groups = group3(n)
  let texts : Array[String] = []
  let triples : Array[Int] = []
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
    triples.push(t)
  }
  let mut joined = ""
  for i = 0; i < texts.length(); i = i + 1 {
    if i > 0 {
      joined = joined + pt_group_sep(triples[i])
    }
    joined = joined + texts[i]
  }
  if neg {
    "menos " + joined
  } else {
    joined
  }
}

/// Portuguese years are read as a plain cardinal ("2024" ->
/// "dois mil e vinte e quatro"), so this delegates to `cardinal_pt`.
pub fn year_pt(n : BigInt) -> String {
  lang_pt().cardinal_pt(n)
}
