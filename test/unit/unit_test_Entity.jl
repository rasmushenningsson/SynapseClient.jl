






#from synapseclient.entity import Entity, Project, Folder, File, split_entity_namespaces, is_container
#from synapseclient.exceptions import *
import SynapseClient: Entity
using SynapseClient.entity








@testset "Entity" begin
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
        @test e.parentId == "syn1234"


        @test e.properties["parentId"] =="syn1234"

        @test e.foo == 123


        @test e.annotations["foo"] == 123

        @test hasattr(e, "parentId")
        @test hasattr(e, "foo")
        @test hasattr(e, "qwerqwer") == false

        # Annotations is a bit funny, because there is a property call
        # "annotations", which will be masked by a member of the object
        # called "annotations". Because annotations are open-ended, we
        # might even have an annotations called "annotations", which gets
        # really confusing.
        @test typeof(e.annotations) <: AbstractDict
        

        @test e.properties["annotations"] == "/repo/v1/entity/syn1234/annotations"
        @test e.annotations["annotations"] == "How confusing!"

        @test e.nerds == ["chris","jen","janey"]
        @test all(k->hasattr(e,k), [:name, :description, :foo, :nerds, :annotations, :md5, :parentId])
        
        # Test modifying properties
        e.description = "Working, so far"
        @test e.description == "Working, so far"
        e.description = "Wiz-bang flapdoodle"
        @test e.description == "Wiz-bang flapdoodle"

        # Test modifying annotations
        e.foo = 999
        @test e.annotations["foo"] == 999
        e.foo = 12345
        @test e.annotations["foo"] == 12345

        # Test creating a new annotation
        e.bar = 888
        @test e.annotations["bar"] == 888
        e.bat = 7788
        @test e.annotations["bat"] == 7788

        # # Test replacing annotations object
        e.annotations = Dict("splat"=>"a totally new set of annotations", "foo"=>456)
        @test e.foo == 456

        @test typeof(e.annotations) <: AbstractDict

        @test e.annotations["foo"] == 456

        @test e.properties["annotations"] == "/repo/v1/entity/syn1234/annotations"

        ## test unicode properties
        e.train = "時刻表には記載されない　月への列車が来ると聞いて"
        e.band = "Motörhead"
        e.lunch = "すし"


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


@testset "entity_creation" begin
    props = Dict(
        "id"=>"syn123456",
        "concreteType"=>"org.sagebionetworks.repo.model.Folder",
        "parentId"=>"syn445566",
        "name"=>"Testing123"
    )
    annos = Dict("testing"=>123)
    folder = create(Entity, props, annos)

    @test folder.concreteType == "org.sagebionetworks.repo.model.Folder"
    @test typeof(folder) == Folder
    @test folder.name == "Testing123"
    @test folder.testing == 123

    ## In case of unknown concreteType, fall back on generic Entity object
    props = Dict(
        "id"=>"syn123456",
        "concreteType"=>"org.sagebionetworks.repo.model.DoesntExist",
        "parentId"=>"syn445566",
        "name"=>"Whatsits"
    )
    whatsits = create(Entity,props)

    @test whatsits.concreteType == "org.sagebionetworks.repo.model.DoesntExist"
    @test typeof(whatsits) == Entity
end

@testset "parent_id_required" begin
    xkcd1 = File("http://xkcd.com/1343/", name="XKCD: Manuals", parent="syn1000001", synapseStore=false)
    @test xkcd1.parentId == "syn1000001"

    xkcd2 = File("http://xkcd.com/1343/", name="XKCD: Manuals", parentId="syn1000002", synapseStore=false)
    @test xkcd2.parentId == "syn1000002"

    @test_pythrows SynapseMalformedEntityError File("http://xkcd.com/1343/", name="XKCD: Manuals", synapseStore=false)
end

@testset "entity_constructors" begin
    project = Project("TestProject", id="syn1001", foo="bar")
    @test project.name == "TestProject"
    @test project.foo == "bar"

    folder = Folder("MyFolder", parent=project, foo="bat", id="syn1002")
    @test folder.name == "MyFolder"
    @test folder.foo == "bat"
    @test folder.parentId == "syn1001"

    a_file = File("/path/to/fabulous_things.zzz", parent=folder, foo="biz", contentType="application/cattywampus")
    #@test a_file.name == "fabulous_things.zzz"
    @test a_file.concreteType == "org.sagebionetworks.repo.model.FileEntity"
    @test a_file.path == "/path/to/fabulous_things.zzz"
    @test a_file.foo == "biz"
    @test a_file.parentId == "syn1002"
    @test a_file.contentType == "application/cattywampus"
    @test "contentType" in keys(a_file._file_handle)
