#lang scribble/manual

@title{Test Mocks}

@defmodule[mock]

This library includes functions and forms for working with
@deftech[#:key "mock"]{mocks}. A mock is a "fake" function
used in place of the real thing during testing to simplify
the test and ensure only a single unit and not it's complex
dependencies is being tested. Mocks are most useful for
testing side-effectful and IO-heavy operations.

@author[@author+email["Jack Firth" "jackhfirth@gmail.com"]]

source code: @url["https://github.com/jackfirth/racket-mock"]

@include-section["private/base.scrbl"]
