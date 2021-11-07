import Base: +,-,/,*,==,!==

mutable struct Measurement
    Name::AbstractString
    Data::Array
    Labbook::Dict{Any,Any}
end

Base.size(m::Measurement) = size(m.Data)
Base.copy(m::Measurement)  = Measurement(copy(m.Name),copy(m.Data),copy(m.Labbook))

==(m1::Measurement,m2::Measurement) = (m1.Name == m2.Name) && (m1.Data == m2.Data)
!==(m1::Measurement,m2::Measurement) = (m1.Name !== m2.Name) || (m1.Data !== m2.Data)
-(m1::Measurement,m2::Measurement) = m1.Data - m2.Data
+(m1::Measurement,m2::Measurement) = m1.Data + m2.Data
*(m::Measurement,n::Number) = m.Data * n
*(m::Measurement,n::Number) = n * m.Data 
/(m::Measurement,n::Number) = m.Data /n
/(m::Measurement,n::Number) = n / m.Data 

