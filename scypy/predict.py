#!/usr/bin/python

# Author: Ian Pye <ianpye@gmail.com>
# License: BSD Style.

import pylab as pl
import numpy as np
import loader as ld
import sys
import smtplib
import re

from os import listdir
from os.path import isfile, join

from datetime import datetime

from email.mime.text import MIMEText
from email.utils import COMMASPACE

from sklearn import preprocessing
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.externals import joblib

fromaddr         = f = open(".from").read().strip()
toaddrs          = f = open(".to").read().strip().split(",")
subject          = 'LendingClubBuy (' + datetime.today().strftime("%d/%m/%Y %H:%M") + ")"
username         = fromaddr  
password         = f = open(".passwd").read().strip()
prefix           = "https://www.lendingclub.com/browse/loanDetail.action?loan_id="
data_dir         = sys.argv[1]
input_dir        = sys.argv[2]

def run_predict(loans, name, regressor, ids):

    print(name)
    X_scaled = preprocessing.scale(loans.data)

    for i in range(X_scaled.shape[0]):

        if (not loans.info[i]["id"] in ids):
            ids[loans.info[i]["id"]] = [];

        res = regressor.predict(X_scaled[i])
        intr = loans.info[i]["int"]
        actRes = min(res[0], intr)

        inv = 0

        if actRes >= 8.0:
            inv = 25
            #print("%f %f %f %s" % (res[0], actRes, intr, loans.info[i]["id"]))            

        if inv > 0:
            ids[loans.info[i]["id"]].append(1)
        else:
            ids[loans.info[i]["id"]].append(0)

def load_model(filename, regressors):
    m = re.search(r"_(.*?)_.csv\.pkl$", f)
    if m != None:
        print(input_dir+"/"+f)
        regressors[m.group(1)] = joblib.load(filename)

def load_data(filename, loans):
    m = re.search(r"_(.*?)_.csv$", f)
    if m != None:
        loans[m.group(1)] = ld.load_for_predic(filename)

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
buy = []
for lid, lst in ids.iteritems():
    inv = 0
    if sum(lst) >= 6:
        inv = 10 * sum(lst)
        buy.append(("* Buy: " + prefix + lid + " @ $" + str(inv) + " -- " + str(lst),sum(lst)))
    else:
        passed+=1

server = smtplib.SMTP('smtp.gmail.com:587')  
server.starttls()  
server.login(username,password)  

buy.sort(key=lambda tup: tup[1], reverse=True)

msg = MIMEText("You should\n" + '\n'.join([x[0] for x in buy]))
msg['Subject'] = subject
msg['From'] = fromaddr
msg['To'] = COMMASPACE.join(toaddrs)

server.sendmail(fromaddr, toaddrs, msg.as_string())  
server.quit()  

print("Found " + str(len(buy)) + " Loans -- " + datetime.today().strftime("%d/%m/%Y %H:%M"))
