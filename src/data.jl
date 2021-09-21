using Dierckx,Statistics

"""
calc_time(v::AbstractVector;Δt=1e-1) \n

Calculate a time vector with the length of the given input array and a Δt which refers to the sample time, it defaults to 1e-1. 
"""
function calc_time(v::AbstractVector;Δt=1e-1)
    collect(0:Δt:(length(v)-1)*Δt)
end

function diff(v)
    [v[i] - v[i+1] for i in 1:lenght(v)-1]
end

function idx_cycle(v::AbstractVector;start_pot=nothing,start_idx=nothing,start_min  = nothing)
    x   = collect(1:length(v))
    smooth_v = savitzky_golay_filter(v,101,2)
    spl_v = Spline1D(x,smooth_v,s=1e-4)
    der= [derivative(spl_v,i) for i in x]
    

    if  start_min !== nothing
        smooth_der = savitzky_golay_filter(der,101,2)
        spl_der = Spline1D(x,smooth_der,s=1e-10)
        roots_der  = roots(spl_der) .|> round .|> Int

        if start_min +2 > length(roots_der)
            error("You cant use the start_min kwarg since there is no full cycle starting from the potential minimum.")
        else
            if isodd(start_min) == true

                return roots_der[start_min]:roots_der[start_min+2]
            else
                start_min += 1

                return roots_der[start_min]:roots_der[start_min+2]
            end

        end
    end



    if start_pot !== nothing && start_idx === nothing && start_min == false

        pot_diff = v .- pot .|> abs
        minstd =  diff(v) |> std
        start_idx = 1

        for i in 1:length(v) 
            if pot_diff[i] < minstd/2
                start_idx = i
                break
            end
        end
    elseif start_pot === nothing && start_idx === nothing && start_min == false
        start_idx = 1

    elseif start_pot === nothing && start_idx !== nothing && start_min == false

        start_idx = start_idx
    else
        error("You cannot give a start potential and a start index as input.")
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
function total_cycles(v::AbstractVector;start_pot=nothing,start_idx=nothing,start_min = nothing)

    idx = idx_cycle(v,start_pot=start_pot,start_idx=start_idx,start_min = start_min)[end]
    round(length(v)/idx) |> Int
end  


function cycle(v::AbstractVector,cycle::Int64;start_pot=nothing,start_idx=nothing,start_min  = false) 

         
    n_cycles = total_cycles(v,start_pot = start_pot, start_idx = start_idx, start_min = 1)
   
    if cycle > n_cycles
        error("There are only $(n_cycles) full cycles in your Array.")
    elseif start_min === true
        return v[idx_cycle(v,start_min=cycle)]
    else
        range = idx_cycle(v,start_pot=start_pot,start_idx=start_idx)

        if cycle == 1
        
            return v[range]

        elseif cycle > 1 
            _idx = range[end]
            for i in 2:cycle
                range = idx_cycle(v,start_idx=_idx)
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
function cycle(v::AbstractVector,cycle::Int64;start_pot=nothing,start_idx=nothing,start_min  = false) 

         
    n_cycles = total_cycles(v,start_pot = start_pot, start_idx = start_idx, start_min = 1)
   
    if cycle > n_cycles
        error("There are only $(n_cycles) full cycles in your Array.")
    elseif start_min === true
        return v[idx_cycle(v,start_min=cycle)]
    else
        range = idx_cycle(v,start_pot=start_pot,start_idx=start_idx)

        if cycle == 1
        
            return v[range],c[range]

        elseif cycle > 1 
            _idx = range[end]
            for i in 2:cycle
                range = idx_cycle(v,start_idx=_idx)
                _idx = range[end]
                if i == cycle 
                    break
                end
            end
            return v[range],c[range]
        end
    end       
end