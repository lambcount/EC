using Dierckx

"""
calc_time(v::AbstractVector;Δt=1e-1) \n

Calculate a time vector with the length of the given input array and a Δt which refers to the sample time, it defaults to 1e-1. 
"""
function calc_time(v::AbstractVector;Δt=1e-1)
    collect(0:Δt:(length(v)-1)*Δt)
end


"""
diff(v::AbstractVector)) \n

Returns a length(v)-1 array with the differences between the i and the i+1 value.
"""
function diff(v::AbstractVector)
    [v[i] - v[i+1] for i in 1:length(v)-1]
end

function idx_cycle(v::AbstractVector;start_pot=nothing,start_idx=nothing,start_cycle  = nothing)
    x   = collect(1:length(v))
    smooth_v = savitzky_golay_filter(v,101,2)
    spl_v = Spline1D(x,smooth_v,s=1e-4)
    der= [derivative(spl_v,i) for i in x]
    

    if  start_cycle !== nothing
        smooth_der = savitzky_golay_filter(der,101,2)
        spl_der = Spline1D(x,smooth_der,s=1e-10)
        roots_der  = roots(spl_der,maxn=100) .|> round .|> Int

        if start_cycle +2 > length(roots_der)
            error("You cant use the start_cycle kwarg since there is no full cycle starting from the potential minimum.")
        else
            if v[roots_der[1]] < v[roots_der[2]]

                return roots_der[start_cycle]:roots_der[start_cycle+2]

            elseif v[roots_der[1]] > v[roots_der[2]]
                start_cycle += 1

                return roots_der[start_cycle]:roots_der[start_cycle+2]
            else 
                error("The derivative of your potential does not show any roots. Try smoothing your input potential.")
            end

        end
    end



    if start_pot !== nothing && start_idx === nothing && start_cycle === nothing

        pot_diff = v .- start_pot .|> abs
        minstd =  diff(v) |> std
        start_idx = 1

        for i in 1:length(v) 
            if pot_diff[i] < minstd/2
                start_idx = i
                break
            end
        end
    elseif start_pot === nothing && start_idx === nothing && start_cycle === nothing
        start_idx = 1

    elseif start_pot === nothing && start_idx !== nothing && start_cycle === nothing

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
function total_cycles(v::AbstractVector;start_pot=nothing,start_idx=nothing,start_cycle = nothing)

    idx = idx_cycle(v,start_pot=start_pot,start_idx=start_idx,start_cycle = start_cycle)[end]
    round(length(v)/idx) |> Int
end  


function cycle(v::AbstractVector,cycle::Int64;start_pot=nothing,start_idx=nothing,start_min  = false) 

         
    n_cycles = total_cycles(v,start_pot = start_pot, start_idx = start_idx, start_cycle = 1)
   
    if cycle > n_cycles
        error("There are only $(n_cycles) full cycles in your Array.")
    elseif start_min === true
        range = idx_cycle(v,start_cycle=cycle)
        return v[idx_cycle(v,start_cycle=cycle)]
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
cycle(v::AbstractVector,c::AbstractVector,cycle::Int64;start_pot=nothing,start_idx=nothing,start_min  = false)  \n

Return the Input voltage and current Arrays for the given cycle argument. Specify the start potential of the cycle with either the potential (start_pot) or the index (start_idx) or just start from the minimum (start_min)
"""
function cycle(v::AbstractVector,c::AbstractVector,cycle::Int64;start_pot=nothing,start_idx=nothing,start_min  = false) 

         
    n_cycles = total_cycles(v,start_pot = start_pot, start_idx = start_idx, start_cycle = 1)
   
    if cycle > n_cycles
        error("There are only $(n_cycles) full cycles in your Array.")
    elseif start_min === true
        range = idx_cycle(v,start_cycle=cycle)
        return v[range],c[range]
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
