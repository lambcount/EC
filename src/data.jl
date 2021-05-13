import SmoothingSplines: fit,predict

function idx_cycle(voltage)

    _voltage = voltage .+1000
    if _voltage[1] > _voltage[10]
        _idx=findnext(x->x>= _voltage[1],_voltage,2)
        idx=findnext(x->x<= _voltage[1],_voltage,_idx+1)

    elseif _voltage[1] < _voltage[10]
        _idx=findnext(x->x<= _voltage[1],_voltage,2)
        idx=findnext(x->x>= _voltage[1],_voltage,_idx+1)
    end
    return idx
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

    return total_cycle
end  



"""Returns the anodic and cathodic current at the given potential value (val).Works only if c and v consist of only one cycle. For Value you can put any potential in the scan range.
get_eq_anodickathodiccurrents(v,c,val)

julia> get_eq_anodickathodiccurrents(v_cycle1[1],c_cycle1[1],-0.03)
    (-1.3481340532268844, 0.9398593965871291)
"""
function get_eq_anodickathodiccurrents(v,c,val)
    idx_1,idx_2 = get_ind_eq_anodickathodicpotentials(v,c,val)

    val_p1 = v[idx_1]
    val_p2 = v[idx_2]
    val_p3 = v[idx_2+1]

    inc_idx = abs(val_p1-val_p2 )/abs(val_p3-val_p2)

    itp = interpolate(c, BSpline(Quadratic(Reflect(OnCell()))))

    if val_p1 < val_p2 
        
        return c[idx_1],itp(idx_2+inc_idx)

    elseif val_p1 > val_p2 
        
        return c[idx_1],itp(idx_2+(1-inc_idx))
    end 
end


"""Returns the anodic and cathodic current indices at the given potential value (val).Works only if c and v consist of only one cycle. For Value you can put any potential in the scan range.
get_ind_eq_anodickathodicpotentials(v,c,val)

julia> get_eq_anodickathodicpotentials(v_cycle1[1],c_cycle1[1],-0.03)
    (42,97)
"""
function get_ind_eq_anodickathodicpotentials(v,c,val)

    p=sortperm(v)
    v_sorted = v[p]

    _v = v_sorted .- val

    idx_1=findnext(x->x>= 0,_v,1)

    idx_2=findpotential(v,p,idx_1,c)

    idxs= [p[idx_1],p[idx_2]]

    return idxs

    
end


function findpotential(v,p,idx,c;sample_rate=10)
    val = v[p[idx]]
    pot_halfcycle= abs(maximum(v) - minimum(v))

    time4halfcycle=  abs((argmin(v) - argmax(v))/sample_rate)

    scan_rate = pot_halfcycle/time4halfcycle

    if c[p[idx]] > 0 
        current= "anodic"
    else
        current= "cathodic"
    end

    idx_2= 0

    for i in idx-10:idx+10
        if current == "anodic"
            if abs(v[p][i] - val) < (scan_rate/sample_rate) && c[p[i]] < 0 && c[p[i]] < 0
                idx_2= i
                return idx_2
            end
        elseif current == "cathodic"
            if abs(v[p][i] - val) < (scan_rate/sample_rate) && c[p[i]] > 0
                idx_2= i
                return idx_2
            end
        end
    end

  
end
