// lang_it.mbt — Italian number spelling (cardinal, year).
//
// Italian quirks handled here:
//   * the tens word drops its final vowel before "uno" and "otto"
//     (venti + uno -> "ventuno", trenta + otto -> "trentotto");
//   * "tre" takes an accent when it ends a compound ("ventitré");
//   * "cento" elides its final vowel before "otto" ("centotto"), but keeps it
//     before other vowel-initial units ("centouno");
//   * scale words: "mila" attaches to the preceding word ("duemila") while
//     million-and-above are separate words ("due milioni").

// Scale words for a group value of exactly 1. Index = group power:
// 1 -> 10^3, 2 -> 10^6, 3 -> 10^9, 4 -> 10^12 ...
let it_scale_sing : Array[String] = [
  "", "mille", "milione", "miliardo", "bilione", "biliardo", "trilione",
  "triliardo",
]

// Scale words for group values >= 2. Index = group power.
let it_scale_plur : Array[String] = [
  "", "mila", "milioni", "miliardi", "bilioni", "biliardi", "trilioni",
  "triliardi",
]

// Hundreds: 2 -> "duecento", 3 -> "trecento", ... 9 -> "novecento".
let it_hundreds : Array[String] = [
  "", "", "duecento", "trecento", "quattrocento", "cinquecento", "seicento",
  "settecento", "ottocento", "novecento",
]

// Units as they appear inside a compound: "tre" becomes "tré" in final
// position ("ventitré").
let it_units_compound : Array[String] = [
  "", "uno", "due", "tré", "quattro", "cinque", "sei", "sette", "otto",
  "nove",
]

pub fn lang_it() -> Lang {
  {
    variant: It,
    zero: "zero",
    ones: [
      "zero", "uno", "due", "tre", "quattro", "cinque", "sei", "sette",
      "otto", "nove",
    ],
    teens: [
      "dieci", "undici", "dodici", "tredici", "quattordici", "quindici",
      "sedici", "diciassette", "diciotto", "diciannove",
    ],
    tens: [
      "", "dieci", "venti", "trenta", "quaranta", "cinquanta", "sessanta",
      "settanta", "ottanta", "novanta",
    ],
    hundred: "cento",
    thousands: it_scale_plur,
    negative: "meno",
    decimal: "virgola",
    comma_sep: false,
  }
}

/// Drop the final vowel of a tens/hundreds word (venti -> "vent").
fn it_truncate(w : String) -> String {
  if w.length() == 0 {
    return w
  }
  w[0 : w.length() - 1].to_owned()
}

fn Lang::below100_it(self : Lang, r : Int) -> String {
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
  if u == 1 || u == 8 {
    // venti + uno -> "ventuno"; trenta + otto -> "trentotto"
    return it_truncate(self.tens[d]) + it_units_compound[u]
  }
  // tre carries an accent in final position: 23 -> "ventitré"
  return self.tens[d] + it_units_compound[u]
}

fn Lang::triple_it(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_it(r)
  }
  let prefix = if h == 1 { "cento" } else { it_hundreds[h] }
  if r == 0 {
    return prefix
  }
  let low = self.below100_it(r)
  // The final vowel of "...cento" is dropped when the following part starts
  // with "o": 108 -> "centotto", 180 -> "centottanta", 208 -> "duecentotto".
  // It is kept before other vowels: 101 -> "centouno", 111 -> "centoundici".
  if low[0 : 1].to_owned() == "o" {
    return it_truncate(prefix) + low
  }
  return prefix + low
}

fn Lang::cardinal_it(self : Lang, n : BigInt) -> String {
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
  let powers : Array[Int] = []
  for i = 0; i < groups.length(); i = i + 1 {
    let (triple, power) = groups[i]
    let t = triple.to_int()
    if t == 0 {
      continue
    }
    let mut s = self.triple_it(t)
    if power > 0 {
      if power == 1 {
        // 1000 -> "mille"; 2000 -> "duemila" (attached, no space)
        s = if t == 1 { "mille" } else { s + "mila" }
      } else if t == 1 {
        // 1000000 -> "un milione"
        s = "un " + it_scale_sing[power]
      } else {
        // 2000000 -> "due milioni"
        s = s + " " + it_scale_plur[power]
      }
    }
    parts.push(s)
    powers.push(power)
  }
  // Italian writes a number as one word; a space appears only after a
  // million-or-larger scale word: 1234567 -> "un milione duecento-
  // trentaquattromilacinquecentosessantasette", 2345 -> "duemilatrecento-
  // quarantacinque", 1001 -> "milleuno".
  let mut joined = ""
  for i = 0; i < parts.length(); i = i + 1 {
    if i > 0 && powers[i - 1] >= 2 {
      joined = joined + " "
    }
    joined = joined + parts[i]
  }
  if neg {
    "meno " + joined
  } else {
    joined
  }
}

/// Italian years are read as a plain cardinal ("2024" ->
/// "duemilaventiquattro"), so this simply delegates to `cardinal_it`.
pub fn year_it(n : BigInt) -> String {
  lang_it().cardinal_it(n)
}
