#lang sweet-exp racket/base

provide definition-header
        replace-header-id

require syntax/parse


(define-syntax-class definition-header
  (pattern (~or root-id:id
                (~or (subheader:definition-header (~or arg-clause kwarg-clause) ...)
                     (subheader:definition-header (~or arg-clause kwarg-clause) ... . rest-arg:id)))
           #:attr id
           (or (attribute root-id) (attribute subheader.id))))
(define (replace-header-id header-stx new-id-stx)
  (syntax-parse header-stx
    [root-id:id new-id-stx]
    [(header arg ...) #`(#,(replace-header-id #'header new-id-stx) arg ...)]))
