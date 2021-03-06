module annotations

import SynapseClient: @annotationsfunction, @standalonefunction, @createtype, @dicttype, AbstractSynapseDict, synapsecall, synapseclient, pyannotations

using PyCall


export
	to_synapse_annotations,
	from_synapse_annotations,
	to_submission_status_annotations,
	from_submission_status_annotations,
	set_privacy

@dicttype Annotations pyannotations.Annotations	

@annotationsfunction to_synapse_annotations
@annotationsfunction from_synapse_annotations
@annotationsfunction to_submission_status_annotations
@annotationsfunction from_submission_status_annotations
@annotationsfunction set_privacy

end
