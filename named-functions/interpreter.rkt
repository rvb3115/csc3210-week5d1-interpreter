#lang racket
(require "util.rkt")
(provide (all-defined-out))

(define (return-val? value)
  (and (list? value) (= (length value) 2) (eq? (car value) 'return-val)))

;; Statements run in order. A tagged return skips every remaining statement.
(define (process-statements statements)
  (cond [(null? statements) (void)]
        [else
         (define result (process (car statements)))
         (if (return-val? result) result
             (process-statements (cdr statements)))]))

;; Always pop the current scope, not a saved environment. Outer updates survive.
(define (in-scope bindings thunk)
  (dynamic-wind
   (lambda () (push_scope_to_environment bindings))
   thunk
   pop_scope_from_environment))

(define (call-function name arguments)
  (define function (resolve_env environment name))
  (cond
    [(not (and (list? function) (= (length function) 3)
               (eq? (car function) 'func-val)))
     (displayln "INTERPRETER ERROR: not a function.")]
    [else
     ;; All arguments are evaluated before arity checking and before the push.
     (define values (map process arguments))
     (define parameters (cadr function))
     (if (not (= (length parameters) (length values)))
         (displayln "INTERPRETER ERROR: wrong number of arguments.")
         (let ([result (in-scope (map list parameters values)
                                (lambda () (process (caddr function))))])
           (if (return-val? result) (cadr result) (void))))]))

(define (process parsed-exp)
  (match parsed-exp
    [(? void?) (void)] ; parser already printed its error
    ['() (displayln "ERROR: EMPTY PROGRAM.")]
    [(list 'var-exp name) (resolve_env environment name)]
    [(list 'num-exp number) number]
    [(list 'string-exp text) text]
    [(list 'assign-exp (list (list 'var-exp name) expression))
     (define value (process expression)) ; evaluate once before reading environment
     (wolf_env environment name value)]
    [(list 'math-exp operator left right)
     (let ([x (process left)] [y (process right)])
       (if (and (number? x) (number? y))
           (do_math operator x y)
           (displayln "INTERPRETER ERROR: non-numeric cannot apply math.")))]
    [(list 'boolean-exp operator left right)
     (cond [(void? left) (or (eq? operator 'True) (equal? operator "True"))]
           [(void? right) (not (process left))]
           [else (calculate_boolean operator (process left) (process right))])]
    [(list 'func-def-exp (list 'var-exp name) parameters body)
     ;; Defining stores a value; it never executes the body.
     (wolf_env environment name (list 'func-val (map cadr parameters) body))]
    [(list 'call-exp (list 'var-exp name) arguments)
     (call-function name arguments)]
    [(list 'return-exp expression) (list 'return-val (process expression))]
    [(cons 'list-exp statements) (process-statements statements)]
    [(list 'ask-exp condition yes no)
     (process (if (process condition) yes no))]
    [(list 'while-exp condition body)
     (let loop ()
       (if (process condition)
           (let ([result (in-scope '() (lambda () (process body)))])
             (if (return-val? result) result (loop)))
           (void)))]
    [(list 'do-while-exp body condition)
     (let loop ()
       (define result (in-scope '() (lambda () (process body))))
       (cond [(return-val? result) result]
             [(process condition) (loop)]
             [else (void)]))]
    [(list 'for-exp init condition step body)
     (in-scope '()
       (lambda ()
         (define initialized (process init))
         (if (return-val? initialized) initialized
             (let loop ()
               (if (process condition)
                   (let ([result (in-scope '() (lambda () (process body)))])
                     (if (return-val? result) result
                         (let ([advanced (process step)])
                           (if (return-val? advanced) advanced (loop)))))
                   (void))))))]
    [(list 'fire-exp expression) (displayln (process expression))]
    ;; Retain the earlier anonymous-function and bulk-expression forms.
    [(list 'func-exp pairs body)
     (define bindings (map (lambda (pair)
                             (list (cadar pair) (process (cadr pair)))) pairs))
     (define result (in-scope bindings (lambda () (process body))))
     (cond [(return-val? result) (cadr result)]
           [(and (pair? result) (eq? (car result) 'terminator-exp)) (cadadr result)]
           [else (void)])]
    [(cons 'bulk-exp statements)
     (let loop ([remaining statements] [last-value (void)])
       (if (null? remaining)
           (list 'terminator-exp (list 'bulk-ret last-value))
           (let ([result (process (car remaining))])
             (if (return-val? result) result (loop (cdr remaining) result)))))]
    [_ (displayln "ERROR: expression has not been supported yet.")]))