end

@testset "property_keys" begin
    @test "parentId" in PyFile._property_keys
    @test "versionNumber" in PyFile._property_keys
    @test "dataFileHandleId" in PyFile._property_keys
end

@testset "keys" begin
    f = File("foo.xyz", parent="syn1234", foo="bar")

    # iter_keys = collect(keys(f)) # TODO: implement keys(e::AbstractEntity)


    # @test "parentId" in iter_keys == true
    # @test "name" in iter_keys == true
    # @test "foo" in iter_keys == true
    # @test "concreteType" in iter_keys == true
end

@testset "attrs" begin
    f = File("foo.xyz", parent="syn1234", foo="bar")
    @test hasattr(f, "parentId")
    @test hasattr(f, "foo")
    @test hasattr(f, "path")
end

@testset "split_entity_namespaces" begin
    # """Test split_entity_namespaces"""

    e = Dict("concreteType"=>"org.sagebionetworks.repo.model.Folder",
         "name"=>"Henry",
         "color"=>"blue",
         "foo"=>1234,
         "parentId"=>"syn1234")
    (properties,annotations,local_state) = split_entity_namespaces(e)

    @test Set(keys(properties)) == Set(["concreteType", "name", "parentId"])
    @test properties["name"] == "Henry"
    @test Set(keys(annotations)) == Set(["color", "foo"])
    @test annotations["foo"] == 1234
    @test length(local_state) == 0

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

    @test Set(keys(properties)) == Set(["concreteType", "name", "parentId", "dataFileHandleId"])
    @test properties["name"] == "Henry"
    @test properties["dataFileHandleId"] == 54321
    @test Set(keys(annotations)) == Set(["color", "foo"])
    @test annotations["foo"] == 1234
    @test Set(keys(local_state)) == Set(["cacheDir", "files", "path"])
    @test local_state["cacheDir"] == "/foo/bar/bat"

    f = create(Entity,properties,annotations,local_state)
    @test f.properties["dataFileHandleId"] == 54321
    @test f.properties["name"] == "Henry"
    @test f.annotations["foo"] == 1234
    @test f.__dict__["cacheDir"] == "/foo/bar/bat"
    @test f.__dict__["path"] == "/foo/bar/bat/foo.xyz"
end

@testset "concrete_type" begin
    f1 = File("http://en.wikipedia.org/wiki/File:Nettlebed_cave.jpg", name="Nettlebed Cave", parent="syn1234567", synapseStore=false)
    @test f1.concreteType == "org.sagebionetworks.repo.model.FileEntity"
end

@testset "is_container" begin
    ## result from a Synapse entity annotation query
    ## Note: prefix may be capitalized or not, depending on the from clause of the query
    result = Dict("entity.versionNumber"=>1,
              "entity.nodeType"=>"project",
              "entity.concreteType"=>["org.sagebionetworks.repo.model.Project"],
              "entity.createdOn"=>1451512703905,
              "entity.id"=>"syn5570912",
              "entity.name"=>"blah")
    @test is_container(result)

    result = Dict("Entity.nodeType"=>"project",
              "Entity.id"=>"syn5570912",
              "Entity.name"=>"blah")
    @test is_container(result)

    result = Dict("entity.concreteType"=>["org.sagebionetworks.repo.model.Folder"],
              "entity.id"=>"syn5570914",
              "entity.name"=>"flapdoodle")
    @test is_container(result)

    result = Dict("File.concreteType"=>["org.sagebionetworks.repo.model.FileEntity"],
              "File.id"=>"syn5570914",
              "File.name"=>"flapdoodle")
    @test is_container(result) == false

    @test is_container(Folder("Stuff", parentId="syn12345"))
    @test is_container(Project("My Project", parentId="syn12345"))
    @test is_container(File("asdf.png", parentId="syn12345")) == false
end
