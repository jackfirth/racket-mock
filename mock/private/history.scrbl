#lang scribble/manual
@(require "util-doc.rkt")

@title{Mock Call Histories}

@defproc[(call-history) call-history?]{
 Constructs a fresh mock call history value. Every @mock-tech{mock} has an
 associated call history, although external call histories can be shared between
 mocks. Call histories store a log of @racket[mock-call] values in the order the
 calls were made.}

@defproc[(call-history? [v any/c]) boolean?]{
 Returns true when @racket[v] is a @racket[call-history] value, and false
 otherwise.}

@defproc[(call-history-record! [history call-history?] [call mock-call?])
         void?]{
 Saves @racket[call] in @racket[history] as the most recent mock call.}

@defproc[(call-history-calls [history call-history?]) (listof mock-call?)]{
 Returns a list of all calls recorded in @racket[history] with
 @racket[call-history-record!]. The list contains calls in order of least recent
 to most recent.
 @(mock-examples
   (define history (call-history))
   (call-history-record! history
                         (mock-call #:name 'foo
                                    #:args (arguments 1 2 3)
                                    #:results (list 'foo)))
   (call-history-record! history
                         (mock-call #:name 'bar
                                    #:args (arguments 10 20 30)
                                    #:results (list 'bar)))
   (call-history-calls history))}

@defproc[(call-history-count [history call-history?]) (listof mock-call?)]{
 Returns the number of calls recorded in @racket[history].
 @(mock-examples
   (define history (call-history))
   (call-history-count history)
   (call-history-record! history (mock-call))
   (call-history-count history))}

@defproc[(call-history-reset! [history call-history?]) void?]{
 Erases all calls from @racket[history], in a similar manner to
 @racket[mock-reset!].
 @(mock-examples
   (define history (call-history))
   (call-history-record! history (mock-call))
   (call-history-reset! history)
   (call-history-calls history))}
