#lang sweet-exp racket/base

require racket/contract/base

provide
  with-mock-behavior
  contract-out
    current-mock-name (-> (or/c symbol? #f))
    current-mock-calls (-> (listof mock-call?))
    current-mock-num-calls (-> exact-nonnegative-integer?)
    mock? predicate/c
    mock (->* () (#:name symbol? #:behavior procedure?) mock?)
    mock-reset! (-> mock? void?)
    mock-reset-all! (->* () #:rest (listof mock?) void?)
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
        "util.rkt"

module+ test
  require rackunit
          racket/format


(define (make-mock-proc-parameter source-name)
  (define message
    (format "~a: can't be called outside mock behavior" source-name))
  (make-parameter
   (thunk (raise (make-exn:fail message (current-continuation-marks))))))

(define-simple-macro (define-mock-proc-parameter proc-id:id id:id)
  (define-values (proc-id id)
    (values (make-mock-proc-parameter 'id)
            (lambda () ((proc-id))))))

(define-mock-proc-parameter current-mock-name-proc current-mock-name)
(define-mock-proc-parameter current-mock-calls-proc current-mock-calls)
(define-mock-proc-parameter current-mock-num-calls-proc current-mock-num-calls)

(module+ test
  (test-exn "Mock reflection params should only be callable inside behavior"
            #rx"current-mock-name: can't be called outside mock behavior"
            current-mock-name))

(define call-mock-behavior
  (make-keyword-procedure
   (λ (kws kw-vs a-mock . vs)
     (define current-behavior (mock-behavior a-mock))
     (define calls-box (mock-calls-box a-mock))
     (define calls (unbox calls-box))
     (define results
       (parameterize ([current-mock-name-proc (const (mock-name a-mock))]
                      [current-mock-calls-proc (const calls)]
                      [current-mock-num-calls-proc (const (length calls))])
         (with-values-as-list
          (keyword-apply (current-behavior) kws kw-vs vs))))
     (define args (make-arguments vs (kws+vs->hash kws kw-vs)))
     (box-cons-end! calls-box (mock-call args results))
     (apply values results))))

(define (mock-custom-write a-mock port mode)
  (write-string "#<procedure:mock" port)
  (define name (mock-name a-mock))
  (when name
    (write-string ":" port)
    (write-string (symbol->string name) port))
  (write-string ">" port))

(struct mock-call (args results) #:transparent)
(struct mock (name behavior calls-box)
  #:property prop:procedure call-mock-behavior
  #:property prop:object-name (struct-field-index name)
  #:constructor-name make-mock
  #:omit-define-syntaxes
  #:methods gen:custom-write
  [(define write-proc mock-custom-write)])

(define (mock #:behavior [given-behavior #f] #:name [name #f])
  (define behavior
    (or given-behavior raise-unexpected-mock-call))
  (make-mock name (make-parameter behavior) (box '())))

(define mock-calls (compose unbox mock-calls-box))

(module+ test
  (test-case "Mocks should record calls made with them"
    (define m (mock #:behavior ~a))
    (check-equal? (m 0) "0")
    (check-equal? (m 0 #:width 3 #:align 'left) "0  ")
    (check-equal? (mock-calls m)
                  (list (mock-call (arguments 0) '("0"))
                        (mock-call (arguments 0 #:width 3 #:align 'left)
                                   '("0  ")))))
  (test-equal?
   "Mocks should print like named procedures, but identify themselves as mocks"
   (~a (mock #:name 'foo)) "#<procedure:mock:foo>")
  (test-equal? "Anonymous mocks should print like a procedure named mock"
               (~a (mock)) "#<procedure:mock>")
  (define return-mock-name (thunk* (current-mock-name)))
  (test-equal?
   "The current mock name should be available to behaviors"
   ((mock #:name 'foo #:behavior return-mock-name) 1 2 3) 'foo)
  (test-equal?
   "The current mock name should be false for anonymous mocks"
   ((mock #:behavior return-mock-name) 1 2 3) #f)
  (define return-mock-calls (thunk* (current-mock-calls)))
  (test-begin
   "The current mock call history should be available to behaviors"
   (define calls-mock (mock #:behavior return-mock-calls))  
   (check-equal? (calls-mock 1 2 3) '())
   (check-equal? (calls-mock #:foo 'bar)
                 (list (mock-call (arguments 1 2 3) (list (list))))))
  (define return-mock-count (thunk* (current-mock-num-calls)))
  (test-begin
   "The current mock call count should be available to behaviors"
   (define count-mock (mock #:behavior return-mock-count))
   (check-equal? (count-mock 1 2 3) 0)
   (check-equal? (count-mock #:foo 'bar) 1)
   (check-equal? (count-mock 'a #:b 'c) 2)))

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

(define raise-unexpected-mock-call
  (make-keyword-procedure
   (λ (kws kw-vs . vs)
     (define proc (make-raise-unexpected-arguments-exn (or (current-mock-name) 'mock)))
     (keyword-apply proc kws kw-vs vs))))

(define (mock-reset-all! . mocks)
  (for-each mock-reset! mocks))
