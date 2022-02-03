using Optim,BlackBoxOptim
"""
Returns the time,potential and current vector of the impedance file under path. Currently works with Data from Mephisto and Picosscope.

julia> read_imped_files("./test/Data/imped/mephisto/kl_675.CSV")
"""
function read_imped_files(path)
    data = readdlm(path,',')
    # Check if unit is in V or mV
    unit = [i == "(mV)" ? 1000 : 1 for i in data[2,2:3]] 
    # Checks which lines of the file are of type data
    idx = [i for i in 1:size(data,1) if (typeof(data[i,1]) <: Number) && (data[i,3] !== Inf && data[i,3] !== -Inf) ]
    # Get the Data
    time      = data[idx,1]
    potential = data[idx,2] ./ unit[1]
    current   = data[idx,3] ./ unit[2]

    return time,potential,current
end

"""
Generate an impedance table. Rounds all values to the given argument of sigdigits.

julia> imped_table(
    measurement_index,
    frequency,
    impedance,
    impedance_error,
    impedance_real,
    impedance_real_error,
    impedance_imag,
    impedance_imag_error,
    phase,
    phase_error,
    potential_offset
)

1×11 DataFrame
 Row │ measurement  frequency   impedance  impedance_error  impedance_real  impedance_real_error  impedance_imag  impedance_imag_error  phase    phase_error  potential_offset 
     │ Int64        Float64     Float64    Float64          Float64         Float64               Float64         Float64               Float64  Float64      Float64          
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │         675  10007.9         88.98            6.908          52.08                  14.23           72.15                 8.381    54.18       10.65          -0.001585

"""
function imped_table(
    meas_ind,
    frequency,
    impedance,
    impedance_error,
    impedance_real,
    impedance_real_error,
    impedance_imag,
    impedance_imag_error,
    phase,
    phase_error,
    potential_offset
    )
    
   df = DataFrame()

   df.measurement               = [meas_ind]
   df.frequency                 = [frequency]
   df.impedance                 = [round(impedance,sigdigits=4)]
   df.impedance_error           = [round(impedance_error,sigdigits=4)]
   df.impedance_real            = [round(impedance_real,sigdigits=4)]
   df.impedance_real_error      = [round(impedance_real_error,sigdigits=4)]
   df.impedance_imag            = [round(impedance_imag,sigdigits=4)]
   df.impedance_imag_error      = [round(impedance_imag_error,sigdigits=4)]
   df.phase                     = [round(phase,sigdigits=4)]
   df.phase_error               = [round(phase_error,sigdigits=4)]
   df.potential_offset          = [round(potential_offset,sigdigits=4)]

   return df
end
    
    
    
    
    
    
"""
Import the impedance data from path. And correct the current with the amplifier value RV.If you have multiple scans for a measurement, set multiple=true. \n
import_oszi_imped(meas,dir,RV;multiple=false)\n
julia> time,potential,current = import_oszi_imped("kl_794","./imp_data",10)

"""
function import_oszi_imped(meas,dir,RV;multiple=false,type = ".csv")

    if multiple == false
        path = joinpath(dir,meas*type)
        time,potential, current   = read_imped_files(path)
        current = current ./ RV
    else
        multiple_pathes = [i for i in readdir(dir,join=true) if occursin(meas,i) == true]
        data            = read_imped_files.(multiple_pathes)
        time            = [data[i][1] for i in 1:size(data,1)]
        potential       = [data[i][2] for i in 1:size(data,1)]
        current         = [data[i][3] ./ RV for i in 1:size(data,1)]
    end
    return time,potential,current
end

"""
Sine function for fitting. \n 
    p[1]+p[2]*sin(p[3]*t+p[4]) \n 
julia> y = f_sin(collect(0:0.01:1),[0.0,1.0,1,π])

"""
function f_sin(t,p)
    y_0 = p[1]
    A   = p[2]
    ω   = p[3]*2π
    ϕ   = p[4] # in rad
    y = fill(0.0,length(t))
   @. y = y_0+A*sin(ω*t+ϕ)
