#lang scribble/manual
@(require "util-doc.rkt")

@title{Opaque Values}
Often libraries work with values whose representations are unknown to clients,
values which can only be constructed via those libraries. For example, a database
library may define a database connection value and a @racket[database-connection?]
predicate, and only allow construction of connections via a @racket[database-connect!]
procedure. This is powerful for library creators but tricky for testers, as tests
likely don't want to spin up a database just to verify they've called the library
procedures correctly. The @racketmodname[mock] library provides utilities for
defining @define-opaque-tech{opaque values} that @mock-tech{mocks} can interact with.

@defform[(define-opaque clause ...)
         #:grammar ([clause (code:line id)])]{
 Defines an @opaque-tech{opaque} value and predicate for each @racket[id]. Each
 given @racket[id] is bound to the value, and each predicate is bound to an
 identifier matching the format of @racket[id?].
 @mock-examples[
 (define-opaque foo bar)
 foo
 foo?
 (foo? foo)
 (equal? foo foo)]

 If @racket[name-id] is provided,
 it is used for the reflective name of each opaque value and predicate. Otherwise,
 @racket[id] is used.
 @mock-examples[
 (define-opaque foo #:name FOO)
 foo
 foo?]

 Additionally, @racket[define/mock] provides syntax for defining opaque values.}
