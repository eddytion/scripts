import matplotlib.pyplot as plt
import pandas as pd
pd.core.common.is_list_like = pd.api.types.is_list_like

cpu_all = []
with open('/tmp/test.nmon','r') as f:
    for line in f:
        if "CPU" in line and "Wait" not in line:
                cpu_all.append(line.rstrip('\n'))


array = []
for i in cpu_all:
    array.append(i.split(',')[2] + "," + i.split(',')[3] + "," + i.split(',')[4] + "," + i.split(',')[5])

for i in array:
    plt.plot(i)

