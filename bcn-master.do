/*
    Projecto:        Elasticidad ingreso del gasto sanitario en los hogares 
	                 nicaragüenses.
    Autoras:         Roxana Gómez-Valle, Darling Rodríguez, Flavia García Álvarez 
	                 y Gabriela López Gutiérrez.  
    Producto:        Base de datos final para las estimaciones del modelo. 	
	Año de creación: 2017
*/

/*
    Program set up		 
*/

global pjdatabase = "C:\Users\User\OneDrive\BCN 2017\Database"
global dofiles = "C:\Users\User\OneDrive\BCN 2017\Do-files"

set more off , perm
clear all
version 15.1

/*
    Ejecutando do-files externos		 
*/
qui {
    do "${dofiles}/indice-de-riqueza.do" 
    do "${dofiles}/otros-gastos.do"
	do "${dofiles}/distancia-centro-salud.do"
	do "${dofiles}/gastos-educacion.do"
}

/*
    Limpieza de variables del hogar restantes		 
*/

use "${pjdatabase}/emnv14_04_poblacion.dta", clear
rename *, lower
numlabel, add

*Área de residencia
gen     rural = (i06 == 2)
lab var rural "Reside en zona rural"

*Región de residencia - Interactivas
gen     managua = (dominio == 1) 
lab var managua "Managua"

gen     pacifico = (dominio == 2)
lab var pacifico "Resto Pacífico"

gen     central = (dominio == 3)
lab var central "Centro" 

gen     caribe = (dominio == 4)
lab var caribe "Caribe"

gen     managua_rural = managua * rural 
lab var managua_rural "Zona rural Managua"

gen     pacifico_rural = pacifico * rural
lab var pacifico_rural "Zona rural Pacífico"

gen     central_rural = central * rural
lab var central_rural "Zona rural Central"

gen     caribe_rural = caribe * rural
lab var caribe_rural "Zona rural Caribe"

*Nivel educativo del jefe de hogar
recode s4p12a (0 1 2 3 12 = 0) (4 7 = 6)(5 6 = 9) (8 9 = 11) (10 = 16) (11 = 18) ///
    (else = .), gen (niv_edu)
	
gen     hh_escolaridad = niv_edu + s4p12b 
lab var hh_escolaridad "Años de escolaridad del jefe de hogar"

*Educación promedio
bys i00: egen hh_promesc = mean(hh_escolaridad)

*Sexo del jefe de hogar
gen jefe_mujer = ((s2p4 == 1) & (s2p5 == 2))

bys i00: egen hh_mujer = max(jefe_mujer)

*Número de niños
bys i00: egen children = count (s2p2a) if ((s2p2a>0) & (s2p2a<14))
bys i00: egen num_children = max(children)
lab var       num_children "Número de niños por hogar"
replace       num_children = 0 if num_children == .

*Número de ancianos
bys i00: egen ancianos = count (s2p2a) if (s2p2a >= 65)

bys i00: egen num_ancianos = max (ancianos)
lab var       num_ancianos "Número de ancianos por hogar"
replace       num_ancianos = 0 if (num_ancianos == .)

*Número de personas en el hogar
bys i00: egen h_size= max(s2p00)
lab var       h_size "Número de personas en el hogar"

*Presencia de mujeres en el hogar
gen mujer = (s2p5 == 2)
bys i00: egen mujer_hogar= max (mujer)
lab var mujer_hogar "Presencia de mujeres en el hogar"

/*
    Limpieza de variable ingreso	 
*/

/*
    Ingreso del primer trabajo	 
*/

*Ingreso por trabajo
replace s5p19a = . if ((s5p19a == 9999998)| (s5p19a == 9999999))
replace s5p19b = . if ((s5p19b == 98)| (s5p19b == 99))

gen     wage_freq = .
replace wage_freq = 30.41 if (s5p19b == 1)
replace wage_freq = 4.33 if (s5p19b == 2)
replace wage_freq = 2.16 if ((s5p19b == 3) | (s5p19b == 4))
replace wage_freq = 1 if (s5p19b == 5)
replace wage_freq = 1 / 3 if (s5p19b == 6)
replace wage_freq = 1 / 6 if (s5p19b == 7)
replace wage_freq = 1 / 12 if (s5p19b == 8)
lab var wage_freq "Frecuencia del salario"

gen     m_wage1 = wage_freq * s5p19a
lab var m_wage1 "Salario mensual primer trabajo"

