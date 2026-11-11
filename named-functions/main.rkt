#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

; Run every required test and both bonuses, each in a fresh environment.

; T1 | Expected: 10
(displayln "T1")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((a = 5) (b = (a * 2)) (fire b)))))
(display "env: ") (print environment) (newline)

; T2 | Expected: PARSER ERROR: main must hold a list of statements.
(displayln "T2")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main (a = 1))))
(display "env: ") (print environment) (newline)

; T3 | Expected: 2500, 1, #<void>
(displayln "T3")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main (
  (func sum_seq (a b s)
    ((c = (((a + b) * (((b - a) / s) + 1)) / 2))
     (return c)))
  (x = (call sum_seq (1 99 2)))
  (fire x) (fire a) (fire c)))))
(display "env: ") (print environment) (newline)

; T4 | Expected: 7, #<void>
(displayln "T4")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((func hello (n) ((fire n)))
       (y = (call hello (7))) (fire y)))))
(display "env: ") (print environment) (newline)

; T5 | Expected: 3 and no 999
(displayln "T5")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((func first (n) ((return n) (fire 999)))
       (fire (call first (3)))))))
(display "env: ") (print environment) (newline)

; T6 | Expected: INTERPRETER ERROR: wrong number of arguments.
(displayln "T6")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((func sum_seq (a b s) ((return a)))
       (call sum_seq (1 2))))))
(display "env: ") (print environment) (newline)

; T7 | Expected: INTERPRETER ERROR: not a function.
(displayln "T7")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((q = 5) (call q (1))))))
(display "env: ") (print environment) (newline)

; T8 | Expected: 21, 10
(displayln "T8")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((k = 10)
       (func addone (k) ((return (k + 1))))
       (fire (call addone ((k * 2))))
       (fire k)))))
(display "env: ") (print environment) (newline)

; B1 | Expected: 120
(displayln "B1")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((func fact (n)
         ((ask (n < 2)
            ((return 1))
            ((return (n * (call fact ((n - 1)))))))))
       (fire (call fact (5)))))))
(display "env: ") (print environment) (newline)

; B2 | Expected: 40, -1
(displayln "B2")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((func find (lim)
         ((i = 0)
          (while (i < 100)
            ((i = (i + 1))
             (ask (i == lim) ((return (i * 10))) ((i = i)))))
          (return -1)))
       (fire (call find (4)))
       (fire (call find (500)))))))
(display "env: ") (print environment) (newline)
