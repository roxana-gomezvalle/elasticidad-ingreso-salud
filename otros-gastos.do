/*
    Projecto:        Elasticidad ingreso del gasto sanitario en los hogares 
	                 nicaragüenses.
    Autoras:         Roxana Gómez-Valle, Darling Rodríguez, Flavia García Álvarez 
	                 y Gabriela López Gutiérrez.  
    Producto:        Bases de datos de otros gastos del hogar. 	
	Año de creación: 2017
*/

/*
    Program set up		 
*/

global pjdatabase = "C:\Users\User\OneDrive\BCN 2017\Database"

set more off , perm
clear all
version 15.1

/*
    Gastos en servicios básicos
*/

*Alquiler
use "${pjdatabase}/emnv14_02_datos_de_la_vivienda_y_el_hogar.dta", clear

replace s1p12b = s1p12b * 26.276843
egen    alquiler = rsum (s1p12a s1p12b)
replace alquiler = . if ((s1p12a == .) & (s1p12b == .))
lab var alquiler "Pago mensual por alquiler de la vivienda"

*Amortización
replace s1p13b = s1p13b * 26.276843
egen    amort = rsum (s1p13a s1p13b)
replace amort = . if ((s1p13a == .) & (s1p13b == .))
lab var amort "Pago mensual amortización"

*Agua
gen     agua = s1p17
lab var agua "Pago mensual de agua"

*Basura
replace s1p20 = . if (s1p20 == 99998)
gen     basura = s1p20
lab var basura "Pago mensual por basura"

*Energía eléctrica
gen     energia = s1p23
lab var energia "Pago mensual por energia electrica"

*Combustible energia
gen     alumb_otros = s1p24
lab var alumb_otros "Pago por combustible para alumbrado"

*Combustible para cocinar
gen     cocina_comb = s1p27
lab var cocina_comb "Gasto mensual combustible para cocinar"

*Otros servicios
replace s1p30b = . if s1p30b == 9998
replace s1p30d = . if s1p30d == 9998
replace s1p30f = . if s1p30f == 9998

egen    otros_servicios = rsum (s1p30a s1p30b s1p30c s1p30d s1p30e s1p30f)
replace otros_servicios = . if ((s1p30a == .) & (s1p30b == .) & (s1p30c == .) ///
    & (s1p30d == .) & (s1p30e == .) & (s1p30f == .))
lab var otros_servicios "Gasto mensual por otros servicios"

*Total gastos por servicios en el hogar
egen    gastos_servicios = rsum (alquiler amort agua basura energia alumb_otros cocina_comb otros_servicios)
lab var gastos_servicios "Gastos mensuales por servicios en el hogar"

keep i00 gastos_servicios
save "${pjdatabase}/gastos-servicios-hogar.dta", replace

/*
    Transporte y otros servicios
*/
use "${pjdatabase}/emnv14_09_parte_b1_de_la_seccion_7.dta", clear
reshape wide s7p18 s7p17 , i(i00) j( s7b1cod)

egen    otros_gastos = rsum (s7p181 s7p182 s7p183 s7p184)
replace otros_gastos = . if  ((s7p181 == .) & (s7p182 == .) & (s7p183 == .) ///
    & (s7p184 == .))
replace otros_gastos = otros_gastos * 4.33
lab var otros_gastos "Gastos mensuales por otros gastos"

keep i00 otros_gastos
save "${pjdatabase}/otros-gastos.dta", replace

/*
    Gastos generales
*/
use "${pjdatabase}/emnv14_10_parte_b2_de_la_seccion_7.dta", clear
reshape wide s7p20 s7p19 , i(i00) j(s7b2cod)

egen gastos_generales = rsum (s7p201 s7p202 s7p203 s7p204 s7p205 s7p206 s7p207 ///
    s7p208 s7p209 s7p2010 s7p2011 s7p2012 s7p2013 s7p2014 s7p2015 s7p2016 s7p2017 ///
	s7p2018 s7p2019 s7p2020 s7p2021 s7p2022 s7p2023 s7p2024)
keep i00 gastos_generales	
save "${pjdatabase}/gastos-generales.dta", replace

/*
    Gastos en alimentos
*/
use "${pjdatabase}/emnv14_08_parte_a_de_la_seccion_7.dta", clear

*Gastos en alimentos
replace s7p6 = . if (s7p6 == 99999.99)
recode  s7p4 (1 = 30.41) (2 = 4.33) (3 = 2.16) (4 = 1) (5 = 0.333) (6 = 0.166) ///
    (7 = 0.083)
gen gasto_producto = s7p4 * s7p6

lab var gasto_producto "Gasto mensual por producto individual"

*Autoconsumo
gen     autogasto = s7p10 if ((s7p7 == 1) | (s7p7 == 3))
replace autogasto = autogasto * 30.41 if (s7p8 == 1)
replace autogasto = autogasto * 4.33 if (s7p8 == 2)
replace autogasto = autogasto * 2.16 if (s7p8 == 3)
replace autogasto = autogasto / 3 if (s7p8 == 5)
replace autogasto = autogasto / 6 if (s7p8 == 6)
replace autogasto = autogasto / 12 if (s7p8 == 7)
lab var autogasto "Autoconsumo pulperias y produccion propia"

*Total gasto en alimentos
egen    consumo_alimento = rsum (gasto_producto autogasto)
lab var consumo_alimento "Gaso mensual total"

*Gasto en alimentos del hogar
bys i00: egen gasto_alimento = sum (consumo_alimento)
sum           gasto_alimento 
lab var       gasto_alimento "Gasto mensual por alimento"

collapse (mean) dominio4 i06 gasto_alimento, by (i00)
save "${pjdatabase}/gastos-alimentos.dta", replace

exit
*End of do-file	


