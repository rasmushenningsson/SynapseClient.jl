









facts("DictObject") do
    # """Test creation and property access on DictObjects"""
    d = DictObject(Dict("args_working?"=>"yes"), a=123, b="foobar", nerds=["chris","jen","janey"])
    @fact d["a"]-->123
    #@fact d["a"]-->123
    @fact d["b"]-->"foobar"
    #@fact d["b"]-->"foobar"
    @fact d["nerds"]-->["chris","jen","janey"]
    @fact haskey(d,"nerds") --> true
    #@fact d["nerds"]-->["chris","jen","janey"]
    @fact haskey(d,"qwerqwer") --> false

    println(keys(d))
    @fact all([key in keys(d) for key in ["args_working?", "a", "b", "nerds"]]) --> true
    println(d)
    d["new_key"] = "new value!"
    @fact d["new_key"] --> "new value!"
end