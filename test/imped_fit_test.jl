
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
measurements = [import_oszi_imped(m_pathes[i],RV[i]) for i in 1:length(m_pathes)]
r = r"(\d+)"
matches  = match.(r,readdir(path)) 
meas_indexes = [matches[i].captures[1] for i in 1:length(matches)]
df  = fit_traces_for_imped(measurements[1][1],measurements[1][2],measurements[1][3],meas_indexes[1])
for i in 2:length(measurements)
    fit_traces_for_imped(measurements[i][1],measurements[i][2],measurements[i][3],meas_indexes[i],df=df)
end




function plot_bode(df)

    p = plot(xlabel="frequency [Hz]",ylabel="abs. impedance [Ω]", axis= :log)
        scatter!(df.frequency,df.impedance,label=false,marker=(2,:black))
        
        #scatter!(df.frequency,df.phase,xaxis=:log,marker=(2,:steelblue))

    return p
end
    


p1 = plot_bode(df)
df