#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

; B1 | Expected: 120
(displayln "B1")
(update_base_environment (list '((a 1) (b 2))))
(process (parse '(main ((func fact (n)
         ((ask (n < 2)
            ((return 1))
            ((return (n * (call fact ((n - 1)))))))))
       (fire (call fact (5)))))))
(display "env: ") (print environment) (newline)
