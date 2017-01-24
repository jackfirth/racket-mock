#lang sweet-exp racket/base

provide check-mock-calls
        check-mock-called-with?
        check-mock-num-calls
        check-call-history-names

require racket/list
        rackunit
        syntax/parse/define
        mock

(define-simple-macro (with-check-info/id (id:id ...) body ...+)
  (with-check-info (['id id] ...) body ...))

(define no-calls-made-message "No calls were made matching the expected arguments")

(define-check (check-mock-calls mock expected-call-args-list)
  (define actual-num-calls (mock-num-calls mock))
  (define expected-num-calls (length expected-call-args-list))
  (define actual-call-args-list (map mock-call-args (mock-calls mock)))
  (with-check-info/id (mock)
    (with-check-info/id (actual-num-calls expected-num-calls)
      (when (< actual-num-calls expected-num-calls)
        (define missing-calls (drop expected-call-args-list (length actual-call-args-list)))
        (with-check-info/id (missing-calls)
          (fail-check "Mock called less times than expected")))
      (when (> actual-num-calls expected-num-calls)
        (define extra-calls (drop actual-call-args-list (length expected-call-args-list)))
        (with-check-info/id (extra-calls)
          (fail-check "Mock called more times than expected"))))
    (for ([actual-call-args (in-list actual-call-args-list)]
          [expected-call-args (in-list expected-call-args-list)]
          [which-call (in-naturals)])
      (with-check-info/id (which-call actual-call-args expected-call-args)
        (unless (equal? actual-call-args expected-call-args)
          (fail-check "Mock called with unexpected arguments"))))))

(module+ test
  (test-case "Should check that a mocks calls exactly match a given list of arguments"
    (define void-mock (mock #:name 'void-mock #:behavior void))
    (check-mock-calls void-mock '())
    (void-mock 1 2 3)
    (check-mock-calls void-mock (list (arguments 1 2 3)))
    (void-mock 'foo)
    (void-mock 'bar)
    (check-mock-calls void-mock (list (arguments 1 2 3) (arguments 'foo) (arguments 'bar)))))

(define-check (check-mock-called-with? mock args)
  (with-check-info (['expected-args args]
                    ['actual-calls (mock-calls mock)])
    (unless (mock-called-with? mock args) (fail-check no-calls-made-message))))

(module+ test
  (test-case "Should check if a mock's been called with given arguments"
    (define m (mock #:behavior void))
    (m 1 2 3)
    (check-mock-called-with? m (arguments 1 2 3))))

(define-simple-check (check-mock-num-calls mock expected-num-calls)
  (equal? (mock-num-calls mock) expected-num-calls))

(module+ test
  (test-case "Should check if a mock's been called a certain number of times"
    (define m (mock #:behavior void))
    (check-mock-num-calls m 0)
    (m 1 2 3)
    (check-mock-num-calls m 1)
    (m 'foo)
    (m 'bar)
    (check-mock-num-calls m 3)))

(define-simple-check (check-call-history-names history expected-call-names)
  (define actual-num-calls (call-history-count history))
  (define expected-num-calls (length expected-call-names))
  (define actual-call-names (map mock-call-name (call-history-calls history)))
  (with-check-info/id (history)
    (with-check-info/id (actual-num-calls expected-num-calls)
      (when (< actual-num-calls expected-num-calls)
        (define missing-call-names
          (drop expected-call-names (length actual-call-names)))
        (with-check-info/id (missing-call-names)
          (fail-check "Mock call history contained fewer calls than expected")))
      (when (> actual-num-calls expected-num-calls)
        (define extra-call-names
          (drop actual-call-names (length expected-call-names)))
        (with-check-info/id (extra-call-names)
          (fail-check "Mock call history contained more calls than expected"))))
    (for ([actual-call-name (in-list actual-call-names)]
          [expected-call-name (in-list expected-call-names)]
          [which-call (in-naturals)])
      (with-check-info/id (which-call actual-call-name expected-call-name)
        (unless (equal? actual-call-name expected-call-name)
          (fail-check "Unexpected mock called"))))))

(module+ test
  (test-case "Should check if mocks have been called in proper order"
    (define h (call-history))
    (define m1 (mock #:name 'm1 #:behavior void #:external-histories (list h)))
    (define m2 (mock #:name 'm2 #:behavior void #:external-histories (list h)))
    (m1 'foo)
    (m2 'bar)
    (m1 'baz)
    (check-call-history-names h (list 'm1 'm2 'm1))))
