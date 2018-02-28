import matplotlib
import matplotlib.pyplot as plt
import numpy as np

matplotlib.rcParams.update({'font.size': 22})

results = np.genfromtxt("data.csv",delimiter=",")
results = results[:,1:].T # transpose so that results are column vectors
overhead = np.median(results[:,0::2],0)
ops = results[:,1::2]
pows = np.arange(0,21)
sizes = 2**pows

fig, ax = plt.subplots()
plt.boxplot(ops-overhead)
plt.grid(True)
ax.set_xticklabels(map(lambda p: "2^"+str(p), pows))
plt.title('Persistent Vec Apply')
plt.xlabel('size')
plt.ylabel('runtime (ns)')

plt.figure()
idxs = np.arange(20,4,-5)
for i in idxs:
  plt.hist(ops[:,i]-overhead[i])
plt.title('Histogram of Persistent Vec Apply (sizes 32^n)')
plt.legend(map(lambda s: "size "+str(s), sizes[idxs]))
plt.xlabel('runtime (ns)')
plt.ylabel('occurences')

plt.show()
