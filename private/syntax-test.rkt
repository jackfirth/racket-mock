#lang sweet-exp racket/base

require racket/function
        rackunit
        "base.rkt"
        "check.rkt"
        "syntax.rkt"

(define (not-mock? v) (not (mock? v)))

(define/mock (bar)
  #:mock foo #:with-behavior (const "fake")
  (foo))

(define (foo) "real")

(test-equal? "Should use real implementation when called normally"
             (bar) "real")
(test-pred "Should not bind mocks outside with-mocks"
           not-mock? foo)

(test-case "Should reset mocks after with-mocks scope"
  (with-mocks bar
    (check-mock-num-calls 0 foo)
    (bar)
    (check-mock-num-calls 1 foo))
  (with-mocks bar
    (check-mock-num-calls 0 foo)))

(with-mocks bar
  (test-equal? "Should use mock implementation in with-mocks"
               (bar) "fake")
  (test-pred "Should bind mocks inside with-mocks"
             mock? foo))

(module+ test
  (test-case "Should behave identically in submod when called normally"
    (check-equal? (bar) "real")
    (check-pred not-mock? foo))
  (test-case "Should behave identically in submod when called in with-mocks"
    (with-mocks bar
      (check-equal? (bar) "fake")
      (check-pred mock? foo))))

(let ()
  (define/mock (bar-local)
    #:mock foo #:with-behavior (const "fake")
    (foo))

  (test-case "Should behave identically in local definition context when called normally"
    (check-equal? (bar-local) "real")
    (check-pred not-mock? foo))
  (test-case "Should behave identically in local definition context when called in with-mocks"
    (with-mocks bar-local
      (check-equal? (bar-local) "fake")
      (check-pred mock? foo))))

(define/mock (bar-explicit)
  #:mock foo #:as foo-mock #:with-behavior (const "fake")
  (foo))

(test-case "Should use given binding instead of mocked procedure id"
  (with-mocks bar-explicit
    (check-pred not-mock? foo)
    (check-pred mock? foo-mock)))
