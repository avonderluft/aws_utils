#!/usr/bin/env bash

rake users:table quiet=yes cache=no
rake users
