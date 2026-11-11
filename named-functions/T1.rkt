#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

; T1 | Expected: 10
(displayln "T1")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((a = 5) (b = (a * 2)) (fire b)))))
(display "env: ") (print environment) (newline)
