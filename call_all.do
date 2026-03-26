********************************************************************************
* Project: Coding Sample (Stata)
* Author: Michel Wachsmann
* Last Modified: 2026-03-25
********************************************************************************

clear all
set more off

********************************************************************************
* 1. MASTER PATH
********************************************************************************

* Change working directory to the folder containing this do-file
* Works on any machine as long as Stata is opened FROM this file
cd "`c(pwd)'"

* Store the root project directory (current working directory)
* This ensures that the entire project is portable and reproducible
global PROJ_PATH "`c(pwd)'"

* Normalize path separators (defensive, Stata handles / on Windows too)
if "`c(os)'" == "Windows" {
    global PROJ_PATH = subinstr("$PROJ_PATH", "\", "/", .)
}

********************************************************************************
* 2. INPUT / OUTPUT PATHS
********************************************************************************

* Define standardized folder structure
global INPUT_PATH  "$PROJ_PATH/input"
global DO_PATH     "$PROJ_PATH/dofiles"
global TEMP_PATH   "$INPUT_PATH/temp"

********************************************************************************
* 3. CREATE FOLDERS IF THEY DO NOT EXIST
********************************************************************************

* Input raw
cap mkdir "$INPUT_PATH"
cap mkdir "$INPUT_PATH/raw"
cap mkdir "$INPUT_PATH/raw/electorate"
cap mkdir "$INPUT_PATH/raw/candidates"
cap mkdir "$INPUT_PATH/raw/results"

* Input clean
cap mkdir "$INPUT_PATH/clean"
cap mkdir "$INPUT_PATH/clean/electorate"
cap mkdir "$INPUT_PATH/clean/candidates"
cap mkdir "$INPUT_PATH/clean/results"

* Input temp
cap mkdir "$TEMP_PATH"
cap mkdir "$TEMP_PATH/electorate"
cap mkdir "$TEMP_PATH/candidates"
cap mkdir "$TEMP_PATH/results"

* Do-files
cap mkdir "$DO_PATH"

********************************************************************************
* 4. RUN DO-FILES
********************************************************************************

* Data Cleaning
do "$DO_PATH/electorate.do"
do "$DO_PATH/candidates.do"
do "$DO_PATH/results.do"

