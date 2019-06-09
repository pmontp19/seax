#!/bin/bash

leases=$( grep "^lease" /var/lib/dhcp/dhcpd.leases | sort | grep "10.10.2" | uniq | wc -l )
if [[ $leases -gt 0 ]]; then
  mail -s "Alerta!" entel <<< "Tenim una anomalia a la xarxa DMZ, el servidor DHCP ha repartit una adresa a una maquina."
fi
