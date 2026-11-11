#lang racket
(require "parser.rkt" "interpreter.rkt" "util.rkt")

(displayln "TASK 1: assignment")
(update_base_environment '(()))
(displayln (parse '(a = 1))) ; (assign-exp (var-exp a) (num-exp 1))
(process (parse '(main
  (a = 1) (fire a)          ; new variable: 1
  (a = (a + 4)) (fire a)    ; existing variable updated: 5
  (b = 0) (fire b))))       ; new variable: 0

(displayln "TASK 2: for loop")
(process (parse '(main
  (for ((a = 0) (a < 10) (a = (a + 1)))
       ((b = (b + 1))))
  (fire a)                 ; 10: outer a was updated
  (fire b))))              ; 10: body ran ten times

(displayln "FALSE CONDITION: body and step skipped")
(process (parse '(main
  (for ((i = 10) (i < 10) (i = (i + 1)))
       ((b = 999)))
  (fire b))))              ; still 10
(printf "Loop-local i removed: ~a\n" (void? (resolve_env environment 'i)))
(printf "Final environment: ~s\n" environment)
