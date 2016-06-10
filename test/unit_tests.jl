_raise_for_status = SynapseClient.synapseclient.exceptions[:_raise_for_status]
SynapseMalformedEntityError = SynapseClient.synapseclient.exceptions[:SynapseMalformedEntityError]
SynapseHTTPError = SynapseClient.synapseclient.exceptions[:SynapseHTTPError]
ValueError = pyeval("ValueError") # TODO: is there a better way to do this???

DictObject = SynapseClient.synapseclient.dict_object[:DictObject]

_find_used(activity::Activity,predicate::Function) = activity[:used][findfirst(predicate, activity[:used])]
utils_is_json = SynapseClient.synapseclient.utils[:_is_json]
utils_limit_and_offset = SynapseClient.synapseclient.utils[:_limit_and_offset]















facts("activity_creation_from_dict") do
	# """test that activities are created correctly from a dictionary"""
	d = Dict("name"=>"Project Fuzz",
			 "description"=>"hipster beard dataset",
			 "used"=>[ Dict("reference"=>Dict("targetId"=>"syn12345", "versionNumber"=>42), "wasExecuted"=>true) ])
	a = Activity(data=d)
	@fact a[:name] --> "Project Fuzz"
	@fact a[:description] --> "hipster beard dataset"

	usedEntities = a[:used]
	@fact length(usedEntities) --> 1

	u = usedEntities[1]
	@fact u["wasExecuted"] --> true

	@fact u["reference"]["targetId"] --> "syn12345"
	@fact u["reference"]["versionNumber"] --> 42
end

facts("activity_used_execute_methods") do
	# """test activity creation and used and execute methods"""
	a = Activity(name="Fuzz", description="hipster beard dataset")
	used(a,Dict("id"=>"syn101", "versionNumber"=>42, "concreteType"=> "org.sagebionetworks.repo.model.FileEntity"))
	executed(a,"syn102", targetVersion=1)
	usedEntities = a[:used]
	@fact length(usedEntities) --> 2

	@fact a[:name] --> "Fuzz"
	@fact a[:description] --> "hipster beard dataset"

	## ??? are activities supposed to come back in order? Let"s not count on it
	used_syn101 = _find_used(a, res -> res["reference"]["targetId"] == "syn101")
	@fact used_syn101["reference"]["targetVersionNumber"] --> 42
	@fact used_syn101["wasExecuted"] --> false

	used_syn102 = _find_used(a, res -> res["reference"]["targetId"] == "syn102")
	@fact used_syn102["reference"]["targetVersionNumber"] --> 1
	@fact used_syn102["wasExecuted"] --> true
end
facts("activity_creation_by_constructor") do
	# """test activity creation adding used entities by the constructor"""

	ue1 = Dict("reference"=>Dict("targetId"=>"syn101", "targetVersionNumber"=>42), "wasExecuted"=>false)
	ue2 = Dict("id"=>"syn102", "versionNumber"=>2, "concreteType"=> "org.sagebionetworks.repo.model.FileEntity")
	ue3 = "syn103"

	a = Activity(name="Fuzz", description="hipster beard dataset", used=[ue1, ue3], executed=[ue2])

	# print(a["used"])

	used_syn101 = _find_used(a, res -> res["reference"]["targetId"] == "syn101")
	@fact used_syn101 --> not(Void())
	@fact used_syn101["reference"]["targetVersionNumber"] --> 42
	@fact used_syn101["wasExecuted"] --> false

	used_syn102 = _find_used(a, res -> res["reference"]["targetId"] == "syn102")
	@fact used_syn102 --> not(Void())
	@fact used_syn102["reference"]["targetVersionNumber"] --> 2
	@fact used_syn102["wasExecuted"] --> true

	used_syn103 = _find_used(a, res -> res["reference"]["targetId"] == "syn103")
	@fact used_syn103 --> not(Void())
