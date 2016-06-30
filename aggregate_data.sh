#!/bin/bash

CSV=./results/dna_data.csv
rm -f $CSV
touch $CSV

OUT=./results/times
rm -f $OUT
touch $OUT

TAR=results/benchmarks.tar.gz
rm -rf $TAR
tar -cf $TAR -T /dev/null

for i in *dve;
do
	RES=results/$i-res
	#cat $SUBRES >> "$CSV"
	#tar -f $TAR --append results/$i-res/times
	echo -n "$i-res " >>$OUT
	cat results/$i-res/times >>$OUT
	echo "" >>$OUT
done
