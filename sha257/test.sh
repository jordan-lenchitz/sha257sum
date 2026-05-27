#!/bin/bash
# Test script for sha257sum
echo "Running tests..."

/root/sha257sum/sha257/sha257sum kevin > test_out_1.txt
/root/sha257sum/sha257/sha257sum -f kevin > test_out_2.txt

if [ -s test_out_1.txt ] && [ -s test_out_2.txt ]; then
    echo "Tests passed!"
    rm test_out_1.txt test_out_2.txt
    exit 0
else
    echo "Tests failed!"
    rm test_out_1.txt test_out_2.txt
    exit 1
fi
