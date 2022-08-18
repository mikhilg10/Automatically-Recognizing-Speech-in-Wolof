import sys

inp = sys.argv[1:]
sentence = ["<s>"] + inp + ["</s>"]

with open('inp.txt', 'w') as f:
    f.write(' '.join(sentence))

wrd_set = set()
f_ent = []

with open('L.vocab', 'r') as f:
    lines = f.readlines()
    for line in lines:
        word, val = line.split()
        wrd_set.add(word)

for i, word in enumerate(sentence):
    word = word.strip().lower()
    if (word == 'xxx'):
        for all_words in wrd_set:
            if all_words in ['<eps>', '<s>', '</s>', '<unk>']:
                continue
            else:
                ent  = "{} {} {} {}\n".format(i, i+1, all_words, all_words)
                f_ent.append(ent)
    else:
        if word in wrd_set:
            ent = "{} {} {} {}\n".format(i, i+1, word, word)
        else:
            ent = "{} {} <unk> <unk>\n".format(i, i+1)
        f_ent.append(ent)

final_state = len(sentence)
f_ent.append("{}\n".format(final_state))

with open('F.txt', 'w') as f:
    f.writelines(f_ent)


