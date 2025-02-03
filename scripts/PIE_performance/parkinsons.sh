#!/bin/sh

#####Set Scheduler Configuration Directives#####
#Set the name of the job. This will be the first part of the error/output filename.
#$ -N parkinsons

#Set the current working directory as the location for the error and output files.
#(Will show up as .e and .o files)
#$ -cwd

#Send e-mail at beginning/end/suspension of job
#$ -m bes

#####End Set Scheduler Configuration Directives#####
#See the HPC wiki for complete resource information: https://wiki.uiowa.edu/display/hpcdocs/Argon+Cluster
#Select the queue to run in
#$ -q XXX

#Select the number of slots the job will use 
#$ -pe smp 56 

#Indicate that the job requires a GPU
##$ -l gpu=false

#Sets the number of requested GPUs to 1
##$ -l ngpus=1

#Indicate that the job requires a mid-memory (currently 256GB node)
##$ -l mem_384G=true

#Indicate the CPU architecture the job requires
##$ -l cpu_arch=broadwell

#Specify a data center for to run the job in
##$ -l datacenter=LC

#Specify the high speed network fabric required to run the job
##$ -l fabric=omnipath

#####Begin Compute Work#####
module load stack/2021.1
module load r/4.0.5_gcc-9.3.0
Rscript load_functions.R
echo "function load finished"
Rscript parkinsons_load.R
#Parameter Tuning set
count=0
Nrounds=(200)
Lambda1=(0.0001 0.0005 0.001 0.005 0.01 0.1 1 10 100)
Lambda2=(0.001 0.005 0.01 0.05 0.1 0.25 0.5 0.75 1)
Eta=(0.05)
Iteration=(500)


for i in {1,2,3,4,5}
do
for nrounds in ${Nrounds[@]}
do
for lambda1 in ${Lambda1[@]}
do
for lambda2 in ${Lambda2[@]}
do
for eta in ${Eta[@]}
do
for iteration in ${Iteration[@]}
do

((count+=1))
##do parallel functions
name="output_${count}.txt"
##Use CASP Dataset as an example
Rscript parallelCV.R load_parkinsons.RData $i $count $lambda1 $lambda2 $iteration $eta $nrounds parkinsons > $name &

done
done
done
done
done
done

## data_name fold
echo "start summing all outcomes finished"
Rscript parallelFinal.R parkinsons $count parkinsons_full.csv parkinsons_CV.csv

deactivate
