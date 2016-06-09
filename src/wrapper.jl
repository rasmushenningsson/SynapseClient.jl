import Base: convert, ==, getindex, setindex!

# AbstractSynapse is used for all PyObjects that are wrapped in a Julia type
abstract AbstractSynapse
abstract AbstractEntity <: AbstractSynapse
abstract AbstractSynapseDict <: AbstractSynapse

# utility function for making sure AbstractSynapse objects are passed as PyObjects to python
pythonobject(a::Any) = a # fallback
pythonobject(a::AbstractSynapse) = a.po # unwrap
pythonobject(a::AbstractSynapseDict) = PyObject(a.pd) # unwrap

pythonobjecttuple(a::Any) = a # fallback
pythonobjecttuple(t::Tuple{Symbol,AbstractSynapse}) = (t[1],t[2].po) # unwrap for keyword arguments
pythonobjecttuple(t::Tuple{Symbol,AbstractSynapseDict}) = (t[1],PyObject(t[2].pd)) # unwrap for keyword arguments

# wrappythonobject is more or less the inverse of pythonobject()
wrappythonobject(x::Any) = x # fallback

function wrappythonobject(po::PyObject)
	if pyisinstance(po, synapseclient.Entity)
		pyisinstance(po, synapseclient.Project) && return Project(po)
		pyisinstance(po, synapseclient.Folder)  && return Folder(po)
		pyisinstance(po, synapseclient.File)    && return File(po)
		pyisinstance(po, synapseclient.Link)    && return Link(po)
		pyisinstance(po, synapseclient.Schema)  && return Schema(po)
		return Entity(po)
	end
	pyisinstance(po, synapseclient.Evaluation) && return Evaluation(po)
	pyisinstance(po, synapseclient.Activity)   && return Activity(po)
	pyisinstance(po, synapseclient.Wiki)       && return Wiki(po)
	pyisinstance(po, synapseclient.Team)       && return Team(po)
	pyisinstance(po, client.Synapse)           && return Synapse(po)
	convert(pytype_query(po),po) # fallback to default python -> julia conversion
end

convert(::Type{PyObject}, a::AbstractSynapse) = pythonobject(a)
==(x::AbstractSynapse, y::AbstractSynapse) = pythonobject(x)==pythonobject(y)

getindex(e::AbstractEntity, key::Symbol) = pythonobject(e)[key]
setindex!(e::AbstractEntity, value, key::Symbol) = pythonobject(e)[key] = value
getindex(a::AbstractSynapseDict, key::Symbol) = a.pd[key]
setindex!(a::AbstractSynapseDict, value, key::Symbol) = a.pd[key] = value



# usage: @synapsetype MyType <: MySuperType
macro synapsetype(expr)
	if expr.head == :<: # julia >= 0.5.0-
		@assert length(expr.args)==2
		name = expr.args[1]
		super = expr.args[2]
	else # julia 0.4.x
		@assert expr.head == :comparison
		@assert expr.args[2] == :(<:)
		@assert length(expr.args)==3
		name = expr.args[1]
		super = expr.args[3]
	end

	esc(quote
		immutable $name <: $super
			po::PyObject
			# function $name(po::PyObject)
			# 	@assert pytypeof(po)==synapseclient.$name # doesn't work for Synapse type
			# 	new(po)
			# end
		end
		$name(args...;kwargs...) = $name(synapseclient.$name(args...;kwargs...))
	end)

end

# usage: @dicttype MyDictType
macro dicttype(name)
	esc(quote
		immutable $name <: AbstractSynapseDict
			pd::PyDict
			function $name(pd::PyDict)
				@assert pytypeof(convert(PyObject,pd))==synapseclient.$name
				new(pd)
			end
		end
		$name(po::PyObject) = $name(PyDict(po))
		$name(args...;kwargs...) = $name(synapseclient.$name(args...;kwargs...))
	end)
end



# return type conversion is done by wrappythonobject, since PyCall conversion is a bit too eager to convert classes to pure dicts
function synapsecall(obj::PyObject,method::Symbol,args...;kwargs...)
	wrappythonobject(pycall(obj[method], PyObject, 
	                        map(pythonobject,args)...; 
	                        map(pythonobjecttuple,kwargs)...))
end
synapsecall(obj::AbstractSynapse,method::Symbol,args...;kwargs...) = synapsecall(pythonobject(obj),method,args...;kwargs...)
utilcall(method::Symbol,args...;kwargs...) = synapsecall(synapseclient.utils,method,args...;kwargs...)

lowercasesymbol(s::Symbol) = symbol(lowercase(string(s)))

macro synapsefunction(T,name)
	x = Expr(:quote,name) # x is now :(:val) where val is $name
	name = lowercasesymbol(name)
	esc(:(  $name(t::$T,args...;kwargs...) = synapsecall(t,$x,args...;kwargs...)  ))
end

macro utilfunction(name)
	x = Expr(:quote,name) # x is now :(:val) where val is $name
	name = lowercasesymbol(name)
	esc(:(  $name(args...;kwargs...) = utilcall($x,args...;kwargs...)  ))
end