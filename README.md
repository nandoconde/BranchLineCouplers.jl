# BranchLineCouplers.jl

Synthesize and simulate symmetrical branch line couplers.

## Using this package

There are currently three ways to use this package.

### Analysis

```julia
# Create a coupler
# a is the vector of branch line immittances
# b is the vector of series line immittances
# For now, they should be normalized to 1
a = fill(Float64, 1.0)
b = fill(Float64, 1.0)
coupler = Coupler(a, b)


# Analyze coupler
# Returns, respectively, the reflection coefficient
(Γ, D, IL, C) = 
```

## Source

The procedure used in this package to synthesize and analyze symmetrical branch-line directional couplers is based on:

- R. Levy and L. F. Lind, "Synthesis of Symmetrical Branch-Guide Directional Couplers," in *IEEE Transactions on Microwave Theory and Techniques*, vol. 16, no. 2, pp. 80-89, February 1968, [doi: 10.1109/TMTT.1968.1126612](https://ieeexplore.ieee.org/document/1126612).

It can be readily extended to asymmetrical couplers using the extension given by:

- A. Buesa-Zubiria and J. Esteban, "Design of Broadband Doubly Asymmetrical Branch-Line Directional Couplers," in *IEEE Transactions on Microwave Theory and Techniques*, vol. 68, no. 4, pp. 1439-1451, April 2020, [doi: 10.1109/TMTT.2019.2953904](https://ieeexplore.ieee.org/document/8935491).
