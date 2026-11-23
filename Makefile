# km2: build, test, and quality gates.
# `make ci` is everything CI runs.

KAI ?= kai
KM  ?= km
KM2 := ./km2

KAI_VERSION := $(shell cat .kaikai-version)

.PHONY: build test fmt fmt-check lint toolchain gate-km gate-km2 gate diff-km corpus ci

toolchain:
	@$(KAI) --version | grep -q " $(KAI_VERSION) " || \
	  { echo "toolchain: kaikai $(KAI_VERSION) required (.kaikai-version), found: $$($(KAI) --version | head -1)"; exit 1; }

build: toolchain
	$(KAI) build -o $(KM2)

test: toolchain
	$(KAI) test

fmt:
	$(KAI) fmt .

fmt-check:
	$(KAI) fmt --check .

lint:
	$(KAI) lint .

# The reference gate, with the released km.
gate-km:
	@sh tools/quality-gate.sh $(KM)

# Dogfooding: the same gate with km2, over the commands km2 implements.
gate-km2: build
	@sh tools/quality-gate.sh $(KM2)

gate: gate-km gate-km2

# Differential tests: km and km2 on the same arguments, output compared
# byte for byte (tests/diff/*.args, one argument set per line), then each
# file of the language fixtures on its own.
diff-km: build
	@cat tests/diff/*.args | bash tools/diff-matrix.sh $(KM2)
	@bash tools/diff-km.sh --km2 $(KM2) --files fixtures/lang && echo "SAME  loc per file, fixtures/lang"

# The language corpus (tests/corpus/repos.tsv): real repositories, two per
# language, fetched once and compared with km. Not part of ci: it needs
# the network and several gigabytes.
corpus: build
	@bash tools/corpus.sh --km2 $(KM2) fetch
	@bash tools/corpus.sh --km2 $(KM2) run

ci: fmt-check lint build test gate diff-km
