## use the chenies_cvp_new.cfg to run for all chenies CVPs
./automation_scripts/RunVP.sh -r Chenies -s 20220101 -e 20220102 -c ./config/chenies_cvp_new.cfg
## check on the jobs as it is running - how many array jobs failed, running, completed 
sacct -j 30249180 --format=JobID,State --noheader | grep -E "^[0-9]+_[0-9]+[[:space:]]" | awk '{print $2}' | sort | uniq -c
./automation_scripts/check_failed_jobs.sh -j 30249180 -r Chenies -s 20220101 -c ./config/chenies_cvp_new.cfg
# running 30249180


#### running now for harpenden
## run for harpenden for whole archive (just a couple of days in 2013, not worth bothering with) 
./automation_scripts/RunVP.sh -r Chenies -s 20140101 -e 20260421 -c ./config/chenies_cvp_harpenden_save_to_gws.cfg
sacct -j 30266663 --format=JobID,State --noheader | grep -E "^[0-9]+_[0-9]+[[:space:]]" | awk '{print $2}' | sort | uniq -c
# find failed jobs
./automation_scripts/check_failed_jobs.sh -j 30266663 -r Chenies -s 20140101 -c ./config/chenies_cvp_harpenden_save_to_gws.cfg
# resubmit failed jobs
./automation_scripts/RunVP_dates.sh -r Chenies -d ./Output/failed_jobs/failed_dates_30266663.txt -c ./config/chenies_cvp_harpenden_save_to_gws.cfg
# resubmit jobID: 30275692
# seems to be that some h5 data files dont have data_type 'lp' in the top level groups
./automation_scripts/check_failed_jobs.sh -j 30275692 -r Chenies -s 20140101 -c ./config/chenies_cvp_harpenden_save_to_gws.cfg
sacct -j 30275692 --format=JobID,State --noheader | grep -E "^[0-9]+_[0-9]+[[:space:]]" | awk '{print $2}' | sort | uniq -c
./automation_scripts/RunVP_dates.sh -r Chenies -d ./Output/failed_jobs/failed_dates_30275692.txt -c ./config/chenies_cvp_harpenden_save_to_gws.cfg
sacct -j 30280650 --format=JobID,State --noheader | grep -E "^[0-9]+_[0-9]+[[:space:]]" | awk '{print $2}' | sort | uniq -c

./automation_scripts/check_failed_jobs.sh -j 30280650 -r Chenies -s 20140101 -c ./config/chenies_cvp_harpenden_save_to_gws.cfg -d -x
sacct -j 30283844 --format=JobID,State --noheader | grep -E "^[0-9]+_[0-9]+[[:space:]]" | awk '{print $2}' | sort | uniq -c
./automation_scripts/check_failed_jobs.sh -j 30283844 -r Chenies -s 20140101 -c ./config/chenies_cvp_harpenden_save_to_gws.cfg -d -x

##################### running now for watford to check everything works OK

./automation_scripts/RunVP.sh -r Chenies -s 20140101 -e 20150421 -c ./config/chenies_cvp_watford_save_to_gws.cfg
sacct -j 30301555 --format=JobID,State --noheader | grep -E "^[0-9]+_[0-9]+[[:space:]]" | awk '{print $2}' | sort | uniq -c
./automation_scripts/check_failed_jobs.sh -j 30301555 -r Chenies -s 20140101 -c ./config/chenies_cvp_watford_save_to_gws.cfg -d 
