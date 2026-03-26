# Coding Sample (Stata)

**Author:** Michel Wachsmann (FGV EESP)  
**Date:** March 2026

## Overview

This repository processes and cleans electoral data from Brazil's **Tribunal Superior Eleitoral (TSE)**, covering all federal and local elections from 1994 to 2024. The project standardizes three main datasets—electorate demographics, candidate profiles, and voting results—across 16 election years spanning three decades.

The TSE provides the most comprehensive public record of Brazilian electoral data, including voter registration by demographic group, candidate characteristics, and vote counts at the electoral zone level. The raw data exhibit inconsistent variable names, multiple layout changes, and character encoding issues that prevent direct panel analysis. This project harmonizes variable naming, handles layout transitions, and produces clean, analysis-ready panel datasets.

## Data Sources

All data are sourced from the TSE's open data portal:  
https://dadosabertos.tse.jus.br/

### 1. Electorate Data (`perfil_eleitorado_*.csv`)
- **Years:** 1994, 1996, 1998, 2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022, 2024
- **Observation level:** Electoral zone × demographic profile
- **Raw file format:** Semicolon-delimited CSV, Latin1 encoding
- **Two layout structures:**
  - **Layout 1 (1994–2006):** 21 variables, includes biometric status
  - **Layout 2 (2008–2024):** 28 variables, adds race, gender identity, quilombola status, Libras interpreter registration, and mandatory voting indicator

### 2. Candidates Data (`consulta_cand_*_BRASIL.csv`)
- **Years:** 1994, 1996, 1998, 2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022, 2024
- **Observation level:** Candidate
- **Raw file format:** Semicolon-delimited CSV, Latin1 encoding
- **Two layout structures:**
  - **Layout A (1994–2010):** 63 variables, includes email, birth municipality, age at inauguration, maximum campaign expenditure, reelection status, asset declaration, candidacy protocol, process number, and ballot insertion status
  - **Layout B (2014–2024):** 50 variables, streamlined structure with federation variables

### 3. Results Data (`votacao_candidato_munzona_*_BRASIL.csv`)
- **Years:** 1994, 1996, 1998, 2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022, 2024
- **Observation level:** Electoral zone × municipality × candidate
- **Raw file format:** Semicolon-delimited CSV, Latin1 encoding
- **Two layout structures:**
  - **Layout A (1994–2014):** 38 variables
  - **Layout B (2016–2024):** 50 variables, adds legal judgment status, cassation status, diploma issuance status, vote destination type, and valid nominal votes

## Folder Structure

```text
TSE/
├── call_all.do                    # Master script: runs full pipeline
├── dofiles/
│   ├── electorate.do              # Electorate profile data cleaning (1994–2024)
│   ├── candidates.do              # Candidate information cleaning (1994–2024)
│   └── results.do                 # Election results cleaning (1994–2024)
└── input/
    ├── raw/                       # Raw TSE data files (CSV)
    │   ├── electorate/
    │   │   ├── perfil_eleitorado_1994.csv
    │   │   ├── perfil_eleitorado_1996.csv
    │   │   ├── ...
    │   │   └── perfil_eleitorado_2024.csv
    │   ├── candidates/
    │   │   ├── consulta_cand_1994_BRASIL.csv
    │   │   ├── consulta_cand_1996_BRASIL.csv
    │   │   ├── ...
    │   │   └── consulta_cand_2024_BRASIL.csv
    │   └── results/
    │       ├── votacao_candidato_munzona_1994_BRASIL.csv
    │       ├── votacao_candidato_munzona_1996_BRASIL.csv
    │       ├── ...
    │       └── votacao_candidato_munzona_2024_BRASIL.csv
    ├── clean/                     # Cleaned datasets (Stata .dta)
    │   ├── electorate/
    │   │   └── data_electorate.dta
    │   ├── candidates/
    │   │   └── data_candidates.dta
    │   └── results/
    │       └── data_results.dta
    └── temp/                      # Temporary year-level files
        ├── electorate/
        │   ├── electorate_1994.dta
        │   ├── electorate_1996.dta
        │   ├── ...
        │   └── electorate_2024.dta
        ├── candidates/
        │   ├── candidates_1994.dta
        │   ├── candidates_1996.dta
        │   ├── ...
        │   └── candidates_2024.dta
        └── results/
            ├── results_1994.dta
            ├── results_1996.dta
            ├── ...
            └── results_2024.dta
```

## How to Run

### Prerequisites

- **Stata** (>= 15.0 recommended for better Unicode handling)
- Raw CSV files downloaded from TSE and placed in `input/raw/` subdirectories

### One-Click Execution

Open Stata and run:

```stata
cd /path/to/TSE
do call_all.do
```

This runs the full pipeline: creates folder structure, imports raw data, harmonizes variables, converts data types, and saves cleaned panels.

### Step-by-Step Execution

Alternatively, run each script individually in order:

