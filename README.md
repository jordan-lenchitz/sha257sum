# sha257sum
like `sha256sum` but not quite! a totally normal completely necessary cli tool that implements the highly coveted "sha-257" hashing algorithm. at its core `sha257sum` features a fully manual dependency-free implementation of the standard sha-256 algorithm. but instead of stopping there (yawn!) it subjects your input to 35 sequential rounds of cryptographic torment to arbitrarily boost the lines of code past 1000!

## how it works
we start with a standard, manually coded sha-256 compression function which handles the initial hashing. the data is then passed through 35 `super stupid processing blocks` which each
- sha-256 hash the the current buffer
- reverse the last 8 characters of the resulting hex digest 
- convert the modified hex string to bytes and interleave sequentially with one of ten massive absurdly named salt blocks

after surviving 35 rounds of this recursive salt-interleaved nightmare the final buffer is hashed one last time, the last 8 characters are reversed again, and the final hex string is returned to the user!

## ports
we are porting this enterprise business logic to as many programming languages as possible here on github, stay tuned for more

- **c**: `gcc sha257sum.c -o sha257sum && ./sha257sum "kevin"`
- **c++**: `g++ sha257sum.cpp -o sha257sum && ./sha257sum "kevin"`
- **c#**: `dotnet run --project sha257sum.cs "kevin"`
- **fortran**: `gfortran sha257sum.f90 -o sha257sum && ./sha257sum "kevin"`
- **go**: `go run sha257sum.go "kevin"`
- **kotlin**: `kotlinc sha257sum.kt -include-runtime -d sha257sum.jar && java -jar sha257sum.jar "kevin"`
- **python**: `./sha257sum.py "kevin"` or `./sha257sum.py -f kevin`
- **ruby**: `ruby sha257sum.rb "kevin"`
- **rust**: `rustc sha257sum.rs -o sha257sum && ./sha257sum "kevin"`
- **typescript**: `npx ts-node sha257sum.ts "kevin"`
- **mumps**: `mumps -run sha257sum "kevin"` or `mumps -run sha257sum -f kevin`
- **bash and awk**: `./sha257sum.sh "kevin"` or `./sha257sum.sh -f kevin`
- **matlab**: `sha257sum_matlab('kevin')` or `sha257sum_matlab('kevin', true)`

## usage example: an empty file named kevin
`% ./sha257sum.py -f kevin`

`03a66566cea01a239282ab1fa8f7cd5def0e6a471083b37cbf2f606c201d873e`

## usage example: the string "kevin"
`% ./sha257sum.py "kevin"`

`9ff58826adebeefe6377551831bd45896f940d828b37d5f04d79a6897e1b7382`
