#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

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