*Ingreso por trabajo - otros
gen     m_extras= s5p20b
lab var m_extras "Ingreso mensual por otros"

*Ingreso por trabajo - otros derechos
replace s5p21b = . if ((s5p21b == 9999998) | (s5p21b == 9999999))
replace s5p21c = . if (s5p21c == 99)

gen     m_dtes = s5p21b / s5p21c
lab var m_dtes "Ingreso mensual por vacaciones, 13mes"

*Total ingreso mensual - primer trabajo asalariado
egen    mw_empleado = rsum (m_wage1 m_extras m_dtes)
replace mw_empleado = . if ((m_wage1 == .) & (m_extras == .) & (m_dtes == .))
lab var mw_empleado "Ingreso mensual empleado primer trabajo"

*Cuenta Propia, empleador, miembro de cooperativa
gen     inc_freq = .
replace inc_freq = 30.41 if (s5p26b == 1)
replace inc_freq = 4.33 if (s5p26b == 2)
replace inc_freq = 2.16 if ((s5p26b == 3) | (s5p26b == 4))
replace inc_freq = 1 if (s5p26b == 5)
replace inc_freq = 1 / 3 if (s5p26b == 6)
replace inc_freq = 1 / 6 if (s5p26b == 7)
replace inc_freq = 1 / 12 if (s5p26b == 8)
lab var inc_freq "Frecuencia del ingreso"

replace s5p26a = . if ((s5p26a == 9999998) | (s5p26a == 9999999))
gen     ing_cp = s5p26a * inc_freq
lab var ing_cp "Ingreso cuenta propia primer trabajo"

*Total ingreso mensual - primer trabajo no asalariado
egen    ing_pt = rsum (mw_empleado ing_cp)
replace ing_pt = . if ((ing_cp == .) & (mw_empleado == .))
lab var ing_pt "Ingreso total del primer trabajo"

/*
    Ingreso del segundo trabajo	 
*/

*Ingreso asalariado
gen     wage_freq2 = .
replace wage_freq2 = 30.41 if (s5p35b == 1)
replace wage_freq2 = 4.33 if (s5p35b == 2)
replace wage_freq2 = 2.16 if ((s5p35b == 3) | (s5p35b == 4))
replace wage_freq2 = 1 if (s5p35b == 5)
replace wage_freq2 = 1 / 3 if (s5p35b == 6)
replace wage_freq2 = 1 / 6 if (s5p35b == 7)
replace wage_freq2 = 1 / 12 if (s5p35b == 8)
lab var wage_freq2 "Frecuencia del segundo salario"

gen     m_wage2 = wage_freq2 * s5p35a
lab var m_wage2 "Salario mensual segundo trabajo"

*Otros ingresos
gen     extras2 = s5p36b
lab var extras2 "Ingresos mensuales otros segundo trabajo"

*Otros derechos
gen     m_dtm = s5p37b / s5p37c
lab var m_dtm "Ingresos mensuales por vacaciones, 13mes segundo trabajo"

*Ingreso mensual asalariado
egen    mw_empleado2 = rsum (m_wage2 extras2 m_dtm)
replace mw_empleado2 = . if ((m_wage2 == .) & (extras2 == .) & (m_dtm == .))
lab var mw_empleado2 "Salario mensual segundo trabajo"

*Ingresos por cuenta propia
replace s5p42b=. if s5p42b==99 | s5p42b==98

gen     inc_freq2 = .
replace inc_freq2 = 30.41 if (s5p42b == 1)
replace inc_freq2 = 4.33 if (s5p42b == 2)
replace inc_freq2 = 2.16 if ((s5p42b == 3) | (s5p42b == 4)) 
replace inc_freq2 = 1 if (s5p42b == 5)
replace inc_freq2 = 1 / 3 if (s5p42b == 6)
replace inc_freq2 = 1 / 6 if (s5p42b == 7)
replace inc_freq2 = 1 / 12 if (s5p42b == 8)
lab var inc_freq2 "Frecuencia del ingreso"

gen     ing_cp2 = inc_freq2 * s5p42a
lab var ing_cp2 "Ingreso cuenta propia segundo trabajo"

*Ingreso total por segundo trabajo
egen    ing_st = rsum (mw_empleado2 ing_cp2)
replace ing_st = . if ((ing_cp2 == .) & (mw_empleado2 == .))
lab var ing_st "Ingreso total del segundo trabajo"

