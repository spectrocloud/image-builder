#!/bin/bash

#
# This script is to harden linux OS for Spectro
# Benchmark used - CIS Linux Benchmark
#


root_dir="$( cd "$( dirname $0 )" && pwd )"
echo Root dir $root_dir


##########################################################################
#  Check for exit status and print error msg
##########################################################################
check_error()
{
        status=$1
        msg=$2
        exit_status=$3

        if [[ ${status} -ne 0 ]]; then
                echo -e "\033[31m       - ${msg} \033[0m"
                exit ${exit_status}
        fi

        return 0
}


##########################################################################
#  Update the config files with specified values for hardening
##########################################################################
update_config_files() {
  search_str="$1"
  append_str="$2"
  config_file="$3"

  if [[ ! -f ${config_file} ]]; then
     check_error 1 "File ${config_file} not found"
  fi

  sed -i "s/^\($search_str.*\)$/#\1/"  ${config_file}
  check_error $? "Failed commenting config value $search_str." 1

  echo "$append_str" >> ${config_file}
  check_error $? "Failed appending config value $append_str" 1

  return 0
}


##########################################################################
#  Determine the Operating system
##########################################################################
get_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        OS=Suse
    elif [ -f /etc/centos-release ]; then
        OS='CentOS Linux'
        VER=$(cat /etc/centos-release | sed 's/.*\( [0-9][^ ]\+\) .*/\1/')
    elif [ -f /etc/redhat-release ]; then
        OS='Red Hat Enterprise Linux'
        VER=$(cat /etc/redhat-release | sed 's/.*\( [0-9][^ ]\+\) .*/\1/')
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi

   if [[ $OS =~ 'Red Hat' ]]; then
       OS_FLAVOUR="rhel"
   elif [[ $OS =~ 'CentOS' ]]; then
       OS_FLAVOUR="centos"
   elif [[ $OS =~ 'Ubuntu' ]]; then
       OS_FLAVOUR="ubuntu"
    else
       OS_FLAVOUR="linux"
    fi
}

##########################################################################
#  Upgrade OS packages
##########################################################################
upgrade_packages() {

  if [[ ${OS_FLAVOUR} == "ubuntu" ]]; then
    apt-get update
    apt-get -y upgrade
    check_error $? "Failed upgrading packages" 1
  fi

  if [[ ${OS_FLAVOUR} == "centos" ]]; then
    yum -y update
    check_error $? "Failed upgrading packages" 1
  fi

  if [[ ${OS_FLAVOUR} == "rhel" ]]; then
    yum -y update
    check_error $? "Failed upgrading packages" 1
  fi

  # Placeholder for supporting other linux OS
  if [[ ${OS_FLAVOUR} == "linux" ]]; then
    test 1 -eq 2
    check_error $? "OS not supported" 1
  fi

  return 0

}

##########################################################################
#  Harden Sysctl based parameters
##########################################################################
harden_sysctl() {
  config_file='/etc/sysctl.conf'

  echo "" >> ${config_file}
  #Disabling IP forward related hardening as it is needed for k8s
  # update_config_files 'net.ipv4.ip_forward' 'net.ipv4.ip_forward=0' ${config_file}
  # update_config_files 'net.ipv4.conf.all.forwarding' 'net.ipv4.conf.all.forwarding=0' ${config_file}
  # update_config_files 'net.ipv4.conf.all.mc_forwarding' 'net.ipv4.conf.all.mc_forwarding=0' ${config_file}

  update_config_files 'net.ipv4.conf.all.send_redirects' 'net.ipv4.conf.all.send_redirects=0' ${config_file}
  update_config_files 'net.ipv4.conf.default.send_redirects' 'net.ipv4.conf.default.send_redirects=0' ${config_file}

  update_config_files 'net.ipv4.conf.all.accept_source_route' 'net.ipv4.conf.all.accept_source_route=0' ${config_file}
  update_config_files 'net.ipv4.conf.default.accept_source_route' 'net.ipv4.conf.default.accept_source_route=0' ${config_file}

  update_config_files 'net.ipv4.conf.all.accept_redirects' 'net.ipv4.conf.all.accept_redirects=0' ${config_file}
  update_config_files 'net.ipv4.conf.default.accept_redirects' 'net.ipv4.conf.default.accept_redirects=0' ${config_file}

  update_config_files 'net.ipv4.conf.all.secure_redirects' 'net.ipv4.conf.all.secure_redirects=0' ${config_file}
  update_config_files 'net.ipv4.conf.default.secure_redirects' 'net.ipv4.conf.default.secure_redirects=0' ${config_file}


  update_config_files 'net.ipv4.conf.all.log_martians' 'net.ipv4.conf.all.log_martians=1' ${config_file}
  update_config_files 'net.ipv4.conf.default.log_martians' 'net.ipv4.conf.default.log_martians=1' ${config_file}

  update_config_files 'net.ipv4.icmp_echo_ignore_broadcasts' 'net.ipv4.icmp_echo_ignore_broadcasts=1' ${config_file}
  update_config_files 'net.ipv4.icmp_ignore_bogus_error_responses' 'net.ipv4.icmp_ignore_bogus_error_responses=1' ${config_file}
  update_config_files 'net.ipv4.conf.all.rp_filter' 'net.ipv4.conf.all.rp_filter=1' ${config_file}
  update_config_files 'net.ipv4.conf.default.rp_filter' 'net.ipv4.conf.default.rp_filter=1' ${config_file}
  update_config_files 'net.ipv4.tcp_syncookies' 'net.ipv4.tcp_syncookies=1' ${config_file}
  update_config_files 'kernel.randomize_va_space' 'kernel.randomize_va_space=2' ${config_file}
  update_config_files 'fs.suid_dumpable' 'fs.suid_dumpable=0' ${config_file}


  update_config_files 'net.ipv6.conf.all.accept_redirects' 'net.ipv6.conf.all.accept_redirects=0'  ${config_file}
  update_config_files 'net.ipv6.conf.default.accept_redirects' 'net.ipv6.conf.default.accept_redirects=0'   ${config_file}
  update_config_files 'net.ipv6.conf.all.accept_source_route' 'net.ipv6.conf.all.accept_source_route=0'   ${config_file}
  update_config_files 'net.ipv6.conf.default.accept_source_route' 'net.ipv6.conf.default.accept_source_route=0' ${config_file}
  update_config_files 'net.ipv6.conf.all.accept_ra' 'net.ipv6.conf.all.accept_ra=0'  ${config_file}
  update_config_files 'net.ipv6.conf.default.accept_ra' 'net.ipv6.conf.default.accept_ra=0' ${config_file}

  return 0
}

