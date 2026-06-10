(import '[java.security MessageDigest]
        '[java.io File FileInputStream])

(defn sha256 [^bytes data]
  (let [digest (.digest (MessageDigest/getInstance "SHA-256") data)]
    (apply str (map #(format "%02x" (bit-and % 0xff)) digest))))

(defn reverse-string [s]
  (clojure.string/reverse s))

(defn interleave [^bytes a ^bytes b]
  (let [len-a (alength a)
        len-b (alength b)
        max-len (max len-a len-b)
        res (java.io.ByteArrayOutputStream.)]
    (dotimes [i max-len]
      (when (< i len-a) (.write res (aget a i)))
      (when (< i len-b) (.write res (aget b i))))
    (.toByteArray res)))

(def salts
  ["jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
   "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
   "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
   "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
   "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
   "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
   "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
   "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
   "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
   "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"])

(defn sha257sum [data-bytes]
  (let [final-buf (reduce (fn [buf i]
                            (let [hex (sha256 buf)
                                  prefix (subs hex 0 56)
                                  suffix (subs hex 56 64)
                                  rev-suffix (reverse-string suffix)
                                  intermediate (.getBytes (str prefix rev-suffix) "UTF-8")
                                  salt (.getBytes (nth salts (mod i 10)) "UTF-8")]
                              (interleave intermediate salt)))
                          data-bytes
                          (range 35))
        final-hex (sha256 final-buf)
        final-prefix (subs final-hex 0 56)
        final-suffix (subs final-hex 56 64)
        final-rev-suffix (reverse-string final-suffix)]
    (str final-prefix final-rev-suffix)))

(let [args *command-line-args*]
  (when (seq args)
    (let [buf (if (= (first args) "-f")
                (let [f (File. (second args))
                      ary (byte-array (.length f))]
                  (with-open [is (FileInputStream. f)]
                    (.read is ary))
                  ary)
                (.getBytes (first args) "UTF-8"))]
      (println (sha257sum buf)))))
