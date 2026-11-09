#lang racket
(provide (all-defined-out))

;; Original representation: environment = list of scopes (nearest first).
;; Each scope is a list of (symbol value) pairs. No hashes or boxes.
(define scope '((a 1) (b 2)))
(define environment (list scope))

(define (resolve scope name)
  (cond [(null? scope) (void)]
        [(eq? (caar scope) name) (cadar scope)]
        [else (resolve (cdr scope) name)]))

(define (lookup-variable name env)
  (cond [(null? env) (error 'lookup "variable not found: ~a" name)]
        [(assq name (car env)) => cadr]
        [else (lookup-variable name (cdr env))]))

(define (create-variable scope name value)
  (when (assq name scope)
    (error 'create-variable "variable already exists: ~a" name))
  (cons (list name value) scope))

(define (update-variable scope name value)
  (cond [(null? scope)
         (error 'update-variable "variable not found: ~a" name)]
        [(eq? (caar scope) name)
         (cons (list name value) (cdr scope))]
        [else (cons (car scope) (update-variable (cdr scope) name value))]))

;; Return a rebuilt environment, updating only the nearest binding.
(define (update-env env name value)
  (cond [(null? env) (error 'update-variable "variable not found: ~a" name)]
        [(assq name (car env))
         (cons (update-variable (car env) name value) (cdr env))]
        [else (cons (car env) (update-env (cdr env) name value))]))
