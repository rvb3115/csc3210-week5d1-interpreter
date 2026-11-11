#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

; T4 | Expected: 7, #<void>
(displayln "T4")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((func hello (n) ((fire n)))
       (y = (call hello (7))) (fire y)))))
(display "env: ") (print environment) (newline)
