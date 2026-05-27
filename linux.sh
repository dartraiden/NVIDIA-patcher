#!/bin/bash

set -e

INSTALLER=$(ls NVIDIA-Linux*.run 2>/dev/null | head -n 1)

if [ -z "$INSTALLER" ]; then
    echo "Error: Installer not found."
    exit 1
fi

# Extract files from installer
echo "Extracting $INSTALLER..."
chmod +x "$INSTALLER"
./"$INSTALLER" --extract-only

# Define the path to the binary inside the extracted directory
# The extracted folder matches the filename without .run
FILE="${INSTALLER%.run}/kernel/nvidia/nv-kernel.o_binary"
BACKUP="$FILE.backup"

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
    "P1xx|071b0700871b0700c71b0700071c0700091c07|ffff0700ffff0700ffff0700ffff0700ffff07"
    "CMP|091e0700491e0700bc1e0700fc1e07000b1f0700812007008220070083200700c2200700892107000d2207004d2207008a2407|ffff0700ffff0700ffff0700ffff0700ffff0700ffff0700ffff0700ffff0700ffff0700ffff0700ffff0700ffff0700ffff07"
    "RTX 3080 Ti 20 GB|c7210000052200000922000014220000|c7210000ffff00000922000014220000"
    "RTX 3060 3840SP|f7240000f82400000025000001250000|f7240000f824000000250000ffff0000"
    "RTX 4070 10 GB|85270000af270000bf270000c2270000|ffff0000af270000bf270000c2270000"
    "NVIDIA L40 ES|87260000af260000b0260000bf260000|87260000ffff0000b0260000bf260000"
    "RTX 5080M ES N22W-ES-A1|172c00001a2c00002b2c00002c2c0000|172c00001a2c00002b2c0000ffff0000"
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