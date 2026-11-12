// lang_es.mbt — Spanish number spelling (cardinal, year).

// Long-scale scale words. Index = group power.

///|
let es_scale_sing : Array[String] = [
  "", "mil", "millón", "mil millones", "billón", "mil billones", "trillón", "mil trillones",
  "cuatrillón",
]

///|
let es_scale_plur : Array[String] = [
  "", "mil", "millones", "mil millones", "billones", "mil billones", "trillones",
  "mil trillones", "cuatrillones",
]

// Hundreds words: 1 -> "cien"/"ciento", 2..9 -> "doscientos", ...

///|
let es_hundreds : Array[String] = [
  "cien", "cien", "doscientos", "trescientos", "cuatrocientos", "quinientos", "seiscientos",
  "setecientos", "ochocientos", "novecientos",
]

// 21..29 compound forms.

///|
let es_veinti : Array[String] = [
  "veintiuno", "veintidós", "veintitrés", "veinticuatro", "veinticinco", "veintiséis",
  "veintisiete", "veintiocho", "veintinueve",
]

///|
pub fn lang_es() -> Lang {
  {
    variant: Es,
    zero: "cero",
    ones: [
      "cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve",
    ],
    teens: [
      "diez", "once", "doce", "trece", "catorce", "quince", "dieciséis", "diecisiete",
      "dieciocho", "diecinueve",
    ],
    tens: [
      "", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta",
      "ochenta", "noventa",
    ],
    hundred: "ciento",
    thousands: es_scale_plur,
    negative: "menos",
    decimal: "coma",
    comma_sep: false,
  }
}

///|
fn Lang::below100_es(self : Lang, r : Int) -> String {
  if r < 10 {
    return self.ones[r]
  }
  if r < 20 {
    return self.teens[r - 10]
  }
  if r == 20 {
    return "veinte"
  }
  if r > 20 && r < 30 {
    return es_veinti[r - 21]
  }
  let d = r / 10
  let u = r % 10
  if u == 0 {
    return self.tens[d]
  }
  return self.tens[d] + " y " + self.ones[u]
}

///|
fn Lang::triple_es(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_es(r)
  }
  let prefix = if h == 1 {
    if r == 0 {
      "cien"
    } else {
      "ciento"
    }
  } else {
    es_hundreds[h]
  }
  if r == 0 {
    return prefix
  }
  return prefix + " " + self.below100_es(r)
}

///|
fn es_group_value(groups : Array[(BigInt, Int)], power : Int) -> Int {
  for i = 0; i < groups.length(); i = i + 1 {
    let (value, p) = groups[i]
    if p == power {
      return value.to_int()
    }
  }
  0
}

///|
/// Speak 0..999999 as a plain number ("mil", "mil uno", "cuatro mil
/// cuatrocientos cuarenta"), used inside a long-scale phrase.
fn Lang::es_below_million(self : Lang, v : Int) -> String {
  let high = v / 1000
  let low = v % 1000
  if high == 0 {
    return self.triple_es(low)
  }
  let head = if high == 1 { "mil" } else { self.triple_es(high) + " mil" }
  if low == 0 {
    head
  } else {
    head + " " + self.triple_es(low)
  }
}

///|
fn Lang::cardinal_es(self : Lang, n : BigInt) -> String {
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
  let parts : Array[String] = []
  // Long scale: the groups at 10^(2k+1) and 10^(2k) form one phrase
  // (4_440_000_000 -> "cuatro mil cuatrocientos cuarenta millones").
  let mut p = if top % 2 == 0 { top } else { top - 1 }
  while p >= 2 {
    let odd = es_group_value(groups, p + 1)
    let even = es_group_value(groups, p)
    let value = odd * 1000 + even
    if value > 0 {
      let s = if value == 1 {
        "un " + es_scale_sing[p]
      } else {
        self.es_below_million(value) + " " + es_scale_plur[p]
      }
      parts.push(s)
    }
    p = p - 2
  }
  let thousands = es_group_value(groups, 1)
  if thousands > 0 {
    parts.push(
      if thousands == 1 {
        "mil"
      } else {
        self.triple_es(thousands) + " mil"
      },
    )
  }
  let units = es_group_value(groups, 0)
  if units > 0 {
    parts.push(self.triple_es(units))
  }
  let joined = join_parts(parts, " ")
  if neg {
    "menos " + joined
  } else {
    joined
  }
}

///|
/// Spanish years use the plain cardinal reading, matching upstream
/// ("2024" -> "dos mil veinticuatro").
pub fn year_es(n : BigInt) -> String {
  lang_es().cardinal_es(n)
}
