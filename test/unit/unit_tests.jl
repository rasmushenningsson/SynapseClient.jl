_find_used(activity::Activity,predicate::Function) = activity[:used][findfirst(predicate, activity[:used])]
utils_is_json = SynapseClient.synapseclient.utils._is_json
utils_limit_and_offset = SynapseClient.synapseclient.utils._limit_and_offset






















@testset "activity_creation_from_dict" begin
	# """test that activities are created correctly from a dictionary"""
	d = Dict("name"=>"Project Fuzz",
			 "description"=>"hipster beard dataset",
			 "used"=>[ Dict("reference"=>Dict("targetId"=>"syn12345", "versionNumber"=>42), "wasExecuted"=>true) ])
	a = Activity(data=d)
	@test a["name"] == "Project Fuzz"
	@test a["description"] == "hipster beard dataset"

	usedEntities = a["used"]
	@test length(usedEntities) == 1

	u = usedEntities[1]
	@test u["wasExecuted"] == true

	@test u["reference"]["targetId"] == "syn12345"
	@test u["reference"]["versionNumber"] == 42
end

@testset "activity_used_execute_methods" begin
	# """test activity creation and used and execute methods"""
	a = Activity(name="Fuzz", description="hipster beard dataset")
	used(a,Dict("id"=>"syn101", "versionNumber"=>42, "concreteType"=> "org.sagebionetworks.repo.model.FileEntity"))
	executed(a,"syn102", targetVersion=1)
	usedEntities = a["used"]
	@test length(usedEntities) == 2

	@test a["name"] == "Fuzz"
	@test a["description"] == "hipster beard dataset"

	## ??? are activities supposed to come back in order? Let"s not count on it
	used_syn101 = _find_used(a, res -> res["reference"]["targetId"] == "syn101")
	@test used_syn101["reference"]["targetVersionNumber"] == 42
	@test used_syn101["wasExecuted"] == false

	used_syn102 = _find_used(a, res -> res["reference"]["targetId"] == "syn102")
	@test used_syn102["reference"]["targetVersionNumber"] == 1
	@test used_syn102["wasExecuted"] == true
end
@testset "activity_creation_by_constructor" begin
	# """test activity creation adding used entities by the constructor"""

	ue1 = Dict("reference"=>Dict("targetId"=>"syn101", "targetVersionNumber"=>42), "wasExecuted"=>false)
	ue2 = Dict("id"=>"syn102", "versionNumber"=>2, "concreteType"=> "org.sagebionetworks.repo.model.FileEntity")
	ue3 = "syn103"

	a = Activity(name="Fuzz", description="hipster beard dataset", used=[ue1, ue3], executed=[ue2])

	# print(a["used"])

	used_syn101 = _find_used(a, res -> res["reference"]["targetId"] == "syn101")
	@test used_syn101 != nothing
	@test used_syn101["reference"]["targetVersionNumber"] == 42
	@test used_syn101["wasExecuted"] == false

	used_syn102 = _find_used(a, res -> res["reference"]["targetId"] == "syn102")
	@test used_syn102 != nothing
	@test used_syn102["reference"]["targetVersionNumber"] == 2
	@test used_syn102["wasExecuted"] == true

	used_syn103 = _find_used(a, res -> res["reference"]["targetId"] == "syn103")
	@test used_syn103 != nothing
end 
@testset "activity_used_url" begin
	# """test activity creation with UsedURLs"""
	u1 = "http://xkcd.com"
	u2 = Dict("name"=>"The Onion", "url"=>"http://theonion.com")
	u3 = Dict("name"=>"Seriously advanced code", "url"=>"https://github.com/cbare/Pydoku/blob/ef88069f70823808f3462410e941326ae7ffbbe0/solver.py", "wasExecuted"=>true)
	u4 = Dict("name"=>"Heavy duty algorithm", "url"=>"https://github.com/cbare/Pydoku/blob/master/solver.py")

	a = Activity(name="Foobarbat", description="Apply foo to a bar and a bat", used=[u1, u2, u3], executed=[u3, u4])

	executed(a,url="http://cran.r-project.org/web/packages/glmnet/index.html", name="glm.net")
	used(a,url="http://earthquake.usgs.gov/earthquakes/feed/geojson/2.5/day", name="earthquakes")

	u = _find_used(a, res -> haskey(res,"url") && res["url"]==u1)
	@test u != nothing
	@test u["url"] == u1
	@test u["wasExecuted"] == false

	u = _find_used(a, res -> haskey(res,"name") && res["name"]=="The Onion")
	@test u != nothing
	@test u["url"] == "http://theonion.com"
	@test u["wasExecuted"] == false

	u = _find_used(a, res -> haskey(res,"name") && res["name"] == "Seriously advanced code")
	@test u != nothing
	@test u["url"] == u3["url"]
	@test u["wasExecuted"] == u3["wasExecuted"]

	u = _find_used(a, res -> haskey(res,"name") && res["name"] == "Heavy duty algorithm")
	@test u != nothing
	@test u["url"] == u4["url"]
	@test u["wasExecuted"] == true

	u = _find_used(a, res -> haskey(res,"name") && res["name"] == "glm.net")
	@test u != nothing
	@test u["url"] == "http://cran.r-project.org/web/packages/glmnet/index.html"
	@test u["wasExecuted"] == true

	u = _find_used(a, res -> haskey(res,"name") && res["name"] == "earthquakes")
	@test u != nothing
	@test u["url"] == "http://earthquake.usgs.gov/earthquakes/feed/geojson/2.5/day"
	@test u["wasExecuted"] == false
