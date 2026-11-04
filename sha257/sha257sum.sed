#!/usr/bin/env bash
set -euo pipefail

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
trap 'rm -f "$BUF_FILE" "$BUF_FILE.new"' EXIT

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <string> | -f <file>" >&2
    exit 1
elif [ "$1" = "-f" ]; then
    if [ "$#" -lt 2 ] || [ ! -f "$2" ]; then
        echo "Error: File ${2:-} not found." >&2
        exit 1
    fi
    cat "$2" > "$BUF_FILE"
else
    printf '%s' "$1" > "$BUF_FILE"
fi

for i in {0..34}; do
    HEX=$(sha256sum "$BUF_FILE" | cut -d' ' -f1)
    SALT="${SALTS[$((i % 10))]}"
    # Transform hex (reverse last 8 chars) and interleave with salt in sed
    printf '%s#%s' "$HEX" "$SALT" | sed -E '
        s/^(.{56})(.)(.)(.)(.)(.)(.)(.)(.)/\1\9\8\7\6\5\4\3\2/
        s/^/~/
        :loop
        s/^([^~]*)~(.)([^#]*)#(.)(.*)$/\1\2\4~\3#\5/
        t loop
        s/^([^~]*)~(.)([^#]*)#$/\1\2~\3#/
        t loop
        s/^([^~]*)~#(.)(.*)$/\1\2~#\3/
        t loop
        s/~.*$//
    ' > "$BUF_FILE.new"
    mv "$BUF_FILE.new" "$BUF_FILE"
done

FINAL_HEX=$(sha256sum "$BUF_FILE" | cut -d' ' -f1)
printf '%s' "$FINAL_HEX" | sed -E 's/^(.{56})(.)(.)(.)(.)(.)(.)(.)(.)/\1\9\8\7\6\5\4\3\2/'
echo ""
