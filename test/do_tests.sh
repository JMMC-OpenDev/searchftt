#!/bin/bash

mkdir outs

for cmdfile in cmds/*.sh
do
  TEST=$(basename $cmdfile .sh)
  echo "Testing $TEST ..."
  REFFILE=refs/$TEST.out
  OUTFILE=outs/$TEST.out
  ERRFILE=outs/$TEST.err
  $cmdfile > $OUTFILE 2> $ERRFILE
  if diff -q $REFFILE $OUTFILE
  then
      echo "- test $TEST SUCCEEDED"
  else
      echo "- test $TEST FAILED"
  fi
done

mv -v outs outs.$(date -Is)
