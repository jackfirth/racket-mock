#lang racket/base

(require racket/bool
         racket/contract
         racket/splicing
         rackunit
         unstable/sequence)

(provide
 (contract-out
  [mock? predicate/c]
  [make-mock (-> procedure? mock?)]
  [mock-calls (-> mock? (listof mock-call?))]
  [struct mock-call ([args list?] [results list?])]
  [mock-called-with? (-> list? mock? boolean?)]
  [mock-num-calls (-> mock? exact-nonnegative-integer?)]))


(struct mock (proc calls-box)
  #:property prop:procedure (struct-field-index proc))

(struct mock-call (args results) #:prefab)

(define (make-mock proc)
  (define calls (box '()))
  (define (add-call! call)
    (set-box! calls (cons call (unbox calls))))
  (define (wrapper . vs)
    (define results (call-with-values (λ _ (apply proc vs))
                                      list))
    (add-call! (mock-call vs results))
    (apply values results))
  (mock wrapper calls))

(define (mock-calls mock)
  (unbox (mock-calls-box mock)))

(define (mock-called-with? args mock)
  (not (false? (member args (map mock-call-args (mock-calls mock))))))

(define (mock-num-calls mock)
  (length (mock-calls mock)))
