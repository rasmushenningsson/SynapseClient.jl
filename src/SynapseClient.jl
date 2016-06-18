module SynapseClient

using PyCall
@pyimport synapseclient
@pyimport synapseclient.client as pyclient
@pyimport synapseclient.annotations as pyannotations
@pyimport synapseclient.dict_object as pydict_object

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

end