1. **`dofiles/electorate.do`**  
   Imports 16 years of electorate profile data, harmonizes variable names across two layout structures, converts string variables to numeric where appropriate, collapses zone-level demographics to municipality-year totals by gender, and saves the final panel.

2. **`dofiles/candidates.do`**  
   Imports 16 years of candidate data, standardizes variable names across two layout structures (1994–2010 vs. 2014–2024), converts numeric variables, keeps a reduced set of core variables, and appends all years into a single candidate-level panel.

3. **`dofiles/results.do`**  
   Imports 16 years of voting results at the zone-municipality-candidate level, harmonizes variable names across two layout structures (1994–2014 vs. 2016–2024), handles conditional presence of `votes_nominal_valid` (only available 2016+), and appends all years into a single panel.

## Data Processing Details

### Electorate Data Processing (`electorate.do`)

**Variables Present in All Years:**
- `year` — Election year
- `state` — State abbreviation (UF)
- `municipality_id` — TSE municipality code
- `municipality_name` — Municipality name
- `zone` — Electoral zone number
- `gender_code` — Gender code (0 = unknown, 2 = male, 4 = female)
- `gender` — Gender description
- `civil_status_code` — Marital status code
- `civil_status` — Marital status description
- `age_group_code` — Age group code
- `age_group` — Age group description
- `education_code` — Education level code
- `education` — Education level description
- `voters_profile` — Number of registered voters in this profile
- `voters_biometric` — Number of voters with biometric registration
- `voters_disability` — Number of voters with disability registration
- `voters_social_name` — Number of voters registered with social name

**Variables Present in 1994–2006 Only:**
- `biometric_status_code` — Municipality biometric collection status code
- `biometric_status` — Municipality biometric collection status description

**Variables Present in 2008–2024 Only:**
- `race_code` — Race/color code
- `race` — Race/color description
- `gender_identity_code` — Gender identity code
- `gender_identity` — Gender identity description
- `quilombola_code` — Quilombola community member indicator code
- `quilombola` — Quilombola community member indicator description
- `libras_interpreter_code` — Libras interpreter need indicator code
- `libras_interpreter` — Libras interpreter need indicator description
- `voting_mandatory` — Mandatory voting status

**Output Structure:**  
Municipality-year panel with total registered voters and counts by gender (`voters_total`, `voters_male`, `voters_female`, `voters_unknown`).

### Candidates Data Processing (`candidates.do`)

**Core Variables (Retained in Final Panel):**
- `year` — Election year
- `election_type_code` — Election type code
- `round` — Round number (1 or 2)
- `election_code` — Election code
- `election_name` — Election name
- `election_date` — Election date
- `state` — State abbreviation (UF)
- `office_code` — Office code
- `office` — Office description (e.g., President, Governor, Mayor, Senator)
- `candidate_seq` — Candidate sequential ID (TSE unique identifier)
- `candidate_number` — Candidate ballot number
- `candidate_name` — Candidate full legal name
- `ballot_name` — Candidate name as printed on ballot
- `cpf` — Candidate CPF (individual taxpayer ID)
- `party_number` — Party number
- `party_abbrev` — Party abbreviation
- `party_name` — Party full name
- `gender_code` — Gender code
- `gender` — Gender description
- `birth_date` — Birth date
- `occupation_code` — Occupation code
- `occupation` — Occupation description
- `round_result_code` — Round result code
- `round_result` — Round result description (e.g., elected, not elected)
- `candidacy_status_code` — Candidacy status code
- `candidacy_status` — Candidacy status description (e.g., approved, rejected)

**Additional Variables Present in 1994–2010 (Stored in Temp Files):**
- `email` — Candidate email
- `candidacy_detail_code` — Candidacy detail code
- `candidacy_detail` — Candidacy detail description
- `nationality_code` — Nationality code
- `nationality` — Nationality description
- `birth_municipality_code` — Birth municipality code
- `birth_municipality` — Birth municipality name
- `age_at_inauguration` — Age at inauguration
- `max_campaign_expenditure` — Maximum allowed campaign expenditure
- `reelection` — Reelection status
- `assets_declared` — Asset declaration status
- `candidacy_protocol` — Candidacy protocol number
- `process_number` — Legal process number
- `election_status_code` — Election status code
- `election_status` — Election status description
- `ballot_status_code` — Ballot status code
- `ballot_status` — Ballot status description
- `inserted_ballot` — Whether candidate was inserted into electronic ballot

**Additional Variables Present in 2014–2024 (Stored in Temp Files):**
- `federation_number` — Federation number
- `federation_name` — Federation name
- `federation_abbrev` — Federation abbreviation
- `federation_composition` — Federation composition

**Output Structure:**  
Candidate-level panel with core variables retained for analysis.

### Results Data Processing (`results.do`)

