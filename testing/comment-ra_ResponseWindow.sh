#!/bin/bash
# Replace string s1 with string s2 in all files recursively in the current directory


s1="ra_ResponseWindow"
s2="#ra_ResponseWindow"

# Use find to locate all files and sed to perform the replacement in-place
# Use null-delimited find to safely handle all filenames
find . -maxdepth 1 -type f -print0 | while IFS= read -r -d '' file; do
    gsed -i "s/$s1/$s2/g" "$file"
    echo "Updated: $file"
done

echo "Replacement complete."   
