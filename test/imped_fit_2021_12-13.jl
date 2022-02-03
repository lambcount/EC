dir = "/Users/lammerzahl/Git/Share_Library/FcC11/data/exp_raw/EC/2012_11_22"
meas_name = ["kl_$i" for i in 794:848]
RV = [fill(10,22);fill(20,9);100;fill(500,5);1e4;fill(2e3,4);1e4;fill(5e4,3);fill(2e5,3);fill(2e6,6)]

f = [
    1e6,
    7e5,
    5e5,
    3e5,
    2e5,
    1e5,
    7e4,
    5e4,
    3e4,
    2e4,
    1e4,
    7e3,
    5e3,
    3e3,
    2e3,
    1e3,
    1.5e3,
    1.3e3,
    1.2e3,
    1.1e3,
    1e3,
    7e2,
    7e2,
    7e2,
    7e2,
    5e2,
    3e2,
    2e2,
    1e2,
    1e2,
    7e1,
    5e1,
    5e1,
    4e1,
    4e1,
    3e1,
    2e1,
    2e1,
    2e1,
    1e1,
    7,
    7,
    3,
    2,
    1,
    7e-1,
    5e-1,
    3e-1,
    2e-1,
    1e-1,
    7e-2,
    5e-2,
    3e-2,
    2e-2,
    1e-2

]
A = [
    fill(1e-1,21);
    fill(5e-2,3);
    fill(1e-1,4);
    5e-2;
    1e-1;
    fill(5e-2,4);
    fill(1e-1,19);
    fill(2e-1,2)
]

multiple = [fill(true,length(794:837));fill(false,length(838:848))]

if multiple |> length == RV |> length == f |> length == A |> length
    @time measurements = [import_oszi_imped(meas_name[i],dir,RV[i],multiple=multiple[i]) for i in 1:length(meas_name)]
else
    println("n_multiple = $(multiple |> length), n_RV = $(RV|> length), n_f = $(f |> length), n_A = $(A |> length)")
end
meas_indexes = [i for i in 794:848]
@time  df,pot_fit,cur_fit  = fit_traces_for_imped(measurements[1][1],measurements[1][2],measurements[1][3],meas_indexes[1],f[1],A[1],multiple=multiple[1])
ar_pot_fit = []
push!(ar_pot_fit,pot_fit)
ar_cur_fit = []
push!(ar_cur_fit,cur_fit)
for i in 2:length(measurements)
    @time _df,_pot_fit,_cur_fit = fit_traces_for_imped(measurements[i][1],measurements[i][2],measurements[i][3],meas_indexes[i],f[i],A[i],multiple=multiple[i],df=df)
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