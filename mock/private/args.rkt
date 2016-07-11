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
    struct (exn:fail:unexpected-arguments exn:fail)
      ([message string?]
       [continuation-marks continuation-mark-set?]
       [args arguments?])
    make-raise-unexpected-arguments-exn (-> string? procedure?)

require fancy-app

module+ test
  require rackunit

(define keyword-hash? (hash/c keyword? any/c #:immutable #t #:flat? #t))

(module+ test
  (check-true (keyword-hash? (hash '#:foo 'bar '#:baz "blah")))
  (check-false (keyword-hash? (make-hash '((#:foo . bar) (#:baz . "blah")))))
  (check-false (keyword-hash? (hash '#:foo 'bar '#:baz "blah" 0 1))))

(define (kws+vs->hash kws vs) (make-immutable-hash (map cons kws vs)))

(struct arguments (positional keyword)
  #:transparent
  #:constructor-name make-arguments
  #:omit-define-syntaxes)

(define arguments
  (make-keyword-procedure
   (λ (kws kw-vs . vs)
     (make-arguments vs (kws+vs->hash kws kw-vs)))))

(module+ test
  (check-equal? (arguments) (make-arguments '() (hash)))
  (check-equal? (arguments 1 2 3) (make-arguments '(1 2 3) (hash)))
  (check-equal? (arguments #:foo 'bar #:baz "blah")
                (make-arguments '() (hash '#:foo 'bar '#:baz "blah")))
  (check-equal? (arguments 1 2 3 #:foo 'bar #:baz "blah")
                (make-arguments '(1 2 3) (hash '#:foo 'bar '#:baz "blah"))))

(define (format-positional-args-message args)
  (apply string-append
         (map (format "\n   ~v" _) args)))

(module+ test
  (check-equal? (format-positional-args-message '(1 foo "blah"))
                "\n   1\n   'foo\n   \"blah\""))

(define (format-keyword-args-message kwargs)
  (apply string-append
         (hash-map kwargs (format "\n   ~a: ~v" _ _) #t)))

(module+ test
  (check-equal? (format-keyword-args-message (hash '#:foo 'bar '#:baz "blah"))
                "\n   #:baz: \"blah\"\n   #:foo: 'bar"))

(struct exn:fail:unexpected-arguments exn:fail (args) #:transparent)
(define unexpected-call-message-format
  "~a: unexpectedly called with arguments\n  positional: ~a\n  keyword: ~a")

(define (make-raise-unexpected-arguments-exn source-name)
  (make-keyword-procedure
   (λ (kws kw-vs . vs)
     (define kwargs (kws+vs->hash kws kw-vs))
     (define message
       (format unexpected-call-message-format
               source-name
               (format-positional-args-message vs)
               (format-keyword-args-message kwargs)))
     (raise
      (exn:fail:unexpected-arguments
       message (current-continuation-marks) (make-arguments vs kwargs))))))
