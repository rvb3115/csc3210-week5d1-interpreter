#lang racket
(provide parse parse-statement parse-block)

;; Input is quoted Racket data with infix operators, as in the assignment.
(define (parse exp)
  (match exp
    [(? number?) `(num-exp ,exp)]
    [(? boolean?) `(bool-exp ,exp)]
    [(? symbol?) `(var-exp ,exp)]
    [(list left (and op (or '+ '- '* '/ '< '<= '> '>= '= '!=)) right)
     `(binary-exp ,op ,(parse left) ,(parse right))]
    [_ (error 'parse "unsupported expression: ~s" exp)]))

(define (parse-block body)
  (unless (list? body) (error 'parse "body must be a list of statements"))
  (map parse-statement body))

(define (parse-statement stmt)
  (match stmt
    [(list 'if condition yes no)
     `(if-stmt ,(parse condition) ,(parse-block yes) ,(parse-block no))]
    [(list 'if condition yes)
     `(if-stmt ,(parse condition) ,(parse-block yes) ())]
    [(list 'while condition body)
     `(while-stmt ,(parse condition) ,(parse-block body))]
    [(list 'do body 'while condition)
     `(do-while-stmt ,(parse-block body) ,(parse condition))]
    [(list 'var (? symbol? name) value)
     `(declare-stmt ,name ,(parse value))]
    [(list (? symbol? name) '= value)
     `(assign-stmt ,name ,(parse value))]
    ;; Assignment convention: (a + 1) as a statement updates a.
    ;; Inside an expression, (a + 1) only computes a value.
    [(list (? symbol? name) (and op (or '+ '- '* '/)) value)
     `(assign-stmt ,name ,(parse (list name op value)))]
    [(list 'print value) `(print-stmt ,(parse value))]
    [_ (error 'parse "unsupported statement: ~s" stmt)]))
