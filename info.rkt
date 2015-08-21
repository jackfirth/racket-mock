#lang info


(define collection 'multi)


(define version "0.1")


(define deps
  '("base"
    "fancy-app"
    "rackunit-lib"
    "scribble-lib"))


(define build-deps
  '("cover"
    "rackunit-lib"
    "rackunit-doc"
    "racket-doc"
    "doc-coverage"))
