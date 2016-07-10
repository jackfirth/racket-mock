#lang sweet-exp racket/base

require racket/contract/base

provide
  with-mock-behavior
  contract-out
    mock? predicate/c
    make-mock (-> procedure? mock?)
    mock-calls (-> mock? (listof mock-call?))
    struct mock-call ([args list?] [kwargs (hash/c keyword? any/c)] [results list?])
    mock-called-with? (-> mock? list? (hash/c keyword? any/c) boolean?)
    mock-num-calls (-> mock? exact-nonnegative-integer?)

require fancy-app
        racket/match
        racket/function
        rackunit
        syntax/parse/define

module+ test
  require rackunit
          racket/format


(define (box-transform! a-box f)
  (set-box! a-box (f (unbox a-box))))

(define-syntax-rule (with-values-as-list body ...)
  (call-with-values (thunk body ...) list))

(define call-mock-behavior
  (make-keyword-procedure
   (λ (kws kw-vs a-mock . vs)
     (match-define (mock current-behavior calls-box) a-mock)
     (define results
       (with-values-as-list (keyword-apply (current-behavior) kws kw-vs vs)))
     (define kwargs (make-immutable-hash (map cons kws kw-vs)))
     (add-call! calls-box (mock-call vs kwargs results))
     (apply values results))))

(struct mock-call (args kwargs results) #:transparent)
(struct mock (behavior calls-box)
  #:property prop:procedure call-mock-behavior)

(define (add-call! calls-box call)
  (box-transform! calls-box (append _ (list call))))

(define (make-mock proc)
  (mock (make-parameter proc) (box '())))

(define (mock-called-with? mock args kwargs)
  (for/or ([call (in-list (mock-calls mock))])
    (and (equal? args (mock-call-args call))
         (equal? kwargs (mock-call-kwargs call)))))

(define mock-calls (compose unbox mock-calls-box))
(define mock-num-calls (compose length mock-calls))

(module+ test
  (define m (make-mock ~a))
  (check-equal? (m 0) "0")
  (check-equal? (m 0 #:width 3 #:align 'left) "0  ")
  (check-equal? (mock-calls m)
                (list (mock-call '(0) (hash) '("0"))
                      (mock-call '(0) (hash '#:width 3 '#:align 'left) '("0  "))))
  (check-equal? (mock-num-calls m) 2)
  (check-true (mock-called-with? m '(0) (hash)))
  (check-true (mock-called-with? m '(0) (hash '#:align 'left '#:width 3)))
  (check-false (mock-called-with? m '(42) (hash))))

(define-simple-macro (with-mock-behavior ([mock:id new-behavior:expr] ...) body ...)
  (parameterize ([(mock-behavior mock) new-behavior] ...) body ...))

(module+ test
  (define num-proc-mock (make-mock add1))
  (check-equal? (num-proc-mock 0) 1)
  (with-mock-behavior ([num-proc-mock sub1])
    (check-equal? (num-proc-mock 0) -1)))
