#!/usr/bin/env bash

asg_name=$1
rake asg:refresh:launch_only[$asg_name]
