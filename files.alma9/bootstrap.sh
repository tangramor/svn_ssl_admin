#!/bin/bash

set -e
set -u

# Supervisord default params
SUPERVISOR_PARAMS='-c /etc/supervisord.conf'


# Create directories for supervisor's UNIX socket and logs (which might be missing
# as container might start with /data mounted from another data-container).
if [ ! -d "/home/svnadmin/rep" ];then
    mkdir -p /home/svnadmin/{crond,logs,rep,backup} /home/svnadmin/templete/initStruct/01/{trunk,tags,branches} /run/php-fpm
    # touch /home/svnadmin/sasl/ldap/saslauthd.conf
fi

if [[ -d "/data.template/" ]] && [[ ! -f "/home/svnadmin/lock" ]];then
    /usr/bin/cp -Rf /data.template/* /home/svnadmin/
    # /usr/bin/cp -f /app/templete/database/sqlite/svnadmin.db /home/svnadmin/
    # /usr/bin/cp -f /app/templete/svnserve/* /home/svnadmin/
    # /usr/bin/cp -Rf /app/templete/hooks /home/svnadmin/

    touch /home/svnadmin/lock
fi

chmod -R 711 /home/svnadmin/
chown -R apache:apache /home/svnadmin

# Execute some init scripts if exist
if [ "$(ls /config/init/)" ]; then
  for init in /config/init/*.sh; do
    . $init
  done
fi


# We have TTY, so probably an interactive container...
if test -t 0; then
  # Run supervisord detached...
  supervisord $SUPERVISOR_PARAMS
  
  # Some command(s) has been passed to container? Execute them and exit.
  # No commands provided? Run bash.
  if [[ $@ ]]; then 
    eval $@
  else 
    export PS1='[\u@\h : \w]\$ '
    /bin/bash
  fi

# Detached mode? Run supervisord in foreground, which will stay until container is stopped.
else
  # If some extra params were passed, execute them before.
  # @TODO It is a bit confusing that the passed command runs *before* supervisord, 
  #       while in interactive mode they run *after* supervisor.
  #       Not sure about that, but maybe when any command is passed to container,
  #       it should be executed *always* after supervisord? And when the command ends,
  #       container exits as well.
  if [[ $@ ]]; then 
    eval $@
  fi
  supervisord -n $SUPERVISOR_PARAMS
fi
