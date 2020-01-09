#!/bin/sh

tail -1 AppDir/.git/logs/refs/remotes/origin/master | awk {'{print $2}'} | cut -b 1-7

