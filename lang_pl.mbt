// lang_pl.mbt — Polish number spelling (cardinal, ordinal, year).
//
// Faithful port of upstream num2words 0.5.14 `lang_PL.py`:
//   * cardinal: 3-digit groups, high to low; every group is "hundreds +
//     tens/teens + unit", then a scale word. The scale word inflects by the
//     group value using upstream's `pluralize`:
//       1      -> "tysiąc" / "milion"
//       2..4   -> "tysiące" / "miliony"   (but not 12..14, 112..114, ...)
//       0, 5+  -> "tysięcy" / "milionów"
//     so 1000 -> "tysiąc", 2000 -> "dwa tysiące", 5000 -> "pięć tysięcy";
//   * a lone 1 in any non-final group drops the unit word, so 1000000 is
//     "milion" (not "jeden milion");
//   * words are separated by single spaces and no commas are written;
//   * ordinals only ordinalise the lowest non-zero group; higher groups stay
//     cardinal ("tysiąc dwieście trzydziesty czwarty" for 1234), while a
//     trailing zero group turns the ordinal into a scale word and the rest
//     into a prefix ("dwutysięczny", "stutysięczny").
//
// Deviations (upstream raises instead of returning a string):
//   * negative cardinals would raise ValueError; here they read
//     "minus <abs>";
//   * ordinal 0 raises IndexError upstream; here it returns "";
//   * ordinals whose trailing-zero level is above 3 raise KeyError upstream
//     (the `prefixes_ordinal` table stops at "milairdowy"); here "" is
//     returned;
//   * some level-1 ordinals with a hundreds digit raise IndexError upstream
//     (`HUNDREDS[...]` tuples have only one element): 101000, 110000, 120000,
//     110000000, ...; here "" is returned.

// --- cardinal tables --------------------------------------------------------

///|
/// Hundreds: 1 -> "sto", 2 -> "dwieście", ... 9 -> "dziewięćset".
let pl_hundreds : Array[String] = [
  "", "sto", "dwieście", "trzysta", "czterysta", "pięćset", "sześćset", "siedemset",
  "osiemset", "dziewięćset",
]

///|
/// Tens 20..90 (index = tens digit). Index 1 is unused: teens come from
/// `Lang.teens`.
let pl_twenties : Array[String] = [
  "", "", "dwadzieścia", "trzydzieści", "czterdzieści", "pięćdziesiąt", "sześćdziesiąt",
  "siedemdziesiąt", "osiemdziesiąt", "dziewięćdziesiąt",
]

// --- ordinal tables ---------------------------------------------------------
//
// Upstream stores each ordinal form as a pair: index 0 is the standalone word
// ("drugi", "dwudziesty", "setny"), index 1 the combining stem used when the
// group is followed by a scale word ("dwu", "dwudziesto", "stu").

///|
let pl_ones_ord_standalone : Array[String] = [
  "", "pierwszy", "drugi", "trzeci", "czwarty", "piąty", "szósty", "siódmy", "ósmy",
  "dziewiąty", "dziesiąty", "jedenasty", "dwunasty", "trzynasty", "czternasty",
  "piętnasty", "szesnasty", "siedemnasty", "osiemnasty", "dziewiętnasty",
]

///|
let pl_ones_ord_combining : Array[String] = [
  "", "pierwszo", "dwu", "trzy", "cztero", "pięcio", "sześcio", "siedmio", "ośmio",
  "dziewięcio", "dziesięcio", "jedenasto", "dwunasto", "trzynasto", "czternasto",
  "piętnasto", "szesnasto", "siedemnasto", "osiemnasto", "dziewiętnasto",
]

///|
let pl_twenties_ord_standalone : Array[String] = [
  "", "", "dwudziesty", "trzydziesty", "czterdziesty", "pięćdziesiąty", "sześćdziesiąty",
  "siedemdziesiąty", "osiemdziesiąty", "dziewięćdziesiąty",
]

///|
/// Upstream's combining stem for 30 is the typo "trzydiesto"; preserved.
let pl_twenties_ord_combining : Array[String] = [
  "", "", "dwudziesto", "trzydiesto", "czterdziesto", "pięćdziesięcio", "sześćdziesięcio",
  "siedemdziesięcio", "osiemdziesięcio", "dziewięćdziesięcio",
]

///|
let pl_hundreds_ord_standalone : Array[String] = [
  "", "setny", "dwusetny", "trzysetny", "czterysetny", "pięćsetny", "sześćsetny",
  "siedemsetny", "osiemsetny", "dziewięćsetny",
]

