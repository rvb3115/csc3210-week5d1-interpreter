#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

; T5 | Expected: 3 and no 999
(displayln "T5")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((func first (n) ((return n) (fire 999)))
       (fire (call first (3)))))))
(display "env: ") (print environment) (newline)
