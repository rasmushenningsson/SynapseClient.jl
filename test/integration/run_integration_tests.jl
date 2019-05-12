# module IntegrationTests # TODO: put in module?

_to_cleanup = Array{Any,1}()
schedule_for_cleanup(item) = push!(_to_cleanup,item)


function cleanup(items)
	for i=length(items):-1:1 # iterate in reverse order
		item = items[i]

		if typeof(item) <: AbstractEntity || utils.is_synapse_id(item) != nothing ||
		   (typeof(item) <: AbstractSynapse && haskey(item,"deleteURI"))
			try
				delete(syn, item)
			catch ex
				# TODO: rewrite if exception handling is improved
				if ex <: PyError && haskey(ex.val, "response") && ex.val[:response][:status_code] in [404,403]
				else
					println("Error cleaning up entity: ", ex)				
				end 
			end
		elseif typeof(item) <: AbstractString
			if ispath(item)
				try
					rm(item, recursive=true) # works on both files and folders
				catch ex
					println(ex)
				end
			end
		else
			println(STDERR, "Don't know how to clean: $item")
		end
	end
end


syn = SynapseClient.Synapse(debug=true, skip_checks=true)

print("Testing against endpoints:")
print("  " * syn.repoEndpoint)
print("  " * syn.authEndpoint)
print("  " * syn.fileHandleEndpoint)
print("  " * syn.portalEndpoint * "\n")

login(syn)

project = Project() # for scope reasons

try
    project = store(syn, Project(name=string(Base.Random.uuid4())))
    schedule_for_cleanup(project)

    println("Created project:")
    println(project["id"])

    include("integration_test.jl")

    
#catch ex
finally
	cleanup(_to_cleanup)
end



# end
