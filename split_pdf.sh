#!/usr/bin/sh
# Splits pages in half horizontally.
set -x
set -e

# Uses pdfinfo, pdfcrop, bc, grep, awk
pdf_name="$1"
if [ -z "pdf_name" ]
then
    >&2 echo "Please provide a pdf to split in half"
    exit 1
fi

# Get dimensions in pt using pdfinfo and grep
width=$(pdfinfo "$pdf_name" | grep "Page size:" | awk '{printf $3}')

# For whatever reason if the pdf is not found the set -e doesnt catch it
if [ -z "$width" ]
then
    >&2 echo "pdf not found"
    exit 1
fi

# Convert to bp with bc to 6dp, use awk to print the leading 0
# Divide by the magic number to convert and by 2 to get half the page
crop_bp=$(echo "scale=4; $width/1.00374/2" | bc | awk '{printf "%f", $1}')

echo "$width"

# Create one with the left pages (odd)
pdfcrop --margins "0 0 -$crop_bp 0" "$pdf_name" "/tmp/odd.$pdf_name"

# Create one with the right pages (even)
pdfcrop --margins "-$crop_bp 0 0 0" "$pdf_name" "/tmp/even.$pdf_name"

# Interweave them
pdftk odd="/tmp/odd.$pdf_name" even="/tmp/even.$pdf_name" shuffle odd even output "out.$pdf_name"

# Remove tmp files

set +e
