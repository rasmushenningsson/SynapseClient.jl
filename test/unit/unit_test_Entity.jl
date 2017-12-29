






#from synapseclient.entity import Entity, Project, Folder, File, split_entity_namespaces, is_container
#from synapseclient.exceptions import *
import SynapseClient: Entity
using SynapseClient.entity








facts("Entity") do
    # Test the basics of creating and accessing properties on an entity
    for i in 0:1
        e = Entity(name="Test object", description="I hope this works",
                   annotations = Dict("foo"=>123, "nerds"=>["chris","jen","janey"], "annotations"=>"How confusing!"),
                   properties  = Dict("annotations"=>"/repo/v1/entity/syn1234/annotations",
                                      "md5"=>"cdef636522577fc8fb2de4d95875b27c",
                                      "parentId"=>"syn1234"),
                   concreteType="org.sagebionetworks.repo.model.Data")

        # Should be able to create an Entity from an Entity
        if i == 1
            e = create(Entity,e)
        end    
        @fact e["parentId"] --> "syn1234"


        @fact e["properties"]["parentId"] -->"syn1234"

        @fact e["foo"] --> 123


        @fact e["annotations"]["foo"] --> 123

        @fact haskey(e, "parentId") --> true
        @fact haskey(e, "foo") --> true
        @fact haskey(e, "qwerqwer") --> false

        # Annotations is a bit funny, because there is a property call
        # "annotations", which will be masked by a member of the object
        # called "annotations". Because annotations are open-ended, we
        # might even have an annotations called "annotations", which gets
        # really confusing.
        @fact typeof(e["annotations"]) <: Associative --> true
        

        @fact e["properties"]["annotations"] --> "/repo/v1/entity/syn1234/annotations"
        @fact e["annotations"]["annotations"] --> "How confusing!"

        @fact e["nerds"] --> ["chris","jen","janey"]
        @fact all(k->haskey(e,k), ["name", "description", "foo", "nerds", "annotations", "md5", "parentId"]) --> true
        
        # Test modifying properties
        e["description"] = "Working, so far"
        @fact e["description"] --> "Working, so far"
        e["description"] = "Wiz-bang flapdoodle"
        @fact e["description"] --> "Wiz-bang flapdoodle"

        # Test modifying annotations
        e["foo"] = 999
        @fact e["annotations"]["foo"] --> 999
        e["foo"] = 12345
        @fact e["annotations"]["foo"] --> 12345

        # Test creating a new annotation
        e["bar"] = 888
        @fact e["annotations"]["bar"] --> 888
        e["bat"] = 7788
        @fact e["annotations"]["bat"] --> 7788

        # # Test replacing annotations object
        e["annotations"] = Dict("splat"=>"a totally new set of annotations", "foo"=>456)
        @fact e["foo"] --> 456

        @fact typeof(e["annotations"]) <: Associative --> true

        @fact e["annotations"]["foo"] --> 456

        @fact e["properties"]["annotations"] --> "/repo/v1/entity/syn1234/annotations"

        ## test unicode properties
        e["train"] = "時刻表には記載されない　月への列車が来ると聞いて"
        e["band"] = "Motörhead"
        e["lunch"] = "すし"


        println(e)


    end
end
# def test_subclassing():
#     """Test ability to subclass and add a member variable"""
    
#     ## define a subclass of Entity to make sure subclassing and creating
#     ## a new member variable works
#     class FoobarEntity(Entity):
#         def __init__(self, x):
#             self.__dict__['x'] = x

#     foobar = FoobarEntity(123)
#     assert foobar.x == 123
#     assert 'x' in foobar.__dict__
#     assert foobar.__dict__['x'] == 123
#     foobar.id = 'syn999'
#     assert foobar.properties['id'] == 'syn999'
#     foobar.n00b = 'henry'
#     assert foobar.annotations['n00b'] == 'henry'


facts("entity_creation") do
    props = Dict(
        "id"=>"syn123456",
        "concreteType"=>"org.sagebionetworks.repo.model.Folder",
        "parentId"=>"syn445566",
        "name"=>"Testing123"
    )
    annos = Dict("testing"=>123)
    folder = create(Entity, props, annos)

    @fact folder["concreteType"] --> "org.sagebionetworks.repo.model.Folder"
    @fact typeof(folder) --> Folder
    @fact folder["name"] --> "Testing123"
    @fact folder["testing"] --> 123

    ## In case of unknown concreteType, fall back on generic Entity object
    props = Dict(
        "id"=>"syn123456",
        "concreteType"=>"org.sagebionetworks.repo.model.DoesntExist",
        "parentId"=>"syn445566",
        "name"=>"Whatsits"
    )
    whatsits = create(Entity,props)

    @fact whatsits["concreteType"] --> "org.sagebionetworks.repo.model.DoesntExist"
    @fact typeof(whatsits) --> Entity
end

facts("parent_id_required") do
    xkcd1 = File("http://xkcd.com/1343/", name="XKCD: Manuals", parent="syn1000001", synapseStore=false)
    @fact xkcd1["parentId"] --> "syn1000001"

    xkcd2 = File("http://xkcd.com/1343/", name="XKCD: Manuals", parentId="syn1000002", synapseStore=false)
    @fact xkcd2["parentId"] --> "syn1000002"

    @fact_pythrows SynapseMalformedEntityError File("http://xkcd.com/1343/", name="XKCD: Manuals", synapseStore=false)
end

