#print __doc__

# Author: Ian Pye <ianpye@gmail.com>
# License: BSD Style.

#import pylab as pl
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

#X_learn_scaled = X_learn
#X_val_scaled = X_val

X_learn_scaled = preprocessing.scale(X_learn)
X_val_scaled = preprocessing.scale(X_val)

n_features = X_learn.shape[1]
if n_features == 0:
    exit(0)

regressors = {
    #    'SVR_rbf':                 SVR(kernel='rbf', C=1e3, gamma=0.1),
    #    'SVR_linear':                 SVR(kernel='linear', C=1e3),
    #   'SVR_ploy':                 SVR(kernel='poly', C=1e3, degree=2),
    #    'DT':                tree.DecisionTreeRegressor(),
    'Gradient_LS':       GradientBoostingRegressor(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0, loss='ls'),
    'Gradient_LAD':      GradientBoostingRegressor(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0, loss='lad'),
    'Gradient_HUBER':    GradientBoostingRegressor(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0, loss='huber')
    }

for index, (name, classifier) in enumerate(regressors.iteritems()):

    classifier.fit(X_learn_scaled, y_learn)

    total_score = 0.0
    invested = 0
    passed = 0
    amount_invested = 0

    base_score = 0.0
    base_invested = 0.0
    total_seen = 0

    print(name)

    for i in range(X_val_scaled.shape[0]):
        res = classifier.predict(X_val_scaled[i])

        inv = 0

        #print("%f %f %f" % (res[0], y_val[i], (y_val[i] - res[0])))
        if res[0] >= 17.0:
            inv = 50
        elif res[0] >= 16.0:
            inv = 47
        elif res[0] >= 15.0:
            inv = 46
        elif res[0] >= 12.0:
            inv = 40
        elif res[0] >= 11.0:
            inv = 30
        elif res[0] >= 10.0:
            inv = 25

        if inv > 0:
            total_score += (inv * (y_val[i] / 100.))
            invested+=1
            amount_invested += inv
            #print(loans.ids[i])
        else:
            passed+=1

        base_score += (loans.info[i]["cost"] * (y_val[i] / 100.))
        base_invested += loans.info[i]["cost"]
        total_seen+=1

    #y_pred = classifier.predict(X_val_scaled)
    #classif_rate = np.mean(y_pred.ravel() == y_val.ravel()) * 100
    #print("classif_rate for %s : %f " % (name, classif_rate))

    ## Save for later
    joblib.dump(classifier, dest + name + '_class.pkl') 

    #if (name == "DT"):
    #    with open("/tmp/dt.dot", 'w') as f:
    #        f = tree.export_graphviz(classifier, out_file=f)
        
    # make importances relative to max importance
    #feature_importance = 100.0 * (feature_importance / feature_importance.max())
    #print(name)
    
    print(loans.strs)
    if (hasattr(classifier, 'feature_importances_')):
        feature_importance = classifier.feature_importances_
        print(feature_importance)

    print("Made: $%s on %d loans, passed %d, invested %s" % (locale.format("%d", total_score, grouping=True), invested,
                                                             passed, locale.format("%d", amount_invested, grouping=True)))

    if (amount_invested > 0):
        print("ROI: %.02f" % ((total_score / amount_invested)*100.))

    print("Base: $%s on %d loans, invested %s" % (locale.format("%d", base_score, grouping=True), total_seen, 
                                                             locale.format("%d", base_invested, grouping=True)))

    if (base_invested > 0):
        print("BASE ROI: %.02f" % ((base_score / base_invested)*100.))
