with open('inp.txt', 'r') as f:
    sentence = f.read()

sentence = list(sentence.split(' '))
with open('path_output', 'r') as f:
    lines = f.readlines()

for line in lines:
    if '<eps>' + '\t' in line:
        lines.remove(line)

i = sentence.index('xxx')
_, _, _, out, _ = lines[-i].split('\t')

print(out)
