#lang racket
(require "util.rkt" "parser.rkt" "interpreter.rkt" "tests.rkt")

(define (run source env)
  (execute-statement (parse-statement source) env))
(define (show label source env)
  (define result (run source env))
  (printf "~a: ~s\n  final scope = ~s\n" label source (car result))
  result)
(define (show-error action)
  (define message
    (with-handlers ([exn:fail? exn-message]) (action) #f))
  (unless message (error 'demo "Expected an error, but none occurred"))
  (printf "  Caught expected error: ~a\n" message))

(define (run-demo)
  (displayln "TASK 1: IF CONDITION AND DEBUGGING")
  (show "True branch" '(if (a < 10) ((a = 5)) ((a = 99))) '(((a 1))))
  (show "False branch" '(if (a < 10) ((a = 5)) ((a = 99))) '(((a 12))))
  (show "Debug: unchosen branch is skipped"
        '(if #t ((a = 7)) ((missing + 1))) '(((a 1))))
  (displayln "Debug: reject a number used as a boolean condition")
  (show-error (lambda () (run '(if 0 ((a = 5)) ()) '(((a 1))))))
  (displayln "\nTASK 2: WHILE (CHECK BEFORE BODY)")
  (displayln "Start a = 7; print after each increment:")
  (show "While" '(while (a < 10) ((a + 1) (print a))) '(((a 7))))
  (show "Initially false: zero iterations"
        '(while (a < 10) ((a + 1))) '(((a 10))))
  (displayln "\nTASK 3: DO-WHILE (BODY BEFORE CHECK)")
  (displayln "Start a = 7; print after each increment:")
  (show "Do-while" '(do ((a + 1) (print a)) while (a < 10)) '(((a 7))))
  (show "Initially false: still one iteration"
        '(do ((a + 1)) while (a < 10)) '(((a 10))))
  (displayln "\nSCOPE CHECKS (BOTH LOOP TYPES)")
  (for ([source '((while (a < 2) ((var temp a) (a + 1)))
                 (do ((var temp a) (a + 1)) while (a < 2)))])
    (define result (show "Local temp" source '(((a 0)))))
    (show-error (lambda () (lookup-variable 'temp result))))
  (displayln "\nAUTOMATED REGRESSION TESTS")
  (run-checks))

;; DrRacket Run or: racket main.rkt
(module+ main (run-demo))
