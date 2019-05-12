









@testset "DictObject" begin
    # """Test creation and property access on DictObjects"""
    d = DictObject(Dict("args_working?"=>"yes"), a=123, b="foobar", nerds=["chris","jen","janey"])
    @test d["a"]==123
    #@test d["a"]==123
    @test d["b"]=="foobar"
    #@test d["b"]=="foobar"
    @test d["nerds"]==["chris","jen","janey"]
    @test haskey(d,"nerds") == true
    #@test d["nerds"]==["chris","jen","janey"]
    @test haskey(d,"qwerqwer") == false

    # println(keys(d))
    @test all([key in keys(d) for key in ["args_working?", "a", "b", "nerds"]]) == true
    println(d)
    d["new_key"] = "new value!"
    @test d["new_key"] == "new value!"
end