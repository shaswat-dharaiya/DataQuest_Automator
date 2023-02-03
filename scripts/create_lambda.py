lines = []
with open("./s2quest.py", "r+") as f:
    lines = f.readlines()
    idx = 20
    lines.insert(idx, "def lambda_handler(event, context):")
    for i in range(idx+1,len(lines)):
        lines[i] = '\t'+lines[i]
    f.writelines([])
    f.close()

with open("./s2quest.py", "r+") as f:
    f.writelines(lines)
    f.close()

