module SynapseClient

using PyCall


const synapseclient = PyNULL()
const pyclient = PyNULL()
const pyannotations = PyNULL()
const pydict_object = PyNULL()
const pycache = PyNULL()


function __init__()
	try 
		copy!(synapseclient, pyimport("synapseclient"))
		copy!(pyclient,      synapseclient.client)
		copy!(pyannotations, synapseclient.annotations)
		copy!(pydict_object, synapseclient.dict_object)
		copy!(pycache,       synapseclient.cache)
		copy!(pyhasattr, pybuiltin(:hasattr))
	catch
		@warn "Please install the python package \"synapseclient\"."
	end
end


import Base: get

export
	Synapse,

	# SynapseClient
	chunkedquery,
	delete,
	deleteprovenance,
	downloadtablecolumns,
	downloadtablefile,
	#get, # NB: it makes more sense to extend Base.get since it is a dictionary lookup
	getannotations,
	getcolumn,
	getcolumns,
	getconfigfile,
	getevaluation,
	getevaluationbycontentsource,
	getevaluationbyname,
	getpermissions,
	getprovenance,
	getsubmission,
	getsubmissionbundles,
	getsubmissionstatus,
	getsubmissions,
	gettablecolumns,
	getteam,
	getteammembers,
	getuserprofile,
	getwiki,
	getwikiheaders,
	hasattr,
	invalidateapikey,
	login,
	logout,
	md5query,
	onweb,
	printentity,
	restdelete,
	restget,
	restpost,
	restput,
	sendmessage,
	setannotations,
	setendpoints,
	setpermissions,
	setprovenance,
	store,
	submit,
	tablequery,
	updateactivity,
	uploadfile,

	# Entity
	create,

	# Activity
	used,
	executed

include("wrapper.jl")
include("types.jl")
include("synapse.jl")
include("utils.jl")
include("entity.jl")
include("annotations.jl")
include("cache.jl")

end
