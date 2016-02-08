#!/bin/bash

CONFIGFILE=bgp-konzentrator.conf
[ -r ${CONFIGFILE} ] && . ${CONFIGFILE}

function myread {
	local prompt=$1
	local default=$2
	read -p "${prompt} (${default}): " value
	echo $(sed 's/\//\\\\\//g' <<< ${value:-${default}})
}

echo "========================================="
echo "Konfigurationshelfer für BGP-Konzentrator"
echo "========================================="

echo -e "\n=== Allgemeine Parameter:"

## @@FFRL_AS_NUMBER@@
echo -en "\t" 
ffrl_as_number=$(myread "AS Nummer vom FF-RL" "${FFRL_AS_NUMBER:-201701}")

## @@MY_AS_NUMBER@@
echo -en "\t" 
my_as_number=$(myread "Eigene AS Nummer" "${MY_AS_NUMBER}")

## @@MY_FFRL_EXIT_IPV4@@
echo -en "\t" 
my_ffrl_exit_ipv4=$(myread "Zugewiesene FFRL-IPV4-Exit-Adresse" "${MY_FFRL_EXIT_IPV4}")

# @@MY_PUBLIC_IPV4@@
# TODO: Adresse automatisch ermitteln
echo -en "\t" 
my_public_ipv4=$(myread "Eigene öffentliche IPV4 Adresse" "${MY_PUBLIC_IPV4}")


TUNNELENDPOINTS="BER_A BER_B DUS_A DUS_B"

for bb_endpoint in ${TUNNELENDPOINTS}; do 
	echo -e "\n=== Konfiguration für GRE-Tunnel nach ${bb_endpoint}:"
	echo -en "\t" 

	unset value
	bar=${bb_endpoint}_GRE_BB_IPV4
	eval $bar=\$${bar}
	value=$(eval echo \$${bar})
	value=$(myread "IPV4 Adresse für Tunnelendpunkt auf Backbone-Server" "${value}")
	eval $bar=$value

	echo -en "\t" 
	unset value
	bar=${bb_endpoint}_GRE_MY_IPV4
	eval $bar=\$${bar}
	value=$(eval echo \$${bar})
	value=$(myread "IPV4 Adresse für Tunnelendpunk auf Konzentrator" "${value}") 
	eval $bar=$value

	echo -en "\t" 
	unset value
	bar=${bb_endpoint}_GRE_MY_IPV6
	eval $bar=\$${bar}
	value=$(eval echo \$${bar})
	value=$(myread "IPV6 Adresse auf Konzentrator" "${value}") 
	eval $bar=$value
done

echo -e "\n=== Ausgaben"
for f in bird.conf interfaces-bgp-konzentrator; do
	sed "s/@@FFRL_AS_NUMBER@@/${ffrl_as_number}/g;\
	       s/@@MY_AS_NUMBER@@/${my_as_number}/g; \
	       s/@@MY_FFRL_EXIT_IPV4@@/${my_ffrl_exit_ipv4}/g; \
	       s/@@MY_PUBLIC_IPV4@@/${my_public_ipv4}/g; \
	       s/@@BER_A_GRE_BB_IPV4@@/${BER_A_GRE_BB_IPV4}/g; \
	       s/@@BER_B_GRE_BB_IPV4@@/${BER_B_GRE_BB_IPV4}/g; \
	       s/@@DUS_A_GRE_BB_IPV4@@/${DUS_A_GRE_BB_IPV4}/g; \
	       s/@@DUS_B_GRE_BB_IPV4@@/${DUS_B_GRE_BB_IPV4}/g; \
	       s/@@BER_A_GRE_MY_IPV4@@/${BER_A_GRE_MY_IPV4}/g; \
	       s/@@BER_B_GRE_MY_IPV4@@/${BER_B_GRE_MY_IPV4}/g; \
	       s/@@DUS_A_GRE_MY_IPV4@@/${DUS_A_GRE_MY_IPV4}/g; \
	       s/@@DUS_B_GRE_MY_IPV4@@/${DUS_B_GRE_MY_IPV4}/g; \
	       s/@@BER_A_GRE_MY_IPV6@@/${BER_A_GRE_MY_IPV6}/g; \
	       s/@@BER_B_GRE_MY_IPV6@@/${BER_B_GRE_MY_IPV6}/g; \
	       s/@@DUS_A_GRE_MY_IPV6@@/${DUS_A_GRE_MY_IPV6}/g; \
	       s/@@DUS_B_GRE_MY_IPV6@@/${DUS_B_GRE_MY_IPV6}/g; \
	    "< ${f}.template > ${f} 
	echo -e "\tKonfigurationen geschrieben nach: ${f}"
done
