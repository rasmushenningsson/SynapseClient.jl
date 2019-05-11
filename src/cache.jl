module cache

import SynapseClient: @cachefunction, @standalonefunction, @synapsefunction, @createtype, AbstractSynapse, synapsecall, synapseclient

using PyCall
# @pyimport synapseclient.cache as pycache
pycache = synapseclient.cache



export 
	add,
	contains,
	get,
	get_cache_dir,
	purge,
	remove

@createtype(Cache,AbstractSynapse,pycache.Cache,PyObject,false)

@synapsefunction Cache add
@synapsefunction Cache contains
@synapsefunction Cache get
@synapsefunction Cache get_cache_dir
@synapsefunction Cache purge
@synapsefunction Cache remove

end
