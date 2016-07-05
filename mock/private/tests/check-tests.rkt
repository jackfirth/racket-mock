#lang sweet-exp racket

require rackunit
        mock

(define (has-info? check-failure info-name)
  (member info-name (map check-info-name (exn:test:check-stack check-failure))))

(module+ test
  (test-case
    "check-mock-num-calls does not fail when amount of calls is equal"
    (check-mock-num-calls 0 (void-mock)))

  (test-case
    "check-info is added by check-mock-num-calls? on failure"
    (check-exn
      (λ (e) (and (has-info? e 'expected) (has-info? e 'actual)))
      (thunk
        (parameterize ([current-check-handler raise])
          (check-mock-num-calls 1 (void-mock))))))

  (test-case
    "check-info is added by check-mock-called-with? on failure"
    (check-exn
      (λ (e) (and (has-info? e 'expected) (has-info? e 'actual)))
      (thunk
        (parameterize ([current-check-handler raise])
          (check-mock-called-with? '(1) (void-mock)))))))
