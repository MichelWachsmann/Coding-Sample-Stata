********************************************************************************
* Project: Coding Sample (Stata)
* Author: Michel Wachsmann
* Last Modified: 2026-03-25
* Description: Imports and cleans TSE results data (1994-2024).
*              Saves full zone-municipality level panel per year in temp, then
*              appends a reduced panel with key variables for analysis.
*              Layout A: 1994-2014 (38 vars)
*              Layout B: 2016-2024 (50 vars) - adds legal status vars,
*              federation vars, vote destination and valid votes.
********************************************************************************

********************************************************************************
* 1. SETUP
********************************************************************************
clear all
set more off

local years 1994 1996 1998 2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024

********************************************************************************
* 2. IMPORT AND CLEAN EACH YEAR SEPARATELY
********************************************************************************
foreach year of local years {

    display as text ">>> Processing `year'..."

    import delimited "$INPUT_PATH/raw/results/votacao_candidato_munzona_`year'_BRASIL.csv", ///
        delimiter(";") encoding("latin1") stringcols(_all) varnames(1) clear

    * Drop metadata
    drop dt_geracao hh_geracao

    * Rename variables present in all years
    rename ano_eleicao                  year
    rename cd_tipo_eleicao              election_type_code
    rename nm_tipo_eleicao              election_type
    rename nr_turno                     round
    rename cd_eleicao                   election_code
    rename ds_eleicao                   election_name
    rename dt_eleicao                   election_date
    rename tp_abrangencia               scope
    rename sg_uf                        state
    rename sg_ue                        electoral_unit
    rename nm_ue                        electoral_unit_name
    rename cd_municipio                 municipality_id
    rename nm_municipio                 municipality_name
    rename nr_zona                      zone
    rename cd_cargo                     office_code
    rename ds_cargo                     office
    rename sq_candidato                 candidate_seq
    rename nr_candidato                 candidate_number
    rename nm_candidato                 candidate_name
    rename nm_urna_candidato            ballot_name
    rename nm_social_candidato          social_name
    rename cd_situacao_candidatura      candidacy_status_code
    rename ds_situacao_candidatura      candidacy_status
    rename cd_detalhe_situacao_cand     candidacy_detail_code
    rename ds_detalhe_situacao_cand     candidacy_detail
    rename tp_agremiacao                party_type
    rename nr_partido                   party_number
    rename sg_partido                   party_abbrev
    rename nm_partido                   party_name
    rename sq_coligacao                 coalition_seq
    rename nm_coligacao                 coalition_name
    rename ds_composicao_coligacao      coalition_composition
    rename st_voto_em_transito          transit_vote
    rename qt_votos_nominais            votes_nominal
    rename cd_sit_tot_turno             round_result_code
    rename ds_sit_tot_turno             round_result

    * Rename variables only in some Layout A years (capture)
    capture rename nr_federacao             federation_number
    capture rename nm_federacao             federation_name
    capture rename sg_federacao             federation_abbrev
    capture rename ds_composicao_federacao  federation_composition

    * Rename variables only in Layout B: 2016-2024
    capture rename cd_situacao_julgamento       judgment_status_code
    capture rename ds_situacao_julgamento       judgment_status
    capture rename cd_situacao_cassacao         cassation_status_code
    capture rename ds_situacao_cassacao         cassation_status
    capture rename cd_situacao_dconst_diploma   diploma_status_code
    capture rename ds_situacao_dconst_diploma   diploma_status
    capture rename cd_situacao_diploma          diploma_status_code
    capture rename ds_situacao_diploma          diploma_status
    capture rename nm_tipo_destinacao_votos     vote_destination_type
    capture rename qt_votos_nominais_validos    votes_nominal_valid

    * Convert numeric variables present in all years
    destring year,                  replace
    destring election_type_code,    replace
    destring round,                 replace
    destring election_code,         replace
    destring municipality_id,       replace
    destring zone,                  replace
    destring office_code,           replace
    destring candidate_seq,         replace force
    destring candidate_number,      replace
    destring candidacy_status_code, replace
    destring candidacy_detail_code, replace
    destring party_number,          replace
    destring coalition_seq,         replace force
    destring votes_nominal,         replace force
    destring round_result_code,     replace

    * Convert numeric variables present in some years
    capture destring federation_number,     replace
    capture destring judgment_status_code,  replace
    capture destring cassation_status_code, replace
    capture destring diploma_status_code,   replace
    capture destring votes_nominal_valid,   replace force

    * Save full year as temp
    save "$TEMP_PATH/results/results_`year'.dta", replace
    display as text ">>> Saved temp: results_`year'.dta"
}

********************************************************************************
* 3. APPEND REDUCED PANEL
********************************************************************************
display as text ">>> Appending all years..."

local keep_vars year election_type_code round election_code election_name  ///
    election_date state municipality_id municipality_name zone             ///
    office_code office candidate_seq candidate_number candidate_name       ///
    ballot_name party_number party_abbrev party_name                       ///
    candidacy_status_code candidacy_status                                 ///
    votes_nominal votes_nominal_valid                                      ///
    round_result_code round_result

use "$TEMP_PATH/results/results_1994.dta", clear
keep `keep_vars'

foreach year of local years {
    if `year' == 1994 continue

    preserve
    use "$TEMP_PATH/results/results_`year'.dta", clear
    capture confirm variable votes_nominal_valid
    local has_valid = (_rc == 0)
    restore

    if `has_valid' {
        append using "$TEMP_PATH/results/results_`year'.dta", keep(`keep_vars')
    }
    else {
        append using "$TEMP_PATH/results/results_`year'.dta", ///
            keep(year election_type_code round election_code election_name  ///
                election_date state municipality_id municipality_name zone  ///
                office_code office candidate_seq candidate_number           ///
                candidate_name ballot_name party_number party_abbrev        ///
                party_name candidacy_status_code candidacy_status           ///
                votes_nominal round_result_code round_result)
    }
}

********************************************************************************
* 4. FINALIZE AND SAVE
********************************************************************************
sort year state municipality_id zone candidate_seq

label variable year                     "Election year"
label variable election_type_code       "Election type code"
label variable round                    "Round number"
label variable election_code            "Election code"
label variable election_name            "Election name"
label variable election_date            "Election date"
label variable state                    "State abbreviation (UF)"
label variable municipality_id          "TSE municipality code"
label variable municipality_name        "Municipality name"
label variable zone                     "Electoral zone number"
label variable office_code              "Office code"
label variable office                   "Office description"
label variable candidate_seq            "Candidate sequential ID (TSE)"
label variable candidate_number         "Candidate ballot number"
label variable candidate_name           "Candidate full name"
label variable ballot_name              "Candidate ballot name"
label variable party_number             "Party number"
label variable party_abbrev             "Party abbreviation"
label variable party_name               "Party name"
label variable candidacy_status_code    "Candidacy status code"
label variable candidacy_status         "Candidacy status description"
label variable votes_nominal            "Nominal votes received"
label variable votes_nominal_valid      "Valid nominal votes (2016+)"
label variable round_result_code        "Round result code"
label variable round_result             "Round result description"

tabulate year

save "$INPUT_PATH/clean/results/data_results.dta", replace
display as text ">>> Saved: data_results.dta"
