#lang racket
(require "util.rkt")
;parser will translate my programming language into an intemediate form
;it will be reletively easier to execute

(define parse
  (lambda
      (exp)
    (cond
      ((symbol? exp) (list 'var-exp exp))
      ((number? exp) (list 'num-exp exp))
      ((string? exp) (list 'string-exp exp))
      ((null? exp) (displayln "ERROR: empty statement"))
      ((equal? (car exp) 'main)
        (cons 'list-exp (map parse (cdr exp)))
      )
      ;; Assignment has exactly the AST required by the homework.
      ((and (= (length exp) 3) (eq? (cadr exp) '=))
       (unless (symbol? (car exp))
         (error 'parse "assignment target must be a variable"))
       (list 'assign-exp (parse (car exp)) (parse (caddr exp))))
      ;a math is a triple element list, and the second element is a valid operator
      ;1 + a
      ((and (is_valid_math_op (cadr exp)) (equal? (length exp) 3))
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
            (cons 'list-exp (map parse (caddr exp)))
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
      ;; (for ((a = 0) (a < 10) (a = (a + 1))) ((b = (b + 1))))
      ;; Keep the previous class form with init/step statement lists too.
      ((eq? 'for (car exp))
       (match exp
         [(list 'for (list init condition step) body)
          (list 'for-exp (parse init) (parse condition) (parse step)
                (cons 'list-exp (map parse body)))]
         [(list 'for init condition step body)
          (list 'for-exp (cons 'list-exp (map parse init))
                (parse condition) (cons 'list-exp (map parse step))
                (cons 'list-exp (map parse body)))]
         [_ (error 'parse "for needs initialization, condition, step and body")]))
      ((equal? 'fire (car exp)) (list 'fire-exp (parse (cadr exp))))
  ;(func add (a b) (
  ;  (c = a + b)
  ;  (return c)
  ;)) 
      ((equal? 'func (car exp))
       (list 'assign-exp (parse (cadr exp))
             (list 'new-func-exp (map parse (caddr exp))
                   (cons 'list-exp (map parse (cadddr exp))))))
      ((equal? 'return (car exp))
        (list
          'return-exp
          (parse (cadr exp))
        )
      )
      ((equal? 'call (car exp))
        (list
          'call-exp
          (parse (cadr exp))
          (map parse (caddr exp))
        )
      )
      (else (displayln "PARSER ERROR: the statement has not been supported yet."))
    )
  )
)

(provide (all-defined-out))
