#!/usr/bin/env python
#
# This script converts an xml file into JUnit xml format. JUnit is a testing
# framework supported by CI tools such as Jenkins to display test results.
#
# Run the script by supplying the file path to an xml file and an output
# directory path as arguments.
#
import xml.etree.ElementTree as ET
import sys,os

# input parameters
input_filepath = sys.argv[1]
output_dirpath = sys.argv[2]
skip_test = (sys.argv[3] == "--skip_tests")

# create output filename
input_name = input_filepath[input_filepath.find("memcheck"):input_filepath.rfind("/")]
output_filename = output_dirpath + "/"+ input_name
if not output_filename.endswith('.xml'):
    output_filename += '.xml'

# read errors in document
doc = ET.parse(input_filepath)
errors = doc.findall('.//error')

test_type = "error"
plural = "s"
if (skip_test):
    test_type = "skipped"
    plural = ""

out = open(output_filename,"w")
out.write('<?xml version="1.0" encoding="UTF-8"?>\n')
if len(errors) == 0:
    out.write('<testsuite name="valgrind" tests="1" '+test_type+''+plural+'="'+str(len(errors))+'">\n')
    out.write('    <testcase classname="valgrind-memcheck" name="'+str(input_name)+'"/>\n')
else:
    out.write('<testsuite name="valgrind" tests="'+str(len(errors))+'" '+test_type+''+plural+'="'+str(len(errors))+'">\n')
    errorcount=0
    for error in errors:
        errorcount += 1

        kind = error.find('kind')
        what = error.find('what')
        if what == None:
            what = error.find('xwhat/text')

        stack = error.find('stack')
        frames = stack.findall('frame')

        for frame in frames:
            fi = frame.find('file')
            li = frame.find('line')
            if fi != None and li != None:
               break

        if fi != None and li != None:
            out.write('    <testcase classname="valgrind-memcheck" name="'+str(input_name)+' '+str(errorcount)+' ('+kind.text+', '+fi.text+':'+li.text+')">\n')
        else:
            out.write('    <testcase classname="valgrind-memcheck" name="'+str(input_name)+' '+str(errorcount)+' ('+kind.text+')">\n')
        out.write('        <'+test_type+' type="'+kind.text+'">\n')  
        out.write('  '+what.text+'\n\n')

        for frame in frames:
            ip = frame.find('ip')
            fn = frame.find('fn')
            fi = frame.find('file')
            li = frame.find('line')
	    if fn != None:
                bodytext = fn.text
            else:
                bodytext = "unknown function name" 
            bodytext = bodytext.replace("&","&amp;")
            bodytext = bodytext.replace("<","&lt;")
            bodytext = bodytext.replace(">","&gt;")
            if fi != None and li != None:
                out.write('  '+ip.text+': '+bodytext+' ('+fi.text+':'+li.text+')\n')
            else:
                out.write('  '+ip.text+': '+bodytext+'\n')
        out.write('        </'+test_type+'>\n')
        out.write('    </testcase>\n')

out.write('</testsuite>\n')
out.close()

