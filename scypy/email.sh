#!/bin/bash

features="1,1,1,1,0,1,1,0,0,0,0,0,0"
new_file=InFunding2StatsNew.csv.new
old_file=InFunding2StatsNew.csv
curl -s 'https://www.lendingclub.com/fileDownload.action?file=InFunding2StatsNew.csv&type=gen' > $new_file
sed -i '1d' $new_file

new_sum=`md5sum $new_file | cut -f '1' -d ' '`
old_sum=`md5sum $old_file | cut -f '1' -d ' '`

if [ "$new_sum" != "$old_sum" ]
then
    rm $old_file
    mv $new_file $old_file
    perl ./process.pl zipcodes.csv $old_file 1 "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"  > run/in_funding.csv
    python extract_features.py run/in_funding.csv run/in_funding_extracted.csv $features
    python -W ignore::DeprecationWarning predict.py run/in_funding_extracted.csv classifiers/Gradient_HUBER_class.pkl    
else
    echo "NOOP"
fi




