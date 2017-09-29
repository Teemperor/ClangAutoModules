#!/usr/bin/env python

import os

script_dir = os.path.dirname(os.path.realpath(__file__))

unpack_code = ""

def escape_string_for_cmake(data):
  return data.replace("\\", "\\\\").replace("\"", "\\\"")

with open(script_dir + '/../ClangModules.py', 'r') as python_script:
  data = python_script.read()
  unpack_code += "#Write the python backend out:\n"
  unpack_code += "file(WRITE \"${ClangModules_UNPACK_FOLDER}/ClangModules.py\" \""
  unpack_code += escape_string_for_cmake(data)
  unpack_code += "\")\n\n"
  
for modulemap_name in os.listdir(script_dir + '/../files'):
  with open(script_dir + '/../files/' + modulemap_name, 'r') as modulemap:
    data = modulemap.read()
    unpack_code += "file(WRITE \"${ClangModules_UNPACK_FOLDER}/" + modulemap_name + "\" \""
    unpack_code += escape_string_for_cmake(data)
    unpack_code += "\")\n\n"

if len(unpack_code) == 0:
  print("Couldn't find /files directory! Script dir is " + script_dir)
  exit(1)

with open(script_dir + '/../ClangModules.in.cmake', 'r') as infile:
    data = infile.read()
    data = data.replace("##UNPACK_PLACEHOLDER", unpack_code)
    with open('ClangModules.cmake', 'w') as outfile:
      outfile.write(data)

