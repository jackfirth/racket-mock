#lang info
(define collection 'multi)
(define version "0.2")
(define deps
  '(("base" '#:version "6.3")
    "fancy-app"
    "rackunit-lib"
    "reprovide-lang"
    "scribble-lib"
    "sweet-exp"
    "unstable-lib"))
(define build-deps
  '("cover"
    "rackunit-lib"
    "rackunit-doc"
    "racket-doc"
    "doc-coverage"))
(define test-omit-paths
  '("mock/main.scrbl"
    "mock/private/base.scrbl"
    "mock/private/check.scrbl"
    "mock/private/predefined.scrbl"
    "mock/private/syntax.scrbl"))
