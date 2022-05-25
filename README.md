# Baley & Olivaw
Baley and Olivaw are automated scripts for Ansible's AWX.

## Baley
- Baley help the user get information and fix issues | ```$ baley [command] [args...]``` :
    - bash [OPTIONNAL DOCKER] - Begin a bash session on ${main_docker} or given argument
    - build-ui - Build / Rebuild AWX Ui
    - deploy - Deploy or Re-Deploy AWX Cluster
    - destroy - Destroy every trace of AWX-Related Docker or Volumes
    - edit [ls] - Edit docker-compose.yml.j2 while creating a backup file or list backup files
    - fix (issue) - Apply an automated fix for a know issue
        - issue==Nginx ~ Fix Unreachable Web UI caused by nginx service not launching
        - issue==MarkupSafe ~ Fix Web UI being reachable but not usable even after build
    - help - Display help without error
    - ls - Display list of awx-related running dockers
    - kill [OPTIONNAL DOCKER] - Kill gracefully all AWX-related docker or given argument
    - logs [OPTIONNAL DOCKER] - Display logs of ${main_docker} or given argument
    - network - Display network information about AWX cluster
    - ports (http/https=NUMBER) - Display network information about AWX cluster

## Olivaw
- Olivaw automate all process of AWX | ```$ olivaw``` :
    - Update & install pkgs : __python3.9, / python3-pip / docker-compose / docker.io / ansible / openssl / pass / gnupg2 / gzip / conntrack__
    - Clone and install specific AWX version
    - Change HTTPS / HTTP ports
    - Create clean Database directory
    - Build Docker Images
    - Deploy
    - Fix know issues
    - Create UI
