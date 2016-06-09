using SynapseClient
using FactCheck
import SynapseClient: Utils, Activity


_find_used(activity::Activity,predicate::Function) = activity[:used][findfirst(predicate, activity[:used])]
macro catchpyerror(expr)
	quote
		begin
			err = Void()
			try $(esc(expr))
			catch e
				err=e.T
			end
			err
		end
	end
end
macro synapseexception(exception)
	exception = Expr(:quote,exception)
	:( SynapseClient.synapseclient.exceptions[$exception] )
end



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
    @fact @catchpyerror(used(a, ["syn12345", "http://google.com"], url="http://amazon.com")) --> @synapseexception(SynapseMalformedEntityError)
    @fact @catchpyerror(used(a, "syn12345", url="http://amazon.com")) --> @synapseexception(SynapseMalformedEntityError)
    @fact @catchpyerror(used(a, "http://amazon.com", targetVersion=1)) --> @synapseexception(SynapseMalformedEntityError)
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









