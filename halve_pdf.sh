#!/usr/bin/sh
# Splits pages in half horizontally.
# Uses pdfinfo, pdfcrop, pdftk, bc, grep, awk

# set -x
set -e

pdf_name="$1"
if [ -z "pdf_name" ]
then
    >&2 echo "Please provide a pdf to split in half"
    exit 1
fi

# Get dimensions in pt using pdfinfo and grep

# Pass through cat -v to show non-printing characters.
# Necessary because, for example, converting a png to a pdf with convert from
# ImageMagick adds a NUL char at the end of the title, making grep not work
width=$(pdfinfo "$pdf_name" | cat -v | grep "Page size:" | awk '{printf $3}')

# For whatever reason if the pdf is not found the set -e doesnt catch it
if [ -z "$width" ]
then
    >&2 echo "pdf not found"
    exit 1
fi

# Convert to bp with bc to 6dp, use awk to print the leading 0
# Divide by the magic number to convert and by 2 to get half the page
crop_bp=$(echo "scale=6; $width/1.00374/2" | bc | awk '{printf "%f", $1}')

echo "The next part might take a bit"

# Create one with the left pages (odd)
echo "Creating tmp pdf with only right sides..."
pdfcrop --margins "0 0 -$crop_bp 0" "$pdf_name" "/tmp/odd.$pdf_name"

# Create one with the right pages (even)
echo "Creating tmp pdf with only left sides..."
pdfcrop --margins "-$crop_bp 0 0 0" "$pdf_name" "/tmp/even.$pdf_name"

# Logic for output filename
if [ -z "$2" ]
then
    output_fn="out.$pdf_name"
else
    output_fn="$2"
fi

echo "Saving them to $output_fn"

# Interweave them
pdftk ODD="/tmp/odd.$pdf_name" EVEN="/tmp/even.$pdf_name" shuffle ODD EVEN output "$output_fn"

# Remove tmp files
rm "/tmp/odd.$pdf_name" "/tmp/even.$pdf_name"

set +e
