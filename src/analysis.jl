function analysis_functions(c::Coupler)
    # Extract number of branches
    n = length(c.a)

    # Form ABCD matrix
    M = _ABCD_open_stub(c.a[1])
    for i in eachindex(c.b)
        M *= (_ABCD_line(c.b[i]) * _ABCD_open_stub(c.a[i+1]))
    end
    A_ = M[1,1]
    B_ = M[1,2]
    C_ = M[2,1]
    D_ = M[2,2]
    
    # Γₑ_N 
    Γₑ_N = (A_ - D_) + (B_ - C_)

    # Γₑ_D
    Γₑ_D = (A_ + D_ + B_ + C_)

    # Tₑ_N
    Tₑ_N = 2*(Polynomial([1, 0, -1], :t)^(n-1))

    # Create functions
    # Reflection coefficient
    Γ(t) = (1/2) * (Γₑ_N(t)/Γₑ_D(t) + Γₑ_N(1/t)/Γₑ_D(1/t))

    # Directivity
    D(t) = (1/2) * (Γₑ_N(t)/Γₑ_D(t) - Γₑ_N(1/t)/Γₑ_D(1/t))

    # Insertion Loss
    IL(t)  = (1/2) * (Tₑ_N(t)/Γₑ_D(t) + (-1)^(n) * Tₑ_N(1/t)/Γₑ_D(1/t))
    
    # Coupling
    C(t) = (1/2) * (Tₑ_N(t)/Γₑ_D(t) - (-1)^(n) * Tₑ_N(1/t)/Γₑ_D(1/t))

    return (Γ = Γ, D = D, IL = IL, C = C)
end


db(x) = 10*log10(abs2(x))

function _ABCD_open_stub(a)
    A = Polynomial(Float64[1], :t)
    B = Polynomial(Float64[0], :t)
    C = Polynomial(Float64[0, a], :t)
    D = Polynomial(Float64[1], :t)
    return [A B;C D]
end

function _ABCD_line(b)
    A = Polynomial(Float64[1, 0, 1], :t)
    B = Polynomial(Float64[0, 2/b], :t)
    C = Polynomial(Float64[0, 2*b], :t)
    D = Polynomial(Float64[1, 0, 1], :t)
    return [A B;C D] 
end