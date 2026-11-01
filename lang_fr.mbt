// lang_fr.mbt — French number spelling (cardinal, year).
//
// French uses a vigesimal (base-20) system for 70-99:
//   70 = soixante-dix, 71 = soixante et onze, 80 = quatre-vingts,
//   90 = quatre-vingt-dix, 99 = quatre-vingt-dix-neuf.

pub fn lang_fr() -> Lang {
  {
    variant: Fr,
    zero: "zéro",
    ones: [
      "zéro", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit",
      "neuf",
    ],
    teens: [
      "dix", "onze", "douze", "treize", "quatorze", "quinze", "seize",
      "dix-sept", "dix-huit", "dix-neuf",
    ],
    tens: [
      "", "dix", "vingt", "trente", "quarante", "cinquante", "soixante",
      "soixante-dix", "quatre-vingts", "quatre-vingt-dix",
    ],
    hundred: "cent",
    // scale words, index = group power (1 -> mille, 2 -> million, ...)
    thousands: [
      "", "mille", "million", "milliard", "billion", "billiard", "trillion",
      "trilliard", "quintillion", "quintilliard", "sextillion",
    ],
    negative: "moins",
    decimal: "virgule",
    comma_sep: false,
  }
}

fn Lang::small_fr(self : Lang, x : Int) -> String {
  if x < 10 {
    self.ones[x]
  } else {
    self.teens[x - 10]
  }
}

fn Lang::below100_fr(self : Lang, r : Int) -> String {
  if r < 10 {
    return self.ones[r]
  }
  if r < 20 {
    return self.teens[r - 10]
  }
  let d = r / 10
  let u = r % 10
  if d >= 2 && d <= 6 {
    if u == 0 {
      return self.tens[d]
    }
    if u == 1 {
      return self.tens[d] + " et un"
    }
    return self.tens[d] + "-" + self.ones[u]
  }
  if d == 7 {
    let rest = r - 70
    if rest == 0 {
      return "soixante-dix"
    }
    if rest == 1 {
      return "soixante et onze"
    }
    return "soixante-" + self.teens[rest]
  }
  // d == 8 or 9: quatre-vingt(s) + (0..19)
  let rest = r - 80
  if rest == 0 {
    return "quatre-vingts"
  }
  return "quatre-vingt-" + self.small_fr( rest)
}

fn Lang::triple_fr(self : Lang, t : Int) -> String {
  if t == 0 {
    return ""
  }
  let h = t / 100
  let r = t % 100
  if h == 0 {
    return self.below100_fr( r)
  }
  if h == 1 {
    if r == 0 {
      return "cent"
    }
    return "cent " + self.below100_fr( r)
  }
  if r == 0 {
    return self.ones[h] + " cents"
  }
  return self.ones[h] + " cent " + self.below100_fr( r)
}

fn Lang::cardinal_fr(self : Lang, n : BigInt) -> String {
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
    let mut s = self.triple_fr( t)
    if power > 0 {
      if t == 1 && power == 1 {
        s = "mille"
      } else if t == 1 {
        s = "un " + self.thousands[power]
      } else {
        s = s + " " + self.thousands[power]
        if triple > BigInt::from_int(1) && power >= 2 {
          s = s + "s"
        }
      }
    }
    parts.push(s)
  }
  let joined = join_parts(parts, " ")
  if neg {
    "moins " + joined
  } else {
    joined
  }
}

/// French year reading (e.g. 2024 -> "vingt vingt-quatre").
pub fn year_fr(n : BigInt) -> String {
  if n < BigInt::from_int(1000) || n > BigInt::from_int(9999) {
    return lang_fr().cardinal_fr( n)
  }
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  if n % BigInt::from_int(1000) == BigInt::from_int(0) {
    return lang_fr().cardinal_fr( n)
  }
  let s = n.to_string()
  let first = BigInt::from_string(s[0:2].to_owned()).to_int()
  let second = BigInt::from_string(s[2:4].to_owned()).to_int()
  if second == 0 {
    return lang_fr().cardinal_fr( n)
  }
  let a = lang_fr().cardinal_fr( BigInt::from_int(first))
  let b = lang_fr().cardinal_fr( BigInt::from_int(second))
  if neg {
    "moins " + a + " " + b
  } else {
    a + " " + b
  }
}
