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
fn pt_pt_group_value(groups : Array[(BigInt, Int)], power : Int) -> Int {
  for i = 0; i < groups.length(); i = i + 1 {
    let (value, p) = groups[i]
    if p == power {
      return value.to_int()
    }
  }
  0
}

///|
/// Speak 0..999999 as a plain number ("mil e um", "quatro mil quatrocentos e
/// quarenta"), used inside a long-scale phrase.
fn Lang::pt_pt_below_million(self : Lang, v : Int) -> String {
  let high = v / 1000
  let low = v % 1000
  if high == 0 {
    return self.triple_pt(low)
  }
  let head = if high == 1 { "mil" } else { self.triple_pt(high) + " mil" }
  if low == 0 {
    head
  } else {
    head + " e " + self.triple_pt(low)
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
  let top = groups[0].1
  let texts : Array[String] = []
  // Long scale: 10^(2k+1) and 10^(2k) form one phrase
  // (4_440_000_000 -> "quatro mil quatrocentos e quarenta milhões").
  let mut p = if top % 2 == 0 { top } else { top - 1 }
  while p >= 2 {
    let odd = pt_pt_group_value(groups, p + 1)
    let even = pt_pt_group_value(groups, p)
    let value = odd * 1000 + even
    if value > 0 {
      let idx = p / 2
      let s = if value == 1 {
        "um " + pt_pt_long_sing[idx]
      } else {
        self.pt_pt_below_million(value) + " " + pt_pt_long_plur[idx]
      }
      texts.push(s)
    }
    p = p - 2
  }
  let thousands = pt_pt_group_value(groups, 1)
  if thousands > 0 {
    texts.push(
      if thousands == 1 {
        "mil"
      } else {
        self.triple_pt(thousands) + " mil"
      },
    )
  }
  let units = pt_pt_group_value(groups, 0)
  if units > 0 {
    texts.push(self.triple_pt(units))
  }
  let joined = pt_postprocess(join_parts(texts, " e "), true)
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
