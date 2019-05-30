#!/bin/python

import sys

def add_space(input):
  res = ""
  for i in input:
    res += i + " "
  return res


subword_file = sys.argv[1]

subword = open(subword_file)

subword_vec = []

for word in subword:
  subword_vec.append(word.strip())

#print (subword_vec)

for raw_line in sys.stdin:

  raw_line = raw_line.replace(" ", "_ ")
  # adding space, turn "TH" into "T H "
  line = add_space(raw_line.strip())

  for w in subword_vec:
    line = line.replace(add_space(w), "  " + w + "  ")

  line = line.replace("  ", " ")
  line = line.replace("  ", " ")
  line = line.replace("  ", " ")
  line = line.replace(" _ ", "_ ")
#  line = line.replace(" _ ", "_")
  print (line)
