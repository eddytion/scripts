with open('/home/eduard/Documents/CMS1.x_Support.csv','r') as f:
    for line in f.readlines():
        if "IMP" in line:
            print(line)
