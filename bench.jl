@require "." URI => B
import URIParser.URI
using Benchmark

const uri = "http://test.com/a#frag"

compare([
  JuliaWeb() = URI(uri),
  coiljl() = B(uri),
], 100) |> println
