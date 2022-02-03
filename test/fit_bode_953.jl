using Plots,DelimitedFiles
data  = readdlm("/Users/lammerzahl/Git/EC/test/Data/bode_plot/imp_953.txt")
frequency     = data[6:end-2,1]
Z_abs = data[6:end-2,2]
phase = data[6:end-2,3]

circuit_1_str = "R_1-p(R_2,C_1)"
circuit_1_lower = [5,  1e5, 1e-6]
circuit_1_upper = [51, 5e6, 1e-4]

circuit_2_str = "R_1-C_1-p(R_2,C_2)"
circuit_2_lower = [5, 1e-6, 1e5, 1e-6]
circuit_2_upper = [51,1e-3, 5e6, 1e-4]




circuit_1_fit = EC.fit_bode(circuit_1_str,frequency,Z_abs,circuit_1_lower,circuit_1_upper,bbo=true,bbo_time=20)
circuit_2_fit = EC.fit_bode(circuit_2_str,frequency,Z_abs,circuit_2_lower,circuit_2_upper,bbo=true,bbo_time=20)

p_imp   = plot(xlabel="frequency [Hz]",ylabel="abs. impedance [Ω]", axis= :log)
          scatter!(frequency,Z_abs,label=false,marker=(5,:black))
          plot!(frequency,circuit_1_fit.impedance .|> abs)
          plot!(frequency,circuit_2_fit.impedance .|> abs)
p_phase = plot(xlabel="frequency [Hz]",ylabel="phase [°]", xaxis= :log)
          scatter!(frequency,phase,xaxis=:log,marker=(5,:steelblue),ylim=(0,100))
          plot!(frequency,circuit_1_fit.phase .|> rad2deg)
          plot!(frequency,circuit_2_fit.phase .|> rad2deg)


p_imp