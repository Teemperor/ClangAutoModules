#!/usr/bin/env python

import os

script_dir = os.path.dirname(os.path.realpath(__file__))

unpack_code = ""

for modulemap_name in os.listdir(script_dir + '/files'):
  with open(script_dir + '/files/' + modulemap_name, 'r') as modulemap:
    data=modulemap.read().replace("##UNPACK_PLACEHOLDER", unpack_code)
    data = data.replace("\"", "\\\"")
    unpack_code += "file(WRITE \"${ClangModules_UNPACK_FOLDER}/" + modulemap_name + "\" \""
    unpack_code += data
    unpack_code += "\")\n\n"

if len(unpack_code) == 0:
  print("Couldn't find /files directory! Script dir is " + script_dir)
  exit(1)

with open(script_dir + '/ClangModules.in.cmake', 'r') as infile:
    data = infile.read()
    data = data.replace("##UNPACK_PLACEHOLDER", unpack_code)
    with open('ClangModules.cmake', 'w') as outfile:
      outfile.write(data)

