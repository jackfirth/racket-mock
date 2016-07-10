#lang scribble/manual

@(require "private/util/doc.rkt")

@title{Mocks}
@defmodule[mock]
@author[@author+email["Jack Firth" "jackhfirth@gmail.com"]]

This library includes functions and forms for working with
@deftech[#:key "mock"]{mocks}. A mock is a "fake" function
used in place of the real thing during testing to simplify
the test and ensure only a single unit and not it's complex
dependencies is being tested. Mocks are most useful for
testing code that calls side-effectful operations and IO.

source code: @url["https://github.com/jackfirth/racket-mock"]

@include-section["private/base.scrbl"]
@include-section["private/check.scrbl"]
@include-section["private/syntax.scrbl"]