facts("entity_constructors") do
    project = Project("TestProject", id="syn1001", foo="bar")
    @fact project["name"] --> "TestProject"
    @fact project["foo"] --> "bar"

    folder = Folder("MyFolder", parent=project, foo="bat", id="syn1002")
    @fact folder["name"] --> "MyFolder"
    @fact folder["foo"] --> "bat"
    @fact folder["parentId"] --> "syn1001"

    a_file = File("/path/to/fabulous_things.zzz", parent=folder, foo="biz", contentType="application/cattywampus")
    #@fact a_file.name --> "fabulous_things.zzz"
    @fact a_file["concreteType"] --> "org.sagebionetworks.repo.model.FileEntity"
    @fact a_file["path"] --> "/path/to/fabulous_things.zzz"
    @fact a_file["foo"] --> "biz"
    @fact a_file["parentId"] --> "syn1002"
    @fact a_file["contentType"] --> "application/cattywampus"
    @fact "contentType" in keys(a_file["_file_handle"]) --> true
end

facts("property_keys") do
    @fact "parentId" in PyFile["_property_keys"] --> true
    @fact "versionNumber" in PyFile["_property_keys"] --> true
    @fact "dataFileHandleId" in PyFile["_property_keys"] --> true
end

facts("keys") do
    f = File("foo.xyz", parent="syn1234", foo="bar")

    # iter_keys = collect(keys(f)) # TODO: implement keys(e::AbstractEntity)


    # @fact "parentId" in iter_keys --> true
    # @fact "name" in iter_keys --> true
    # @fact "foo" in iter_keys --> true
    # @fact "concreteType" in iter_keys --> true
end

facts("attrs") do
    f = File("foo.xyz", parent="syn1234", foo="bar")
    @fact haskey(f, "parentId") --> true
    @fact haskey(f, "foo") --> true
    @fact haskey(f, "path") --> true
end

facts("split_entity_namespaces") do
    # """Test split_entity_namespaces"""

    e = Dict("concreteType"=>"org.sagebionetworks.repo.model.Folder",
         "name"=>"Henry",
         "color"=>"blue",
         "foo"=>1234,
         "parentId"=>"syn1234")
    (properties,annotations,local_state) = split_entity_namespaces(e)

    @fact Set(keys(properties)) --> Set(["concreteType", "name", "parentId"])
    @fact properties["name"] --> "Henry"
    @fact Set(keys(annotations)) --> Set(["color", "foo"])
    @fact annotations["foo"] --> 1234
    @fact length(local_state) --> 0

    e = Dict("concreteType"=>"org.sagebionetworks.repo.model.FileEntity",
         "name"=>"Henry",
         "color"=>"blue",
         "foo"=>1234,
         "parentId"=>"syn1234",
         "dataFileHandleId"=>54321,
         "cacheDir"=>"/foo/bar/bat",
         "files"=>["foo.xyz"],
         "path"=>"/foo/bar/bat/foo.xyz")
    (properties,annotations,local_state) = split_entity_namespaces(e)

    @fact Set(keys(properties)) --> Set(["concreteType", "name", "parentId", "dataFileHandleId"])
    @fact properties["name"] --> "Henry"
    @fact properties["dataFileHandleId"] --> 54321
    @fact Set(keys(annotations)) --> Set(["color", "foo"])
    @fact annotations["foo"] --> 1234
    @fact Set(keys(local_state)) --> Set(["cacheDir", "files", "path"])
    @fact local_state["cacheDir"] --> "/foo/bar/bat"

    f = create(Entity,properties,annotations,local_state)
    @fact f["properties"]["dataFileHandleId"] --> 54321
    @fact f["properties"]["name"] --> "Henry"
    @fact f["annotations"]["foo"] --> 1234
    @fact f["__dict__"]["cacheDir"] --> "/foo/bar/bat"
    @fact f["__dict__"]["path"] --> "/foo/bar/bat/foo.xyz"
end

facts("concrete_type") do
    f1 = File("http://en.wikipedia.org/wiki/File:Nettlebed_cave.jpg", name="Nettlebed Cave", parent="syn1234567", synapseStore=false)
    @fact f1["concreteType"] --> "org.sagebionetworks.repo.model.FileEntity"
end

facts("is_container") do
    ## result from a Synapse entity annotation query
    ## Note: prefix may be capitalized or not, depending on the from clause of the query
    result = Dict("entity.versionNumber"=>1,
              "entity.nodeType"=>"project",
              "entity.concreteType"=>["org.sagebionetworks.repo.model.Project"],
              "entity.createdOn"=>1451512703905,
              "entity.id"=>"syn5570912",
              "entity.name"=>"blah")
    @fact is_container(result) --> true

    result = Dict("Entity.nodeType"=>"project",
              "Entity.id"=>"syn5570912",
              "Entity.name"=>"blah")
    @fact is_container(result) --> true

    result = Dict("entity.concreteType"=>["org.sagebionetworks.repo.model.Folder"],
              "entity.id"=>"syn5570914",
              "entity.name"=>"flapdoodle")
    @fact is_container(result) --> true

    result = Dict("File.concreteType"=>["org.sagebionetworks.repo.model.FileEntity"],
              "File.id"=>"syn5570914",
              "File.name"=>"flapdoodle")
    @fact is_container(result) --> false

    @fact is_container(Folder("Stuff", parentId="syn12345")) --> true
    @fact is_container(Project("My Project", parentId="syn12345")) --> true
    @fact is_container(File("asdf.png", parentId="syn12345")) --> false
end
