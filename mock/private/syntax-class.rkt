#lang sweet-exp racket/base

provide definition-header
        id/mock
        mocks-clause
        opaque-clause
        static-val-transformer
        stub-header
        stubs
        struct-out mock-static-info
        struct-out mocks-syntax-info

require racket/function
        racket/match
        racket/syntax
        syntax/stx
        syntax/parse/define
        "syntax-util.rkt"
        for-template racket/base
                     "opaque.rkt"
                     "base.rkt"
                     "not-implemented.rkt"

require syntax/parse

(define-syntax-class definition-header
  (pattern (~or root-id:id
                (~or (subheader:definition-header (~or arg-clause kwarg-clause) ...)
                     (subheader:definition-header (~or arg-clause kwarg-clause) ... . rest-arg:id)))
           #:attr id
           (or (attribute root-id) (attribute subheader.id))
           #:attr fresh-id
           (if (attribute root-id)
               (generate-temporary #'id)
               (attribute subheader.fresh-id))
           #:attr fresh
           (cond [(attribute root-id) #'fresh-id]
                 [(attribute rest-arg)
                  #'(subheader.fresh arg-clause ... kwarg-clause ... . rest-arg)]
                 [else #'(subheader.fresh arg-clause ... kwarg-clause ...)])
           #:attr fresh-id-secondary
           (if (attribute root-id)
               (generate-temporary #'id)
               (attribute subheader.fresh-id-secondary))
           #:attr fresh-secondary
           (cond [(attribute root-id) #'fresh-id-secondary]
                 [(attribute rest-arg)
                  #'(subheader.fresh-secondary arg-clause ... kwarg-clause ... . rest-arg)]
                 [else #'(subheader.fresh-secondary arg-clause ... kwarg-clause ...)])))

(define-splicing-syntax-class mock-clause
  (pattern (~seq #:mock mocked-id:id
                 (~optional (~seq #:as given-id:id))
                 (~optional (~seq #:with-behavior given-behavior:expr)))
           #:attr id (or (attribute given-id) #'mocked-id)
           #:attr fresh-id (generate-temporary #'id)
           #:attr value
           (if (attribute given-behavior)
               #'(mock #:name 'id #:behavior given-behavior)
               #'(mock #:name 'id))
           #:attr definition #'(define fresh-id value)
           #:attr binding #'[mocked-id fresh-id]
           #:attr static-info #'(mock-static-info #'id #'fresh-id)))

(define-splicing-syntax-class mocks-clause
  (pattern (~seq clause:mock-clause ...)
           #:attr definitions #'(begin clause.definition ...)
           #:attr bindings #'(clause.binding ...)
           #:attr static-info #'(list clause.static-info ...)))

(define-splicing-syntax-class opaque-clause
  #:attributes (definitions bindings static-info)
  (pattern (~seq)
           #:attr definitions #'(begin)
           #:attr bindings #'()
           #:attr static-info #'(list))
  (pattern (~seq #:opaque id:id)
           #:with id? (predicate-id #'id)
           #:with fresh-id (generate-temporary #'id)
           #:with fresh-id? (predicate-id #'fresh-id)
           #:attr definitions #'(define-opaque fresh-id #:name id)
           #:attr bindings #'([id fresh-id] [id? fresh-id?])
           #:attr static-info #'(list (mock-static-info #'id #'fresh-id)
                                      (mock-static-info #'id? #'fresh-id?)))
  (pattern (~seq #:opaque (id:id ...))
           #:with (id? ...) (stx-map predicate-id #'(id ...))
           #:with (fresh-id ...) (generate-temporaries #'(id ...))
           #:with (fresh-id? ...) (stx-map predicate-id #'(fresh-id ...))
           #:attr definitions #'(begin (define-opaque fresh-id #:name id) ...)
           #:attr bindings #'([id fresh-id] ... [id? fresh-id?] ...)
           #:attr static-info
           #'(map mock-static-info
                  (syntax->list #'(id ... id? ...))
                  (syntax->list #'(fresh-id ... fresh-id? ...)))))

(define-syntax-class stub-header
  (pattern plain-id:id
           #:attr definition
           #'(define plain-id (not-implemented-proc 'plain-id)))
  (pattern header:definition-header
           #:attr definition
           #'(define header (raise-not-implemented 'header.id))))

(define-splicing-syntax-class stubs
  (pattern (~seq stubbed:stub-header ...+)
           #:attr definitions #'(begin stubbed.definition ...)))

(struct mock-static-info (id bound-id) #:transparent)
(struct mocks-syntax-info (proc-id opaques mocks) #:transparent)

(define (mock-bindings mock-static-infos)
  (map (match-lambda [(mock-static-info mock-id mock-impl-id)
                      (list (syntax-local-introduce mock-id) mock-impl-id)])
       mock-static-infos))

(struct static-val-transformer (id value)
  #:property prop:rename-transformer (struct-field-index id))

(define (static-val static-trans-stx)
  (define-values (trans _)
    (syntax-local-value/immediate static-trans-stx (thunk (values #f #f))))
  (and trans (static-val-transformer-value trans)))

(define-syntax-class id/mock
  #:description "define/mock identifier"
  (pattern id:id
           #:do [(define static (static-val #'id))]
           #:fail-unless (mocks-syntax-info? static)
           (format "identifier ~a not bound with define/mock" (syntax-e #'id))
           #:do [(match-define (mocks-syntax-info proc-id opaques mocks)
                   static)]
           #:attr proc-id proc-id
           #:with (opaque-binding-stx ...) (mock-bindings opaques)
           #:with ([mock-id mock-impl-id] ...) (mock-bindings mocks)
           #:attr [opaque-binding 1] (syntax->list #'(opaque-binding-stx ...))
           #:attr [mock-binding 1]
           (syntax->list #'([mock-id mock-impl-id] ...))))
