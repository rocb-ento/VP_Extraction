#! /bin/bash -l
#conda init
#conda activate DRUID_VP
function usage {
          echo "" 1>&2;
          echo "Usage: $0 -s <<YYYYmmdd>> -e <<YYYYmmdd>> -m <<CVP|QVP>> -c <<cfg_file>> [-h] [-v]" 1>&2;
          echo "" 1>&2;
          echo "Required Arguments: " 1>&2;
          echo "  -r : radar name" 1>&2;
          echo "  -s : Start date for VP extraction" 1>&2;
          echo "  -e : End date for VP extraction" 1>&2;
          echo "  -c : Path to config file" 1>&2;
          echo "" 1>&2;
          echo "Options: " 1>&2;
          echo "  -h : Show this usage helper" 1>&2;
          echo "  -v : Run programs in verbose mode" 1>&2;
          echo "" 1>&2;
          echo "$2" 1>&2;
          exit $1;
}

verbose="false"

while getopts ":r:s:e:c:h:v" flag; do
    case "${flag}" in
        r)
            r=${OPTARG}
            ;;
        s)
            s=${OPTARG}
            ;;
        e)
            e=${OPTARG}
            ;;
        c)
            c=${OPTARG}
            ;;
        h)
            usage 0 ""
            ;;
        v)
            verbose="true"
            ;;
        *)
            usage 1 "Unrecognised option ${flag}"
            ;;
    esac
done
shift $((OPTIND-1))

#Requires all these arguments
if [ -z "${r}" ] || [ -z "${s}" ] || [ -z "${e}" ] ||  [ -z "${c}" ]; then
    usage 1 "-r -s -e and -c arguments are all required"
fi

if [ $? != 0 ]; then
    exit
fi


mkdir -p Output
echo 'RunVP.sh -r' $r '-s' $s '-e' $e '-c' $c $verbose
date1=$( date -d $s +%s )
date2=$( date -d $e +%s )
if  [ $date2 -lt $date1 ]; then
  echo "start date occurs after end date. Swapping dates"
  date2=$( date -d $s +%s )
  date1=$( date -d $e +%s )
fi

date_len=$(( ($date2 - $date1 )/(60*60*24)+1))
Max_iter=$(( $date_len -1))

cat > vp_slurm.sb <<-EOF
#!/bin/bash -l
#SBATCH --account=ncas_radar
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --job-name=${r}
#SBATCH --time=4:00:00
#SBATCH --output=Output/${r}_%A_%a.out
#SBATCH --array=0-$Max_iter
#SBATCH --mem=2G

source activate DRUID_VP

# Calculate the date for this array task
this_date=${s}
if (( \$SLURM_ARRAY_TASK_ID > 0 )); then
    this_date=\$(date -d "${s} + \$SLURM_ARRAY_TASK_ID day" +'%Y%m%d')
fi

# Create job ID subdirectory and rename .out file to include date instead of task index
mkdir -p Output/\${SLURM_ARRAY_JOB_ID}
mv Output/${r}_\${SLURM_ARRAY_JOB_ID}_\${SLURM_ARRAY_TASK_ID}.out \
   Output/\${SLURM_ARRAY_JOB_ID}/${r}_\${SLURM_ARRAY_JOB_ID}_\${this_date}.out 2>/dev/null || true

source ./automation_scripts/VP_Main.sh ${r} ${s} ${c} \$SLURM_ARRAY_TASK_ID
EOF

echo "running batch script for ${r}, ${s}, ${c} ${Max_iter} days."
sbatch vp_slurm.sb