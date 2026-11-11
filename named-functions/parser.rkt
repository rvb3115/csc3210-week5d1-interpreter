#lang racket
(require "util.rkt")
;parser will translate my programming language into an intemediate form
;it will be reletively easier to execute

(define (statement-list? body)
  (and (list? body) (andmap list? body)))

(define parse
  (lambda
      (exp)
    (cond
      ((symbol? exp) (list 'var-exp exp))
      ((number? exp) (list 'num-exp exp))
      ((or (equal? exp "True") (equal? exp "False"))
       (list 'boolean-exp exp (void) (void)))
      ((string? exp) (list 'string-exp exp))
      ((null? exp) (displayln "ERROR: empty statement"))
      ;; Keywords are checked before infix math and comparisons.
      ((and (pair? exp) (eq? (car exp) 'main))
       (if (and (list? exp) (= (length exp) 2)
                (statement-list? (cadr exp)))
           (cons 'list-exp (map parse (cadr exp)))
           (displayln "PARSER ERROR: main must hold a list of statements.")))
      ((and (pair? exp) (eq? (car exp) 'func))
       (if (and (list? exp) (= (length exp) 4)
                (symbol? (cadr exp)) (list? (caddr exp))
                (andmap symbol? (caddr exp))
                (statement-list? (cadddr exp)))
           (list 'func-def-exp (parse (cadr exp))
                 (map parse (caddr exp))
                 (cons 'list-exp (map parse (cadddr exp))))
           (displayln "PARSER ERROR: invalid function definition.")))
      ((and (pair? exp) (eq? (car exp) 'call))
       (if (and (list? exp) (= (length exp) 3)
                (symbol? (cadr exp)) (list? (caddr exp)))
           (list 'call-exp (parse (cadr exp)) (map parse (caddr exp)))
           (displayln "PARSER ERROR: invalid function call.")))
      ((and (pair? exp) (eq? (car exp) 'return))
       (if (and (list? exp) (= (length exp) 2))
           (list 'return-exp (parse (cadr exp)))
           (displayln "PARSER ERROR: invalid return.")))
      ((not (list? exp)) (displayln "PARSER ERROR: invalid statement."))

      ((and (equal? (length exp) 3) (equal? (cadr exp) '=))
        (list 'assign-exp 
          (list
            (list 'var-exp (car exp))
            (parse (caddr exp))
          )
        )
      )
      ;a math is a triple element list, and the second element is a valid operator
      ;1 + a
      ((and (= (length exp) 3) (is_valid_math_op (cadr exp)))
        (list
          'math-exp
          (cadr exp)
          (parse (car exp))
          (parse (caddr exp))
        ))  ;math-exp has no error message here
      ;boolean expression: True/False; A OP B; !A
      ;we unify everything into the same interface, OP, A, B
      ;when it is only true or false, OP will be TRUE OR FALSE
      ;when it is three elements, OP will be the operator, A and B will be the value
      ;when it is two elements, OP will be NOT, A will be the value, and B will be empty
      ((or (equal? exp "True") (equal? exp "False"))
        (list 'boolean-exp exp (void) (void)))
      ((and (eq? (length exp) 3) (is_valid_boolean_op (cadr exp)))
       (list 'boolean-exp (cadr exp) (parse (car exp)) (parse (caddr exp))))
      ((and (eq? (length exp) 2) (eq? '! (car exp)))
       (list 'boolean-exp (car exp) (parse (cadr exp)) (void)))
      ;function expression
      ((equal? 'function (car exp))
        (if (and (equal? (length (cadr exp)) (length (cadddr exp))) (not (null? (caddr exp))))
          (list
            'func-exp
            (create_pair_list '() (map parse (cadr exp)) (map parse (cadddr exp)))
            (cons 'bulk-exp (map parse (caddr exp)))
          )
          (displayln "PARSER ERROR: this is not a valid anonymous function definition."))
      )
      ;ask (boolean) true false
      (
        (equal? 'ask (car exp))
        (list
          'ask-exp
          (parse (cadr exp))
          (cons 'list-exp (map parse (caddr exp)))
          (cons 'list-exp (map parse (cadddr exp)))
        )
      )
      ;while (boolean S) (S1, S2, S3, ...)
      ((equal? 'while (car exp))
        (list
          'while-exp
          (parse (cadr exp))
          (cons
            'list-exp
            (map parse (caddr exp))
          )
        )
      )
      ;(do-while (S1, S2, S3, ...) (boolean S))
      ((equal? 'do-while (car exp))
        (list
          'do-while-exp
          (cons
            'list-exp
            (map parse (cadr exp))
          )
          (parse (caddr exp))
        )
      )
      ;(for (list-exp S0_1, S0_2, ...) (boolean S) (list-exp S1_1, S1_2, ...) (list-exp S2_1, S2_2, ...))
      ((equal? 'for (car exp))
        (list
          'for-exp
          (cons
            'list-exp
            (map parse (cadr exp))
          )
          (parse (caddr exp))
          (cons
            'list-exp
            (map parse (cadddr exp))
          )
          (cons
            'list-exp
            (map parse (cadr (cdddr exp)))
          )
        )
      )
      ((equal? 'fire (car exp)) (list 'fire-exp (parse (cadr exp))))
      (else (displayln "PARSER ERROR: the statement has not been supported yet."))
    )
  )
)

(provide (all-defined-out))
