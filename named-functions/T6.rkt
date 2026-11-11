#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

; T6 | Expected: INTERPRETER ERROR: wrong number of arguments.
(displayln "T6")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((func sum_seq (a b s) ((return a)))
       (call sum_seq (1 2))))))
(display "env: ") (print environment) (newline)
