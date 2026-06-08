#! /bin/bash -l
# RunVP_dates.sh
# Like RunVP.sh but accepts an explicit list of dates (one per line) rather than a date range.
# Designed to rerun failed dates from a job array.
#
# Usage:
#   ./automation_scripts/RunVP_dates.sh -r <radar> -d <dates_file> -c <cfg_file>
#
# Example:
#   ./automation_scripts/RunVP_dates.sh -r Chenies -d failed_dates_12345678.txt -c ./config/chenies_cvp_new.cfg

function usage {
    echo "" 1>&2
    echo "Usage: $0 -r <radar> -d <dates_file> -c <cfg_file> [-v] [-h]" 1>&2
    echo "" 1>&2
    echo "Required Arguments:" 1>&2
    echo "  -r : Radar name" 1>&2
    echo "  -d : Path to file containing dates to process (one YYYYmmdd per line)" 1>&2
    echo "  -c : Path to config file" 1>&2
    echo "" 1>&2
    echo "Options:" 1>&2
    echo "  -v : Run in verbose mode" 1>&2
    echo "  -h : Show this usage helper" 1>&2
    exit $1
}

verbose="false"

while getopts ":r:d:c:vh" flag; do
    case "${flag}" in
        r) r=${OPTARG} ;;
        d) dates_file=${OPTARG} ;;
        c) c=${OPTARG} ;;
        v) verbose="true" ;;
        h) usage 0 ;;
        *) usage 1 "Unrecognised option ${flag}" ;;
    esac
done

if [ -z "${r}" ] || [ -z "${dates_file}" ] || [ -z "${c}" ]; then
    usage 1 "-r -d and -c arguments are all required"
fi

if [ ! -f "$dates_file" ]; then
    echo "Error: dates file not found: $dates_file"
    exit 1
fi

# Read dates into array, skipping blank lines
mapfile -t dates < <(grep -v '^\s*$' "$dates_file")
n_dates=${#dates[@]}

if [ $n_dates -eq 0 ]; then
    echo "No dates found in ${dates_file}. Exiting."
    exit 0
fi

echo "Rerunning ${n_dates} date(s) for radar ${r}"
echo "Dates: ${dates[*]}"

mkdir -p Output

# Write the dates array into the SLURM script as a bash array
# Each array task looks up its date by index
cat > vp_rerun_slurm.sb <<-EOF
#!/bin/bash -l
#SBATCH --account=ncas_radar
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --job-name=${r}_rerun
#SBATCH --time=4:00:00
#SBATCH --output=Output/${r}_rerun_%A_%a.out
#SBATCH --array=0-$(( n_dates - 1 ))
#SBATCH --mem=2G

source activate DRUID_VP

# Look up the date for this array task from the explicit list
dates=(${dates[*]})
this_date=\${dates[\$SLURM_ARRAY_TASK_ID]}

echo "Rerunning date: \${this_date} (task \$SLURM_ARRAY_TASK_ID)"

# Rename log to include date
mv Output/${r}_rerun_\${SLURM_ARRAY_JOB_ID}_\${SLURM_ARRAY_TASK_ID}.out \
   Output/${r}_rerun_\${SLURM_ARRAY_JOB_ID}_\${this_date}.out 2>/dev/null || true

python ./workflow_scripts/ukmo_cvp_extraction.py -r ${r} -t \${this_date} -c ${c}
EOF

echo "Submitting rerun job for ${n_dates} date(s)..."
sbatch vp_rerun_slurm.sb
