#lang racket/base

(provide definition-header
         predicate-id
         static-val
         static-val-transformer)

(require racket/function
         racket/syntax
         syntax/parse)


(define (predicate-id id-stx)
  (format-id id-stx "~a?" id-stx))

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

(struct static-val-transformer (id value)
  #:property prop:rename-transformer (struct-field-index id))

(define (static-val static-trans-stx)
  (define-values (trans _)
    (syntax-local-value/immediate static-trans-stx (thunk (values #f #f))))
  (and trans (static-val-transformer-value trans)))
