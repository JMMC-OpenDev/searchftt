#!/bin/bash

for cmdfile in cmds/*.sh
do
  TEST=$(basename $cmdfile .sh)
  echo "Testing $TEST ..."
  REFFILE=refs/$TEST.ref
  OUTFILE=outs/$TEST.out
  ERRFILE=outs/$TEST.err
  $cmdfile > $OUTFILE
  if diff -q $REFFILE $OUTFILE
  then
      echo "- test $TEST SUCCEEDED"
  else
      echo "- test $TEST FAILED"
  fi
done
