// lang_fi.mbt — Finnish number spelling (cardinal, ordinal, year, currency).
//
// Port of upstream num2words 0.5.14 `lang_FI.py`. Finnish has two features the
// shared 3-digit grouping cannot express on its own:
//   * below a million everything is glued together ("kaksikymmentäyksi",
//     "satayksi", "kaksisataakolmekymmentäneljä"), while a group of 1000 or
//     more is separated by a space ("tuhat kaksisataakolmekymmentäneljä");
//   * a multiplier from 2 to 999 puts the following scale word in the
//     partitive ("kaksisataa", "kaksituhatta", "kaksimiljoonaa"), whereas a
//     bare 1 keeps the nominative ("sata", "tuhat", "miljoona").
//
// Upstream builds the words with its recursive `splitnum`/`merge` pair over a
// dictionary of scale cards. `fi_spell` reproduces that recursion exactly, so
// the greedy choice of scale words (and its quirks around the rare 10^15-sized
// steps) is preserved.

// Scale words: index = power / 2 - 1, covering the even group powers
// 2, 4, ..., 200 (10^6, 10^12, ..., 10^600). Upstream only defines cards for
// 10^6, 10^9 (miljardi), 10^12, 10^18, ...; the missing powers (10^15, ...)
// are spelled by the greedy split as "tuhat" followed by the partitive of the
// next lower scale word ("tuhatbiljoonaa").

///|
let fi_scales : Array[String] = [
  "miljoona", "biljoona", "triljoona", "kvadriljoona", "kvintiljoona", "sekstiljoona",
  "septiljoona", "oktiljoona", "noniljoona", "dekiljoona", "undekiljoona", "duodekiljoona",
  "tredekiljoona", "kvattuordekiljoona", "kvindekiljoona", "sedekiljoona", "septendekiljoona",
  "duodevigintiljoona", "undevigintiljoona", "vigintiljoona", "unvigintiljoona",
  "duovigintiljoona", "trevigintiljoona", "kvattuorvigintiljoona", "kvinvigintiljoona",
  "sevigintiljoona", "septenvigintiljoona", "duodetrigintiljoona", "undetrigintiljoona",
  "trigintiljoona", "untrigintiljoona", "duotrigintiljoona", "tretrigintiljoona",
  "kvattuortrigintiljoona", "kvintrigintiljoona", "setrigintiljoona", "septentrigintiljoona",
  "duodekvadragintiljoona", "undekvadragintiljoona", "kvadragintiljoona", "unkvadragintiljoona",
  "duokvadragintiljoona", "trekvadragintiljoona", "kvattuorkvadragintiljoona", "kvinkvadragintiljoona",
  "sekvadragintiljoona", "septenkvadragintiljoona", "duodekvinkvagintiljoona", "undekvinkvagintiljoona",
  "kvinkvagintiljoona", "unkvinkvagintiljoona", "duokvinkvagintiljoona", "trekvinkvagintiljoona",
  "kvattuorkvinkvagintiljoona", "kvinkvinkvagintiljoona", "sekvinkvagintiljoona",
  "septenkvinkvagintiljoona", "duodeseksagintiljoona", "undeseksagintiljoona", "seagintiljoona",
  "unseksagintiljoona", "duoseksagintiljoona", "treseksagintiljoona", "kvattuorseksagintiljoona",
  "kvinseksagintiljoona", "seseagintiljoona", "septenseksagintiljoona", "duodeseptuagintiljoona",
  "undeseptuagintiljoona", "septenuagintiljoona", "unseptuagintiljoona", "duoseptuagintiljoona",
  "treseptuagintiljoona", "kvattuorseptuagintiljoona", "kvinseptuagintiljoona", "seseptuagintiljoona",
  "septenseptuagintiljoona", "duodeoktogintiljoona", "undeoktogintiljoona", "duodegintiljoona",
  "unoktogintiljoona", "duooktogintiljoona", "treoktogintiljoona", "kvattuoroktogintiljoona",
  "kvinoktogintiljoona", "seoktogintiljoona", "septenoktogintiljoona", "duodenonagintiljoona",
  "undenonagintiljoona", "nonagintiljoona", "unnonagintiljoona", "duononagintiljoona",
  "trenonagintiljoona", "kvattuornonagintiljoona", "kvinnonagintiljoona", "senonagintiljoona",
  "septennonagintiljoona", "duodeiljoona", "undeiljoona", "sentiljoona",
]

