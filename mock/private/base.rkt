#lang sweet-exp racket/base

require racket/bool
        racket/contract
        racket/splicing
        rackunit
        unstable/sequence

provide
  contract-out
    mock? predicate/c
    make-mock (-> procedure? mock?)
    mock-calls (-> mock? (listof mock-call?))
    struct mock-call ([args list?] [results list?])
    mock-called-with? (-> list? mock? boolean?)
    mock-num-calls (-> mock? exact-nonnegative-integer?)


(struct mock (proc calls-box)
  #:property prop:procedure (struct-field-index proc))

(struct mock-call (args results) #:prefab)

(define (ensure-same-keyword-arity proc-to-wrap wrapper-proc)
  (define arity (procedure-arity proc-to-wrap))
  (define-values (req-kws all-kws) (procedure-keywords proc-to-wrap))
  (procedure-reduce-keyword-arity wrapper-proc arity req-kws all-kws))

(define (make-mock proc)
  (define calls (box '()))
  (define (add-call! call)
    (set-box! calls (cons call (unbox calls))))
  (define wrapper
    (make-keyword-procedure
     (λ (kws kw-vs . vs)
       (define results
         (call-with-values (λ _ (keyword-apply proc kws kw-vs vs))
                           list))
       (define all-vs (append vs (map list kws kw-vs)))
       (add-call! (mock-call all-vs  results))
       (apply values results))))
  (define wrapper-with-proper-keyword-args
    (ensure-same-keyword-arity proc wrapper))
  (mock wrapper-with-proper-keyword-args calls))

(define (mock-calls mock)
  (unbox (mock-calls-box mock)))

(define (mock-called-with? args mock)
  ;; For user convenience, don't require the keywords to be sorted.
  (define member? (compose not not member))
  (for/or ([call (in-list (mock-calls mock))])
    (for/and ([arg (in-list args)])
      (member? arg (mock-call-args call)))))

(define (mock-num-calls mock)
  (length (mock-calls mock)))

(module* test racket/base
  (require rackunit
           racket/format
           (submod ".."))
  (define m (make-mock ~a))
  (check-equal? (call-with-values (λ _ (procedure-keywords ~a)) list)
                (call-with-values (λ _ (procedure-keywords m)) list))
  (check-equal? (m 0) "0")
  (check-equal? (m 0 #:width 3 #:align 'left) "0  ")
  (check-equal? (mock-calls m)
                '(#s(mock-call (0 [#:align left] [#:width 3]) ("0  "))
                  #s(mock-call (0) ("0"))))
  (check-equal? (mock-num-calls m) 2)
  (check-true (mock-called-with? '(0) m))
  (check-true (mock-called-with? '(0 [#:align left] [#:width 3]) m))
  (check-true (mock-called-with? '(0 [#:width 3] [#:align left]) m))
  (check-false (mock-called-with? '(42) m)))
