#lang racket

(require racket/splicing
         rackunit
         unstable/sequence)

(struct proc-mock (proc calls)
  #:property prop:procedure (struct-field-index proc))

(struct proc-call (args result) #:prefab)

(define (make-mock proc)
  (define calls (box '()))
  (define (add-call! call)
    (set-box! calls (cons call (unbox calls))))
  (define (wrapper . vs)
    (define result (apply proc vs))
    (add-call! (proc-call vs result))
    result)
  (proc-mock wrapper calls))

(define (initialize-mock! mock)
  (set-box! (proc-mock-calls mock) '()))

(define (mock-calls mock)
  (unbox (proc-mock-calls mock)))

(define (const-mock v) (make-mock (const v)))
(define (void-mock) (make-mock void))

(define (unzip-list vs)
  (define groups (sequence->list (in-slice 2 vs)))
  (values
   (map first groups)
   (map second groups)))

(define (case-mock . cases)
  (define-values (case-vs case-results) (unzip-list cases))
  (lambda (v)
    (for/first ([case-v case-vs]
                [case-result case-results]
                #:when (equal? case-v v))
      case-result)))

(define (called-with? args mock)
  (not (false? (member args (map proc-call-args (mock-calls mock))))))

(define (num-calls mock)
  (length (mock-calls mock)))

(define-syntax-rule (define-id/mock-value-as id ([mock-id mock-value-id mock-value] ...) expr)
  (begin
    (define (make-with-mocks mock-id ...) expr)
    (define id (make-with-mocks mock-id ...))
    (module+ test
      (define mock-value-id mock-value) ...
      (define id (make-with-mocks mock-value ...)))))

(define-syntax-rule (define-id/mock-value id ([mock-id mock-value] ...) expr)
  (define-id/mock-value-as id ([mock-id mock-id mock-value] ...) expr))

(define-syntax-rule (define-id/mock id ([mock-id mock-expr] ...) expr)
  (splicing-let ([mock-value mock-expr] ...)
    (define-id/mock-value id ([mock-id mock-value] ...) expr)))

(define-syntax-rule (define-id/mock-as id ([mock-id mock-value-id mock-expr] ...) expr)
  (splicing-let ([mock-value mock-expr] ...)
    (define-id/mock-value-as id ([mock-id mock-value-id mock-value] ...) expr)))

(define-id/mock displayln-twice
  ([displayln (void-mock)])
  (lambda (v)
    (displayln v)
    (displayln v)))

(define-simple-check (check-called-with? mock args)
  (called-with? args mock))

(define-simple-check (check-num-calls mock expected-num-calls)
  (equal? (num-calls mock) expected-num-calls))

(module+ test
  (displayln-twice "foo")
  (check-called-with? displayln '("foo"))
  (check-num-calls displayln 2))
