********************************************************************************
* Project: Coding Sample (Stata)
* Author: Michel Wachsmann
* Last Modified: 2026-03-23
* Description: Imports and cleans TSE electorate profile data (1994-2024).
*              Saves full zone-level demographic panel, all variables retained.
*              Layout 1: 1994-2006 (21 vars) - includes biometric status,
*              excludes race/identity/quilombola/libras/voting_mandatory.
*              Layout 2: 2008-2024 (28 vars) - excludes biometric status,
*              includes race/identity/quilombola/libras/voting_mandatory.
********************************************************************************

********************************************************************************
* 1. SETUP
********************************************************************************

clear all
set more off

* Years available
local years 1994 1996 1998 2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024

********************************************************************************
* 2. IMPORT AND CLEAN EACH YEAR SEPARATELY
********************************************************************************

foreach year of local years {

    display as text ">>> Processing `year'..."

    * Import raw CSV: all columns as string to avoid type conflicts across years
    import delimited "$INPUT_PATH/raw/electorate/perfil_eleitorado_`year'.csv", ///
        delimiter(";") encoding("latin1") stringcols(_all) varnames(1) clear

    * Drop metadata variables (file generation timestamp, not data)
    drop dt_geracao hh_geracao

    * Rename variables present in all years
    rename ano_eleicao                  year
    rename sg_uf                        state
    rename cd_municipio                 municipality_id
    rename nm_municipio                 municipality_name
    rename nr_zona                      zone
    rename cd_genero                    gender_code
    rename ds_genero                    gender
    rename cd_estado_civil              civil_status_code
    rename ds_estado_civil              civil_status
    rename cd_faixa_etaria              age_group_code
    rename ds_faixa_etaria              age_group
    rename cd_grau_escolaridade         education_code
    rename ds_grau_escolaridade         education
    rename qt_eleitores_perfil          voters_profile
    rename qt_eleitores_biometria       voters_biometric
    rename qt_eleitores_deficiencia     voters_disability
    rename qt_eleitores_inc_nm_social   voters_social_name

    * Rename variables only in 1994-2006
    capture rename cd_mun_sit_biometrica    biometric_status_code
    capture rename ds_mun_sit_biometrica    biometric_status

    * Rename variables only in 2008-2024
    capture rename cd_raca_cor              race_code
    capture rename ds_raca_cor              race
    capture rename cd_identidade_genero     gender_identity_code
    capture rename ds_identidade_genero     gender_identity
    capture rename cd_quilombola            quilombola_code
    capture rename ds_quilombola            quilombola
    capture rename cd_interprete_libras     libras_interpreter_code
    capture rename ds_interprete_libras     libras_interpreter
    capture rename tp_obrigatoriedade_voto  voting_mandatory

    * Convert numeric variables present in all years
    destring year,                   replace
    destring municipality_id,        replace
    destring zone,                   replace
    destring gender_code,            replace
    destring civil_status_code,      replace
    destring age_group_code,         replace
    destring education_code,         replace
    destring voters_profile,         replace force
    destring voters_biometric,       replace force
    destring voters_disability,      replace force
    destring voters_social_name,     replace force

    * Convert numeric variables only in 1994-2006
    capture destring biometric_status_code, replace

    * Convert numeric variables only in 2008-2024
    capture destring race_code,               replace
    capture destring gender_identity_code,    replace
    capture destring quilombola_code,         replace
    capture destring libras_interpreter_code, replace

    * Save each year as separate temp file
    save "$TEMP_PATH/electorate/electorate_`year'.dta", replace
    display as text ">>> Saved temp: electorate_`year'.dta"
}

********************************************************************************
* 3. APPEND ALL YEARS INTO PANEL
********************************************************************************

display as text ">>> Appending all years..."

use "$TEMP_PATH/electorate/electorate_1994.dta", clear

keep year state municipality_id municipality_name gender_code voters_profile

foreach year of local years {
    if `year' == 1994 continue

    append using "$TEMP_PATH/electorate/electorate_`year'.dta", ///
        keep(year state municipality_id municipality_name gender_code voters_profile)
}

********************************************************************************
* 4. COLLAPSE AND SAVE FINAL PANEL
********************************************************************************

* Basic check
tabulate year

* Gender-specific counts
gen voters_male    = voters_profile if gender_code == 2
gen voters_female  = voters_profile if gender_code == 4
gen voters_unknown = voters_profile if gender_code == 0

* Collapse to municipality-year level
collapse ///
    (sum) voters_profile ///
    (sum) voters_male ///
    (sum) voters_female ///
    (sum) voters_unknown, ///
    by(year state municipality_id municipality_name)

rename voters_profile voters_total

sort year state municipality_id

label variable year              "Election year"
label variable state             "State abbreviation (UF)"
label variable municipality_id   "TSE municipality code"
label variable municipality_name "Municipality name"
label variable voters_total      "Total registered voters"
label variable voters_male       "Male registered voters"
label variable voters_female     "Female registered voters"
label variable voters_unknown    "Registered voters with unknown gender"

save "$INPUT_PATH/clean/electorate/data_electorate.dta", replace
display as text ">>> Saved: data_electorate.dta"
