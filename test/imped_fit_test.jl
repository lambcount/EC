
t = collect(0:1e-3:1)
sine_1 = f_sin(t,[0,1,10,0])
sine_2 = f_sin(t,[0,0.5,100,0])
sine_3 = sine_1 .+ sine_2


path = "/Users/lammerzahl/Git/EC/test/Data/imped/mephisto"
m_pathes = joinpath.(path,readdir(path))
RV = [
    10,
    10,
    10,
    10,
    20,
    10,
    10,
    20,
    20,
    100,
    100
]

f = [
    1e4,
    7e3,
    3e3,
    3e3,
    3e3,
    1e3,
    7e2,
    7e2,
    3e2,
    3e2,
    1e2
]
measurements = [import_oszi_imped(m_pathes[i],RV[i]) for i in 1:length(m_pathes)]
r = r"(\d+)"
matches  = match.(r,readdir(path)) 
meas_indexes = [parse(Int,matches[i].captures[1]) for i in 1:length(matches)]
df,pot_fit,cur_fit  = fit_traces_for_imped(measurements[1][1],measurements[1][2],measurements[1][3],meas_indexes[1],f[1])
ar_pot_fit = []
push!(ar_pot_fit,pot_fit)
ar_cur_fit = []
push!(ar_cur_fit,cur_fit)
for i in 2:length(measurements)
    _df,_pot_fit,_cur_fit = fit_traces_for_imped(measurements[i][1],measurements[i][2],measurements[i][3],meas_indexes[i],f[i],df=df)
    push!(ar_pot_fit,_pot_fit)
    push!(ar_cur_fit,_cur_fit)
end




function plot_bode(df)
    p_imp = plot(xlabel="frequency [Hz]",ylabel="abs. impedance [Ω]", axis= :log)
        scatter!(df.frequency,df.impedance,label=false,marker=(5,:black))
    p_phase = plot(xlabel="frequency [Hz]",ylabel="phase [°]", xaxis= :log)
        scatter!(df.frequency,df.phase,xaxis=:log,marker=(5,:steelblue),ylim=(0,100))

        return plot(p_imp,p_phase,size = (1200,600))
end

p1 = plot_bode(df)
p2 = []

for i in 1:length(ar_pot_fit)
    _p_pot   = plot(xlabel="time [s]",ylabel="potential [V]")
               scatter!(measurements[i][1],measurements[i][2],label="raw pot",marker=(5,:steelblue,0.6))
               plot!(measurements[i][1],EC.f_sin(measurements[i][1],ar_pot_fit[i].param),label="fit pot",line=(3,:steelblue,1))
    _pot_cur = plot(xlabel="time [s]",ylabel="current [A]")
               scatter!(measurements[i][1],measurements[i][3],label="raw cur",marker=(5,:coral2,0.6))
               plot!(measurements[i][1],EC.f_sin(measurements[i][1],ar_cur_fit[i].param),label="fit cur",line=(3,:steelblue,1))
    _p       = plot(_p_pot,_pot_cur,size=(600,500))
    push!(p2,_p)
end
df