.PHONY: lint test check

# lint and test are always verbose. check is terse: suppress everything on
# success, dump the full log on any failure -- matching the intent (not
# necessarily the literal dots) of Go's/Ruby's own lint/test/check split.

# No separate linter configured for this package yet -- swift build surfaces
# warnings/errors, which is as close to "lint" as this repo currently has.
lint:
	swift build

# Verbose on purpose -- swift test's raw per-test output, tidied into a
# grouped pass/fail tree via xctidy (github.com/woodie/xctidy), the Swift
# equivalent of Go's `ginkgo-fd -r` / Ruby's `rspec -fd`.
test:
	swift test 2>&1 | xctidy -fs

# Terser than `test` on purpose: dots are a formatter freebie in ginkgo/rspec,
# not something worth emulating here -- so this just suppresses output on
# success and dumps the full log on failure, guaranteeing errors are never
# hidden regardless of swift build's/swift test's exact output format.
# Doesn't depend on `lint` as a Make prerequisite -- unlike golangci-lint/
# ktlint/standardrb, `swift build` is never quiet on success, so chaining
# through a separate always-verbose target would leak its output straight
# through check's own suppression. Both steps run inside the same wrapped
# block instead, matching xctidy's own check target.
check:
	@LOG=$$(mktemp); \
	if swift build >> "$$LOG" 2>&1 && swift test >> "$$LOG" 2>&1; then \
		echo "PASS"; \
	else \
		cat "$$LOG"; \
		rm -f "$$LOG"; \
		exit 1; \
	fi; \
	rm -f "$$LOG"
