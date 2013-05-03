#!/bin/bash

file=${1}.csv
randomized=${1}_random.csv
temp=${1}_temp.csv
echo $file $randomized

if [ ! -f "$file" ]; then
    echo "Error: " $file "does not exist"
    exit
fi 

## Take the first two lines to the new file
head -2 $file > $randomized

## Take off these same two lines
sed '1,2d' $file > $temp
sort --random-sort $temp >> $randomized
rm $temp
