line = "DANUDADANUNUDANUDANUNUDADADADANUDANUNUDADADANUNUDANUNUDADADADANUDANUNUNUDADANUDADANUDADADADADANUDANUNUDANUDADANUDANUDADANUDADANUDANUNUDANUNUNUDADANUNUDADADANUNUDANUNUDADANUDANUDANUNUNUDADANUDADANUNUDADADANUNUDANUNUDADADADANUDANUNUNUDANUDADA"
n=2
words = ([line[i:i+n] for i in range(0, len(line), n)])
for i in words:
    if "DA" in i:
        print(0)
    else:
        print(1)