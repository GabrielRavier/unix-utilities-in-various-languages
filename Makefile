# Makefile for the unix-utilities-in-various-languages project

# Makefiles are prettier like this
ifeq ($(origin .RECIPEPREFIX), undefined)
    $(error This Make does not support .RECIPEPREFIX. \
        Please use GNU Make 3.82 or later)
endif
.RECIPEPREFIX = >

# Use bash as the shell
SHELL := bash

# ...And use strict flags with it to make sure things fail if a step in there
# fails
.SHELLFLAGS := -eu -o pipefail -c

# Delete the target file of a Make rule if it fails - this guards against
# broken files
.DELETE_ON_ERROR:

# --warn-undefined-variables: Referencing undefined variables is probably
# wrong...
# --no-builtin-rules: I'd rather make my own rules myself, make, thanks :)
# Note: --warn-undefined-variables is removed here because CMake screws it up
MAKEFLAGS += --no-builtin-rules

.PHONY: bin/mv

all: bin/mv bin/cat

bin/mv:
> +cmake -S mv -B mv/build
> +cmake --build mv/build

bin/cat: cat/cat.f90
> @mkdir -p bin
> gfortran -ggdb3 cat/f90getopt.F90 cat/cat.f90 -o bin/cat -Jcat -fdec

test: all
> ./tests/run_tests.sh

clean:
> rm -rf ./bin/ ./mv/build/ ./cat/cat.mod