end

@testset "activity_parameter_errors" begin
	# """Test error handling in Activity.used()"""
	a = Activity(name="Foobarbat", description="Apply foo to a bar and a bat")
	@test_pythrows SynapseMalformedEntityError used(a, ["syn12345", "http://google.com"], url="http://amazon.com")
	@test_pythrows SynapseMalformedEntityError used(a, "syn12345", url="http://amazon.com")
	@test_pythrows SynapseMalformedEntityError used(a, "http://amazon.com", targetVersion=1)
end

@testset "is_url" begin
	# """test the ability to determine whether a string is a URL"""
	@test utils.is_url("http://mydomain.com/foo/bar/bat?asdf=1234&qewr=ooo") == true
	@test utils.is_url("http://xkcd.com/1193/") == true
	@test utils.is_url("syn123445") == false
	@test utils.is_url("wasssuuuup???") == false
	@test utils.is_url("file://foo.com/path/to/file.xyz") == true
	@test utils.is_url("file:///path/to/file.xyz") == true
	@test utils.is_url("file:/path/to/file.xyz") == true
	@test utils.is_url("file:///c:/WINDOWS/clock.avi") == true
	@test utils.is_url("file:c:/WINDOWS/clock.avi") == true
	@test utils.is_url("c:/WINDOWS/ugh/ugh.ugh") == false
end
@testset "windows_file_urls" begin
	url = "file:///c:/WINDOWS/clock.avi"
	@test utils.is_url(url) == true
	@test utils.file_url_to_path(url, verify_exists=false) == "c:/WINDOWS/clock.avi"
end

@testset "is_in_path" begin
    #Path as returned form syn.restGET('entity/{}/path')
    path = Dict("path"=>[Dict("id"=>"syn4489",  "name"=>"root", "type"=>"org.sagebionetworks.repo.model.Folder"),
                      Dict("id"=>"syn537704", "name"=>"my Test project", "type"=>"org.sagebionetworks.repo.model.Project"),
                      Dict("id"=>"syn2385356","name"=>".emacs", "type"=>"org.sagebionetworks.repo.model.FileEntity")])

    @test utils.is_in_path("syn537704", path) == true
    @test utils.is_in_path("syn123", path) == false
end
@testset "id_of" begin
    @test utils.id_of(1) == "1"
    @test utils.id_of("syn12345") == "syn12345"
    @test utils.id_of(Dict("foo"=>1, "id"=>123)) == "123"
    @test_pythrows ValueError utils.id_of(Dict("foo"=>1, "idzz"=>123))
    @test utils.id_of(Dict("properties"=>Dict("id"=>123))) == "123"
    @test_pythrows ValueError utils.id_of(Dict("properties"=>Dict("qq"=>123)))
    @test_pythrows ValueError utils.id_of(py"object()")

    # class Foo:
    #     def __init__(self, id):
    #         self.properties = Dict("id"=>id)

    # foo = Foo(123)
    # @test utils.id_of(foo) == 123 # TODO: is there a reasonable julia version of this test?
end
@testset "guess_file_name" begin
    @test utils.guess_file_name("a/b") == "b"
    @test utils.guess_file_name("file:///a/b") == "b"
    @test utils.guess_file_name("A:/a/b") == "b"
    @test utils.guess_file_name("B:/a/b/") == "b"
    @test utils.guess_file_name("c:\\a\\b") == "b"
    @test utils.guess_file_name("d:\\a\\b\\") == "b"
    @test utils.guess_file_name("E:\\a/b") == "b"
    @test utils.guess_file_name("F:\\a/b/") == "b"
    @test utils.guess_file_name("/a/b") == "b"
    @test utils.guess_file_name("/a/b/") == "b"
    @test utils.guess_file_name("http://www.a.com/b") == "b"
    @test utils.guess_file_name("http://www.a.com/b/") == "b"
    @test utils.guess_file_name("http://www.a.com/b?foo=bar") == "b"
    @test utils.guess_file_name("http://www.a.com/b/?foo=bar") == "b"
    @test utils.guess_file_name("http://www.a.com/b?foo=bar&arga=barga") == "b"
    @test utils.guess_file_name("http://www.a.com/b/?foo=bar&arga=barga") == "b"
