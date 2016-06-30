#include <stdio.h>
#include <fcntl.h>
#include "matacc.h"

int main(int argc, char** argv) {
	if (argc < 2) {
		perror("Syntax: countglobals DVE2C_FILE TARGET_FILE\n");
		return 1;
	}
	int init_val = init(argv[1]);
	if (init_val) {
		perror("Could not load model\n");
		return 2;
	}
	FILE *target = fopen(argv[2], "a");
	if (!target) {
		perror("Could not open target file\n");
		return 3;
	}
	fprintf(target, "%s:%d\n", argv[1], get_global_count());
	fclose(target);
	return 0;
}
