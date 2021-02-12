#!/usr/bin/env python
# Replaces values in the XML from stdin to stdout, py2.7/py3
#
# Usage:
#   $ cat file.xml | xml_replace.py [xmlpath=value [...]] > file_mod.xml

from __future__ import print_function

import sys
from xml.etree import ElementTree as et

tree = et.parse(sys.stdin)
for item in sys.argv[1:]:
    (path, value) = item.split('=', 1)
    tree.find(path).text = value

print(et.tostring(tree.getroot()).decode())