**Core Variables (Retained in Final Panel):**
- `year` — Election year
- `election_type_code` — Election type code
- `round` — Round number
- `election_code` — Election code
- `election_name` — Election name
- `election_date` — Election date
- `state` — State abbreviation (UF)
- `municipality_id` — TSE municipality code
- `municipality_name` — Municipality name
- `zone` — Electoral zone number
- `office_code` — Office code
- `office` — Office description
- `candidate_seq` — Candidate sequential ID (TSE unique identifier)
- `candidate_number` — Candidate ballot number
- `candidate_name` — Candidate full legal name
- `ballot_name` — Candidate name as printed on ballot
- `party_number` — Party number
- `party_abbrev` — Party abbreviation
- `party_name` — Party full name
- `candidacy_status_code` — Candidacy status code
- `candidacy_status` — Candidacy status description
- `votes_nominal` — Nominal votes received by candidate
- `votes_nominal_valid` — Valid nominal votes (available 2016–2024 only)
- `round_result_code` — Round result code
- `round_result` — Round result description

**Additional Variables Present in 2016–2024 (Stored in Temp Files):**
- `judgment_status_code` — Legal judgment status code
- `judgment_status` — Legal judgment status description
- `cassation_status_code` — Cassation status code
- `cassation_status` — Cassation status description
- `diploma_status_code` — Diploma issuance status code
- `diploma_status` — Diploma issuance status description
- `vote_destination_type` — Vote destination type

**Output Structure:**  
Electoral zone × municipality × candidate panel with votes received. The panel includes all 16 election years, with `votes_nominal_valid` populated only for 2016–2024.

## Key Design Choices

### Portability
- All file paths are defined relative to the project root using Stata's `c(pwd)` feature
- Works on any operating system (Windows, macOS, Linux) without path modifications
- The `call_all.do` master script automatically creates all necessary folder structures

### Layout Harmonization
- Raw TSE data exhibit two to three distinct variable layouts per dataset due to changes in data collection protocols
- Each do-file uses `capture rename` and `capture destring` to handle variables that appear only in certain years
- Full year-level files are saved to `temp/` directories, preserving all original variables
- Reduced panels are created by selecting core variables common across all years

### Encoding and Delimiter Handling
- All raw TSE files use Latin1 (ISO-8859-1) encoding and semicolon delimiters
- Import commands explicitly specify `encoding("latin1")` and `delimiter(";")` to ensure proper character handling for Portuguese text with accents and special characters
- All variables are initially imported as strings (`stringcols(_all)`) to avoid type conflicts, then converted to numeric via `destring` where appropriate

### Variable Naming Convention
- Portuguese TSE variable names (e.g., `ano_eleicao`, `nm_candidato`) are renamed to English equivalents (`year`, `candidate_name`)
- Code variables are named with `_code` suffix (e.g., `gender_code`, `office_code`)
- Description variables use full English words (e.g., `gender`, `office`)

### Gender Coding
- TSE uses numeric gender codes: 0 = unknown/not declared, 2 = male, 4 = female
- Electorate data are collapsed to municipality-year totals by gender for easier aggregation

### Missing Data Handling
- `destring` uses `force` option where necessary to convert non-numeric strings to missing values
- CPF, coalition sequence, and voter ID variables often contain missing or non-numeric entries and are converted with `force`

## Output Datasets

### `input/clean/electorate/data_electorate.dta`
- **Observation level:** Municipality × year
- **Panel structure:** 1994–2024 (16 election years)
- **Key variables:** `voters_total`, `voters_male`, `voters_female`, `voters_unknown`
- **Use case:** Analyzing electorate size and gender composition over time

### `input/clean/candidates/data_candidates.dta`
- **Observation level:** Candidate × election × round
- **Panel structure:** 1994–2024 (16 election years)
- **Key variables:** Candidate demographics, party affiliation, office sought, election outcome
- **Use case:** Studying candidate characteristics, party composition, and electoral success

### `input/clean/results/data_results.dta`
- **Observation level:** Electoral zone × municipality × candidate × election × round
- **Panel structure:** 1994–2024 (16 election years)
- **Key variables:** `votes_nominal`, `votes_nominal_valid` (2016+), candidate and party identifiers
- **Use case:** Vote share analysis, turnout estimation, geographic voting patterns

## Data Limitations and Notes

- **Zone-level geographic identifiers:** Electoral zones change boundaries and identifiers over time, making longitudinal zone-level analysis challenging. Municipality-level aggregation is more stable.
- **2012 candidate data:** The 2012 candidate file is substantially larger than adjacent years, suggesting possible duplication or different inclusion criteria.
- **Missing `votes_nominal_valid`:** Only available from 2016 onward. Prior years include only `votes_nominal`.
- **Encoding issues:** Some municipality names and candidate names contain special characters that may require Latin1 encoding awareness in downstream analysis.
- **Coalition and federation data:** Coalition composition and federation variables are stored as text and may require additional parsing for coalition-level analysis.

## References

- Tribunal Superior Eleitoral (TSE). *Repositório de Dados Eleitorais.* Available at: https://dadosabertos.tse.jus.br/
- IBGE. *Divisão Territorial Brasileira.* Brazilian Institute of Geography and Statistics.
