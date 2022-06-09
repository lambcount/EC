using Statistics
"""
calc_time(v::AbstractVector;Δt=1e-1) \n

Calculate a time vector with the length of the given input array and a Δt which refers to the sample time, it defaults to 1e-1. 
"""
function calc_time(v::AbstractVector;Δt=1e-1)
    collect(0:Δt:(length(v)-1)*Δt)
end


"""
diff(v::AbstractVector)) \n

Returns a length(v)-1 array with the differences between the i and the i-1 value.
"""
function diff(v::AbstractVector)
    [v[i] - v[i-1] for i in 2:length(v)]
end

"""
    findall_localmaxima(data) \n
Return all local maxima in given data.
"""
function findall_localmaxima(data)
    v_max      = maximum(data)          
    lb_v_max   = v_max-0.01*v_max                       # Define the range, in which we are looking for all argmaxima
    ub_v_max   = v_max+0.01*v_max 
    extrema_01 = findall(x-> lb_v_max<=x<=ub_v_max,data)  # Find all args in the above defined range                                
        
    diff_extrema = diff(extrema_01)                 # calc. difference to check if the maxima are real maxima or just due to noise. If its due to noise the diff should be smaller than the std
    std_extrema  = std(diff_extrema)                 
    extrema_02 = Int[]
        push!(extrema_02,extrema_01[2])
        append!(extrema_02,extrema_01[findall(x-> x> std_extrema,diff_extrema).+2])
    return extrema_02
end

"""
    triangle(t,p) \n
Simulate triangular waveforms. Inpute parameters are the time (t) and the parameters (p), where: \n

    amplitude = p[1] \n
    period    = p[2] \n
    phase     = p[3] \n
    offset    = p[4] \n

Do not use a phase of 0, as it is divided by the phase and thus the function would only return NaN.
"""
function triangle(t,p)
    A      = p[1]                       # amplitude
    T      = p[2]                       # period
    phase  = p[3]                       # phase
    offset = p[4]                       # offset
    if phase == 0                       # if the phase is 0, the function would return NaN, so now it will return unreasonable high values, which is great for fitting
        return fill(1e10,length(t))
    else
    @.  4*A/T *abs((mod((t-T/phase),T))-T/2)+offset
    end
end

"""
    fit_voltag(voltage,Δt) \n

Fit the triangular voltage data. Input parameters are the raw volatge and the sample time Δt. Function will return the fitted parameters. \n

p = fit_voltag(voltage,Δt)

amplitude = p[1] \n
period    = p[2] \n
phase     = p[3] \n
offset    = p[4] \n

triangle(t,p) will return the triangular voltage fit.
"""
function fit_voltage(data,Δt)
    time     = EC.calc_time(data,Δt= Δt)                                        # calculate the measurement time from length(data) multiplied by the time increment Δt
    A_0      = (abs(maximum(data)) + abs(minimum(data))) /2                     # get a good inital guess on the amplitude (A)
    maxima   = findall_localmaxima(data)                                        # to get a good initial estimate for period (T), find two adjacent maxima 
    T_0      =  time[maxima[2]]-time[maxima[1]]                                  # and calculate the difference
    phase_0  = 1e-1                                                             
    offset_0 = maximum(data)
    p_0      = [A_0,T_0,phase_0,offset_0]    
    p_lb = [0.0,T_0*0.5,-2pi,-10.0]                                          # maybe not needed
    p_ub = [2*A_0,T_0*1.5,2pi,10.0]
    fit       = curve_fit(triangle,time,data,p_0,lower=p_lb,upper=p_ub)
     
       return fit.param
     
 end

"""
    idx_cycle(data,Δt) \n

    Returns the length of a cycle period, by fitting the data.
  
"""
 function idx_cycle(data,Δt)
    T_cycle = fit_voltage(data,Δt)[2]                       # We only need the period
    T_idx_cycle = round(T_cycle/Δt,RoundUp) |> Int          # round up the length of the period

    return T_idx_cycle
end

"""
    find_nearest(A,x, tol)

    Returns the argument of the closest element in A to x within a tolerence of tol.

"""
function find_nearest(A,x, tol)
    diff = abs.(A.-x)
    findfirst(x-> x <=tol ,diff) 
end


