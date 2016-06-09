import Base: getindex

@synapsetype Entity  <: AbstractEntity
@synapsetype Project <: AbstractEntity
@synapsetype Folder  <: AbstractEntity
@synapsetype File    <: AbstractEntity
@synapsetype Link    <: AbstractEntity
@synapsetype Schema  <: AbstractEntity

@dicttype Evaluation
@dicttype Activity
@dicttype Wiki
@dicttype Team

@synapsefunction Activity used
@synapsefunction Activity executed
