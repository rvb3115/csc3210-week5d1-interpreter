#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

; T7 | Expected: INTERPRETER ERROR: not a function.
(displayln "T7")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((q = 5) (call q (1))))))
(display "env: ") (print environment) (newline)
