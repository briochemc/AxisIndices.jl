
@testset "Axis Constructors" begin
    a1 = Axis(2:3 => 1:2)

    @test UnitRange(a1) == 1:2

    @test @inferred(Axis(a1)) isa typeof(a1)

    @test @inferred(SimpleAxis(Axis(1:2))) isa SimpleAxis

    @test SimpleAxis{Int,UnitRange{Int}}(SimpleAxis(Base.OneTo(10))) isa SimpleAxis{Int,UnitRange{Int}}

    @test StaticRanges.similar_type(SimpleAxis(1:10)) <: SimpleAxis{Int64,UnitRange{Int64}}

    @test @inferred(Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(1:10)) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}

    @test @inferred(Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}(1:10)) isa Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}

    @test @inferred(Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}(1:10)) isa Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}

    @test @inferred(Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}(1:10)) isa Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}

    @test @inferred(AxisIndices.to_axis(a1)) == a1

    @test @inferred(Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}(1:2)) isa Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}
    @test @inferred(Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}(UnitRange(UInt(1), UInt(2)))) isa Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}

    @test SimpleAxis{Int,UnitMRange{Int}}(Base.OneTo(10)) isa SimpleAxis{Int,UnitMRange{Int}}
    @test SimpleAxis{Int,UnitMRange{Int}}(1:2) isa SimpleAxis{Int,UnitMRange{Int}}

    @test Axis{String,Int,Vector{String},Base.OneTo{Int}}(Axis(["a", "b"])) isa Axis{String,Int,Vector{String},Base.OneTo{Int}}

    axis = Axis(1:10)
    @test @inferred(keys(similar(axis, 2:3))) == 2:3
    @test @inferred(keys(similar(axis, ["a", "b"]))) == ["a", "b"]
    @test @inferred(similar(SimpleAxis(10), 2:3)) == 2:3

    @test SimpleAxis{Int,UnitRange{Int}}(Base.OneTo(2)) isa SimpleAxis{Int,UnitRange{Int}}
    @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(Base.OneTo(2)) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}
    @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(1:2) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}
    @test Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}(Base.OneTo(2)) isa Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}
    @test Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}(1:2) isa Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}
end


@testset "Array constructors" begin
    A_fixed = ones(2, 2)

    A_static = SMatrix{2,2}(A_fixed)

    @testset "AxisIndicesArray(::AbstractArray)" begin
        A_fixed_axes = @inferred(AxisIndicesArray(A_fixed));
        A_static_axes = @inferred(AxisIndicesArray(A_static));

        @test @inferred(axes(A_fixed_axes)) isa Tuple{SimpleAxis{Int64,OneTo{Int64}},SimpleAxis{Int64,OneTo{Int64}}}
        @test @inferred(axes(A_static_axes)) isa Tuple{SimpleAxis{Int64,UnitSRange{Int64,1,2}},SimpleAxis{Int64,UnitSRange{Int64,1,2}}}
    end

    @testset "AxisIndicesArray(::AbstractArray, ::Tuple{Keys...})" begin
        A_fixed_axes = @inferred(AxisIndicesArray(A_fixed, (["a", "b"], [:one, :two])))
        A_static_axes = @inferred(AxisIndicesArray(A_static))

        @test isa(@inferred(axes(A_fixed_axes)),
                  Tuple{SimpleAxis{Int64,OneToMRange{Int64}},SimpleAxis{Int64,OneToMRange{Int64}}})
        @test isa(@inferred(axes(A_static_axes)),
                  Tuple{SimpleAxis{Int64,OneToSRange{Int64,2}},SimpleAxis{Int64,OneToSRange{Int64,2}}})
    end

    @testset "AxisIndicesArray(::Array{T,0})" begin
        A = AxisIndicesArray(Array{Int,0}(undef, ()))
    end

    @testset "AxisIndicesArray{T,N}(::AbstractArray...)" begin
        @test parent_type(@inferred(AxisIndicesArray{Int,2}(ones(2,2), (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int,2}(ones(2,2), ["a", "b"], [:one, :two]))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int,2}(ones(2,2), (2, 2)))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int,2}(ones(2,2), 2, 2))) <: Array{Int,2}

    end

    # FIXME
    @testset "AxisIndicesArray{T}(::AbstractArray...)" begin
        @test parent_type(@inferred(AxisIndicesArray{Int}(ones(2,2), (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int}(ones(2,2), ["a", "b"], [:one, :two]))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int}(ones(2,2), (2, 2)))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int}(ones(2,2), 2, 2))) <: Array{Int,2}

    end

    @testset "AxisIndicesArray(undef, ::Tuple{Keys...})" begin
        @test parent_type(@inferred(AxisIndicesArray{Int}(undef, (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int}(undef, ["a", "b"], [:one, :two]))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int}(undef, (2, 2)))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int}(undef, 2, 2))) <: Array{Int,2}

        @test parent_type(@inferred(AxisIndicesArray{Int,2}(undef, (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int,2}(undef, ["a", "b"], [:one, :two]))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int,2}(undef, (2, 2)))) <: Array{Int,2}
        @test parent_type(@inferred(AxisIndicesArray{Int,2}(undef, 2, 2))) <: Array{Int,2}
    end

end


@testset "column methods" begin
    A = AxisIndicesArray(ones(2,2), ["a", "b"], [:one, :two])
    @test @inferred(colaxis(A)) isa Axis{Symbol,Int64,Array{Symbol,1},Base.OneTo{Int64}}
    @test @inferred(colkeys(A)) == [:one, :two]
    @test @inferred(coltype(A)) <: Axis{Symbol,Int64,Array{Symbol,1},Base.OneTo{Int64}}
end

@testset "row methods" begin
    A = AxisIndicesArray(ones(2,2), ["a", "b"], [:one, :two])
    @test @inferred(rowaxis(A)) isa Axis{String,Int64,Array{String,1},Base.OneTo{Int64}}
    @test @inferred(rowkeys(A)) == ["a", "b"]
    @test @inferred(rowtype(A)) <: Axis{String,Int64,Array{String,1},Base.OneTo{Int64}}
end

#=
@testset "to_axis-dynamic" begin
    @test isa(@inferred(to_axis(["a", "b"], as_dynamic(axes(A_, 1)))),
              Axis{String,Int64,Array{String,1},OneToMRange{Int64}})

    @test isa(@inferred(to_axis(1:2, as_dynamic(axes(A_dynamic, 1)))),
              Axis{Int64,Int64,UnitMRange{Int64},OneToMRange{Int64}})

    @test isa(@inferred(to_axis(axes(A_dynamic, 1), as_dynamic(axes(A_dynamic, 1)))),
              SimpleAxis{Int64,OneToMRange{Int64}})
end

@inferred(as_static(["a", "b"], Val((2,))))

@testset "to_axis-dynamic" begin
    @test isa(@inferred(to_axis(["a", "b"], axes(A_static, 1))),
              Axis{String,Int64,SArray{Tuple{2},String,1,2},UnitSRange{Int64,1,2}})

    @test isa(@inferred(to_axis(1:2, axes(A_static, 1))),
              Axis{String,Int64,Array{String,1},OneToMRange{Int64}})

    @test isa(@inferred(to_axis(axes(A_static, 1), axes(A_static, 1))),
              SimpleAxis{Int64,OneToMRange{Int64}})
end

@testset "to_axis-static" begin
    typeof(as_axis(A_dynamic, ["a", "b"], axes(A_dynamic, 1), check_length))
end

=#