end
@testset "extract_filename" begin
    @test utils.extract_filename("attachment; filename=\"fname.ext\"") == "fname.ext"
    @test utils.extract_filename("attachment; filename=fname.ext") == "fname.ext"
    @test utils.extract_filename(nothing) == nothing
    @test utils.extract_filename(nothing, "fname.ext") == "fname.ext"
end
@testset "version_check" begin
    _version_tuple = SynapseClient.synapseclient.version_check._version_tuple
    @test _version_tuple("0.5.1.dev200", levels=2) == ("0", "5")
    @test _version_tuple("0.5.1.dev200", levels=3) == ("0", "5", "1")
    @test _version_tuple("1.6", levels=3) == ("1", "6", "0")
end
@testset "normalize_path" begin
    ## tests should pass on reasonable OSes and also on windows

    ## resolves relative paths
    @test length(utils.normalize_path("asdf.txt")) > 8

    ## doesn't resolve home directory references
    #@test '~' in utils.normalize_path("~/asdf.txt") == false

    ## converts back slashes to forward slashes
    @test ('\\' in utils.normalize_path("\\windows\\why\\why\\why.txt")) == false

    ## what's the right thing to do for None?
    @test utils.normalize_path(nothing) == nothing
end
@testset "limit_and_offset" begin
    query_params(uri) = Dict([ (split(kvp,'=')...,) for kvp in split(split(uri,'?')[2],'&') ])
    


    qp = query_params(utils_limit_and_offset("/asdf/1234", limit=10, offset=0))
    @test qp["limit"] == "10"
    @test qp["offset"] == "0"

    qp = query_params(utils_limit_and_offset("/asdf/1234?limit=5&offset=10", limit=25, offset=50))
    @test qp["limit"] == "25"
    @test qp["offset"] == "50"
    @test length(qp) == 2

    qp = query_params(utils_limit_and_offset("/asdf/1234?foo=bar", limit=10, offset=30))
    @test qp["limit"] == "10"
    @test qp["offset"] == "30"
    @test qp["foo"] == "bar"
    @test length(qp) == 3

    qp = query_params(utils_limit_and_offset("/asdf/1234?foo=bar&a=b", limit=10))
    @test qp["limit"] == "10"
    @test haskey(qp,"offset") == false
    @test qp["foo"] == "bar"
    @test qp["a"] == "b"
    @test length(qp) == 3
end

@testset "utils_extract_user_name" begin
    profile = Dict("firstName"=>"Madonna")
    @test utils.extract_user_name(profile) == "Madonna"
    profile = Dict{String,Any}("firstName"=>"Oscar", "lastName"=>"the Grouch")
    @test utils.extract_user_name(profile) == "Oscar the Grouch"
    profile["displayName"] = nothing
    @test utils.extract_user_name(profile) == "Oscar the Grouch"
    profile["displayName"] = ""
    @test utils.extract_user_name(profile) == "Oscar the Grouch"
    profile["displayName"] = "Assistant Professor Oscar the Grouch, PhD"
    @test utils.extract_user_name(profile) == "Assistant Professor Oscar the Grouch, PhD"
    profile["userName"] = "otg"
    @test utils.extract_user_name(profile) == "otg"
end
@testset "is_json" begin
    @test utils_is_json("application/json") == true
    @test utils_is_json("application/json;charset=ISO-8859-1") == true
    @test utils_is_json("application/flapdoodle;charset=ISO-8859-1") == false
    @test utils_is_json(nothing) == false
    @test utils_is_json("") == false
end
@testset "unicode_output" begin
    # encoding = sys.stdout.encoding if hasattr(sys.stdout, 'encoding') else 'no encoding'
    # print("\nPython thinks your character encoding is:", encoding)
    # if encoding and encoding.lower() in ['utf-8', 'utf-16']:
        println("ȧƈƈḗƞŧḗḓ uʍop-ǝpısdn ŧḗẋŧ ƒǿř ŧḗşŧīƞɠ")
    # else:
    #     print("can't display unicode, skipping test_unicode_output...")
