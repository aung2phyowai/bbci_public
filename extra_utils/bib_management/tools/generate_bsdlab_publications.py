import pybtex.database.input.bibtex
import pybtex.database.output.bibtex
import pybtex.database

import re
import glob
import codecs
import datetime
import sys
import os

# Remove the bibtex code from the code
def cleanbib(s):
	accent = {'\"':"uml",'\'':"acute",'`':"grave",'^':"circ","~":"tilde"}
	s = re.sub("<[aA].*?>","",s)
	s = re.sub("[\{\}]","",s)
	s = re.sub("\~|\\\\ "," ",s)
	s = re.sub("--","-",s)
	s = re.sub("\\\\ss","ss",s) #  &szlig;
	s = re.sub("\\\\&","&",s)
	s = re.sub("\\\\([\\\"\\\'\\`\\~\\^])([auoAUOuUiInN])",lambda m: "&" + m.group(2) + accent[m.group(1)] + ";",s)
	s = re.sub("\\\\.","",s)
	s = re.sub("\`\`|\'\'","\"",s)
	s = re.sub("--","-",s)
	return s

def html(b):
	print(b['key'])
	top,bottom = [],[]
	if 'author' in b: top.append("<span class='pubauthor'>%s</span>" % b['author'])
	if 'title' in b: top.append("<span class='pubtitle'>%s</span>" % b['title'])
	if 'note' in b: top.append("<span class='pubnote'>%s</span>" % b['note'])
	if 'conference' in b: bottom += [b['conference']]
	elif 'journal' in b: bottom += [b['journal']]
	elif 'booktitle' in b: bottom += [b['booktitle']]
	elif 'institution' in b: bottom += [b['institution']]
	elif 'school' in b: bottom += [b['school']]
	if 'publisher' in b: bottom += [b['publisher']]
	volref = ""
	if 'volume' in b: volref += b['volume']
	if 'volume' in b and 'number' in b: volref += "(%s)" % b['number']
	if 'volume' in b and 'pages' in b:  volref += ":%s" % b['pages']
	if volref != "": bottom += [volref]
	if 'year' in b: bottom += [b['year']]

	template = """
		<p>
		<span class='title'>%s</span><br>
		<span class='journal'>%s</span> 
		<span class='publinks'>%s %s %s</span>
		</p>"""
	return template% (
		cleanbib(", ".join(top)),
		cleanbib(", ".join(bottom)),
		"[<a href='%s'>pdf</a>]" % b['pdf'] if 'pdf' in b else "",
		"[<a href='%s'>ps</a>]"  % b['ps']  if 'ps'  in b else "",
		"[<a href='%s'>url</a>]"  % b['url']  if 'url'  in b else "",
		)

PATH = "../bib_files/"

fo = codecs.open( "tmp.bib", "w", "utf-8")
for s in [
	'macros/journal_macros.bib',
	'macros/journal_macros_short.bib',
	'macros/journal_macros_short_conf_long.bib',
	'macros/journal_macros_database.bib',
	'bsdlab.bib'
	]:
  fi = codecs.open(PATH + s, "r", "utf-8")
  fo.write(fi.read())
  fi.close()
fo.close()
# ----------------------------------------------------------------
# Write bib files
# ----------------------------------------------------------------

##writer = pybtex.database.output.bibtex.Writer()
##bdata = pybtex.database.input.bibtex.Parser().parse_file('tmp.bib')
##for x in bdata.entries:
##	writer.write_file(pybtex.database.BibliographyData(entries={x:bdata.entries[x]}),"bib/%s.bib.txt"%x)

##	# Hack to correct pybtex bug #########
##	f = open("bib/%s.bib.txt"%x,'r');
##	s = f.read()
##	s = re.sub("{\\\\\'\'([aAoOuUeEiI])}",lambda m: "{\\\"" + m.group(1) + "}",s);
##	s = re.sub("\\\\\'\'([aAoOuUeEiI])",  lambda m: "{\\\"" + m.group(1) + "}",s);
##	f.close()
##	f = open("bib/%s.bib.txt"%x,'w'); f.write(s); f.close()
##	############

# ----------------------------------------------------------------
# Create html pages
# ----------------------------------------------------------------

