#!/usr/bin/env python

import os
import sys

def sizeof_fmt(num, suffix='B'):
    for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi', suffix)


has_error = False
checked_pcms = 0
size_limit = 500000000
size_limit_str = sizeof_fmt(size_limit)
percentage_bar_limit = 20
filename_size = 40

print("Checking PCM sizes")

for root, subdirs, files in os.walk("."):
    for filename in files:
        if filename.endswith(".pcm"):
            checked_pcms += 1
            full_path = os.path.join(root, filename)
            file_size = os.path.getsize(full_path)
            percentage = file_size / float(size_limit)
            percentage_filled = int(percentage * percentage_bar_limit)
            if percentage_filled > percentage_bar_limit:
                percentage_filled = percentage_bar_limit

            percentage_empty = percentage_bar_limit - percentage_filled
            percentage_bar = "[" + ("=" * percentage_filled)
            percentage_bar += (" " * percentage_empty) + "] "
            percentage_bar += sizeof_fmt(file_size).rjust(8)


            sys.stdout.write(filename[:-4].ljust(filename_size) + percentage_bar)
            if file_size > size_limit:
                print(" ERROR: Bigger than size limit of " + size_limit_str.rjust(8) + "!")
                has_error = True
            else:
                print(" OK!")
if has_error:
    exit(1)
if checked_pcms < 5:
    print("Only found " + str(checked_pcms) + " PCMs. Probably something in the script is broken!")
    exit(1)
