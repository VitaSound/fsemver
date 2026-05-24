\ fsemver.4th — Semver requirement parser & matcher (Hex/Elixir-style).
\
\ This is the canonical implementation used by fmix, flint, fcov and
\ any user project that needs to express / check version requirements
\ in the same vocabulary.
\
\ Grammar:
\
\   ~> X.Y          \ MAJOR pinned:        >= X.Y.0  and  < (X+1).0.0
\   ~> X.Y.Z        \ MAJOR+MINOR pinned:  >= X.Y.Z  and  <  X.(Y+1).0
\   >= X.Y.Z        \ minimum, no upper bound
\   == X.Y.Z        \ exact match
\   >  X.Y.Z        \ strictly greater
\   <  X.Y.Z        \ strictly less
\   <= X.Y.Z        \ less-or-equal
\   X.Y.Z           \ bare = synonym for `>= X.Y.Z`
\
\ Operators are matched longest-first (`~>`, `>=`, `<=`, `==` before
\ single-char `>` / `<`). Surrounding whitespace is tolerated.
\
\ Public API:
\
\   fsemver.parse-version-parts ( a u -- ma mi pa n-parts )
\                       Parse "X[.Y[.Z]]". Missing parts default to 0.
\                       n-parts ∈ {0,1,2,3} — 0 means nothing parseable
\                       at all (caller should treat as invalid).
\
\   fsemver.parse-req ( a u -- op ma mi pa valid? )
\                       Parse a requirement string. `op` is one of the
\                       fsemver.op-* constants below. valid? = false on
\                       any parse error (and the version triple is 0/0/0).
\
\   fsemver.semver-cmp ( a-ma a-mi a-pa  b-ma b-mi b-pa -- {-1|0|1} )
\                       Compare two semver triples. -1: a<b, 0: a==b, 1: a>b.
\
\   fsemver.req-matches? ( rma rmi rpa rop  sma smi spa -- f )
\                       True iff installed semver `self (s*)` satisfies
\                       the requirement `req (r*) + op`.
\
\ All requirement parsing is tolerant: garbage in => `valid? = false`,
\ never an exception. Callers (fmix's assert-min-version, flint's
\ check-required-version, ...) decide whether that's WARN or ERROR.

\ --- Operator constants -------------------------------------------------

0 constant fsemver.op-tilde-2     \ ~> X.Y
1 constant fsemver.op-tilde-3     \ ~> X.Y.Z
2 constant fsemver.op-gte         \ >= X.Y.Z  (also: bare X.Y.Z)
3 constant fsemver.op-eq          \ == X.Y.Z
4 constant fsemver.op-gt          \ >  X.Y.Z
5 constant fsemver.op-lt          \ <  X.Y.Z
6 constant fsemver.op-lte         \ <= X.Y.Z

\ --- Low-level helpers --------------------------------------------------

\ ( a u -- a' u' n parsed? )
\ Parse a leading non-negative integer. parsed? is false if the prefix
\ isn't a digit (in which case the original a u is preserved on stack).
: fsemver.parse-uint-strict ( a u -- a' u' n parsed? )
    dup 0= IF 0 false EXIT THEN
    over c@ [char] 0 [char] 9 1+ within 0= IF 0 false EXIT THEN
    0 0 2swap >number 2swap d>s true ;

: fsemver.skip-dot ( a u -- a' u' )
    dup 0= IF EXIT THEN
    over c@ [char] . = IF 1 /string THEN ;

: fsemver.strip-ws { a u -- a' u' }
    begin u 0> IF a c@ bl <= ELSE false THEN
    while a 1+ to a u 1- to u repeat
    begin u 0> IF a u + 1- c@ bl <= ELSE false THEN
    while u 1- to u repeat
    a u ;

: fsemver.startswith? { a u pa pu -- f }
    u pu < IF false EXIT THEN
    a pu pa pu compare 0= ;

\ --- Version parsing ----------------------------------------------------

: fsemver.parse-version-parts ( a u -- ma mi pa n-parts )
    fsemver.parse-uint-strict { ma got1 }
    got1 0= IF 2drop 0 0 0 0 EXIT THEN
    fsemver.skip-dot fsemver.parse-uint-strict { mi got2 }
    got2 0= IF 2drop ma 0 0 1 EXIT THEN
    fsemver.skip-dot fsemver.parse-uint-strict { pa got3 }
    got3 0= IF 2drop ma mi 0 2 EXIT THEN
    2drop ma mi pa 3 ;

