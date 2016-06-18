module annotations


import SynapseClient: @annotationsfunction, @standalonefunction, synapsecall, synapseclient


export
	to_synapse_annotations,
	from_synapse_annotations,
	to_submission_status_annotations,
	from_submission_status_annotations,
	set_privacy

@annotationsfunction to_synapse_annotations
@annotationsfunction from_synapse_annotations
@annotationsfunction to_submission_status_annotations
@annotationsfunction from_submission_status_annotations
@annotationsfunction set_privacy

end
