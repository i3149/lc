print __doc__

# Author: Ian Pye <ianpye@gmail.com>
# License: BSD Style.

import pylab as pl
import numpy as np
import loader as ld
import sys

from sklearn import preprocessing
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.externals import joblib

datafile = sys.argv[1]
loans = ld.load_for_predic(datafile)

clsfile = sys.argv[2]
cls = joblib.load(clsfile)

for i in range(loans.data.shape[0]):
    res = cls.predict(loans.data[i])

    if (res[0] == 200):
        print("Fully Paid,"+loans.strs[i]+",https://www.lendingclub.com/browse/loanDetail.action?loan_id=" + str(loans.ids[i]))
    elif (res[0] == 100):
        print("Charged Off,"+loans.strs[i]+",https://www.lendingclub.com/browse/loanDetail.action?loan_id=" + str(loans.ids[i]))
    else:
        print("Error: " + str(loans.ids[i]));
