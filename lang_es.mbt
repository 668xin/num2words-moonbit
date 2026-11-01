// lang_es.mbt — Spanish number spelling (cardinal, year).

// Long-scale scale words. Index = group power.
let es_scale_sing : Array[String] = [
  "", "mil", "millón", "mil millones", "billón", "mil billones", "trillón",
  "mil trillones", "cuatrillón",
]
let es_scale_plur : Array[String] = [
  "", "mil", "millones", "mil millones", "billones", "mil billones",
  "trillones", "mil trillones", "cuatrillones",
]

// Hundreds words: 1 -> "cien"/"ciento", 2..9 -> "doscientos", ...
let es_hundreds : Array[String] = [
  "cien", "cien", "doscientos", "trescientos", "cuatrocientos", "quinientos",
  "seiscientos", "setecientos", "ochocientos", "novecientos",
]

// 21..29 compound forms.
let es_veinti : Array[String] = [
  "veintiuno", "veintidós", "veintitrés", "veinticuatro", "veinticinco",
  "veintiséis", "veintisiete", "veintiocho", "veintinueve",
]

pub fn lang_es() -> Lang {
  {
    variant: Es,
    zero: "cero",
    ones: [
      "cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho",
      "nueve",
    ],
    teens: [
      "diez", "once", "doce", "trece", "catorce", "quince", "dieciséis",
      "diecisiete", "dieciocho", "diecinueve",
    ],
    tens: [
      "", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta",
      "setenta", "ochenta", "noventa",
    ],
    hundred: "ciento",
    thousands: es_scale_plur,
    negative: "menos",
    decimal: "coma",
    comma_sep: false,
  }
}

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

fn Lang::triple_es(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_es( r)
  }
  let prefix = if h == 1 {
    if r == 0 { "cien" } else { "ciento" }
  } else {
    es_hundreds[h]
  }
  if r == 0 {
    return prefix
  }
  return prefix + " " + self.below100_es( r)
}

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
  let parts : Array[String] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    let mut s = self.triple_es( t)
    if power > 0 {
      if power == 1 {
        if t == 1 {
          s = "mil"
        } else {
          s = s + " mil"
        }
      } else if t == 1 {
        s = "un " + es_scale_sing[power]
      } else {
        s = s + " " + es_scale_plur[power]
      }
    }
    parts.push(s)
  }
  let joined = join_parts(parts, " ")
  if neg {
    "menos " + joined
  } else {
    joined
  }
}

/// Spanish year reading (e.g. 2024 -> "veinte veinticuatro").
pub fn year_es(n : BigInt) -> String {
  if n < BigInt::from_int(1000) || n > BigInt::from_int(9999) {
    return lang_es().cardinal_es( n)
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  if n % BigInt::from_int(1000) == BigInt::from_int(0) {
    return lang_es().cardinal_es( n)
  }
  let s = n.to_string()
  let first = BigInt::from_string(s[0:2].to_owned()).to_int()
  let second = BigInt::from_string(s[2:4].to_owned()).to_int()
  if second == 0 {
    // 1900 -> "mil novecientos"
    return lang_es().cardinal_es( n)
  }
  let a = lang_es().cardinal_es( BigInt::from_int(first))
  let b = lang_es().cardinal_es( BigInt::from_int(second))
  if neg {
    "menos " + a + " " + b
  } else {
    a + " " + b
  }
}
