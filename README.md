# fsemver

**Semver requirement parser + matcher for Forth.** Hex/Elixir-style
operators: `~>`, `>=`, `==`, `>`, `<`, `<=`, and bare `X.Y.Z`. One file,
one dependency for tests (ttester), zero runtime dependencies.

Part of the **VitaSound Forth tooling family** —
[fmix](https://github.com/VitaSound/fmix),
[flint](https://github.com/VitaSound/flint),
[ttester](https://github.com/VitaSound/ttester),
[fenum](https://github.com/VitaSound/fenum).

## Why a separate library

Both fmix (`fmix_version_check.4th`) and flint (`flint/version-check.4th`)
need to read a version-requirement string from the project's
`package.4th`, parse it, and check whether the installed tool
satisfies it. The algorithm is small (~100 lines), but copying it
into a third tool (fcov, …) is the path to drift. fsemver is the
single source of truth.

## Install

```bash
cd ~ && git clone git@github.com:VitaSound/fsemver.git
cd fsemver && fmix packages.get
```

fsemver is a library — no `bin/` launcher, no `~/.bashrc` change.

For your own project, add to `package.4th`:

```forth
key-list dependencies fsemver git https://github.com/VitaSound/fsemver tag 0.1.0
```

then `fmix packages.get` pulls it into `forth-packages/fsemver/0.1.0/`.
In your Forth code:

```forth
require forth-packages/fsemver/0.1.0/fsemver.4th
```

## Operators

| Form        | Means                                              |
|-------------|----------------------------------------------------|
| `~> X.Y`    | `>= X.Y.0`   and   `< (X+1).0.0`                   |
| `~> X.Y.Z`  | `>= X.Y.Z`   and   `<  X.(Y+1).0`                  |
| `>= X.Y.Z`  | minimum, no upper bound                            |
| `==  X.Y.Z` | exact match                                        |
| `>  X.Y.Z`  | strictly greater                                   |
| `<  X.Y.Z`  | strictly less                                      |
| `<= X.Y.Z`  | less-or-equal                                      |
| `X.Y.Z`     | bare = synonym for `>= X.Y.Z`                      |

Operators are matched **longest-first** (`~>`, `>=`, `<=`, `==` before
single-char `>` / `<`). Whitespace around the operator is tolerated.

## API

```forth
fsemver.parse-version-parts ( a u -- ma mi pa n-parts )
    \ Parse "X[.Y[.Z]]". Missing components default to 0.
    \ n-parts ∈ {0,1,2,3} — 0 means nothing parseable (invalid).

fsemver.semver-cmp ( a-ma a-mi a-pa  b-ma b-mi b-pa -- {-1|0|1} )
    \ Numeric compare two semver triples. -1: a<b, 0: a==b, 1: a>b.
    \ (Note: 10 > 9, NOT 10 < 9 — this is not a lexicographic compare.)

fsemver.parse-req ( a u -- op ma mi pa valid? )
    \ Parse a requirement string. `op` is one of the fsemver.op-*
    \ constants. valid? = false on parse error (and ma/mi/pa = 0).

fsemver.req-matches? ( rma rmi rpa rop  sma smi spa -- f )
    \ True iff installed semver `s*` satisfies the requirement `r* op`.
```

Operator constants (returned by `parse-req`, consumed by `req-matches?`):

```forth
fsemver.op-tilde-2     \  ~> X.Y
fsemver.op-tilde-3     \  ~> X.Y.Z
fsemver.op-gte         \  >= X.Y.Z  (also: bare X.Y.Z)
fsemver.op-eq          \  == X.Y.Z
fsemver.op-gt          \  >  X.Y.Z
fsemver.op-lt          \  <  X.Y.Z
fsemver.op-lte         \  <= X.Y.Z
```

## Example

```forth
require fsemver.4th

\ A project pins itself to `~> 0.7`, we have 0.7.4 installed:
s" ~> 0.7" fsemver.parse-req      \ ( 0 0 7 0 true )
s" 0.7.4"  fsemver.parse-version-parts drop  \ ( 0 7 4 )
\ Stack now: rma rmi rpa rop sma smi spa
fsemver.req-matches? .            \ -1  (true: 0.7.4 satisfies ~> 0.7)
```

Real-world wiring (lifted from fmix 0.7.1 / flint 0.2.1):

```forth
\ Project told us `key-value fmix ~> 0.7`. Installed is fmix 0.6.5:
s" ~> 0.7" fsemver.parse-req { rop rma rmi rpa rok }
rok 0= IF ." invalid requirement" cr EXIT THEN

s" 0.6.5" fsemver.parse-version-parts drop { sma smi spa }

rma rmi rpa rop sma smi spa fsemver.req-matches? 0= IF
    ." installed fmix doesn't satisfy ~> 0.7" cr
THEN
```

## Tests

```bash
fmix test
```

71 unit assertions: parse-version-parts, semver-cmp, parse-req for
every operator, req-matches? truth-table for every operator.

## Design notes

- **One flat file** (~210 lines). Splitting into `parse.4th` /
  `req.4th` / `cmp.4th` was considered and rejected — the whole file
  is shorter than the readme.
- **Tolerant parser.** Garbage in => `valid? = false`, never `throw`s
  or `bye`s. Calling tools decide whether that's a WARN (flint, soft
  check) or a hard ERROR (fmix, build gate).
- **No external deps at runtime.** Only ttester for the test suite.
- **Pure ANS Forth** wherever possible; the one Gforth-ism is the
  locals syntax (`{ a b c -- }`) used pervasively.

## Russian docs

See [README.ru.md](README.ru.md).

## License

[COPL](LICENSE) — Communist Public License. Use freely, share with
others.
