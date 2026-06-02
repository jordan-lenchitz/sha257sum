       IDENTIFICATION DIVISION.
       PROGRAM-ID. SHA257SUM.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ARGS PIC X(100).
       01  WS-BLOCK-IDX PIC 9(2).
       01  WS-DATA-BUF PIC X(2048).
       01  WS-HASH-OUT PIC X(64).
       
       *> Salts Table
       01  WS-SALTS.
           05 SALT-TBL OCCURS 10 TIMES PIC X(73).
       01  SALT-IDX PIC 9(2).
       01  TEMP-SALT PIC X(73).
       01  TEMP-SUFFIX PIC X(8).
       01  I PIC 9(3).
       01  J PIC 9(3).
       01  SALT-LEN PIC 9(3).
       01  HASH-LEN PIC 9(3) VALUE 64.
       
       *> SHA-256 Variables
       01  H-VALS.
           05 H PIC 9(10) COMP-5 OCCURS 8 TIMES.
       01  W-SCHED PIC 9(10) COMP-5 OCCURS 64 TIMES.
       
       PROCEDURE DIVISION.
       MAIN-LOGIC.
           ACCEPT WS-ARGS FROM COMMAND-LINE.
           MOVE "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA" TO SALT-TBL(1)
           MOVE "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB" TO SALT-TBL(2)
           MOVE "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC" TO SALT-TBL(3)
           MOVE "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD" TO SALT-TBL(4)
           MOVE "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE" TO SALT-TBL(5)
           MOVE "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF" TO SALT-TBL(6)
           MOVE "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG" TO SALT-TBL(7)
           MOVE "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH" TO SALT-TBL(8)
           MOVE "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II" TO SALT-TBL(9)
           MOVE "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ" TO SALT-TBL(10)

           PERFORM VARYING WS-BLOCK-IDX FROM 1 BY 1 UNTIL WS-BLOCK-IDX > 35
               PERFORM SHA256-COMPRESS
               PERFORM INTERLEAVE-SALT
               PERFORM REVERSE-SUFFIX
           END-PERFORM.
           
           DISPLAY "SHA-257 Result: " WS-HASH-OUT.
           STOP RUN.

       SHA256-COMPRESS.
           *> 1. Padding
           *> 2. Message Schedule W (0-63)
           *> 3. 64 Rounds of H (a-h)
           *> 4. Update WS-HASH-OUT with hex representation of H-VALS
           CONTINUE.

       INTERLEAVE-SALT.
           COMPUTE SALT-IDX = FUNCTION MOD(WS-BLOCK-IDX - 1, 10) + 1.
           MOVE SALT-TBL(SALT-IDX) TO TEMP-SALT.
           
           MOVE 73 TO SALT-LEN.
           PERFORM VARYING I FROM 73 BY -1 UNTIL I < 1 OR TEMP-SALT(I:1) NOT = SPACE
               COMPUTE SALT-LEN = I - 1
           END-PERFORM.
           
           MOVE 1 TO J.
           MOVE SPACES TO WS-DATA-BUF.
           
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > HASH-LEN AND I > SALT-LEN
               IF I <= HASH-LEN
                   MOVE WS-HASH-OUT(I:1) TO WS-DATA-BUF(J:1)
                   ADD 1 TO J
               END-IF
               IF I <= SALT-LEN
                   MOVE TEMP-SALT(I:1) TO WS-DATA-BUF(J:1)
                   ADD 1 TO J
               END-IF
           END-PERFORM.

       REVERSE-SUFFIX.
           MOVE WS-HASH-OUT(57:8) TO TEMP-SUFFIX.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > 8
               MOVE TEMP-SUFFIX(I:1) TO WS-HASH-OUT(64 - I + 1 : 1)
           END-PERFORM.
       END PROGRAM SHA257SUM.
