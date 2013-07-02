import csv
import sys
import string

filename = sys.argv[1]
dest = sys.argv[2]
feature_set = sys.argv[3].split(",")
f = open(dest, 'w')

n_fixed = 1
n_features = 0
for feature in feature_set:
    if feature == "1":
        n_features+=1
data_file = csv.reader(open(filename))
temp = next(data_file)
temp[1] = str(n_features)
f.write(",".join(temp)+"\n")
for i, ir in enumerate(data_file):
    res = []
    index = n_fixed
    for fixed in range(0,n_fixed):
        res.append(ir[fixed])
    for feature in feature_set:
        if feature == "1":
            res.append(ir[index])
        index+=1
    res.append(ir[-2])
    res.append(ir[-1])

    f.write(",".join(res)+"\n")    

f.close()
