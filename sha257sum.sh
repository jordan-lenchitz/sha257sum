#!/bin/bash

# sha257sum implementation using bash and awk
# Author: Gemini CLI

SALTS=(
    "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA"
    "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB"
    "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC"
    "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD"
    "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE"
    "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF"
    "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG"
    "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH"
    "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II"
    "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
)

BUF_FILE=$(mktemp)

if [ "$1" == "-f" ]; then
    if [ -f "$2" ]; then
        cat "$2" > "$BUF_FILE"
    else
        echo "Error: File $2 not found."
        rm "$BUF_FILE"
        exit 1
    fi
elif [ -n "$1" ]; then
    echo -n "$1" > "$BUF_FILE"
else
    echo "Usage: $0 <string> | -f <file>"
    rm "$BUF_FILE"
    exit 1
fi

for i in {0..34}; do
    HEX=$(sha256sum "$BUF_FILE" | awk '{print $1}')
    SALT="${SALTS[$((i % 10))]}"
    # Transform hex and interleave with salt in one AWK pass
    echo "$HEX" | awk -v salt="$SALT" '
    {
        prefix = substr($1, 1, 56)
        suffix = substr($1, 57, 8)
        rev_suffix = ""
        for (j = length(suffix); j > 0; j--) rev_suffix = rev_suffix substr(suffix, j, 1)
        inter = prefix rev_suffix
        
        l1 = length(inter)
        l2 = length(salt)
        maxL = (l1 > l2 ? l1 : l2)
        for (k = 1; k <= maxL; k++) {
            if (k <= l1) printf "%s", substr(inter, k, 1)
            if (k <= l2) printf "%s", substr(salt, k, 1)
        }
    }' > "$BUF_FILE.new"
    mv "$BUF_FILE.new" "$BUF_FILE"
done

FINAL_HEX=$(sha256sum "$BUF_FILE" | awk '{print $1}')
echo "$FINAL_HEX" | awk '
{
    prefix = substr($1, 1, 56)
    suffix = substr($1, 57, 8)
    rev_suffix = ""
    for (j = length(suffix); j > 0; j--) rev_suffix = rev_suffix substr(suffix, j, 1)
    print prefix rev_suffix
}'

rm "$BUF_FILE"
