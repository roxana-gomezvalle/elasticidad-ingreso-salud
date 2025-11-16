/*
    Projecto:        Elasticidad ingreso del gasto sanitario en los hogares 
	                 nicaragüenses.
    Autoras:         Roxana Gómez-Valle, Darling Rodríguez, Flavia García Álvarez 
	                 y Gabriela López Gutiérrez.  
    Producto:        índice de riqueza. 	
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
    Creando los indicadores del índice		 
*/
use "${pjdatabase}/emnv14_18_parte_d_de_la_seccion_7.dta", clear
numlabel, add
codebook s7dcod

*Contando los equipos del hogar
by i00 , sort: gen num = s7dcod
drop s7p50a1 s7p50a2 
reshape wide s7dcod s7p47 s7p48 s7p49, i(i00) j(num)	
	
*Indicador de activos del hogar	
egen    assets = rsum (s7p481 s7p482 s7p483 s7p484 s7p485 s7p486 s7p487 s7p488 ///
                 s7p489 s7p4810 s7p4811 s7p4812 s7p4813 s7p4814 s7p4815 s7p4816 ///
				 s7p4817 s7p4818 s7p4819 s7p4820 s7p4821 s7p4822 s7p4823 s7p4824 ///
				 s7p4825 s7p4826 s7p4827 s7p4828 s7p4829 s7p4830 s7p4831 s7p4832 ///
				 s7p4833)
lab var assets "Numero de equipos con los que cuenta el hogar"

save "${pjdatabase}/equipos-del-hogar.dta", replace

*Servicios básicos
use "${pjdatabase}/emnv14_02_datos_de_la_vivienda_y_el_hogar", clear

*Electricidad
gen h_electricidad = (s1p21 == 1) if (s1p21 != .)

*Combustible para cocinar
gen h_combus = ((s1p22 == 2) | (s1p22 == 3) | (s1p22 == 4) | (s1p22 == 5)) ///
    if (s1p22 != .)

*Agua
gen h_agua = ((s1p15 == 1)| (s1p15 == 2)) if (s1p15 != .)

*Servicio higiénico
gen h_serv_hig_1 = ((s1p18 == 3) | (s1p18 == 4)) if (s1p18 != .)
gen h_serv_hig_2 = ((s1p18 == 1) | (s1p18 == 2)) if (s1p18 != .)
gen h_serv_hig_3 = ((s1p18 == 5) | (s1p18 == 6)) if (s1p18 != .)

*Piso de la vivienda
gen h_piso_1 = ((s1p5 == 1) | (s1p5 == 2)) if (s1p5 != .)
gen h_piso_2 = ((s1p5 == 3) | (s1p5 == 4)) if (s1p5 != .)
gen h_piso_3 = ((s1p5 == 5) | (s1p5 == 6)) if (s1p5 != .)

*Cuartos en el hogar
gen h_cuart_dorm_1 = (s1p10 > 2)
gen h_cuart_dorm_2 = (s1p10 == 2)
gen h_cuart_dorm_3 = ((s1p10 ==0) | (s1p10 == 1))

*Servicios de comunicación
local servicios s1p28a s1p28b s1p28c s1p28d s1p28e s1p28f
foreach servicio of local servicios {
    gen h_servi`servicio' = (`servicio' == 1) if (`servicio' != .)
}

joinby i00 using "${pjdatabase}/equipos-del-hogar.dta", unmatched (master) _merge(_merge)

global riqueza assets h_servis1p28a h_servis1p28b h_servis1p28c h_servis1p28d  ///
    h_servis1p28e h_servis1p28f h_serv_hig_1 h_serv_hig_2 h_serv_hig_3 h_piso_1 ///
	h_piso_2 h_piso_3 h_electricidad h_cuart_dorm_1 h_cuart_dorm_2 h_cuart_dorm_3

factor $riqueza [aw = peso2], pcf
predict ind_riq

xtile h_riq = ind_riq [aw = peso2], nq(5)
tab   h_riq, miss 

*Para hogares rurales
factor $riqueza [aw = peso2] if (i06 == 2) , pcf
predict ind_riqrur if (i06 == 2)

xtile h_riqrur = ind_riqrur if (i06 == 2) [aw = peso2] , nq(5)
tab h_riqrur , miss 

*******si lo hacemos urbano*****************************************************
/*
factor $riqueza [aw=peso2] if i06==1 , pcf
predict ind_riqurb if i06==1

xtile h_riqurb=ind_riqurb if i06==1 [aw = peso2], nq(5)

tab h_riqurb, miss */

keep i00 assets ind_riqrur h_riq
save "${pjdatabase}/indice-de-riqueza.dta", replace
exit
* End of do-file


