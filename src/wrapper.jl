import Base: convert, ==, getindex, setindex!, haskey,
             length, start, next, done, eltype,
             get, get!, getkey, delete!, pop!, keys, values, merge, merge!,
             sizehint!, keytype, valtype

# AbstractSynapse is used for all PyObjects that are wrapped in a Julia type
abstract AbstractSynapse
abstract AbstractEntity <: AbstractSynapse
abstract AbstractSynapseDict <: Associative{Any,Any} # Would have preferred multiple inheritance. Use traits?

# utility function for making sure AbstractSynapse objects are passed as PyObjects to python
unwrap(a::Any) = a # fallback
unwrap(a::AbstractSynapse) = a.po
unwrap(a::AbstractSynapseDict) = a.po

# unwrap for keyword arguments
unwraptuple(t::Tuple{Symbol,Any}) = t # fallback
unwraptuple(t::Tuple{Symbol,AbstractSynapse}) = (t[1],t[2].po)
unwraptuple(t::Tuple{Symbol,AbstractSynapseDict}) = (t[1],t[2].po)

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
	pyisinstance(po, pyannotations.Annotations) && return Annotations(po)
	pyisinstance(po, pyclient.Synapse)            && return Synapse(po)

	# IMPORTANT: do not convert python dicts because that will make a copy
	pyisinstance(po, pybuiltin(:dict)) && return PyDict(po)

	convert(pytype_query(po),po) # fallback to default python -> julia conversion
end








# return type conversion is done by wrap, since PyCall conversion is a bit too eager to convert classes to pure dicts
# function synapsecall(obj::PyObject,method::Symbol,args...;kwargs...)
# 	wrap(pycall(obj[method], PyObject, 
# 	                        map(unwrap,args)...; 
# 	                        map(unwraptuple,kwargs)...))
# end
function synapsecall(func::PyObject,args...;kwargs...)
	wrap(pycall(func, PyObject, 
	                        map(unwrap,args)...; 
	                        map(unwraptuple,kwargs)...))
end
synapsecall(obj::PyObject,method::Symbol,args...;kwargs...) = synapsecall(obj[method],args...;kwargs...)
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



macro createtype(name, super, wrappedClass, storageClass, doAssert)
	assert = doAssert ? :(@assert pytypeof(po)==$wrappedClass) : (:;)

	esc(quote
		immutable $name <: $super
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

getindex(e::AbstractEntity, key::AbstractString)              = wrap( unwrap(e)[key] )
setindex!(e::AbstractEntity, value, key::AbstractString)      = unwrap(e)[key] = value
# getindex(a::AbstractSynapseDict, key::AbstractString)         = wrap( unwrap(a)[key] )
getindex(a::AbstractSynapseDict, key::AbstractString)         = wrap( get(unwrap(a).o,Any,key) )
setindex!(a::AbstractSynapseDict, value, key::AbstractString) = unwrap(a)[key] = value


hasattr = pybuiltin(:hasattr)
haskey(e::AbstractEntity, key)      = synapsecall(hasattr, e, key)
haskey(d::AbstractSynapseDict, key) = haskey(unwrap(d), key)


length(a::AbstractSynapseDict) = length(a.po)
start(a::AbstractSynapseDict) = start(a.po)
next(a::AbstractSynapseDict,state) = next(a.po,state)
done(a::AbstractSynapseDict,state) = done(a.po,state)
eltype(::Type{AbstractSynapseDict}) = Pair{Any,Any}#eltype(PyDict) # PyDict bug?


get(a::AbstractSynapseDict, key, default) = get(a.po,key,default)
get(f::Function, a::AbstractSynapseDict, key) = get(f,a.po,key)
get!(a::AbstractSynapseDict, key, default) = get(!a.po,key,default)
get!(f::Function, a::AbstractSynapseDict, key) = get!(f,a.po,key)
getkey(a::AbstractSynapseDict, key, default) = getkey(a.po,key,default)
delete!(a::AbstractSynapseDict, key) = delete!(a.po,key)
pop!(a::AbstractSynapseDict, key) = pop!(a.po,key)
pop!(a::AbstractSynapseDict, key, default) = pop!(a.po,key,default)
keys(a::AbstractSynapseDict) = keys(a.po)
values(a::AbstractSynapseDict) = values(a.po)
merge{T<:AbstractSynapseDict}(a::T, others...) = T(merge(a.po,others))
merge!{T<:AbstractSynapseDict}(a::T, others...) = merge!(a.po,others)
sizehint!(a::AbstractSynapseDict, n) = sizehint!(a.po,n)
keytype(a::AbstractSynapseDict) = keytype(a.po)
valtype(a::AbstractSynapseDict) = valuetype(a.po)

