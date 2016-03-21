import string
import csv
import StringIO
fbib = open('bsdlab.bib', 'r')
fconverted = open('out.bib','w')

fcollection = open('2013JCRTITLES.txt','r')
reader = csv.reader(fcollection,delimiter='\t')
lnames = []
snames = []
for l, s, country, science, sscience in reader:
    lnames.append(l)
    snames.append(s)
fcollection.close()

def replace_name(old_name, conv_type = 'ls'):
    if conv_type == 'ls':
        in_names = lnames
        out_names = snames
    elif conv_type == 'sl':
        in_names = snames
        out_names = lnames
    else:
        print('No conversion available for "'+old_name+'"')
        return old_name
        
    for idx, rn in enumerate(in_names):
        rn_match = rn.translate(None, string.whitespace)
        rn_match = rn_match.lower()
        if old_name in rn_match:
            return out_names[idx].rstrip('\n')
    print('No conversion available for "'+old_name+'"')
    return old_name
            
for line in fbib:
    modified_line = line.translate(None, string.whitespace)
    if 'journal=' in modified_line:
        m_line = modified_line.replace('{','').lower()
        m_line = m_line.replace('}','')
        m_line = m_line.replace('"','')
        idx_a = m_line.find('=')
        idx_b = m_line.find(',')
        jname = m_line[idx_a+1:idx_b]
        new_name = replace_name(jname)
        if new_name == jname:
            nline = line
        else:
            nline = 'journal="'+new_name+'"\n'
        fconverted.write(nline)
    else:
        fconverted.write(line)
        
fbib.close()
fconverted.close()
