

import SynapseClient: Wiki

facts("Wiki") do
    # """Test the construction and accessors of Wiki objects."""

    #Wiki contstuctor only takes certain values
    @fact_pythrows ValueError Wiki(title="foo")

    #Construct a wiki and test uri's
    wiki = Wiki(title ="foobar2", markdown="bar", owner=Dict("id"=>"5"))
end


    
