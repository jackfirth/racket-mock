#lang sweet-exp racket/base

require racket/contract/base

provide
  with-mock-behavior
  contract-out
    mock? predicate/c
    mock (->* () (#:name string? #:behavior procedure?) mock?)
    mock-reset! (-> mock? void?)
    mock-calls (-> mock? (listof mock-call?))
    struct mock-call ([args arguments?] [results list?])
    mock-called-with? (-> mock? arguments? boolean?)
    mock-num-calls (-> mock? exact-nonnegative-integer?)

require fancy-app
        racket/match
        racket/function
        rackunit
        syntax/parse/define
        "args.rkt"

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
     (define current-behavior (mock-behavior a-mock))
     (define calls-box (mock-calls-box a-mock))
     (define results
       (with-values-as-list (keyword-apply (current-behavior) kws kw-vs vs)))
     (define args (make-arguments vs (kws+vs->hash kws kw-vs)))
     (add-call! calls-box (mock-call args results))
     (apply values results))))

(struct mock-call (args results) #:transparent)
(struct mock (behavior calls-box)
  #:property prop:procedure call-mock-behavior
  #:constructor-name make-mock
  #:omit-define-syntaxes)

(define (add-call! calls-box call)
  (box-transform! calls-box (append _ (list call))))

(define (mock #:behavior [given-behavior #f] #:name [name "mock"])
  (define behavior
    (or given-behavior (make-raise-unexpected-arguments-exn name)))
  (make-mock (make-parameter behavior) (box '())))

(define mock-calls (compose unbox mock-calls-box))

(module+ test
  (test-case "Mocks should record calls made with them"
    (define m (mock #:behavior ~a))
    (check-equal? (m 0) "0")
    (check-equal? (m 0 #:width 3 #:align 'left) "0  ")
    (check-equal? (mock-calls m)
                  (list (mock-call (arguments 0) '("0"))
                        (mock-call (arguments 0 #:width 3 #:align 'left)
                                   '("0  "))))))

(define mock-num-calls (compose length mock-calls))

(module+ test
  (test-case "Mocks should record how many times they've been called"
    (define m (mock #:behavior ~a))
    (check-equal? (m 0) "0")
    (check-equal? (m 1) "1")
    (check-equal? (m 2) "2")
    (check-equal? (mock-num-calls m) 3)))

(define (mock-called-with? mock args)
  (for/or ([call (in-list (mock-calls mock))])
    (equal? args (mock-call-args call))))

(module+ test
  (test-case "Mock call arguments should be queryable"
    (define m (mock #:behavior void))
    (m 0)
    (m 10)
    (check-true (mock-called-with? m (arguments 0)))
    (check-true (mock-called-with? m (arguments 10)))
    (check-false (mock-called-with? m (arguments 42))))
  (test-case "Default mock behavior should throw"
    (check-exn exn:fail:unexpected-arguments?
               (thunk ((mock) 10 #:foo 'bar)))))

(define (mock-reset! a-mock)
  (set-box! (mock-calls-box a-mock) '()))

(module+ test
  (test-case "Resetting a mock should erase its call history"
    (define m (mock #:behavior void))
    (m 'foo)
    (check-equal? (mock-num-calls m) 1)
    (mock-reset! m)
    (check-equal? (mock-num-calls m) 0)))

(define-simple-macro (with-mock-behavior ([mock:expr new-behavior:expr] ...) body ...)
  (parameterize ([(mock-behavior mock) new-behavior] ...) body ...))

(module+ test
  (test-case "Mock behavior should be changeable"
    (define num-proc-mock (mock #:behavior add1))
    (check-equal? (num-proc-mock 0) 1)
    (with-mock-behavior ([num-proc-mock sub1])
      (check-equal? (num-proc-mock 0) -1))))
