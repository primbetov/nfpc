#!/bin/bash
# Begin /etc/dhcpd/update.sh

# Variables
  KRB5CC="/tmp/krb5cc_0"
  KEYTAB="/etc/dhcp/dhcpd.keytab"
DOMAIN="nfpc.lan"
  REALM="NFPC.LAN"
  PRINCIPAL="administrator@${REALM}"

USERCRED="administrator%le660YBM"
NAMESERVER=10.90.15.3
#"dc1.${DOMAIN}"
ZONE="${DOMAIN}"

SAMBATOOL="/usr/local/bin/samba-tool"
#`which samba-tool`
ACTION=$1
IP=$2
HNAME=$3
  DATA=$@

OCT1=$(echo $IP | cut -d . -f 1)
OCT2=$(echo $IP | cut -d . -f 2)
OCT3=$(echo $IP | cut -d . -f 3)
OCT4=$(echo $IP | cut -d . -f 4)
RZONE="$OCT3.$OCT2.$OCT1.in-addr.arpa"

echo `date -R` $DATA >>/var/log/dhcp/lease.log


add_host(){
  logger -s -p daemon.info -t dhcpd Adding A record for host $HNAME with IP $IP to zone $ZONE on server $NAMESERVER
  $SAMBATOOL dns add $NAMESERVER $ZONE $HNAME A $IP -U$USERCRED
  echo "samba-tool dns add $NAMESERVER $ZONE $HNAME A $IP -k yes"
}

delete_host(){
  logger -s -p daemon.info -t dhcpd Removing A record for host $HNAME with IP $IP from zone $ZONE on server $NAMESERVER
  $SAMBATOOL dns delete $NAMESERVER $ZONE $HNAME A $IP -U$USERCRED
  echo "samba-tool dns delete $NAMESERVER $ZONE $HNAME A $IP -k yes"
}

update_host(){
  logger -s -p daemon.info -t dhcpd Removing A record for host $HNAME with IP $CURIP from zone $ZONE on server $NAMESERVER
  $SAMBATOOL dns delete $NAMESERVER $ZONE $HNAME A $CURIP -U$USERCRED

  echo "samba-tool dns delete $NAMESERVER $ZONE $HNAME A $CURIP -k yes"

  add_host
}

add_ptr(){
  logger -s -p daemon.info -t dhcpd Adding PTR record $OCT4 with hostname $HNAME to zone $RZONE on server $NAMESERVER
  $SAMBATOOL dns add $NAMESERVER $RZONE $OCT4 PTR $HNAME.$DOMAIN -U$USERCRED
  echo "samba-tool dns add $NAMESERVER $RZONE $OCT4 PTR $HNAME.$DOMAIN -k yes"
}

delete_ptr(){
  logger -s -p daemon.info -t dhcpd Removing PTR record $OCT4 with hostname $HNAME from zone $RZONE on server $NAMESERVER
  $SAMBATOOL dns delete $NAMESERVER $RZONE $OCT4 PTR $HNAME.$DOMAIN -U$USERCRED
  echo "samba-tool dns delete $NAMESERVER $RZONE $OCT4 PTR $HNAME.$DOMAIN -k yes"
}

update_ptr(){
  logger -s -p daemon.info -t dhcpd Removing PTR record $OCT4 with hostname $CURHNAME from zone $RZONE on server $NAMESERVER
  $SAMBATOOL dns delete $NAMESERVER $RZONE $OCT4 PTR $CURHNAME -U$USERCRED
  echo "samba-tool dns delete $NAMESERVER $RZONE $OCT4 PTR $CURHNAME -k yes"
  add_ptr
}



case $ACTION in
    ADD)
#      /usr/local/samba/sbin/samba-dnsupdate.sh -a ADD -i $IP -H $HNAME
#   kerberos_creds
      # проверяем существует ли создаваемое доменное имя
      host -t A $HNAME.$DOMAIN > /dev/null
      if [ "${?}" == 0 ]; then
        # имя существует, переписываем его
        CURIP=$(host -t A $HNAME.$DOMAIN | cut -d " " -f 4 )
        if [[ "$CURIP" != "$IP" ]]; then
          update_host
        fi
      else
        # имя новое, регистрируем
        add_host
      fi

      # создаем обратную запись
      host -t PTR $IP > /dev/null
      if [ "${?}" == 0 ]; then
        CURHNAME=$(host -t PTR $IP | cut -d " " -f 5 | rev | cut -c 2- | rev)
        if [[ "$CURHNAME" != "$HNAME.$DOMAIN" ]]; then
          update_ptr
        fi
      else
        add_ptr
      fi

    ;;
    DEL)
      /usr/local/samba/sbin/samba-dnsupdate.sh -a DEL -i $IP -H $HNAME
    ;;
    TEST)
    
    ;;
    *)
      echo "Error: Invalid action $ACTION" && exit 12
    ;;
esac