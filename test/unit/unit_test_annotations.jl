#using DataStructures
collections = pyimport("collections") # @pyimport collections











# import synapseclient.utils as utils
# from synapseclient.annotations import to_synapse_annotations, from_synapse_annotations, to_submission_status_annotations, from_submission_status_annotations, set_privacy
# from synapseclient.exceptions import *
using SynapseClient.annotations







@testset "annotations" begin
    # """Test string annotations"""
    a = Dict("foo"=>"bar", "zoo"=>["zing","zaboo"], "species"=>"Platypus")
    sa = to_synapse_annotations(a)
    # print(sa)
    @test sa["stringAnnotations"]["foo"] == ["bar"]
    @test sa["stringAnnotations"]["zoo"] == ["zing","zaboo"]
    @test sa["stringAnnotations"]["species"] == ["Platypus"]
end

@testset "annotation_name_collision" begin
    # """Test handling of a name collisions between typed user generated and untyped
       # system generated annotations, see SYNPY-203 and PLFM-3248"""

    ## order is important: to repro the erro, the key uri has to come before stringAnnotations
    sa = collections.OrderedDict()
    sa["uri"] = "/entity/syn47396/annotations"
    sa["doubleAnnotations"] = Dict()
    sa["longAnnotations"] = Dict()
    sa["stringAnnotations"] = Dict(
            "tissueType"=> ["Blood"],
            "uri"=> ["/repo/v1/dataset/47396"])
    sa["creationDate"] = "1321168909232"
    sa["id"] = "syn47396"

    a = from_synapse_annotations(sa)
    @test a["tissueType"] == ["Blood"]
##    assert a["uri"] == u"/entity/syn47396/annotations"
end

@testset "more_annotations" begin
    # """Test long, float and data annotations"""
    a = Dict("foo"=>1234,
             "zoo"=>[123.1, 456.2, 789.3],
             "species"=>"Platypus",
             # "birthdays"=>[Datetime(1969,4,28), Datetime(1973,12,8), Datetime(2008,1,3)],
             "birthdays"=>[Dates.DateTime(1969,4,28), Dates.DateTime(1973,12,8), Dates.DateTime(2008,1,3)],
             "test_boolean"=>true,
             "test_mo_booleans"=>[false, true, true, false])
    sa = to_synapse_annotations(a)
    println(sa)
    @test sa["longAnnotations"]["foo"] == [1234]
    @test sa["doubleAnnotations"]["zoo"] == [123.1, 456.2, 789.3]
    @test sa["stringAnnotations"]["species"] == ["Platypus"]
    @test sa["stringAnnotations"]["test_boolean"] == ["true"]
    @test lowercase.(sa["stringAnnotations"]["test_mo_booleans"]) == ["false", "true", "true", "false"]

    ## this part of the test is kinda fragile. It it breaks again, it should be removed
    bdays = [utils.from_unix_epoch_time(t) for t in sa["dateAnnotations"]["birthdays"]]
    @test all(Bool[t in bdays for t in [Dates.DateTime(1969,4,28), Dates.DateTime(1973,12,8), Dates.DateTime(2008,1,3)]]) == true
end
@testset "annotations_unicode" begin
    a = Dict("files"=>["tmp6y5tVr.txt"], "cacheDir"=>"/Users/chris/.synapseCache/python/syn1809087", "foo"=>1266)
    sa = to_synapse_annotations(a)
    @test sa["stringAnnotations"]["cacheDir"] == ["/Users/chris/.synapseCache/python/syn1809087"]
end
@testset "round_trip_annotations" begin
    # """Test that annotations can make the round trip from a simple dictionary
    # to the synapse format and back"""
    a = Dict("foo"=>1234, "zoo"=>[123.1, 456.2, 789.3], "species"=>"Moose", "birthdays"=>[Dates.DateTime(1969,4,28), Dates.DateTime(1973,12,8), Dates.DateTime(2008,1,3), Dates.DateTime(2013,3,15)])
    sa = to_synapse_annotations(a)
    # print(sa)
    a2 = from_synapse_annotations(sa)
    # print(a2)
    a = a2 # TODO: Shouldn't there be a test here?
