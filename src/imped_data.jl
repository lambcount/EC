"""
Returns the time,potential and current vector of the impedance file under path. Currently works with Data from Mephisto and Picosscope.

julia> read_imped_files("./test/Data/imped/mephisto/kl_675.CSV")
"""
function read_imped_files(path)
    data = readdlm(path,',')
    # Checks which lines of the file are of type data
    idx = [i for i in 1:size(data,1) if typeof(data[i,1]) <: Number]
    # Get the Data
    time      = [data[i,1] for i in idx]
    potential = [data[i,2] for i in idx]
    current   = [data[i,3] for i in idx]

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
Import the impedance data from path. And correct the current with the amplifier value RV.\n
julia> time,potential,current = import_oszi_imped("./test/Data/imped/mephisto/kl_675.CSV",10)
"""
function import_oszi_imped(path,RV)
    time,potential, current   = read_imped_files(path)

    current = current ./ RV
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
    
    
    
    
    
    
    
function fit_traces_for_imped(time,potential,current,meas_index,freq; df= nothing)
    
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
        -π
    ]
    p_upper_pot = [
        2.0,
        2.0,
        freq + freq*0.025,
        π
    ]
    
    fit_potential = curve_fit(f_sin,time,potential,p0_pot,lower=p_lower_pot,upper=p_upper_pot)
    error_potential = margin_error(fit_potential)

    potential_offset                   = fit_potential.param[1]
    potential_offset_error             = error_potential[1]
    potential_amplitude                = fit_potential.param[2]
    potential_amplitude_error          = error_potential[2]
    frequency_potential                = fit_potential.param[3] 
    frequency_potential_error          = error_potential[3] 
    phase_potential                    = fit_potential.param[4] / π * 180
    phase_potential_error              = error_potential[4] / π * 180


    p0_cur = fit_potential.param |> copy
    
    p_lower_cur = p_lower_pot |> copy
    p_lower_cur[3] = frequency_potential- 0.01 * frequency_potential # fix frequency 
    p_lower_cur[4] = fit_potential.param[4]  - 2π # max phase difference to potental should be ±π


    p_upper_cur = p_upper_pot |> copy
    p_upper_cur[3] = frequency_potential + 0.01 * frequency_potential 
    p_upper_cur[4] = fit_potential.param[4] + 2π

    fit_current = curve_fit(f_sin,time,current,p0_cur,lower=p_lower_cur,upper=p_upper_cur)
    
    error_current = margin_error(fit_current)

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
    if df===nothing 
        return imp_table,fit_potential,fit_current
    else
        append!(df,imp_table)
        return df,fit_potential,fit_current
    end


    
end
   

   

 
 
    
    
    
    

    
    
    
    
    

    
  
    
    
    
    