for page in ["bsdlab"]:

	parser = pybtex.database.input.bibtex.Parser()

	bdata = parser.parse_file('tmp.bib')

	B = []
	for x in bdata.entries:

		def trim(name,y):
			name = cleanbib(name)
			if y != 'last' and name != "": return name[:1] # + "."
			else: return name + " "

		fields = bdata.entries[x].fields
		fields['key'] = x
		fields['type'] = bdata.entries[x].type
		print(fields['type'],fields['key'])

		if 'author' in bdata.entries[x].persons:
			for p in bdata.entries[x].persons['author']:
				if re.match("K.-*R|Klaus-R.*",p.get_part_as_text('first')): p._middle=['Robert'] # Make Klaus initials consistent

		for persontype in ['editor','author']:
			if persontype in bdata.entries[x].persons:
				fields['author'] = ", ".join([
					"".join([
						trim(p.get_part_as_text(y),y) for y in ['last', 'first', 'middle', 'prelast']
					]).strip() for p in bdata.entries[x].persons[persontype]
				])
				fields['listauthors'] =  [cleanbib(y.get_part_as_text('last')) for y in bdata.entries[x].persons[persontype]]

		B.append(fields)


	# ---------------------------------
	# Generation of the HTML document
	# ---------------------------------
	
	groupsscan = [str(i) for i in range(datetime.datetime.now().year,2012,-1)]
	groups = [str(i) for i in range(datetime.datetime.now().year,2012,-1)]
	print(groups)
	content = ""
	for year in groupsscan[:]:
		for x in B:
			print(x['key'])
			print(x['year'])
		Byear = filter(lambda x: year == x['year'],B)
		if len(Byear) > 0: content += "\n<h2><a name='%s'>%s</a></h2>\n" % (year,year)
		for cat in ['book','article','incollection','inproceedings','techreport','phdthesis']:
			Bf = filter(lambda x: x['type'] == cat,Byear)
			Bf = sorted(Bf,key=lambda x: x['listauthors'][0])
			if len(Bf) > 0: content += "\n<h3>%s</h3>\n"%{'book':'Books','phdthesis':'PhD theses','article':'Journal papers','incollection':'Book chapters','inproceedings':'Conference papers','techreport':'Technical reports'}[cat]
			pubyear = [html(b) for b in Bf]
			content += ("\n".join(pubyear))
	

	htmlcode = """
	<!DOCTYPE php>
	<html lang = "en">
	<head>
	  <title>Brain State Decoding Lab</title>
	<style type="text/css"><!-- @import url(http://www.bsdlab.uni-freiburg.de/assets/css/base-cachekey8075.css); --></style>
	<style type="text/css"><!-- @import url(http://www.bsdlab.uni-freiburg.de/assets/css/publications.css); --></style>
	<style type="text/css"><!-- @import url(http://www.bsdlab.uni-freiburg.de/assets/css/flyoutnav-cachekey6798.css); --></style>
	<style type="text/css" media="all"><!-- @import url(http://www.bsdlab.uni-freiburg.de/assets/css/content_types.css); --></style>
	<style type="text/css" media="all"><!-- @import url(http://www.bsdlab.uni-freiburg.de/assets/css/calendar-system.css); --></style>
	<meta charset = "UTF-8" />

	</head>
	<body>
	<div>
	<body dir="ltr">
	<?php include("../include/menu.php"); ?>

	<!-- start content -->
	<div id="content">
	<h1 id="parent-fieldname-title" class="documentFirstHeading">
	Publications
	</h1>
	<div class="header">
	<nav>[%s]</nav>
	<div class="noteauthority">
	Note that the PDFs available on this web page are the authors' draft versions of the respective papers.<br/>The authoratative versions must be retrieved from the publisher.
	</div>
	</div>%s</div>
	</div>
	
	<!-- end content -->
                                                    
	<?php include("../include/right_content.php"); ?>
	<?php include("../include/footer.php"); ?>
	</body>
	</html>"""%(" | ".join(map(lambda x: "<a href='#%s'>%s</a>"%(x,x),groups)),content)
	htmlcode = htmlcode.encode('utf-8')
	open({'bsdlab':'index.php'}[page],'w').write(htmlcode)
os.remove("tmp.bib")