end 
facts("activity_used_url") do
	# """test activity creation with UsedURLs"""
	u1 = "http://xkcd.com"
	u2 = Dict("name"=>"The Onion", "url"=>"http://theonion.com")
	u3 = Dict("name"=>"Seriously advanced code", "url"=>"https://github.com/cbare/Pydoku/blob/ef88069f70823808f3462410e941326ae7ffbbe0/solver.py", "wasExecuted"=>true)
	u4 = Dict("name"=>"Heavy duty algorithm", "url"=>"https://github.com/cbare/Pydoku/blob/master/solver.py")

	a = Activity(name="Foobarbat", description="Apply foo to a bar and a bat", used=[u1, u2, u3], executed=[u3, u4])

	executed(a,url="http://cran.r-project.org/web/packages/glmnet/index.html", name="glm.net")
	used(a,url="http://earthquake.usgs.gov/earthquakes/feed/geojson/2.5/day", name="earthquakes")

	u = _find_used(a, res -> haskey(res,"url") && res["url"]==u1)
	@fact u --> not(Void())
	@fact u["url"] --> u1
	@fact u["wasExecuted"] --> false

	u = _find_used(a, res -> haskey(res,"name") && res["name"]=="The Onion")
	@fact u --> not(Void())
	@fact u["url"] --> "http://theonion.com"
	@fact u["wasExecuted"] --> false

	u = _find_used(a, res -> haskey(res,"name") && res["name"] == "Seriously advanced code")
	@fact u --> not(Void())
	@fact u["url"] --> u3["url"]
	@fact u["wasExecuted"] --> u3["wasExecuted"]

	u = _find_used(a, res -> haskey(res,"name") && res["name"] == "Heavy duty algorithm")
	@fact u --> not(Void())
	@fact u["url"] --> u4["url"]
	@fact u["wasExecuted"] --> true

	u = _find_used(a, res -> haskey(res,"name") && res["name"] == "glm.net")
	@fact u --> not(Void())
	@fact u["url"] --> "http://cran.r-project.org/web/packages/glmnet/index.html"
	@fact u["wasExecuted"] --> true

	u = _find_used(a, res -> haskey(res,"name") && res["name"] == "earthquakes")
	@fact u --> not(Void())
	@fact u["url"] --> "http://earthquake.usgs.gov/earthquakes/feed/geojson/2.5/day"
	@fact u["wasExecuted"] --> false
end

facts("activity_parameter_errors") do
	# """Test error handling in Activity.used()"""
	a = Activity(name="Foobarbat", description="Apply foo to a bar and a bat")
	@fact_pythrows SynapseMalformedEntityError used(a, ["syn12345", "http://google.com"], url="http://amazon.com")
	@fact_pythrows SynapseMalformedEntityError used(a, "syn12345", url="http://amazon.com")
	@fact_pythrows SynapseMalformedEntityError used(a, "http://amazon.com", targetVersion=1)
end

facts("is_url") do
	# """test the ability to determine whether a string is a URL"""
	@fact Utils.is_url("http://mydomain.com/foo/bar/bat?asdf=1234&qewr=ooo") --> true
	@fact Utils.is_url("http://xkcd.com/1193/") --> true
	@fact Utils.is_url("syn123445") --> false
	@fact Utils.is_url("wasssuuuup???") --> false
	@fact Utils.is_url("file://foo.com/path/to/file.xyz") --> true
	@fact Utils.is_url("file:///path/to/file.xyz") --> true
	@fact Utils.is_url("file:/path/to/file.xyz") --> true
	@fact Utils.is_url("file:///c:/WINDOWS/clock.avi") --> true
	@fact Utils.is_url("file:c:/WINDOWS/clock.avi") --> true
	@fact Utils.is_url("c:/WINDOWS/ugh/ugh.ugh") --> false
end
facts("windows_file_urls") do
	url = "file:///c:/WINDOWS/clock.avi"
	@fact Utils.is_url(url) --> true
	@fact Utils.file_url_to_path(url, verify_exists=false)["path"] == "c:/WINDOWS/clock.avi" --> true Utils.file_url_to_path(url)
