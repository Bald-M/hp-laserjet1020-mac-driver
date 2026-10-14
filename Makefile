.PHONY: package test

package:
	@test -n "$(SOURCE_DIR)" || { echo 'Set SOURCE_DIR to a checkout of the reference driver repository.' >&2; exit 2; }
	./scripts/build-package.sh "$(SOURCE_DIR)"

test:
	@test -n "$(SOURCE_DIR)" || { echo 'Set SOURCE_DIR to a checkout of the reference driver repository.' >&2; exit 2; }
	./tests/package-smoke.sh "$(SOURCE_DIR)"