// Cardinal and ordinal forms of the units.

///|
let fi_low_card : Array[String] = [
  "nolla", "yksi", "kaksi", "kolme", "neljä", "viisi", "kuusi", "seitsemän", "kahdeksan",
  "yhdeksän",
]

///|
let fi_low_ord : Array[String] = [
  "nollas", "ensimmäinen", "toinen", "kolmas", "neljäs", "viides", "kuudes", "seitsemäs",
  "kahdeksas", "yhdeksäs",
]

// Ordinal stems for 11..19 (they precede "toista"): 11 is "yhdes", not
// "ensimmäinen".

///|
let fi_teen_ord : Array[String] = [
  "", "yhdes", "kahdes", "kolmas", "neljäs", "viides", "kuudes", "seitsemäs", "kahdeksas",
  "yhdeksäs",
]

///|
/// The scale cards used by the recursive split, ordered from the largest key
/// down to 0. `card_nom`/`card_ptv` are the nominative and partitive forms of
/// the cardinal word, `ord_nom` the nominative ordinal.
priv struct FiTables {
  keys : Array[BigInt]
  card_nom : Array[String]
  card_ptv : Array[String]
  ord_nom : Array[String]
}

///|
fn fi_push(
  t : FiTables,
  key : BigInt,
  card : String,
  ptv : String,
  ord : String,
) -> Unit {
  t.keys.push(key)
  t.card_nom.push(card)
  t.card_ptv.push(ptv)
  t.ord_nom.push(ord)
}

///|
/// Build the card dictionary in descending key order. The partitive forms are
/// only needed for the keys that can appear as the right operand of a
/// multiplication (100, 1000 and the million-scale words); the units, teens
/// and tens are never multiplied by a larger key.
fn fi_tables() -> FiTables {
  let keys : Array[BigInt] = []
  let card_nom : Array[String] = []
  let card_ptv : Array[String] = []
  let ord_nom : Array[String] = []
  let t : FiTables = { keys, card_nom, card_ptv, ord_nom, }
  let thousand = BigInt::from_int(1000)
  let million = BigInt::from_int(1000000)
  // 10^600, the largest card upstream defines.
  let mut top = BigInt::from_int(1)
  for i = 0; i < 200; i = i + 1 {
    top = top * thousand
  }
  let mut key = top
  for p = 200; p >= 2; p = p - 2 {
    let nom = fi_scales[p / 2 - 1]
    fi_push(t, key, nom, nom + "a", nom + "s")
    if p == 4 {
      // 10^9 has its own short-scale word between 10^12 and 10^6.
      let miljard = key / thousand
      fi_push(t, miljard, "miljardi", "miljardia", "miljardis")
    }
    key = key / million
  }
  fi_push(t, BigInt::from_int(1000), "tuhat", "tuhatta", "tuhannes")
  fi_push(t, BigInt::from_int(100), "sata", "sataa", "sadas")
  for d = 9; d >= 3; d = d - 1 {
    fi_push(
      t,
      BigInt::from_int(d * 10),
      fi_low_card[d] + "kymmentä",
      "",
      fi_low_ord[d] + "kymmenes",
    )
  }
  fi_push(t, BigInt::from_int(20), "kaksikymmentä", "", "kahdeskymmenes")
  for v = 19; v >= 11; v = v - 1 {
    let u = v - 10
    fi_push(
      t,
      BigInt::from_int(v),
      fi_low_card[u] + "toista",
      "",
      fi_teen_ord[u] + "toista",
    )
  }
  fi_push(t, BigInt::from_int(10), "kymmenen", "", "kymmenes")
  for v = 9; v >= 0; v = v - 1 {
    fi_push(t, BigInt::from_int(v), fi_low_card[v], "", fi_low_ord[v])
  }
  t
}