\ --- semver-cmp ---------------------------------------------------------

: fsemver.semver-cmp { am ami apa bm bmi bpa -- n }
    am bm <  IF -1 EXIT THEN
    am bm >  IF  1 EXIT THEN
    ami bmi < IF -1 EXIT THEN
    ami bmi > IF  1 EXIT THEN
    apa bpa < IF -1 EXIT THEN
    apa bpa > IF  1 EXIT THEN
    0 ;

\ --- Requirement parsing ------------------------------------------------
\
\ Helper: parse the 3-part-or-2-part version after we've already consumed
\ an operator prefix. Returns the same shape as parse-req. The `expect3?`
\ flag tells us whether the caller demands all 3 components (>= == > < <=)
\ or accepts 2 as well (~>).

: fsemver.parse-req-tilde ( a u -- op ma mi pa valid? )
    fsemver.parse-version-parts { ma mi pa np }
    np 2 = IF fsemver.op-tilde-2 ma mi pa true EXIT THEN
    np 3 = IF fsemver.op-tilde-3 ma mi pa true EXIT THEN
    0 0 0 0 false ;

\ For >= == > < <= we require an X.Y.Z triple (missing parts → 0 is OK,
\ but at least 1 component must be present).
: fsemver.parse-req-rel { a u op -- op-out ma mi pa valid? }
    a u fsemver.parse-version-parts { ma mi pa np }
    np 0= IF 0 0 0 0 false EXIT THEN
    op ma mi pa true ;

: fsemver.parse-req-bare ( a u -- op ma mi pa valid? )
    fsemver.parse-version-parts { ma mi pa np }
    np 0= IF 0 0 0 0 false EXIT THEN
    fsemver.op-gte ma mi pa true ;

\ Try each operator prefix in longest-first order; on a match, recurse
\ into the appropriate sub-parser.
: fsemver.parse-req { a u -- op ma mi pa valid? }
    a u fsemver.strip-ws to u to a
    u 0= IF 0 0 0 0 false EXIT THEN

    a u s" ~>" fsemver.startswith? IF
        a 2 + u 2 - fsemver.strip-ws fsemver.parse-req-tilde EXIT
    THEN
    a u s" >=" fsemver.startswith? IF
        a 2 + u 2 - fsemver.strip-ws fsemver.op-gte fsemver.parse-req-rel EXIT
    THEN
    a u s" <=" fsemver.startswith? IF
        a 2 + u 2 - fsemver.strip-ws fsemver.op-lte fsemver.parse-req-rel EXIT
    THEN
    a u s" ==" fsemver.startswith? IF
        a 2 + u 2 - fsemver.strip-ws fsemver.op-eq fsemver.parse-req-rel EXIT
    THEN
    a u s" >" fsemver.startswith? IF
        a 1+ u 1- fsemver.strip-ws fsemver.op-gt fsemver.parse-req-rel EXIT
    THEN
    a u s" <" fsemver.startswith? IF
        a 1+ u 1- fsemver.strip-ws fsemver.op-lt fsemver.parse-req-rel EXIT
    THEN

    \ Fallthrough: bare X.Y.Z (= >= X.Y.Z).
    a u fsemver.parse-req-bare ;

\ --- Matcher ------------------------------------------------------------

: fsemver.req-matches? { rma rmi rpa rop sma smi spa -- f }
    rop fsemver.op-tilde-2 = IF
        sma rma <> IF false EXIT THEN
        smi rmi <  IF false EXIT THEN
        smi rmi >  IF true  EXIT THEN
        spa rpa <  IF false EXIT THEN
        true EXIT
    THEN
    rop fsemver.op-tilde-3 = IF
        sma rma <> IF false EXIT THEN
        smi rmi <> IF false EXIT THEN
        spa rpa <  IF false EXIT THEN
        true EXIT
    THEN

    \ Remaining ops reduce to a single cmp result.
    sma smi spa rma rmi rpa fsemver.semver-cmp { cmp }
    rop fsemver.op-gte = IF cmp -1 <> EXIT THEN
    rop fsemver.op-eq  = IF cmp  0 = EXIT THEN
    rop fsemver.op-gt  = IF cmp  1 = EXIT THEN
    rop fsemver.op-lt  = IF cmp -1 = EXIT THEN
    rop fsemver.op-lte = IF cmp  1 <> EXIT THEN
    \ Unknown op → fail closed.
    false ;
