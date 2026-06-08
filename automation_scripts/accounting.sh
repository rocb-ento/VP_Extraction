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



##################### test run for watford to check everything works OK
# 9 failures in initial run - caused by missing times within files 
./automation_scripts/RunVP.sh -r Chenies -s 20150101 -e 20150421 -c ./config/chenies_cvp_watford_save_to_gws.cfg
sacct -j 30304234 --format=JobID,State --noheader | grep -E "^[0-9]+_[0-9]+[[:space:]]" | awk '{print $2}' | sort | uniq -c
./automation_scripts/check_failed_jobs.sh -j 30304234 -r Chenies -s 20150101 -c ./config/chenies_cvp_watford_save_to_gws.cfg -d 
## seems to work ok
# we get this 20150212: KeyError: 'Unable to synchronously open object (component not found)'

#### run a 1km CVP for RR
./automation_scripts/RunVP.sh -r Chenies -s 20140101 -e 20260421 -c ./config/chenies_cvp_harpenden_1km_save_to_gws.cfg
sacct -j 30313431 --format=JobID,State --noheader | grep -E "^[0-9]+_[0-9]+[[:space:]]" | awk '{print $2}' | sort | uniq -c



## broken file
source activate DRUID_VP && python -c "
import h5py
f = h5py.File('/gws/ssde/j25a/ncas_radar/vol2/avocet/ukmo-nimrod/raw_h5_data_final/single-site/chenies/2015/20150212_polar_pl_radar05_aggregate.h5', 'r')
print('top level keys:', list(f.keys()))
print('lp keys count:', len(list(f['lp'].keys())))
print('keys under lp/0000:', list(f['lp']['0000'].keys()))
print('keys under lp/0000/dataset1:', list(f['lp']['0000']['dataset1'].keys()))
"
# working file 
source activate DRUID_VP && python -c "
import h5py
f = h5py.File('/gws/ssde/j25a/ncas_radar/vol2/avocet/ukmo-nimrod/raw_h5_data_final/single-site/chenies/2015/20150110_polar_pl_radar05_aggregate.h5', 'r')
print('top level keys:', list(f.keys()))
print('lp keys count:', len(list(f['lp'].keys())))
print('keys under lp/0000:', list(f['lp']['0000'].keys()))
print('keys under lp/0000/dataset1:', list(f['lp']['0000']['dataset1'].keys()))
"

VP_Extraction/Output/30304234/Chenies_30304234_20150110.out