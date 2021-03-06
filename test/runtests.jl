
using Test
using Statistics
using DelimitedFiles
using LinearAlgebra
using StaticRanges
using Documenter
using Dates
using Tables
using AxisIndices
using AxisIndices.AxisCore
using AxisIndices.AxisTables
using AxisIndices.Names
using AxisIndices.Mapped
using AxisIndices: mappedarray, of_eltype, matmul_axes # from MappedArrays
using StaticRanges: can_set_first, can_set_last, can_set_length
using StaticRanges: grow_last, grow_last!, grow_first, grow_first!
using StaticRanges: shrink_last, shrink_last!, shrink_first, shrink_first!, has_offset_axes
#using OffsetArrays

using Base: step_hp, OneTo
using Base.Broadcast: broadcasted
bstyle = Base.Broadcast.DefaultArrayStyle{1}()


struct Axis2{K,V,Ks,Vs} <: AbstractAxis{K,V,Ks,Vs}
    keys::Ks
    values::Vs
end

Axis2(ks, vs) = Axis2{eltype(ks),eltype(vs),typeof(ks),typeof(vs)}(ks, vs)
Base.keys(a::Axis2) = getfield(a, :keys)
Base.values(a::Axis2) = getfield(a, :values)
function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
) where {A<:Axis2}
    return Axis2{eltype(ks_type),eltype(vs_type),ks_type,vs_type}
end

@test Base.to_shape(SimpleAxis(1)) == 1

include("to_index_tests.jl")
include("to_axis_tests.jl")
include("getindex_tests.jl")
include("values_tests.jl")
include("keys_tests.jl")
include("size_tests.jl")
include("pop_tests.jl")
include("popfirst_tests.jl")
include("first_tests.jl")
include("step_tests.jl")
include("last_tests.jl")
include("length_tests.jl")
include("cartesianaxes.jl")
include("linearaxes.jl")
include("append_tests.jl")
include("filter_tests.jl")
include("promotion_tests.jl")
include("similar_tests.jl")
include("resize_tests.jl")

include("reduce_tests.jl")
include("staticness_tests.jl")
include("checkbounds.jl")
include("functions_dims_tests.jl")
include("math_tests.jl")

include("drop_tests.jl")

include("functions_tests.jl")
include("concatenation_tests.jl")
include("array_tests.jl")
include("broadcasting_tests.jl")
include("linear_algebra.jl")

include("mapped_arrays.jl")
include("nameddims_tests.jl")
include("traits_tests.jl")
include("copyto_tests.jl")
include("reshape_tests.jl")

#include("offset_tests.jl")

@testset "pretty_array" begin
    A = AxisIndicesArray(Array{Int,0}(undef, ()))
    @test pretty_array(String, A) == repr(A[1])
end

@testset "ObservationDims" begin
    using AxisIndices.ObservationDims
    nia = NIArray(reshape(1:6, 2, 3), x = 2:3, observations = 3:5)
    @test has_obsdim(nia)
    @test !has_obsdim(parent(nia))
    @test @inferred(obs_keys(nia)) == 3:5
    @test @inferred(nobs(nia)) == 3
    @test @inferred(obs_indices(nia)) == 1:3
    @test @inferred(obsdim(nia)) == 2
    @test @inferred(select_obsdim(nia, 2)) == selectdim(parent(parent(nia)), 2, 2)
    @test @inferred(obs_axis_type(nia)) <: Integer
end

include("structaxis_tests.jl")
include("table_tests.jl")

#= TODO this needs to be formally tested
io = IOBuffer()
pretty_array(io, AxisIndicesArray(reshape(1:33, (1, 11, 3))))
str = String(take!(io))
@test str == "[dim1, dim2, dim3[1]] =\n          1       2       3       4       5       6       7       8       9       10       11  \n  1   1.000   2.000   3.000   4.000   5.000   6.000   7.000   8.000   9.000   10.000   11.000  \n\n\n[dim1, dim2, dim3[2]] =\n           1        2        3        4        5        6        7        8        9       10       11  \n  1   12.000   13.000   14.000   15.000   16.000   17.000   18.000   19.000   20.000   21.000   22.000  \n\n\n[dim1, dim2, dim3[3]] =\n           1        2        3        4        5        6        7        8        9       10       11  \n  1   23.000   24.000   25.000   26.000   27.000   28.000   29.000   30.000   31.000   32.000   33.000  \n"
=#

#include("offset_array_tests.jl")

# this avoids errors due to differences in how Symbols are printing between versions of Julia
if !(VERSION < v"1.4")
    @testset "docs" begin
        doctest(AxisIndices)
    end
end

