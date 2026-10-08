TESTS_INIT=scripts/minimal_init.lua
TESTS_DIR=tests/
DTS_SCRIPT=tests/precognition/dts.lua
SEED_START=0
NUM_TESTS=500000
DTS_CHUNK=50000

.PHONY: test

test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "lua MiniTest.run()" \

# Each chunk runs in a fresh nvim: a long-lived process overflows Neovim's
# copyID counter through repeated vim.fn calls and aborts.
dts:
	@[ ${DTS_CHUNK} -gt 0 ] || { echo "DTS_CHUNK must be positive" >&2; exit 1; }; \
	seed=${SEED_START}; end=$$((${SEED_START} + ${NUM_TESTS})); \
	while [ $$seed -lt $$end ]; do \
		n=$$((end - seed)); \
		[ $$n -gt ${DTS_CHUNK} ] && n=${DTS_CHUNK}; \
		nvim \
			--headless \
			--noplugin \
			-u ${TESTS_INIT} \
			-l ${DTS_SCRIPT} $$seed $$n || exit $$?; \
		seed=$$((seed + n)); \
	done