end
@testset "mixed_annotations" begin
    # """test that to_synapse_annotations will coerce a list of mixed types to strings"""
    a = Dict("foo"=>[1, "a", Dates.DateTime(1969,4,28,11,47)])
    sa = to_synapse_annotations(a)
    # print(sa)
    a2 = from_synapse_annotations(sa)
    # print(a2)
    @test a2["foo"][1] == "1"
    @test a2["foo"][2] == "a"
    @test findfirst("1969",a2["foo"][3]) != nothing
end

@testset "idempotent_annotations" begin
    # """test that to_synapse_annotations won"t mess up a dictionary that"s already
    # in the synapse format"""
    a = Dict("species"=>"Moose", "n"=>42, "birthday"=>Dates.DateTime(1969,4,28))
    sa = to_synapse_annotations(a)
    a2 = Dict()
    merge!(a2,sa)#a2.update(sa)
    sa2 = to_synapse_annotations(a2)
    @test sa == sa2
end
@testset "submission_status_annotations_round_trip" begin
    april_28_1969 = Dates.DateTime(1969,4,28)
    a = Dict("screen_name"=>"Bullwinkle", "species"=>"Moose", "lucky"=>13, "pi"=>float(pi), "birthday"=>april_28_1969)
    sa = to_submission_status_annotations(a)
    println(sa)
    @test Set([kvp["key"]   for kvp in sa["stringAnnos"]]) == Set(["screen_name","species"])
    @test Set([kvp["value"] for kvp in sa["stringAnnos"]]) == Set(["Bullwinkle","Moose"])

    ## test idempotence
    @test to_submission_status_annotations(sa) == sa

    @test Set([kvp["key"] for kvp in sa["longAnnos"]]) == Set(["lucky", "birthday"])
    for kvp in sa["longAnnos"]
        key = kvp["key"]
        value = kvp["value"]
        key=="lucky" && @test value == 13

        key=="birthday" && @test utils.from_unix_epoch_time(value) == april_28_1969
    end

    @test Set([kvp["key"] for kvp in sa["doubleAnnos"]]) == Set(["pi"])
    @test Set([kvp["value"] for kvp in sa["doubleAnnos"]]) == Set([float(pi)])

    set_privacy(sa, key="screen_name", is_private=false)
    @test_pythrows PyKeyError set_privacy(sa, key="this_key_does_not_exist", is_private=false)

    for kvp in sa["stringAnnos"]
        kvp["key"] == "screen_name" && @test kvp["isPrivate"] == false

    end
    a2 = from_submission_status_annotations(sa)
    # TODO: is there a way to convert dates back from longs automatically?
    a2["birthday"] = utils.from_unix_epoch_time(a2["birthday"])
    @test a == a2

    ## test idempotence
    @test from_submission_status_annotations(a) == a
end
@testset "submission_status_double_annos" begin
    ssa = Dict("longAnnos"=>   [Dict("isPrivate"=>false, "value"=>13, "key"=>"lucky")],
           "doubleAnnos"=>[Dict("isPrivate"=>false, "value"=>3, "key"=>"three"), Dict("isPrivate"=>false, "value"=>float(pi), "key"=>"pi")])
    ## test that the double annotation "three":3 is interpretted as a floating
    ## point 3.0 rather than an integer 3
    annotations = from_submission_status_annotations(ssa)
    @test typeof(annotations["three"]) == Float64
    ssa2 = to_submission_status_annotations(annotations)
    @test Set([kvp["key"] for kvp in ssa2["doubleAnnos"]]) == Set(["three", "pi"])
    @test Set([kvp["key"] for kvp in ssa2["longAnnos"]]) == Set(["lucky"])
end