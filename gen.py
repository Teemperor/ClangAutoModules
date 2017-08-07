#!/usr/bin/env python

import os

unpack_code=""

for modulemap_name in os.listdir('files'):
  with open('files/' + modulemap_name, 'r') as modulemap:
    data=modulemap.read().replace("##UNPACK_PLACEHOLDER", unpack_code)
    data = data.replace("\"", "\\\"")
    unpack_code += "file(WRITE \"${ClangModules_UNPACK_FOLDER}/" + modulemap_name + "\" \""
    unpack_code += data
    unpack_code += "\")\n\n"



with open('ClangModules.in.cmake', 'r') as infile:
    data = infile.read()
    data = data.replace("##UNPACK_PLACEHOLDER", unpack_code)
    with open('ClangModules.cmake', 'w') as outfile:
      outfile.write(data)

