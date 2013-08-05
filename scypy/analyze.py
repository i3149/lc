##
## For each class of note (A-G), compute the average distance of my predicted ROI from the actual ROI.
##
"""
 Backtest notes, looking at expected $ valuation vs actual $
 valuation. Run this monthly, charting to see how expected diverges.
 Eg, after 10 months, here's the average divergence, then after 11, ...
"""
# So, get expected, actual, class here
# Predict each run, then, sum(|p-a|) - n = diff, per class

import pylab as pl
import numpy as np
import loader as ld
import sys
import smtplib
import re
import locale

from os import listdir
from os.path import isfile, join

from datetime import datetime

from email.mime.text import MIMEText
from email.utils import COMMASPACE

from sklearn import preprocessing
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.externals import joblib

data_dir         = sys.argv[1]
input_dir        = sys.argv[2]
base_buy_level   = int(sys.argv[3])

def run_predict(loans, name, regressor, ids):

    print(name)

    X_val = loans.data_val
    y_val = loans.target_val
    X_val_scaled = preprocessing.scale(X_val)

    for i in range(X_val_scaled.shape[0]):

        res = regressor.predict(X_val_scaled[i])
        intr = loans.info[i]["int"]
        actRes = min(res[0], intr)

        if (not loans.info[i]["id"] in ids):
            ids[loans.info[i]["id"]] = (intr, [], [], y_val[i], loans.info[i]["grade"]);
        ids[loans.info[i]["id"]][1].append(res[0])
        if actRes >= 8.0:
            ids[loans.info[i]["id"]][2].append(1)
        else:
            ids[loans.info[i]["id"]][2].append(0)

def load_model(filename, regressors):
    m = re.search(r"_(.*?)_.csv\.pkl$", f)
    if m != None:
        print(input_dir+"/"+f)
        regressors[m.group(1)] = joblib.load(filename)

def load_data(filename, loans):
    m = re.search(r"_(.*?)_.csv$", f)
    if m != None:
        loans[m.group(1)] = ld.load_data(filename)

## Load up a list of loans, each with a different feature set.
input_files = [ f for f in listdir(input_dir) if isfile(join(input_dir,f)) ]
data_files = [ f for f in listdir(data_dir) if isfile(join(data_dir,f)) ]
regressors = {}
ids = {}
loans = {}

for f in data_files:
    if re.search(r"\.csv$", f):
        print(data_dir+"/"+f)
        load_data(data_dir+"/"+f, loans)

for f in input_files:
    if re.search(r"\.pkl$", f):
        load_model(input_dir+"/"+f, regressors)

for name, r in regressors.iteritems():
    run_predict(loans[name], name, r, ids)

passed = 0;

diffs = {"A": [], "B": [], "C": [], "D": [], "E": [], "F": [], "G": []}
means = {"A": [], "B": [], "C": [], "D": [], "E": [], "F": [], "G": []}
loss = {"A": [], "B": [], "C": [], "D": [], "E": [], "F": [], "G": []}
loss_pre = {"A": [], "B": [], "C": [], "D": [], "E": [], "F": [], "G": []}
gain = {"A": [], "B": [], "C": [], "D": [], "E": [], "F": [], "G": []}
numbers = {"A": 0, "B": 0, "C": 0, "D": 0, "E": 0, "F": 0, "G": 0}

seen = 0
buy = 0;

total_score = 0.0
invested = 0
passed = 0
amount_invested = 0

base_score = 0.0
base_invested = 0.0
total_seen = 0

for lid, lst in ids.iteritems():
    arr = np.array(lst[1])
    seen = seen+1

    base_score += (25 * (lst[3] / 100.))
    base_invested += 25
    total_seen+=1

    #print lid,lst[0], arr.mean(), arr.std(),lst[3],lst[4]
    if sum(lst[2]) >= base_buy_level:
        buy = buy+1
        preparts = []
        for pre in lst[1]:
            if pre >= 8.0:
                preparts.append(pre)
        
        inv = min(400, 10 * sum(lst[2]))
        total_score += (inv * (lst[3] / 100.))
        invested += 1
        amount_invested += inv

        arrpre = np.array(preparts)
        print lid,lst[0],arrpre.mean(),arrpre.std(),lst[3],lst[4]
        diffs[lst[4]].append(abs(arrpre.mean() - lst[3]))

        means[lst[4]].append(abs(arr.mean()))
        if lst[3] < 0:
            loss[lst[4]].append(lst[3])
            loss_pre[lst[4]].append(arrpre.mean())
        else:
            gain[lst[4]].append(lst[3])
        numbers[lst[4]]+=1
    else:
        passed+=1

print("Diff")
for grade, vals in iter(sorted(diffs.iteritems())):
    if (len(vals) > 0):
        arr = np.array(vals)
        print (grade, arr.mean(), arr.std(), arr.shape[0])

print("Means")
for grade, vals in iter(sorted(means.iteritems())):
    if (len(vals) > 0):
        arr = np.array(vals)
        print (grade, arr.mean(), arr.std(), arr.shape[0])

print("Loss")
for grade, vals in iter(sorted(loss.iteritems())):
    if (len(vals) > 0):
        arr = np.array(vals)
        print (grade, arr.mean(), arr.std(), arr.shape[0])

print("Loss Predicted")
for grade, vals in iter(sorted(loss_pre.iteritems())):
    if (len(vals) > 0):
        arr = np.array(vals)
        print (grade, arr.mean(), arr.std(), arr.shape[0])

print("Gain")
for grade, vals in iter(sorted(gain.iteritems())):
    if (len(vals) > 0):
        arr = np.array(vals)
        print (grade, arr.mean(), arr.std(), arr.shape[0])

print("Numbers")
print(numbers)

print("Seen: " + str(seen) + ", Buy: " + str(buy))

print("Made: $%s on %d loans, passed %d, invested %s" % (locale.format("%d", total_score, grouping=True), invested,
                                                         passed, locale.format("%d", amount_invested, grouping=True)))
if (amount_invested > 0):
    print("ROI: %.02f" % ((total_score / amount_invested)*100.))
    
print("Base: $%s on %d loans, invested %s" % (locale.format("%d", base_score, grouping=True), total_seen, 
                                              locale.format("%d", base_invested, grouping=True)))

if (base_invested > 0):
    print("BASE ROI: %.02f" % ((base_score / base_invested)*100.))
