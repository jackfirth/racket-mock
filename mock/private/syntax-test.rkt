#lang sweet-exp racket/base

require racket/function
        rackunit
        syntax/macro-testing
        arguments
        "base.rkt"
        "history.rkt"
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
    (check-equal? (mock-num-calls foo) 0)
    (bar)
    (check-equal? (mock-num-calls foo) 1))
  (with-mocks bar
    (check-equal? (mock-num-calls foo) 0)))

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

(test-case "Should use given binding instead of mocked procedure id"
  (define/mock (bar-explicit)
    #:mock foo #:as foo-mock #:with-behavior (const "fake")
    (foo))
  (with-mocks bar-explicit
    (check-not-exn bar-explicit)
    (check-pred not-mock? foo)
    (check-pred mock? foo-mock)))

(test-case "Should use default mock behavior (throwing) when behavior unspecified"
  (define/mock (bar-default-behavior)
    #:mock foo
    (foo))
  (with-mocks bar-default-behavior
    (check-exn exn:fail:unexpected-arguments? bar-default-behavior)))

(test-case "Should allow positional, keyword, and rest arguments"
  (define/mock (bar-args arg #:keyword kwarg . rest)
    #:mock foo #:with-behavior (const "fake")
    (foo))
  (check-equal? (bar-args #f #:keyword 'foo 1 2 3) "real")
  (with-mocks bar-args
    (check-equal? (bar-args #f #:keyword 'foo 1 2 3) "fake")))

(test-case "Should define opaque value and make it available in mock behaviors"
  (define/mock (bar-opaque)
    #:opaque foo-result
    #:mock foo #:with-behavior (const foo-result)
    (foo))
  (check-equal? (bar-opaque) "real")
  (with-mocks bar-opaque
    (check-pred foo-result? foo-result)
    (check-equal? (bar-opaque) foo-result)))

(test-case "Should work with multiple opaque values"
  (define/mock (bar-opaque-multi)
    #:opaque (left right)
    #:mock foo #:with-behavior (const (cons left right))
    (foo))
  (check-equal? (bar-opaque-multi) "real")
  (with-mocks bar-opaque-multi
    (check-pred left? left)
    (check-pred right? right)
    (check-equal? (bar-opaque-multi) (cons left right))))

(test-case "Should raise a syntax error when used with a normal procedure"
  (define (bar-normal)
    (foo))
  (check-equal? (bar-normal) "real")
  (check-exn #rx"bar-normal not bound with define/mock"
             (thunk
              (convert-compile-time-error (with-mocks bar-normal (void))))))

(test-case "Should raise a syntax error when with-mocks is nested"
  (define/mock (bar1) #:mock foo (foo))
  (define/mock (bar2) #:mock foo (foo))
  (check-equal? (bar1) "real")
  (check-equal? (bar2) "real")
  (check-exn #rx"nested use of with-mocks not allowed"
             (thunk
              (convert-compile-time-error
               (with-mocks bar1 (with-mocks bar2 (void)))))))

(test-case "Should add an external history to all mocks when defined"
  (define/mock (bar/history)
    #:history bar-history
    #:mock foo #:with-behavior void
    (foo))
  (with-mocks bar/history
    (bar/history)
    (check-equal? (call-history-count bar-history) 1)))

(test-case "Should allow mocking of procedure-containing parameters"
  (define current-foo (make-parameter foo))
  (define (foo/param) ((current-foo)))
  (test-case "Should provide mock in param by default"
    (define/mock (bar/param)
      #:mock-param current-foo #:with-behavior (const "foo-param")
      (foo/param))
    (with-mocks bar/param
      (check-equal? (bar/param) "foo-param")
      (check-equal? (mock-num-calls (current-foo)) 1)))
  (test-case "Should provide mock directly when given binding"
    (define/mock (bar/param/name)
      #:mock-param current-foo #:as foo-mock #:with-behavior (const "foo-param")
      (foo/param))
    (with-mocks bar/param/name
      (check-equal? (bar/param/name) "foo-param")
      (check-equal? (mock-num-calls foo-mock) 1))))
