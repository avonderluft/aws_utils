#!/usr/bin/env bash

asg_name=$1
rake asg:refresh[$asg_name]
rake asg[$asg_name]
