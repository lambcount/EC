
function read_imped_files(path)
    data = readdlm(path,',')
    time      = [data[i,1] for i in 1:size(data,1) if typeof(data[i,1]) <: Number]
    potential = [data[i,2] for i in 1:size(data,1) if typeof(data[i,1]) <: Number]
    current   = [data[i,3] for i in 1:size(data,1) if typeof(data[i,1]) <: Number]

    return time,potential,current
end


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
    ac_amplitude
    )
    
   df = DataFrame()

   df.measurement               = [meas_ind]
   df.frequency                 = [frequency]
   df.impedance                 = [impedance]
   df.impedance_error           = [impedance_error]
   df.impedance_real            = [impedance_real]
   df.impedance_real_error      = [impedance_real_error]
   df.impedance_imag            = [impedance_imag]
   df.impedance_imag_error      = [impedance_imag_error]
   df.phase                     = [phase]
   df.phase_error               = [phase_error]
   df.ac_amplitude              = [ac_amplitude]

   return df
end
    
    
    
    
    
    
    
function import_oszi_imped(path,RV)
    time,potential, current   = read_imped_files(path)

    current = current ./ RV
    return time,potential,current
end
    
function f_sin(t,p)
    y_0 = p[1]
    A   = p[2]
    ω   = p[3]*2π
    ϕ   = p[4] # in rad
    y = fill(0.0,length(t))
   @. y = y_0+A*sin(ω*t+ϕ)
end
    
    
    
    
    
    
    
function fit_traces_for_imped(time,potential,current,meas_index; N_pnts= length(potential), df= nothing)

    Δt = time[2]-time[1]
    freq_0 = 1/ (N_pnts * Δt) 
    
    p0_pot = [
        1e-5,
        1e-5,
        freq_0,
        0.0
        ]
    p_lower_pot = [
        -2,
        -2,
        freq_0 - freq_0*0.15,
        -π
    ]
    p_upper_pot = [
        2,
        2,
        freq_0 + freq_0*0.15,
        π
    ]
    
    fit_potential = curve_fit(f_sin,time,potential,p0_pot,lower=p_lower_pot,upper=p_upper_pot)
    error_potential = margin_error(fit_potential)

    potential_amplitude                = fit_potential.param[1]
    potential_amplitude_error          = error_potential[1]
    potential_amplitude                = fit_potential.param[2]
    potential_amplitude_error          = error_potential[2]
    frequency_potential                = fit_potential.param[3] 
    frequency_potential_error          = error_potential[3] 
    phase_potential                    = fit_potential.param[4] / π * 180
    phase_potential_error              = error_potential[4] / π * 180


    p0_cur = p0_pot |> copy
    p0_cur[3] = frequency_potential |> copy


    p_lower_cur = p_lower_pot |> copy
    p_lower_cur[3] = frequency_potential- 0.025 * frequency_potential # fix frequency 
    p_lower_cur[4] = fit_potential.param[4]  - π # max phase difference to potental should be ±π


    p_upper_cur = p_upper_pot |> copy
    p_upper_cur[3] = frequency_potential + 0.025 * frequency_potential 
    p_upper_cur[4] = fit_potential.param[4] + π

    fit_current = curve_fit(f_sin,time,current,p0_cur,lower=p_lower_cur,upper=p_upper_cur)
    
    error_current = margin_error(fit_current)

    current_amplitude           = fit_current.param[1]
    current_amplitude_error     = error_current[1]

    current_amplitude           = fit_current.param[2]
    current_amplitude_error     = error_current[2]
    
    frequency_current           = fit_current.param[3]
    frequency_current_error     = error_current[3]
    
    phase_current                = fit_current.param[4] / π * 180
    phase_current_error         = error_current[4] / π * 180



    impedance_absolut = potential_amplitude / current_amplitude
    impedance_absolut_error = (potential_amplitude + potential_amplitude_error ) / (current_amplitude - current_amplitude_error)  - impedance_absolut |> abs
    
    phase_difference = phase_potential - phase_current |> abs
    error_phase_difference = phase_potential_error   + phase_current_error |> abs


    impedance_real = impedance_absolut * cos(phase_difference / 180 * π) |> abs
    impedance_real_error = impedance_absolut *  (cos((phase_difference + error_phase_difference) / 180 * π)  - cos((phase_difference) / 180 * π)  )  |> abs
    
    
    impedance_imag = impedance_absolut * sin(phase_difference / 180 * π) |> abs
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
            potential_amplitude
        )
    if df===nothing 
        return imp_table
    else
        append!(df,imp_table)
        return df
    end


    
end
   

   

 
 
    
    
    
    

    
    
    
    
    

    
  
    
    
    
    



