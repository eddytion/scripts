#!/usr/bin/sh

cat > /etc/motd << _EOF_
#      #                                                                         
#     # #   #    # #####  ####  #    #   ##   ##### #  ####  #    #              
#    #   #  #    #   #   #    # ##  ##  #  #    #   # #    # ##   #              
#   #     # #    #   #   #    # # ## # #    #   #   # #    # # #  #              
#   ####### #    #   #   #    # #    # ######   #   # #    # #  # #              
#   #     # #    #   #   #    # #    # #    #   #   # #    # #   ##              
#   #     #  ####    #    ####  #    # #    #   #   #  ####  #    #              
#                                                                                
#   ######                                                                       
#   #     # ###### #    # ###### #       ####  #####  #    # ###### #    # ##### 
#   #     # #      #    # #      #      #    # #    # ##  ## #      ##   #   #   
#   #     # #####  #    # #####  #      #    # #    # # ## # #####  # #  #   #   
#   #     # #      #    # #      #      #    # #####  #    # #      #  # #   #   
#   #     # #       #  #  #      #      #    # #      #    # #      #   ##   #   
#   ######  ######   ##   ###### ######  ####  #      #    # ###### #    #   #   
#                                                                                


_EOF_

CPUTIME=$(ps -eo pcpu | awk 'NR>1' | awk '{tot=tot+$1} END {print tot}')
CPUCORES=$(cat /proc/cpuinfo | grep -c processor)
UP=$(echo `uptime` | awk '{ print $3 " " $4 }')
echo "
System Status
Updated: `date`

- Server Name               = `hostname`
- Public IP                 = `dig +short $(hostname) | tail -1`
- OS Version                = `cat /etc/redhat-release`
- Load Averages             = `cat /proc/loadavg`
- System Uptime             = `echo $UP`
- Platform Data             = `uname -orpi | awk {'print $2'}`
- CPU Usage (average)       = `echo $CPUTIME / $CPUCORES | bc`%
- Memory free (real)        = `free -m | head -n 2 | tail -n 1 | awk {'print $4'}` Mb
- Swap in use               = `free -m | tail -n 1 | awk {'print $3'}` Mb
- Disk Space Used           = `df -h / | awk '{ a = $4 } END { print a }'`
" >> /etc/motd
