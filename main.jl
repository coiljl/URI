@require "github.com/coiljl/querystring" Query

const regex = r"
  (?:([A-Za-z-+\.]+):)? # protocol
  (?://
    (?:
      (\w+)             # username
      (?::(\w+))?       # password
      @
    )?
    ([^:/]+)?           # host
    (?::(\d+))?         # port
  )?
  ([^?\#]*)?            # path
  (?:\?([^\#]*))?       # query
  (?:\#(.+))?           # fragment
"x

immutable URI{protocol}
  username::AbstractString
  password::AbstractString
  host::AbstractString
  port::Integer
  path::AbstractString
  query::Query
  fragment::AbstractString
end

"""
Parse a URI from a String
"""
URI(uri::AbstractString) = begin
  m = match(regex, uri).captures
  URI{symbol(m[1] ≡ nothing ? "" : m[1])}(
    m[2] ≡ nothing ? "" : m[2],             # username
    m[3] ≡ nothing ? "" : m[3],             # password
    m[4] ≡ nothing ? "" : m[4],             # host
    m[5] ≡ nothing ? 0 : parse(UInt16,m[5]),# port
    m[6],                                   # path
    m[7] ≡ nothing ? Query() : Query(m[7]), # query
    m[8] ≡ nothing ? "" : m[8])             # fragment
end

"""
Parse a URI from a String while specifying the default value of each field
"""
URI(uri::AbstractString, defaults::Dict) = begin
  m = match(regex, uri).captures
  URI{symbol(m[1] ≡ nothing ? get(defaults, :protocol, "") : m[1])}(
    m[2] ≡ nothing ? get(defaults, :username, "") : m[2],
    m[3] ≡ nothing ? get(defaults, :password, "") : m[3],
    m[4] ≡ nothing ? get(defaults, :host, "") : m[4],
    m[5] ≡ nothing ? get(defaults, :port, 0) : parse(UInt16,m[5]),
    m[6] == "" ? get(defaults, :path, "") : m[6],
    m[7] ≡ nothing ? get(defaults, :query, Query()) : Query(m[7]),
    m[8] ≡ nothing ? get(defaults, :fragment, "") : m[8])
end

"""
Create a URI based of of `uri` but some fields modified
"""
URI{default_protocol}(uri::URI{default_protocol};
                      protocol=nothing,
                      username=nothing,
                      password=nothing,
                      host=nothing,
                      port=nothing,
                      path=nothing,
                      query=nothing,
                      fragment=nothing) =
  URI{protocol == nothing ? default_protocol : symbol(protocol)}(
    username == nothing ? uri.username : username,
    password == nothing ? uri.password : password,
    host == nothing ? uri.host : host,
    port == nothing ? uri.port : port,
    path == nothing ? uri.path : path,
    query == nothing ? uri.query : query,
    fragment == nothing ? uri.fragment : fragment)

function Base.(:(==)){protocol}(a::URI{protocol}, b::URI{protocol})
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
  protocol == symbol("") || write(io, protocol, ':')
  isempty(u.username * u.host) || write(io,  "//")
  if !isempty(u.username)
    write(io, u.username)
    isempty(u.password) || write(io, ':', u.password)
    write(io, '@')
  end
  write(io, u.host)
  u.port == 0 || write(io, ':', string(u.port))
  write(io, u.path)
  write(io, reduce((s,a)->"$s$(a[1])=$(a[2])&", "?", u.query)[1:end-1])
  isempty(u.fragment) || write(io, '#', u.fragment)
end

const uses_authority = ["hdfs", "ftp", "http", "gopher", "nntp", "telnet", "imap", "wais", "file", "mms", "https", "shttp", "snews", "prospero", "rtsp", "rtspu", "rsync", "svn", "svn+ssh", "sftp" ,"nfs", "git", "git+ssh", "ldap"]
const uses_params = ["ftp", "hdl", "prospero", "http", "imap", "https", "shttp", "rtsp", "rtspu", "sip", "sips", "mms", "sftp", "tel"]
const non_hierarchical = ["gopher", "hdl", "mailto", "news", "telnet", "wais", "imap", "snews", "sip", "sips"]
const uses_query = ["http", "wais", "imap", "https", "shttp", "mms", "gopher", "rtsp", "rtspu", "sip", "sips", "ldap"]
const uses_fragment = ["hdfs", "ftp", "hdl", "http", "gopher", "news", "nntp", "wais", "https", "shttp", "snews", "file", "prospero"]

##
# Validate known URI formats
#
function Base.isvalid{protocol}(uri::URI{protocol})
  @assert protocol != symbol("") "can not validate a relative URI"
  s = string(protocol)
  s in non_hierarchical && search(uri.path, '/', 1) > 1 && return false # path hierarchy not allowed
  s in uses_query || isempty(uri.query) || return false                 # query component not allowed
  s in uses_fragment || isempty(uri.fragment) || return false           # fragment identifier component not allowed
  s in uses_authority && return true
  isempty(uri.host) && uri.port == 0  && isempty(uri.username)          # authority component not allowed
end

"""
Enables shorthand syntax `uri"mailto:pretty@julia"`
"""
macro uri_str(str) URI(str) end

"""
Get the protocol of a `URI`
"""
protocol{x}(uri::URI{x}) = x
