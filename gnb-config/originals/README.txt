To update gnb conf files from
https://gitlab.eurecom.fr/oai/openairinterface5g/-/tree/develop/targets/PROJECTS/GENERIC-NR-5GC/CONF

First retrieve the gnb.conf than update the gnb docker image to use -- latest develop version for both gnb image and conf file...

Example:
 - wget https://gitlab.eurecom.fr/oai/openairinterface5g/-/raw/develop/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.2x2.usrpn300.conf?inline=false
 - mv gnb.sa.band78.fr1.106PRB.2x2.usrpn300.conf?inline=false gnb.sa.band78.fr1.106PRB.2x2.usrpn300.conf

The scripts will then automatically apply required changes for SophiaNode/R2lab environment, e.g., NSSAI sd and sdr_addrs parameters.
 - NSSAI sd info to be added
 - sdr_addrs to be added

Those config files correspond to a specific version of oai-gnb docker image.
So, make sure to recompile and push the corresponding docker image on dockerhub:
  - https://hub.docker.com/r/r2labuser/oai-gnb/tags
  - https://hub.docker.com/r/r2labuser/oai-gnb-aw2s/tags
