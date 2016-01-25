#!/bin/sh
#PBS -l nodes=1:ppn=1
#PBS -l mem=1gb
#PBS -l scratch=1gb

# it suppose the following variables set:
#
#   ID             -- integer idetificating this task's ID
#   EXPID          -- string with unique identifier of the whole experiment
#   EXPPATH_SHORT  -- usually $APPROOT/exp/experiments
# 

# MATLAB Runtime environment
export LD_LIBRARY_PATH=/storage/plzen1/home/bajeluk/bin/mcr/v90/runtime/glnxa64:/storage/plzen1/home/bajeluk/bin/mcr/v90/bin/glnxa64:/storage/plzen1/home/bajeluk/bin/mcr/v90/sys/os/glnxa64:$LD_LIBRARY_PATH

# Load global settings and variables
. $EXPPATH_SHORT/../bash_settings.sh

# this should be set in 'exp/bash_settings.sh'
# DEPLOY_DIR=deploy
# DEPLOY_ARCHIVE=${EXPID}_src.tar

export SCRATCHDIR
export LOGNAME
EXPPATH="$EXPPATH_SHORT/$EXPID"

if [ -z "$EXPID" ] ; then
  echo "Error: EXPID (experiment ID) is not known"; exit 1
fi
if [ -z "$ID" ] ; then
  echo "Error: Task ID number is not known"; exit 1
fi
if [ -z "$EXPPATH_SHORT" ] ; then
  echo "Error: directory with the experiment is not known"; exit 1
fi

# clean up the lock-file(s) on exit
trap "rm -f $EXPPATH/calculating_$ID $EXPPATH/queued_$ID" TERM EXIT

#
# Un-pack the archive with current sources and change dir. to therein
#
DEPLOY_FILE="$EXPPATH_SHORT/../../$DEPLOY_DIR/$DEPLOY_ARCHIVE"
if [ ! -f "$DEPLOY_FILE" ]; then
  echo "Error: archive with current sources does not exist. It should be here:"
  echo "  $DEPLOY_FILE"
  exit 1
else
  # defined in exp/bash_settings.sh: RUNDIR="$SCRATCHDIR/surrogate-cmaes"
  mkdir -p "$RUNDIR"
  cd "$RUNDIR"
  tar -xf "$DEPLOY_FILE"
fi

# cd "$EXPPATH_SHORT/.."
# ulimit -t unlimited

module add matlab

echo "====================="
echo "Compiling..."
lasthome="$HOME"
HOME="$RUNDIR"
make

echo "====================="
echo -n "Current dir:    "; pwd
echo    '$HOME =        ' $HOME
echo    "Will be called:" $MATLAB_BINARY_CALL "$EXPID" "$EXPPATH_SHORT" $ID
echo "====================="

######### CALL #########
#
$MATLAB_BINARY_CALL "$EXPID" "$EXPPATH_SHORT" $ID
#
########################

if [ $? -eq 0 ]; then
  echo `date "+%Y-%m-%d %H:%M:%S"` "  **$EXPID**  ==== FINISHED ===="
  rm -rf $SCRATCHDIR/*
  exit 0
else
  echo `date "+%Y-%m-%d %H:%M:%S"` "  **$EXPID**  ==== ENDED WITH ERROR! ===="
  exit 1
fi