///|
/// Upstream's combining stems keep its typos "pięcset" and "ośiemset".
let pl_hundreds_ord_combining : Array[String] = [
  "", "stu", "dwustu", "trzystu", "czterystu", "pięcset", "sześćset", "siedemset",
  "ośiemset", "dziewięćset",
]

///|
/// Ordinal scale words for a trailing-zero level: 1 -> "tysięczny",
/// 2 -> "milionowy", 3 -> "milairdowy" (upstream typo, preserved).
let pl_prefixes_ordinal : Array[String] = [
  "", "tysięczny", "milionowy", "milairdowy",
]

///|
fn pl_ones_ord(idx : Int, level : Int) -> String {
  if level == 0 {
    pl_ones_ord_standalone[idx]
  } else {
    pl_ones_ord_combining[idx]
  }
}

///|
fn pl_twenties_ord(idx : Int, level : Int) -> String {
  if level == 0 {
    pl_twenties_ord_standalone[idx]
  } else {
    pl_twenties_ord_combining[idx]
  }
}

///|
fn pl_hundreds_ord(idx : Int, level : Int) -> String {
  if level == 0 {
    pl_hundreds_ord_standalone[idx]
  } else {
    pl_hundreds_ord_combining[idx]
  }
}

// --- scale words ------------------------------------------------------------
//
// Upstream builds the long-scale names from
//   prefixes = mi, bi, try, kwadry, kwinty, seksty, septy, okty, nony, decy
//   suffixes = lion, liard
// in product order, so power 2 = "milion", 3 = "miliard", 4 = "bilion", ...
// up to power 21 = "decyliard". Each name has three plural forms
// (name / name+"y" / name+"ów"); "tysiąc" is irregular.

///|
/// Build the scale table for one plural form (0 = one, 1 = few, 2 = many).
fn pl_make_thousands(form : Int) -> Array[String] {
  let prefixes : Array[String] = [
    "mi", "bi", "try", "kwadry", "kwinty", "seksty", "septy", "okty", "nony", "decy",
  ]
  let thousand = if form == 0 {
    "tysiąc"
  } else if form == 1 {
    "tysiące"
  } else {
    "tysięcy"
  }
  let table : Array[String] = ["", thousand]
  for i = 0; i < prefixes.length(); i = i + 1 {
    let lion = prefixes[i] + "lion"
    let liard = prefixes[i] + "liard"
    if form == 0 {
      table.push(lion)
      table.push(liard)
    } else if form == 1 {
      table.push(lion + "y")
      table.push(liard + "y")
    } else {
      table.push(lion + "ów")
      table.push(liard + "ów")
    }
  }
  table
}

///|
let pl_scale_one : Array[String] = pl_make_thousands(0)

///|
let pl_scale_few : Array[String] = pl_make_thousands(1)

///|
let pl_scale_many : Array[String] = pl_make_thousands(2)

///|
/// Pick the plural form of a group value: 0 = one (only 1), 1 = few (2..4,
/// excluding 12..14 and 112..114, ...), 2 = many (everything else).
fn pl_form(n : Int) -> Int {
  if n == 1 {
    return 0
  }
  let m10 = n % 10
  let m100 = n % 100
  if m10 > 1 && m10 < 5 && (m100 < 10 || m100 > 20) {
    return 1
  }
  2
}

///|
fn pl_scale(power : Int, form : Int) -> String {
  if form == 0 {
    pl_scale_one[power]
  } else if form == 1 {
    pl_scale_few[power]
  } else {
    pl_scale_many[power]
  }
}

// --- Lang descriptor --------------------------------------------------------

///|
pub fn lang_pl() -> Lang {
  {
    variant: Pl,
    zero: "zero",
    ones: [
      "zero", "jeden", "dwa", "trzy", "cztery", "pięć", "sześć", "siedem", "osiem",
      "dziewięć",
    ],
    teens: [
      "dziesięć", "jedenaście", "dwanaście", "trzynaście", "czternaście", "piętnaście",
      "szesnaście", "siedemnaście", "osiemnaście", "dziewiętnaście",
    ],
    tens: [
      "", "dziesięć", "dwadzieścia", "trzydzieści", "czterdzieści", "pięćdziesiąt",
      "sześćdziesiąt", "siedemdziesiąt", "osiemdziesiąt", "dziewięćdziesiąt",
    ],
    hundred: "sto",
    thousands: pl_scale_one,
    negative: "minus",
    decimal: "przecinek",
    comma_sep: false,
  }
}

// --- cardinal ---------------------------------------------------------------

