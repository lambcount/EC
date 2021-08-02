


function idx_cycle(voltage,start_idx)

    _voltage = voltage .+1000

    if _voltage[start_idx] > _voltage[start_idx+10]
        _idx=findnext(x->x>= _voltage[start_idx],_voltage,start_idx+1)
        idx=findnext(x->x<= _voltage[start_idx],_voltage,_idx+1)

    elseif _voltage[start_idx] < _voltage[start_idx+10]
        _idx=findnext(x->x<= _voltage[start_idx],_voltage,start_idx+1)
        idx=findnext(x->x>= _voltage[start_idx],_voltage,_idx+1)
    end
    return idx
end


"""
total_cycles(voltage::Array{Number,1})

Returns the total number of full cycles in voltage.
"""
function total_cycles(voltage)

    idx = idx_cycle(voltage,1)
    total_cycle = round(length(voltage)/idx) |> Int
end  



function cycle(voltage,cycle::Int64) 

    
    idx = idx_cycle(voltage,1)
    total_cycles = round(length(voltage)/idx) |> Int
   
    if cycle > total_cycles
        error("There are only $(total_cycles) full cycles in your Array.")
    else

        if cycle == 1
        
            return voltage[1:idx]

        elseif cycle > 1 
            _idx_1 = 1
            _idx_2 = deepcopy(idx)
    

            for i in 2:cycle

                if i == cycle
                    _idx_1 = deepcopy(_idx_2)
                end
                _idx_2 = idx_cycle(voltage,_idx_2)

                
          
            end
            return voltage[_idx_1:_idx_2]
        end
    end       
end

"""
cycle(voltage::Array{Any,1},current::Array{Any,1},cycle::Int64)

Return the Input voltage and current Arrays for the given cycle argument.
"""
function cycle(voltage,current,cycle::Int64)

    idx = idx_cycle(voltage,1)
    total_cycles = round(length(voltage)/idx) |> Int
   
    if cycle > total_cycles
        error("There are only $(total_cycles) full cycles in your Array.")
    else

        if cycle == 1
        
            return voltage[1:idx],current[1:idx]

        elseif cycle > 1 
            _idx_1 = 1
            _idx_2 = deepcopy(idx)
    

            for i in 2:cycle

                if i == cycle
                    _idx_1 = deepcopy(_idx_2)
                end

                _idx_2 = idx_cycle(voltage,_idx_2)
            end
            return voltage[_idx_1:_idx_2],current[_idx_1:_idx_2]
        end
    end  
end