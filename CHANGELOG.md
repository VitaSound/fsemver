# Change Log

All notable changes to fsemver are documented here.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and
this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.0] - 2026-05-24

Initial extraction. Previously the same algorithm lived inline inside
`fmix_version_check.4th` (fmix 0.7.0) and `flint/version-check.4th`
(flint 0.2.0). fsemver consolidates it into a standalone package so
future tools (fcov, etc.) can `require` it instead of copying.

### Added
- `fsemver.parse-version-parts ( a u -- ma mi pa n-parts )`
  Best-effort semver parser. Missing components default to 0;
  `n-parts ∈ {0,1,2,3}` tells the caller how many components were
  actually present (0 = unparseable).
- `fsemver.semver-cmp ( a-ma a-mi a-pa  b-ma b-mi b-pa -- {-1|0|1} )`
  Numeric (not lexicographic) compare for two 3-part semver triples.
- `fsemver.parse-req ( a u -- op ma mi pa valid? )`
  Parses every Hex/Elixir-style operator:
  - `~> X.Y`     — pessimistic, MAJOR locked
  - `~> X.Y.Z`   — pessimistic, MAJOR+MINOR locked
  - `>= X.Y.Z`   — greater-or-equal (also: bare `X.Y.Z`)
  - `== X.Y.Z`   — exact
  - `> X.Y.Z`    — strictly greater
  - `< X.Y.Z`    — strictly less
  - `<= X.Y.Z`   — less-or-equal

  Operator parsing is longest-match-first (`~>`, `>=`, `<=`, `==`
  before single-char `>` / `<`). Whitespace around the operator is
  tolerated. Invalid input gives `valid? = false`, never an exception.
- `fsemver.req-matches? ( rma rmi rpa rop  sma smi spa -- f )`
  True iff the installed semver triple satisfies the requirement.
- `tests/fsemver_test.4th` — 71 unit assertions covering parse,
  cmp and the full operator truth-table.

### Design notes
- One flat file (~210 lines). No sub-modules — premature splitting for
  a library this size.
- Pure ANS Forth wherever possible; the one Gforth-ism is the locals
  syntax (`{ a b c -- }`) used pervasively.
- Tolerant parser: garbage in => `valid? = false`. Callers decide
  whether that's a WARN (linter, soft check) or a hard ERROR (build
  gate). fsemver never `bye`s or `throw`s on user input.
