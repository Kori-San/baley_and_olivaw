#!/bin/bash

############################################################################
## Olivaw - A Naive AWX Automated Installer ________________/  / May 2022 ##
## └─(v.0.9a)                              / By Aymen Ezzayer / Kori-San  ##
############################################################################

##############
# Init

# [Settings] - Can be changed
awx_root_dir="$HOME"
# ↳ Root Directory of AWX - By default it's "$HOME"
#   Need to be an absolute path e.g "~/projects/get_git_cloned"
awx_clone_dir="/awx" 
# ↳ Name of AWX Cloned Repo - By default it's "/awx" 
#   Need to be a relative path from above e.g "/my_awx"
awxdb_root_dir="$HOME"
# ↳ Root Directory the DB - By default it's "$HOME"
#   Need to be an absolute path e.g "~/projects/get_git_cloned"
awxdb_dir="/awx_db"
# ↳ Name of AWX's DB dir - By default it's "/awx_db"
#   Need to be a relative path from above e.g "/my_awx_db"
awx_version="20.0.0" 
# ↳ AWX Version to Clone - Last & Most Stable release of official repo is "21.0.0"
awx_git="https://github.com/ansible/awx.git"
# ↳ AWX Version git - Official repo is "https://github.com/ansible/awx.git"
http="80"
# ↳ HTTP Port - Default is 8013
https="443"
# ↳ HTTPS Port - Default is 8043
waiting_interval="6"
# ↳ Seconds to wait between Steps - At least 5 Seconds recommended
main_docker="tools_awx_1"
# ↳ Name of main docker - Default is tools_awx_1

# [Vars] - You rather not touch it
working_dir="$(pwd)"
# ↳ Saving the current directory in a variable.
awx_path="${awx_root_dir}${awx_clone_dir}"
# ↳ It's a variable that contains the path of the cloned repo.
awxdb_path="${awxdb_root_dir}${awxdb_dir}"
# ↳ It's a variable that contains the path of the database linked to the cloned repo.
ps_filter="label=com.docker.compose.project.working_dir=${awx_path}/tools/docker-compose/_sources"
# ↳ It's a variable that contains the label of the docker-compose project.
docker_compose_path="${awx_path}/tools/docker-compose/ansible/roles/sources/templates/docker-compose.yml.j2"
# ↳ It's a variable that contains the path of the docker-compose.yml.j2 file.
docker_volume_settings="\n    driver_opts:\n      type: 'none'\n      o: 'bind'\n      device: "
# ↳ It's a variable that contains the settings of the docker volume.

##############
# Functions
 
# It's a function that checks if a package is installed or not.
pkg_check(){
    if dpkg -s "${1}" 1> /dev/null ; then
        echo -e " ~ '$ ${1}' found, skipping install...\n"
    else
        echo -e " ~ '$ ${1}' not found, installing ${1}...\n"
        apt-get install -q -y "${1}" 1> /dev/null
    fi
}

# It's a function that checks if a directory exists or not.
dir_check(){
    if [ -d ${1} ]; then
        printf " ~ 📂 Directory '%s' was found\n\n" "${1}"
        rm -fr ${1} && printf " ~ 📂 Directory '%s' was succesfully removed\n\n" "${1}"
        return 0
    fi
    printf " ~ 📂 Directory '%s' was not found\n\n" "${1}"
}

# It's a function that checks if a docker volume exists or not.
volume_check(){
    if [[ $(docker volume ls | grep "${1}") ]]; then
        printf " ~ 🚢 Docker Volume '%s' was found\n\n" "${1}"
        docker volume rm "${1}" && printf " ~ 🚢 Docker Volume '%s' was succesfully removed\n\n" "${1}"
        return 0
    fi
    printf " ~ 🚢 Docker Volume '%s' was not found\n\n" "${1}"
}

# It's a function that waits for a given time.
waiting(){
    if [ "${#}" -ne "1" ]; then
        printf "⛔ Ain't wainting\n"
        exit 1;
    fi
    wtime="${1}" # Wait Time
    for i in $(seq "1" "${wtime}"); do
        if [ "$(( i % 2))" -eq "0" ]; then
            printf " ~ ⌛ Waiting %s second(s)     \r" "$(( wtime - i ))" # Whitespaces to avoid bugged display
        else
            printf " ~ ⏳ Waiting %s second(s)     \r" "$(( wtime - i ))" # Whitespaces to avoid bugged display
        fi
        sleep 1
    done
    printf "\n\n"
    return 0
}

