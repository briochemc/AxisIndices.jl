
# We can't specify Vs<:AbstractUnitRange b/c it does some really bizarre things
# to internal inferrence code on some versions of Julia. It ends up spitting out
# a bunch of references to "intersect"/"intersect_all"/"intersect_asied"/etc in "subtype.c"
"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{K,V<:Integer,Ks,Vs} <: AbstractUnitRange{V} end

"""
    AbstractSimpleAxis{V,Vs}

A subtype of `AbstractAxis` where the keys and values are represented by a single collection.
"""
abstract type AbstractSimpleAxis{V,Vs} <: AbstractAxis{V,V,Vs,Vs} end

Base.keytype(::Type{<:AbstractAxis{K}}) where {K} = K

Base.haskey(a::AbstractAxis{K}, key::K) where {K} = key in keys(a)

"""
    keys_type(x)

Retrieves the type of the keys of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> keys_type(Axis(1:2))
UnitRange{Int64}

julia> keys_type(typeof(Axis(1:2)))
UnitRange{Int64}

julia> keys_type(UnitRange{Int})
Base.OneTo{Int64}
```
"""
keys_type(::T) where {T} = keys_type(T)
keys_type(::Type{T}) where {T} = OneTo{Int}  # default for things is usually LinearIndices{1}
keys_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Ks