///|
/// Index of the largest card not greater than `value` (keys are descending).
fn fi_find_key(t : FiTables, value : BigInt) -> Int {
  for i = 0; i < t.keys.length(); i = i + 1 {
    if t.keys[i] <= value {
      return i
    }
  }
  t.keys.length() - 1
}

///|
/// Upstream `splitnum` + `clean` for a non-negative value: pick the largest
/// card not greater than the value, spell the multiplier (a bare 1 contributes
/// nothing), then append the remainder. A cardinal multiplier from 2 leaves the
/// scale word in the partitive; an ordinal multiplier 2 becomes "kahdes"
/// ("kahdessadas", "kahdestuhannes") instead of "toinen".
fn fi_spell(t : FiTables, value : BigInt, is_ordinal : Bool) -> String {
  if value == BigInt::from_int(0) {
    let last = t.keys.length() - 1
    return if is_ordinal { t.ord_nom[last] } else { t.card_nom[last] }
  }
  let idx = fi_find_key(t, value)
  let key = t.keys[idx]
  let div = value / key
  let rest = value % key
  let mut acc = if is_ordinal { t.ord_nom[idx] } else { t.card_nom[idx] }
  let mut acc_num = key
  if div > BigInt::from_int(1) {
    let mut left = fi_spell(t, div, is_ordinal)
    if is_ordinal && div == BigInt::from_int(2) {
      left = "kahdes"
    }
    let right = if is_ordinal { t.ord_nom[idx] } else { t.card_ptv[idx] }
    acc = left + right
    acc_num = div * key
  }
  if rest != BigInt::from_int(0) {
    let tail = fi_spell(t, rest, is_ordinal)
    // Groups of 1000 and above are separated by a space.
    acc = acc +
      (if acc_num >= BigInt::from_int(1000) { " " } else { "" }) +
      tail
  }
  acc
}

///|
fn fi_thousands() -> Array[String] {
  let out : Array[String] = []
  out.push("")
  out.push("tuhat")
  for p = 2; p <= 200; p = p + 1 {
    if p % 2 == 0 {
      out.push(fi_scales[p / 2 - 1])
    } else if p == 3 {
      out.push("miljardi")
    } else {
      // Powers that upstream has no card for: the bare value is spelled as
      // "tuhat" + partitive of the next lower scale word.
      out.push("tuhat" + fi_scales[(p - 1) / 2 - 1] + "a")
    }
  }
  out
}

///|
pub fn lang_fi() -> Lang {
  {
    variant: Fi,
    zero: "nolla",
    ones: fi_low_card,
    teens: [
      "kymmenen", "yksitoista", "kaksitoista", "kolmetoista", "neljätoista", "viisitoista",
      "kuusitoista", "seitsemäntoista", "kahdeksantoista", "yhdeksäntoista",
    ],
    tens: [
      "", "kymmenen", "kaksikymmentä", "kolmekymmentä", "neljäkymmentä", "viisikymmentä",
      "kuusikymmentä", "seitsemänkymmentä", "kahdeksankymmentä", "yhdeksänkymmentä",
    ],
    hundred: "sata",
    thousands: fi_thousands(),
    negative: "miinus",
    decimal: "pilkku",
    comma_sep: false,
  }
}

///|
fn Lang::cardinal_fi(self : Lang, n : BigInt) -> String {
  if n == BigInt::from_int(0) {
    return self.zero
  }
  if !self.supports(n) {
    return ""
  }
  let neg = n < BigInt::from_int(0)
  let value = if neg { -n } else { n }
  let words = fi_spell(fi_tables(), value, false)
  if neg {
    self.negative + " " + words
  } else {
    words
  }
}

