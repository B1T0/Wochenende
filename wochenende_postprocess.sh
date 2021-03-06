#!/bin/bash
# Colin Davenport, Sophia Poertner

version="0.14, Feb 2021"
#0.14 - add haybaler env and use this
#0.13 - copy filled directory plots and reporting into current directory, if missing
#0.12 - make prerequisite docs clearer
#0.11 - add variable for random 
#0.10 - initial commits


echo "INFO: Postprocess Wochenende BAM and bam.txt files for plotting and reporting" 
echo "INFO: Version: " $version
echo "INFO: Remember to run this using the haybaler conda environment if available - we attempt to load this in the script"
echo "INFO: WORK IN PROGRESS ! . May not completely work for all steps, still useful."
echo "INFO:  ####### "
echo "INFO:  Usage: Make sure the directories plots and reporting exist and are filled"
echo "INFO:  eg. run get_wochenende.sh to get the relevant files"
echo "INFO:  ####### "
echo "INFO:  Runs following stages"
echo "INFO:  - sambamba depth"
echo "INFO:  - Wochenende reporting"
echo "INFO:  - Haybaler"
echo "INFO:  - Wochenende plot"
echo "INFO:  - cleanup directories "


# Setup conda and directories
haybaler_dir=/mnt/ngsnfs/tools/dev/haybaler/
wochenende_dir=/mnt/ngsnfs/tools/dev/Wochenende/
# Use existing conda env
. /mnt/ngsnfs/tools/miniconda3/etc/profile.d/conda.sh
conda activate wochenende

# Setup sleep duration. Might be useful to set higher for some big projects, where the wait command may fail for some SLURM jobs.
sleeptimer=12
#sleeptimer=120

# Cleanup previous results to a directory with a random name which includes a number, calculated here.
rand_number=$RANDOM

### Check if required directories exist, copy if missing ###
if [ ! -d "reporting" ] 
then
    echo "INFO: Copying directory reporting, as it was missing!" 
    cp -R $wochenende_dir/reporting .
fi
if [ ! -d "plots" ] 
then
    echo "INFO: Copying directory plots, as it was missing!" 
    cp -R $wochenende_dir/plots .
fi

# get current dir containing Wochenende BAM and bam.txt output
bamDir=$(pwd)

echo "INFO: Starting Wochenende_postprocess"
echo "INFO: Current directory" $bamDir
sleep 3

echo "INFO: Started Sambamba depth"
bash runbatch_metagen_awk_filter.sh
wait
bash runbatch_sambamba_depth.sh >/dev/null 2>&1
wait
echo "INFO: Sleeping for " $sleeptimer
sleep $sleeptimer
runbatch_metagen_window_filter.sh >/dev/null 2>&1
wait
echo "INFO: Completed Sambamba depth and filtering"


# Run reporting 
echo "INFO: Started Wochenende reporting"
cd reporting
cp ../*.bam.txt .
bash runbatch_Wochenende_reporting.sh >/dev/null 2>&1
wait
echo "INFO: Sleeping for " $sleeptimer
sleep $sleeptimer
#echo "INFO: Sleeping for " $sleeptimer " * 10"
#sleep $((sleeptimer*10))

echo "INFO: Completed Wochenende reporting"


# Run haybaler
echo "INFO: Start Haybaler"
conda activate haybaler
cp $haybaler_dir/*.sh .
cp $haybaler_dir/*.py .
cp $haybaler_dir/*.R .
#mv output output_$rand_number
bash run_haybaler.sh >/dev/null 2>&1
wait
echo "INFO: Sleeping for " $sleeptimer
sleep $sleeptimer

echo "INFO: Start csv to xlsx conversion"
bash runbatch_csv_to_xlsx.sh >/dev/null 2>&1
wait
echo "INFO: Sleeping for " $sleeptimer
sleep $sleeptimer
echo "INFO: Completed Haybaler"





# Plots
echo "INFO: Started Wochenende plot"
cd $bamDir
cd plots
cp ../*_window.txt . 
cp ../*_window.txt.filt.csv .
bash runbatch_wochenende_plot.sh >/dev/null 2>&1
#wait
echo "INFO: Sleeping for " $sleeptimer
sleep $sleeptimer
cd $bamDir
echo "INFO: Completed Wochenende plot"



echo "INFO: Start cleanup reporting"
cd $bamDir
cd reporting
# create backup, move folders from previous reporting run to a directory
mkdir reporting_$rand_number
mv txt csv xlsx reporting_$rand_number 
# make and fill current folders from this run
mkdir txt csv xlsx
mv *.txt txt
mv *.csv csv
mv *.xlsx xlsx
cd $bamDir
echo "INFO: Completed cleanup reporting"

echo "INFO: ########### Completed Wochenende_postprocess #############"

