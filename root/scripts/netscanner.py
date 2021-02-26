#!/usr/bin/python
import os,re,subprocess


logdir = '/root/netLogs'
for dir in ['by-ip','by-mac','by-alias']:
    if not os.path.exists(logdir+'/'+dir):
        os.makedirs(logdir+'/'+dir)


aliasDict = {}
aliasFile = '/root/lib/netscanner.cfg'
child  = subprocess.Popen(['cat',aliasFile], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
aliasOutput = child.communicate()[0].rstrip().split('\n')
aliasOutput = filter(re.compile(r'(?!^\s*$)').search,aliasOutput)
aliasOutput = filter(re.compile(r'(?!^\s#)' ).search,aliasOutput)
for line in aliasOutput:
    mac,alias = re.split('\s+',line)
    aliasDict[mac] = alias


def scan():
    child  = subprocess.Popen(['nmap','-n','-sP','192.168.0.1/24'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output = child.communicate()[0].rstrip().split('\n')
    output = filter(re.compile(r'^(?!\s*$)').search,output)
    output = filter(re.compile(r'^(?!Starting Nmap)').search,output)
    output = filter(re.compile(r'^(?!Nmap done)').search,output)
    return output


child      = subprocess.Popen('/usr/bin/date', stdout=subprocess.PIPE, stderr=subprocess.PIPE)
date       = child.communicate()[0].rstrip().split('\n')[0]
output     = scan()
ip         = ''
mac        = ''
log_string = ''


for line in output:
    if re.search(r'^Nmap scan',line):
        ip = line
        ip = re.sub(r'Nmap scan report for ','',ip)
    if re.search(r'^MAC Address',line):
        mac = line
        mac = re.split('\s+',mac)[2]
    if re.search(r'^MAC Address',line):
        if mac in aliasDict:
            alias = aliasDict[mac]
        else:
            alias = ''
        logstring = date+'  '+ip+'  '+mac+'  '+alias
        if ip:
            cmd   = '/usr/bin/echo '+logstring+' >> '+logdir+'/by-ip/'+ip
            child = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
        if mac:
            cmd   = '/usr/bin/echo '+logstring+' >> '+logdir+'/by-mac/'+mac
            child = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
        if alias:
            cmd   = '/usr/bin/echo '+logstring+' >> '+logdir+'/by-alias/'+alias
            child = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
            ip    = ''
            mac   = ''
            alias = ''