##function################################################################
#  ssh related hardening
##########################################################################
harden_ssh() {


  config_file='/etc/ssh/sshd_config'

  echo "Harden ssh parameters"
  # Set permissions on ssh config file
  chown root:root ${config_file}
  chmod og-rwx ${config_file}

  echo "" >> ${config_file}
  update_config_files 'Protocol ' 'Protocol 2' ${config_file}
  update_config_files 'LogLevel ' 'LogLevel INFO' ${config_file}
  update_config_files 'PermitEmptyPasswords ' 'PermitEmptyPasswords no' ${config_file}
  update_config_files 'X11Forwarding ' 'X11Forwarding no' ${config_file}
  update_config_files 'IgnoreRhosts ' 'IgnoreRhosts yes' ${config_file}
  update_config_files 'MaxAuthTries' 'MaxAuthTries 5' ${config_file}
  update_config_files 'PermitRootLogin' 'PermitRootLogin no' ${config_file}

  #echo "Set strong ciphers for non-fips based instances"
  # sysctl crypto.fips_enabled
  # if [[ $? -eq 0 ]]; then
  #  fips_stat=$(sysctl crypto.fips_enabled | awk -F '=' '{print $2}')
  #  if [[ ${fips_stat} -ne 1 ]]; then
  #    update_config_files 'Ciphers ' 'Ciphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,arcfour' ${config_file}
  #    update_config_files 'MACs ' 'MACs hmac-sha1,hmac-ripemd160' ${config_file}
  #  fi
  # else
  #  update_config_files 'Ciphers ' 'Ciphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,arcfour' ${config_file}
  #  update_config_files 'MACs ' 'MACs hmac-sha1,hmac-ripemd160' ${config_file}
  #fi

  service sshd restart
  check_error $? "Failed restarting ssh service" 1
  return 0
}


##function################################################################
#  boot up related hardening
##########################################################################
harden_boot() {
  echo "Disable Ctrl + Alt + Del key"
  systemctl mask ctrl-alt-del.target

  grub_conf='/boot/grub2/grub.cfg'
  user_conf='/boot/grub2/user.cfg'

  if [[ -f ${grub_conf} ]]; then
    chown root:root ${grub_conf}
    chmod og-rwx ${grub_conf}
  fi
  if [[ -f ${user_conf} ]]; then
    chown root:root ${user_conf}
    chmod og-rwx ${user_conf}
  fi

  return 0
}

##function################################################################
#  password related hardening
##########################################################################
harden_password_files() {

  chmod 644 /etc/passwd
  chown root:root  /etc/passwd
  chmod 644 /etc/passwd-
  chown root:root  /etc/passwd-
  chmod 000 /etc/shadow
  chown root:root  /etc/shadow
  chmod 000 /etc/shadow-
  chown root:root  /etc/shadow-
  chmod 000 /etc/gshadow
  chown root:root  /etc/gshadow
  chmod 000 /etc/gshadow-
  chown root:root  /etc/gshadow-
  chmod 644 /etc/group
  chown root:root  /etc/group
  chmod 644 /etc/group-
  chown root:root  /etc/group-

  return 0
}