function cycle(v::AbstractVector,cycle::Int64,Δt;start_pot=nothing,start_idx=nothing,start_min  = false,tol =1e-2)
    
    T_idx_cycle = idx_cycle(v,Δt)
    
    if start_pot !== nothing 
        
        start_pot_idx = find_nearest(v,start_pot,tol)
        first = (cycle-1)*T_idx_cycle+start_pot_idx
        last  =  cycle*T_idx_cycle+start_pot_idx+1
        
        return v[first:last]
        
    elseif start_idx !== nothing
        
        first = (cycle-1)*T_idx_cycle+start_idx
        last  = cycle*T_idx_cycle+start_idx+1
        
        return v[first:last]
        
    elseif start_min == true
        
        first_min_idx = argmin(v)
        
        while first_min_idx > T_idx_cycle
            first_min_idx  -= T_idx_cycle
        end
        
        first = (cycle-1)*T_idx_cycle+first_min_idx
        last  = cycle*T_idx_cycle+first_min_idx+1
        
        return v[first:last]
    else
        first = (cycle-1)*T_idx_cycle+1
        last  = cycle*T_idx_cycle+1
        
        return v[first:last]
    end
end

"""
    cycle(v::AbstractVector,c::AbstractVector,cycle::Int64,Δt;start_pot=nothing,start_idx=nothing,start_min  = false,tol =1e-2)  \n

Return the Input voltage and current Arrays for the given cycle and sample time (Δt) argument. Specify the start potential of the cycle with either the potential (start_pot) or the index (start_idx) or just start from the minimum (start_min)
"""
function cycle(v::AbstractVector,c::AbstractVector,cycle::Int64,Δt;start_pot=nothing,start_idx=nothing,start_min  = false,tol =1e-2)
    
    T_idx_cycle = idx_cycle(v,Δt)    
    println("index per cycle $(T_idx_cycle)")                                       # The length of a cycle always the same for a given dataset.
    
    if start_pot !== nothing                                                # Special Case, if you want the cycle to start a specific potential.
        
        start_pot_idx = find_nearest(v,start_pot,tol)                       # Find the first occurence potential of the potential in data
        first = (cycle-1)*T_idx_cycle+start_pot_idx                         # First Index of the cycle
        last  =  cycle*T_idx_cycle+start_pot_idx+1                          # Last Index of the cycle

        n_cycles = 0                                                        # While loop for checking how many cycles there are if you start at the 
        total_cycles = copy(first)                                          # start potential

        while total_cycles+T_idx_cycle < length(v)
            n_cycles += 1
            total_cycles += T_idx_cycle
        end
        if n_cycles < cycle
            error("There are only $(n_cycles) cycles in this data set with the specified start potential ($(start_pot)). You selected cycle $(cycle)!")
        else

            println("Cycle $(cycle)/$(n_cycles)")

            return v[first:last],c[first:last]
        end
        
    elseif start_idx !== nothing                                            # Special Case, if you want the cycle to start a specific index.
        
        first = (cycle-1)*T_idx_cycle+start_idx                             # First Index of the cycle
        last  = cycle*T_idx_cycle+start_idx+1                               # Last Index of the cycle

        n_cycles = 0
        total_cycles = copy(first)

        while total_cycles+T_idx_cycle < length(v)
            n_cycles += 1
            total_cycles += T_idx_cycle
        end

        if n_cycles < cycle
            error("There are only $(n_cycles) cycles in this data set with the specified argument ($(start_idx)). You selected cycle $(cycle)!")
        else

            println("Cycle $(cycle)/$(n_cycles)")

            return v[first:last],c[first:last]
        end
        
    elseif start_min == true                                                # Special Case, if you want the cycle to start at the lowest potential.
        
        first_min_idx = argmin(v)                                           # Find any minimum
        
        while first_min_idx > T_idx_cycle                                   # Find the argument of the lowest minimum, by substracting a full cycle
            first_min_idx  -= T_idx_cycle                                   # from first_min_idx. Stop when first_min_idx is smaller than a full cycle
        end
        
        first = (cycle-1)*T_idx_cycle+first_min_idx
        last  = cycle*T_idx_cycle+first_min_idx+1

        n_cycles = 0
        total_cycles = copy(first)

        while total_cycles+T_idx_cycle < length(v)
            n_cycles += 1
            total_cycles += T_idx_cycle
        end

        if n_cycles < cycle
            error("There are only $(n_cycles) cycles in this data set if you start from a minimum. You selected cycle $(cycle)!")
        else

            println("Cycle $(cycle)/$(n_cycles)")

            return v[first:last],c[first:last]
        end
    else                                                                    # Normal case
        first = (cycle-1)*T_idx_cycle+1
        last  = cycle*T_idx_cycle+1

        n_cycles = 0
        total_cycles = copy(first)

        while total_cycles+T_idx_cycle < length(v)
            n_cycles += 1
            total_cycles += T_idx_cycle
        end

        if n_cycles < cycle
            error("There are only $(n_cycles) cycles in this data set. You selected cycle $(cycle)!")
        else

            println("Cycle $(cycle)/$(n_cycles)")

            return v[first:last],c[first:last]
        end
    end
end






