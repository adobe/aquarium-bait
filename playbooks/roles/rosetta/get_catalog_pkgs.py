#!/usr/bin/env python3
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# This script automated the rosetta distributives download for all the known versions of MacOS
# It will store the downloaded archive & metadata into "./rosetta" directory and output the
# yaml data to put to your override for rosetta_packages var of rosetta ansible role if you need.
#
# Usage:
#   $ ./get_catalog_pkgs.py

import os
import gzip
from urllib import request
import xml.etree.ElementTree as ET
import hashlib

ROSETTA_CATALOG_URL='https://swscan.apple.com/content/catalogs/others/index-rosettaupdateauto-1.sucatalog.gz'

with request.urlopen(ROSETTA_CATALOG_URL) as response:
    with gzip.GzipFile(fileobj=response) as uncompressed:
        tree = ET.parse(uncompressed)
#tree = ET.parse('catalog.plist')
root = tree.getroot()

def nextSibling(el, tag, text):
   '''Returns the next element after the found tag with value of text in provided element'''
   items = list(el.iter())
   for i, child in enumerate(items):
       if child.tag == tag and child.text == text:
           return items[i+1]

# Getting and processing the catalog items
data = root.findall('./dict/dict/dict')
for child in data:
    post_date = nextSibling(child, 'key', 'PostDate').text
    macos_build_version = nextSibling(nextSibling(child, 'key', 'ExtendedMetaInfo'), 'key', 'BuildVersion').text
    urls = []
    packages = nextSibling(child, 'key', 'Packages')
    for pkg in packages:
        urls.append(nextSibling(pkg, 'key', 'URL').text)

    file_prefix = f'rosetta/RosettaUpdateAuto_{macos_build_version}'

    # Reading the existing file metadata to check if we need to download new version
    # Metadata format:
    #   <date>\n
    #   <sha256sum>\n
    existing_sum = ''
    try:
        with open(file_prefix+'.meta', 'r') as fd:
            existing_date = fd.readline().strip()
            existing_sum = fd.readline().strip()
            if existing_date == post_date:
                # Skipping download since post date are the same
                continue
    except:
        pass

    # We should not put much stress on the Apple servers, so downloading here one-by-one
    for url in urls:
        # Calculating checksum while downloading the file
        file_sum = hashlib.sha256()
        with request.urlopen(url) as resp, open('.tmp.RosettaUpdateAuto.pkg', 'wb') as fd:
            while True:
                data = resp.read(8192)
                if not data:
                    break
                file_sum.update(data)
                fd.write(data)

        file_checksum = file_sum.hexdigest()
        if file_checksum == existing_sum:
            os.remove('.tmp.RosettaUpdateAuto.pkg')
            continue

        # (Re)placing the package and metadata to the desired location
        try:
            os.remove(file_prefix+'.pkg')
        except:
            os.makedirs(os.path.dirname(file_prefix), exist_ok=True)
        os.rename('.tmp.RosettaUpdateAuto.pkg', file_prefix+'.pkg')

        # Writing new metadata file
        with open(file_prefix+'.meta', 'w') as fd:
            fd.write(post_date+'\n')
            fd.write(file_checksum+'\n')

        # Displaying data to put into the rosetta ansible role var file
        print(f'  {macos_build_version}:')
        print(f'    - rel: {file_prefix}.pkg')
        print(f'      mtd: {file_prefix}.meta')
        print(f'      sum: sha256:{file_checksum}')
