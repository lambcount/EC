using Dierckx

"""
calc_time(v::AbstractVector;Δt=1e-1) \n

Calculate a time vector with the length of the given input array and a Δt which refers to the sample time, it defaults to 1e-1. 
"""
function calc_time(v::AbstractVector;Δt=1e-1)
    collect(0:Δt:(length(v)-1)*Δt)
end

function idx_cycle(v::AbstractVector;Δt= 1e-1,pot=nothing,start_ind=nothing)
    time = calc_time(v,Δt=Δt)
    spl = Spline1D(time,v)
    der= [derivative(spl,i) for i in time]

    if pot !== nothing && start_ind === nothing
        diff = v .- pot .|> abs
        start_idx = 1
       for i in 1:length(v) 
            if diff[i] < 0.0005
                start_idx = i
                break
            end
        end
    elseif pot === nothing && start_ind === nothing
        start_idx = 1

    elseif pot === nothing && start_ind !== nothing

        start_idx = start_ind
    else
        error!("You cannot give a start potential and a start index as input.")
    end

    start = copy(start_idx)

    if der[start_idx] < 0
        
        _idx=findnext(x->x>= v[start_idx],v,start_idx+1)

        while _idx === nothing 
            start_idx += 1
            _idx=findnext(x->x>= v[start_idx],v,start_idx+1) 
        end

        idx=findnext(x->x<= v[start_idx],v,_idx+1)

    elseif der[start_idx] > 0
        _idx=findnext(x->x<= v[start_idx],v,start_idx+1)

        while _idx === nothing 
            start_idx += 1
            _idx=findnext(x->x<= v[start_idx],v,start_idx+1)
        end

        idx=findnext(x->x>= v[start_idx],v,_idx+1)
    end   
    
    return start:idx
    
end


"""
total_cycles(v::AbstractVector;Δt= 1e-1,pot=nothing,start_ind=nothing) \n

Returns the total number of full cycles in v. Specify the start potential of the cycle with either the potential (pot) or the index (start_ind).
"""
function total_cycles(v::AbstractVector;Δt= 1e-1,pot=nothing,start_ind=nothing)

    idx = idx_cycle(v,Δt=Δt,pot=pot,start_ind=start_ind)[end]
    round(length(v)/idx) |> Int
end  


function cycle(v::AbstractVector,cycle::Int64;Δt= 1e-1,pot=nothing,start_ind=nothing) 

    
    range = idx_cycle(v,Δt=Δt,pot=pot,start_ind=start_ind)      
    n_cycles = total_cycles(v,Δt=Δt,pot=pot,start_ind=start_ind)
   
    if cycle > n_cycles
        error("There are only $(n_cycles) full cycles in your Array.")
    else
        if cycle == 1
        
            return v[range]

        elseif cycle > 1 
            _idx = range[end]
            for i in 2:cycle
                range = idx_cycle(v,Δt=Δt,start_ind=_idx)
                _idx = range[end]
                if i == cycle 
                    break
                end
            end
            return v[range]
        end
    end       
end

"""
cycle(v::AbstractVector,c::AbstractVector,cycle::Int64;Δt= 1e-1,pot=nothing,start_ind=nothing) \n

Return the Input voltage and current Arrays for the given cycle argument. Δt refers to the sample time, default at 1e-1. Specify the start potential of the cycle with either the potential (pot) or the index (start_ind).
"""
function cycle(v::AbstractVector,c::AbstractVector,cycle::Int64;Δt= 1e-1,pot=nothing,start_ind=nothing) 


    range = idx_cycle(v,Δt=Δt,pot=pot,start_ind=start_ind)       
    n_cycles = total_cycles(v,Δt=Δt,pot=pot,start_ind=start_ind)
   
    if cycle > n_cycles
        error("There are only $(n_cycles) full cycles in your Array.")
    else

        if cycle == 1
        
            return v[range],c[range]

        elseif cycle > 1 
            _idx = range[end]
            for i in 2:cycle
                range = idx_cycle(v,Δt=Δt,start_ind=_idx)
                _idx = range[end]
                if i == cycle 
                    break
                end
            end
            return v[range],c[range]
        end
    end       
end;