#!/bin/bash

. /home/holuser/.bashrc

#Prepare Console VM with powershell script for 2640-02 Mod1
/bin/bash /vpodrepo/2026-labs/2640/lab-startup/prepare-pwsh.sh | tee -a /lmchol/hol/labstartup.log >> /home/holuser/hol/labstartup.log 2>&1

#Execute the final updates
#/bin/bash /vpodrepo/2026-labs/2670/lab-startup/final-updates.sh | tee -a /lmchol/hol/labstartup.log >> /home/holuser/hol/labstartup.log 2>&1
