# km2: build, test, and quality gates.
# `make ci` is everything CI runs.

KAI ?= kai
KM  ?= km
KM2 := ./km2

KAI_VERSION := $(shell cat .kaikai-version)

.PHONY: build test fmt fmt-check lint toolchain gate-km gate-km2 gate diff-km ci

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
# byte for byte (tests/diff/*.args, one argument set per line).
diff-km: build
	@cat tests/diff/*.args | bash tools/diff-matrix.sh $(KM2)

ci: fmt-check lint build test gate diff-km