///|
/// Finnish ordinals: 1 ensimmäinen, 2 toinen, 3 kolmas, 10 kymmenes,
/// 11 yhdestoista, 21 kahdeskymmenesensimmäinen, 100 sadas, 1000 tuhannes.
pub fn ordinal_fi(n : BigInt) -> String {
  if n < BigInt::from_int(0) {
    // Upstream raises TypeError for negative ordinals.
    return ""
  }
  if !lang_fi().supports(n) {
    return ""
  }
  fi_spell(fi_tables(), n, true)
}

///|
/// Upstream `to_ordinal_num` raises `NotImplementedError`, so the string API
/// reports the mode as unavailable.
pub fn ordinal_num_fi(_n : BigInt) -> String {
  ""
}

///|
/// Upstream `to_year` spells the cardinal without spaces and appends
/// " ennen ajanlaskun alkua" for negative years.
pub fn year_fi(n : BigInt) -> String {
  let l = lang_fi()
  let neg = n < BigInt::from_int(0)
  let abs_n = if neg { -n } else { n }
  let compact = join_parts(split_to_array(l.cardinal_fi(abs_n), " "), "")
  if neg {
    compact + " ennen ajanlaskun alkua"
  } else {
    compact
  }
}

///|
/// Euro-style currency words: "<amount> <unit> ja <cents> <cent>", with both
/// nouns singular after 1 and plural otherwise ("yksi euro ja viisikymmentä
/// senttiä", "nolla euroa ja nolla senttiä"). `units` and `cents` are already
/// split into major units and 0..99 cents.
fn currency_fi(
  units : BigInt,
  cents : BigInt,
  neg : Bool,
  code : String,
) -> Result[String, String] {
  let (unit_one, unit_many, cent_one, cent_many) = match code {
    "BRL" => ("real", "realia", "centavo", "centavoa")
    "CHF" => ("frangi", "frangia", "rappen", "rappenia")
    "CNY" => ("juan", "juania", "fen", "feniä")
    "EUR" => ("euro", "euroa", "sentti", "senttiä")
    "FIM" => ("markka", "markkaa", "penni", "penniä")
    "INR" => ("rupia", "rupiaa", "paisa", "paisaa")
    "JPY" => ("jeni", "jeniä", "sen", "seniä")
    "KRW" => ("won", "wonia", "jeon", "jeonia")
    "KPW" => ("won", "wonia", "chon", "chonia")
    "MXN" => ("peso", "pesoa", "centavo", "centavoa")
    "RUB" => ("rupla", "ruplaa", "kopeekka", "kopeekkaa")
    "TRY" => ("liira", "liiraa", "kuruş", "kuruşia")
    "ZAR" => ("randi", "randia", "sentti", "senttiä")
    "DKK" | "ISK" | "NOK" | "SEK" => ("kruunu", "kruunua", "äyri", "äyriä")
    "AUD" | "CAD" | "HKD" | "NZD" | "SGD" | "USD" =>
      ("dollari", "dollaria", "sentti", "senttiä")
    "GBP" => ("punta", "puntaa", "penny", "pennyä")
    _ => return Err("currency code not supported for fi: " + code)
  }
  let l = lang_fi()
  if !l.supports(units) {
    return Err("magnitude out of supported range: " + units.to_string())
  }
  let one = BigInt::from_int(1)
  let unit = if units == one { unit_one } else { unit_many }
  let cent = if cents == one { cent_one } else { cent_many }
  let body = l.cardinal_fi(units) +
    " " +
    unit +
    " ja " +
    l.cardinal_fi(cents) +
    " " +
    cent
  if neg {
    Ok("miinus " + body)
  } else {
    Ok(body)
  }
}
