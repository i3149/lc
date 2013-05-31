#!/bin/bash

features="1,1,1,1,0,1,1,0,0,0,0,0,0"
file=InFunding2StatsNew.csv
curl -s 'https://www.lendingclub.com/fileDownload.action?file=InFunding2StatsNew.csv&type=gen' > $file
sed -i '1d' $file
perl ./process.pl zipcodes.csv $file 1 "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"  > run/in_funding.csv
python extract_features.py run/in_funding.csv run/in_funding_extracted.csv $features
python -W ignore::DeprecationWarning predict.py run/in_funding_extracted.csv classifiers/Gradient_HUBER_class.pkl

