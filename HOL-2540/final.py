# final.py - version v1.8 - 4-February 2025
import sys
import lsfunctions as lsf
import os
import shutil
import datetime
import requests
import logging
import subprocess
from pathlib import Path

# default logging level is WARNING (other levels are DEBUG, INFO, ERROR and CRITICAL)
logging.basicConfig(level=logging.DEBUG)

# read the /hol/config.ini
lsf.init(router=False)

color = 'red'
if len(sys.argv) > 1:
    lsf.start_time = datetime.datetime.now() - datetime.timedelta(seconds=int(sys.argv[1]))
    if sys.argv[2] == "True":
        lsf.labcheck = True
        color = 'green'
        lsf.write_output(f'{sys.argv[0]}: labcheck is {lsf.labcheck}')
    else:
        lsf.labcheck = False

lsf.write_output(f'Running {sys.argv[0]}')
if lsf.labcheck == False:
    lsf.write_vpodprogress('Final Checks', 'GOOD-8', color=color)

# add any code you want to run at the end of the startup before final "Ready"
#lsf.write_output("This is final.py output")

if not lsf.labcheck:
    try:
        r = subprocess.run(["/usr/bin/sshpass -p '*****' ssh -o StrictHostKeyChecking=no admin@nsx-mgmt.vcf2.sddc.lab 'clear user HOLFinance-ProjectAdmin password-expiration'"], 
            capture_output=True, text=True, check=True, shell=True)
        lsf.write_output(r)
    except Exception as e:
        lsf.write_output(e)
        try:
            lsf.write_output(e.stdout)
            lsf.write_output(e.stderr)
        except:
            pass  
        lsf.write_output('NSX HOLFinance-ProjectAdmin password change failed')  
    try:
        r = subprocess.run(["/usr/bin/sshpass -p '*****' ssh -o StrictHostKeyChecking=no admin@nsx-mgmt.vcf2.sddc.lab 'clear user RetailApp-VIAdmin password-expiration'"], 
            capture_output=True, text=True, check=True, shell=True)
        lsf.write_output(r)
    except Exception as e:
        lsf.write_output(e)
        try:
            lsf.write_output(e.stdout)
            lsf.write_output(e.stderr)
        except:
            pass  
        lsf.write_output('NSX RetailApp-VIAdmin password change failed') 

    lsf.write_output('Attempting to redeploy the HOL-1-IX-I1 appliance. This could take up to 10 minutes')
    command = "Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCeip $false -ProxyPolicy NoProxy -Scope User -Confirm:$false | Out-Null"
    subprocess.run(["pwsh","-Command",command])
    p = subprocess.run(["pwsh","/vpodrepo/2025-labs/2540/redeploy_appliance.ps1"],capture_output=True, text=True)
    response = p.stdout.rstrip("\r\n")
    if "SUCCESS" in response:
        lsf.write_output('Successfully redeployed the HOL-1-IX-I1 appliance')
        lsf.write_output(p.stdout)
    else:
        lsf.write_output('Failed to redeploy HOL-1-IX-I1 appliance')
        lsf.write_output(p.stdout)

# fail like this
#lsf.labfail('FINAL ISSUE')
#exit(1)

lsf.write_output('Finished Final Checks')
lsf.write_vpodprogress('Finished Final Checks', 'GOOD-9', color=color)
