DMD ?= dmd
LDC ?= ldc2
DUB ?= dub

all: build

build:
	$(DUB) build --build=release

debug:
	$(DUB) build --build=debug

run:
	$(DUB) run

test-sound:
	$(DUB) run -- --test-sound

clean:
	$(DUB) clean
	rm -rf bin/ .dub/

.PHONY: all build debug run test-sound clean
