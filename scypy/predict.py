# Author: Ian Pye <ianpye@gmail.com>
# License: BSD Style.

import pylab as pl
import numpy as np
import loader as ld
import sys
import smtplib

from datetime import datetime

from email.mime.text import MIMEText
from email.utils import COMMASPACE

from sklearn import preprocessing
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.externals import joblib

fromaddr = f = open(".from").read().strip()
toaddrs  = f = open(".to").read().strip().split(",")
subject = 'LendingClubBuy (' + datetime.today().strftime("%d/%m/%Y %H:%M") + ")"
username = fromaddr  
password = f = open(".passwd").read().strip()
prefix = "https://www.lendingclub.com/browse/loanDetail.action?loan_id="

datafile = sys.argv[1]
loans = ld.load_for_predic(datafile)

clsfile = sys.argv[2]
cls = joblib.load(clsfile)

X_scaled = preprocessing.scale(loans.data)

print ("Running, from: " + fromaddr)
print (toaddrs)

buy = []

for i in range(X_scaled.shape[0]):
    res = cls.predict(X_scaled[i])
    inv = 0;
    if res[0] >= 40.0:
        inv = 50
    elif res[0] >= 39.0:
        inv = 47
    elif res[0] >= 37.0:
        inv = 46
    elif res[0] >= 35.0:
        inv = 40
    elif res[0] >= 25.0:
        inv = 30
    elif res[0] >= 20.0:
        inv = 25

    if inv > 0:
        buy.append("* Buy: " + prefix + str(loans.ids[i]) + " @ $" + str(inv))

server = smtplib.SMTP('smtp.gmail.com:587')  
server.starttls()  
server.login(username,password)  

msg = MIMEText("You should\n" + '\n'.join(buy))
msg['Subject'] = subject
msg['From'] = fromaddr
msg['To'] = COMMASPACE.join(toaddrs)

server.sendmail(fromaddr, toaddrs, msg.as_string())  
server.quit()  

print("Found " + str(len(buy)) + " Loans -- " + datetime.today().strftime("%d/%m/%Y %H:%M"))
