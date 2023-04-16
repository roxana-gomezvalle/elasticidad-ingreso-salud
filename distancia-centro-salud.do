/*
    Projecto:        Elasticidad ingreso del gasto sanitario en los hogares 
	                 nicaragüenses.
    Autoras:         Roxana Gómez-Valle, Darling Rodríguez, Flavia García Álvarez 
	                 y Gabriela López Gutiérrez.  
    Producto:        Base de datos con distancia del hogar del centro de salud 
	                 más cercano. 	
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
    Generando variable		 
*/

use "${pjdatabase}/emnv14_02_datos_de_la_vivienda_y_el_hogar.dta", clear

gen distancia_mts = s1p31mt / 1000
gen distancia_vrs = s1p31vr / 1196

egen    hc_distancia = rsum (s1p31km distancia_mts distancia_vrs)
lab var hc_distancia "Distancia al centro de salud más cercano km"

keep i00 hc_distancia
save "${pjdatabase}/distancia-hc.dta", replace
