TESTS_INIT=tests/minimal.lua
TESTS_DIR=tests/
DTS_SCRIPT=tests/precognition/dts.lua
SEED_START=0
NUM_TESTS=500000

.PHONY: test

test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }" \

dts:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-l ${DTS_SCRIPT} ${SEED_START} ${NUM_TESTS} \
