#!/bin/bash

#SBATCH --job-name=modelFit
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=12:00:00
#SBATCH --export=NONE

# Set the amount of time MATLAB is aiming to run for. Speciify as ??:??:??
timeLim="03:00:00"

# INPUT
# $1 directory. All relevant MATLAB scripts should be in the folder 
#    directory/scripts or a subfolder of this directory. Temp folders will be 
#    created here.
# $2 file name of the job to run
# $3 Are we starting a new fit or resuming and old one ("0" or "1")

umask 077 
set -e
module load matlab/2018b

jobDirectory="$1"
filename="$2"
resuming="$3"

TMP="$TMPDIR"
echo 'System temp dirs:'
echo "$TMPDIR"
echo "$TMP"

export MATLAB_PREFDIR=$TMPDIR/.matlab/R2018b/
mkdir $TMPDIR/.matlab
cp -r $HOME/.matlab/R2018b $TMPDIR/.matlab


cat<<EOF | matlab -nodisplay -nosplash

tmpFolder = fullfile("$TMPDIR", 'parallelJobs');
disp('Folder in use for temporary storage of files...')
disp(tmpFolder)
disp('')
mkdir(tmpFolder)

try
    thisClst = parcluster();
    thisClst.JobStorageLocation = tmpFolder;
    parpool(thisClst, [1, 32])
    mT_runOnCluster('$jobDirectory', '$filename', '$resuming', '$timeLim');
catch err
    disp('Quitting early due to error')
    rethrow(err)
end

EOF
