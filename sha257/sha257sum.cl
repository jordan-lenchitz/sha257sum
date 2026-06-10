(defun right-rotate (n b)
  (declare (type (unsigned-byte 32) n) (type (integer 0 32) b))
  (logand #xffffffff (logior (ash n (- b)) (ash n (- 32 b)))))

(defun ch (e f g)
  (logxor (logand e f) (logand (lognot e) g)))

(defun maj (a b c)
  (logxor (logand a b) (logand a c) (logand b c)))

(defun s0 (a)
  (logxor (right-rotate a 2) (right-rotate a 13) (right-rotate a 22)))

(defun s1 (e)
  (logxor (right-rotate e 6) (right-rotate e 11) (right-rotate e 25)))

(defun msg-s0 (w)
  (logxor (right-rotate w 7) (right-rotate w 18) (ash w -3)))

(defun msg-s1 (w)
  (logxor (right-rotate w 17) (right-rotate w 19) (ash w -10)))

(defparameter *k*
  #(#x428a2f98 #x71374491 #xb5c0fbcf #xe9b5dba5 #x3956c25b #x59f111f1 #x923f82a4 #xab1c5ed5
    #xd807aa98 #x12835b01 #x243185be #x550c7dc3 #x72be5d74 #x80deb1fe #x9bdc06a7 #xc19bf174
    #xe49b69c1 #xefbe4786 #x0fc19dc6 #x240ca1cc #x2de92c6f #x4a7484aa #x5cb0a9dc #x76f988da
    #x983e5152 #xa831c66d #xb00327c8 #xbf597fc7 #xc6e00bf3 #xd5a79147 #x06ca6351 #x14292967
    #x27b70a85 #x2e1b2138 #x4d2c6dfc #x53380d13 #x650a7354 #x766a0abb #x81c2c92e #x92722c85
    #xa2bfe8a1 #xa81a664b #xc24b8b70 #xc76c51a3 #xd192e819 #xd6990624 #xf40e3585 #x106aa070
    #x19a4c116 #x1e376c08 #x2748774c #x34b0bcb5 #x391c0cb3 #x4ed8aa4a #x5b9cca4f #x682e6ff3
    #x748f82ee #x78a5636f #x84c87814 #x8cc70208 #x90befffa #xa4506ceb #xbef9a3f7 #xc67178f2))

(defun sha256 (msg)
  (let ((h (vector #x6a09e667 #xbb67ae85 #x3c6ef372 #xa54ff53a #x510e527f #x9b05688c #x1f83d9ab #x5be0cd19))
        (msg-len (length msg)))
    (let* ((new-len (+ msg-len 1))
           (padding-len (mod (- 56 (mod new-len 64)) 64)))
      (setf new-len (+ new-len padding-len 8))
      (let ((padded (make-array new-len :element-type '(unsigned-byte 8) :initial-element 0)))
        (replace padded msg)
        (setf (aref padded msg-len) #x80)
        (let ((bits (* msg-len 8)))
          (loop for i from 0 to 7 do
            (setf (aref padded (- new-len 1 i)) (logand (ash bits (* i -8)) #xff))))
        
        (loop for offset from 0 below new-len by 64 do
          (let ((w (make-array 64 :element-type '(unsigned-byte 32) :initial-element 0)))
            (loop for i from 0 below 16 do
              (setf (aref w i) 
                    (logior (ash (aref padded (+ offset (* i 4))) 24)
                            (ash (aref padded (+ offset (* i 4) 1)) 16)
                            (ash (aref padded (+ offset (* i 4) 2)) 8)
                            (aref padded (+ offset (* i 4) 3)))))
            (loop for i from 16 below 64 do
              (setf (aref w i) (logand #xffffffff (+ (msg-s1 (aref w (- i 2)))
                                                      (aref w (- i 7))
                                                      (msg-s0 (aref w (- i 15)))
                                                      (aref w (- i 16))))))
            (let ((a (aref h 0)) (b (aref h 1)) (c (aref h 2)) (d (aref h 3))
                  (e (aref h 4)) (f (aref h 5)) (g (aref h 6)) (hh (aref h 7)))
              (loop for j from 0 below 64 do
                (let* ((t1 (logand #xffffffff (+ hh (s1 e) (ch e f g) (aref *k* j) (aref w j))))
                       (t2 (logand #xffffffff (+ (s0 a) (maj a b c)))))
                  (setf hh g g f f e e (logand #xffffffff (+ d t1))
                        d c c b b a a (logand #xffffffff (+ t1 t2)))))
              (setf (aref h 0) (logand #xffffffff (+ (aref h 0) a))
                    (aref h 1) (logand #xffffffff (+ (aref h 1) b))
                    (aref h 2) (logand #xffffffff (+ (aref h 2) c))
                    (aref h 3) (logand #xffffffff (+ (aref h 3) d))
                    (aref h 4) (logand #xffffffff (+ (aref h 4) e))
                    (aref h 5) (logand #xffffffff (+ (aref h 5) f))
                    (aref h 6) (logand #xffffffff (+ (aref h 6) g))
                    (aref h 7) (logand #xffffffff (+ (aref h 7) hh)))))))
      (format nil "~(~{~8,'0x~}~)" (coerce h 'list)))))

(defun string-to-bytes (s)
  (map '(vector (unsigned-byte 8)) #'char-code s))

(defun interleave (bytes-a bytes-b)
  (let* ((len-a (length bytes-a))
         (len-b (length bytes-b))
         (max-len (max len-a len-b))
         (res (make-array 0 :element-type '(unsigned-byte 8) :fill-pointer 0 :adjustable t)))
    (loop for i from 0 below max-len do
      (when (< i len-a) (vector-push-extend (aref bytes-a i) res))
      (when (< i len-b) (vector-push-extend (aref bytes-b i) res)))
    res))

(defun reverse-string (s)
  (reverse s))

(defun sha257sum (msg-bytes)
  (let ((salts (map 'vector #'string-to-bytes
                    '("jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
                      "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
                      "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
                      "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
                      "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
                      "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
                      "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
                      "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
                      "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
                      "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"))))
    (let ((buf msg-bytes))
      (loop for i from 0 below 35 do
        (let* ((hex (sha256 buf))
               (prefix (subseq hex 0 56))
               (suffix (subseq hex 56 64))
               (rev-suffix (reverse-string suffix))
               (intermediate (string-to-bytes (concatenate 'string prefix rev-suffix)))
               (salt (aref salts (mod i 10))))
          (setf buf (interleave intermediate salt))))
      (let* ((hex (sha256 buf))
             (prefix (subseq hex 0 56))
             (suffix (subseq hex 56 64))
             (rev-suffix (reverse-string suffix)))
        (concatenate 'string prefix rev-suffix)))))

(defun read-file-bytes (path)
  (with-open-file (stream path :element-type '(unsigned-byte 8))
    (let ((data (make-array (file-length stream) :element-type '(unsigned-byte 8))))
      (read-sequence data stream)
      data)))

(let ((args (cdr sb-ext:*posix-argv*)))
  (when args
    (let ((buf (if (string= (car args) "-f")
                   (read-file-bytes (cadr args))
                   (string-to-bytes (car args)))))
      (format t "~a~%" (sha257sum buf)))))
