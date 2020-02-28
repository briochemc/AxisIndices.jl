"""
    matmul_axes(a, b) -> Tuple

Returns the appropriate axes for the return of `a * b` where `a` and `b` are a
vector or matrix.

## Examples
```jldoctest
julia> using AxisIndices

julia> axs2, axs1 = (Axis(1:2), Axis(1:4)), (Axis(1:6),);

julia> matmul_axes(axs2, axs2)
(Axis(1:2 => Base.OneTo(2)), Axis(1:4 => Base.OneTo(4)))

julia> matmul_axes(axs1, axs2)
(Axis(1:6 => Base.OneTo(6)), Axis(1:4 => Base.OneTo(4)))

julia> matmul_axes(axs2, axs1)
(Axis(1:2 => Base.OneTo(2)),)

julia> matmul_axes(axs1, axs1)
()

julia> matmul_axes(rand(2, 4), rand(4, 2))
(Base.OneTo(2), Base.OneTo(2))

julia> matmul_axes(CartesianAxes((2,4)), CartesianAxes((4, 2))) == matmul_axes(rand(2, 4), rand(4, 2))
true
```
"""
matmul_axes(a::AbstractArray,  b::AbstractArray ) = matmul_axes(axes(a), axes(b))
matmul_axes(a::Tuple{Any},     b::Tuple{Any,Any}) = (first(a), last(b))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any,Any}) = (first(a), last(b))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any}    ) = (first(a),)
matmul_axes(a::Tuple{Any},     b::Tuple{Any}    ) = ()

for (N1,N2) in ((2,2), (1,2), (2,1))
    @eval begin
        function Base.:*(a::AbstractAxisIndices{T1,$N1}, b::AbstractAxisIndices{T2,$N2}) where {T1,T2}
            return _matmul(a, promote_type(T1, T2), *(parent(a), parent(b)), to_axis(a, matmul_axes(a, b)))
        end
        function Base.:*(a::AbstractArray{T1,$N1}, b::AbstractAxisIndices{T2,$N2}) where {T1,T2}
            return _matmul(b, promote_type(T1, T2), *(a, parent(b)), to_axis(b, matmul_axes(a, b)))
        end
        function Base.:*(a::AbstractAxisIndices{T1,$N1}, b::AbstractArray{T2,$N2}) where {T1,T2}
            return _matmul(a, promote_type(T1, T2), *(parent(a), b), to_axis(a, matmul_axes(a, b)))
        end
    end
end

function Base.:*(a::Diagonal{T1}, b::AbstractAxisIndices{T2,2}) where {T1,T2}
    return _matmul(b, promote_type(T1, T2), *(a, parent(b)), to_axis(b, matmul_axes(a, b)))
end
function Base.:*(a::AbstractAxisIndices{T1,2}, b::Diagonal{T2}) where {T1,T2}
    return _matmul(a, promote_type(T1, T2), *(parent(a), b), to_axis(a, matmul_axes(a, b)))
end

_matmul(A, ::Type{T}, a::T, axs) where {T} = a
function _matmul(A, ::Type{T}, a::AbstractArray{T}, axs) where {T}
    return similar_type(A, typeof(a), typeof(axs))(a, axs)
end



# Using `CovVector` results in Method ambiguities; have to define more specific methods.
for A in (Adjoint{<:Any, <:AbstractVector}, Transpose{<:Real, <:AbstractVector{<:Real}})
    @eval function Base.:*(a::$A, b::AbstractAxisIndices{T,1,<:AbstractVector{T}}) where {T}
        return *(a, parent(b))
    end
end

# vector^T * vector
Base.:*(a::AbstractAxisIndices{T,2,<:CoVector}, b::AbstractAxisIndices{S,1}) where {T,S} = *(parent(a), parent(b))

