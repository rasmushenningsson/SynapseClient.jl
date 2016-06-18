#using DataStructures
@pyimport collections











# import synapseclient.utils as utils
# from synapseclient.annotations import to_synapse_annotations, from_synapse_annotations, to_submission_status_annotations, from_submission_status_annotations, set_privacy
# from synapseclient.exceptions import *








facts("annotations") do
    # """Test string annotations"""
    a = Dict("foo"=>"bar", "zoo"=>["zing","zaboo"], "species"=>"Platypus")
    sa = to_synapse_annotations(a)
    # print(sa)
    @fact sa["stringAnnotations"]["foo"] --> ["bar"]
    @fact sa["stringAnnotations"]["zoo"] --> ["zing","zaboo"]
    @fact sa["stringAnnotations"]["species"] --> ["Platypus"]
end

facts("annotation_name_collision") do
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
    @fact a["tissueType"] --> ["Blood"]
##    assert a["uri"] == u"/entity/syn47396/annotations"
end

facts("more_annotations") do
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
    @fact sa["longAnnotations"]["foo"] --> [1234]
    @fact sa["doubleAnnotations"]["zoo"] --> [123.1, 456.2, 789.3]
    @fact sa["stringAnnotations"]["species"] --> ["Platypus"]
    @fact sa["stringAnnotations"]["test_boolean"] --> ["true"]
    @fact sa["stringAnnotations"]["test_mo_booleans"] --> ["False", "True", "True", "False"]

    ## this part of the test is kinda fragile. It it breaks again, it should be removed
    bdays = [Utils.from_unix_epoch_time(t) for t in sa["dateAnnotations"]["birthdays"]]
    @fact all(Bool[t in bdays for t in [Dates.DateTime(1969,4,28), Dates.DateTime(1973,12,8), Dates.DateTime(2008,1,3)]]) --> true
end
facts("annotations_unicode") do
    a = Dict("files"=>["tmp6y5tVr.txt"], "cacheDir"=>"/Users/chris/.synapseCache/python/syn1809087", "foo"=>1266)
    sa = to_synapse_annotations(a)
    @fact sa["stringAnnotations"]["cacheDir"] --> ["/Users/chris/.synapseCache/python/syn1809087"]
end
facts("round_trip_annotations") do
    # """Test that annotations can make the round trip from a simple dictionary
    # to the synapse format and back"""
    a = Dict("foo"=>1234, "zoo"=>[123.1, 456.2, 789.3], "species"=>"Moose", "birthdays"=>[Dates.DateTime(1969,4,28), Dates.DateTime(1973,12,8), Dates.DateTime(2008,1,3), Dates.DateTime(2013,3,15)])
    sa = to_synapse_annotations(a)
    # print(sa)
    a2 = from_synapse_annotations(sa)
    # print(a2)
    a = a2 # TODO: Shouldn't there be a test here?
end
facts("mixed_annotations") do
    # """test that to_synapse_annotations will coerce a list of mixed types to strings"""
    a = Dict("foo"=>[1, "a", Dates.DateTime(1969,4,28,11,47)])
    sa = to_synapse_annotations(a)
    # print(sa)
    a2 = from_synapse_annotations(sa)
    # print(a2)
    @fact a2["foo"][1] --> "1"
    @fact a2["foo"][2] --> "a"
    @fact isempty(search(a2["foo"][3],"1969")) --> false
end

facts("idempotent_annotations") do
    # """test that to_synapse_annotations won"t mess up a dictionary that"s already
    # in the synapse format"""
    a = Dict("species"=>"Moose", "n"=>42, "birthday"=>Dates.DateTime(1969,4,28))
    sa = to_synapse_annotations(a)
    a2 = Dict()
    merge!(a2,sa)#a2.update(sa)
    sa2 = to_synapse_annotations(a2)
    @fact sa --> sa2
end
facts("submission_status_annotations_round_trip") do
    april_28_1969 = Dates.DateTime(1969,4,28)
    a = Dict("screen_name"=>"Bullwinkle", "species"=>"Moose", "lucky"=>13, "pi"=>float(pi), "birthday"=>april_28_1969)
    sa = to_submission_status_annotations(a)
    println(sa)
    @fact Set([kvp["key"]   for kvp in sa["stringAnnos"]]) --> Set(["screen_name","species"])
    @fact Set([kvp["value"] for kvp in sa["stringAnnos"]]) --> Set(["Bullwinkle","Moose"])

    ## test idempotence
    @fact to_submission_status_annotations(sa) --> sa

    @fact Set([kvp["key"] for kvp in sa["longAnnos"]]) --> Set(["lucky", "birthday"])
    for kvp in sa["longAnnos"]
        key = kvp["key"]
        value = kvp["value"]
        key=="lucky" && @fact value --> 13

        key=="birthday" && @fact Utils.from_unix_epoch_time(value) --> april_28_1969
    end

    @fact Set([kvp["key"] for kvp in sa["doubleAnnos"]]) --> Set(["pi"])
    @fact Set([kvp["value"] for kvp in sa["doubleAnnos"]]) --> Set([float(pi)])

    set_privacy(sa, key="screen_name", is_private=false)
    @fact_pythrows PyKeyError set_privacy(sa, key="this_key_does_not_exist", is_private=false)

    for kvp in sa["stringAnnos"]
        kvp["key"] == "screen_name" && @fact kvp["isPrivate"] --> false

    end
    a2 = from_submission_status_annotations(sa)
    # TODO: is there a way to convert dates back from longs automatically?
    a2["birthday"] = Utils.from_unix_epoch_time(a2["birthday"])
    @fact a --> a2

    ## test idempotence
    @fact from_submission_status_annotations(a) --> a
end
facts("submission_status_double_annos") do
    ssa = Dict("longAnnos"=>   [Dict("isPrivate"=>false, "value"=>13, "key"=>"lucky")],
           "doubleAnnos"=>[Dict("isPrivate"=>false, "value"=>3, "key"=>"three"), Dict("isPrivate"=>false, "value"=>float(pi), "key"=>"pi")])
    ## test that the double annotation "three":3 is interpretted as a floating
    ## point 3.0 rather than an integer 3
    annotations = from_submission_status_annotations(ssa)
    @fact typeof(annotations["three"]) --> Float64
    ssa2 = to_submission_status_annotations(annotations)
    @fact Set([kvp["key"] for kvp in ssa2["doubleAnnos"]]) --> Set(["three", "pi"])
    @fact Set([kvp["key"] for kvp in ssa2["longAnnos"]]) --> Set(["lucky"])
end