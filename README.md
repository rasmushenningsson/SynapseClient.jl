# SynapseClient.jl
The goal of SynapseClient.jl is to provide a lightweight wrapper around the Synapse Python Client (https://github.com/Sage-Bionetworks/synapsePythonClient), that has full functionality but is easy to maintain and extend as the python client changes.

Notable differences to the python version:
- Follows the Julia, rather than Python, naming conventions whenever possible. Exception: submodule names are lowercase (entity, annotations, utils, etc.), to avoid name clashes with types (Entity, Annotations, etc.).
- entity = get(syn, "syn1906479") instead of entity = syn.get('syn1906479').

# Installation
SynapseClient.jl assumes that the Synapse python client is already installed in the Python installation used by Julia. You can install the python client by running:
```
run(`$(Conda.SCRIPTDIR)/pip install synapseclient`)
```
or, if Julia is configured to use your default python installation (which is the default on linux)
```
run(`pip install synapseclient`)
```
