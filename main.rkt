#lang racket
(require "parser.rkt"
         "util.rkt"
         "interpreter.rkt"
         rackunit
         rackunit/text-ui)

; All successful examples pass a source symbol through the parser first.
(define nested-env '(((a 100)) ((middle 20)) ((a 1) (b 2))))
(define (show-result source [env environment])
  (define parsed (parse source))
  (printf "~s -> ~s -> ~s\n" source parsed (execute parsed env)))

(define (run-demo)
  (displayln "Default environment:")
  (show-result 'a)
  (show-result 'b)
  (displayln "Nested environment: current -> parent -> root")
  (show-result 'a nested-env)
  (show-result 'middle nested-env)
  (show-result 'b nested-env)
  (displayln "Missing variable (caught so the demo can continue):")
  (with-handlers ([exn:fail? (lambda (e) (displayln (exn-message e)))])
    (execute (parse 'c))))

(define interpreter-tests
  (test-suite
   "Variable interpreter"
   (test-case "parser output and default a"
     (check-equal? (parse 'a) '(var-exp a))
     (check-equal? (execute (parse 'a)) 1))
   (test-case "default b"
     (check-equal? (execute (parse 'b)) 2))
   (test-case "current scope shadows root"
     (check-equal? (execute (parse 'a) nested-env) 100))
   (test-case "parent lookup"
     (check-equal? (execute (parse 'middle) nested-env) 20))
   (test-case "root lookup"
     (check-equal? (execute (parse 'b) nested-env) 2))
   (test-case "missing variable raises exact error"
     (check-exn #rx"^error: variable not found$"
                (lambda () (execute (parse 'c)))))
   (test-case "empty environment"
     (check-exn #rx"^error: variable not found$"
                (lambda () (execute (parse 'a) '()))))
   (test-case "skip empty scopes"
     (check-equal? (execute (parse 'b) '(() () ((b 2)))) 2))
   (test-case "false is a valid value"
     (check-false (execute (parse 'flag) '(((flag #f))))))
   (test-case "void binding shadows outer value"
     (check-true (void? (execute (parse 'x)
                                (list (list (list 'x (void))) '((x 7)))))))
   (test-case "reject unsupported and malformed intermediate forms"
     (for ([exp (list 1 '(num-exp 1) '(var-exp) '(var-exp 1)
                      '(var-exp a b) (void))])
       (check-exn #rx"^error: unsupported expression$"
                  (lambda () (execute exp)))))
   (test-case "reject unsupported parser input"
     ; The starter parser prints ERROR and returns void for non-symbols.
     (check-exn #rx"^error: unsupported expression$"
                (lambda ()
                  (parameterize ([current-output-port (open-output-string)])
                    (execute (parse 1))))))))

; DrRacket Run or: racket main.rkt
(module+ main
  (run-demo)
  (displayln "\nAutomated test results:")
  (define failures (run-tests interpreter-tests))
  (unless (zero? failures) (exit 1)))

; Command-line test runner: raco test main.rkt
(module+ test
  (define failures (run-tests interpreter-tests))
  (unless (zero? failures) (error 'tests "Interpreter tests failed")))
