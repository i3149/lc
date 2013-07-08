#print __doc__

# Author: Ian Pye <ianpye@gmail.com>
# License: BSD Style.

#import pylab as pl
import numpy as np
import loader as ld
import sys
import StringIO
import locale
import re

from os import listdir
from os.path import isfile, join
from sklearn.metrics import mean_squared_error
from sklearn import preprocessing
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.svm import SVR
from sklearn import tree
from sklearn.externals import joblib
from sklearn.feature_selection import SelectPercentile, f_classif
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.ensemble import GradientBoostingRegressor

locale.setlocale(locale.LC_ALL, '')

C               = 1.0
input_dir       = sys.argv[1]
used_class      = "L1logistic"

classifiers = {
    #'L2 logistic': LogisticRegression(C=C, penalty='l2'),
    #'Linear SVC':  SVC(kernel='linear', C=C, probability=True),
    #'DT':          tree.DecisionTreeClassifier(),
    #'GB':          GradientBoostingClassifier(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0)

    'L1logistic': LogisticRegression(C=C, penalty='l1'),
    }

regressors = {
    #'SVR_rbf':                 SVR(kernel='rbf', C=1e3, gamma=0.1),
    #'SVR_linear':                 SVR(kernel='linear', C=1e3),
    #'SVR_ploy':                 SVR(kernel='poly', C=1e3, degree=2),
    #'DT':                tree.DecisionTreeRegressor(),
    
    'Gradient_LS':       GradientBoostingRegressor(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0, loss='ls'),
    #'Gradient_LAD':      GradientBoostingRegressor(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0, loss='lad'),
    #'Gradient_HUBER':    GradientBoostingRegressor(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0, loss='huber')
    }

def run_learn(filename, loans, name, regressor, classif_name, classif, ids, lidtoyval):

    print(name + " - " + classif_name)

    X_learn = loans.data_learn
    y_learn = loans.target_learn
    X_val = loans.data_val
    y_val = loans.target_val

    X_learn_scaled = preprocessing.scale(X_learn)
    X_val_scaled = preprocessing.scale(X_val)

    #classif.fit(X_learn_scaled, loans.class_learn)
    regressor.fit(X_learn_scaled, y_learn)

    for i in range(X_val_scaled.shape[0]):
        res = regressor.predict(X_val_scaled[i])
        #status = classif.predict(X_val_scaled[i])

        inv = 0
        if (not loans.info[i]["id"] in ids):
            ids[loans.info[i]["id"]] = [];
            lidtoyval[loans.info[i]["id"]] = y_val[i]

        #print("%f %f %f" % (res[0], y_val[i], (y_val[i] - res[0])))
        #if status[0] > 0.0:
        if res[0] >= 8.0:
            inv = 25

        if inv > 0:
            ids[loans.info[i]["id"]].append(1)
        else:
            ids[loans.info[i]["id"]].append(0)

    #y_pred = classif.predict(X_val_scaled)
    #classif_rate = np.mean(y_pred.ravel() == loans.class_val.ravel()) * 100
    #print("classif_rate for %s : %f " % (classif_name, classif_rate))

    ## Save for later
    joblib.dump(regressor, filename + ".pkl") 
    joblib.dump(classif, filename + "_class.pkl") 
    
    #if (hasattr(regressor, 'feature_importances_')):
    #    feature_importance = regressor.feature_importances_
    #    print(feature_importance)

def load_data(filename):
    return ld.load_data(filename)

## Load up a list of loans, each with a different feature set.
input_files = [ f for f in listdir(input_dir) if isfile(join(input_dir,f)) ]
lidtoyval = {}
    
for index, (name, r) in enumerate(regressors.iteritems()):

    ## For each file in inputs, run
    ids = {}

    for f in input_files:
        if re.search(r"\.csv$", f):
            print(input_dir+"/"+f)
            loan = load_data(input_dir+"/"+f)
            run_learn(f, loan, name, r, used_class, classifiers[used_class], ids, lidtoyval)

    # now, for each ids
    total_score = 0.0
    invested = 0
    passed = 0
    amount_invested = 0

    base_score = 0.0
    base_invested = 0.0
    total_seen = 0

    for lid, lst in ids.iteritems():

        inv = 0
        if sum(lst) >= 3:
            inv = 10 * sum(lst)
            total_score += (inv * (lidtoyval[lid] / 100.))
            invested += 1
            amount_invested += inv
        else:
            passed+=1

        base_score += (25 * (lidtoyval[lid] / 100.))
        base_invested += 25
        total_seen+=1

    print("Made: $%s on %d loans, passed %d, invested %s" % (locale.format("%d", total_score, grouping=True), invested,
                                                             passed, locale.format("%d", amount_invested, grouping=True)))
    if (amount_invested > 0):
        print("ROI: %.02f" % ((total_score / amount_invested)*100.))

    print("Base: $%s on %d loans, invested %s" % (locale.format("%d", base_score, grouping=True), total_seen, 
                                                  locale.format("%d", base_invested, grouping=True)))

    if (base_invested > 0):
        print("BASE ROI: %.02f" % ((base_score / base_invested)*100.))