end
@testset "normalize_whitespace" begin
    @test utils.normalize_whitespace("   zip\ttang   pow   \n    a = 2   ") == "zip tang pow a = 2"
    result = utils.normalize_lines("   zip\ttang   pow   \n    a = 2   \n    b = 3   ")
    @test "zip tang pow\na = 2\nb = 3" == result
end

@testset "query_limit_and_offset" begin
    query, limit, offset = utils.query_limit_and_offset("select foo from bar where zap > 2 limit 123 offset 456")
    println(query, limit, offset)
    @test query == "select foo from bar where zap > 2"
    @test limit == 123
    @test offset == 456

    query, limit, offset = utils.query_limit_and_offset("select limit from offset where limit==2 limit 123 offset 456")
    @test query == "select limit from offset where limit==2"
    @test limit == 123
    @test offset == 456

    query, limit, offset = utils.query_limit_and_offset("select foo from bar where zap > 2 limit 123")
    @test query == "select foo from bar where zap > 2"
    @test limit == 123
    @test offset == 1

    query, limit, offset = utils.query_limit_and_offset("select foo from bar where zap > 2 limit 65535", hard_limit=1000)
    @test query == "select foo from bar where zap > 2"
    @test limit == 1000
    @test offset == 1
end
@testset "as_urls" begin
    @test utils.as_url("C:\\Users\\Administrator\\AppData\\Local\\Temp\\2\\tmpvixuld.txt") == "file:///C:/Users/Administrator/AppData/Local/Temp/2/tmpvixuld.txt"
    @test utils.as_url("/foo/bar/bat/zoinks.txt") == "file:///foo/bar/bat/zoinks.txt"
    @test utils.as_url("http://foo/bar/bat/zoinks.txt") == "http://foo/bar/bat/zoinks.txt"
    @test utils.as_url("ftp://foo/bar/bat/zoinks.txt") == "ftp://foo/bar/bat/zoinks.txt"
    @test utils.as_url("sftp://foo/bar/bat/zoinks.txt") == "sftp://foo/bar/bat/zoinks.txt"
end

@testset "time_manipulation" begin
    round_tripped_datetime = utils.datetime_to_iso(
                                utils.from_unix_epoch_time_secs(
                                    utils.to_unix_epoch_time_secs(
                                        utils.iso_to_datetime("2014-12-10T19:09:34.000Z"))))
    println(round_tripped_datetime)
    @test round_tripped_datetime == "2014-12-10T19:09:34.000Z"

    round_tripped_datetime = utils.datetime_to_iso(
                                utils.from_unix_epoch_time_secs(
                                    utils.to_unix_epoch_time_secs(
                                        utils.iso_to_datetime("1969-04-28T23:48:34.123Z"))))
    println(round_tripped_datetime)
    @test round_tripped_datetime == "1969-04-28T23:48:34.123Z"

    ## check that rounding to milliseconds works
    round_tripped_datetime = utils.datetime_to_iso(
                                utils.from_unix_epoch_time_secs(
                                    utils.to_unix_epoch_time_secs(
                                        utils.iso_to_datetime("1969-04-28T23:48:34.999499Z"))))
    println(round_tripped_datetime)
    @test round_tripped_datetime == "1969-04-28T23:48:34.999Z"

    ## check that rounding to milliseconds works
    round_tripped_datetime = utils.datetime_to_iso(
                                utils.from_unix_epoch_time_secs(
                                    utils.to_unix_epoch_time_secs(
                                        utils.iso_to_datetime("1969-04-27T23:59:59.999999Z"))))
    println(round_tripped_datetime)#     @test round_tripped_datetime == "1969-04-28T00:00:00.000Z" "This fails due to PyCall conversion error"
end

@testset "raise_for_status" begin
	@pydef mutable struct FakeResponse <: PyDictObject
		json(self) = self["_json"] # why can't I use self._json here?
	end

	response = pycall( FakeResponse, PyObject, 
	    status_code=501,
	    headers=Dict("content-type"=>"application/json;charset=utf-8"),
	    reason="SchlumpError",
	    text="{\"reason\":\"it schlumped\"}",
	    _json=Dict("reason"=>"it schlumped"),
	    request=Dict(
	        "url"=>"http://foo.com/bar/bat",
	        "headers"=>Dict("xyz"=>"pdq"),
	        "method"=>"PUT",
	        "body"=>"body"))

    @test_pythrows SynapseHTTPError _raise_for_status(response, verbose=false)
end

# @testset "treadsafe_generator") do # threadsafe_generator not available in SynapseClien begin
#     @utils.threadsafe_generator
#     def generate_letters():
#         for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
#             yield c

#     "".join(letter for letter in generate_letters()) == "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
# end
