#lang sweet-exp racket/base

provide definition-header
        mocks-clause
        struct-out mock-static-info

require racket/syntax
        for-template racket/base
                     "opaque.rkt"
                     "base.rkt"

require syntax/parse

(struct mock-static-info (id bound-id) #:transparent)

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
