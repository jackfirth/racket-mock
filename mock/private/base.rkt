#lang sweet-exp racket/base

require racket/contract/base

provide
  with-mock-behavior
  contract-out
    mock? predicate/c
    make-mock (->* () (procedure?) mock?)
    mock-reset! (-> mock? void?)
    struct (exn:fail:unexpected-call exn:fail)
      ([message string?]
       [continuation-marks continuation-mark-set?]
       [args list?]
       [kwargs (hash/c keyword? any/c)])
    raise-unexpected-call-exn procedure?
    mock-calls (-> mock? (listof mock-call?))
    struct mock-call
      [args list?] [kwargs (hash/c keyword? any/c)] [results list?]
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

(define (kws+vs->kwargs kws vs) (make-immutable-hash (map cons kws vs)))

(define (format-positional-args-message args)
  (apply string-append
         (for/list ([v args])
           (format "\n   ~a" v))))

(define (format-keyword-args-message kwargs)
  (apply string-append
         (for/list ([(kw v) kwargs])
           (format "\n   ~a: ~a" kw v))))

(struct exn:fail:unexpected-call exn:fail (args kwargs) #:transparent)
(define unexpected-call-message-format
  "mock: unexpectedly called with arguments\n  positional: ~a\n  keyword: ~a")

(define raise-unexpected-call-exn
  (make-keyword-procedure
   (λ (kws kw-vs . vs)
     (define kwargs (kws+vs->kwargs kws kw-vs))
     (define message
       (format unexpected-call-message-format
               (format-positional-args-message vs)
               (format-keyword-args-message kwargs)))
     (raise
      (exn:fail:unexpected-call
       message (current-continuation-marks) vs kwargs)))))

(define call-mock-behavior
  (make-keyword-procedure
   (λ (kws kw-vs a-mock . vs)
     (match-define (mock current-behavior calls-box) a-mock)
     (define results
       (with-values-as-list (keyword-apply (current-behavior) kws kw-vs vs)))
     (add-call! calls-box (mock-call vs (kws+vs->kwargs kws kw-vs) results))
     (apply values results))))

(struct mock-call (args kwargs results) #:transparent)
(struct mock (behavior calls-box)
  #:property prop:procedure call-mock-behavior)

(define (add-call! calls-box call)
  (box-transform! calls-box (append _ (list call))))

(define (make-mock [behavior raise-unexpected-call-exn])
  (mock (make-parameter behavior) (box '())))

(define (mock-called-with? mock args kwargs)
  (for/or ([call (in-list (mock-calls mock))])
    (and (equal? args (mock-call-args call))
         (equal? kwargs (mock-call-kwargs call)))))

(define mock-calls (compose unbox mock-calls-box))
(define mock-num-calls (compose length mock-calls))

(module+ test
  (test-case "Standard mock use cases"
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
  (test-case "Default mock behavior throws"
    (check-exn exn:fail:unexpected-call?
               (thunk ((make-mock) 10 #:foo 'bar)))))

(define (mock-reset! a-mock)
  (set-box! (mock-calls-box a-mock) '()))

(module+ test
  (test-case "Resetting mocks"
    (define m (make-mock void))
    (m 'foo)
    (check-equal? (mock-num-calls m) 1)
    (mock-reset! m)
    (check-equal? (mock-num-calls m) 0)))

(define-simple-macro (with-mock-behavior ([mock:expr new-behavior:expr] ...) body ...)
  (parameterize ([(mock-behavior mock) new-behavior] ...) body ...))

(module+ test
  (test-case "Changing mock behavior"
    (define num-proc-mock (make-mock add1))
    (check-equal? (num-proc-mock 0) 1)
    (with-mock-behavior ([num-proc-mock sub1])
      (check-equal? (num-proc-mock 0) -1))))