end

facts("is_in_path") do
    #Path as returned form syn.restGET('entity/{}/path')
    path = Dict("path"=>[Dict("id"=>"syn4489",  "name"=>"root", "type"=>"org.sagebionetworks.repo.model.Folder"),
                      Dict("id"=>"syn537704", "name"=>"my Test project", "type"=>"org.sagebionetworks.repo.model.Project"),
                      Dict("id"=>"syn2385356","name"=>".emacs", "type"=>"org.sagebionetworks.repo.model.FileEntity")])

    @fact Utils.is_in_path("syn537704", path) --> true
    @fact Utils.is_in_path("syn123", path) --> false
end
facts("id_of") do
    @fact Utils.id_of(1) --> "1"
    @fact Utils.id_of("syn12345") --> "syn12345"
    @fact Utils.id_of(Dict("foo"=>1, "id"=>123)) --> 123
    @fact_pythrows ValueError Utils.id_of(Dict("foo"=>1, "idzz"=>123))
    @fact Utils.id_of(Dict("properties"=>Dict("id"=>123))) --> 123
    @fact_pythrows ValueError Utils.id_of(Dict("properties"=>Dict("qq"=>123)))
    @fact_pythrows ValueError Utils.id_of(pyeval("object()"))

    # class Foo:
    #     def __init__(self, id):
    #         self.properties = Dict("id"=>id)

    # foo = Foo(123)
    # @fact Utils.id_of(foo) --> 123 # TODO: is there a reasonable julia version of this test?
end
facts("guess_file_name") do
    @fact Utils.guess_file_name("a/b") --> "b"
    @fact Utils.guess_file_name("file:///a/b") --> "b"
    @fact Utils.guess_file_name("A:/a/b") --> "b"
    @fact Utils.guess_file_name("B:/a/b/") --> "b"
    @fact Utils.guess_file_name("c:\\a\\b") --> "b"
    @fact Utils.guess_file_name("d:\\a\\b\\") --> "b"
    @fact Utils.guess_file_name("E:\\a/b") --> "b"
    @fact Utils.guess_file_name("F:\\a/b/") --> "b"
    @fact Utils.guess_file_name("/a/b") --> "b"
    @fact Utils.guess_file_name("/a/b/") --> "b"
    @fact Utils.guess_file_name("http://www.a.com/b") --> "b"
    @fact Utils.guess_file_name("http://www.a.com/b/") --> "b"
    @fact Utils.guess_file_name("http://www.a.com/b?foo=bar") --> "b"
    @fact Utils.guess_file_name("http://www.a.com/b/?foo=bar") --> "b"
    @fact Utils.guess_file_name("http://www.a.com/b?foo=bar&arga=barga") --> "b"
    @fact Utils.guess_file_name("http://www.a.com/b/?foo=bar&arga=barga") --> "b"
end
facts("extract_filename") do
    @fact Utils.extract_filename("attachment; filename=\"fname.ext\"") --> "fname.ext"
    @fact Utils.extract_filename("attachment; filename=fname.ext") --> "fname.ext"
    @fact Utils.extract_filename(Void()) --> Void()
    @fact Utils.extract_filename(Void(), "fname.ext") --> "fname.ext"
end
facts("version_check") do
    _version_tuple = SynapseClient.synapseclient.version_check[:_version_tuple]
    @fact _version_tuple("0.5.1.dev200", levels=2) --> ("0", "5")
    @fact _version_tuple("0.5.1.dev200", levels=3) --> ("0", "5", "1")
    @fact _version_tuple("1.6", levels=3) --> ("1", "6", "0")
end
facts("normalize_path") do
    ## tests should pass on reasonable OSes and also on windows

    ## resolves relative paths
    @fact length(Utils.normalize_path("asdf.txt")) > 8 --> true

    ## doesn't resolve home directory references
    #@fact '~' in Utils.normalize_path("~/asdf.txt") --> false

    ## converts back slashes to forward slashes
    @fact '\\' in Utils.normalize_path("\\windows\\why\\why\\why.txt") --> false

    ## what's the right thing to do for None?
    @fact Utils.normalize_path(Void()) --> Void()
