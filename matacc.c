#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "matacc.h"

const int* (*get_dna_matrix)(int g);
const int* (*get_guard_nes_matrix)(int g);
const int* (*get_guard_nds_matrix)(int g);
const int* (*get_guard_may_be_coenabled_matrix)(int g);
const int* (*read_dep)(int t);
int (*get_transition_count)();
int (*get_guard_count)();

int (*get_state_variable_count)();
const char* (*get_state_variable_name)(int var);
int (*get_state_variable_type)(int var);
int (*var_type_count)();

int init(char* path) {
    void* dlHandle = dlopen(path, RTLD_LAZY);
    if (dlHandle == 0) {
    	printf("Error: dlHandle == NULL: %s\n", path);
	return 2;
    }
    get_dna_matrix = dlsym(dlHandle, "get_dna_matrix");
    get_transition_count = dlsym(dlHandle, "get_transition_count");
    get_guard_count = dlsym(dlHandle, "get_guard_count");
    get_guard_nes_matrix = dlsym(dlHandle, "get_guard_nes_matrix");
    get_guard_nds_matrix = dlsym(dlHandle, "get_guard_nds_matrix");
    get_guard_may_be_coenabled_matrix = dlsym(dlHandle, "get_guard_may_be_coenabled_matrix");
    get_state_variable_count = dlsym(dlHandle, "get_state_variable_count");
    get_state_variable_name = dlsym(dlHandle, "get_state_variable_name" );
    get_state_variable_type = dlsym(dlHandle, "get_state_variable_type" );
    read_dep = dlsym(dlHandle, "get_transition_read_dependencies");
    var_type_count = dlsym(dlHandle, "get_state_variable_type_count");
    if (!get_dna_matrix || !get_transition_count || !get_guard_nes_matrix || !get_guard_nds_matrix || !get_guard_may_be_coenabled_matrix) {
	return 1;
    }
    return 0;
}

int guard_count() { return get_guard_count(); }
int trans_count() { return get_transition_count(); }
int dna_val(int i, int j) { return get_dna_matrix(i)[j]; }
int nes_val(int i, int j) { return get_guard_nes_matrix(i)[j]; }
int nds_val(int i, int j) { return get_guard_nds_matrix(i)[j]; }
int coen_val(int i, int j) { return get_guard_may_be_coenabled_matrix(i)[j]; }
int var_count() { return get_state_variable_count(); }
const char* var_name(int var) { return get_state_variable_name(var); }
bool var_valid(int var) { return get_state_variable_type(var) == 0; }

const int get_global_count() {
	int valid_count = 0;
	for (int i = 0; i < var_count(); i++) {
		if (var_valid(i)) {
			const char* name = var_name(i);
			if (strpbrk(name, ".") == NULL) {
				valid_count++;
			}
		}
	}
	return valid_count;
}

const bool is_global(int var) {
	if (var < 0 || var >= var_count()) {
		return false;
	}
	return strpbrk(var_name(var), "." ) == NULL;
}

const int* get_global_vars() {
	int count = var_count();
	int* res = malloc(count);
	int idx = 0;
	for (int i = 0; i < count; i++) {
		if (is_global(i)) {
			res[idx++] = i;
		}
	}
	return res;
}

int global_read_dep_count() {
	int tcount = get_transition_count();
	int vcount = get_state_variable_count();
	int gcount = get_global_count();
	int global_deps = 0;
	for (int t = 0; t < tcount; t++) {
		const int* deps = read_dep(t);
		for (int v = 0; v < vcount; v++) {
			if (deps[v] && is_global(v)) {
				global_deps++;
			}
		}
	}
	return global_deps;// / (double) (tcount*vcount);
}

int main(int argc, char* argv[]) {
	if (!init(argv[1])) {
		printf("%d", var_type_count()*global_read_dep_count());
	}
}