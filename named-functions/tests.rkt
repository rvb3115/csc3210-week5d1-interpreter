#lang racket
(require rackunit rackunit/text-ui racket/runtime-path
         "parser.rkt" "interpreter.rkt" "util.rkt")
(define-runtime-path here ".")
(define (reset) (update_base_environment (list '((a 1) (b 2)))))
(define (run source) (process (parse source)))
(define (capture thunk) (with-output-to-string thunk))
(define suite
  (test-suite "Programs and named functions"
    (for ([id '(T1 T2 T3 T4 T5 T6 T7 T8 B1 B2)]
          [expected '("10\n" "PARSER ERROR: main must hold a list of statements.\n"
                      "2500\n1\n#<void>\n" "7\n#<void>\n" "3\n"
                      "INTERPRETER ERROR: wrong number of arguments.\n"
                      "INTERPRETER ERROR: not a function.\n" "21\n10\n"
                      "120\n" "40\n-1\n")])
      (test-case (symbol->string id)
        (define output (capture (lambda ()
          (dynamic-require (build-path here (format "~a.rkt" id)) #f))))
        (check-true (string-prefix? output (format "~a\n~aenv: " id expected)))
        (check-equal? (length environment) 1)
        (unless (eq? id 'T1)
          (check-equal? (resolve_env environment 'a) 1)
          (check-equal? (resolve_env environment 'b) 2))
        (when (eq? id 'T3) (check-true (void? (resolve_env environment 'c))))))
    (test-case "Exact assignment and function ASTs"
      (check-equal? (parse '(x = (call sum_seq (1 99 2))))
        '(assign-exp ((var-exp x) (call-exp (var-exp sum_seq)
                     ((num-exp 1) (num-exp 99) (num-exp 2))))))
      (check-equal? (parse '(func id (n) ((return n))))
        '(func-def-exp (var-exp id) ((var-exp n))
                       (list-exp (return-exp (var-exp n))))))
    (test-case "All required parser validation messages"
      (for ([group (list
        (list "main must hold a list of statements." '(main) '(main 5) '(main () ()) '(main (a = 1)))
        (list "invalid function definition." '(func) '(func 1 () ()) '(func f (1) ()) '(func f () (return 1)))
        (list "invalid function call." '(call) '(call 1 ()) '(call f 7) '(call f () ()))
        (list "invalid return." '(return) '(return 1 2)))])
        (for ([bad (cdr group)])
          (check-equal? (capture (lambda () (parse bad)))
                        (string-append "PARSER ERROR: " (car group) "\n")))))
    (test-case "Definition stores value without running body"
      (reset)
      (check-equal? (capture (lambda () (run '(main ((func stored () ((fire 999)))))))) "")
      (check-equal? (car (resolve_env environment 'stored)) 'func-val)
      (check-equal? (capture (lambda () (run '(main ((fire stored))))))
                    "(func-val () (list-exp (fire-exp (num-exp 999))))\n"))
    (test-case "Undefined function and zero-argument call"
      (reset)
      (check-equal? (capture (lambda () (run '(main ((call missing ()))))))
                    "INTERPRETER ERROR: not a function.\n")
      (run '(main ((func zero () ((return 42))) (x = (call zero ())))))
      (check-equal? (resolve_env environment 'x) 42))
    (test-case "Math evaluates each call once and outer effects survive"
      (reset)
      (run '(main ((count = 0)
        (func tick () ((count = (count + 1)) (return count)))
        (answer = ((call tick ()) + (call tick ()))))))
      (check-equal? (resolve_env environment 'count) 2)
      (check-equal? (resolve_env environment 'answer) 3)
      (check-equal? (length environment) 1))
    (test-case "Arguments evaluated before wrong-arity error"
      (reset)
      (run '(main ((count = 0) (func tick () ((count = (count + 1)) (return count)))
                   (func needs (x y) ((return x))))))
      (check-equal? (capture (lambda () (run '(main ((call needs ((call tick ()))))))))
                    "INTERPRETER ERROR: wrong number of arguments.\n")
      (check-equal? (resolve_env environment 'count) 1)
      (check-equal? (length environment) 1))
    (test-case "Empty body returns void and void parameter shadows outer binding"
      (reset)
      (run '(main ((func empty () ()) (func identity (a) ((return a)))
                   (result = (call identity ((call empty ())))))))
      (check-true (void? (resolve_env environment 'result)))
      (check-equal? (resolve_env environment 'a) 1))
    (test-case "Early return unwinds for and do-while scopes"
      (reset)
      (run '(main ((steps = 0)
        (func fromfor () ((for ((i = 0)) (i < 3) ((steps = (steps + 1))) ((return 7))) (return 99)))
        (func fromdo () ((do-while ((return 8)) (1 < 2)) (return 99)))
        (x = (call fromfor ())) (y = (call fromdo ())))))
      (check-equal? (resolve_env environment 'steps) 0)
      (check-equal? (resolve_env environment 'x) 7)
      (check-equal? (resolve_env environment 'y) 8)
      (check-equal? (length environment) 1))))
(define failures (run-tests suite))
(unless (zero? failures) (error 'tests "~a failure(s)" failures))
