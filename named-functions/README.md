# Programs and named functions

This submission extends the [week 9 day 2 class starter](https://github.com/freindst/CSC3210_language_theory_fall_2026/tree/main/week9d2) with whole programs, named function definitions, calls, and tagged return values. The environment remains a list of scopes containing symbol–value pairs.

## Run all assignment cases

Open **main.rkt** in DrRacket and click **Run**. It contains T1–T8 and both bonuses B1–B2. Every case resets the environment to `(((a 1) (b 2)))` and prints the environment afterward.

```sh
racket main.rkt
racket tests.rkt
```

The automated suite passes **18 tests**. [Full assignment output](console-output.txt) and [test report](test-results.txt).

## Required behavior

- `(main (S1 ... Sn))` parses to `list-exp`. Malformed programs print the required error. A recursive statement helper executes in order and stops on `return-val`.
- `func`, `call`, and `return` validate their syntax and produce the exact required `func-def-exp`, `call-exp`, and `return-exp` forms.
- Definitions store `(func-val (parameters ...) body)` using `wolf_env`; defining a function does not execute its body. `(fire NAME)` can display the stored value.
- Calls resolve the function, evaluate arguments in the caller's environment, check arity, push parameter bindings, run the body, and pop the current scope. Updates to outer variables survive.
- `return` produces `(return-val value)`. Calls unwrap that tag; a function with no return produces `void`.
- Math operands are evaluated once, so calls inside arithmetic do not run twice.
- `ask` parses both branches. Return propagates through `ask`, `while`, `do-while`, and `for` while removing their temporary scopes.
- Utility fixes preserve earlier bindings when updating a later pair and distinguish missing names from bindings whose value is `void`.

The assignment's nested assignment form is retained, for example:

```racket
(assign-exp ((var-exp x)
             (call-exp (var-exp sum_seq)
                       ((num-exp 1) (num-exp 99) (num-exp 2)))))
```

## Actual DrRacket screenshots

Each screenshot shows the labeled test program in Definitions and the actual output plus complete printed environment in Interactions. The individual `.rkt` files reproduce the same cases included in `main.rkt`.

| Test | Expected output | Program | Screenshot |
| --- | --- | --- | --- |
| T1 | `10` | [T1.rkt](T1.rkt) | [T1.png](T1.png) |
| T2 | `PARSER ERROR: main must hold a list of statements.` | [T2.rkt](T2.rkt) | [T2.png](T2.png) |
| T3 | `2500`, `1`, `#<void>` | [T3.rkt](T3.rkt) | [T3.png](T3.png) |
| T4 | `7`, `#<void>` | [T4.rkt](T4.rkt) | [T4.png](T4.png) |
| T5 | `3`; no `999` output | [T5.rkt](T5.rkt) | [T5.png](T5.png) |
| T6 | `INTERPRETER ERROR: wrong number of arguments.` | [T6.rkt](T6.rkt) | [T6.png](T6.png) |
| T7 | `INTERPRETER ERROR: not a function.` | [T7.rkt](T7.rkt) | [T7.png](T7.png) |
| T8 | `21`, `10` | [T8.rkt](T8.rkt) | [T8.png](T8.png) |
| B1 | `120` | [B1.rkt](B1.rkt) | [B1.png](B1.png) |
| B2 | `40`, `-1` | [B2.rkt](B2.rkt) | [B2.png](B2.png) |

All ten cases match, and each leaves exactly one environment scope. T2, T6, and T7 intentionally demonstrate the specified error messages. The `999` syntax remains visible in T5's stored function value; it is never executed or printed as a separate result.
