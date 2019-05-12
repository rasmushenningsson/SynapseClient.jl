import Base: convert, ==, getproperty, setproperty!, getindex, setindex!, haskey,
             length, iterate, eltype,
             get, get!, getkey, delete!, pop!, keys, values, merge, merge!,
             sizehint!, keytype, valtype

# AbstractSynapse is used for all PyObjects that are wrapped in a Julia type
abstract type AbstractSynapse end
abstract type AbstractEntity <: AbstractSynapse end
abstract type AbstractSynapseDict <: AbstractDict{Any,Any} end # Would have preferred multiple inheritance. Use traits?

# utility function for making sure AbstractSynapse objects are passed as PyObjects to python
unwrap(a::Any) = a # fallback
unwrap(a::AbstractSynapse) = getfield(a,:po) #a.po
unwrap(a::AbstractSynapseDict) = getfield(a,:po) #a.po

# # unwrap for keyword arguments
# unwrappair(t::Pair{Symbol,Any}) = t # fallback
# unwrappair(t::Pair{Symbol,AbstractSynapse}) = (t[1],t[2].po)
# unwrappair(t::Pair{Symbol,AbstractSynapseDict}) = (t[1],t[2].po)

# wrap is more or less the inverse of unwrap()
wrap(x::Any) = x # fallback
function wrap(po::PyObject)
	if pyisinstance(po, synapseclient.Entity)
		pyisinstance(po, synapseclient.Project) && return Project(po)
		pyisinstance(po, synapseclient.Folder)  && return Folder(po)
		pyisinstance(po, synapseclient.File)    && return File(po)
		pyisinstance(po, synapseclient.Link)    && return Link(po)
		pyisinstance(po, synapseclient.Schema)  && return Schema(po)
		return Entity(po)
	elseif pyisinstance(po, pydict_object.DictObject)
		pyisinstance(po, synapseclient.Evaluation) && return Evaluation(po)
		pyisinstance(po, synapseclient.Wiki)       && return Wiki(po)
		pyisinstance(po, synapseclient.Team)       && return Team(po)
		return DictObject(po) # IMPORTANT - this will make sure the internal dictionaries are modified in-place and not copied
	end
	# Activity and Annotations inherit from dict, not DictObject
	pyisinstance(po, synapseclient.Activity)    && return Activity(po)
	pyisinstance(po, pyannotations.Annotations) && return annotations.Annotations(po)
	pyisinstance(po, pyclient.Synapse)          && return Synapse(po)
	pyisinstance(po, pycache.Cache)             && return cache.Cache(po)

	# IMPORTANT: do not convert python dicts because that will make a copy
	pyisinstance(po, pybuiltin(:dict)) && return PyDict(po)

	convert(pytype_query(po),po) # fallback to default python -> julia conversion
end








# return type conversion is done by wrap, since PyCall conversion is a bit too eager to convert classes to pure dicts
# function synapsecall(obj::PyObject,method::Symbol,args...;kwargs...)
# 	wrap(pycall(obj[method], PyObject, 
# 	                        map(unwrap,args)...; 
# 	                        map(unwrappair,kwargs)...))
# end
function synapsecall(func::PyObject,args...;kwargs...)
	# wrap(pycall(func, PyObject, 
	#                         map(unwrap,args)...; 
	#                         map(unwrappair,kwargs)...))
	wrap(pycall(func, PyObject, 
	                        unwrap.(args)...;
	                        (k=>unwrap(v) for (k,v) in kwargs)... ))
end
synapsecall(obj::PyObject,method::Symbol,args...;kwargs...) = synapsecall(getproperty(obj,method),args...;kwargs...)
synapsecall(obj::AbstractSynapse,method::Symbol,args...;kwargs...) = synapsecall(unwrap(obj),method,args...;kwargs...)
# synapsecall(obj::AbstractSynapseDict,method::Symbol,args...;kwargs...) = synapsecall(unwrap(obj),method,args...;kwargs...)
synapsecall(obj::AbstractSynapseDict,method::Symbol,args...;kwargs...) = synapsecall(convert(PyObject,obj),method,args...;kwargs...)
#utilcall(method::Symbol,args...;kwargs...) = synapsecall(synapseclient.utils,method,args...;kwargs...)

lowercasesymbol(s::Symbol) = Symbol(lowercase(string(s)))



macro synapsefunction(T, name)
	x = Expr(:quote,name) # x is now :(:val) where val is $name
	name = lowercasesymbol(name)
	esc(:(  $name(t::$T,args...;kwargs...) = synapsecall(t,$x,args...;kwargs...)  ))
end

macro standalonefunction(parent, name)
	x = Expr(:quote,name) # x is now :(:val) where val is $name
	name = lowercasesymbol(name)
	esc(:(  $name(args...;kwargs...) = synapsecall($parent,$x,args...;kwargs...)  ))

end
macro utilfunction(name)
	esc(:( @standalonefunction(synapseclient.utils, $name) ))
