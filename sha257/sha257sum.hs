import Data.Word (Word32, Word64, Word8)
import Data.Bits (xor, (.&.), (.|.), complement, shiftR, shiftL, rotateR)
import Data.List (foldl')
import Data.Char (ord)
import Numeric (showHex)
import System.Environment (getArgs)
import System.IO (openBinaryFile, IOMode(ReadMode), hGetContents)

-- SHA-256 round constants
kConsts :: [Word32]
kConsts =
  [ 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
  , 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
  , 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
  , 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
  , 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
  , 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
  , 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
  , 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
  , 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
  , 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
  , 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
  , 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
  , 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
  , 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
  , 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
  , 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
  ]

initHash :: [Word32]
initHash =
  [ 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
  , 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
  ]

ch :: Word32 -> Word32 -> Word32 -> Word32
ch e f g = (e .&. f) `xor` (complement e .&. g)

maj :: Word32 -> Word32 -> Word32 -> Word32
maj a b c = (a .&. b) `xor` (a .&. c) `xor` (b .&. c)

sigma0 :: Word32 -> Word32
sigma0 a = rotateR a 2 `xor` rotateR a 13 `xor` rotateR a 22

sigma1 :: Word32 -> Word32
sigma1 e = rotateR e 6 `xor` rotateR e 11 `xor` rotateR e 25

msgSigma0 :: Word32 -> Word32
msgSigma0 w = rotateR w 7 `xor` rotateR w 18 `xor` (w `shiftR` 3)

msgSigma1 :: Word32 -> Word32
msgSigma1 w = rotateR w 17 `xor` rotateR w 19 `xor` (w `shiftR` 10)

toWord32BE :: [Word8] -> Word32
toWord32BE = foldl' (\acc b -> (acc `shiftL` 8) .|. fromIntegral b) 0

fromWord64BE :: Word64 -> [Word8]
fromWord64BE w =
  [ fromIntegral (w `shiftR` 56), fromIntegral (w `shiftR` 48)
  , fromIntegral (w `shiftR` 40), fromIntegral (w `shiftR` 32)
  , fromIntegral (w `shiftR` 24), fromIntegral (w `shiftR` 16)
  , fromIntegral (w `shiftR` 8),  fromIntegral w
  ]

chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs = take n xs : chunksOf n (drop n xs)

padMessage :: [Word8] -> [Word8]
padMessage msg = msg ++ [0x80] ++ replicate padLen 0x00 ++ lenBytes
  where
    msgLen   = length msg
    padLen   = (55 - msgLen) `mod` 64
    lenBytes = fromWord64BE (fromIntegral msgLen * 8 :: Word64)

buildSchedule :: [[Word8]] -> [Word32]
buildSchedule chunks = go (map toWord32BE chunks) 16
  where
    go acc i
      | i >= 64   = acc
      | otherwise =
          let w = msgSigma1 (acc !! (i-2)) + acc !! (i-7)
                + msgSigma0 (acc !! (i-15)) + acc !! (i-16)
          in  go (acc ++ [w]) (i+1)

processBlock :: [Word32] -> [Word8] -> [Word32]
processBlock h block = zipWith (+) h compressed
  where
    ws         = buildSchedule (chunksOf 4 block)
    compressed = foldl' step h (zip kConsts ws)
    step [a,b,c,d,e,f,g,hh] (k,w) =
      let t1 = hh + sigma1 e + ch e f g + k + w
          t2 = sigma0 a + maj a b c
      in  [t1+t2, a, b, c, d+t1, e, f, g]
    step st _ = st

toHex8 :: Word32 -> String
toHex8 w = let s = showHex w "" in replicate (8 - length s) '0' ++ s

sha256 :: [Word8] -> String
sha256 msg = concatMap toHex8 (foldl' processBlock initHash (chunksOf 64 (padMessage msg)))

reverseLast8 :: String -> String
reverseLast8 hex = take 56 hex ++ reverse (drop 56 hex)

interleave :: [a] -> [a] -> [a]
interleave []     ys     = ys
interleave xs     []     = xs
interleave (x:xs) (y:ys) = x : y : interleave xs ys

toBytes :: String -> [Word8]
toBytes = map (fromIntegral . ord)

-- the 10 absurd salts, cycling endlessly through all 35 rounds (haskell loves a good cycle)
salts :: [String]
salts = cycle
  [ "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
  , "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
  , "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
  , "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
  , "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
  , "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
  , "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
  , "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
  , "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
  , "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
  ]

-- START OF SUPER STUPID PROCESSING BLOCK (all 35 of them, collapsed into one referentially transparent catamorphism)
stupidBlock :: [Word8] -> String -> [Word8]
stupidBlock buf salt = interleave (toBytes (reverseLast8 (sha256 buf))) (toBytes salt)

superStupidPipeline :: [Word8] -> [Word8]
superStupidPipeline = flip (foldl' stupidBlock) (take 35 salts)

main :: IO ()
main = do
  args <- getArgs
  buf  <- case args of
    ["-f", path] -> do
      h <- openBinaryFile path ReadMode
      fmap toBytes (hGetContents h)
    [input]      -> return (toBytes input)
    _            -> return []
  putStrLn (reverseLast8 (sha256 (superStupidPipeline buf)))
