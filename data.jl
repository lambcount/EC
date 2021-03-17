function cycle(voltage::Array{Any,1},cycle::Int64) 

    _voltage = voltage .+1000
    if _voltage[1] > _voltage[10]
        _idx=findnext(x->x>= _voltage[1],_voltage,2)
        idx=findnext(x->x<= _voltage[1],_voltage,_idx+1)

    elseif _voltage[1] < voltage[10]
        _idx=findnext(x->x<= _voltage[1],_voltage,2)
        idx=findnext(x->x>= _voltage[1],_voltage,_idx+1)
    end

    total_cycle = round(length(voltage)/idx) |> Int
    
    if cycle > total_cycle
        error("There are only $(total_cycle) full cycles in your Array.")
    else
        return voltage[1+(cycle-1)*idx:cycle*idx]
    end       

    
end

"""
cycle(voltage::Array{Number,1},current::Array{Number,1},cycle::Int64)

Return the Input voltage and current Arrays for the given cycle argument.
"""
function cycle(voltage::Array{Any,1},current::Array{Any,1},cycle::Int64)

    _voltage = voltage .+1000
    if _voltage[1] > _voltage[10]
        _idx=findnext(x->x>= _voltage[1],_voltage,2)
        idx=findnext(x->x<= _voltage[1],_voltage,_idx+1)

    elseif _voltage[1] < voltage[10]
        _idx=findnext(x->x<= _voltage[1],_voltage,2)
        idx=findnext(x->x>= _voltage[1],_voltage,_idx+1)
    end

    total_cycle = round(length(voltage)/idx) |> Int
    
    if cycle > total_cycle
        error("There are only $(total_cycle) full cycles in your Array.")
    else
        _start = 1+(cycle-1)*idx
        _end   = cycle*idx

        return [voltage[_start:_end] current[_start:_end]]

    end 
end  