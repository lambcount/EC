p1 = [100]
p2 = [100,1e-5]
p3 = [100,1e-5,1000]
p4 = [100,5e1,1000,5,5000]
p5 = [100,5e1-5,1000,1e3,1000]

p = [p1,p2,p3,p4,p5]

raw_circuit1 = "R_1"
raw_circuit2 = "R_1-C_1"
raw_circuit3 = "R_1-p(C_1,R_2)"
raw_circuit4 = "R_1-p(C_1,R_2)-p(C_2,R_3)"
raw_circuit5 = "R_1-p(C_1,R_2-p(L_1,R_3))"

raw_circuit = [raw_circuit1,raw_circuit2,raw_circuit3,raw_circuit4,raw_circuit5]

frq = [i*10^j for i in 0.1:0.1:9.9 for j in -2.0:1:5] |> sort

circs = [build_circuit(raw_circuit[i],p[i],frq) for i in 1:length(p)]


circs_test1 = EC.series([EC.R(p1[1],frq)])
circs_test2 = EC.series([EC.R(p1[1],frq),EC.C(p2[2],frq)])
circs_test3 = EC.series([EC.R(p1[1],frq),EC.parallel([EC.C(p2[2],frq),EC.R(p3[3],frq)])])
circs_test4 = EC.series(
    [
        EC.R(p4[1],frq),
        EC.parallel(
            [
                EC.C(p4[2],frq),
                EC.R(p4[3],frq)
            ]
        ),
        EC.parallel(
            [
                EC.C(p4[4],frq),
                EC.R(p4[5],frq)
            ]
        )
    ]
)
circs_test5 = EC.series(
    [
        EC.R(p5[1],frq),
        EC.parallel(
            [
                EC.C(p5[2],frq),
                EC.series(
                    [
                        EC.parallel(
                            [
                                EC.L(p5[3],frq),
                                EC.R(p5[4],frq)
                            ]
                        ),
                        EC.R(p5[5],frq)
                    ]
                )
            ]
        )
    ]
)


circs_test = [circs_test1,circs_test2,circs_test3,circs_test4,circs_test5]


test_circuits = [
    "R_1-p(C_1-R_2,CPE_1)-p(C_2-p(C_3,R_3),R_4)",
    "R_1-p(C_1-R_2,CPE_1)-p(C_2,R_3-p(C_3,R_4))",
    "R_1-p(C_1-R_2,CPE_1)-p(C_2,CPE_2,R_3-p(C_3,R_4))",
    "R_1-p(C_1-p(R_2,CPE_1),R_3)-p(C_2-p(C_3,R_4),R_5)",
    "R_1-p(C_1-p(R_2,CPE_1),R_3)-p(C_2-p(C_3,R_4),R_5,R_6)",
    "p(R_1,R_2)"
]

test_dictsdict = test_circuits .|> EC.conv_circuit 

p = plot(axis=:log,xlabel="frequency [Hz]",ylabel="impedance [Ω]")

for i = 5
    plot!(frq,circs_test[i] .|> real,label="test circ $i real",line=(2,:dash,0.6,:coral2))
    plot!(frq,circs_test[i] .|> imag .|> abs,label="test circ $i imag",line=(2,:dash,0.6,:steelblue))
    plot!(frq,circs[i].impedance .|> real,label="circ $i real",line=(2,:coral2,0.3))
    plot!(frq,circs[i].impedance .|> imag .|> abs,label="circ $i imag",line=(2,:steelblue,0.3))
end
p



good = [circs[i].impedance .- circs_test[i] |> sum for i in 1:length(circs)]

p