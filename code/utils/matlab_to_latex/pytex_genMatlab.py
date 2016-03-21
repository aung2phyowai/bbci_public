from string import Template
import os.path
import sys
import argparse
# Collection of functions to append tex templates to a tex file
def beginDoc(fileID):
	head = """\\documentclass[10pt,a4paper]{article}
\\usepackage[utf8x]{inputenc}
\\usepackage{ucs}
\\usepackage{amsmath}
\\usepackage{amsfonts}
\\usepackage{amssymb}
\\usepackage{graphicx}
\\usepackage{subfigure}
\\begin{document}\n
"""
	fileID.write(head)

def endDoc(fileID):
	close_tag = "\n\\end{document}"
	fileID.write(close_tag)

def beginFigure(fileID, centering = True):
	content="\n\\begin{figure}[h!]\n"
	if centering:
		content = content+"\\centering\n"
		fileID.write(content)
def endFigure(fileID):
	content = "\\end{figure}\n"
	fileID.write(content)
	
def addCaptionFigure(fileID, caption):
	content = "\\caption{"+caption+"}\n"
	fileID.write(content)

def addSubfigure(fileID, figname, gwidth = 0.9, caption = ''):
	content="""\\subfigure[$cap]{
\\includegraphics[width=$width\\textwidth]{$name}
\\label{}}\n"""
	s = Template(content)
	content = s.substitute(width=str(gwidth),name=figname,cap = caption)
	fileID.write(content)

def addRawText(fileID, text):
	fileID.write(text)

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description='Process some integers.')
	parser.add_argument('--filename', dest='filename', action='store',
							type=str, nargs=1)
	parser.add_argument('--type', dest='contentType', action='store')
	parser.add_argument('--properties', dest='properties', action='store',
							type=str, nargs='+', default='')
	parser.add_argument('--overwrite', dest='ow', action='store_const',
							const='overwrite', default='append')
	
	
	args = parser.parse_args()
	
	if args.ow == 'overwrite':
		fileID = open(args.filename[0],'w+')
	elif args.ow == 'append':
		fileID = open(args.filename[0], 'a+')
		
	if len(args.properties) > 0:
		keys = args.properties[0::2]
		values = args.properties[1::2]
		for i in range(len(values)):
			try:
				values[i] = float(values[i])
			except:
				pass
		spParameters= dict(zip(keys,values))
		locals()[args.contentType](fileID, **spParameters)
	else:
		locals()[args.contentType](fileID)
	
	fileID.close()
