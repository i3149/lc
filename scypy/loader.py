
#import pylab as pl
import numpy as np
import csv

VALIDATION_PERCENT = .75

class Bunch(dict):
    """Container object for datasets: dictionary-like object that
       exposes its keys as attributes."""

    def __init__(self, **kwargs):
        dict.__init__(self, kwargs)
        self.__dict__ = self

def load_data(filename):

    START_PLACE = 3

    data_file = csv.reader(open(filename))
    temp = next(data_file)
    n_samples = int(temp[0])
    n_features = int(temp[1]) - START_PLACE
    n_learn = int(n_samples * VALIDATION_PERCENT)
    n_validate = n_samples - n_learn

    data_learn = np.empty((n_learn, n_features))
    target_learn = np.empty((n_learn,), dtype=np.float)
    ids = np.empty((n_samples,), dtype=np.int)
    payoff = np.empty((n_samples,), dtype=np.float)
    cost = np.empty((n_samples,), dtype=np.float)

    data_val = np.empty((n_validate, n_features))
    target_val = np.empty((n_validate,), dtype=np.float)
    strs = []

    for i, ir in enumerate(data_file):
        if (i == 0):
            strs.append(ir[START_PLACE:-1])    
        else:
            if i < n_learn:
                data_learn[i-1] = np.asarray(ir[START_PLACE:-1], dtype=np.float)
                target_learn[i-1] = np.asarray(ir[-1], dtype=np.float)
            else:
                data_val[(i-1)-n_learn] = np.asarray(ir[START_PLACE:-1], dtype=np.float)
                target_val[(i-1)-n_learn] = np.asarray(ir[-1], dtype=np.float)
                ids[(i-1)-n_learn] = np.asarray(ir[0], dtype=np.int)
                payoff[(i-1)-n_learn] = np.asarray(ir[1], dtype=np.float)
                cost[(i-1)-n_learn] = np.asarray(ir[2], dtype=np.float)

    return Bunch(data_learn=data_learn, target_learn=target_learn, 
                 data_val=data_val, target_val=target_val, ids=ids,
                 labels=strs, payoff=payoff, cost=cost)

def load_for_predic(filename):
    START_PLACE = 3

    data_file = csv.reader(open(filename))
    temp = next(data_file)
    n_samples = int(temp[0])
    n_features = int(temp[1]) - START_PLACE

    data = np.empty((n_samples, n_features))
    ids = np.empty((n_samples,), dtype=np.int)
    strs = []

    for i, ir in enumerate(data_file):
        if i > 0:
            data[i-1] = np.asarray(ir[START_PLACE:-1], dtype=np.float)
            ids[i-1] = np.asarray(ir[0], dtype=np.int)
            strs.append(ir[1])
        #strs[i] = ir[1]
        #print(ir[1])

    return Bunch(data=data, ids=ids, strs=strs)
