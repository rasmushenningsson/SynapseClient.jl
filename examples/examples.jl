using SynapseClient

e = SynapseClient.Entity(name="Test object", description="I hope this works",
           annotations = Dict("foo"=>123, "nerds"=>["chris","jen","janey"], "annotations"=>"How confusing!"),
           properties  = Dict("annotations"=>"/repo/v1/entity/syn1234/annotations",
                              "md5"=>"cdef636522577fc8fb2de4d95875b27c",
                              "parentId"=>"syn1234"),
           concreteType="org.sagebionetworks.repo.model.Data")

syn = SynapseClient.Synapse(debug=true, skip_checks=true)
printentity(syn,e)


syn = SynapseClient.login()

file = get(syn, "syn1906479")
printentity(syn,file)
provenance = getprovenance(syn, "syn1906479")

project = get(syn, "syn1901847")
wiki = getwiki(syn, "syn1901847")
wiki2 = getwiki(syn, project)

@assert wiki == wiki2

team = getteam(syn,3341340)

evaluation = getevaluation(syn,2005090)


SynapseClient.check_for_updates()
