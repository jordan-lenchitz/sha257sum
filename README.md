# sha257sum
like `sha256sum` but not quite! a totally normal completely necessary cli tool that features a fully manual dependency-free implementation of the standard sha-256 algorithm and then subjects your input to 35 sequential rounds of cryptographic torment to arbitrarily boost the number lines of code :)
## how it works
we start with a standard, manually coded sha-256 compression function which handles the initial hashing. the data is then passed through 35 `super stupid processing blocks` which each
- sha-256 hash the the current buffer
- reverse the last 8 characters of the resulting hex digest 
- convert the modified hex string to bytes and interleave sequentially with one of ten massive absurdly named salt blocks

after surviving 35 rounds of this recursive salt-interleaved nightmare the final buffer is hashed one last time, the last 8 characters are reversed again, and the final hex string is returned to the user!

## ports and howto
we are porting `sha257sum` to as many programming languages as possible here on github so please stay tuned for more!
**note: all source code is located in the `sha257/` directory**

`cd sha257` then sudo your choice

- **c**: `gcc sha257sum.c -o sha257sum && ./sha257sum "kevin"`
- **c++**: `g++ sha257sum.cpp -o sha257sum && ./sha257sum "kevin"`
- **c#**: `dotnet run --project sha257sum.cs "kevin"`
- **fortran**: `gfortran sha257sum.f90 -o sha257sum && ./sha257sum "kevin"`
- **go**: `go run sha257sum.go "kevin"`
- **java**: `javac sha257sum.java && java sha257sum "kevin"`
- **node.js**: `node sha257sum.js "kevin"`
- **kotlin**: `kotlinc sha257sum.kt -include-runtime -d sha257sum.jar && java -jar sha257sum.jar "kevin"`
- **lua**: `./sha257sum.lua "kevin"`
- **perl**: `./sha257sum.pl "kevin"`
- **php**: `php sha257sum.php "kevin"`
- **python**: `./sha257sum.py "kevin"` or `./sha257sum.py -f kevin`
- **ruby**: `ruby sha257sum.rb "kevin"`
- **rust**: `rustc sha257sum.rs -o sha257sum && ./sha257sum "kevin"`
- **swift**: `swiftc sha257sum.swift -o sha257sum && ./sha257sum "kevin"`
- **typescript**: `npx ts-node sha257sum.ts "kevin"`
- **mumps**: `mumps -run sha257sum "kevin"` or `mumps -run sha257sum -f kevin`
- **bash and awk**: `./sha257sum.sh "kevin"` or `./sha257sum.sh -f kevin`
- **matlab**: `sha257sum_matlab('kevin')` or `sha257sum_matlab('kevin', true)`

## usage example: an empty file named kevin
`cd sha257 && ./sha257sum.py -f kevin`

`03a66566cea01a239282ab1fa8f7cd5def0e6a471083b37cbf2f606c201d873e`

## usage example: the string "kevin"
`cd sha257 && ./sha257sum.py "kevin"`

`9ff58826adebeefe6377551831bd45896f940d828b37d5f04d79a6897e1b7382`
