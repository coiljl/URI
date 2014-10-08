@require "." URI @uri_str Query

for url in [
  "hdfs://user:password@hdfshost:9000/root/folder/file.csv#frag",
  "https://user:password@httphost:9000/path1/path2;paramstring?q=a&p=r#frag",
  "https://user:password@httphost:9000/path1/path2?q=a&p=r#frag",
  "https://user:password@httphost:9000/path1/path2;paramstring#frag",
  "https://user:password@httphost:9000/path1/path2#frag",
  "file:/path/to/file/with%3fshould%3dwork%23fine",
  "ftp://ftp.is.co.za/rfc/rfc1808.txt",
  "http://www.ietf.org/rfc/rfc2396.txt",
  # "ldap://[2001:db8::7]/c=GB?objectClass?one", see http://tools.ietf.org/html/rfc3986#section-3.2.2
  "mailto:John.Doe@example.com",
  "news:comp.infosystems.www.servers.unix",
  "tel:+1-816-555-1212",
  "telnet://192.0.2.16:80/",
  "urn:oasis:names:specification:docbook:dtd:xml:4.1.2"
]
  u = URI(url)
  @test string(u) == url
  @test isvalid(u)
end

@test ==(URI("hdfs://user:password@hdfshost:9000/root/folder/file.csv"),
         URI("hdfs", "user", "password", "hdfshost", 9000, "/root/folder/file.csv", Query(), ""))

@test !isvalid(URI("file:///path/to/file/with?should=work#fine"))
@test  isvalid(URI("file:///path/to/file/with%3fshould%3dwork%23fine"))

@test URI("//google.com") == URI("", "", "", "google.com", 0, "", Query(), "")

@test uri"//google.com" == URI("", "", "", "google.com", 0, "", Query(), "")

@test uri"?a=1&b=2".query == Query({"a"=>"1","b"=>"2"})
