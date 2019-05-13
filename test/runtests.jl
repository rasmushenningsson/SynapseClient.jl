module SynapseClientTests

using SynapseClient, PyCall
using Test
using Dates
using UUIDs
import SynapseClient: utils, 
                      AbstractEntity, AbstractSynapse, AbstractSynapseDict, 
                      Activity, Folder, File, Project, Evaluation, Submission, DictObject, Team

ValueError = pybuiltin(:ValueError)
PyKeyError = pybuiltin(:KeyError)

_raise_for_status = SynapseClient.synapseclient.exceptions._raise_for_status
SynapseMalformedEntityError = SynapseClient.synapseclient.exceptions.SynapseMalformedEntityError
SynapseHTTPError = SynapseClient.synapseclient.exceptions.SynapseHTTPError


PyDictObject = SynapseClient.synapseclient.dict_object.DictObject
PyFile = SynapseClient.synapseclient.File


macro catchpyerror(expr)
	esc(quote
		begin
			err = nothing
			try
				$expr
			catch e
				typeof(e) == PyCall.PyError || rethrow(e)
				err=e.T
			end
			err
		end
	end)
end
macro test_pythrows( exception, expr )
	esc(:(@test @catchpyerror($expr) == $exception))
end




include("unit/run_unit_tests.jl")
include("integration/run_integration_tests.jl")


end