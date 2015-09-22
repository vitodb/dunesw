#!/bin/bash

NEVENTS=$1
STEP=$2
LARSOFT_REFERENCE_VERSION=$3
BASEFILENAME=$4
EXPCODE=$5

declare -a STEPS=( ${@:6:$(($#-5))} )


INPUT_FILE="${BASEFILENAME}_Reference_${STEPS[STEP-1]}_${LARSOFT_REFERENCE_VERSION}.root"
if [ x"${STEPS[STEP-1]}" == xnone ]; then INPUT_FILE=""; fi

OUTPUT_FILE="${BASEFILENAME}_Current_${STEPS[STEP]}.root"

FHiCL_FILE="ci_test_${STEPS[STEP]}_${EXPCODE}.fcl"

echo "Input file:  $INPUT_FILE"
echo "Output file: $OUTPUT_FILE"
echo "FHiCL file:  $FHiCL_FILE"
echo



function larsoft_data_production
{

    echo -e "\nNumber of events for ${STEPS[STEP]} step: $NEVENTS\n"
    echo lar --rethrow-default -n $NEVENTS -o $OUTPUT_FILE --config $FHiCL_FILE ${INPUT_FILE}
    echo

    lar --rethrow-default -n $NEVENTS -o $OUTPUT_FILE --config $FHiCL_FILE ${INPUT_FILE}

}

function compare_data_products
{

    declare -a CHECKMSG=("Check for added/removed data products" "Check for differences in the size of data products")


    if [ $COMPAREINIT -eq 0 ]; then

        lar --rethrow-default -n $NEVENTS --config eventdump.fcl ${BASEFILENAME}_Reference_${STEPS[STEP]}_${LARSOFT_REFERENCE_VERSION}.root > ${BASEFILENAME}_Reference_${STEPS[STEP]}.dump
        OUTPUT_REFERENCE=$(cat ${BASEFILENAME}_Reference_${STEPS[STEP]}.dump | sed -e  '/PROCESS NAME/,/^\s*$/!d ; s/PROCESS NAME.*$// ; /^\s*$/d' )

        lar --rethrow-default -n $NEVENTS --config eventdump.fcl ${BASEFILENAME}_Current_${STEPS[STEP]}.root > ${BASEFILENAME}_Current_${STEPS[STEP]}.dump
        OUTPUT_CURRENT=$(cat ${BASEFILENAME}_Current_${STEPS[STEP]}.dump | sed -e  '/PROCESS NAME/,/^\s*$/!d ; s/PROCESS NAME.*$// ; /^\s*$/d' )

        echo -e "\nCompare data products."
        echo    "Reference files for ${STEPS[STEP]} step generated using LARSOFT_VERSION $LARSOFT_REFERENCE_VERSION"
        echo -e "Current files for ${STEPS[STEP]} step generated using LARSOFT_VERSION $LARSOFT_VERSION\n"
        echo -e "\n${BASEFILENAME}_Reference_${STEPS[STEP]}.dump\n"
        echo "$OUTPUT_REFERENCE"
        echo -e "\n${BASEFILENAME}_Current_${STEPS[STEP]}.dump\n"
        echo "$OUTPUT_CURRENT"
    fi

    DIFF=$(diff  <(echo "$OUTPUT_REFERENCE" | awk -v MYNF=$((1-$1)) 'NF{NF-=MYNF}1' | sed 's/\.//g' ) <(echo "$OUTPUT_CURRENT" | awk -v MYNF=$((1-$1)) 'NF{NF-=MYNF}1' | sed 's/\.//g' ) )

    echo
    echo ${CHECKMSG[$1]}
    echo "difference(s)"
    echo

    if [ ${#DIFF} -gt 0 ]; then
       echo "$DIFF"
       exitstatus 1999 "compare_data_products step $1";
    else
       echo -e "none\n\n"
    fi

    COMPAREINIT=1

}

function exitstatus
{
    EXITSTATUS=$1
    TASKSTRING=$2

    echo -e "\nCI MSG $TASKSTRING exit status: ${EXITSTATUS}\n"
    if [ ${EXITSTATUS} -ne 0 ]; then
      exit ${EXITSTATUS}
    fi
}

trap 'LASTERR=$?; echo -e "\nCI MSG `basename $0`: line ${LINENO}: exit status: ${LASTERR}\n"; exit ${LASTERR}' ERR

echo -e "\nRun `basename $0` script"

larsoft_data_production

exitstatus $? "larsoft_data_production"


COMPAREINIT=0
compare_data_products 0 #Check for added/removed data products

exitstatus $? "compare_data_products step 0"

# compare_data_products 1 #Check for differences in the size of data products

# exitstatus $? "compare_data_products step 1"