end

function mean(a)
    sum(a)/length(a)
end

    
    
function fit_traces_for_imped(time,potential,current,meas_index,freq,amplitude; df= nothing,multiple=false)
    
    p0_pot = [
        1e-7,
        amplitude,
        freq,
        0.0
        ]
    p_lower_pot = [
        -2.0,
        -2.0,
        freq - freq*0.025,
        -π
    ]
    p_upper_pot = [
        2.0,
        2.0,
        freq + freq*0.025,
        π
    ]

    if multiple == false
    
        fit_potential = curve_fit(f_sin,time,potential,p0_pot,lower=p_lower_pot,upper=p_upper_pot)
        error_potential = margin_error(fit_potential)

            pot_param_1         = fit_potential.param[1]
            pot_param_error_1   = error_potential[1]
            pot_param_2         = fit_potential.param[2]
            pot_param_error_2   = error_potential[2]
            pot_param_3         = fit_potential.param[3] 
            pot_param_error_3   = error_potential[3] 
            pot_param_4         = fit_potential.param[4] / π * 180
            pot_param_error_4   = error_potential[4] / π * 180

    else
        fit_potential = [curve_fit(f_sin,time[i],potential[i],p0_pot,lower=p_lower_pot,upper=p_upper_pot) for i in 1:length(time)]
        error_potential = [margin_error(fit_potential[i]) for i in 1:length(fit_potential)]

        pot_param_1         = [fit_potential[i].param[1] for i in 1:length(fit_potential)] |> mean
        pot_param_error_1   = [error_potential[i][1] for i in 1:length(fit_potential)] |> mean
        pot_param_2         = [fit_potential[i].param[2] for i in 1:length(fit_potential)] |> mean
        pot_param_error_2   = [error_potential[i][2] for i in 1:length(fit_potential)] |> mean
        pot_param_3         = [fit_potential[i].param[3] for i in 1:length(fit_potential)] |> mean
        pot_param_error_3   = [error_potential[i][3] for i in 1:length(fit_potential)] |> mean
        pot_param_4         = [fit_potential[i].param[4] / π * 180 for i in 1:length(fit_potential)] # Mean is not useful here
        pot_param_error_4   = [error_potential[i][4] / π * 180 for i in 1:length(fit_potential)] 
        
    end


    potential_offset                   = pot_param_1      
    potential_offset_error             = pot_param_error_1
    potential_amplitude                = pot_param_2      
    potential_amplitude_error          = pot_param_error_2
    frequency_potential                = pot_param_3      
    frequency_potential_error          = pot_param_error_3
    phase_potential                    = pot_param_4      
    phase_potential_error              = pot_param_error_4


    p0_cur = [pot_param_1, pot_param_2,pot_param_3,pot_param_4[1]]
    
    p_lower_cur = p_lower_pot |> copy
    p_lower_cur[3] = frequency_potential- 0.01 * frequency_potential # fix frequency 
    p_lower_cur[4] = phase_potential[1]   - 2π # max phase difference to potental should be ±π


    p_upper_cur = p_upper_pot |> copy
    p_upper_cur[3] = frequency_potential + 0.01 * frequency_potential 
    p_upper_cur[4] = phase_potential[1]  + 2π
    if multiple == false
    
        fit_current = curve_fit(f_sin,time,current,p0_cur,lower=p_lower_cur,upper=p_upper_cur)
        error_current = margin_error(fit_current)

            cur_param_1         = fit_current.param[1]
            cur_param_error_1   = error_current[1]
            cur_param_2         = fit_current.param[2]
            cur_param_error_2   = error_current[2]
            cur_param_3         = fit_current.param[3] 
            cur_param_error_3   = error_current[3] 
            cur_param_4         = fit_current.param[4] / π * 180
            cur_param_error_4   = error_current[4] / π * 180

    else
        fit_current = [curve_fit(f_sin,time[i],current[i],p0_cur,lower=p_lower_cur,upper=p_upper_cur) for i in 1:length(time)]
        error_current = [margin_error(fit_current[i]) for i in 1:length(fit_current)]

        cur_param_1         = [fit_current[i].param[1] for i in 1:length(fit_current)] |> mean
        cur_param_error_1   = [error_current[i][1] for i in 1:length(fit_current)] |> mean
        cur_param_2         = [fit_current[i].param[2] for i in 1:length(fit_current)] |> mean
        cur_param_error_2   = [error_current[i][2] for i in 1:length(fit_current)] |> mean
        cur_param_3         = [fit_current[i].param[3] for i in 1:length(fit_current)] |> mean
        cur_param_error_3   = [error_current[i][3] for i in 1:length(fit_current)] |> mean
        cur_param_4         = [fit_current[i].param[4] / π * 180 for i in 1:length(fit_current)] 
        cur_param_error_4   = [error_current[i][4] / π * 180 for i in 1:length(fit_current)] 
        
    end


    current_offset              = cur_param_1      
    current_offset_error        = cur_param_error_1
    current_amplitude           = cur_param_2      
    current_amplitude_error     = cur_param_error_2
    frequency_current           = cur_param_3      
    frequency_current_error     = cur_param_error_3
    phase_current               = cur_param_4      
    phase_current_error         = cur_param_error_4



    impedance_absolut = potential_amplitude / current_amplitude 
    impedance_absolut_error = (potential_amplitude + potential_amplitude_error ) / (current_amplitude - current_amplitude_error)  - impedance_absolut |> abs
    
    
        
   
    all_phase_difference = (phase_potential .- phase_current) .|> abs
    phase_difference = all_phase_difference |> mean
    
    
    all_error_phase_difference = phase_potential_error   .+ phase_current_error .|> abs
    error_phase_difference = all_error_phase_difference |> mean


    impedance_real = impedance_absolut * cos(phase_difference / 180 * π) 
    impedance_real_error = impedance_absolut *  (cos((phase_difference + error_phase_difference) / 180 * π)  - cos((phase_difference) / 180 * π)  )  |> abs
    
    
    impedance_imag = impedance_absolut * sin(phase_difference / 180 * π) 
    impedance_imag_error =  impedance_absolut * ( sin(( phase_difference + error_phase_difference) / 180 * π)  - sin(( phase_difference ) / 180 * π)  )   |> abs
    
        imp_table = imped_table(
            meas_index,
            frequency_potential,
            impedance_absolut,
            impedance_absolut_error,
            impedance_real,
            impedance_real_error,
            impedance_imag,
            impedance_imag_error,
            phase_difference,
            error_phase_difference,
            potential_offset 
        )
    if df===nothing 
        return imp_table,fit_potential,fit_current
    else
        append!(df,imp_table)
        return df,fit_potential,fit_current
    end


    
