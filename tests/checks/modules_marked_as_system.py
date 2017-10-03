#!/usr/bin/env python

import os

error = False

def check_modulemap(file_path):
  global error
  has_top_level_module = False
  with open(file_path) as f:
    line_num = 0
    for line in f:
      line_num += 1
      if line.startswith("module"):
        has_top_level_module = True
        if not "[system]" in line:
          error = True
          prefix = file_path + ":" + str(line_num)
          print(prefix.ljust(30, ' ') + ": Module not marked as [system]: " + line.rstrip())
  if not has_top_level_module:
    print("Found no top level module (i.e. without indentation before) in file " + file_path)
    error = True

for f in os.listdir('files'):
  if f.endswith(".modulemap"):
    check_modulemap("files/" + f)

if error:
  print("Found non-system modules. Add comment with '//no [system] because XZY'")
  print("to the affected line or indent.")
  exit(1)
