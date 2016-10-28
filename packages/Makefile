rbm=./rbm/rbm

all: tbb-testsuite

tbb-testsuite: tbb-testsuite-linux-x86_64

tbb-testsuite-linux-x86_64: submodule-update
	$(rbm) build tbb-testsuite --target linux-x86_64

tbb-testsuite-linux-i686: submodule-update
	$(rbm) build tbb-testsuite --target linux-i686

tbb-testsuite-native-osx-x86_64: submodule-update
	$(rbm) build tbb-testsuite --target native-osx-x86_64

submodule-update:
	git submodule update --init

fetch:
	$(rbm) fetch

