#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [keyword-hash? flat-contract?]
  [arguments? predicate/c]
  [arguments-positional (-> arguments? list?)]
  [arguments-keyword (-> arguments? keyword-hash?)]
  [arguments (unconstrained-domain-> arguments?)]
  [apply/arguments (-> procedure? arguments? any)]
  [make-arguments (-> list? keyword-hash? arguments?)]
  [empty-arguments arguments?]))

(module+ test
  (require racket/format
           rackunit))

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

(define (apply/arguments f args)
  (define vs (arguments-positional args))
  (define kwargs (hash->list (arguments-keyword args)))
  (define kws (map car kwargs))
  (define kw-vs (map cdr kwargs))
  (keyword-apply f kws kw-vs vs))

(module+ test
  (test-case "apply/arguments"
    (define args (arguments '("fooooo" "bar" "bazz") < #:key string-length))
    (check-equal? (apply/arguments sort args) '("bar" "bazz" "fooooo"))))

(define empty-arguments (arguments))
