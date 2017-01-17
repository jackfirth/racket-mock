#lang sweet-exp racket/base

require racket/contract/base

provide
  contract-out
    keyword-hash? flat-contract?
    kws+vs->hash (-> (listof keyword?) list? keyword-hash?)
    arguments? predicate/c
    arguments-positional (-> arguments? list?)
    arguments-keyword (-> arguments? keyword-hash?)
    arguments (unconstrained-domain-> arguments?)
    make-arguments (-> list? keyword-hash? arguments?)
    empty-arguments arguments?
    struct (exn:fail:unexpected-arguments exn:fail)
      ([message string?]
       [continuation-marks continuation-mark-set?]
       [args arguments?])
    make-raise-unexpected-arguments-exn (-> symbol? procedure?)

require fancy-app

module+ test
  require racket/format
          rackunit

(define keyword-hash? (hash/c keyword? any/c #:immutable #t #:flat? #t))

(module+ test
  (check-true (keyword-hash? (hash '#:foo 'bar '#:baz "blah")))
  (check-false (keyword-hash? (make-hash '((#:foo . bar) (#:baz . "blah")))))
  (check-false (keyword-hash? (hash '#:foo 'bar '#:baz "blah" 0 1))))

(define (kws+vs->hash kws vs) (make-immutable-hash (map cons kws vs)))

(define (arguments-custom-write args port mode)
  (define recur
    (case mode
      [(#t) write]
      [(#f) display]
      [else (lambda (p port) (print p port mode))]))
  (write-string "(arguments" port)
  (for ([arg (in-list (arguments-positional args))])
    (write-string " " port)
    (recur arg port))
  (define kwargs (arguments-keyword args))
  (define kws (sort (hash-keys (arguments-keyword args)) keyword<?))
  (for ([kw (in-list kws)])
    (define arg (hash-ref kwargs kw))
    (write-string " #:" port)
    (write-string (keyword->string kw) port)
    (write-string " " port)
    (recur arg port))
  (write-string ")" port))

(struct arguments (positional keyword)
  #:transparent
  #:constructor-name make-arguments
  #:omit-define-syntaxes
  #:methods gen:custom-write
  [(define write-proc arguments-custom-write)])

(define arguments
  (make-keyword-procedure
   (λ (kws kw-vs . vs)
     (make-arguments vs (kws+vs->hash kws kw-vs)))))

(module+ test
  (test-equal? "Args constructors should agree when given no values"
               (arguments) (make-arguments '() (hash)))
  (test-equal? "Args constructors should agree when given positional values"
               (arguments 1 2 3) (make-arguments '(1 2 3) (hash)))
  (test-equal? "Args constructors should agree when given keyword values"
               (arguments #:foo 'bar #:baz "blah")
               (make-arguments '() (hash '#:foo 'bar '#:baz "blah")))
  (test-equal?
   "Args constructors should agree when given positional and keyword values"
   (arguments 1 2 3 #:foo 'bar #:baz "blah")
   (make-arguments '(1 2 3) (hash '#:foo 'bar '#:baz "blah")))
  (test-equal?
   "Args value should write the same as positional-first keyword sorted call"
   (~s (arguments 1  #:foo 'bar 2 3 #:baz "blah"))
   "(arguments 1 2 3 #:baz \"blah\" #:foo bar)")
  (test-equal?
   "Args value should display the same as positional-first keyword sorted call"
   (~a (arguments 1  #:foo 'bar 2 3 #:baz "blah"))
   "(arguments 1 2 3 #:baz blah #:foo bar)")
  (test-equal?
   "Args value should print the same as positional-first keyword sorted call"
   (~v (arguments 1  #:foo 'bar 2 3 #:baz "blah"))
   "(arguments 1 2 3 #:baz \"blah\" #:foo 'bar)")
  (test-begin
   "Args values should print unambiguosly in the face of quoted positional keywords"
   (check-not-equal? (~v (arguments #:foo 'bar))
                     (~v (arguments '#:foo 'bar)))))

(define empty-arguments (arguments))

(define (format-positional-args-message args)
  (apply string-append
         (map (format "\n   ~v" _) args)))

(module+ test
  (check-equal? (format-positional-args-message '(1 foo "blah"))
                "\n   1\n   'foo\n   \"blah\""))

(define (format-keyword-args-message kwargs)
  (apply string-append
         (hash-map kwargs (format "\n   ~a: ~v" _ _))))

(struct exn:fail:unexpected-arguments exn:fail (args) #:transparent)

(define (unexpected-call-message source-name
                                 #:positional positional-msg
                                 #:keyword keyword-msg)
  (define (arg-part type msg) (format "\n  ~a: ~a" type msg))
  (define first-part (format "~a: unexpectedly called" source-name))
  (if (or positional-msg keyword-msg)
      (format "~a with arguments~a~a"
              first-part
              (if positional-msg (arg-part 'positional positional-msg) "")
              (if keyword-msg (arg-part 'keyword keyword-msg) ""))
      first-part))

(module+ test
  (check-equal? (unexpected-call-message 'foo #:positional #f #:keyword #f)
                "foo: unexpectedly called")
  (check-equal? (unexpected-call-message 'foo #:positional "pos" #:keyword #f)
                "foo: unexpectedly called with arguments\n  positional: pos")
  (check-equal? (unexpected-call-message 'foo #:positional #f #:keyword "kw")
                "foo: unexpectedly called with arguments\n  keyword: kw")
  (check-equal? (unexpected-call-message 'foo #:positional "pos" #:keyword "kw")
                "foo: unexpectedly called with arguments
  positional: pos
  keyword: kw"))

(define (make-raise-unexpected-arguments-exn source-name)
  (make-keyword-procedure
   (λ (kws kw-vs . vs)
     (define kwargs (kws+vs->hash kws kw-vs))
     (define message
       (unexpected-call-message source-name
                                #:positional (format-positional-args-message vs)
                                #:keyword (format-keyword-args-message kwargs)))
     (raise
      (exn:fail:unexpected-arguments
       message (current-continuation-marks) (make-arguments vs kwargs))))))