##############
# Main

# -> It's stopping all the dockers related to the awx project.
echo -e "\n> 📦 Stopping AWX-Related Dockers\n"
docker kill $(docker ps --filter "${ps_filter}" -q)
docker system prune -af
docker volume prune -f

# -> It's updating the package database.
echo -e "\n> 📦 Checking Dependencies PKG\n"
waiting "${waiting_interval}"
apt-get update > /dev/null

# -> It's checking if the packages are installed or not.
waiting "${waiting_interval}"
pkgs=("python3.9" "python3-pip" "docker-compose" "docker.io" "ansible" "openssl" "pass" "gnupg2" "gzip" "conntrack")
for package in ${pkgs[@]}; do
    pkg_check "${package}"
done

# -> It's upgrading the packages.
echo -e "> 📦 Upgrading Dependencies PKG\n"
waiting "${waiting_interval}"
apt-get upgrade -y > /dev/null

# -> It's cloning the AWX repo.
echo -e "> 📥 Cloning version ${awx_version} from ${awx_git}\n"
waiting "${waiting_interval}"
dir_check "${awx_path}"
git clone -b "${awx_version}" "${awx_git}" "${awx_path}" || exit 1

# -> It's changing the ports of the docker-compose.yml.j2 file.
echo -e "\n> 🧭 Changing Ports 8013 -> ${http} & 8043 -> ${https}\n"
waiting "${waiting_interval}"
sed -i -e "s/[0-9]*:8013/${http}:8013/g" "${docker_compose_path}" 
sed -i -e "s/[0-9]*:8043/${https}:8043/g" "${docker_compose_path}" 

# -> It's creating the database directory and changing the database's path.
echo -e "\n> 📂 Creating Database directory and changing Database's path\n"
dir_check "${awxdb_path}"
mkdir "${awxdb_path}"
mkdir "${awxdb_path}/postgre"
mkdir "${awxdb_path}/redis"

# -> Making PostgreDB Volume persistent in docker-compose file.
dbname="tools_awx_db"
volume_check "tools_awx_db"
sed -i -e "s@name: ${dbname}@name: ${dbname}${docker_volume_settings}'${awxdb_path}/postgre'@g" "${docker_compose_path}"

# -> Making Redis Volume persistent in docker-compose file.
dbname="tools_redis_socket_{{ container_postfix }}"
volume_check "tools_redis_socket_1"
sed -i -e "s@name: ${dbname}@name: ${dbname}${docker_volume_settings}'${awxdb_path}/redis'@g" "${docker_compose_path}"

# -> It's going into the cloned repo directory.
echo -e "> 🛬 Going into ${awx_path} folder"
cd "${awx_path}" || exit 1

# -> It's building the docker images.
echo -e "\n> 🧱 Building AWX and Ansible Receptor Docker Images\n"
waiting "${waiting_interval}"
make "docker-compose-build" || exit 1

# -> It's deploying the docker-compose environment.
echo -e "\n> 🚀 Deploying docker-compose environment\n"
waiting "${waiting_interval}"
make "docker-compose" COMPOSE_UP_OPTS="-d" || exit 1

# -> It's a fix for a bug that install the wrong version of "markupsafe".
echo -e " \n> 🔧 Fixing markupsafe version\n"
waiting "${waiting_interval}"
docker exec "${main_docker}" pip uninstall -y 'markupsafe'
docker exec "${main_docker}" pip install -y 'markupsafe'=='2.0.1'

# -> It's re-deploying the docker-compose environment.
echo -e "\n> 🚀 Re-Deploying\n"
waiting "${waiting_interval}"
docker stop $(docker ps --filter ${ps_filter} -q)
make "docker-compose" COMPOSE_UP_OPTS="-d" || exit 1

# -> It's cleaning the UI and creating it again.
echo -e "\n> 🖌️ Cleaning and creating UI from ${main_docker}\n"
waiting "${waiting_interval}"
docker exec "${main_docker}" make clean-ui ui-devel

# -> It's going back to the original directory.
echo -e "> 🛬 Going into ${working_dir} folder"
cd "${working_dir}" || exit 1
