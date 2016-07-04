#ifndef FANN_BRIDGE_H_
#define FANN_BRIDGE_H_
//#include "matacc_stub.h"
#include <fann.h>

/*
* Generate a network using the training file to which src is a path.
*/
struct fann *generate_net(const char* src);

/*
* Run a file through a network and return the output vector.
*/
fann_type *evaluate(char *filename, struct fann *ann);

/*
* Parse temporary files created by external commands
*/
float *parse_tmp();

#endif