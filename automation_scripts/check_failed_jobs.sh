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
    echo "Usage: $0 -j <array_job_id> -r <radar> -s <start_date> -c <cfg_file> [-x]" 1>&2
    echo "" 1>&2
    echo "Required Arguments:" 1>&2
    echo "  -j : SLURM array job ID" 1>&2
    echo "  -r : Radar name (must match original RunVP.sh call)" 1>&2
    echo "  -s : Start date used in original RunVP.sh call (YYYYmmdd)" 1>&2
    echo "  -c : Path to config file" 1>&2
    echo "" 1>&2
    echo "Options:" 1>&2
    echo "  -x : Automatically resubmit failed dates (default: dry run only)" 1>&2
    echo "  -h : Show this usage helper" 1>&2
    exit $1
}

resubmit="false"

while getopts ":j:r:s:c:xh" flag; do
    case "${flag}" in
        j) job_id=${OPTARG} ;;
        r) r=${OPTARG} ;;
        s) s=${OPTARG} ;;
        c) c=${OPTARG} ;;
        x) resubmit="true" ;;
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
    --noheader \
    --parsable2 | \
    grep -E "FAILED|TIMEOUT|NODE_FAIL|OUT_OF_MEMORY" | \
    grep -E "_[0-9]+\|" | \
    awk -F'[_|]' '{print $2}' | \
    sort -un)

if [ -z "$failed_indices" ]; then
    echo "No failed tasks found for job ${job_id}."
    exit 0
fi

echo ""
echo "Failed array indices and corresponding dates:"
echo "----------------------------------------------"

failed_dates=()
for idx in $failed_indices; do
    if (( idx == 0 )); then
        this_date=$s
    else
        this_date=$(date -d "$s + $idx day" +'%Y%m%d')
    fi
    echo "  Index $idx -> $this_date"
    failed_dates+=("$this_date")
done

echo ""
echo "${#failed_dates[@]} failed date(s) found."

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
