#lang racket
(define
  scope
  (list ;key-value pairs
   (list 'a 1) ;(#symbol value)
   '(b 2)
   )
  )

;var_env:= var_scop x (var_env)
(define
  environment
  (list scope)
  )

;define a function that can pass in a variable name, and resolve it
;(resolve #symbol) -> value or null
(define
  resolve
  (lambda (var_scope var_name)
    (cond
     ((null? var_scope) (void))
     ((eq? (car (car var_scope)) var_name) (cadr (car var_scope)))
     (else (resolve (cdr var_scope) var_name))
     )
    )
  )

;expand that the resolve will work in the environment. it check the first scope, until the root
(define
  resolve_env
  (lambda (var_env var_name)
    (cond
      ((null? var_env) (void))
      ((void? (resolve (car var_env) var_name)) (resolve_env (cdr var_env) var_name))
      (else (resolve (car var_env) var_name))
      )
    )
  )

;define a function that can store new variable name and value
;when variable name already in memory, then
(define
  dog
  (lambda (var_scope var_name var_value)
    (cond
      ((null? var_scope) (set! scope (cons (list var_name var_value) var_scope)))
      ((void? (resolve var_scope var_name)) (set! scope (cons (list var_name var_value) var_scope)))
      (else (displayln "### ERROR ### Variable name has been used."))
      )
    )
  )
;define a function that can override the value of an existed variable name
(define
  update_pair
  (lambda (left_part lst key value)
    (cond
      ((null? lst) left_part)
      ((eq? (car (car lst)) key) (append left_part (list (list key value)) (cdr lst)))
      (else (update_pair (append left_part (list (list key value))) (cdr lst) key value))
      )
    )
  )

;insert and update
(define
  wolf
  (lambda (var_scope var_name var_value)
    (cond
      ((null? var_scope) (dog var_scope var_name var_value))
      ((void? (resolve var_scope var_name)) (dog var_scope var_name var_value))
      (else (set! scope (update_pair '() var_scope var_name var_value)))
      )
    )
  )

;this is the version return the updated scope that doing the scope insert_or_update
(define
  update_scope
  (lambda (var_scope var_name var_value)
    (cond
      ((null? var_scope) (list (list var_name var_value)))
      ((void? (resolve var_scope var_name)) (cons (list var_name var_value) var_scope))
      (else (update_pair '() var_scope var_name var_value))
      )
    )
  )

;expland the wolf(insert or update) to the variable environment
;we need to confirm there is no scope contains the variable name, then we will insert into the top scope of the environment (as a stack)
;otherwise, we will try to check which scope has the variable name, and update it.
(define
  wolf_env
  (lambda (var_env var_name var_value)
    (cond
      ;when variable has not been take, insert into the top scope
      ((void? (resolve_env var_env var_name))
       ;wolf is updating the global variable scope
       (if
        (null? var_env)
        (list (list var_name var_value))
        (set! environment (append (list (cons (list var_name var_value) (car var_env))) (cdr var_env)))
        ))
      (else
       (letrec
           ((update_env (lambda (left right)
                          (cond
                            ;if the right is empty, return left
                            ((null? right) left)
                            ;if the first scope of the right has the variable, update it, and move it to the left, and return the left + right
                            ((not (void? (resolve (car right) var_name)))
                             (append
                              left
                             (list (update_scope (car right) var_name var_value))
                             (cdr right)))
                            (else
                             (update_env (append left (list (car right))) (cdr right)))
                            )
                          )
                        )
            )
         (set! environment (update_env '() var_env))
         )
       )
      )
    )
  )

(provide (all-defined-out))
