function synthesise_coupler(n::Int, _K, _BW_REL, POLYNOMIAL = :Butterworth)
    # POLYNOMIAL = :Butterworth
    # POLYNOMIAL = :Chebyshev

    # Parse inputs to desired precision (input string in ord)
    K = isa(_K, String) ? parse(BigFloat, _K) : convert(BigFloat, _K)
    BW_REL = isa(_BW_REL, String) ? parse(BigFloat, _BW_REL) : convert(BigFloat, _BW_REL)

    # Polynomial for pole extraction
    P_x̄ = -design_polynomial(POLYNOMIAL, n-1, BigFloat, :x̄)


    # Calculate related constants
    tc = tand(45 * (1 - BW_REL/2))      # Always a real number
	xc = real(x(im*tc))                 # Always a real number
    K_ = parse(BigFloat,"0.5") * K * P_x̄.coeffs[end];

	# Design function for calculations
	Γ_T(t) = parse(BigFloat,"0.5") * K * t * P_x̄(x(t)/xc)

    ## REFLECTION COEFFICIENT
    # Polynomial roots
    r̄ = roots(P_x̄)

    # Numerator zeros
    Z_n = begin
        # Preallocate zeros (for both functions and add )
        local Z_n = zeros(Complex{BigFloat}, 2n-1)
        for i in eachindex(r̄)
            Z_n[2i:(2i+1)] = [im, -im] .* sqrt((1-xc*r̄[i])/(1+xc*r̄[i]))
        end
        Z_n
    end
    
    # Denominator zeros
    LHS = Polynomial(xc .* BigFloat[1,0,-1], :t)^(n-1)
    RHS = begin
        local RHS_ = K_ * Polynomial(BigFloat[0,1], :t);
        for i in eachindex(r̄)
            RHS_ = RHS_ * 
                (Polynomial(BigFloat[1,0,1], :t) - xc*r̄[i]*Polynomial(BigFloat[1,0,-1], :t))
        end
        RHS_
    end
    Z_d = begin
        Z_d_a = roots(LHS - RHS);
        Z_d_b = roots(LHS + RHS);
        # Join roots from both parentheses
        Z_d_ = vcat(Z_d_a, Z_d_b);
        # Select only left half-plane
        Z_d = Z_d_[sortperm(real.(Z_d_))[1:2n-1]]
    end

    # Coefficient reconstruction
    Γ_N = -1 * Polynomial(real.(fromroots(Complex{BigFloat}.(Z_n)).coeffs), :t)
    Γ_D = Polynomial(real.(fromroots(Complex{BigFloat}.(Z_d)).coeffs), :t)
    Γ(t) = (Γ_N(t)/Γ_D(t))


    ## TRANSMISSION COEFFICIENT
    _Kt = sqrt(abs(((LHS+RHS)*(LHS-RHS)).coeffs[end]))
	T(t) = -LHS(t)/(_Kt * Γ_D(t))


    ## DARLINGTON SYNTHESIS
    # Preallocate vectors
    a = Vector{BigFloat}(undef, n)
    b = Vector{BigFloat}(undef, n-1)

    # Initial admittance functions
    Y_N = Γ_D - Γ_N;    # Numerator of admittance
    Y_D = Γ_D + Γ_N;    # Denominator of admittance
    dY_in = polynomial_fraction_derivative(Y_N, Y_D) # Derivative of admittance

    # Extract first branch as an open-circuit stub
    a[1] = dY_in(1)
    a[end] = a[1]

    # Update input admittance and derivative
    Y_N = Y_N - a[1] * Polynomial(BigFloat[0,1], :t) * Y_D
    Y_D = Y_D
    dY_in = polynomial_fraction_derivative(Y_N, Y_D)

    # Iterate through all "transmission line followed by shunt open-circuit stub" sections
    for i in 2:Int(floor(n/2)+1)
        # Extract transmission line
        b[i-1] = Y_N(1)/Y_D(1)
        b[end-i+2] = b[i-1]

        # Get new admittance
        # Calculate numerator and denominator naïvely
        Y_N_ = Y_N * Polynomial(BigFloat[1,0,1], :t) * b[i-1] - 
            2 * Y_D * Polynomial(BigFloat[0,1], :t) * (b[i-1]^2)
        Y_D_ = Y_D * Polynomial(BigFloat[1,0,1], :t) * b[i-1] - 
            2 * Y_N * Polynomial(BigFloat[0,1], :t)
        # Remove common roots
        rn = roots(Y_N_) # Roots of naïve numerator
        rd = roots(Y_D_) # Roots of naïve denominator
        _goodi = fill(true,length(rn)); # Flags for non-common root
        for j in eachindex(rn)
            # Find first root in common within the range of precision 
            #   of reconstructed function
            k = findfirst(isapprox.(rn[j], rd, atol = eps(Float64(abs(rn[j])))))
            # If there exists, pop from denominator and flag as common root for numerator
            isnothing(k) || (_goodi[j] = false; popat!(rd,k))
        end
        rn = rn[_goodi]; # Remove numerator common roots
        # Get coefficients with potentially spurious imaginary parts
        c_Y_N = (Y_N_.coeffs[end] * fromroots(Complex{BigFloat}.(rn); var = :t)).coeffs
        c_Y_D = (Y_D_.coeffs[end] * fromroots(Complex{BigFloat}.(rd); var = :t)).coeffs
        # Build admittance functions without spurious imaginary parts
        Y_N = Polynomial(real.(c_Y_N), :t)
        Y_D = Polynomial(real.(c_Y_D), :t)
        dY_in = polynomial_fraction_derivative(Y_N, Y_D)

        # Extract shunt line
        a[i] = dY_in(1)
        a[end-i+1] = a[i]

        # Prepare next admittance
        Y_N = Y_N - a[i] * Polynomial(BigFloat[0,1], :t) * Y_D
        Y_D = Y_D
        dY_in = polynomial_fraction_derivative(Y_N, Y_D)
    end

    return Coupler(a, b)
end

@inline x(t) = (1 + t^2) / (1 - t^2)

@inline t²(x) = (x-1)/(x+1)

@inline t(x) = sqrt(Complex(t²(x)))

function design_polynomial(family, degree, type_precision = Float64, polyvar = :x)
	p = zeros(type_precision, degree+1)
	p[end] = 1
    if family == :Butterworth
        return Polynomial(p, polyvar)
    elseif family == :Chebyshev
        return convert(Polynomial{type_precision}, ChebyshevT(p, polyvar))
    end
end

function polynomial_fraction_derivative(N, D)
	dN = derivative(N)
	dD = derivative(D)
	return (t) -> ((dN(t)*D(t) - dD(t)*N(t))/((D(t))^2))
end