\ tests/fsemver_test.4th — unit tests for fsemver.
\
\ Covers:
\   - parse-version-parts (incl. partials, garbage)
\   - semver-cmp (full transitivity & ordering)
\   - parse-req for every operator: ~> (X.Y and X.Y.Z), >=, ==, >, <, <=, bare
\   - req-matches? truth-table for every operator
\
\ Run via:
\   fmix test
\ or directly:
\   gforth tests/fsemver_test.4th

require ../forth-packages/ttester/1.2.0/ttester.4th
require ../fsemver.4th

0 #ERRORS !

\ --- parse-version-parts -------------------------------------------------

T{ s" 0.0.0"  fsemver.parse-version-parts -> 0 0 0 3 }T
T{ s" 1.2.3"  fsemver.parse-version-parts -> 1 2 3 3 }T
T{ s" 0.7"    fsemver.parse-version-parts -> 0 7 0 2 }T
T{ s" 5"      fsemver.parse-version-parts -> 5 0 0 1 }T
T{ s" 10.0.0" fsemver.parse-version-parts -> 10 0 0 3 }T
T{ s" 0.20.7" fsemver.parse-version-parts -> 0 20 7 3 }T

T{ s" "       fsemver.parse-version-parts -> 0 0 0 0 }T
T{ s" abc"    fsemver.parse-version-parts -> 0 0 0 0 }T

\ --- semver-cmp ----------------------------------------------------------
\ Stack: a-ma a-mi a-pa  b-ma b-mi b-pa -- {-1|0|1}

T{ 0 0 0    0 0 0  fsemver.semver-cmp ->  0 }T
T{ 1 2 3    1 2 3  fsemver.semver-cmp ->  0 }T

T{ 1 0 0    1 0 1  fsemver.semver-cmp -> -1 }T
T{ 1 0 1    1 0 0  fsemver.semver-cmp ->  1 }T

T{ 0 5 0    0 5 1  fsemver.semver-cmp -> -1 }T
T{ 0 5 1    0 5 0  fsemver.semver-cmp ->  1 }T

T{ 0 9 9    1 0 0  fsemver.semver-cmp -> -1 }T
T{ 1 0 0    0 9 9  fsemver.semver-cmp ->  1 }T

\ Non-lexicographic numeric compare (10 > 9, not 10 < 9).
T{ 0 4 0    0 10 0  fsemver.semver-cmp -> -1 }T
T{ 0 10 0   0  4 0  fsemver.semver-cmp ->  1 }T

\ --- parse-req: ~> X.Y ---------------------------------------------------

T{ s" ~> 0.6"     fsemver.parse-req -> 0 0 6 0 true }T
T{ s" ~> 1.0"     fsemver.parse-req -> 0 1 0 0 true }T
T{ s" ~> 10.2"    fsemver.parse-req -> 0 10 2 0 true }T
T{ s"   ~> 0.6  " fsemver.parse-req -> 0 0 6 0 true }T
T{ s" ~>0.6"      fsemver.parse-req -> 0 0 6 0 true }T

\ --- parse-req: ~> X.Y.Z -------------------------------------------------

T{ s" ~> 0.6.2"   fsemver.parse-req -> 1 0 6 2 true }T
T{ s" ~> 1.2.3"   fsemver.parse-req -> 1 1 2 3 true }T

\ --- parse-req: >= -------------------------------------------------------

T{ s" >= 0.6.0"   fsemver.parse-req -> 2 0 6 0 true }T
T{ s" >= 1.0.0"   fsemver.parse-req -> 2 1 0 0 true }T
T{ s" >=0.6.0"    fsemver.parse-req -> 2 0 6 0 true }T

\ --- parse-req: == -------------------------------------------------------

T{ s" == 1.2.3"   fsemver.parse-req -> 3 1 2 3 true }T
T{ s" ==0.0.1"    fsemver.parse-req -> 3 0 0 1 true }T

\ --- parse-req: > / < / <= -----------------------------------------------

T{ s" > 0.5.0"    fsemver.parse-req -> 4 0 5 0 true }T
T{ s" < 2.0.0"    fsemver.parse-req -> 5 2 0 0 true }T
T{ s" <= 1.0.0"   fsemver.parse-req -> 6 1 0 0 true }T

\ Single-char ops without spaces.
T{ s" >0.5.0"     fsemver.parse-req -> 4 0 5 0 true }T
T{ s" <2.0.0"     fsemver.parse-req -> 5 2 0 0 true }T

\ --- parse-req: bare X.Y.Z (= >=) ----------------------------------------

