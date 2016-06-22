#@synapsetype Synapse <: AbstractSynapse
@createtype(Synapse,AbstractSynapse,synapseclient.Synapse,PyObject,false)

login(args...;kwargs...) = Synapse(synapseclient.login(args...;kwargs...))
check_for_updates(args...;kwargs...) = synapseclient.check_for_updates(args...;kwargs...)
release_notes(args...;kwargs...) = synapseclient.release_notes(args...;kwargs...)

# NB: Public API
@synapsefunction Synapse chunkedQuery
@synapsefunction Synapse delete
@synapsefunction Synapse deleteProvenance
@synapsefunction Synapse downloadTableColumns
@synapsefunction Synapse downloadTableFile
@synapsefunction Synapse get
@synapsefunction Synapse getAnnotations
@synapsefunction Synapse getColumn
@synapsefunction Synapse getColumns
@synapsefunction Synapse getConfigFile
@synapsefunction Synapse getEvaluation
@synapsefunction Synapse getEvaluationByContentSource
@synapsefunction Synapse getEvaluationByName
@synapsefunction Synapse getPermissions
@synapsefunction Synapse getProvenance
@synapsefunction Synapse getSubmission
@synapsefunction Synapse getSubmissionBundles
@synapsefunction Synapse getSubmissionStatus
@synapsefunction Synapse getSubmissions
@synapsefunction Synapse getTableColumns
@synapsefunction Synapse getTeam
@synapsefunction Synapse getTeamMembers
@synapsefunction Synapse getUserProfile
@synapsefunction Synapse getWiki
@synapsefunction Synapse getWikiHeaders
@synapsefunction Synapse invalidateAPIKey
@synapsefunction Synapse login
@synapsefunction Synapse logout
@synapsefunction Synapse md5Query
@synapsefunction Synapse onweb
@synapsefunction Synapse printEntity
@synapsefunction Synapse restDELETE
@synapsefunction Synapse restGET
@synapsefunction Synapse restPOST
@synapsefunction Synapse restPUT
@synapsefunction Synapse sendMessage
@synapsefunction Synapse setAnnotations
@synapsefunction Synapse setEndpoints
@synapsefunction Synapse setPermissions
@synapsefunction Synapse setProvenance
@synapsefunction Synapse store
@synapsefunction Synapse submit
@synapsefunction Synapse tableQuery
@synapsefunction Synapse updateActivity
@synapsefunction Synapse uploadFile

# deprecated in python version, were never exported by SynapseClient.jl
@synapsefunction Synapse query
@synapsefunction Synapse downloadEntity
@synapsefunction Synapse createEntity
@synapsefunction Synapse getEntity
@synapsefunction Synapse updateEntity

# not exported
@synapsefunction Synapse _list
@synapsefunction Synapse _findteam
