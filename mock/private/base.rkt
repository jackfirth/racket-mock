#lang sweet-exp racket/base

require fancy-app
        racket/bool
        racket/contract
        racket/function
        racket/splicing
        rackunit
        unstable/sequence

provide
  contract-out
    mock? predicate/c
    make-mock (-> procedure? mock?)
    mock-calls (-> mock? (listof mock-call?))
    struct mock-call ([args list?] [kwargs (hash/c keyword? any/c)] [results list?])
    mock-called-with? (-> mock? list? (hash/c keyword? any/c) boolean?)
    mock-num-calls (-> mock? exact-nonnegative-integer?)

module+ test
  require rackunit
          racket/format


(struct mock (proc calls-box)
  #:property prop:procedure (struct-field-index proc))

(struct mock-call (args kwargs results) #:transparent)

(define (ensure-same-keyword-arity proc-to-wrap wrapper-proc)
  (define arity (procedure-arity proc-to-wrap))
  (define-values (req-kws all-kws) (procedure-keywords proc-to-wrap))
  (procedure-reduce-keyword-arity wrapper-proc arity req-kws all-kws))

(define (box-transform! a-box f)
  (set-box! a-box (f (unbox a-box))))

(define (make-mock proc)
  (define calls (box '()))
  (define (add-call! call) (box-transform! calls (append _ (list call))))
  (define wrapper
    (make-keyword-procedure
     (λ (kws kw-vs . vs)
       (define results
         (call-with-values (thunk (keyword-apply proc kws kw-vs vs))
                           list))
       (define kwargs (make-immutable-hash (map cons kws kw-vs)))
       (add-call! (mock-call vs kwargs results))
       (apply values results))))
  (mock (ensure-same-keyword-arity proc wrapper) calls))

(define mock-calls (compose unbox mock-calls-box))

(define (mock-called-with? mock args kwargs)
  (for/or ([call (in-list (mock-calls mock))])
    (and (equal? args (mock-call-args call))
         (equal? kwargs (mock-call-kwargs call)))))

(define mock-num-calls (compose length mock-calls))

(module+ test
  (define m (make-mock ~a))
  (check-equal? (call-with-values (λ _ (procedure-keywords ~a)) list)
                (call-with-values (λ _ (procedure-keywords m)) list))
  (check-equal? (m 0) "0")
  (check-equal? (m 0 #:width 3 #:align 'left) "0  ")
  
  (check-equal? (mock-calls m)
                (list (mock-call '(0) (hash) '("0"))
                      (mock-call '(0) (hash '#:width 3 '#:align 'left) '("0  "))))
  (check-equal? (mock-num-calls m) 2)
  (check-true (mock-called-with? m '(0) (hash)))
  (check-true (mock-called-with? m '(0) (hash '#:align 'left '#:width 3)))
  (check-false (mock-called-with? m '(42) (hash))))
