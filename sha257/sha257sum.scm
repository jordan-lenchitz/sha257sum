#!/usr/bin/env guile
!#

(use-modules (rnrs bytevectors)
             (ice-9 binary-ports)
             (ice-9 format))

(define MASK32 #xffffffff)
(define (u32 x) (logand x MASK32))
(define (u32+ . args) (u32 (apply + args)))

(define (rotr x n)
  (u32 (logior (ash x (- n)) (ash x (- 32 n)))))

(define (ch e f g)
  (logxor (logand e f) (logand (u32 (lognot e)) g)))

(define (maj a b c)
  (logxor (logand a b) (logand a c) (logand b c)))

(define (big-s0 a)
  (logxor (rotr a 2) (rotr a 13) (rotr a 22)))

(define (big-s1 e)
  (logxor (rotr e 6) (rotr e 11) (rotr e 25)))

(define (msg-s0 w)
  (logxor (rotr w 7) (rotr w 18) (ash w -3)))

(define (msg-s1 w)
  (logxor (rotr w 17) (rotr w 19) (ash w -10)))

(define K
  #(#x428a2f98 #x71374491 #xb5c0fbcf #xe9b5dba5
    #x3956c25b #x59f111f1 #x923f82a4 #xab1c5ed5
    #xd807aa98 #x12835b01 #x243185be #x550c7dc3
    #x72be5d74 #x80deb1fe #x9bdc06a7 #xc19bf174
    #xe49b69c1 #xefbe4786 #x0fc19dc6 #x240ca1cc
    #x2de92c6f #x4a7484aa #x5cb0a9dc #x76f988da
    #x983e5152 #xa831c66d #xb00327c8 #xbf597fc7
    #xc6e00bf3 #xd5a79147 #x06ca6351 #x14292967
    #x27b70a85 #x2e1b2138 #x4d2c6dfc #x53380d13
    #x650a7354 #x766a0abb #x81c2c92e #x92722c85
    #xa2bfe8a1 #xa81a664b #xc24b8b70 #xc76c51a3
    #xd192e819 #xd6990624 #xf40e3585 #x106aa070
    #x19a4c116 #x1e376c08 #x2748774c #x34b0bcb5
    #x391c0cb3 #x4ed8aa4a #x5b9cca4f #x682e6ff3
    #x748f82ee #x78a5636f #x84c87814 #x8cc70208
    #x90befffa #xa4506ceb #xbef9a3f7 #xc67178f2))

(define SALTS
  #("jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
    "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
    "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
    "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
    "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
    "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
    "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
    "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
    "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
    "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"))

(define (sha256 bv)
  (let* ((h (vector #x6a09e667 #xbb67ae85 #x3c6ef372 #xa54ff53a
                    #x510e527f #x9b05688c #x1f83d9ab #x5be0cd19))
         (len (bytevector-length bv))
         (rem (modulo (+ len 9) 64))
         (pad-len (if (= rem 0) (+ len 9) (+ len 9 (- 64 rem))))
         (padded (make-bytevector pad-len 0))
         (bits (* len 8))
         (w (make-vector 64 0)))
    (bytevector-copy! bv 0 padded 0 len)
    (bytevector-u8-set! padded len #x80)
    (do ((i 0 (+ i 1))) ((= i 8))
      (bytevector-u8-set! padded (+ (- pad-len 8) i)
                          (logand (ash bits (* (- 7 i) -8)) #xff)))
    (do ((off 0 (+ off 64))) ((>= off pad-len))
      (do ((i 0 (+ i 1))) ((= i 16))
        (vector-set! w i (bytevector-u32-ref padded (+ off (* i 4)) (endianness big))))
      (do ((i 16 (+ i 1))) ((= i 64))
        (vector-set! w i
                     (u32+ (msg-s1 (vector-ref w (- i 2)))
                           (vector-ref w (- i 7))
                           (msg-s0 (vector-ref w (- i 15)))
                           (vector-ref w (- i 16)))))
      (let loop ((i 0)
                 (a (vector-ref h 0)) (b (vector-ref h 1))
                 (c (vector-ref h 2)) (d (vector-ref h 3))
                 (e (vector-ref h 4)) (f (vector-ref h 5))
                 (g (vector-ref h 6)) (hh (vector-ref h 7)))
        (if (= i 64)
            (begin
              (vector-set! h 0 (u32+ (vector-ref h 0) a))
              (vector-set! h 1 (u32+ (vector-ref h 1) b))
              (vector-set! h 2 (u32+ (vector-ref h 2) c))
              (vector-set! h 3 (u32+ (vector-ref h 3) d))
              (vector-set! h 4 (u32+ (vector-ref h 4) e))
              (vector-set! h 5 (u32+ (vector-ref h 5) f))
              (vector-set! h 6 (u32+ (vector-ref h 6) g))
              (vector-set! h 7 (u32+ (vector-ref h 7) hh)))
            (let* ((t1 (u32+ hh (big-s1 e) (ch e f g) (vector-ref K i) (vector-ref w i)))
                   (t2 (u32+ (big-s0 a) (maj a b c))))
              (loop (+ i 1)
                    (u32+ t1 t2) a b c
                    (u32+ d t1) e f g)))))
    (apply string-append
           (map (lambda (x) (format #f "~8,'0x" x)) (vector->list h)))))

(define (reverse-suffix s)
  (let* ((n (string-length s))
         (prefix (substring s 0 (- n 8)))
         (suffix (list->string (reverse (string->list (substring s (- n 8) n))))))
    (string-append prefix suffix)))

(define (interleave-to-bv a b)
  (let* ((la (string-length a))
         (lb (string-length b))
         (m (max la lb))
         (out (make-bytevector (+ la lb) 0)))
    (let loop ((k 0) (j 0))
      (if (= k m)
          out
          (let* ((j1 (if (< k la)
                         (begin (bytevector-u8-set! out j (char->integer (string-ref a k))) (+ j 1))
                         j))
                 (j2 (if (< k lb)
                         (begin (bytevector-u8-set! out j1 (char->integer (string-ref b k))) (+ j1 1))
                         j1)))
            (loop (+ k 1) j2))))))

(define (calculate-sha257sum bv)
  (let loop ((r 0) (cur bv))
    (if (= r 35)
        (reverse-suffix (sha256 cur))
        (let* ((h (sha256 cur))
               (rev (reverse-suffix h))
               (next (interleave-to-bv rev (vector-ref SALTS (modulo r 10)))))
          (loop (+ r 1) next)))))

(define (read-file-bv path)
  (call-with-input-file path
    (lambda (port)
      (let ((data (get-bytevector-all port)))
        (if (eof-object? data) (make-bytevector 0) data)))
    #:binary #t))

(define (main args)
  (when (< (length args) 2)
    (format (current-error-port) "Usage: guile sha257sum.scm <string> | -f <file>~%")
    (exit 1))
  (let ((data
         (if (string=? (cadr args) "-f")
             (begin
               (when (< (length args) 3)
                 (format (current-error-port) "Usage: guile sha257sum.scm <string> | -f <file>~%")
                 (exit 1))
               (read-file-bv (caddr args)))
             (string->utf8 (cadr args)))))
    (display (calculate-sha257sum data))
    (newline)))

(main (command-line))
