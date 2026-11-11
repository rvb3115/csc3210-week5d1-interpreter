#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

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
