
(define done-been-expanded (mkht))

(define expand-err
    (lambda (ex continue)
        (debug 'compile-error
            (if (and (hash-table? ex) (eq? (vaquero-send-atomic ex 'type) 'error))
                (map (lambda (f) (vaquero-view (vaquero-send-atomic ex f))) '(name form to-text))
                (vaquero-view ex)))
        (exit)))

(define (vaquero-expand code env)
    (define (expand x)
        (vaquero-expand x env))
    (define (noob)
        (vaquero-environment env))
    (define (look-it-up x)
        (if (vaquero-global? x)
            (glookup x)
            (lookup env x top-cont expand-err)))
    (define (vaquero-macro? obj)
        (and (hash-table? obj) (eq? (htr obj 'type) 'operator)))
    (if (not (list? code))
        code
        (if (eq? code '())
            '()
            (let ((head (car code)))
                (case head
                    ((use)
                        (if (check-vaquero-use code)
                            (let ((name (cadr code)) (p (make-module-absolute-path (caddr code))))
                                (if (hte? done-been-expanded p)
                                    (cons 'use (cons name (cons p (cdddr code))))
                                    (begin
                                        (hts! done-been-expanded p #t)
                                        (vaquero-expand-use code env))))
                            (exit)))
                    ((macro)
                        (let* ((noo-env (noob)) (nucode (map (lambda (c) (vaquero-expand c noo-env)) code)))
                            ((vaquero-compile nucode) env top-cont expand-err)
                            nucode))
                    ((macro-eval)
                        (let ((expanded (expand (cons 'seq (cdr code)))))
                            ((vaquero-compile expanded) env top-cont expand-err)
                            ''macro-eval-was-here))
                    ((seq)
                        (if (check-vaquero-seq code)
                            (let ((expanded (map expand code)))
                                (prep-defs (cdr expanded) env top-cont expand-err)
                                expanded)
                            (exit)))
                    ((quote)
                        (if (check-vaquero-quote code)
                            code
                            (exit)))
                    ((syntax)
                        (if (check-vaquero-syntax-export code)
                            (let ((names (cdr code))
                                  (setter! (vaquero-apply-wrapper (vaquero-send-atomic env 'def!))))
                                (setter! 'syntax names)
                                'null)
                            (exit)))
                    ((lambda proc)
                        (cons head (vaquero-expand (cdr code) (noob))))
                    (else 
                        (if (symbol? head)
                            (let ((obj (look-it-up head)))
                                (if (vaquero-macro? obj)
                                    (let ((arg-pair (prepare-vaquero-args (cdr code))))
                                        (define args (car arg-pair))
                                        (define opts (prep-options (cdr arg-pair)))
                                        (vaquero-expand
                                            (vaquero-apply obj args opts top-cont expand-err)
                                            env))
                                    (map expand code)))
                            (map expand code))))))))

(define (vaquero-expand-use code env)
    (define use-name (cadr code))
    (define arg-pair (prepare-vaquero-args (cddr code)))
    (define args (car arg-pair))
    (define path (car args))
    (define abs-path (make-module-absolute-path path))
    (define prog-env (local-env))
    (define prog
        (if (or (symbol? path) (string? path))
            (read-expand-cache-prog path prog-env)
            (vaquero-error code "use: path must be a symbol or a string.")))
    (define use-err
        (lambda (e cont)
            (debug 'USE-ERROR e)
            (exit)))
    (define (looker name)
        (lookup prog-env name top-cont use-err))
    (define exports (looker 'syntax))
    (if (not (eq? exports not-found))
        (let ()
            (define (set-em! k)
                (define defr! (vaquero-send-atomic env 'def!))
                (define op-val (looker k))
                (define spaced-name
                    (string->symbol
                        (apply string-append (map symbol->string (list use-name '- k)))))
                (defr! spaced-name op-val))
            (map set-em! exports))
        #f)
    (cons 'use (cons use-name (cons abs-path (cdddr code)))))


