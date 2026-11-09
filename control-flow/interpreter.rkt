#lang racket
(require "util.rkt")
(provide execute execute-statement execute-block execute-scoped-block)

(define (execute exp [env environment])
  (match exp
    [(list 'num-exp n) n]
    [(list 'bool-exp b) b]
    [(list 'var-exp name) (lookup-variable name env)]
    [(list 'binary-exp op left right)
     (define x (execute left env))
     (define y (execute right env))
     (case op
       [(+) (+ x y)] [(-) (- x y)] [(*) (* x y)] [(/) (/ x y)]
       [(<) (< x y)] [(<=) (<= x y)] [(>) (> x y)] [(>=) (>= x y)]
       [(=) (equal? x y)] [(!=) (not (equal? x y))]
       [else (error 'execute "unsupported operator: ~s" op)])]
    [_ (error 'execute "unsupported expression: ~s" exp)]))

(define (condition-true? condition env)
  (define result (execute condition env))
  (unless (boolean? result)
    (error 'condition "expected a boolean, got ~v" result))
  result)

(define (execute-block statements env)
  (for/fold ([current env]) ([stmt statements])
    (execute-statement stmt current)))

;; Push a fresh scope, run the body, then pop it. Updates to parents survive.
(define (execute-scoped-block statements env)
  (cdr (execute-block statements (cons '() env))))

(define (execute-statement stmt env)
  (match stmt
    [(list 'declare-stmt name value)
     (cons (create-variable (car env) name (execute value env)) (cdr env))]
    [(list 'assign-stmt name value)
     (update-env env name (execute value env))]
    [(list 'print-stmt value)
     (printf "  value = ~v\n" (execute value env))
     env]
    [(list 'if-stmt condition yes no)
     ;; Evaluate only the selected branch, after checking the condition.
     (execute-scoped-block
      (if (condition-true? condition env) yes no) env)]
    [(list 'while-stmt condition body)
     (define loop-env (cons '() env)) ; this loop's private scope
     (let loop ([current loop-env])
       (if (condition-true? condition current)
           (loop (execute-scoped-block body current))
           (cdr current)))] ; pop the loop scope
    [(list 'do-while-stmt body condition)
     (define loop-env (cons '() env))
     (let loop ([current loop-env])
       (define next (execute-scoped-block body current)) ; always first
       (if (condition-true? condition next)
           (loop next)
           (cdr next)))]
    [_ (error 'execute "unsupported statement: ~s" stmt)]))
