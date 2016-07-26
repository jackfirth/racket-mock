# racket-mock [![Build Status](https://travis-ci.org/jackfirth/racket-mock.svg)](https://travis-ci.org/jackfirth/racket-mock) [![Coverage Status](https://coveralls.io/repos/jackfirth/racket-mock/badge.svg?branch=master&service=github)](https://coveralls.io/github/jackfirth/racket-mock?branch=master) [![Stories in Ready](https://badge.waffle.io/jackfirth/racket-mock.png?label=ready&title=Ready)](https://waffle.io/jackfirth/racket-mock)
Mocking library for Racket RackUnit testing.

```
raco pkg install jack-mock
```

Documentation: [`mock`](http://pkg-build.racket-lang.org/doc/mock/index.html)

This library allows for easy construction of *mocks*, which are "fake" implementations of functions that record calls made to them for testing.

Currently unstable, API changes may occur.

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
