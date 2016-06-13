import Base: getindex

@entitytype Entity
@entitytype Project
@entitytype Folder
@entitytype File
@entitytype Link
@entitytype Schema

@dicttype DictObject  dict_object.DictObject
@dicttype Evaluation
@dicttype Submission
@dicttype Activity
@dicttype Annotations annotations.Annotations
@dicttype Wiki
@dicttype Team

create(::Type{Entity},args...;kwargs...) = synapsecall(synapseclient.Entity,:create,args...;kwargs...)

@synapsefunction Activity used
@synapsefunction Activity executed


# TODO: should this be here?
@entityfunction split_entity_namespaces
@entityfunction is_container


@annotationsfunction to_synapse_annotations
@annotationsfunction from_synapse_annotations
@annotationsfunction to_submission_status_annotations
@annotationsfunction from_submission_status_annotations
@annotationsfunction set_privacy