/*
    Ingreso mensual individual
*/
egen    ing_mt = rsum (ing_st ing_pt)
replace ing_mt = . if ((ing_pt == .) & (ing_st == .))
lab var ing_mt "Ingreso total mensual individual"
replace ing_mt = . if (ing_mt == 1200000)
replace ing_mt = . if (ing_mt < 5)

/*
    Ingreso mensual por hogar
*/
bys i00: egen ingreso_hogar = sum (ing_mt)
replace       ingreso_hogar = . if (ingreso_hogar == 0)
lab var       ingreso_hogar "Ingreso mensual por hogar"

*Logaritmo del ingreso
gen     ln_ingreso = ln(ingreso_hogar)
lab var ln_ingreso "Logaritmo ingreso del hogar"

/*
    Tasa de dependencia
*/
gen recibe_inge = ((ing_mt > 0) & missing(ing_mt))
egen si_recing = sum(recibe_inge == 1), by(i00)
egen no_recing = sum(recibe_inge == 0), by(i00)
 
gen     tasa_depen = no_recing / si_recing
replace tasa_depen = no_recing if (si_recing == 0)
lab var tasa_depen "Tasa de dependencia del hogar"	

/*
    Variable dependiente: gastos por salud
*/
*Consultas médicas
replace s3p4b = . if s3p4b == 99998
gen     consulta = s3p4b
replace consulta = . if (((s3p1a == 6) | (s3p1a == 7)) & (s3p1b == .) ///
    & (s3p1c == .) & (s3p1d == .))
lab var consulta "Gastos por consulta"

*Medicamentos
gen     medicamentos = s3p5b 
replace medicamentos = . if (((s3p1a == 6) | (s3p1a ==7)) & (s3p1b == .) ///
    & (s3p1c == .) & (s3p1d == .))
lab var medicamentos "Gastos por medicamento"

*Exámenes
gen     examenes = s3p6b 
replace examenes = . if (((s3p1a == 6) | (s3p1a == 7)) & (s3p1b == .) ///
    & (s3p1c == .) & (s3p1d == .))
lab var examenes "Gastos por examenes"

*Hospitalización
gen     hospital = s3p7b 
replace hospital = . if (((s3p1a == 6) | (s3p1a == 7)) & (s3p1b == .) ///
    & (s3p1c == .) & (s3p1d == .))
lab var hospital "Gastos por hospitalización"

*Transporte
gen     transporte = s3p9b 
replace transporte = . if (((s3p1a == 6) | (s3p1a == 7))& (s3p1b == .) ///
    & (s3p1c == .) & (s3p1d == .))
lab var transporte "Gastos por transporte"

*Otros gastos en salud
gen     otros = s3p10b
replace otros = . if (((s3p1a == 6) | (s3p1a == 7)) & (s3p1b == .) ///
    & (s3p1c == .) & (s3p1d == .))	
lab var otros "Otros gastos en salud"

*Gasto individual en salud
egen    gasto_total = rsum (consulta medicamentos examenes hospital transporte otros)
replace gasto_total = . if ((consulta == .) & (medicamentos == .) ///
    & (examenes == .) & (hospital == .) & (transporte == .) & (otros == .))
lab var gasto_total "Gasto en salud por individuo"

*Gasto en salud del hogar
bys i00: egen gastos_salud = sum (gasto_total)
replace       gastos_salud = . if (gastos_salud == 0)
lab var       gastos_salud "Gasto mensual en salud por hogar" 

*Logaritmo gasto en salud
gen     ln_salud = ln(gastos_salud)
lab var ln_salud "Logaritmo gastos por salud del hogar"
/*
    Remesas del hogar
*/

egen remesa = anycount(s2p10a s2p10b s2p10c s2p10d), v(5)
bys i00: egen remesa_hh= sum(remesa)
replace       remesa_hh = 1 if (remesa_hh >= 1)

/*
    Limitando base de datos
*/

keep i00 s2p00 s2p4 rural managua pacifico central caribe managua_rural pacifico_rural ///
    central_rural caribe_rural hh_mujer hh_escolaridad num_ancianos ing_mt ///
	ingreso_hogar gastos_salud h_size mujer_hogar remesa_hh hh_escolaridad ///
	num_children ln_ingreso ln_salud tasa_depen hh_promesc
		
keep if (s2p00 == 1)

