
#import pylab as pl
import numpy as np
import csv
import base64
import json

LEARN_PERCENT = .75

class Bunch(dict):
    """Container object for datasets: dictionary-like object that
       exposes its keys as attributes."""

    def __init__(self, **kwargs):
        dict.__init__(self, kwargs)
        self.__dict__ = self

def load_data(filename):

    START_PLACE = 1

    data_file = csv.reader(open(filename))
    temp = next(data_file)
    n_samples = int(temp[0])
    n_features = int(temp[1])
    n_learn = int(n_samples * LEARN_PERCENT)
    n_validate = n_samples - n_learn

    data_learn = np.empty((n_learn, n_features))
    target_learn = np.empty((n_learn,), dtype=np.float)

    data_val = np.empty((n_validate, n_features))
    target_val = np.empty((n_validate,), dtype=np.float)

    info = [None]*n_validate
    strs = []

    for i, ir in enumerate(data_file):
        if (i == 0):
            strs.append(ir[START_PLACE:-1])
        else:
            if i <= n_learn:
                data_learn[i-1] = np.asarray(ir[START_PLACE:-1], dtype=np.float)
                target_learn[i-1] = np.asarray(ir[-1], dtype=np.float)
            else:                
                data_val[(i-1)-n_learn] = np.asarray(ir[START_PLACE:-1], dtype=np.float)
                target_val[(i-1)-n_learn] = np.asarray(ir[-1], dtype=np.float)
                info[(i-1)-n_learn] = json.loads(base64.b64decode(ir[0]))

    return Bunch(data_learn=data_learn, target_learn=target_learn, 
                 data_val=data_val, target_val=target_val, info=info,
                 strs=strs)

def load_for_predic(filename):
    START_PLACE = 1

    data_file = csv.reader(open(filename))
    temp = next(data_file)
    n_samples = int(temp[0])
    n_features = int(temp[1])

    data = np.empty((n_samples, n_features))
    info = [None]*n_samples

    for i, ir in enumerate(data_file):
        if i > 0:
            data[i-1] = np.asarray(ir[START_PLACE:-1], dtype=np.float)
            info[i-1] = json.loads(base64.b64decode(ir[0]))

    return Bunch(data=data, info=info)
