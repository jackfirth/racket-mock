#lang scribble/manual

@title{Basic Mock Construction}

@defproc[(mock? [v any/c]) boolean?]{
  Predicate identifying mocks
}

@defproc[(make-mock [proc procedure?]) mock?]{
  Returns a mocked version of @racket[proc]. The
  mock may be used in place of @racket[proc] anywhere
  and behaves just like a regular procedure. When used
  as a procedure, the returned @racket[mock?] forwards
  the arguments it's given to @racket[proc] and records
  the argument list and the result @racket[proc] returned
  in hidden mutable storage. This allows tests to verify
  that a mock was called with the right arguments.
}

@defstruct*[mock-call ([args list?] [result any/c])
            #:prefab]{
  A prefab structure containg the arguments and result
  of a single call to a @racket[mock?].
}

@defproc[(mock-calls [mock mock?]) (listof mock-call?)]{
  Returns a list of all the @racket[mock-call]s made
  so far with @racket[mock].
}
