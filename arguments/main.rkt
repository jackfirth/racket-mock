#lang racket/base

(require racket/contract/base)

(provide define/arguments
         lambda/arguments)

(provide
 (contract-out
  [keyword-hash? flat-contract?]
  [arguments? predicate/c]
  [arguments-positional (-> arguments? list?)]
  [arguments-keyword (-> arguments? keyword-hash?)]
  [arguments-merge (->* () #:rest (listof arguments?) arguments?)]
  [arguments (unconstrained-domain-> arguments?)]
  [apply/arguments (-> procedure? arguments? any)]
  [make-arguments (-> list? keyword-hash? arguments?)]
  [empty-arguments arguments?]))

(require racket/list
         syntax/parse/define)

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

(define-simple-macro (lambda/arguments args:id body:expr ...+)
  (make-keyword-procedure
   (λ (kws kw-vs . vs)
     (define args (make-arguments vs (kws+vs->hash kws kw-vs)))
     body ...)))

(define-simple-macro (define/arguments (id:id args:id) body:expr ...+)
  (define id (lambda/arguments args body ...)))

(define/arguments (arguments args) args)

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
  (define kwargs
    (sort (hash->list (arguments-keyword args)) keyword<? #:key car))
  (define kws (map car kwargs))
  (define kw-vs (map cdr kwargs))
  (keyword-apply f kws kw-vs vs))

(module+ test
  (test-case "apply/arguments"
    (test-begin
     (define args (arguments '("fooooo" "bar" "bazz") < #:key string-length))
     (check-equal? (apply/arguments sort args) '("bar" "bazz" "fooooo")))
    (test-case "keyword-sorting"
      (define args (arguments #:a 1 #:b 2 #:c 3 #:foo 4 #:baz 5))
      (check-equal? (apply/arguments arguments args) args))))

(define empty-arguments (arguments))

(define (arguments-merge . args-vs)
  (define pos (append* (map arguments-positional args-vs)))
  (define kw-hash
    (for*/hash ([h (in-list (map arguments-keyword args-vs))]
                [(k v) (in-hash h)])
      (values k v)))
  (make-arguments pos kw-hash))

(module+ test
  (check-equal? (arguments-merge) empty-arguments)
  (check-equal? (arguments-merge (arguments 1 2)
                                 (arguments 3 4 5)
                                 (arguments 6))
                (arguments 1 2 3 4 5 6))
  (check-equal? (arguments-merge (arguments #:foo 1)
                                 (arguments #:bar 2 #:baz 3)
                                 (arguments #:foo 'replace))
                (arguments #:foo 'replace #:bar 2 #:baz 3))
  (check-equal? (arguments-merge (arguments 1 2 #:foo 3)
                                 (arguments 4 #:bar 5 #:baz 6))
                (arguments 1 2 4 #:foo 3 #:bar 5 #:baz 6)))
