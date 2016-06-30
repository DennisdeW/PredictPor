import re
import sys
import numpy as np
import matplotlib.pyplot as plt

LOW_1 = 2.8
HIGH_1 = 3.8
LOW_2 = 1.4
HIGH_2 = 1.8
GOOD_THRESH = 0.8
MAYBE_THRESH = 1.0

def get_advice(out1, out2):
	return out1 >= LOW_1 and out1 <= HIGH_1 and out2 >= LOW_2 and out2 <= HIGH_2

def por_was_good(entry):
	t = entry['time']
	return 1 if t <= GOOD_THRESH else 0 if t <= MAYBE_THRESH else -1

def plot(data, nr, field):	
	x = [data[key]['fann'][nr] for key in data if get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == 1]
	y = [data[key][field] for key in data if get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == 1]
	plt.scatter(x, y, color='green')
	x = [data[key]['fann'][nr] for key in data if get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == 0]
	y = [data[key][field] for key in data if get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == 0]
	plt.scatter(x, y, color='yellow')
	x = [data[key]['fann'][nr] for key in data if get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == -1]
	y = [data[key][field] for key in data if get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == -1]
	plt.scatter(x, y, color='red')	

	x = [data[key]['fann'][nr] for key in data if not get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == 1]
	y = [data[key][field] for key in data if not get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == 1]
	plt.scatter(x, y, color='purple')
	x = [data[key]['fann'][nr] for key in data if not get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == 0]
	y = [data[key][field] for key in data if not get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == 0]
	plt.scatter(x, y, color='orange')
	x = [data[key]['fann'][nr] for key in data if not get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == -1]
	y = [data[key][field] for key in data if not get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == -1]
	plt.scatter(x, y, color='blue')

def score(data, key):
	advice = get_advice(data[key]['fann'][0],data[key]['fann'][1])
	

data = {}
benchfile = open('times', 'r')
bench_exp = re.compile('(.*?) nopor: \\[([^,]+?), ([^\\]]+?)\\] por: \\[([^,]+?), ([^\\]]+?)\\]')

for line in benchfile.readlines():
	match = bench_exp.match(line);
	if match is not None:
		name = match.group(1)
		realname = name[:len(name)-4]
		data[realname]={'time': float(match.group(4)) / float(match.group(2)), 'state': float(match.group(5)) / float(match.group(3))}
		port = float(match.group(4))
		noport = float(match.group(2))
		data[realname]['bench'] = (port, noport)
	else:
		print(line)
benchfile.close()

fannfile = open(sys.argv[1],'r')
exp = re.compile('\\.\\./dve/(.*?)2C=([^:]+?):(.*?)\n')
for line in fannfile.readlines():
	match = exp.match(line)
	name = match.group(1)
	pair=(-1,-1)
	try:
		pair = (float(match.group(2)), float(match.group(3)))
	except ValueError:
		print(line)	
	if name in data:
		data[name]['fann'] = pair
		adv = get_advice(pair[0], pair[1])
		rating = por_was_good(data[name])
		base_score = 100 * ((data[name]['bench'][1] - data[name]['bench'][0]) / data[name]['bench'][0])
		if rating == 0:
			base_score = base_score / (2 if adv else -2)
		elif (rating == 1 and not adv) or (rating == -1 and adv):
			base_score = -base_score
		data[name]['score'] = base_score
			
fannfile.close()

data = {key:data[key] for key in data if 'fann' in data[key]}
do_annotate = False

fig = plt.figure()
ax = fig.add_subplot(321)
ax.set_title('Time 1')
ax.set_yscale('log')
plot(data, 0, 'time')
if do_annotate:
	for key in data:
		plt.annotate(key, xy=(data[key]['fann'][0], data[key]['time']))

ax = fig.add_subplot(222)
ax.set_title('Time 2')
ax.set_yscale('log')
plot(data, 1, 'time')
if do_annotate:
	for key in data:
		plt.annotate(key, xy=(data[key]['fann'][1], data[key]['time']))

ax = fig.add_subplot(223)
ax.set_title('States 1')
ax.set_yscale('log')
plot(data, 0, 'state')
if do_annotate:
	for key in data:
		plt.annotate(key, xy=(data[key]['fann'][0], data[key]['time']))

ax = fig.add_subplot(224)
ax.set_title('States 2')
ax.set_yscale('log')
plot(data, 1, 'state')
if do_annotate:
	for key in data:
		plt.annotate(key, xy=(data[key]['fann'][1], data[key]['time']))

for key in data:
	print('{}: {}'.format(key, data[key]['score']))
scores = [data[key]['score'] for key in data]
print('total: ' + str(sum(scores)))
print('max: ' + str(max(scores)))
print('min: ' + str(min(scores)))
print('avg: ' + str(sum(scores) / len(scores)))
print('maybe: {}%'.format(100 * (float(len([data[key] for key in data if get_advice(data[key]['fann'][0],data[key]['fann'][1])])) / float(len(data)))))
print('good advice: {}%'.format(100 * (1.0-(float(len([data[key] for key in data if get_advice(data[key]['fann'][0],data[key]['fann'][1]) and por_was_good(data[key]) == -1])) / float(len(data))))))
plt.show()