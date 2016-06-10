using SynapseClient, PyCall
using FactCheck
import SynapseClient: Utils, Activity

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


include("unit_tests.jl")
