#PredictPor
Prerequisites:

Install FANN: http://leenissen.dk/fann/wp/download/
(GHC is probably already installed, but only required if you want to change matacc.hs)
Python, including NumPy: http://numpy.org/
If you want to use evaluate_network.py, additionally install the Matplotlib module: http://matplotlib.org/users/installing.html

To complile predictpor:

gcc -o predictpor -O3 predictpor.c -lfann


To compile hmatacc:

gcc --shared -fPIC --std=c99  -o libmatacc.so matacc.c -ldl

ghc -o hmatacc -O matacc.hs -L. -lmatacc -optl-Wl,-rpath,'$ORIGIN'


To compile countglobals:

gcc -o countglobals countglobals.c -L. -lmatacc


To build a network:

Collect the relevant .dve files in a folder, and place getdata.py and aggregate_benchmarks.sh there as well.

(If divine and/or dve2lts-mc are NOT installed to one of the usual directories (like /usr/bin), then edit the second-to-last line of getdata.py to point to the correct executables)

Run 'python getdata.py', this may take a long time.

Copy or move the 'times' file from the new 'results' folder, and place it where you want to store the network.

Run countglobals.sh in the model folder and put the 'globals' file in the same place as the 'times' file.

Run build_fann.py in the folder which has 'globals'  and 'times', this generates 'fann_data'.

Run predictpor build <path to fann_data> <destination file>


To use build_net.sh:

Place the .dve files in the 'models' folder.
Running build_net.sh will generate 'network', this may take a while.

In either case, building a network with only a few models will produce poor results


To evaluate a model:

Run ./predictpor eval <path-to-dve2C> <path-to-network-file>.
With the original network (default_network), the ranges of outputs for which the result is MAYBE are:

	2.8 <= First Output <= 3.8

	1.4 <= Second Output <= 1.8

In new networks, these bounds will have to be discovered manually, perhaps with the aid of evaluate_network.py
