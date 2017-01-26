#lang racket/base

(provide definition-header/mock
         id/mock)

(require (for-syntax racket/base)
         (for-template racket/base
                       racket/splicing
                       "base.rkt"
                       "history.rkt"
                       "opaque.rkt"
                       "syntax-param.rkt")
         racket/match
         racket/syntax
         syntax/parse
         syntax/parse/experimental/template
         syntax/stx
         syntax/transformer
         "syntax-util.rkt")


(define-splicing-syntax-class id/alt-name
  #:attributes (orig alt id fresh)
  (pattern (~seq orig:id (~optional (~seq #:as alt:id)))
           #:attr id (template (?? alt orig))
           #:attr fresh (generate-temporary #'id)))

(define-splicing-syntax-class mock-clause
  (pattern (~seq #:mock mocked-id:id/alt-name
                 (~optional (~seq #:with-behavior given-behavior:expr)))
           #:attr definition
           (template
            (define mocked-id.fresh
              (mock #:name 'mocked-id.id
                    #:external-histories histories
                    (?? (?@ #:behavior given-behavior)))))
           #:attr binding #'[mocked-id.orig mocked-id.fresh]
           #:attr static-info
           #'(binding-static-info #'mocked-id.id #'mocked-id.fresh)))

(define-splicing-syntax-class mock-param-clause
  #:attributes (definition
                 [binding 1]
                 parameterization
                 binding-info
                 parameterization-info)
  (pattern (~seq #:mock-param mocked-id:id/alt-name
                 (~optional (~seq #:with-behavior given-behavior:expr)))
           #:attr definition
           (template
            (define mocked-id.fresh
              (mock #:name 'mocked-id.id
                    #:external-histories histories
                    (?? (?@ #:behavior given-behavior)))))
           #:attr [binding 1]
           (if (attribute mocked-id.alt)
               (list #'[mocked-id.alt mocked-id.fresh])
               (list))
           #:attr parameterization #'[mocked-id.orig mocked-id.fresh]
           #:attr binding-info
           (if (attribute mocked-id.alt)
               #'(binding-static-info #'mocked-id.alt #'mocked-id.fresh)
               #'(values #f))
           #:attr parameterization-info
           #'(binding-static-info #'mocked-id.orig #'mocked-id.fresh)))

(define-splicing-syntax-class mocks-clause
  (pattern (~seq (~or clause:mock-clause param-clause:mock-param-clause) ...)
           #:attr definitions
           #'(begin clause.definition ... param-clause.definition ...)
           #:attr bindings
           #'(clause.binding ... param-clause.binding ... ...)
           #:attr paramerizations #'(param-clause.parameterization ...)
           #:attr static-info
           #'(filter values
                     (list clause.static-info ...
                           param-clause.binding-info ...))
           #:attr param-static-info
           #'(list param-clause.parameterization-info ...)))

(define-splicing-syntax-class opaque-clause
  #:attributes (definitions [binding 1] static-info)
  (pattern (~seq)
           #:attr definitions #'(begin)
           #:attr [binding 1] (list)
           #:attr static-info #'(list))
  (pattern (~seq #:opaque id:id)
           #:with id? (predicate-id #'id)
           #:with fresh-id (generate-temporary #'id)
           #:with fresh-id? (predicate-id #'fresh-id)
           #:attr definitions #'(define-opaque fresh-id #:name id)
           #:attr [binding 1] (list #'[id fresh-id] #'[id? fresh-id?])
           #:attr static-info #'(list (binding-static-info #'id #'fresh-id)
                                      (binding-static-info #'id? #'fresh-id?)))
  (pattern (~seq #:opaque (id:id ...))
           #:with (id? ...) (stx-map predicate-id #'(id ...))
           #:with (fresh-id ...) (generate-temporaries #'(id ...))
           #:with (fresh-id? ...) (stx-map predicate-id #'(fresh-id ...))
           #:attr definitions #'(begin (define-opaque fresh-id #:name id) ...)
           #:attr [binding 1]
           (syntax->list #'([id fresh-id] ... [id? fresh-id?] ...))
           #:attr static-info
           #'(map binding-static-info
                  (syntax->list #'(id ... id? ...))
                  (syntax->list #'(fresh-id ... fresh-id? ...)))))

(define-splicing-syntax-class history-clause
  #:attributes (definitions [binding 1] static-info stxparam)
  (pattern (~seq)
           #:attr definitions #'(begin)
           #:attr [binding 1] (list)
           #:attr static-info #'(list)
           #:attr stxparam #'(make-variable-like-transformer #'(list)))
  (pattern (~seq #:history id:id)
           #:with fresh-id (generate-temporary #'id)
           #:attr definitions #'(define fresh-id (call-history))
           #:attr [binding 1] (list #'[id fresh-id])
           #:attr static-info #'(list (binding-static-info #'id #'fresh-id))
           #:attr stxparam #'(make-variable-like-transformer #'(list fresh-id))))

(define-splicing-syntax-class define/mock-options
  #:attributes
  (definitions override-bindings opaques-info history-info mocks-info
    param-mocks-info)
  (pattern (~seq opaque:opaque-clause history:history-clause mocks:mocks-clause)
           #:attr definitions
           #'(begin opaque.definitions
                    history.definitions
                    (splicing-syntax-parameterize ([histories history.stxparam])
                      (splicing-let (opaque.binding ... history.binding ...)
                        mocks.definitions)))
           #:attr override-bindings #'mocks.bindings
           #:attr opaques-info #'opaque.static-info
           #:attr history-info #'history.static-info
           #:attr mocks-info #'mocks.static-info
           #:attr param-mocks-info #'mocks.param-static-info))

(define-splicing-syntax-class definition-header/mock
  #:attributes
  (header/plain header/mock definitions override-bindings static-definition)
  (pattern (~seq header:definition-header options:define/mock-options)
           #:attr header/plain #'header.fresh
           #:attr header/mock #'header.fresh-secondary
           #:attr definitions #'options.definitions
           #:attr override-bindings #'options.override-bindings
           #:attr static-definition
           #'(define-syntax header.id
               (static-val-transformer
                #'header.fresh-id
                (mocks-syntax-info #'header.fresh-id-secondary
                                   options.opaques-info
                                   options.history-info
                                   options.mocks-info
                                   options.param-mocks-info)))))

(struct binding-static-info (id bound-id) #:transparent)
(struct mocks-syntax-info (proc-id opaques histories mocks param-mocks) #:transparent)

(define (mock-bindings mock-static-infos)
  (map (match-lambda [(binding-static-info mock-id mock-impl-id)
                      (list (syntax-local-introduce mock-id) mock-impl-id)])
       mock-static-infos))

(define-syntax-class id/mock
  #:description "define/mock identifier"
  #:attributes ([binding 1] [parameterization 1] reset-expr)
  (pattern id:id
           #:do [(define static (static-val #'id))]
           #:fail-unless (mocks-syntax-info? static)
           (format "identifier ~a not bound with define/mock" (syntax-e #'id))
           #:do
           [(match-define
              (mocks-syntax-info proc-id opaques histories mocks param-mocks)
              static)]
           #:with proc-id proc-id
           #:with ([mock-id mock-impl-id] ...) (mock-bindings mocks)
           #:with ([param-mock-id param-mock-impl-id] ...)
           (mock-bindings param-mocks)
           #:with (opaque-binding ...) (mock-bindings opaques)
           #:with ([history-id history-impl-id] ...) (mock-bindings histories)
           #:attr reset-expr
           #'(begin (mock-reset-all! mock-impl-id ...)
                    (mock-reset-all! param-mock-impl-id ...)
                    (call-history-reset-all! history-impl-id ...))
           #:attr [binding 1]
           (syntax->list
            #'([id proc-id]
               opaque-binding ...
               [history-id history-impl-id] ...
               [mock-id mock-impl-id] ...))
           #:attr [parameterization 1]
           (syntax->list #'([param-mock-id param-mock-impl-id] ...))))
