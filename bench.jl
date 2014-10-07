@require "URIParser/src/parser.jl" URI => A
@require "URI" URI => B
using Benchmark

const uri = "http://test.com/a#frag"

show(compare([
  JuliaWeb() = A(uri),
  Jkroso() = B(uri),
], 30))
