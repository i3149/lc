#!/bin/bash

inputs=$1
python extract_features.py datasets/5k_regression_random.csv run_exp/extracted_${inputs}_.csv $inputs
