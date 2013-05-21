#!/bin/bash

inputs=$1
#perl ./process.pl zipcodes.csv LoanStatsTest.csv 0 $inputs > datasets/5k_regression.csv
#./randomize.sh datasets/5k_regression
python extract_features.py datasets/5k_regression_random.csv datasets/5k_extracted.csv $inputs
python learn.py datasets/5k_extracted.csv classifiers/
