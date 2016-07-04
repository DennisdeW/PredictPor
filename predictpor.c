	#include <fann.h>
#include <fann_data.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <fts.h>
#include <regex.h>
#include <argp.h>

#include "predictpor.h"


#define BINARY_TARGET 1

regex_t _stateex, _timeex;

struct fann *generate_net(const char* src) {
	struct fann *f = fann_create_standard(3, 13, 13, 2);
	const char* file = src;

	struct fann_train_data *t = fann_read_train_from_file(file);
	fann_set_scaling_params(f, t, 0, 1, 0, 1);
	fann_scale_train(f, t);
	fann_set_activation_function_output(f, FANN_LINEAR);
	fann_train_on_data(f, t, 100000, 1000, .005f);

	return f;
}

fann_type *evaluate(char* filename, struct fann *ann) {
	char* cmd = calloc(1000, 1);
	strcat(cmd, "./hmatacc ");
	strcat(cmd, filename);
	strcat(cmd, " tmp");
	if (system(cmd) != 0) {
		perror("error computing parameters");
	}
	float *data = parse_tmp();
	free(cmd);
	(void)(system("rm -f tmp")+1);
	fann_scale_input(ann, data);

	return fann_run(ann, data);
}

float *parse_tmp() {
	FILE *tmp = fopen("tmp", "r");
	char buf[200];
	if (fgets(buf, 200, tmp) == NULL) {
		perror("Unable to parse input data");
	}
	char *tok = strtok(buf, " ");
	float *res = calloc(sizeof(float) * 13,1);
	int i = 0;
	int c = 0;
	while (tok) {
		if (++c > 2) {
			res[i++] = atof(tok);
		}
		tok = strtok(NULL, " ");
	}
	return res;
}

void generate(const char* src, const char* dst) {
	struct fann *f = generate_net(src);
	fann_save(f, dst);
	fann_destroy(f);
}

int main(int argc, char *argv[]) {
	char* mode = argv[1];
	if (!strcmp(mode, "build")) {
		//build
		char* source = argv[2];
		char* dest = argv[3];
		generate(source, dest);
	} else {
		//eval
		char* net = argv[3];
		char* model = argv[2];
		struct fann *f = fann_create_from_file(net);
		fann_type *res = evaluate(model, f);
		fann_descale_output(f, res);
		printf("%f:%f\n", res[0], res[1]);
		fann_destroy(f);
	}
}
