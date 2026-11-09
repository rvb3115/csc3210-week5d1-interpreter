#lang racket
(require rackunit rackunit/text-ui "util.rkt" "parser.rkt" "interpreter.rkt")
(provide run-checks)
(define (run source [env '(((a 0)))])
  (execute-statement (parse-statement source) env))
(define (a env) (lookup-variable 'a env))
(define tests
  (test-suite
   "If, while, and do-while interpreter"
   (test-case "original symbol parser and lookup"
     (check-equal? (parse 'a) '(var-exp a))
     (check-equal? (execute (parse 'a)) 1)
     (check-equal? (execute (parse 'b)) 2))
   (test-case "true if selects then"
     (check-equal? (a (run '(if (a < 10) ((a = 5)) ((a = 99))))) 5))
   (test-case "false if selects else"
     (check-equal? (a (run '(if (a > 10) ((a = 5)) ((a = 99))))) 99))
   (test-case "unchosen branches never execute"
     (check-equal? (a (run '(if #t ((a = 5)) ((missing + 1))))) 5)
     (check-equal? (a (run '(if #f ((missing + 1)) ((a = 6))))) 6))
   (test-case "if without else"
     (check-equal? (a (run '(if #f ((a = 5))))) 0))
   (test-case "condition must be boolean"
     (check-exn #rx"expected a boolean"
                (lambda () (run '(if 0 ((a = 5)) ())))))
   (test-case "while reaches 10 without extra iteration"
     (check-equal? (a (run '(while (a < 10) ((a + 1))))) 10))
   (test-case "while false initially skips even an invalid body"
     (check-equal? (a (run '(while #f ((missing + 1))))) 0))
   (test-case "while at boundary skips body"
     (check-equal? (a (run '(while (a < 10) ((a + 1))) '(((a 10))))) 10))
   (test-case "do-while reaches 10"
     (check-equal? (a (run '(do ((a + 1)) while (a < 10)))) 10))
   (test-case "do-while runs once when initially false"
     (check-equal? (a (run '(do ((a + 1)) while (a < 10)) '(((a 10))))) 11))
   (test-case "do-while condition sees updated value"
     (check-equal? (a (run '(do ((a + 1)) while (a < 1)))) 1))
   (test-case "both loops reject non-boolean conditions"
     (for ([s '((while 1 ()) (do () while 1))])
       (check-exn #rx"expected a boolean" (lambda () (run s)))))
   (test-case "loop locals do not leak; declaration works each iteration"
     (for ([s '((while (a < 3) ((var temp a) (a + 1)))
                (do ((var temp a) (a + 1)) while (a < 3)))])
       (define result (run s))
       (check-equal? result '(((a 3))))
       (check-exn #rx"variable not found: temp"
                  (lambda () (lookup-variable 'temp result)))))
   (test-case "body local shadows parent"
     (check-equal? (run '(do ((var a 100) (a + 1)) while #f)) '(((a 0)))))
   (test-case "nested loops update enclosing variables"
     (define result
       (run '(while (a < 2)
               ((var b 0) (while (b < 3) ((b + 1) (total + 1))) (a + 1)))
            '(((a 0) (total 0)))))
     (check-equal? result '(((a 2) (total 6)))))
   (test-case "update only nearest existing binding"
     (check-equal? (run '(a + 1) '(((a 5)) ((a 1)))) '(((a 6)) ((a 1)))))
   (test-case "reject duplicate declaration"
     (check-exn #rx"variable already exists: a" (lambda () (run '(var a 2)))))
   (test-case "reject update of missing variable"
     (check-exn #rx"variable not found: z" (lambda () (run '(z + 1)))))
   (test-case "false and void bindings are present"
     (check-false (lookup-variable 'flag '(((flag #f)))))
     (check-true (void? (lookup-variable 'x (list (list (list 'x (void))) '((x 7)))))))
   (test-case "arithmetic expression is not assignment"
     (define env '(((a 4))))
     (check-equal? (execute (parse '(a + 1)) env) 5)
     (check-equal? env '(((a 4)))))
   (test-case "malformed statements are rejected"
     (for ([s '((while #t) (do () until #f) (if #t 42) (var 1 2))])
       (check-exn exn:fail? (lambda () (parse-statement s)))))))
(define (run-checks)
  (define failures (run-tests tests))
  (unless (zero? failures) (error 'tests "~a test cases failed" failures)))
(module+ test (run-checks))
(module+ main (run-checks))
