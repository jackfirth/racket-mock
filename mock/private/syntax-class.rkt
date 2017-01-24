#lang sweet-exp racket/base

provide definition-header/mock
        id/mock
        stub-header
        stubs

require racket/function
        racket/match
        racket/syntax
        syntax/parse
        syntax/stx
        syntax/transformer
        "syntax-util.rkt"
        for-syntax racket/base
        for-template racket/base
                     racket/splicing
                     "base.rkt"
                     "history.rkt"
                     "not-implemented.rkt"
                     "opaque.rkt"
                     "syntax-param.rkt"


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
               #'(mock #:name 'id
                       #:external-histories histories
                       #:behavior given-behavior)
               #'(mock #:name 'id #:external-histories histories))
           #:attr definition #'(define fresh-id value)
           #:attr binding #'[mocked-id fresh-id]
           #:attr static-info #'(mock-static-info #'id #'fresh-id)))

(define-splicing-syntax-class mocks-clause
  (pattern (~seq clause:mock-clause ...)
           #:attr definitions #'(begin clause.definition ...)
           #:attr bindings #'(clause.binding ...)
           #:attr static-info #'(list clause.static-info ...)))

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
           #:attr static-info #'(list (mock-static-info #'id #'fresh-id)
                                      (mock-static-info #'id? #'fresh-id?)))
  (pattern (~seq #:opaque (id:id ...))
           #:with (id? ...) (stx-map predicate-id #'(id ...))
           #:with (fresh-id ...) (generate-temporaries #'(id ...))
           #:with (fresh-id? ...) (stx-map predicate-id #'(fresh-id ...))
           #:attr definitions #'(begin (define-opaque fresh-id #:name id) ...)
           #:attr [binding 1]
           (syntax->list #'([id fresh-id] ... [id? fresh-id?] ...))
           #:attr static-info
           #'(map mock-static-info
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
           #:attr static-info #'(list (mock-static-info #'id #'fresh-id))
           #:attr stxparam #'(make-variable-like-transformer #'(list fresh-id))))

(define-splicing-syntax-class define/mock-options
  #:attributes
  (definitions override-bindings opaques-info history-info mocks-info)
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
           #:attr mocks-info #'mocks.static-info))

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
                                   options.mocks-info)))))

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
(struct mocks-syntax-info (proc-id opaques histories mocks) #:transparent)

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
           #:do
           [(match-define (mocks-syntax-info proc-id opaques histories mocks)
              static)]
           #:with proc-id proc-id
           #:with ([mock-id mock-impl-id] ...) (mock-bindings mocks)
           #:with (opaque-binding ...) (mock-bindings opaques)
           #:with ([history-id history-impl-id] ...) (mock-bindings histories)
           #:attr reset-expr
           #'(begin (mock-reset-all! mock-id ...)
                    (call-history-reset-all! history-id ...))
           #:attr [binding 1]
           (syntax->list
            #'([id proc-id]
               opaque-binding ...
               [history-id history-impl-id] ...
               [mock-id mock-impl-id] ...))))
