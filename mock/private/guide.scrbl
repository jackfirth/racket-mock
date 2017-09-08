#lang scribble/manual
@(require "util-doc.rkt")

@title[#:tag "mock-guide"]{The Mock Guide}

This guide is intended for programmers who are familiar with Racket but new to working
with @mock-tech{mocks}. It contains a description of the high level concepts associated
with the @racketmodname[mock] library, as well as examples and use cases. For a complete
description of the @racketmodname[mock] API, see @secref{mock-reference}.

@table-of-contents[]

@section{Introduction to Mocks}
@define-persistent-mock-examples[mock-intro-examples]

The @racketmodname[mock] library defines @mock-tech{mocks}, procedures that record how
they're used and can have their response to calls dynamically altered. Mocks are most
useful when testing imperative code or code with side effects, serving as "fake"
implementations in tests for verifying real implementations are used correctly. For
example, consider the following procedure:

@mock-intro-examples[
 (define (call/secret proc)
   (proc "secret")
   (void))
 (call/secret print)
 (call/secret values)]

How can a test verify that the secret value is passed correctly? It would be one thing
if @racket[call/secret] returned the result of the call, then we could simply pass in
@racket[values] and verify that the whole thing returns @racket["secret"]. But because
the result of the call is discarded, we somehow need to use a procedure that records a
history of all calls made with it so we can check that history afterwards. This is
precisely what mocks are for.

@mock-intro-examples[
 (define secret-mock (mock #:behavior void))
 (call/secret secret-mock)
 (mock-calls secret-mock)]

Mocks are constructed by the @racket[mock] function. They're procedures that behave
exactly like whatever their current @behavior-tech{behavior} is, but they also keep a
record of all calls made with them. In the previous example, we construct the mock
@racket[secret-mock] that behaves like the @racket[void] procedure. If the behavior is
unspecified the mock will throw an error whenver its called, so we choose @racket[void]
as its behavior since @racket[call/secret] doesn't need a return value from the procedure
it's given. After evaluating @racket[(call/secret secret-mock)], the @racket[secret-mock]
has a procedure call in its saved history that is accessible via @racket[mock-calls]. Now
we can query this history in tests. We can also clear a mock's history of calls using
@racket[mock-reset!], allowing us to clean up after a test.

@mock-intro-examples[
 (mock-num-calls secret-mock)
 (mock-reset! secret-mock)
 (mock-num-calls secret-mock)]

@section{Using Mocks in Place of Dependencies}
@define-persistent-mock-examples[mock-deps-examples]

In the previous section we used mocks to test a higher order function @racket[call/secret].
Mocks also help when dealing with code that performs operations with side effects. In
tests, we simply replace the operation procedure with a mock. To do this, we can take a
procedure that calls side effectful dependencies and convert it to a higher order procedure
like @racket[call/secret], which accepts the side effectful dependencies as inputs. Consider
a procedure that looks up a favorite color from a file, then prints a message based on that
color.

@mock-deps-examples[
 (define (print-favorite-color-message)
   (define color (file->string "color-preference.txt"))
   (define message
     (case color
       [("blue") "Your favorite color is blue. Like the ocean!"]
       [("red") "Your favorite color is red. Fiery, fiery red!"]
       [("green") "Your favorite color is green. I love forests!"]
       [else "I haven't got much to say about your favorite color."]))
   (displayln message))]

Testing this procedure is definitely tricky. There's input from the
@racket["color-preferences.txt"] file to worry about along with output via
@racket[displayln]. To properly test this procedure, let's alter it slightly.
We'll pass in the side effectful dependency procedures as arguments.

@mock-deps-examples[
 (define (print-favorite-color-message #:read-with [file->string file->string]
                                       #:print-with [displayln displayln])
   (define color (file->string "color-preference.txt"))
   (define message
     (case color
       [("blue") "Your favorite color is blue. Like the ocean!"]
       [("red") "Your favorite color is red. Fiery, fiery red!"]
       [("green") "Your favorite color is green. I love forests!"]
       [else "I haven't got much to say about your favorite color."]))
   (displayln message))]

Much better. By passing in the procedures we use for reading and writing as
arguments, we allow tests to specify that input and output should be performed
with mocks. Using the real functions by default also means we don't affect any
existing code using @racket[print-favorite-color-message]. Now let's try using
mocks.

@mock-deps-examples[
 (define file-mock (mock #:behavior (const "green")))
 (define displayln-mock (mock #:behavior void))
 (print-favorite-color-message #:read-with file-mock
                               #:print-with displayln-mock)
 (mock-calls file-mock)
 (mock-calls displayln-mock)]

By using @racket[const] we're able to easily setup tests that exercise a
particular codepath. We can test side effectful code! There's still more to
discuss, the following sections discuss adjusting mock behavior and automatically
mocking out dependencies.

@section{Dynamically Changing Mock Behavior}
@define-persistent-mock-examples[mock-behavior-examples]

Mocks have a @italic{behavior}, which defines what they return when called. This
behavior is not fixed; mocks can have their behavior changed dynamically using
@racket[with-mock-behavior]. This allows the same mock to respond differently to
different calls while retaining a history of all calls. Recall the favorite color
procedure we defined in the previous section:

@mock-behavior-examples[
 (define (print-favorite-color-message #:read-with [file->string file->string]
                                       #:print-with [displayln displayln])
   (define color (file->string "color-preference.txt"))
   (define message
     (case color
       [("blue") "Your favorite color is blue. Like the ocean!"]
       [("red") "Your favorite color is red. Fiery, fiery red!"]
       [("green") "Your favorite color is green. I love forests!"]
       [else "I haven't got much to say about your favorite color."]))
   (displayln message))]

If we want to test more than one branch of this code, we need our @racket[file->string]
mock to return different results. We could use different mocks, but then each mock has
a separate call history. In this particular case that's not a problem, but for the sake
of a good example we'll assume we want a combined history. We can use
@racket[with-mock-behavior] to dynmaically control the behavior of a mock.

@mock-behavior-examples[
 (define file-mock (mock #:behavior (const "green")))
 (define displayln-mock (mock #:behavior void))
 (print-favorite-color-message #:read-with file-mock
                               #:print-with displayln-mock)
 (with-mock-behavior ([file-mock (const "blue")])
   (print-favorite-color-message #:read-with file-mock
                                 #:print-with displayln-mock))
 (mock-calls displayln-mock)]

A mocks behavior is a @tech[#:doc '(lib "scribblings/guide/guide.scrbl")]{parameter} under the hood, so @racket[with-mock-behavior]
acts similarly to @racket[parameterize]. While here we could have made a second mock,
in the next section we'll introduce automatic mocking which defines one mock per
dependency for us.

@section{Automatic Mocking with Syntax}
@define-persistent-mock-examples[mock-syntax-examples]

In the previous sections we transformed procedures we wanted to test into higher order
functions that accepted their dependencies as input. This let us construct a mock for
each dependency and pass it in to inspect how the procedure called its dependencies.
This was a fairly mechanical translation. In this section we introduce @racket[define/mock],
a syntactic form that automates mocking out dependencies in this fashion. Recall again our
favorite color procedure.

@mock-examples[
 (define (print-favorite-color-message)
   (define color (file->string "color-preference.txt"))
   (define message
     (case color
       [("blue") "Your favorite color is blue. Like the ocean!"]
       [("red") "Your favorite color is red. Fiery, fiery red!"]
       [("green") "Your favorite color is green. I love forests!"]
       [else "I haven't got much to say about your favorite color."]))
   (displayln message))]

We previously mocked out the @racket[file->string] and @racket[displayln] procedures.
This was done in three steps:

@itemlist[
 @item{Add a parameter for each dependency procedure that defaults to the real one.}
 @item{Define a mock for each dependency procedure with appropriate behavior}
 @item{Call @racket[print-favorite-color-message] with the mocks as its dependencies,
  adjusting mock behavior and resetting mocks as necessary.}]

The @racket[define/mock] form automates the first two steps of this process.

@mock-syntax-examples[
 (define/mock (print-favorite-color-message)
   #:mock file->string #:as file-mock #:with-behavior (const "blue")
   #:mock displayln #:as display-mock #:with-behavior void
   (define color (file->string "color-preference.txt"))
   (define message
     (case color
       [("blue") "Your favorite color is blue. Like the ocean!"]
       [("red") "Your favorite color is red. Fiery, fiery red!"]
       [("green") "Your favorite color is green. I love forests!"]
       [else "I haven't got much to say about your favorite color."]))
   (displayln message))]

The details of how this works are covered in @secref{mock-reference}, but the gist is
that each @racket[#:mock] clause mocks out a single dependency procedure and defines a
mock with the name given in the @racket[#:as] clause. The @racket[#:with-behavior] clause
defines the default behavior for each mock. However, the mocks are not immediately
available to client code - their definitions must be brought into scope using a
@racket[with-mocks] form.

@mock-syntax-examples[
 (eval:error file-mock)
 (eval:error (print-favorite-color-message))
 (with-mocks print-favorite-color-message
   (print-favorite-color-message)
   (println (mock-calls display-mock)))]

The @racket[with-mocks] form also takes care of calling @racket[mock-reset!] on every
mock associated with @racket[print-favorite-color-message].

@mock-syntax-examples[
 (with-mocks print-favorite-color-message
   (print-favorite-color-message)
   (println (mock-num-calls display-mock)))
 (with-mocks print-favorite-color-message
   (println (mock-num-calls display-mock)))]

This makes setting up mocked dependencies much simpler. The @racket[define/mock] form
has a few other options to control its behavior, see @secref{mock-reference} for details.

@define-persistent-mock-examples[mock-stub-examples/manual]
@define-persistent-mock-examples[mock-stub-examples]
@section{Stubbing Undefined Dependencies}

When testing with mocks, we're able to test how a procedure calls its dependencies
without actually using real dependencies. In theory then, there's no reason those
dependencies need to be implemented before we write our test. Consider a procedure in a
web application that checks whether the current user is authenticated. What are its
dependencies? Clearly there must be some sort of @racket[user] datatype and a
@racket[user-admin?] predicate. There must also be a way to determine the user associated
with the current request, call that @racket[current-user]. And if the user isn't an admin,
there must be some sort of @racket[raise-non-admin-access-error] procedure to throw an
exception indicating the lack of access. We can try and define a
@racket[check-current-user-admin] procedure in terms of these pieces before defining the
pieces, but our code won't compile.

@mock-examples[
 (define (check-current-user-admin)
   (define user (current-user))
   (unless (user-admin? user)
     (raise-non-admin-access-error user)))]

If we're testing @racket[check-current-user-admin] with mocks, since all those dependencies
will be mocked out anyway we could just define fake implementations for them.

@mock-stub-examples/manual[
 (define current-user #f)
 (define user-admin? #f)
 (define raise-non-admin-access-error #f)
 (define/mock (check-current-user-admin)
   #:mock current-user #:with-behavior (const "user")
   #:mock user-admin? #:with-behavior (const #t)
   #:mock raise-non-admin-access-error
   (define user (current-user))
   (unless (user-admin? user)
     (raise-non-admin-access-error user)))]

Now we can test @racket[check-current-user-admin] without properly defining real dependencies.

@mock-stub-examples/manual[
 (with-mocks check-current-user-admin
   (check-current-user-admin)
   (mock-calls raise-non-admin-access-error)
   (with-mock-behavior ([user-admin? (const #f)]
                        [raise-non-admin-access-error void])
     (check-current-user-admin)
     (println (mock-calls raise-non-admin-access-error))))]

Nice as this approach could be, it's still rather tedious to define each of those fake
dependencies. And if they're @emph{actually} called, the error message is a terrible one
about the evils of treating @racket[#f] as a procedure. The @racketmodname[mock] library
provides a @racket[stub] form for automatically defining these sorts of fake implementations.

@mock-stub-examples[
 (stub current-user user-admin? raise-non-admin-access-error)
 (define/mock (check-current-user-admin)
   #:mock current-user #:with-behavior (const "user")
   #:mock user-admin? #:with-behavior (const #f)
   #:mock raise-non-admin-access-error
   (define user (current-user))
   (unless (user-admin? user)
     (raise-non-admin-access-error user)))]

We can now better control the order in which we implement procedures, writing tests as we
go and even writing code in a test-first fashion.

@section{Mocking and Opaque Values}

Libraries often define "special" values that can't be inspected and are only obtainable
through the library, such as database connections or other "opaque" values. When mocking
dependency functions from that library, we often end up in a situation where a mocked
dependency produces one of these values and another mock consumes it. In this case, it
doesn't matter at all what the producer returns.

@mock-examples[
 (stub db-connect! db-list-ids)
 (define/mock (list-db-user-ids)
   #:mock db-connect! #:with-behavior (const "some random value")
   #:mock db-list-ids #:with-behavior (const '(1 2 3))
   (db-list-ids (db-connect!) 'users))
 (with-mocks list-db-user-ids
   (println (list-db-user-ids))
   (println (mock-calls db-list-ids)))]

We could have returned any value at all from the @racket[db-connect!] procedure, for unit
testing purposes all we care about is that whatever @racket[db-connect!] returns is passed
in properly to @racket[db-list-ids]. However, this could lead to problems if we accidentally
passed the "connection" value somewhere else. If given to a procedure that prints out a string,
instead of throwing an error we'll get "some random value" printed out unexpectedly. What we'd
really like is to create some value that can @emph{only} be used as a mock connection. The
@racket[define-opaque] form lets us define opaque values, which are completely black-boxed
values with no meaning that any procedure could extract from them.

@mock-examples[
 (stub db-connect! db-list-ids)
 (define-opaque test-connection)
 (define/mock (list-db-user-ids)
   #:mock db-connect! #:with-behavior (const test-connection)
   #:mock db-list-ids #:with-behavior (const '(1 2 3))
   (db-list-ids (db-connect!) 'users))
 (with-mocks list-db-user-ids
   (println (list-db-user-ids))
   (println (mock-calls db-list-ids)))
 (eval:error (add1 test-connection))
 (test-connection? test-connection)]

In this example, we've defined an opaque @racket[test-connection] value that our tests can
look for. It's impossible to misuse this value, and it helpfully identifies itself in error
messages when passed around unexpectedly. The @racket[define-opaque] form defines both an
opaque value and a predicate that can be used to recognize that value. In tests, we can
look for the opaque value in mock call history with the predicate or @racket[equal?].

In addition to @racket[define-opaque], the @racket[define/mock] form provides a handy syntax
for defining an opaque value that only that definition's mocks and @racket[with-mocks]
enclosed code can reference. Simply add the identifier in an @racket[#:opaque] clause.

@mock-examples[
 (stub db-connect! db-list-ids)
 (define/mock (list-db-user-ids)
   #:opaque test-connection
   #:mock db-connect! #:with-behavior (const test-connection)
   #:mock db-list-ids #:with-behavior (const '(1 2 3))
   (db-list-ids (db-connect!) 'users))
 (with-mocks list-db-user-ids
   (println (list-db-user-ids))
   (println (mock-calls db-list-ids)))
 (eval:error test-connection)]

The @racket[#:opaque] clause can define multiple opaque values at once by surrounding them
in parentheses. See @racket[define/mock]'s documentation in @secref{mock-reference} for
details.
