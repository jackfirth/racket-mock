# racket-mock [![Build Status](https://travis-ci.org/jackfirth/racket-mock.svg)](https://travis-ci.org/jackfirth/racket-mock) [![Coverage Status](https://coveralls.io/repos/jackfirth/racket-mock/badge.svg?branch=master&service=github)](https://coveralls.io/github/jackfirth/racket-mock?branch=master)
Mocking library for Racket RackUnit testing.

```
raco pkg install jack-mock
```

Documentation: [`mock`](http://pkg-build.racket-lang.org/doc/mock/index.html)

This library allows for easy construction of *mocks*, which are "fake" implementations of functions that record calls made to them for testing.

Currently unstable, API changes may occur.

Example:

```racket
(require mock)
(define/mock (displayln-twice v)
  ([displayln (void-mock)]) ; in the test submodule, calls a mock instead of displayln
  (displayln v)
  (displayln v))
(displayln-twice "sent to real displayln")
(mock? displayln) ; #f
(mock-num-calls displayln) ; error - displayln isn't a mock
(module+ test
  (displayln-twice "sent to mock displayln")
  (mock? displayln) ; #t
  (mock-num-calls displayln)) ; 2
```
