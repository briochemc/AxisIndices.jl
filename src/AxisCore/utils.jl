
function check_axis_length(ks, vs)
    if length(ks) != length(vs)
        throw(DimensionMismatch("keys and indices must have same length, got length(keys) = $(length(ks)) and length(indices) = $(length(vs))."))
    end
    return nothing
end

maybe_first(x::Tuple{}) = ()
maybe_first(x::Tuple) = first(x)
#maybe_first(x::Tuple{<:Tuple,<:Tuple}) = (first(first(x)), first(last(x)))

maybe_tail(::Tuple{}) = ()
maybe_tail(x::Tuple) = tail(x)
#maybe_tail(x::Tuple{<:Tuple,<:Tuple}) = (tail(first(x)), tail(last(x)))

# handle offsets
@inline function k2v(axis::A, index::AbstractVector) where {A<:AbstractAxis}
    if StaticRanges.has_offset_axes(A)
        if StaticRanges.has_offset_axes(keys_type(A))
            return index .+ (first(axis) - firstindex(keys(axis)))
        else
            return index .+ (first(axis) - 1)
        end
    else
        if StaticRanges.has_offset_axes(keys_type(A))
            return index .+ (firstindex(keys(axis)) - 1)
        else
            return index
        end
    end
end

# move index from key indices space to values indices space
@inline function k2v(axis::A, index::Integer) where {A<:AbstractAxis}
    if StaticRanges.has_offset_axes(A)
        if StaticRanges.has_offset_axes(keys_type(A))
            return index + (first(axis) - firstindex(keys(axis)))
        else
            return index + (first(axis) - 1)
        end
    else
        if StaticRanges.has_offset_axes(keys_type(A))
            return index + (firstindex(keys(axis)) - 1)
        else
            return index
        end
    end
end

## values -> keys
@inline function v2k(axis::A, index::AbstractVector) where {A<:AbstractAxis}
    if StaticRanges.has_offset_axes(A)
        if StaticRanges.has_offset_axes(keys_type(A))
            return index .+ (firstindex(keys(axis)) - first(axis))
        else
            return index .+ (1 - first(axis))
        end
    else
        if StaticRanges.has_offset_axes(keys_type(A))
            return index .+ (1 - firstindex(keys(axis)))
        else
            return index
        end
    end
end

@inline function v2k(axis::A, index::Integer) where {A<:AbstractAxis}
    if StaticRanges.has_offset_axes(A)
        if StaticRanges.has_offset_axes(keys_type(A))
            return index + (firstindex(keys(axis)) - first(axis))
        else
            return index + (1 - first(axis))
        end
    else
        if StaticRanges.has_offset_axes(keys_type(A))
            return index + (1 - firstindex(keys(axis)))
        else
            return index
        end
    end
end

naxes(A, v::Val{N}) where {N} = ntuple(i -> axes(A, i), v)

