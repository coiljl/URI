
# URI

A regex based URI parser for Julia. Julia's existing [URIParser](github.com/JuliaWeb/URIParser.jl) does not handle shorthand URI formats very well and since its a hand written state machine its not very easy to fix. And anyway Julia has really nice regex literals so it was kinda rude not to use them in the first place.

## Installation

With [packin](//github.com/jkroso/packin): `packin add jkroso/URI`

## API

```julia
type URI
  schema::UTF8String
  username::UTF8String
  password::UTF8String
  host::UTF8String
  port::Int
  path::UTF8String
  query::UTF8String
  fragment::UTF8String
end
```

### URI(uri::String)

Will parse the `uri` string into a `URI` object

```julia
URI("//google.com").host
# => "google.com"
URI("schema://user:password@host:80/path?query=true#fragment")
# => URI("schema","user","password","host",80,"/path","query=true","fragment")
URI("tel:+123")
# => URI("tel","","","",0,"+123","","")
```

### @uri_str(str::String)

Importing this macro enables Julia's special string syntax

```julia
uri"http://google.com"
```
