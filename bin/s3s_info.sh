#!/usr/bin/env bash

rake s3s:empty:table quiet=yes cache=no
rake s3s:table quiet=yes
rake s3s quiet=yes
