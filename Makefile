DEPOT_TOOLS_PATH := $(shell realpath ./depot_tools)
export PATH := $(DEPOT_TOOLS_PATH):$(PATH)

.NOTPARALLEL:
.PHONY : build pull clean get_source test

.DEFAULT_GOAL := build

SHELL := /bin/bash

DIRS=lucet-spectre sfi-spectre-testing

CURR_DIR := $(shell realpath ./)

bootstrap:
	sudo apt -y install curl cmake
	if [ ! -x "$(shell command -v rustc)" ] ; then \
		curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y; \
	fi
	if [ ! -d /opt/wasi-sdk/ ]; then \
		wget https://github.com/CraneStation/wasi-sdk/releases/download/wasi-sdk-8/wasi-sdk_8.0_amd64.deb -P /tmp/ && \
		sudo dpkg -i /tmp/wasi-sdk_8.0_amd64.deb; \
	fi
	if [ ! -d /opt/binaryen/ ]; then \
		wget https://github.com/WebAssembly/binaryen/releases/download/version_90/binaryen-version_90-x86_64-linux.tar.gz -P /tmp/ && \
		sudo mkdir /opt/binaryen &&
		sudo tar -xzf /tmp/binaryen-version_90-x86_64-linux.tar.gz -C /opt/binaryen &&
		sudo mv /opt/binaryen/binaryen-version_90 /opt/binaryen/bin; \
	fi

	@echo "--------------------------------------------------------------------------"
	@echo "Attention!!!!!!:"
	@echo ""
	@echo "Installed new packages."
	@echo "You need to reload the bash env before proceeding."
	@echo ""
	@echo "Run the command:"
	@echo "source ~/.profile"
	@echo "and run 'make' to build the source"
	@echo ""
	@echo "--------------------------------------------------------------------------"
	touch ./bootstrap

lucet-spectre:
	git clone git@github.com:shravanrn/lucet-spectre.git $@

sfi-spectre-testing:
	git clone git@github.com:shravanrn/sfi-spectre-testing.git $@

get_source: $(DIRS)

install_deps: get_source
	touch ./install_deps

pull: get_source
	git pull
	cd lucet-spectre && git pull --recurse-submodules
	cd sfi-spectre-testing && git pull --recurse-submodules

build: install_deps pull
	cd lucet-spectre && cargo build
	$(MAKE) -C sfi-spectre-testing build

test: build
	$(MAKE) -C sfi-spectre-testing test
	$(MAKE) -C lucet-spectre/benchmarks/shootout 


clean:
	-cd lucet-spectre && cargo clean
	-$(MAKE) -C sfi-spectre-testing clean
