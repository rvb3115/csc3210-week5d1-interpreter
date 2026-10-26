#lang racket
; Starter: https://github.com/freindst/CSC3210_language_theory_fall_2026/tree/main/week5d1
(require "util.rkt")

; Search current scope through root scope. Check the binding itself so
; values such as #f and (void) are not mistaken for missing variables.
(define (lookup-variable var_name var_env)
  (cond
    [(null? var_env) (error "error: variable not found")]
    [else
     (define binding (assq var_name (car var_env)))
     (if binding
         (cadr binding)
         (lookup-variable var_name (cdr var_env)))]))

; Accept the intermediate form returned by parse.
; By default use util.rkt's environment; an optional environment makes
; nested-scope examples possible without changing the global environment.
(define (execute parsed_exp [var_env environment])
  (match parsed_exp
    [(list 'var-exp (? symbol? var_name))
     (lookup-variable var_name var_env)]
    [_ (error "error: unsupported expression")]))

(provide (all-defined-out))
