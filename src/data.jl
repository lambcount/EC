function idx_cycle(voltage)

    _voltage = voltage .+1000
    if _voltage[1] > _voltage[10]
        _idx=findnext(x->x>= _voltage[1],_voltage,2)
        idx=findnext(x->x<= _voltage[1],_voltage,_idx+1)

    elseif _voltage[1] < _voltage[10]
        _idx=findnext(x->x<= _voltage[1],_voltage,2)
        idx=findnext(x->x>= _voltage[1],_voltage,_idx+1)
    end
    return idx+5
end




function cycle(voltage,cycle::Int64) 

    idx = idx_cycle(voltage)
    total_cycle = round(length(voltage)/idx) |> Int
    
    if cycle > total_cycle
        error("There are only $(total_cycle) full cycles in your Array.")
    else
        _start = 1+(cycle-1)*idx
        _end = cycle*idx
        return voltage[_start:_end]
    end      
end

"""
cycle(voltage::Array{Any,1},current::Array{Any,1},cycle::Int64)

Return the Input voltage and current Arrays for the given cycle argument.
"""
function cycle(voltage,current,cycle::Int64)

    idx = idx_cycle(voltage)
    total_cycle = round(length(voltage)/idx) |> Int
    
    if cycle > total_cycle
        error("There are only $(total_cycle) full cycles in your Array.")
    else
        _start = 1+(cycle-1)*idx
        _end   = cycle*idx

        return voltage[_start:_end],current[_start:_end]

    end 
end 

"""
total_cycles(voltage::Array{Number,1})

Returns the total number of full cycles in voltage.
"""
function total_cycles(voltage)

    idx = idx_cycle(voltage)
    total_cycle = round(length(voltage)/idx) |> Int
end  