end
facts("limit_and_offset") do
    query_params(uri) = Dict([ (split(kvp,'=')...) for kvp in split(split(uri,'?')[2],'&') ])
    


    qp = query_params(utils_limit_and_offset("/asdf/1234", limit=10, offset=0))
    @fact qp["limit"] --> "10"
    @fact qp["offset"] --> "0"

    qp = query_params(utils_limit_and_offset("/asdf/1234?limit=5&offset=10", limit=25, offset=50))
    @fact qp["limit"] --> "25"
    @fact qp["offset"] --> "50"
    @fact length(qp) --> 2

    qp = query_params(utils_limit_and_offset("/asdf/1234?foo=bar", limit=10, offset=30))
    @fact qp["limit"] --> "10"
    @fact qp["offset"] --> "30"
    @fact qp["foo"] --> "bar"
    @fact length(qp) --> 3

    qp = query_params(utils_limit_and_offset("/asdf/1234?foo=bar&a=b", limit=10))
    @fact qp["limit"] --> "10"
    @fact haskey(qp,"offset") --> false
    @fact qp["foo"] --> "bar"
    @fact qp["a"] --> "b"
    @fact length(qp) --> 3
end

facts("utils_extract_user_name") do
    profile = Dict("firstName"=>"Madonna")
    @fact Utils.extract_user_name(profile) --> "Madonna"
    profile = Dict{ASCIIString,Any}("firstName"=>"Oscar", "lastName"=>"the Grouch")
    @fact Utils.extract_user_name(profile) --> "Oscar the Grouch"
    profile["displayName"] = Void()
    @fact Utils.extract_user_name(profile) --> "Oscar the Grouch"
    profile["displayName"] = ""
    @fact Utils.extract_user_name(profile) --> "Oscar the Grouch"
    profile["displayName"] = "Assistant Professor Oscar the Grouch, PhD"
    @fact Utils.extract_user_name(profile) --> "Assistant Professor Oscar the Grouch, PhD"
    profile["userName"] = "otg"
    @fact Utils.extract_user_name(profile) --> "otg"
end
facts("is_json") do
    @fact utils_is_json("application/json") --> true
    @fact utils_is_json("application/json;charset=ISO-8859-1") --> true
    @fact utils_is_json("application/flapdoodle;charset=ISO-8859-1") --> false
    @fact utils_is_json(Void()) --> false
    @fact utils_is_json("") --> false
end
facts("unicode_output") do
    # encoding = sys.stdout.encoding if hasattr(sys.stdout, 'encoding') else 'no encoding'
    # print("\nPython thinks your character encoding is:", encoding)
    # if encoding and encoding.lower() in ['utf-8', 'utf-16']:
        println("ȧƈƈḗƞŧḗḓ uʍop-ǝpısdn ŧḗẋŧ ƒǿř ŧḗşŧīƞɠ")
    # else:
    #     print("can't display unicode, skipping test_unicode_output...")
end
facts("normalize_whitespace") do
    @fact Utils.normalize_whitespace("   zip\ttang   pow   \n    a = 2   ") --> "zip tang pow a = 2"
    result = Utils.normalize_lines("   zip\ttang   pow   \n    a = 2   \n    b = 3   ")
    @fact "zip tang pow\na = 2\nb = 3" --> result
end

facts("query_limit_and_offset") do
    query, limit, offset = Utils.query_limit_and_offset("select foo from bar where zap > 2 limit 123 offset 456")
    println(query, limit, offset)
    @fact query --> "select foo from bar where zap > 2"
    @fact limit --> 123
    @fact offset --> 456

    query, limit, offset = Utils.query_limit_and_offset("select limit from offset where limit==2 limit 123 offset 456")
    @fact query --> "select limit from offset where limit==2"
    @fact limit --> 123
    @fact offset --> 456

    query, limit, offset = Utils.query_limit_and_offset("select foo from bar where zap > 2 limit 123")
    @fact query --> "select foo from bar where zap > 2"
    @fact limit --> 123
    @fact offset --> 1

    query, limit, offset = Utils.query_limit_and_offset("select foo from bar where zap > 2 limit 65535", hard_limit=1000)
    @fact query --> "select foo from bar where zap > 2"
    @fact limit --> 1000
    @fact offset --> 1
