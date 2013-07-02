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

import numpy as np
import loader as ld
import sys
import StringIO
import locale

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

filename = sys.argv[1]
dest = sys.argv[2]
loans = ld.load_data(filename)
X_learn = loans.data_learn
y_learn = loans.target_learn
X_val = loans.data_val
y_val = loans.target_val
C = 1.0

X_learn_scaled = preprocessing.scale(X_learn)
X_val_scaled = preprocessing.scale(X_val)

n_features = X_learn.shape[1]
if n_features == 0:
    exit(0)

classifiers = {
    'L1 logistic': LogisticRegression(C=C, penalty='l1'),
    'L2 logistic': LogisticRegression(C=C, penalty='l2'),
    'Linear SVC':  SVC(kernel='linear', C=C, probability=True),
    'DT':          tree.DecisionTreeClassifier(),
    'GB':          GradientBoostingClassifier(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0)
    }

regressors = {
    'Gradient_LS':       GradientBoostingRegressor(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0, loss='ls'),
    'Gradient_LAD':      GradientBoostingRegressor(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0, loss='lad'),
    'Gradient_HUBER':    GradientBoostingRegressor(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0, loss='huber')
    }

for index, (name, regressor) in enumerate(regressors.iteritems()):

    classif = classifiers['GB']
    regressor.fit(X_learn_scaled, y_learn)
    classif.fit(X_learn_scaled, loans.class_learn)

    total_score = 0.0
    invested = 0
    passed = 0
    amount_invested = 0

    base_score = 0.0
    base_invested = 0.0
    total_seen = 0

    diffs = {"A": [], "B": [], "C": [], "D": [], "E": [], "F": [], "G": []}
    loss = {"A": [], "B": [], "C": [], "D": [], "E": [], "F": [], "G": []}
    gain = {"A": [], "B": [], "C": [], "D": [], "E": [], "F": [], "G": []}
    numbers = {"A": 0, "B": 0, "C": 0, "D": 0, "E": 0, "F": 0, "G": 0}

    print(name)

    for i in range(X_val_scaled.shape[0]):
        res = regressor.predict(X_val_scaled[i])
        pclass = classif.predict(X_val_scaled[i])
        intr = loans.info[i]["int"]
        actRes = min(res[0], intr)

        #if abs(intr - res[0]) < 3.0 and y_val[i] < 0:
            #print (", ".join([loans.info[i]["id"], str(intr), str(res[0]), str(y_val[i]), loans.info[i]["grade"]]), str(pclass[0]), str(loans.class_val[i]))

        if (actRes > 8.0 and pclass[0] > 0.0):
            diffs[loans.info[i]["grade"]].append(abs(actRes - y_val[i]))
            loss[loans.info[i]["grade"]].append(min(y_val[i] - actRes, 0))
            
            gain[loans.info[i]["grade"]].append(y_val[i])
            numbers[loans.info[i]["grade"]]+=1
        total_seen+=1
    
    print(loans.strs)
    if (hasattr(regressor, 'feature_importances_')):
        feature_importance = regressor.feature_importances_
        print(feature_importance)

    print("Diff")
    for grade, vals in iter(sorted(diffs.iteritems())):
        if (len(vals) > 0):
            arr = np.array(vals)
            print (grade, arr.mean(), arr.std())

    print("Loss")
    for grade, vals in iter(sorted(loss.iteritems())):
        if (len(vals) > 0):
            arr = np.array(vals)
            print (grade, arr.mean(), arr.std())

    print("Gain")
    for grade, vals in iter(sorted(gain.iteritems())):
        if (len(vals) > 0):
            arr = np.array(vals)
            print (grade, arr.mean(), arr.std())

    print("Numbers")
    print(numbers)
