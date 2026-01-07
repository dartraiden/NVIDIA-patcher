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

# Define patterns in order (name|search|replace)
PATTERNS=(
    "P1xx|071b0700871b0700c71b0700071c0700091c0700|ffff0700ffff0700ffff0700ffff0700ffff0700"
    "CMP|091e0700491e0700bc1e0700fc1e07000b1f0700812007008220070083200700c2200700892107000d2207004d2207008a240700|ffff0700491e0700bc1e0700fc1e0700ffff070081200700ffff070083200700ffff0700ffff0700ffff07004d220700ffff0700"
    "RTX 3080 Ti 20 GB|05220000092200001422000017220000|ffff0000092200001422000017220000"
    "RTX 3060 3840SP|01250000052500000925000040250000|ffff0000052500000925000040250000"
    "RTX 4070 10 GB|85270000af270000bf270000c2270000|ffff0000af270000bf270000c2270000"
    "NVIDIA L40 ES|af260000b0260000bf260000c1260000|ffff0000b0260000bf260000c1260000"
)

# Build sed script for all replacements at once
SED_SCRIPT=""
for pattern in "${PATTERNS[@]}"; do
    IFS='|' read -r name search replace <<< "$pattern"
    
    # Count occurrences efficiently
    count=$(grep -o "$search" <<< "$HEX" | wc -l)
    
    if [ "$count" -gt 0 ]; then
        echo "Found pattern: $name — $count occurrence(s)"
        SED_SCRIPT+="s/$search/$replace/g;"
    else
        echo "Pattern not found: $name"
    fi
done

# Apply all replacements in one sed call
if [ -n "$SED_SCRIPT" ]; then
    HEX=$(sed "$SED_SCRIPT" <<< "$HEX")
fi

# Check if modified
if [ "$HEX" = "$ORIGINAL_HEX" ]; then
    echo "No patterns found. Nothing patched."
    exit 0
fi

# Convert back to binary
echo "$HEX" | xxd -r -p > "$FILE"

echo "=== SUCCESS ==="
echo "Patching complete."