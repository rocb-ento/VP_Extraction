#! /bin/bash -l
# check_failed_jobs.sh
# Usage: ./automation_scripts/check_failed_jobs.sh -j <array_job_id> -r <radar> -s <start_date> -c <cfg_file>
#
# Queries sacct for failed array tasks and writes a file listing failed dates,
# then optionally resubmits them.
#
# Example:
#   ./automation_scripts/check_failed_jobs.sh -j 12345678 -r Chenies -s 20220101 -c ./config/chenies_cvp_new.cfg

function usage {
    echo "" 1>&2
    echo "Usage: $0 -j <array_job_id> -r <radar> -s <start_date> -c <cfg_file> [-x] [-d]" 1>&2
    echo "" 1>&2
    echo "Required Arguments:" 1>&2
    echo "  -j : SLURM array job ID" 1>&2
    echo "  -r : Radar name (must match original RunVP.sh call)" 1>&2
    echo "  -s : Start date used in original RunVP.sh call (YYYYmmdd)" 1>&2
    echo "  -c : Path to config file" 1>&2
    echo "" 1>&2
    echo "Options:" 1>&2
    echo "  -x : Automatically resubmit failed dates (default: dry run only)" 1>&2
    echo "  -d : Diagnose error types from .out files" 1>&2
    echo "  -h : Show this usage helper" 1>&2
    exit $1
}

resubmit="false"
diagnose="false"

while getopts ":j:r:s:c:xdh" flag; do
    case "${flag}" in
        j) job_id=${OPTARG} ;;
        r) r=${OPTARG} ;;
        s) s=${OPTARG} ;;
        c) c=${OPTARG} ;;
        x) resubmit="true" ;;
        d) diagnose="true" ;;
        h) usage 0 ;;
        *) usage 1 ;;
    esac
done

if [ -z "${job_id}" ] || [ -z "${r}" ] || [ -z "${s}" ] || [ -z "${c}" ]; then
    usage 1
fi

echo "Checking sacct for failed tasks in job array: ${job_id}"

# Query sacct for failed array tasks
# FAILED, TIMEOUT, NODE_FAIL, OUT_OF_MEMORY are all considered failures
failed_indices=$(sacct -j "${job_id}" \
    --format=JobID,State \
    --noheader | \
    awk '$2 ~ /^(FAILED|TIMEOUT|NODE_FAIL|OUT_OF_MEMORY)/ && $1 ~ /^[0-9]+_[0-9]+$/ {
        split($1, a, "_"); print a[2]
    }' | \
    sort -un)

if [ -z "$failed_indices" ]; then
    echo "No failed tasks found for job ${job_id}."
    exit 0
fi

echo ""
echo "Failed array indices and corresponding dates:"
echo "----------------------------------------------"

failed_dates=()
sp_error=()
other_error=()

for idx in $failed_indices; do
    if (( idx == 0 )); then
        this_date=$s
    else
        this_date=$(date -d "$s + $idx day" +'%Y%m%d')
    fi
    echo "  Index $idx -> $this_date"
    failed_dates+=("$this_date")

    # Diagnose error type by scanning the corresponding .out file
    if [ "$diagnose" == "true" ]; then
        out_file=$(ls ./Output/${job_id}/${r}_*_${this_date}.out 2>/dev/null | head -1)
        if [ -z "$out_file" ]; then
            other_error+=("$this_date (no .out file found)")
        elif grep -q "This may indicate an older HDF5 format" "$out_file"; then
            sp_error+=("$this_date")
        else
            # Grab the last error line for reporting
            err=$(grep -E "Error|error" "$out_file" | tail -1)
            other_error+=("$this_date: $err")
        fi
    fi
done

echo ""
echo "${#failed_dates[@]} failed date(s) found."

# Print diagnosis summary if -d flag was used
if [ "$diagnose" == "true" ]; then
    echo ""
    echo "====== ERROR DIAGNOSIS SUMMARY ======"
    echo "  sp/older HDF5 format errors : ${#sp_error[@]}"
    echo "  Other errors                : ${#other_error[@]}"
    if [ ${#other_error[@]} -gt 0 ]; then
        echo ""
        echo "  Dates with other errors:"
        for e in "${other_error[@]}"; do
            echo "    $e"
        done
    fi
    echo "======================================"
fi

failed_dates_file="./Output/failed_jobs/failed_dates_${job_id}.txt"
printf "%s\n" "${failed_dates[@]}" > "$failed_dates_file"
echo "Failed dates written to: ${failed_dates_file}"

# Write diagnosis summary to file if -d flag was used
if [ "$diagnose" == "true" ]; then
    reasons_file="./Output/failed_jobs/failed_dates_reasons_${job_id}.txt"
    {
        echo "====== ERROR DIAGNOSIS SUMMARY ======"
        echo "  sp/older HDF5 format errors : ${#sp_error[@]}"
        echo "  Other errors                : ${#other_error[@]}"
        if [ ${#other_error[@]} -gt 0 ]; then
            echo ""
            echo "  Dates with other errors:"
            for e in "${other_error[@]}"; do
                echo "    $e"
            done
        fi
        if [ ${#sp_error[@]} -gt 0 ]; then
            echo ""
            echo "  Dates with sp/older HDF5 format errors:"
            for e in "${sp_error[@]}"; do
                echo "    $e"
            done
        fi
        echo "======================================"
    } > "$reasons_file"
    echo "Error diagnosis written to: ${reasons_file}"
fi

# Write failed dates to a file for reference
failed_dates_file="./Output/failed_jobs/failed_dates_${job_id}.txt"
printf "%s\n" "${failed_dates[@]}" > "$failed_dates_file"
echo "Failed dates written to: ${failed_dates_file}"

if [ "$resubmit" == "true" ]; then
    echo ""
    echo "Resubmitting failed dates..."
    ./automation_scripts/RunVP_dates.sh -r "$r" -d "$failed_dates_file" -c "$c"
else
    echo ""
    echo "Dry run complete. To resubmit, run with -x flag or use:"
    echo "  ./automation_scripts/RunVP_dates.sh -r ${r} -d ${failed_dates_file} -c ${c}"
fi
