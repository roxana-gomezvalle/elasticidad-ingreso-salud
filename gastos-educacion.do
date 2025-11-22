/*
    Projecto:        Elasticidad ingreso del gasto sanitario en los hogares 
	                 nicaragüenses.
    Autoras:         Roxana Gómez-Valle, Darling Rodríguez, Flavia García Álvarez 
	                 y Gabriela López Gutiérrez.  
    Producto:        Base de datos de gastos en educación. 	
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
    Gastos en educación
*/
use "${pjdatabase}/emnv14_04_poblacion.dta", clear

/*
    Gastos de niños menores de seis años
*/

drop if (s4p6c < 3) //Eliminar pagos menores de tres meses

*Cleaning relevant variables
local pagos s4p6a s4p6b s4p6c s4p7a s4p7b s4p7c s4p8a s4p8b s4p8c
foreach pago of local pagos {
    replace `pago' = 0 if (`pago' ==.)
}

local apagos s4p9a s4p9b s4p9c s4p10a s4p10b s4p10c s4p10d s4p10e
foreach apago of local apagos {
    replace `apago' = 0 if (`apago' ==.)
}

local anuales s4p9b s4p9c s4p10b s4p10c s4p10d s4p10e
foreach anual of local anuales {
    replace `anual' = `anual' / 12
}

*Gastos totales en educación menores de seis años
egen    educ_expchild = rsum (s4p6b s4p7b s4p8b s4p8c s4p9b s4p9c s4p10b s4p10c ///
    s4p10d s4p10e)
lab var educ_expchild "Gastos en educacion para menores de 6 anos"

bys i00: egen hheduc_expchild = sum(educ_expchild)
lab var       hheduc_expchild "Gastos en educacion por hogar para menores de 6 anos" 

/*
    Gastos en educación mayores de seis años
*/

*Mensualidades y otros gastos 
drop if ((s4p21c < 3) | (s4p22c < 3))
drop if ((s4p20 == 1) & (s4p23c < 3)) //Eliminar solo si es a pie

local gastos s4p21a s4p21b s4p21c s4p22a s4p22b s4p22c s4p23a s4p23b s4p23c ///
    s4p24a s4p24b s4p24c s4p25a s4p25b s4p25c s4p26a s4p26b s4p26c s4p26d s4p28
foreach gasto of local gastos {
replace `gasto' = 0 if (`gasto' == .)
}

*Mensualizando gastos anuales
local mpagos s4p25a s4p25b s4p25c s4p26a s4p26b s4p26c s4p26d s4p28
foreach mpago of local mpagos {
    replace `mpago' = `mpago' / 12
}

*Gastos en cursos y capacitaciones
replace s4p30 = 0 if (s4p30 == .)
replace s4p30 = s4p30 / 12 

*Total gastos en educacion  mayores de seis años
egen    educ_exppers = rsum (s4p21b s4p22b s4p23b s4p24b s4p24c s4p25b s4p25c ///
    s4p26b s4p26c s4p26d s4p28 s4p30)
lab var educ_exppers "Gastos en educacion para personas mayores a 6 anos"

bys i00: egen hheduc_exppers = sum(educ_exppers)
lab var       hheduc_exppers "Gastos en educacion por hogar para personas mayores a 6 anos"

/*
    Gastos en educación del hogar
*/
egen    hheduc_exptot = rsum (hheduc_expchild hheduc_exppers)
lab var hheduc_exptot "Gastos totales del hogar en educacion"

/*
    Creating database
*/
keep i00 s2p00 hheduc_exptot hheduc_exppers hheduc_expchild
keep if s2p00 == 1
save "${pjdatabase}/gastos-educacion.dta", replace

exit
*End of do-file


