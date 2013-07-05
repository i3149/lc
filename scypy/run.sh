#!/bin/bash

inputs=$1
perl ./process.pl LoanStatsTest.csv 0 > datasets/5k_regression.csv
./randomize.sh datasets/5k_regression
for i in `head -3 no_funded_tenners`; do ./run_multi.sh $i; done
python learn.py run_exp
