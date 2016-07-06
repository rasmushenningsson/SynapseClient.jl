# SynapseClient.jl
The goal of SynapseClient.jl is to provide a lightweight wrapper around the Synapse Python Client (https://github.com/Sage-Bionetworks/synapsePythonClient), that has full functionality but is easy to maintain and extend as the python client changes.

Notable differences to the python version:
- Follows the Julia, rather than Python, naming conventions whenever possible. Exception: submodule names are lowercase (entity, annotations, utils, etc.), to avoid name clashes with types (Entity, Annotations, etc.).
- entity = get(syn, "syn1906479") instead of entity = syn.get('syn1906479').
- Members are accessed with e["field"] only (e.field syntax is not available).
