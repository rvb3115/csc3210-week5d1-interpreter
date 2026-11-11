#lang racket
(require rackunit rackunit/text-ui "parser.rkt" "interpreter.rkt" "util.rkt")
(define (run program) (process (parse program)))
(define (value name) (resolve_env environment name))
(define (reset [env '(() )]) (update_base_environment env))
(define tests
  (test-suite "Assignment and for loop"
    (test-case "Exact assignment AST"
      (check-equal? (parse '(a = 1)) '(assign-exp (var-exp a) (num-exp 1))))
    (test-case "Insert and update without duplicate keys"
      (reset) (run '(a = 1)) (run '(a = (a + 4)))
      (check-equal? environment '(((a 5)))))
    (test-case "Update nearest binding and insert into top scope"
      (reset '(((a 2)) ((a 1) (b 0))))
      (run '(a = 8)) (run '(b = 9)) (run '(c = 3))
      (check-equal? environment '(((c 3) (a 8)) ((a 1) (b 9)))))
    (test-case "Existing void binding is updated rather than duplicated"
      (reset (list (list (list 'a (void))))) (run '(a = 7))
      (check-equal? environment '(((a 7)))))
    (test-case "Assignment right side evaluated once"
      (reset) (run '(main (n = 0)
        (func next () ((n = (n + 1)) (return n)))
        (a = (call next ()))))
      (check-equal? (value 'n) 1) (check-equal? (value 'a) 1))
    (test-case "Exact for AST"
      (check-equal? (parse '(for ((a = 0) (a < 10) (a = (a + 1))) ((b = (b + 1)))))
        '(for-exp (assign-exp (var-exp a) (num-exp 0))
          (boolean-exp < (var-exp a) (num-exp 10))
          (assign-exp (var-exp a) (math-exp + (var-exp a) (num-exp 1)))
          (list-exp (assign-exp (var-exp b) (math-exp + (var-exp b) (num-exp 1)))))))
    (test-case "Required ten-iteration loop"
      (reset) (run '(main (a = 99) (b = 0)
        (for ((a = 0) (a < 10) (a = (a + 1))) ((b = (b + 1))))))
      (check-equal? (value 'a) 10) (check-equal? (value 'b) 10)
      (check-equal? (length environment) 1))
    (test-case "Initialization once and body before step"
      (reset) (run '(main (starts = 0) (n = 0) (sum = 0)
        (for ((starts = (starts + 1)) (n < 3) (n = (n + 1))) ((sum = (sum + n))))))
      (check-equal? (value 'starts) 1) (check-equal? (value 'sum) 3))
    (test-case "False condition skips body and step and removes local index"
      (reset) (run '(main (b = 0) (steps = 0)
        (for ((i = 10) (i < 10) (steps = (steps + 1))) ((b = 99)))))
      (check-equal? (value 'b) 0) (check-equal? (value 'steps) 0)
      (check-true (void? (value 'i))) (check-equal? (length environment) 1))
    (test-case "Nested loops and local cleanup"
      (reset) (run '(main (count = 0)
        (for ((i = 0) (i < 2) (i = (i + 1)))
          ((for ((j = 0) (j < 3) (j = (j + 1)))
            ((temp = j) (count = (count + 1))))))))
      (check-equal? (value 'count) 6)
      (for ([name '(i j temp)]) (check-true (void? (value name)))))
    (test-case "Existing class for syntax remains supported"
      (reset) (run '(main (n = 0)
        (for ((i = 0)) (i < 2) ((i = (i + 1))) ((n = (n + 1))))))
      (check-equal? (value 'n) 2))
    (test-case "Return in body skips step and unwinds scopes"
      (reset) (run '(main (steps = 0)
        (func first () ((for ((i = 0) (i < 3) (steps = (steps + 1)))
          ((ask (i == 0) ((return 7)) ((return 8))))) (return 99)))
        (answer = (call first ()))))
      (check-equal? (value 'answer) 7) (check-equal? (value 'steps) 0)
      (check-equal? (length environment) 1))
    (test-case "Loop scopes removed after runtime error"
      (reset) (check-exn exn:fail? (lambda ()
        (run '(for ((i = 0) (i < 1) (i = (i + 1))) ((x = (1 / 0)))))))
      (check-equal? environment '(())))
    (test-case "Reject nonboolean for condition"
      (reset) (check-exn #rx"condition must produce a boolean"
        (lambda () (run '(for ((i = 0) 1 (i = (i + 1))) ((x = 2))))))
      (check-equal? environment '(())))))
(define failures (run-tests tests))
(unless (zero? failures) (error 'tests "~a test(s) failed" failures))
