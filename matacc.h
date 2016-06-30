#ifndef MATACC_H_
#define MATACC_H_

#include <stdbool.h>			

extern int dna_val(int i, int j);		//Do-Not-Accord
extern int nes_val(int i, int j);		//Neccessary Enabling Set
extern int nds_val(int i, int j); 	//Neccessary Disabling Set
extern int coen_val(int i, int j); 	//May be coenabled
extern int trans_count();			//Transitions
extern int guard_count();		//Guards

extern int var_count();
extern const char* var_name();
extern bool var_valid();
extern const int* get_global_vars();
extern const int get_global_count();

extern int init(char* path);

#endif
