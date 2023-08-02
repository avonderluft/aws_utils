#!/usr/bin/env bash

asg_name=$1
rake asg[$asg_name] cache=no
