// lang_pt_pt.mbt — European Portuguese (pt_PT).
//
// Differences from the Brazilian variant (lang_pt.mbt):
//   * teens 16/17/19 are "dezasseis"/"dezassete"/"dezanove";
//   * long scale: 10^9 = "mil milhões", 10^12 = "bilião", 10^15 =
//     "mil biliões", 10^18 = "trilião", 10^24 = "quatrilião";
//   * the scale table stops at 10^24 (upstream raises OverflowError for
//     10^27), so larger values are reported as unsupported;
//   * currency uses EUR/USD/GBP/CAD/AUD and "cêntimo(s)" (see lang_currency).
//
// Hundreds, tens, group joining ("mil e um", "mil duzentos e trinta e
// quatro") and zero-cents omission are shared with the Brazilian variant.

///|
let pt_pt_teens : Array[String] = [
  "dez", "onze", "doze", "treze", "catorze", "quinze", "dezasseis", "dezassete",
  "dezoito", "dezanove",
]

// Long-scale names, indexed by half the group power: 1 = milhão (10^6),
// 2 = bilião (10^12), 3 = trilião (10^18), 4 = quatrilião (10^24).

///|
let pt_pt_long_sing : Array[String] = [
  "", "milhão", "bilião", "trilião", "quatrilião",
]

///|
let pt_pt_long_plur : Array[String] = [
  "", "milhões", "biliões", "triliões", "quatriliões",
]

// Group power -> scale word, only used for `supports` / `max_power`; the
// cardinal itself composes "mil milhões" from the long-scale tables.

///|
let pt_pt_thousands : Array[String] = [
  "", "mil", "milhão", "mil milhões", "bilião", "mil biliões", "trilião", "mil triliões",
  "quatrilião",
]

///|
pub fn lang_pt_pt() -> Lang {
  {
    variant: PtPt,
    zero: "zero",
    ones: [
      "zero", "um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove",
    ],
    teens: pt_pt_teens,
    tens: [
      "", "dez", "vinte", "trinta", "quarenta", "cinquenta", "sessenta", "setenta",
      "oitenta", "noventa",
    ],
    hundred: "cento",
    thousands: pt_pt_thousands,
    negative: "menos",
    decimal: "vírgula",
    comma_sep: false,
  }
}

///|
fn Lang::cardinal_pt_pt(self : Lang, n : BigInt) -> String {
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
      } else if power % 2 == 1 {
        // 10^9 -> "mil milhões", 2x10^9 -> "dois mil milhões".
        let word = "mil " + pt_pt_long_plur[(power - 1) / 2]
        s = if t == 1 { word } else { s + " " + word }
      } else {
        let idx = power / 2
        s = if t == 1 {
          "um " + pt_pt_long_sing[idx]
        } else {
          s + " " + pt_pt_long_plur[idx]
        }
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

///|
/// European Portuguese years are read as a plain cardinal, like the Brazilian
/// variant ("2024" -> "dois mil e vinte e quatro").

///|
/// Upstream reads a negative year as `<year> antes de Cristo`.
pub fn year_pt_pt(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    return lang_pt_pt().cardinal_pt_pt(-n) + " antes de Cristo"
  }
  lang_pt_pt().cardinal_pt_pt(n)
}

///|
/// Ordinal separators follow the long scale: 10^9 is "milésimo milionésimo"
/// and 10^12 is "bilionésimo" (unlike Brazilian "bilionésimo"/"trilionésimo").
fn pt_pt_thousand_separator(idx : Int) -> String {
  match idx {
    3 => "milésimo"
    6 => "milionésimo"
    9 => "milésimo milionésimo"
    12 => "bilionésimo"
    15 => "milésimo bilionésimo"
    _ => ""
  }
}

///|
pub fn ordinal_pt_pt(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    ""
  } else {
    pt_ordinal_with(n, pt_pt_thousand_separator)
  }
}
