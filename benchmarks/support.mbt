// benchmarks/support.mbt — keeps the package imports used in non-test builds
// (the package itself only contains benchmarks) and exposes a tiny sanity
// helper for the benchmark harness.

///|
pub fn sample_cardinal() -> String {
  @lib.num2words_int(1234, "en", "cardinal")
}

///|
pub fn new_harness() -> @bench.Bench {
  @bench.Bench()
}
