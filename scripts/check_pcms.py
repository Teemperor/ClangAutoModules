#!/usr/bin/env python
import sys

print("working_pcms: " + sys.argv[1])
working_pcms = set(open(sys.argv[1]).readlines())
print("found_pcms: " + sys.argv[2])
found_pcms = set(open(sys.argv[2]).readlines())

missing_pcms = working_pcms.difference(found_pcms)
new_pcms = found_pcms.difference(working_pcms)

if len(new_pcms):
    print("New working PCMS, add them to " + sys.argv[1] + " please:")
    print("--START OF LIST--")
    for pcm in new_pcms:
        print(pcm.strip())
    print("---END OF LIST---")

if len(missing_pcms):
    print("Missing PCMS:")
    print("--START OF LIST--")
    for pcm in missing_pcms:
      print(pcm.strip())
    print("---END OF LIST---")
    exit(1)
else:
    print("Found all PCMS!")