end
facts("as_urls") do
    @fact Utils.as_url("C:\\Users\\Administrator\\AppData\\Local\\Temp\\2\\tmpvixuld.txt") --> "file:///C:/Users/Administrator/AppData/Local/Temp/2/tmpvixuld.txt"
    @fact Utils.as_url("/foo/bar/bat/zoinks.txt") --> "file:///foo/bar/bat/zoinks.txt"
    @fact Utils.as_url("http://foo/bar/bat/zoinks.txt") --> "http://foo/bar/bat/zoinks.txt"
    @fact Utils.as_url("ftp://foo/bar/bat/zoinks.txt") --> "ftp://foo/bar/bat/zoinks.txt"
    @fact Utils.as_url("sftp://foo/bar/bat/zoinks.txt") --> "sftp://foo/bar/bat/zoinks.txt"
end

facts("time_manipulation") do
    round_tripped_datetime = Utils.datetime_to_iso(
                                Utils.from_unix_epoch_time_secs(
                                    Utils.to_unix_epoch_time_secs(
                                        Utils.iso_to_datetime("2014-12-10T19:09:34.000Z"))))
    println(round_tripped_datetime)
    @fact round_tripped_datetime --> "2014-12-10T19:09:34.000Z"

    round_tripped_datetime = Utils.datetime_to_iso(
                                Utils.from_unix_epoch_time_secs(
                                    Utils.to_unix_epoch_time_secs(
                                        Utils.iso_to_datetime("1969-04-28T23:48:34.123Z"))))
    println(round_tripped_datetime)
    @fact round_tripped_datetime --> "1969-04-28T23:48:34.123Z"

    ## check that rounding to milliseconds works
    round_tripped_datetime = Utils.datetime_to_iso(
                                Utils.from_unix_epoch_time_secs(
                                    Utils.to_unix_epoch_time_secs(
                                        Utils.iso_to_datetime("1969-04-28T23:48:34.999499Z"))))
    println(round_tripped_datetime)
    @fact round_tripped_datetime --> "1969-04-28T23:48:34.999Z"

    ## check that rounding to milliseconds works
    round_tripped_datetime = Utils.datetime_to_iso(
                                Utils.from_unix_epoch_time_secs(
                                    Utils.to_unix_epoch_time_secs(
                                        Utils.iso_to_datetime("1969-04-27T23:59:59.999999Z"))))
    println(round_tripped_datetime)
    @fact round_tripped_datetime --> "1969-04-28T00:00:00.000Z" "This fails due to PyCall conversion error"
end

facts("raise_for_status") do
	@pydef type FakeResponse <: DictObject
		json(self) = self["_json"] # why can't I use self._json here?
	end

	response = pycall( FakeResponse, PyObject, 
	    status_code=501,
	    headers=Dict("content-type"=>"application/json;charset=utf-8"),
	    reason="SchlumpError",
	    text="{\"reason\":\"it schlumped\"}",
	    _json=Dict("reason"=>"it schlumped"),
	    request=DictObject(
	        url="http://foo.com/bar/bat",
	        headers=Dict("xyz"=>"pdq"),
	        method="PUT",
	        body="body"))

    @fact_pythrows SynapseHTTPError _raise_for_status(response, verbose=false)
end

# facts("treadsafe_generator") do # threadsafe_generator not available in SynapseClient.jl
#     @utils.threadsafe_generator
#     def generate_letters():
#         for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
#             yield c

#     "".join(letter for letter in generate_letters()) == "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
# end
