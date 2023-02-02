It is important to retrieve gnb conf files tested from the CI from 
https://gitlab.eurecom.fr/oai/openairinterface5g/-/tree/develop/ci-scripts/conf_files

Once new conf files are updated, you will need to update the gnb
docker images to use with
-- always use the same tag for both gnb image and conf file...

Example:
 - wget https://gitlab.eurecom.fr/oai/openairinterface5g/-/raw/develop/ci-scripts/conf_files/gnb.band78.sa.fr1.106PRB.2x2.usrpn310.conf?inline=false
 - mv gnb.band78.sa.fr1.106PRB.2x2.usrpn310.conf?inline=false gnb.band78.sa.fr1.106PRB.2x2.usrpn310.conf

The scripts will then automatically apply required changes for SophiaNode/R2lab environment, e.g., NSSAI sd and sdr_addrs parameters.
 - NSSAI sd info to be added
 - sdr_addrs to be added

Those config files correspond to a specific version of oai-gnb docker image.
So, make sure to recompile and push the corresponding docker image on dockerhub:
  - https://hub.docker.com/r/r2labuser/oai-gnb/tags
  - https://hub.docker.com/r/r2labuser/oai-gnb-aw2s/tags
