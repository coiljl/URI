dependencies: index.jl
	@kip $<
	@ln -snf ../.. $@/coiljl/URI

test: dependencies
	@jest test.jl

.PHONY: test
