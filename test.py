new_list =[]
for a in range(1,10):
    for b in str(a):
        if int(b) % 2 != 0:
            break
    else:
        new_list.append(a)
for x in new_list:
    print(x)
print("=============================================")
print(new_list.__len__())
print(len(new_list))

counter = 0
for i in new_list:
    counter+=1
print("counter: " + str(counter))
