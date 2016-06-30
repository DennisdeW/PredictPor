rm -f globals
for i in *dve2C; do
    LD_LIBRARY_PATH=. ./countglobals $i globals;
done
