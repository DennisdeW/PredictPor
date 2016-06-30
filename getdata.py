import os
from shutil import rmtree
from os.path import isdir, walk
from operator import add, div
import subprocess
import re

STATE_RE = re.compile('.*?Explored (\\d+) states (\\d+) .*?')
TIME_RE = re.compile('.*?exploration time (\\d+\\.\\d+) sec.*?')

def process(divine, dve2lts, name):
	res = 'results/' + name + '-res'
	if isdir(res):
		rmtree(res)
	os.mkdir(res)
	os.chdir(res)

	subprocess.call([divine, 'compile', '-l', '../../' + name])
	model = res + '/' + name + '2C'
	os.chdir('../..')
	times = open(res + '/times', 'w')
	outres = (0.0, 0.0)
	porres = (0.0, 0.0)
	for i in range(0, 3):
		out = open(res + '/' + str(i) + '.nopor', 'a')
		porout = open(res + '/' + str(i) + '.por', 'a')
		subprocess.call(dve2lts + ' --threads=1 ' + model, stderr=out, stdout=out, shell=True)
		subprocess.call(dve2lts + ' --threads=1 --por=heur ' + model, stderr=porout, stdout=porout, shell=True)
		#os.system(dve2lts + ' --threads=1 ./' + model + ' >' + out)
		#os.system(dve2lts + ' --threads=1 --por=heur ./' + model + ' >' + porout)
		t1 = parse(open(res + '/' + str(i) + '.nopor', 'r'))
		t2 = parse(open(res + '/' + str(i) + '.por', 'r'))
		if t1 and t2:
			outres = map(add, outres, t1)
			porres = map(add, porres, t2)
	outres = map(div, outres, (3.0,3.0))
	porres = map(div, porres, (3.0,3.0))
	times.write('nopor: ' + str(outres) + ' por: ' + str(porres))

def defproc(name):
	process('divine', 'dve2lts-mc', name)

def parse(lines):
	time = 0.0
	state = 0.0
	for line in lines:
		time_m = TIME_RE.match(line)
		if time_m:
			time = float(time_m.group(1))
		state_m = STATE_RE.match(line)
		if state_m:
			state = int(state_m.group(1))
	return (time, state)

def procfolder(divine, dve2lts, dir):
	for filename in os.listdir(dir):
		if '.dve' in filename and not '2C' in filename and not 'cpp' in filename:
			process(divine, dve2lts, filename)

subprocess.call(['mkdir', 'results'])
procfolder('divine', 'dve2lts-mc', '.')
subprocess.call('./aggregate_data.sh')
