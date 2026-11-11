#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

; T2 | Expected: PARSER ERROR: main must hold a list of statements.
(displayln "T2")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main (a = 1))))
(display "env: ") (print environment) (newline)