Base.valtype(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = V

"""
    rowaxis(x) -> axis

Returns the axis corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> rowaxis(AxisIndicesArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis(["a", "b"] => Base.OneTo(2))

```
"""
rowaxis(x) = axes(x, 1)

"""
    rowkeys(x) -> axis

Returns the keys corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> rowkeys(AxisIndicesArray(ones(2,2), ["a", "b"], [:one, :two]))
2-element Array{String,1}:
 "a"
 "b"

```
"""
rowkeys(x) = keys(axes(x, 1))

"""
    rowtype(x)

Returns the type of the axis corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> rowtype(AxisIndicesArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis{String,Int64,Array{String,1},Base.OneTo{Int64}}
```
"""
rowtype(::T) where {T} = rowtype(T)
rowtype(::Type{T}) where {T} = axes_type(T, 1)

"""
    colaxis(x) -> axis

Returns the axis corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> colaxis(AxisIndicesArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis([:one, :two] => Base.OneTo(2))

```
"""
colaxis(x) = axes(x, 2)

"""
    coltype(x)

Returns the type of the axis corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> coltype(AxisIndicesArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis{Symbol,Int64,Array{Symbol,1},Base.OneTo{Int64}}
```
"""
coltype(::T) where {T} = coltype(T)
coltype(::Type{T}) where {T} = axes_type(T, 2)

"""
    colkeys(x) -> axis

Returns the keys corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> colkeys(AxisIndicesArray(ones(2,2), ["a", "b"], [:one, :two]))
2-element Array{Symbol,1}:
 :one
 :two

```
"""
colkeys(x) = keys(axes(x, 2))

"""
    values_type(x)

Retrieves the type of the values of `x`. This should be functionally equivalent
to `typeof(values(x))`.

## Examples
```jldoctest
julia> using AxisIndices

julia>  values_type(Axis(1:2))
Base.OneTo{Int64}

julia> values_type(typeof(Axis(1:2)))
Base.OneTo{Int64}

julia> values_type(typeof(1:2))
UnitRange{Int64}
```
"""
values_type(::T) where {T} = values_type(T)
# if it's not a subtype of AbstractAxis assume it is the collection of values
values_type(::Type{T}) where {T} = T  
values_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Vs

"""
    indices(x::AbstractAxis)

Returns the indices `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(Axis(["a"], 1:1))
1:1

julia> indices(CartesianIndex(1,1))
(1, 1)

```
"""
indices(x::AbstractAxis) = values(x)
indices(x::CartesianIndex) = getfield(x, :I)

# FIXME this explanation is confusing.
"""
    axis_eltype(x)

Returns the type corresponds to the type of the ith element returned when slicing
along that dimension.
"""
axis_eltype(axis, i) = Any

# TODO document
axis_eltypes(axis) = Tuple{[axis_eltype(axis, i) for i in axis]...}
@inline axis_eltypes(axis, vs::AbstractVector) = Tuple{map(i -> axis_eltype(axis, i), vs)...}

###
### first
###
Base.first(a::AbstractAxis) = first(values(a))
function StaticRanges.can_set_first(::Type{T}) where {T<:AbstractAxis}
    return StaticRanges.can_set_first(keys_type(T))
end
function StaticRanges.set_first!(x::AbstractAxis{K,V}, val::V) where {K,V}
    StaticRanges.can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    StaticRanges.resize_first!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_first(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_first(values(x), val)
    return unsafe_reconstruct(x, StaticRanges.resize_first(keys(x), length(vs)), vs)
end

function StaticRanges.set_first(x::AbstractSimpleAxis{V}, val::V) where {V}
    return unsafe_reconstruct(x, set_first(values(x), val))
end
function StaticRanges.set_first!(x::AbstractSimpleAxis{V}, val::V) where {V}
    StaticRanges.can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    return x
end

Base.firstindex(a::AbstractAxis) = first(values(a))

"""
    first_key(x)

Returns the first key of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> first_key(Axis(2:10))
2
```
"""
first_key(x) = first(keys(x))

###
### last
###
Base.last(a::AbstractAxis) = last(values(a))
function StaticRanges.can_set_last(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs}
    return StaticRanges.can_set_last(Ks) & StaticRanges.can_set_last(Vs)
end
function StaticRanges.set_last!(x::AbstractAxis{K,V}, val::V) where {K,V}
    StaticRanges.can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    StaticRanges.resize_last!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_last(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_last(values(x), val)
    return unsafe_reconstruct(x, StaticRanges.resize_last(keys(x), length(vs)), vs)
end

function StaticRanges.set_last!(x::AbstractSimpleAxis{V}, val::V) where {V}
    StaticRanges.can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    return x
end

function StaticRanges.set_last(x::AbstractSimpleAxis{K}, val::K) where {K}
    return unsafe_reconstruct(x, set_last(values(x), val))
end

Base.lastindex(a::AbstractAxis) = last(values(a))

"""
    last_key(x)

Returns the last key of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> last_key(Axis(2:10))
10
```
"""
last_key(x) = last(keys(x))

###
### length
###
Base.length(a::AbstractAxis) = length(values(a))

function StaticRanges.can_set_length(::Type{T}) where {T<:AbstractAxis}
    return StaticRanges.can_set_length(keys_type(T)) & StaticRanges.can_set_length(values_type(T))
end

function StaticRanges.set_length!(a::AbstractAxis{K,V,Ks,Vs}, len) where {K,V,Ks,Vs}
    StaticRanges.can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
    set_length!(keys(a), len)
    set_length!(values(a), len)
    return a
end
#function StaticRanges.can_set_length(::Type{<:AbstractSimpleAxis{V,Vs}}) where {V,Vs}
#    return can_set_length(Vs)
#end
function StaticRanges.set_length!(a::AbstractSimpleAxis{V,Vs}, len) where {V,Vs}
    StaticRanges.can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
    StaticRanges.set_length!(values(a), len)
    return a
end

function StaticRanges.set_length(a::AbstractAxis{K,V,Ks,Vs}, len) where {K,V,Ks,Vs}
    return unsafe_reconstruct(a, set_length(keys(a), len), set_length(values(a), len))
end

function StaticRanges.set_length(x::AbstractSimpleAxis{V,Vs}, len) where {V,Vs}
    return unsafe_reconstruct(x, StaticRanges.set_length(values(x), len))
end

StaticRanges.Length(::Type{<:AbstractAxis{K,Ks,V,Vs}}) where {K,Ks,V,Vs} = Length(Vs)

###
### step
###
Base.step(a::AbstractAxis) = step(values(a))

Base.step_hp(a::AbstractAxis) = Base.step_hp(values(a))

"""
    step_key(x)

Returns the step size of the keys of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.step_key(Axis(1:2:10))
2

julia> AxisIndices.step_key(rand(2))
1

julia> AxisIndices.step_key([1])  # LinearIndices are treate like unit ranges
1
```
"""
@inline step_key(x::AbstractVector) = _step_keys(keys(x))
_step_keys(ks) = step(ks)
_step_keys(ks::LinearIndices) = 1

StaticRanges.Size(::Type{T}) where {T<:AbstractAxis} = StaticRanges.Size(values_type(T))

Base.size(a::AbstractAxis) = (length(a),)

"""
    unsafe_reconstruct(axis::AbstractAxis, keys::Ks, values::Vs)

Reconstructs an `AbstractAxis` of the same type as `axis` but with keys of type `Ks` and values of type `Vs`.
This method is considered unsafe because it bypasses checks  to ensure that `keys` and `values` have the same length and the all `keys` are unique.
"""
function unsafe_reconstruct(a::AbstractAxis, ks::Ks, vs::Vs) where {Ks,Vs}
    return similar_type(a, Ks, Vs)(ks, vs)
end

"""
    unsafe_reconstruct(axis::AbstractSimpleAxis, values::Vs)

Reconstructs an `AbstractSimpleAxis` of the same type as `axis` but values of type `Vs`.
"""
unsafe_reconstruct(a::AbstractSimpleAxis, vs::Vs) where {Vs} = similar_type(a, Vs)(vs)

###
### similar
###

function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
) where {A<:AbstractAxis}

    return similar_type(A, ks_type, vs_type)
end

function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=ks_type
) where {A<:AbstractSimpleAxis}

    return similar_type(A, vs_type)
end

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two])
Axis([:one, :two] => 1:2)
```
"""
function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractVector{T}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    if is_static(axis)
        return unsafe_reconstruct(
            axis,
            as_static(new_keys),
            as_static(set_length(values(axis), length(new_keys)))
        )
    elseif is_fixed(axis)
        return unsafe_reconstruct(
            axis,
            as_fixed(new_keys),
            as_fixed(set_length(values(axis), length(new_keys)))
        )
    else
        return unsafe_reconstruct(
            axis,
            as_dynamic(new_keys),
            as_dynamic(set_length(values(axis), length(new_keys)))
        )
    end
end

function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractUnitRange{T}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    if is_static(axis)
        return unsafe_reconstruct(
            axis,
            as_static(new_keys),
            as_static(set_length(values(axis), length(new_keys)))
        )
    elseif is_fixed(axis)
        return unsafe_reconstruct(
            axis,
            as_fixed(new_keys),
            as_fixed(set_length(values(axis), length(new_keys)))
        )
    else
        return unsafe_reconstruct(
            axis,
            as_dynamic(new_keys),
            as_dynamic(set_length(values(axis), length(new_keys)))
        )
    end
end

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector, new_indices::AbstractUnitRange{Integer} [, check_length::Bool=true] ) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`
and indices `new_indices`. If `check_length` is `true` then the lengths of `new_keys`
and `new_indices` are checked to ensure they have the same length before construction.

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(2))
Axis([:one, :two] => 0x0000000000000001:0x0000000000000002)

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(3))
ERROR: DimensionMismatch("keys and indices must have same length, got length(keys) = 2 and length(indices) = 3.")
[...]
```
"""
function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractVector{T},
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    check_length && check_axis_length(new_keys, new_indices)
    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys), as_static(new_indices))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys), as_fixed(new_indices))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys), as_dynamic(new_indices))
    end
end

function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractUnitRange{T},
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    check_length && check_axis_length(new_keys, new_indices)
    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys), as_static(new_indices))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys), as_fixed(new_indices))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys), as_dynamic(new_indices))
    end
end

"""
    similar(axis::AbstractSimpleAxis, new_indices::AbstractUnitRange{Integer}) -> AbstractSimpleAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(SimpleAxis(1:10), 1:3)
SimpleAxis(1:3)
```
"""
function Base.similar(
    axis::AbstractSimpleAxis{V,Vs},
    new_keys::AbstractUnitRange{T}
) where {V<:Integer,Vs<:AbstractUnitRange{V},T}

    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys))
    end
end

const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}

# Vectors should have a mutable axis
true_axes(x::Vector) = (OneToMRange(length(x)),)
true_axes(x) = axes(x)
true_axes(x::Vector, i) = (OneToMRange(length(x)),)
true_axes(x, i) = axes(x, i)

# :resize_first!, :resize_last! don't need to define these ones b/c non mutating ones are only
# defined to avoid ambiguities with methods that pass AbstractUnitRange{<:Integer} instead of Integer
for f in (:grow_last!, :grow_first!, :shrink_last!, :shrink_first!)
    @eval begin
        function StaticRanges.$f(axis::AbstractSimpleAxis, n::Integer)
            StaticRanges.$f(values(axis), n)
            return axis
        end

        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            StaticRanges.$f(keys(axis), n)
            StaticRanges.$f(values(axis), n)
            return axis
        end
    end
end

for f in (:grow_last, :grow_first, :shrink_last, :shrink_first, :resize_first, :resize_last)
    @eval begin
        function StaticRanges.$f(axis::AbstractSimpleAxis, n::Integer)
            return unsafe_reconstruct(axis, StaticRanges.$f(values(axis), n))
        end

        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(keys(axis), n),
                StaticRanges.$f(values(axis), n)
            )
        end

        function StaticRanges.$f(axis::AbstractSimpleAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, n)
        end

        function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, StaticRanges.$f(keys(axis), length(n)), n)
        end
    end
end

#= assign_indices(axis, indices)

Reconstructs `axis` but with `indices` replacing the indices/values.
There shouldn't be any change in size of the indices.
=#
assign_indices(axs::AbstractSimpleAxis, inds) = similar(axs, inds)
assign_indices(axis::AbstractAxis, inds) = unsafe_reconstruct(axis, keys(axis), inds)

"""
    axes_keys(x) -> Tuple

