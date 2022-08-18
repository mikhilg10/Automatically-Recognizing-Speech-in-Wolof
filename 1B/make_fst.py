import sys

inp = sys.argv[1:]

w1,w2,w3,w4 = [w.strip().lower() for w in inp]

wrd_set = set()
with open('L.vocab','r') as f:
    lines = f.readlines()
    for line in lines:
        w, _ = line.split()
        if w not in ['<eps>', '<s>', '</s>', '<unk>']:
            wrd_set.add(w.strip())

if w1 not in wrd_set:
    w1 = '<unk>'
if w2 not in wrd_set:
    w2 = '<unk>'
if w3 not in wrd_set:
    w3 = '<unk>'
if w4 not in wrd_set:
    w4 = '<unk>'

f_ent = []
f_ent.append("{} {} <s> <s>\n".format(0, 1))
for w in wrd_set:
    if w not in [w1,w2]:
        f_ent.append("{} {} {} {}\n".format(1, 1, w, w))

f_ent.append("{} {} {} {}\n".format(1, 2, w1, w1))
for w in wrd_set:
    if w not in [w2]:
        f_ent.append("{} {} {} {}\n".format(2, 2, w, w))

f_ent.append("{} {} {} {}\n".format(2, 3, w2, w2))
for w in wrd_set:
    f_ent.append("{} {} {} {}\n".format(3, 3, w, w))

f_ent.append("{} {} {} {}\n".format(3, 4, '</s>', '</s>'))
f_ent.append('4\n')

with open('first.txt', 'w') as f:
    f.writelines(edges)

f_ent = []
f_ent.append("{} {} <s> <s>\n".format(0, 1))
for w in wrd_set:
    if w not in [w3,w4]:
        f_ent.append("{} {} {} {}\n".format(1, 1, w, w))

f_ent.append("{} {} {} {}\n".format(1, 2, w3, w3))
f_ent.append("{} {} {} {}\n".format(1, 3, w4, w4))

for w in wrd_set:
    if w not in [w4]:
        f_ent.append("{} {} {} {}\n".format(2, 2, w, w))
for w in wrd_set:
    if w not in [w3]:
        f_ent.append("{} {} {} {}\n".format(3, 3, w, w))
        
f_ent.append("{} {} {} {}\n".format(2, 4, w4, w4))
f_ent.append("{} {} {} {}\n".format(3, 5, w3, w3))

for w in wrd_set:
    f_ent.append("{} {} {} {}\n".format(4, 4, w, w))
for w in wrd_set:
    f_ent.append("{} {} {} {}\n".format(5, 5, w, w))

f_ent.append("{} {} {} {}\n".format(5, 6, '</s>', '</s>'))
f_ent.append("{} {} {} {}\n".format(4, 6, '</s>', '</s>'))
f_ent.append('6\n')

with open('second.txt', 'w') as f:
    f.writelines(f_ent)
