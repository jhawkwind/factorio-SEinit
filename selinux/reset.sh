#!/bin/bash

## This is used for debugging clean-up between debugging sessions.

restorecon -R -v /data/factorio
restorecon -R -v /data/factorio-init
restorecon -R -v /opt/glibc-2.18

cat /var/log/audit/audit.log >> /var/log/audit/audit.log.0
echo "" > /var/log/audit/audit.log