##function################################################################
#  os related hardening
##########################################################################
harden_system() {


  echo "Check if root user has 0 as guid , if not set it"
  root_gid=$(grep '^root:' /etc/passwd | cut -d : -f 4)
  if [[ ${root_gid} -ne 0 ]]; then
    usermod -g 0 root
    check_error $? "Failed changing root guid to 0" 1
  fi

  echo "Error out if there are users with empty password"
  cat /etc/shadow |awk -F : '($2 == "" ){ exit 1}'
  if [[ $? -ne 0 ]]; then
    echo "Users present with empty password. Remove the user or set pasword for the users"
    exit 1
  fi

  echo "Check if any user other than root has uid of 0"
  root_uid_count=$(cat /etc/passwd | awk -F ":"  '($3 == 0){print $3}' | wc -l)
  if [[ ${root_uid_count} -ne 1 ]]; then
    echo "Non root users have UID of 0.Correct the error and retry"
    exit 1
  fi

  echo "Fix permission of all cron files"
  for each in `echo /etc/cron.daily /etc/cron.hourly /etc/cron.d /etc/cron.monthly /etc/cron.weekly /etc/crontab`
  do
    stat -L -c "%a %u %g" ${each} | egrep ".00 0 0"
    if [[ $? -ne 0 ]]; then
      chown root:root ${each}
      chmod og-rwx ${each}
    fi
  done

  echo "Remove cron and at deny files anf have allow files in place"
  rm -f /etc/cron.deny
  rm -f /etc/at.deny
  touch /etc/cron.allow
  touch /etc/at.allow
  chmod og-rwx /etc/cron.allow
  chmod og-rwx /etc/at.allow
  chown root:root /etc/cron.allow
  chown root:root /etc/at.allow

  if [[ ! -f /etc/motd ]]; then
    echo "### Authorized users only. All activity may be monitored and reported ###" > /etc/motd
  fi
  chmod 644 /etc/motd
  chown root:root /etc/motd

  if [[ ! -f /etc/issue ]]; then
    echo "### Authorized users only. All activity may be monitored and reported ###" > /etc/issue
  fi
  chmod 644 /etc/issue
  chown root:root /etc/issue

  if [[ ! -f /etc/issue.net ]]; then
    echo "### Authorized users only. All activity may be monitored and reported ###" > /etc/issue.net
  fi
  chmod 644 /etc/issue.net
  chown root:root /etc/issue.net

  if [[ -f /etc/rsyslog.conf ]]; then
    chmod 0640 /etc/rsyslog.conf
  fi

  return 0
}

##########################################################################
#  Remove unnecessary packages
##########################################################################
remove_services() {

  if [[ ${OS_FLAVOUR} == "ubuntu" ]]; then
    echo "Disable setrouble shoot service if enabled"
    systemctl disable setroubleshoot

    echo "Removing legacy networking services"
    systemctl disable xinetd
    apt-get remove -y openbsd-inetd  rsh-client rsh-redone-client nis talk telnet ldap-utils

    echo "Removing X packages"
    apt-get remove -y xserver-xorg*

  fi

  if [[ ${OS_FLAVOUR} == "centos" ]] || [[ ${OS_FLAVOUR} == "rhel" ]]; then
    echo "Disable setrouble shoot service if enabled"
    chkconfig setroubleshoot off

    echo "Removing legacy networking services"
    yum erase -y inetd xinetd ypserv tftp-server telnet-server rsh-server

    echo "Removing X packages"
    yum groupremove -y "X Window System"
    yum remove -y xorg-x11*
  fi

  # Placeholder for supporting other linux OS
  if [[ ${OS_FLAVOUR} == "linux" ]]; then
    test 1 -eq 2
    check_error $? "OS not supported" 1
  fi

  return 0

}

##########################################################################
#  Block unnecessary modules
##########################################################################
disable_modules() {

  if [[ -d  /etc/modprobe.d ]]; then
	echo "install dccp /bin/true"   > /etc/modprobe.d/CIS.conf
	echo "install sctp /bin/true"  >> /etc/modprobe.d/CIS.conf
	echo "install rds /bin/true"   >> /etc/modprobe.d/CIS.conf
	echo "install tipc /bin/true"  >> /etc/modprobe.d/CIS.conf

	echo "install cramfs /bin/true"   > /etc/modprobe.d/blockfs.conf
	echo "install freevxfs /bin/true" >> /etc/modprobe.d/blockfs.conf
	echo "install jffs2 /bin/true"    >> /etc/modprobe.d/blockfs.conf
	echo "install hfs /bin/true"      >> /etc/modprobe.d/blockfs.conf
	echo "install hfsplus /bin/true"  >> /etc/modprobe.d/blockfs.conf
	echo "install udf /bin/true"      >> /etc/modprobe.d/blockfs.conf
	echo "install usb-storage /bin/true" >> /etc/modprobe.d/blockfs.conf
  fi
  return 0

}



OS_FLAVOUR="linux"
get_os
upgrade_packages
harden_sysctl
harden_ssh
harden_boot
harden_password_files
harden_system
remove_services
disable_modules


exit 0
