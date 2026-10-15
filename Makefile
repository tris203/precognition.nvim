TESTS_INIT=scripts/minimal_init.lua
TESTS_DIR=tests/
DTS_SCRIPT=tests/precognition/dts.lua
SEED_START=0
NUM_TESTS=500000
DTS_CHUNK=25000
DTS_JOBS=$(shell getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)

.PHONY: test

test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "lua MiniTest.run()" \

# Each chunk runs in a fresh nvim: a long-lived process overflows Neovim's
# copyID counter through repeated vim.fn calls and aborts. Seeds are
# independent, so chunks run in parallel across DTS_JOBS processes; the init
# runs once first so the parallel processes don't race to clone mini.test.
dts:
	@[ ${DTS_CHUNK} -gt 0 ] || { echo "DTS_CHUNK must be positive" >&2; exit 1; }; \
	[ ${DTS_JOBS} -gt 0 ] || { echo "DTS_JOBS must be positive" >&2; exit 1; }; \
	nvim --headless --noplugin -u ${TESTS_INIT} +qa || exit $$?; \
	seed=${SEED_START}; end=$$((${SEED_START} + ${NUM_TESTS})); \
	while [ $$seed -lt $$end ]; do \
		n=$$((end - seed)); \
		[ $$n -gt ${DTS_CHUNK} ] && n=${DTS_CHUNK}; \
		echo $$seed $$n; \
		seed=$$((seed + n)); \
	done | xargs -n 2 -P ${DTS_JOBS} \
		nvim \
			--headless \
			--noplugin \
			-u ${TESTS_INIT} \
			-l ${DTS_SCRIPT}
