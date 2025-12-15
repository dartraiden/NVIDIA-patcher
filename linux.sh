#!/bin/bash

set -e

FILE="nv-kernel.o_binary"
BACKUP="nv-kernel.o_binary.backup"

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

echo "Creating backup: $BACKUP"
cp -f "$FILE" "$BACKUP"

# Convert file to hex dump (one big line)
HEX=$(xxd -p "$FILE" | tr -d '\n')
ORIGINAL_HEX=$HEX

# Function to replace patterns
replace_pattern() {
    local name="$1"
    local search="$2"
    local replace="$3"

    local count_before=$(grep -o "$search" <<< "$HEX" | wc -l)

    if [ "$count_before" -gt 0 ]; then
        echo "Found pattern: $name — $count_before occurrence(s)"
        HEX=$(sed "s/$search/$replace/g" <<< "$HEX")
    else
        echo "Pattern not found: $name"
    fi
}

# Patterns from PowerShell script (converted to hex)
replace_pattern "Pattern 1" \
"071b0700871b0700c71b0700071c0700091c0700" \
"ffff0700ffff0700ffff0700ffff0700ffff0700"

replace_pattern "Pattern 2" \
"091e0700491e0700bc1e0700fc1e07000b1f0700812007008220070083200700c2200700892107000d2207004d2207008a240700" \
"ffff0700491e0700bc1e0700fc1e0700ffff070081200700ffff070083200700ffff0700ffff0700ffff07004d220700ffff0700"

replace_pattern "Pattern 3" \
"05220000092200001422000017220000" \
"ffff0000092200001422000017220000"

replace_pattern "Pattern 4" \
"01250000052500000925000040250000" \
"ffff0000052500000925000040250000"

replace_pattern "Pattern 5" \
"85270000af270000bf270000c2270000" \
"ffff0000af270000bf270000c2270000"

replace_pattern "Pattern 6" \
"af260000b0260000bf260000c1260000" \
"ffff0000b0260000bf260000c1260000"

# Check if modified
if [ "$HEX" = "$ORIGINAL_HEX" ]; then
    echo "No patterns found. Nothing patched."
    exit 0
fi

# Convert back to binary
echo "$HEX" | xxd -r -p > "$FILE"

echo "=== SUCCESS ==="
echo "Patching complete."

