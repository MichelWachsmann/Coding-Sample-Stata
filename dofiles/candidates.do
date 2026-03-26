********************************************************************************
* Project: Coding Sample (Stata)
* Author: Michel Wachsmann
* Last Modified: 2026-03-25
* Description: Imports and cleans TSE candidates data (1994-2024).
*              Saves full candidate-level panel per year in temp, then appends
*              a reduced panel with key variables for analysis.
*              Layout A: 1994-2010 (63 vars)
*              Layout B: 2014-2024 (50 vars)
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

    import delimited "$INPUT_PATH/raw/candidates/consulta_cand_`year'_BRASIL.csv", ///
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
    rename cd_cargo                     office_code
    rename ds_cargo                     office
    rename sq_candidato                 candidate_seq
    rename nr_candidato                 candidate_number
    rename nm_candidato                 candidate_name
    rename nm_urna_candidato            ballot_name
    rename nm_social_candidato          social_name
    rename nr_cpf_candidato             cpf
    rename cd_situacao_candidatura      candidacy_status_code
    rename ds_situacao_candidatura      candidacy_status
    rename tp_agremiacao                party_type
    rename nr_partido                   party_number
    rename sg_partido                   party_abbrev
    rename nm_partido                   party_name
    rename sq_coligacao                 coalition_seq
    rename nm_coligacao                 coalition_name
    rename ds_composicao_coligacao      coalition_composition
    rename sg_uf_nascimento             birth_state
    rename dt_nascimento                birth_date
    rename nr_titulo_eleitoral_candidato voter_id
    rename cd_genero                    gender_code
    rename ds_genero                    gender
    rename cd_grau_instrucao            education_code
    rename ds_grau_instrucao            education
    rename cd_estado_civil              civil_status_code
    rename ds_estado_civil              civil_status
    rename cd_cor_raca                  race_code
    rename ds_cor_raca                  race
    rename cd_ocupacao                  occupation_code
    rename ds_ocupacao                  occupation
    rename cd_sit_tot_turno             round_result_code
    rename ds_sit_tot_turno             round_result

    * Rename variables only in Layout A: 1994-2010
    capture rename nm_email                         email
    capture rename cd_detalhe_situacao_cand         candidacy_detail_code
    capture rename ds_detalhe_situacao_cand         candidacy_detail
    capture rename cd_nacionalidade                 nationality_code
    capture rename ds_nacionalidade                 nationality
    capture rename cd_municipio_nascimento          birth_municipality_code
    capture rename nm_municipio_nascimento          birth_municipality
    capture rename nr_idade_data_posse              age_at_inauguration
    capture rename vr_despesa_max_campanha          max_campaign_expenditure
    capture rename st_reeleicao                     reelection
    capture rename st_declarar_bens                 assets_declared
    capture rename nr_protocolo_candidatura         candidacy_protocol
    capture rename nr_processo                      process_number
    capture rename cd_situacao_candidato_pleito     election_status_code
    capture rename ds_situacao_candidato_pleito     election_status
    capture rename cd_situacao_candidato_urna       ballot_status_code
    capture rename ds_situacao_candidato_urna       ballot_status
    capture rename st_candidato_inserido_urna       inserted_ballot

    * Rename variables only in Layout B: 2014-2024
    capture rename ds_email                         email
    capture rename nr_federacao                     federation_number
    capture rename nm_federacao                     federation_name
    capture rename sg_federacao                     federation_abbrev
    capture rename ds_composicao_federacao          federation_composition

    * Convert numeric variables
    destring year,                      replace
    destring election_type_code,        replace
    destring round,                     replace
    destring election_code,             replace
    destring office_code,               replace
    destring candidate_seq,             replace
    destring candidate_number,          replace
    destring cpf,                       replace force
    destring candidacy_status_code,     replace
    destring party_number,              replace
    destring coalition_seq,             replace force
    destring voter_id,                  replace force
    destring gender_code,               replace
    destring education_code,            replace
    destring civil_status_code,         replace
    destring race_code,                 replace
    destring occupation_code,           replace
    destring round_result_code,         replace

    * Convert numeric variables only in Layout A
    capture destring candidacy_detail_code,     replace
    capture destring nationality_code,          replace
    capture destring birth_municipality_code,   replace
    capture destring age_at_inauguration,       replace
    capture destring max_campaign_expenditure,  replace force
    capture destring candidacy_protocol,        replace force
    capture destring process_number,            replace force
    capture destring election_status_code,      replace
    capture destring ballot_status_code,        replace

    * Convert numeric variables only in Layout B
    capture destring federation_number,         replace

    * Save full year as temp
    save "$TEMP_PATH/candidates/candidates_`year'.dta", replace
    display as text ">>> Saved temp: candidates_`year'.dta"
}

********************************************************************************
* 3. APPEND REDUCED PANEL
********************************************************************************

display as text ">>> Appending all years..."

local keep_vars year election_type_code round election_code election_name ///
    election_date state office_code office candidate_seq candidate_number  ///
    candidate_name ballot_name cpf party_number party_abbrev party_name   ///
    gender_code gender birth_date occupation_code occupation               ///
    round_result_code round_result candidacy_status_code candidacy_status

use "$TEMP_PATH/candidates/candidates_1994.dta", clear
keep `keep_vars'

foreach year of local years {
    if `year' == 1994 continue
    append using "$TEMP_PATH/candidates/candidates_`year'.dta", keep(`keep_vars')
}

********************************************************************************
* 4. FINALIZE AND SAVE
********************************************************************************

sort year state candidate_seq

label variable year                     "Election year"
label variable election_type_code       "Election type code"
label variable round                    "Round number"
label variable election_code            "Election code"
label variable election_name            "Election name"
label variable election_date            "Election date"
label variable state                    "State abbreviation (UF)"
label variable office_code              "Office code"
label variable office                   "Office description"
label variable candidate_seq            "Candidate sequential ID (TSE)"
label variable candidate_number         "Candidate ballot number"
label variable candidate_name           "Candidate full name"
label variable ballot_name              "Candidate ballot name"
label variable cpf                      "Candidate CPF"
label variable party_number             "Party number"
label variable party_abbrev             "Party abbreviation"
label variable party_name               "Party name"
label variable gender_code              "Gender code"
label variable gender                   "Gender description"
label variable birth_date               "Birth date"
label variable occupation_code          "Occupation code"
label variable occupation               "Occupation description"
label variable round_result_code        "Round result code"
label variable round_result             "Round result description"
label variable candidacy_status_code    "Candidacy status code"
label variable candidacy_status         "Candidacy status description"

tabulate year

save "$INPUT_PATH/clean/candidates/data_candidates.dta", replace
display as text ">>> Saved: data_candidates.dta"
