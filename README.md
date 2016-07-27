# racket-mock [![Build Status](https://travis-ci.org/jackfirth/racket-mock.svg)](https://travis-ci.org/jackfirth/racket-mock) [![Coverage Status](https://coveralls.io/repos/jackfirth/racket-mock/badge.svg?branch=master&service=github)](https://coveralls.io/github/jackfirth/racket-mock?branch=master) [![Stories in Ready](https://badge.waffle.io/jackfirth/racket-mock.png?label=ready&title=Ready)](https://waffle.io/jackfirth/racket-mock)
Mocks for Racket testing.

```bash
raco pkg install mock
raco pkg install mock-rackunit # RackUnit integration
```

Documentation: [`mock`](http://pkg-build.racket-lang.org/doc/mock/index.html)

This library defines *mocks*, which are "fake" implementations of functions that record calls made to them.
Two separate packages are provided, the main package `mock` and the RackUnit checks package `mock-rackunit`.
In standard uses, the `mock-rackunit` dependency is needed only for test code.

Example:

```racket
(require mock mock/rackunit)

(define/mock (foo)
  ; in test, don't call the real bar
  #:mock bar #:as bar-mock #:with-behavior (const "wow!")
  (bar))

(define (bar) "bam!")

(foo) ; "bam!"

(with-mocks foo
  (foo) ; "wow!"
  (check-mock-num-calls 1 bar-mock))
```
