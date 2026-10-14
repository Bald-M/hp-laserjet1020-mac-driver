.PHONY: source package release test

SOURCE_DIR ?= build/upstream

source:
	@if [ "$(SOURCE_DIR)" = 'build/upstream' ]; then ./scripts/fetch-source.sh; else test -d "$(SOURCE_DIR)"; fi

package: source
	./scripts/build-package.sh "$(SOURCE_DIR)"

release: package

test: source
	./tests/uri-filter.sh
	./tests/dependent-queues.sh
	./tests/uninstall-preserves-queues.sh
	./tests/package-smoke.sh "$(SOURCE_DIR)"
