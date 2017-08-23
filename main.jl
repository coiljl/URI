const regex = r"
  (?:([A-Za-z-+\.]+):)?  # protocol
  (?://)?
  (?:
    ([\w.]+)             # username
    (?::(\w+))?          # password
    @
  )?
  ([\w-]+(?:\.[\w-]+)*)? # host
  (?::(\d{1,5}))?        # port
  ([^?\#]*)?             # path
  (?:\?([^\#]*))?        # query
  (?:\#(.+))?            # fragment
"x

const Query = Dict{AbstractString,AbstractString}

struct URI{protocol}
  username::AbstractString
  password::AbstractString
  host::AbstractString
  port::UInt16
  path::AbstractString
  query::Query
  fragment::AbstractString
end

"""
Parse a URI from a String
"""
URI(uri::AbstractString) = begin
  m = match(regex, uri).captures
  URI{Symbol(m[1] ≡ nothing ? "" : m[1])}(
    m[2] ≡ nothing ? "" : m[2],             # username
    m[3] ≡ nothing ? "" : m[3],             # password
    m[4] ≡ nothing ? "" : m[4],             # host
    m[5] ≡ nothing ? 0 : parse(UInt16,m[5]),# port
    decode(m[6]),                           # path
    m[7] ≡ nothing ? Query() : decode_query(m[7]), # query
    m[8] ≡ nothing ? "" : m[8])             # fragment
end

"""
Parse a URI from a String while specifying the default value of each field
"""
URI(uri::AbstractString, defaults::Dict) = begin
  m = match(regex, uri).captures
  URI{Symbol(m[1] ≡ nothing ? get(defaults, :protocol, "") : m[1])}(
    m[2] ≡ nothing ? get(defaults, :username, "") : m[2],
    m[3] ≡ nothing ? get(defaults, :password, "") : m[3],
    m[4] ≡ nothing ? get(defaults, :host, "") : m[4],
    m[5] ≡ nothing ? get(defaults, :port, 0) : parse(UInt16,m[5]),
    m[6] == "" ? get(defaults, :path, "") : m[6],
    m[7] ≡ nothing ? get(defaults, :query, Query()) : decode_query(m[7]),
    m[8] ≡ nothing ? get(defaults, :fragment, "") : m[8])
end

"""
Parse a URI from a String while defaulting to the values of an existing URI
"""
URI(uri::AbstractString, defaults::URI) = begin
  m = match(regex, uri).captures
  URI{Symbol(m[1] ≡ nothing ? protocol(defaults) : m[1])}(
    m[2] ≡ nothing ? defaults.username : m[2],
    m[3] ≡ nothing ? defaults.password : m[3],
    m[4] ≡ nothing ? defaults.host : m[4],
    m[5] ≡ nothing ? defaults.port : parse(UInt16,m[5]),
    m[6] == "" ? defaults.path : m[6],
    m[7] ≡ nothing ? defaults.query : decode_query(m[7]),
    m[8] ≡ nothing ? defaults.fragment : m[8])
end

function Base.:(==){protocol}(a::URI{protocol}, b::URI{protocol})
  a.username == b.username &&
  a.password == b.password &&
  a.host == b.host &&
  a.port == b.port &&
  a.path == b.path &&
  a.query == b.query &&
  a.fragment == b.fragment
end

function Base.show(io::IO, u::URI)
  write(io, "uri\"")
  print(io, u)
  write(io, '"')
end

function Base.print{protocol}(io::IO, u::URI{protocol})
  if protocol != Symbol("")
    write(io, protocol, ':')
    string(protocol) in non_hierarchical || write(io,  "//")
  end
  if !isempty(u.username)
    write(io, u.username)
    isempty(u.password) || write(io, ':', u.password)
    write(io, '@')
  end
  write(io, u.host)
  u.port == 0 || write(io, ':', string(u.port))
  write(io, u.path)
  query = encode_query(u.query)
  isempty(query) || write(io, '?', query)
  isempty(u.fragment) || write(io, '#', u.fragment)
end

const uses_authority = ["hdfs", "ftp", "http", "gopher", "nntp", "telnet", "imap", "wais", "file", "mms", "https", "shttp", "snews", "prospero", "rtsp", "rtspu", "rsync", "svn", "svn+ssh", "sftp" ,"nfs", "git", "git+ssh", "ldap", "mailto"]
const uses_params = ["ftp", "hdl", "prospero", "http", "imap", "https", "shttp", "rtsp", "rtspu", "sip", "sips", "mms", "sftp", "tel"]
const non_hierarchical = ["gopher", "hdl", "mailto", "news", "telnet", "wais", "imap", "snews", "sip", "sips"]
const uses_query = ["http", "wais", "imap", "https", "shttp", "mms", "gopher", "rtsp", "rtspu", "sip", "sips", "ldap"]
const uses_fragment = ["hdfs", "ftp", "hdl", "http", "gopher", "news", "nntp", "wais", "https", "shttp", "snews", "file", "prospero"]

##
# Validate known URI formats
#
function Base.isvalid{protocol}(uri::URI{protocol})
  @assert protocol != Symbol("") "can not validate a relative URI"
  s = string(protocol)
  s in non_hierarchical && search(uri.path, '/') > 0 && return false # path hierarchy not allowed
  s in uses_query || isempty(uri.query) || return false              # query component not allowed
  s in uses_fragment || isempty(uri.fragment) || return false        # fragment identifier component not allowed
  s in uses_authority && return true
  return isempty(uri.username) && isempty(uri.password)              # authority component not allowed
end

"""
Enables shorthand syntax `uri"mailto:pretty@julia"`
"""
macro uri_str(str) URI(str) end

"""
Get the protocol of a `URI`
"""
protocol{x}(uri::URI{x}) = x

"""
Parse a query string
"""
function decode_query(str::AbstractString)
  query = Query()
  for elem in split(str, '&'; keep=false)
    key, value = split(elem, "=")
    query[decode(key)] = decode(value)
  end
  query
end

const hex_regex = r"%[0-9a-f]{2}"i
decode_match(hex) = Char(parse(Int, hex[2:3], 16))

"""
Replace hex string excape codes to make the uri readable again
"""
decode(str::AbstractString) = replace(str, hex_regex, decode_match)

"""
Serialize a `Dict` into a query string
"""
function encode_query(data::Dict)
  join([join(map(encode_component, kv), '=') for kv in data], '&')
end

const control = (map(UInt8, 0:parse(Int,"1f",16)) |> collect |> String) * "\x7f"
const blacklist = Set("<>\",;+\$![]'* {}|\\^`" * control)
const component_blacklist = Set("/=?#:@& ")

encode_match(substr) = string('%', uppercase(hex(substr[1], 2)))

"""
Hex encode characters which might be dangerous in certain contexts without
obfuscating it so much that it loses its structure as a uri string
"""
encode(str::AbstractString) = replace(str, blacklist, encode_match)

"""
Hex encode the structural delimeters used in `str` so that `str` can be used
as a value anywhere within a uri

```julia
query = Dict(:location => encode_component("http://httpbin.org"))
```
"""
encode_component(value) = encode_component(string(value))
encode_component(str::AbstractString) = replace(str, component_blacklist, encode_match)