Returns the keys corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(2:3, 3:4)

julia> axes_keys(Axis(1:2))
(1:2,)
```
"""
axes_keys(x) = map(keys, axes(x))
axes_keys(x::AbstractAxis) = (keys(x),)

"""
    axes_keys(x, i)

Returns the axis keys corresponding of ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
2:3
```
"""
axes_keys(x, i) = axes_keys(x)[i]  # FIXME this needs to be changed to support named dimensions

"""
    keys_type(x, i)

Retrieves axis keys of the ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> keys_type(AxisIndicesArray([1], ["a"]), 1)
Array{String,1}
```
"""
keys_type(::T, i) where {T} = keys_type(T, i)
keys_type(::Type{T}, i) where {T} = keys_type(axes_type(T, i))

"""
    values_type(x, i)

Retrieves axis values of the ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> values_type([1], 1)
Base.OneTo{Int64}

julia> values_type(typeof([1]), 1)
Base.OneTo{Int64}
```
"""
values_type(::T, i) where {T} = values_type(T, i)
values_type(::Type{T}, i) where {T} = values_type(axes_type(T, i))

"""
    indices(x, i)

Returns the indices corresponding to the `i` axis

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
Base.OneTo(2)
```
"""
indices(x, i) = values(axes(x, i))

"""
    indices(x) -> Tuple

Returns the indices corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(Base.OneTo(2), Base.OneTo(2))

julia> indices(Axis(["a"], 1:1))
1:1

julia> indices(CartesianIndex(1,1))
(1, 1)

```
"""
indices(x) = map(values, axes(x))

Base.allunique(a::AbstractAxis) = true

Base.in(x::Integer, a::AbstractAxis) = in(x, values(a))

Base.collect(a::AbstractAxis) = collect(values(a))

Base.eachindex(a::AbstractAxis) = values(a)

function reverse_keys(old_axis::AbstractAxis, new_index::AbstractUnitRange)
    return similar(old_axis, reverse(keys(old_axis)), new_index, false)
end

function reverse_keys(old_axis::AbstractSimpleAxis, new_index::AbstractUnitRange)
    return Axis(reverse(keys(old_axis)), new_index, false)
end

#Base.axes(a::AbstractAxis) = values(a)

# This is required for performing `similar` on arrays
Base.to_shape(r::AbstractAxis) = length(r)

# for when we want the same underlying memory layout but reversed keys
# TODO should this be a formal abstract type?
const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}


# TODO this should all be derived from the values of the axis
# Base.stride(x::AbstractAxisIndices) = axes_to_stride(axes(x))
#axes_to_stride()

Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))

