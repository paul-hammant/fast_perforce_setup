#!/bin/sh

PID=$(ps aux | grep p4d | grep 1666 | tr -s ' ' | cut -d' ' -f2)
kill $PID