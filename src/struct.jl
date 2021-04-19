import Base: +,-,/,*,==,!==
import Plots: plot

mutable struct Measurement
    Name::AbstractString
    Data
    Labbook::Dict{Any,Any}
end

Base.size(m::Measurement) = size(m.Data)
Base.copy(m::Measurement)  = Measurement(copy(m.Name),copy(m.Data),copy(m.Labbook))
Plots.plot(m::Measurement) = plot(m.Data[:,1],m.Data[:,2])

==(m1::Measurement,m2::Measurement) = (m1.Name == m2.Name) && (m1.Data == m2.Data)
!==(m1::Measurement,m2::Measurement) = (m1.Name !== m2.Name) || (m1.Data !== m2.Data)
-(m1::Measurement,m2::Measurement) = m1.Data - m2.Data
+(m1::Measurement,m2::Measurement) = m1.Data + m2.Data
*(m::Measurement,n::Number) = m.Data * n
*(m::Measurement,n::Number) = n * m.Data 
/(m::Measurement,n::Number) = m.Data /n
/(m::Measurement,n::Number) = n / m.Data 