end


"""
Fit Bode
"""
function fit_bode(circuit_str,freq,imp_data,lower,upper;bbo=false,bbo_time=10,compare=false)

    function cost_function(param::Vector{Float64})
        circuit = build_circuit(circuit_str,param,freq)
     
        minimizer_value = (circuit.impedance .|> abs) .- (imp_data .|> abs)
        sum(minimizer_value .^2)   
    end

    if bbo == true 
        param_bounds = [(lower[i],upper[i]) for i in 1:length(lower)]
        
        bbopt = bboptimize(
            cost_function; 
            SearchRange =param_bounds, 
            NumDimensions = 2,
            MaxTime = bbo_time, 
            TraceMode = :compact, 
            NThreads= Threads.nthreads()-1, 
            Method = :random_search, 
            lambda = 1,
            MaxSteps=1e6
        )
        return build_circuit(circuit_str,bbopt.archive_output.best_candidate,freq)
    elseif compare == true
        param_bounds = [(lower[i],upper[i]) for i in 1:length(lower)]
        
        bbopt = compare_optimizers(
            cost_function; 
            SearchRange =param_bounds, 
            NumDimensions = 2,
            MaxTime = bbo_time, 
            TraceMode = :compact, 
            NThreads= Threads.nthreads()-1,  
            lambda = 1,
            MaxSteps=1e6
        )


    else

        initial_guess = [mean([lower[i],upper[i]]) for i in 1:length(lower)]
        
        optim = Optim.optimize(cost_function,lower,upper,initial_guess,Fminbox(LBFGS()))
        
        return build_circuit(circuit_str,optim.minimizer,freq)
    end
