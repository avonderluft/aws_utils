#!/usr/bin/env bash

asg_name=$1
rake asg:refresh[$asg_name]
sleep 1800
rake asg[$asg_name]