T{ s" 0.6.0"      fsemver.parse-req -> 2 0 6 0 true }T
T{ s" 1.2.3"      fsemver.parse-req -> 2 1 2 3 true }T
T{ s" 0.7"        fsemver.parse-req -> 2 0 7 0 true }T   \ partial still gte

\ --- parse-req: invalid --------------------------------------------------

T{ s" "           fsemver.parse-req -> 0 0 0 0 false }T
T{ s" ~>"         fsemver.parse-req -> 0 0 0 0 false }T
T{ s" ~> "        fsemver.parse-req -> 0 0 0 0 false }T
T{ s" ~> 1"       fsemver.parse-req -> 0 0 0 0 false }T  \ ~> demands 2+ parts
T{ s" >="         fsemver.parse-req -> 0 0 0 0 false }T
T{ s" =="         fsemver.parse-req -> 0 0 0 0 false }T
T{ s" >"          fsemver.parse-req -> 0 0 0 0 false }T
T{ s" garbage"    fsemver.parse-req -> 0 0 0 0 false }T
T{ s" ~> abc"     fsemver.parse-req -> 0 0 0 0 false }T

\ --- req-matches?: ~> 0.6 (rop=0, r=0/6/0) -------------------------------
\ Stack: rma rmi rpa rop  sma smi spa -- f

T{ 0 6 0 0   0 6 0    fsemver.req-matches? -> true  }T
T{ 0 6 0 0   0 6 5    fsemver.req-matches? -> true  }T
T{ 0 6 0 0   0 7 0    fsemver.req-matches? -> true  }T
T{ 0 6 0 0   0 99 99  fsemver.req-matches? -> true  }T
T{ 0 6 0 0   0 5 9    fsemver.req-matches? -> false }T
T{ 0 6 0 0   1 0 0    fsemver.req-matches? -> false }T

\ --- req-matches?: ~> 0.6.2 (rop=1) --------------------------------------

T{ 0 6 2 1   0 6 2    fsemver.req-matches? -> true  }T
T{ 0 6 2 1   0 6 9    fsemver.req-matches? -> true  }T
T{ 0 6 2 1   0 6 1    fsemver.req-matches? -> false }T
T{ 0 6 2 1   0 7 0    fsemver.req-matches? -> false }T
T{ 0 6 2 1   1 0 0    fsemver.req-matches? -> false }T

\ --- req-matches?: >= 0.6.0 (rop=2 = gte) --------------------------------

T{ 0 6 0 2   0 6 0    fsemver.req-matches? -> true  }T
T{ 0 6 0 2   0 7 0    fsemver.req-matches? -> true  }T
T{ 0 6 0 2   1 0 0    fsemver.req-matches? -> true  }T
T{ 0 6 0 2   0 5 9    fsemver.req-matches? -> false }T

\ --- req-matches?: == 0.6.0 (rop=3 = eq) ---------------------------------

T{ 0 6 0 3   0 6 0    fsemver.req-matches? -> true  }T
T{ 0 6 0 3   0 6 1    fsemver.req-matches? -> false }T
T{ 0 6 0 3   1 0 0    fsemver.req-matches? -> false }T
T{ 0 6 0 3   0 5 9    fsemver.req-matches? -> false }T

\ --- req-matches?: > 0.6.0 (rop=4 = gt) ----------------------------------

T{ 0 6 0 4   0 6 0    fsemver.req-matches? -> false }T  \ equal NOT enough
T{ 0 6 0 4   0 6 1    fsemver.req-matches? -> true  }T
T{ 0 6 0 4   1 0 0    fsemver.req-matches? -> true  }T
T{ 0 6 0 4   0 5 9    fsemver.req-matches? -> false }T

\ --- req-matches?: < 1.0.0 (rop=5 = lt) ----------------------------------

T{ 1 0 0 5   1 0 0    fsemver.req-matches? -> false }T  \ equal NOT enough
T{ 1 0 0 5   0 9 9    fsemver.req-matches? -> true  }T
T{ 1 0 0 5   0 0 1    fsemver.req-matches? -> true  }T
T{ 1 0 0 5   1 0 1    fsemver.req-matches? -> false }T

\ --- req-matches?: <= 1.0.0 (rop=6 = lte) --------------------------------

T{ 1 0 0 6   1 0 0    fsemver.req-matches? -> true  }T
T{ 1 0 0 6   0 9 9    fsemver.req-matches? -> true  }T
T{ 1 0 0 6   1 0 1    fsemver.req-matches? -> false }T

: report
    #ERRORS @ 0= IF
        cr ." fsemver_test ok" cr
    ELSE
        cr ." fsemver_test FAILED: " #ERRORS @ . ." errors" cr
        1 (bye)
    THEN ;
report
bye