///|
/// Upstream `_int2word`: spell the absolute value of an integer.
fn Lang::cardinal_pl(self : Lang, n : BigInt) -> String {
  let neg = n < BigInt::from_int(0)
  let n = if neg { -n } else { n }
  if !self.supports(n) {
    return ""
  }
  if n == BigInt::from_int(0) {
    return self.zero
  }
  let groups = group3(n)
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
      words.push(pl_hundreds[n3])
    }
    if n2 > 1 {
      words.push(pl_twenties[n2])
    }
    if n2 == 1 {
      words.push(self.teens[n1])
    } else if n1 > 0 && !(power > 0 && x == 1) {
      // A lone "jeden" before a scale word is dropped: 1000 -> "tysiąc".
      words.push(self.ones[n1])
    }
    if power > 0 {
      words.push(pl_scale(power, pl_form(x)))
    }
  }
  let joined = join_parts(words, " ")
  if neg {
    self.negative + " " + joined
  } else {
    joined
  }
}

// --- ordinal ----------------------------------------------------------------

///|
/// Upstream `last_fragment_to_ordinal`. Returns `None` where upstream would
/// raise IndexError: a trailing-zero group ("level" 1) whose hundreds digit is
/// set, combined with a remainder below 20 or a multiple of ten.
fn pl_last_fragment(last : Int, level : Int) -> Array[String]? {
  let words : Array[String] = []
  let n1 = last % 10
  let n2 = last / 10 % 10
  let n3 = last / 100
  let last_two = n2 * 10 + n1
  if last_two == 0 {
    words.push(pl_hundreds_ord(n3, level))
  } else if level == 1 && last == 1 {
    // "tysiączny", "milionowy": the leading unit word disappears.
    return Some(words)
  } else if last_two < 20 {
    if n3 > 0 {
      if level > 0 {
        return None
      }
      words.push(pl_hundreds[n3])
    }
    words.push(pl_ones_ord(last_two, level))
  } else if last_two % 10 == 0 {
    if n3 > 0 {
      if level > 0 {
        return None
      }
      words.push(pl_hundreds[n3])
    }
    words.push(pl_twenties_ord(n2, level))
  } else {
    if n3 > 0 {
      words.push(pl_hundreds[n3])
    }
    words.push(pl_twenties_ord(n2, 0))
    words.push(pl_ones_ord(n1, 0))
  }
  Some(words)
}

///|
/// Upstream `to_ordinal`: only the lowest non-zero group is ordinalised; the
/// higher groups stay cardinal and are emitted as one prefix phrase.
pub fn ordinal_pl(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises IndexError for 0 and an exception for negative input.
    return ""
  }
  if n == BigInt::from_int(0) {
    return ""
  }
  let l = lang_pl()
  if !l.supports(n) {
    return ""
  }
  let groups = group3(n)
  // Upstream pops trailing zero groups and uses their count as `level`, so
  // find the lowest non-zero group here.
  let zero = BigInt::from_int(0)
  let mut last_idx = groups.length() - 1
  let mut found = false
  while last_idx > 0 && !found {
    let (triple, _) = groups[last_idx]
    if triple != zero {
      found = true
    } else {
      last_idx = last_idx - 1
    }
  }
  let (last_group, level) = groups[last_idx]
  let last = last_group.to_int()
  if level > 3 {
    // `prefixes_ordinal` stops at 3 ("milairdowy"); upstream raises KeyError.
    return ""
  }
  let words : Array[String] = []
  if last_idx > 0 {
    // pre_part = number - last * 1000**level, i.e. the groups above `last`.
    let b1000 = BigInt::from_int(1000)
    let mut scale_hi = b1000
    for k = 0; k < level; k = k + 1 {
      scale_hi = scale_hi * b1000
    }
    let pre = n / scale_hi * scale_hi
    words.push(l.cardinal_pl(pre))
  }
  let frag_level = if level == 0 { 0 } else { 1 }
  match pl_last_fragment(last, frag_level) {
    None => return ""
    Some(frag_words) =>
      for w in frag_words {
        words.push(w)
      }
  }
  let mut output = join_parts(words, " ")
  if last == 1 && level > 0 && output != "" {
    // "milion tysięczny": a space separates the prefix from the scale word.
    output = output + " "
  }
  if level > 0 {
    output = output + pl_prefixes_ordinal[level]
  }
  output
}

///|
/// Upstream `to_ordinal_num` falls through to the integer itself.
pub fn ordinal_num_pl(n : BigInt) -> String {
  n.to_string()
}

///|
/// Upstream `to_year` is the plain cardinal (2024 -> "dwa tysiące dwadzieścia
/// cztery"); negative years read "minus ...".
pub fn year_pl(n : BigInt) -> String {
  lang_pl().cardinal_pl(n)
}
