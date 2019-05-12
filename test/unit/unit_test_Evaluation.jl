



@testset "Evaluation" begin
    # """Test the construction and accessors of Evaluation objects."""

    #Status can only be one of ["OPEN", "PLANNED", "CLOSED", "COMPLETED"]
    @test_pythrows ValueError Evaluation(name="foo", description="bar", status="BAH")
    @test_pythrows ValueError Evaluation(name="foo", description="bar", status="OPEN", contentSource="a")


    #Assert that the values are 
    ev = Evaluation(name="foobar2", description="bar", status="OPEN", contentSource="syn1234")
    @test ev["name"] == "foobar2"
    @test ev["description"] == "bar"
    @test ev["status"] == "OPEN"
end

@testset "Submission" begin
    # """Test the construction and accessors of Evaluation objects."""

    @test_pythrows PyKeyError Submission(foo="bar")
end

