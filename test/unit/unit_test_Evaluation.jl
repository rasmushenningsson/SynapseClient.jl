



facts("Evaluation") do
    # """Test the construction and accessors of Evaluation objects."""

    #Status can only be one of ["OPEN", "PLANNED", "CLOSED", "COMPLETED"]
    @fact_pythrows ValueError Evaluation(name="foo", description="bar", status="BAH")
    @fact_pythrows ValueError Evaluation(name="foo", description="bar", status="OPEN", contentSource="a")


    #Assert that the values are 
    ev = Evaluation(name="foobar2", description="bar", status="OPEN", contentSource="syn1234")
    @fact ev["name"] --> "foobar2"
    @fact ev["description"] --> "bar"
    @fact ev["status"] --> "OPEN"
end

facts("Submission") do
    # """Test the construction and accessors of Evaluation objects."""

    @fact_pythrows PyKeyError Submission(foo="bar")
end

