@require "github.com/johnmyleswhite/Benchmark.jl" compare
@require "github.com/JuliaWeb/URIParser.jl" URI => A
@require "." URI => B

const uri = "http://test.com/a#frag"

compare([
  JuliaWeb() = A(uri),
  coiljl() = B(uri),
], 100) |> println
