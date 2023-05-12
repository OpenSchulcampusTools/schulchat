#!/bin/bash

args=("$@")

if [[ ${args[0]} = 'nexus-5' ]];then
  echo 7
fi
if [[ ${args[0]} = 'nexus-10' ]];then
  echo 5
fi
if [[ ${args[0]} = 'pixel_5' ]];then
  echo 26
fi
if [[ ${args[0]} = '10.1in' ]];then
  echo 52
fi
