#!/bin/bash

perl ./process.pl zipcodes.csv LoanStatsTest.csv 0 > datasets/5k_regression.csv
./randomize.sh datasets/5k_regression
python learn.py datasets/5k_regression_random.csv classifiers/
