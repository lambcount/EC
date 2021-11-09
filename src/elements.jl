""" sums elements in series

Notes
---------
    Z = Z_1 + Z_2 + ... + Z_n

"""
function series(series)
    if all(length.(series) .== length(series[1])) == true
        z = fill(complex(0,0),length(series[1]))
        for elem in series
            z += elem
        end
        return z
    else
        error("Dimensions in series are not matching.")
    end
end


""" adds elements in parallel

Notes
---------

    Z = \\frac{1}{\\frac{1}{Z_1} + \\frac{1}{Z_2} + ... + \\frac{1}{Z_n}}

 """
function parallel(parallel)

    if all(length.(parallel) .== length(parallel[1])) == true
        z = fill(complex(0,0),length(parallel[1]))
        for elem in parallel
            z += 1 ./elem
        end
        return 1 ./z
    end
end

""" defines a resistor

Notes
---------
units= "Ohm"

    Z = R

"""
function R(p, f)

    R = p[1]
    Z = fill(R,length(f))
    return Z

end

""" defines a capacitor
    
Notes
---------
units= "Ohm"

    Z = \\frac{1}{C \\times j 2 \\pi f}

 """
function C(p, f)

    omega = 2π .* f
    C = p[1]
    Z  = [1.0/(C*1im*omega[i]) for i in 1:length(omega)]
    return Z
end

""" defines an inductor

Notes
---------
units= "H"


    Z = L \\times j 2 \\pi f

 """
function L(p, f)

    omega = 2π .* f
    L = p[1]
    Z  = [L*1im*omega[i] for i in 1:length(omega)]
    return Z
end



""" defines a constant phase element

Notes
-----
units=["Ohm^-1", "s^a",""]

    Z = 1/(Q(i 2πf)^α)

where "Q" = p[1] and α = p[2].
"""
function CPE(p, f)

    omega = 2π .* f
    Q, alpha = p[1], p[2]
    Z  = [1.0/(Q*(1im*omega[i])^alpha) for i in 1:length(omega)]
    return Z
end

"""
defines a semi-infinite Warburg element

Notes
-----
units=[Ohm/√s]

    Z = A_w /√2πf * (1-i)

"""
function W(p,f)

    omega = 2π .* f
    A_w = p[1]
    Z = [A_w /sqrt(omega[i]) *(1-1im) for i in 1:length(omega)]
    return Z

end




