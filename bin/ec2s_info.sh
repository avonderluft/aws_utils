#!/usr/bin/env bash

rake ec2s:table cache=no quiet=yes
rake ec2s quiet=yes
