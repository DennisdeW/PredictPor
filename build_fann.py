import re
from os import write

csv_exp = re.compile('\\w+=(\\d+\\.\\d+), clusters=(\\d+),((?:\\d+,?)*)')

def read_csv():
	data = {}
	content = ''
	with open("haskell_out") as f:
		content = f.readlines()
	for i in range(0, len(content)-1, 5):
		line = (content[i].rstrip())[:]
		d = {}
		d['dna'] = parse_line(content[i+1])
		d['nes'] = parse_line(content[i+2])
		d['nds'] = parse_line(content[i+3])
		d['coen'] = parse_line(content[i+4])
		data[line.rstrip('2C')] = d
	return data

def parse_line(line):
	res = {}
	match = csv_exp.match(line)
	if not match:
		print(line)
	groups = match.groups()
	res['frac'] = float(groups[0])
	res['ccount'] = int(groups[1])
	clusters = groups[2].split(',')
	res['clusters'] = [] if clusters == [''] else map(int, clusters)
	if len(res['clusters']) > 0:
		res['clusters'] = float(sum(res['clusters'])) / float(len(res['clusters']))
	else:
		res['clusters'] = 0
	return res

def fanndata():
	globfile = open('globals', 'r')
	benchfile = open('times', 'r')

	data = {}

	for line in globfile.readlines():
		parts = line.split(':')
		data[parts[0][:].rstrip('2C')] = {'glob': int(parts[1])}
	globfile.close()

	bench_exp = re.compile('(.*?) nopor: \\[([^,]+?), ([^\\]]+?)\\] por: \\[([^,]+?), ([^\\]]+?)\\]')

	for line in benchfile.readlines():
		match = bench_exp.match(line);
		if match is not None:
			name = match.group(1)
			name = name[:len(name)-4]
			data[name].update({'nopor': (float(match.group(2)), float(match.group(3))), 'por': (float(match.group(4)), float(match.group(5)))})
		else:
			print(line)
	benchfile.close()

	csv = read_csv()

	csv = {key: csv[key] for key in csv if key in data}
	data = {key: data[key] for key in csv if 'por' in data[key]}
	data = {key: dict(data[key].items() + csv[key].items()) for key in data}

	#print(data)
	tables = ['dna', 'nes', 'nds', 'coen']
	out = str(len(data)) + ' 13 2\n'
	for key in data:
		for table in tables:
			t = data[key][table]
			out = out + '{0} {1} {2} '.format(t['frac'], t['ccount'], t['clusters'])
		out = out + '{0}\n'.format(data[key]['glob'])
		if 'por' not in data[key]:
			print(data[key])
		out = out + '{0} {1}\n'.format(data[key]['por'][0] / data[key]['nopor'][0], data[key]['por'][1] / data[key]['nopor'][1])
	return out

if __name__ == "__main__":
	target = open("fanndata", "w")
	target.write(fanndata())
	target.close()