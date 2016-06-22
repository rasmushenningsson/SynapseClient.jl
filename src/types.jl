import Base: getindex

@entitytype Entity
@entitytype Project
@entitytype Folder
@entitytype File
@entitytype Link
@entitytype Schema

@dicttype DictObject  pydict_object.DictObject
@dicttype Evaluation
@dicttype Submission
@dicttype Activity
@dicttype Annotations pyannotations.Annotations
@dicttype Wiki
@dicttype Team

create(::Type{Entity},args...;kwargs...) = synapsecall(synapseclient.Entity,:create,args...;kwargs...)

@synapsefunction AbstractEntity local_state

@synapsefunction Activity used
@synapsefunction Activity executed
