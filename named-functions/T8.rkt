#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

; T8 | Expected: 21, 10
(displayln "T8")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((k = 10)
       (func addone (k) ((return (k + 1))))
       (fire (call addone ((k * 2))))
       (fire k)))))
(display "env: ") (print environment) (newline)
