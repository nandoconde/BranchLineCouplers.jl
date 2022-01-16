# Object definition
struct Coupler{N, N1}
    a::NTuple{N,Float64}
    b::NTuple{N1,Float64}
    Z₀::Float64
    function Coupler(a, b, Z₀)
        N = length(a)
        N1 = length(b)
        N == N1 + 1 || 
            error("Vector of series transmission lines must be 1 shorter than vector of branches")
        new{N,N1}(a, b, Z₀)
    end
end

# Omitting the impedance
Coupler(a::NTuple, b::NTuple) = Coupler(a, b, 1.0)

# Omitting b
Coupler(a, Z₀::T where {T<:Real} = 1.0) = Coupler(a, ntuple(Returns(Z₀),length(a)-1), Z₀)

Coupler(a::AbstractArray{<:Real}, b::T where{T<:Tuple}, x...) = Coupler(tuple(a...), b, x...)
Coupler(a, b::AbstractArray{<:Real}, x...) = Coupler(a, tuple(b...), x...)

a = [0.0965767, 0.114064, 0.131845, 0.114064, 0.0965767]
b  = [1.02556, 1.04526, 1.04526, 1.02556]
c = Coupler(a,b)