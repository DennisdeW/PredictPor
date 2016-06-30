#!/bin/bash

rm -rf tmp
mkdir tmp

cd models

echo "Preparing Files"
for i in *.dve; do
    cp $i ../tmp
done
cd ..

cp getdata.py tmp
cp aggregate_data.sh tmp
cp countglobals.sh tmp
cp build_fann.py tmp
cp countglobals tmp
cp libmatacc.so tmp
cp hmatacc.sh tmp
cp hmatacc tmp

cd tmp

for i in $(ls); do
    if [[ $i =~ .*\.dve$ ]]; then
    	echo $i
	divine compile -l $i
    fi
done

echo "Running Benchmarks"
python getdata.py
cp results/times .

echo "Computing Data"
./countglobals.sh
./hmatacc.sh

echo "Building Network"
python build_fann.py
../predictpor build fanndata network
cp network ..
echo "Cleaning Up"
cd ..
rm -rf tmp
echo "Done"
