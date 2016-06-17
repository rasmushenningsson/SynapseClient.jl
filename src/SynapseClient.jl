module SynapseClient

using PyCall
@pyimport synapseclient
@pyimport synapseclient.client as client
@pyimport synapseclient.annotations as annotations
@pyimport synapseclient.dict_object as dict_object

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
	executed,

	# from Entity	
	split_entity_namespaces,
	is_container,

	# annotations
	to_synapse_annotations,
	from_synapse_annotations,
	to_submission_status_annotations,
	from_submission_status_annotations,
	set_privacy

include("wrapper.jl")
include("types.jl")
include("synapse.jl")
include("Utils.jl")

end
