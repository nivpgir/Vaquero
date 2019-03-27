
(import-for-syntax (chicken io))

(import srfi-1)
(import srfi-13)
(import srfi-69)

(import http-client)
(import openssl)
(import posix-groups)
(import r7rs)
(import symbol-utils)
(import system-information)
;(import unix-sockets)
(import utf8)
;(import utils)
;(import uuid)
(import vector-lib)

(import (chicken bitwise))
(import (chicken condition))
(import (chicken file))
(import (chicken file posix))
(import (chicken io))
(import (chicken irregex))
(import (chicken keyword))
(import (chicken pathname))
(import (chicken process))
(import (chicken process signal))
(import (chicken process-context))
(import (chicken process-context posix))
(import (chicken random))

;(define (uuid-v4) (pseudo-random-integer 340282366920938463463374607431768211456))

(define top-cont identity)
(define top-err
   (lambda (ex continue)
      (debug 'runtime-error
         (if (vaquero-error? ex)
            (map (lambda (f) (vaquero-view (vaquero-send-atomic ex f))) '(name form to-text))
            (vaquero-view ex)))
      (exit)))

(define *cwd* (current-directory))
(define *use-cache* #t)
(define user-home-dir (vector-ref (user-information (current-user-id) #t) 5))

(define (vaquero-cache-dir dir)
   (string-join (list user-home-dir ".vaquero" dir) "/"))

(define cached-global-prelude-path (vaquero-cache-dir "prelude.vaq"))
(define vaquero-mod-dir            (vaquero-cache-dir "modules"))
(define vaquero-expanded-dir       (vaquero-cache-dir "expanded"))
(define vaquero-compiled-dir       (vaquero-cache-dir "compiled"))

(define genv #f)
(define g-has? (lambda (name) #f))
(define g-get  (lambda (name) not-found))

(include "read_expand_cache")
(include "utils")
(include "reader")
(include "syntax_checker")
(include "objects")
(include "send")
(include "macro_expander")
(include "eval_apply")
(include "compiler")
(include "modules")
(include "sockets")
(include "sys")

