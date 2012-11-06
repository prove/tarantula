#!/bin/sh -xe
cd $AT_HOME
project="$1" 
execution="$2" 
testcase="$3"
steps="$4" 
project=$project execution=$execution test=$testcase steps=$steps bundle exec rspec -e "$testcase" -r ./lib/CustomTarantulaFormatter.rb -f CustomTarantulaFormatter || true
bundle exec rake unblock_test["""$project""","""$execution""","""$testcase"""] 