end;

   

function fit_impedance(time,potential,current,meas_index,freq)
    
    p0_pot = [
        1e-5,
        1e-5,
        freq,
        0.0
        ]
    p_lower_pot = [
        -2.0,
        -2.0,
        freq - freq*0.025,
        -2π
    ]
    p_upper_pot = [
        2.0,
        2.0,
        freq + freq*0.025,
        2π
    ]


    fit_potential   = curve_fit(f_sin,time,potential,p0_pot,lower=p_lower_pot,upper=p_upper_pot)
    error_potential = margin_error(fit_potential)

    potential_offset                   = fit_potential[1]      
    potential_offset_error             = error_potential[1]
    potential_amplitude                = fit_potential[2]      
    potential_amplitude_error          = error_potential[2]
    frequency_potential                = fit_potential[3]      
    frequency_potential_error          = error_potential[3]
    phase_potential                    = fit_potential[4]      
    phase_potential_error              = error_potential[4]


    p0_cur = [0.0, pot_param_2,pot_param_3,pot_param_4]
    p_lower_cur = p_lower_pot |> copy
    p_lower_cur[3] = frequency_potential- 0.01 * frequency_potential # fix frequency 
    p_lower_cur[4] = phase_potential   - π # max phase difference to potental should be ±π

    p_upper_cur = p_upper_pot |> copy
    p_upper_cur[3] = frequency_potential + 0.01 * frequency_potential 
    p_upper_cur[4] = phase_potential  + π

    
    fit_current_1 = curve_fit(f_sin,time,current,p0_cur,lower=p_lower_cur,upper=p_upper_cur)
    error_current_1 = margin_error(fit_current)

    current_offset              = fit_current.param[1]
    current_offset_error        = error_current[1]
    current_amplitude           = fit_current.param[2]
    current_amplitude_error     = error_current[2]
    frequency_current           = fit_current.param[3] 
    frequency_current_error     = error_current[3] 
    phase_current               = fit_current.param[4] / π * 180
    phase_current_error         = error_current[4] / π * 180

    impedance_absolut = potential_amplitude / current_amplitude 
    impedance_absolut_error = (potential_amplitude + potential_amplitude_error ) / (current_amplitude - current_amplitude_error)  - impedance_absolut |> abs

    phase_difference = (phase_potential - phase_current) |> abs
    
    error_phase_difference = phase_potential_error   + phase_current_error |> abs


    impedance_real = impedance_absolut * cos(phase_difference / 180 * π) 
    impedance_real_error = impedance_absolut *  (cos((phase_difference + error_phase_difference) / 180 * π)  - cos((phase_difference) / 180 * π)  )  |> abs
    
    
    impedance_imag = impedance_absolut * sin(phase_difference / 180 * π) 
    impedance_imag_error =  impedance_absolut * ( sin(( phase_difference + error_phase_difference) / 180 * π)  - sin(( phase_difference ) / 180 * π)  )   |> abs


    
    
    imp_table = imped_table(
        meas_index,
        frequency_potential,
        impedance_absolut,
        impedance_absolut_error,
        impedance_real,
        impedance_real_error,
        impedance_imag,
        impedance_imag_error,
        phase_difference,
        error_phase_difference,
        potential_offset 
    )


    return imp_table


    
end

 
    
    
    
    

    
    
    
    
    

    
  
    
    
    
    



