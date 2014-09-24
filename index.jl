@require "querystring" Query
import Base: string, isvalid, ==
export URI, @uri_str, Query

const regex = r"""
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
"""x

type URI
  schema::String
  username::String
  password::String
  host::String
  port::Int
  path::String
  query::Query
  fragment::String
end

URI(uri::String) = begin
  m = match(regex, uri).captures
  URI(
    m[1] === nothing ? "" : m[1],             # schema
    m[2] === nothing ? "" : m[2],             # username
    m[3] === nothing ? "" : m[3],             # password
    m[4] === nothing ? "" : m[4],             # host
    m[5] === nothing ? 0 : int(m[5]),         # port
    m[6] === nothing ? "" : m[6],             # path
    m[7] === nothing ? Query() : Query(m[7]), # query
    m[8] === nothing ? "" : m[8])             # fragment
end

function ==(a::URI, b::URI)
  a.schema == b.schema &&
  a.username == b.username &&
  a.password == b.password &&
  a.host == b.host &&
  a.port == b.port &&
  a.path == b.path &&
  a.query == b.query &&
  a.fragment == b.fragment
end

function string(u::URI)
  string(
    isempty(u.schema) ? "" : u.schema * ((isempty(u.username) && isempty(u.host)) ? ":" : "://"),
    u.username == "" ? "" : u.username * (u.password == "" ? "" : ":$(u.password)") * "@",
    u.host,
    u.port == 0 ? "" : ":$(u.port)",
    u.path,
    reduce((s,a)->"$s$(a[1])=$(a[2])&", "?", u.query)[1:end-1],
    u.fragment == "" ? "" : "#$(u.fragment)")
end

const uses_authority = ["hdfs", "ftp", "http", "gopher", "nntp", "telnet", "imap", "wais", "file", "mms", "https", "shttp", "snews", "prospero", "rtsp", "rtspu", "rsync", "svn", "svn+ssh", "sftp" ,"nfs", "git", "git+ssh", "ldap"]
const uses_params = ["ftp", "hdl", "prospero", "http", "imap", "https", "shttp", "rtsp", "rtspu", "sip", "sips", "mms", "sftp", "tel"]
const non_hierarchical = ["gopher", "hdl", "mailto", "news", "telnet", "wais", "imap", "snews", "sip", "sips"]
const uses_query = ["http", "wais", "imap", "https", "shttp", "mms", "gopher", "rtsp", "rtspu", "sip", "sips", "ldap"]
const uses_fragment = ["hdfs", "ftp", "hdl", "http", "gopher", "news", "nntp", "wais", "https", "shttp", "snews", "file", "prospero"]

##
# Validate known URI formats
#
function isvalid(uri::URI)
  s = uri.schema
  @assert !isempty(s) "can not validate a relative URI"
  s in non_hierarchical && search(uri.path, '/', 1) > 1 && return false # path hierarchy not allowed
  s in uses_query || isempty(uri.query) || return false                 # query component not allowed
  s in uses_fragment || isempty(uri.fragment) || return false           # fragment identifier component not allowed
  s in uses_authority && return true
  isempty(uri.host) && uri.port == 0  && isempty(uri.username)          # authority component not allowed
end

##
# Enables shorthand syntax `uri"mailto:pretty@julia"`
#
macro uri_str(str::String)
  URI(str)
end
