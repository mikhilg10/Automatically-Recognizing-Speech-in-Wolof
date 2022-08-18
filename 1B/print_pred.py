final_sent = []
with open('path_output','r') as f:
    lines = f.readlines()
    for line in lines:
        if '<s>' in line or '</s>' in line or '<eps>' in line:
            continue
        line_split = line.split()
        if len(line_split) != 5:
            continue
        _,_,p,_,_ = line_split
        final_sent.append(p.strip())

print(' '.join(final_sent[::-1]))
