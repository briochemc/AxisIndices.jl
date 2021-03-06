
# TODO figure out how to place type inference of each field into indexing
@generated _fieldcount(::Type{T}) where {T} = fieldcount(T)

"""
    StructAxis{T}

An axis that uses a structure `T` to form its keys. the field names of
"""
struct StructAxis{T,L,V,Vs} <: AbstractAxis{Symbol,V,SVector{L,Symbol},Vs}
    values::Vs

    function StructAxis{T,L,V,Vs}(inds::Vs) where {T,L,V,Vs}
        # FIXME should unwrap_unionall be performed earlier?
        return new{T,L,V,Vs}(inds)
    end
end

StructAxis{T}() where {T} = StructAxis{T,_fieldcount(T)}()

StructAxis{T}(vs::AbstractUnitRange) where {T} = StructAxis{T,_fieldcount(T)}(vs)

@inline StructAxis{T,L}() where {T,L} = StructAxis{T,L}(OneToSRange{Int,L}())

function StructAxis{T,L}(inds::I) where {I<:AbstractUnitRange{<:Integer},T,L}
    if is_static(I)
        return StructAxis{T,L,eltype(I),I}(inds)
    else
        return StructAxis{T,L}(as_static(inds))
    end
end

@inline Base.keys(::StructAxis{T,L}) where {T,L} = SVector(fieldnames(T))::SVector{L,Symbol}

Base.values(axis::StructAxis) = getfield(axis, :values)

axis_eltype(::StructAxis{T}, i) where {T} = fieldtype(T, i)

function StaticRanges.similar_type(
    ::Type{StructAxis{T,L,V,Vs}},
    new_type::Type=T,
    new_vals::Type=OneToSRange{Int,nfields(T)}
) where {T,L,V,Vs}

    return StructAxis{T,nfields(T),eltype(new_vals),new_vals}
end

# `ks` should always be a `<:AbstractVector{Symbol}`
@inline function unsafe_reconstruct(axis::StructAxis, ks, vs)
    return StructAxis{NamedTuple{Tuple(ks),axis_eltypes(axis, ks)}}(vs)
end

assign_indices(axis::StructAxis{T}, inds) where {T} = StructAxis{T}(inds)

@inline function structdim(A)
    d = _structdim(axes_type(A))
    if d === 0
        error()
    else
        return d
    end
end


Base.@pure function _structdim(::Type{T}) where {T<:Tuple}
    for i in OneTo(length(T.parameters))
        T.parameters[i] <: StructAxis && return i
    end
    return 0
end

structaxis(x) = axes(x, structdim(x))

function to_index_type(axis::StructAxis{T}, arg) where {T}
    return fieldtype(T, to_index(axis, arg))
end

_fieldnames(::StructAxis{T}) where {T} = Tuple(T.name.names)

# get elemen type of `T` at field `i`
axis_index_eltype(::T) where {T} = axis_index_eltype(T)
axis_index_eltype(::Type{<:StructAxis{T}}) where {T} = T

axis_index_eltype(::T, i) where {T} = axis_index_eltype(T, i)
axis_index_eltype(::Type{<:StructAxis{T}}, i::Integer) where {T} = fieldtype(T, i)
axis_index_eltype(::Type{<:StructAxis{T}}, i::Colon) where {T} = T
axis_index_eltype(::Type{<:AbstractAxis}, i::Integer) = Any
@inline function axis_index_eltype(::Type{T}, inds::AbstractVector) where {T}
    return NamedTuple{
        ([fieldname(T, i) for i in inds]...),
        Tuple{[fieldtype(T, i) for i in inds]...}
    }
end

function to_axis(
    ks::StructAxis{T},
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(vs)
) where {T}

    check_length && check_axis_length(ks, vs)
    return StructAxis{T}(vs)
end

# TODO This documentation is confusing...but I'm tired right now.
"""
    structview(A)

Creates a `MappedArray` using the `StructAxis` of `A` to identify the dimension
that needs to be collapsed into a series of `SubArray`s as views that composed
the `MappedArray`
"""
@inline structview(A) = _structview(A, structdim(A))
@inline _structview(A, dim) = _structview(A, dim, axes(A, dim))
@inline function _structview(A, dim, axis::StructAxis{T}) where {T}
    inds_before = ntuple(d->(:), dim-1)
    inds_after = ntuple(d->(:), ndims(A)-dim)
    return mappedarray(T, (view(A, inds_before..., i, inds_after...) for i in values(axis))...)
end

@inline function _structview(A, dim, axis::StructAxis{T}) where {T<:NamedTuple}
    inds_before = ntuple(d->(:), dim-1)
    inds_after = ntuple(d->(:), ndims(A)-dim)
    return mappedarray((args...) ->T(args) , (view(A, inds_before..., i, inds_after...) for i in values(axis))...)
end


