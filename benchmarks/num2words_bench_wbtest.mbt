// benchmarks/num2words_bench_wbtest.mbt — microbenchmarks for representative
// conversions. Run with:
//
//   moon bench --release benchmarks
//
// The numbers are indicative only; see README "Performance" for the machine
// used when the figures there were recorded.

///|
test "bench cardinal en 1234" (it : @bench.T) {
  it.bench(fn() { it.keep(@lib.num2words_int(1234, "en", "cardinal")) })
}

///|
test "bench cardinal en 15 digits" (it : @bench.T) {
  it.bench(fn() {
    it.keep(@lib.num2words_str("123456789012345", "en", "cardinal"))
  })
}

///|
test "bench cardinal fr 1234" (it : @bench.T) {
  it.bench(fn() { it.keep(@lib.num2words_int(1234, "fr", "cardinal")) })
}

///|
test "bench cardinal ru 1234" (it : @bench.T) {
  it.bench(fn() { it.keep(@lib.num2words_int(1234, "ru", "cardinal")) })
}

///|
test "bench ordinal es 2024" (it : @bench.T) {
  it.bench(fn() { it.keep(@lib.num2words_int(2024, "es", "ordinal")) })
}

///|
test "bench currency en USD 1234.56" (it : @bench.T) {
  it.bench(fn() {
    match @lib.num2words_currency("1234.56", "en", "USD") {
      Ok(words) => it.keep(words)
      Err(_) => ()
    }
  })
}
