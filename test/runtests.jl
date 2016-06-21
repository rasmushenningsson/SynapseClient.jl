using SynapseClient, PyCall
using FactCheck
import SynapseClient: utils, Activity, Folder, File, Project, Evaluation, Submission, DictObject

ValueError = pybuiltin(:ValueError)
PyKeyError = pybuiltin(:KeyError)

_raise_for_status = SynapseClient.synapseclient.exceptions[:_raise_for_status]
SynapseMalformedEntityError = SynapseClient.synapseclient.exceptions[:SynapseMalformedEntityError]
SynapseHTTPError = SynapseClient.synapseclient.exceptions[:SynapseHTTPError]


PyDictObject = SynapseClient.synapseclient.dict_object[:DictObject]
PyFile = SynapseClient.synapseclient.File


macro catchpyerror(expr)
	quote
		begin
			err = Void()
			try
				$(esc(expr))
			catch e
				typeof(e) == PyCall.PyError || rethrow(e)
				err=e.T
			end
			err
		end
	end
end
macro fact_pythrows( exception, expr )
	:(@fact @catchpyerror($expr) --> $exception)
end




include("unit/unit_tests.jl")
include("unit/unit_test_annotations.jl")
include("unit/unit_test_Entity.jl")
include("unit/unit_test_Evaluation.jl")
include("unit/unit_test_Wiki.jl")
include("unit/unit_test_DictObject.jl")