replace ln_ingreso = . if (i00 == 322301) // Información del jefe de hogar no disponible
replace ln_salud = . if (i00 == 322301)   // Información del jefe de hogar no disponible
replace hh_escolaridad = . if (i00 == 322301)   // Información del jefe de hogar no disponible
replace rural = . if (i00 == 322301)     // Información del jefe de hogar no disponible
replace h_size = . if (i00 == 322301)    // Información del jefe de hogar no disponible
replace ingreso_hogar = . if (i00 == 322301)    // Información del jefe de hogar no disponible
replace mujer = . if (i00 == 322301)    // Información del jefe de hogar no disponible

/*
    Unificando base de datos
*/
foreach file in "${pjdatabase}/indice-de-riqueza.dta" "${pjdatabase}/gastos-alimentos.dta" ///
    "${pjdatabase}/gastos-servicios-hogar.dta" "${pjdatabase}/otros-gastos.dta" ///
	"${pjdatabase}/gastos-generales.dta" "${pjdatabase}/distancia-hc.dta" ///
	"${pjdatabase}/gastos-educacion.dta" {
    merge 1:1 i00 using "`file'", gen (merge)
    drop merge
}

order i00, first
replace hc_distancia=. if (i00 == 322301)  // Información del jefe de hogar no disponible
/*
    Proporción del gasto del hogar en salud
*/
egen gasto_hogar = rsum (gastos_salud gasto_alimento gastos_generales ///
    otros_gastos gastos_servicios)
gen     per_hgasto = (gastos_salud / gasto_hogar) * 100
lab var per_hgasto "Gastos en salud como porcentaje del total"

gen     ln_porcentaje_gastoh = log(per_hgasto)
lab var ln_porcentaje_gastoh "Logaritmo gasto en salud como porcentaje del gasto total"

/*
    Regresiones
*/
*Modelo 1
reg ln_salud ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    central_rural caribe_rural num_children
outreg2 using modelosalud.doc, ctitle(Modelo 1) label alpha(0.001, 0.01, 0.05)

*Modelo 2
reg ln_salud ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    central_rural caribe_rural num_children num_ancianos
outreg2 using modelosalud.doc, append ctitle(Modelo 2) ///
    label alpha(0.001, 0.01, 0.05)

*Modelo 3	
reg ln_salud ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    central_rural caribe_rural num_children num_ancianos i.h_riq 
outreg2 using modelosalud.doc, append ctitle(Modelo 3) ///
    label alpha(0.001, 0.01, 0.05)
	
*Modelo 4	
reg ln_salud ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    central_rural caribe_rural num_children num_ancianos i.h_riq i.remesa_hh 
outreg2 using modelosalud.doc, append ctitle(Modelo 4) ///
    label alpha(0.001, 0.01, 0.05)
	
*Corrección de Heckman	
heckman  gastos_salud ln_ingreso  hh_escolaridad  rural pacifico central caribe ///
    pacifico_rural central_rural caribe_rural num_children                      ///
	, select (h_size ingreso_hogar hh_escolaridad mujer hc_distancia)
outreg2 using heckmanmod.doc, append label ctitle(Sesgo de seleccion) ///
    alpha(0.001, 0.01, 0.05) bdec(2) 
		
*Tests
test ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    pacifico_rural central_rural caribe_rural num_children
test ln_ingreso + hh_escolaridad + rural + pacifico + central + caribe ///
    + pacifico_rural + central_rural + caribe_rural + num_children = 0
test ln_ingreso = hh_escolaridad = rural = pacifico = central = caribe ///
    = pacifico_rural = central_rural = caribe_rural = num_children

qui reg ln_salud ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    central_rural caribe_rural num_children	
hettest 

qui reg ln_salud ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    central_rural caribe_rural num_children num_ancianos
hettest

qui reg ln_salud ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    central_rural caribe_rural num_children num_ancianos i.h_riq 
hettest

qui reg ln_salud ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    central_rural caribe_rural num_children num_ancianos i.h_riq i.remesa_hh 
hettest

ovtest
imtest, white

*Mínimos cuadrados en dos etapas
reg ln_salud ln_ingreso hh_escolaridad rural pacifico central caribe pacifico_rural ///
    central_rural caribe_rural num_children
estimates store mco
ivreg ln_salud (ln_ingreso = tasa_depen hh_promesc) hh_escolaridad rural pacifico ///
    central caribe pacifico_rural central_rural caribe_rural num_children
estimates store inst
hausman inst mco, constant

save "${pjdatabase}/master-database.dta", replace

exit
* End of do-file


