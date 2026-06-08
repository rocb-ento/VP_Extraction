## use the chenies_cvp_new.cfg to run for all chenies CVPs
./automation_scripts/RunVP.sh -r Chenies -s 20220101 -e 20220102 -c ./config/chenies_cvp_new.cfg
## check on the jobs as it is running - how many array jobs failed, running, completed 
sacct -j 30249180 --format=JobID,State --noheader | grep -E "^[0-9]+_[0-9]+[[:space:]]" | awk '{print $2}' | sort | uniq -c
./automation_scripts/check_failed_jobs.sh -j 30249180 -r Chenies -s 20220101 -c ./config/chenies_cvp_new.cfg



## use the cvp_luton_harpenden.cfg (or change to user specify lat lons) to run custom CVPs
./automation_scripts/RunVP.sh -r Chenies -s 20220101 -e 20220135 -c ./chenies_cvp_luton_harpenden.cfg

## run for harpenden for whole archive (just a couple of days in 2013, not worth bothering with) NOT RUN YET
./automation_scripts/RunVP.sh -r Chenies -s 20140101 -e 20260421 -c ./chenies_cvp_luton_harpenden.cfg

####################### CHECKING 

# 1. Check for failures (dry run)
./automation_scripts/check_failed_jobs.sh -j 30238465 -r Chenies -s 20220101 -c ./config/chenies_cvp_new.cfg

# 2. Resubmit failures (add -x flag)
./automation_scripts/check_failed_jobs.sh -j 30238465 -r Chenies -s 20220101 -c ./config/chenies_cvp_new.cfg -x


