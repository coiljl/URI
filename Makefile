
dependencies: dependencies.json
	@packin install --folder $@ --meta $<
	@ln -snf .. $@/URI

test: dependencies
	@$</jest/bin/jest test

.PHONY: test