end
macro entityfunction(name)
	esc(:( @standalonefunction(synapseclient.entity, $name) ))
end
macro annotationsfunction(name)
	esc(:( @standalonefunction(synapseclient.annotations, $name) ))
end
macro cachefunction(name)
	esc(:( @standalonefunction(synapseclient.cache, $name) ))
end



macro createtype(name, super, wrappedClass, storageClass, doAssert)
	# assert = doAssert ? :(@assert pytypeof(po)==$wrappedClass) : (:;) # require exact match
	assert = doAssert ? :(@assert pyisinstance(po,$wrappedClass)) : (:;) # require only that it is a subtype

	esc(quote
		struct $name <: $super
			po::$storageClass
			function $name(po::Union{PyObject,$storageClass})
				$assert
				new(po)
			end
		end
		$name(x::$name) = $name(x.po)
		#$name(args...;kwargs...) = $name(pycall($wrappedClass,PyObject,args...;kwargs...))
		$name(args...;kwargs...) = synapsecall($wrappedClass,args...;kwargs...)
	end)
end

macro entitytype(name)
	esc(:( @createtype($name,AbstractEntity,synapseclient.$name,PyObject,true) ))
end
macro dicttype(name, args...)
	pyType = isempty(args) ? (:(synapseclient.$name)) : args[1]
	esc(:( @createtype($name,AbstractSynapseDict,$pyType,PyDict,true) ))
end





convert(::Type{PyObject}, a::AbstractSynapse) = unwrap(a)
convert(::Type{PyObject}, a::AbstractSynapseDict) = convert(PyObject,unwrap(a))
==(x::AbstractSynapse, y::AbstractSynapse) = unwrap(x)==unwrap(y)
==(x::AbstractSynapseDict, y::AbstractSynapseDict) = unwrap(x)==unwrap(y)

# old
# getindex(e::AbstractSynapse, key::AbstractString)              = wrap( unwrap(e)[key] )
# setindex!(e::AbstractSynapse, value, key::AbstractString)      = unwrap(e)[key] = value
# # getindex(a::AbstractSynapseDict, key::AbstractString)         = wrap( unwrap(a)[key] )
# getindex(a::AbstractSynapseDict, key::AbstractString)         = wrap( get(unwrap(a).o,Any,key) )
# setindex!(a::AbstractSynapseDict, value, key::AbstractString) = unwrap(a)[key] = value

getproperty(e::AbstractSynapse, key::Symbol)         = wrap( getproperty(unwrap(e),key) )
setproperty!(e::AbstractSynapse, key::Symbol, value) = setproperty!(unwrap(e),key,value)
# getindex(a::AbstractSynapseDict, key::AbstractString)         = wrap( unwrap(a)[key] )
getindex(a::AbstractSynapseDict, key::AbstractString)         = wrap( get(unwrap(a).o,Any,key) )
setindex!(a::AbstractSynapseDict, value, key::AbstractString) = unwrap(a)[key] = value



hasattr = PyNULL() # pybuiltin(:hasattr)
haskey(e::AbstractSynapse, key)      = synapsecall(hasattr, e, key)
haskey(d::AbstractSynapseDict, key) = haskey(unwrap(d), key)


length(a::AbstractSynapseDict) = length(unwrap(a.po))
iterate(a::AbstractSynapseDict) = iterate(unwrap(a.po))
iterate(a::AbstractSynapseDict,state) = iterate(unwrap(a.po),state)
eltype(::Type{AbstractSynapseDict}) = Pair{Any,Any}#eltype(PyDict) # PyDict bug?


get(a::AbstractSynapseDict, key, default) = get(unwrap(a.po),key,default)
get(f::Function, a::AbstractSynapseDict, key) = get(f,unwrap(a.po),key)
get!(a::AbstractSynapseDict, key, default) = get(!unwrap(a.po),key,default)
get!(f::Function, a::AbstractSynapseDict, key) = get!(f,unwrap(a.po),key)
getkey(a::AbstractSynapseDict, key, default) = getkey(unwrap(a.po),key,default)
delete!(a::AbstractSynapseDict, key) = delete!(unwrap(a.po),key)
pop!(a::AbstractSynapseDict, key) = pop!(unwrap(a.po),key)
pop!(a::AbstractSynapseDict, key, default) = pop!(unwrap(a.po),key,default)
keys(a::AbstractSynapseDict) = keys(unwrap(a.po))
values(a::AbstractSynapseDict) = values(unwrap(a.po))
merge(a::T, others...) where {T<:AbstractSynapseDict} = T(merge(unwrap(a.po),others))
merge!(a::T, others...) where {T<:AbstractSynapseDict} = merge!(unwrap(a.po),others)
sizehint!(a::AbstractSynapseDict, n) = sizehint!(unwrap(a.po),n)
keytype(a::AbstractSynapseDict) = keytype(unwrap(a.po))
valtype(a::AbstractSynapseDict) = valuetype(unwrap(a.po))

