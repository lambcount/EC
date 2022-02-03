struct Circuit
    circuit_string::String
    circuit_dict::Dict
    components_dict::Dict
    impedance::Vector{ComplexF64}
    phase::Vector{Float64}
    parameter::Vector{Float64}
end
