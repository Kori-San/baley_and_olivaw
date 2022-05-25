#!/bin/bash

############################################################################
## Baley - An AWX Utilitary Tool            ________________/  / May 2022 ##
## └─(v.0.9a)                              / By Aymen Ezzayer / Kori-San  ##
############################################################################

##############
# Init

# [Settings] - Can be changed
awx_root_dir="$HOME"
# ↳ Root Directory of AWX - By default it's "$HOME"
#   Need to be an absolute path e.g "$HOME/projects/get_git_cloned"
awx_clone_dir="/awx"
# ↳ Name of AWX Cloned Repo - By default it's "/awx"
#   Need to be a relative path from above e.g "/My_AWX"
save="5"
# ↳ Number of backup file - Default is 5 backup file
waiting_interval="6"
# ↳ Seconds to wait between Steps - At least 5 Seconds recommended
main_docker="tools_awx_1"
# ↳ Name of main docker - Default is tools_awx_1
delimiterTF="false"
# ↳ Set to true to have a clear delimitation 

# [Adjusts] - Don't touch
save=$(( save - 1 ))
# ↳ Adjust Save Var
argument=$(echo "${1}" | sed 's@^-*@@g')
# ↳ Remove '-', even trailling ones

# [Vars] - You rather not touch it
working_dir="$(pwd)"
# ↳ Dir at Launch
awx_path="${awx_root_dir}${awx_clone_dir}"
# ↳ Complete AWX Path
docker_compose_folder="${awx_path}/tools/docker-compose/ansible/roles/sources/templates"
# ↳ docker-compose.yml.j2's Folder
docker_compose_path="${docker_compose_folder}/docker-compose.yml.j2"
# ↳ docker-compose.yml.j2 Path
ps_filter="label=com.docker.compose.project.working_dir=${awx_path}/tools/docker-compose/_sources"
# ↳ Filter for docker's commands

##############
# Functions

# -> Prints a line of dashes.
delimiter(){
    echo "──────────────────────────────────────────────"
}

# -> A function that waits for a certain amount of time.
waiting(){
    if [ "${#}" -ne "1" ]; then
        printf "Not wainting\n"
        exit 1;
    fi
    wtime="${1}" # Wait Time
    for i in $(seq "1" "${wtime}"); do
        if [ "$(( i % 2))" -eq "0" ]; then
            printf "Waiting %s second(s)     \r" "$(( wtime - i ))"
        else
            printf "Waiting %s second(s)     \r" "$(( wtime - i ))"
        fi
        sleep 1
    done
    printf "\n\n"
    return 0
}

# -> The func checks if a package is installed. If it is not installed, it will install it.
pkg_check(){
    if dpkg -s "${1}" 1> /dev/null ; then
        echo " ~ '$ ${1}' found, skipping install..."
    else
        echo " ~ '$ ${1}' not found, installing ${1}..."
        apt-get install -q -y "${1}" 1> /dev/null
    fi
}

error_print(){
    >&2 echo "baley:" "${1}"
    Help
    exit 1
}

# -> A function that displays the help menu.
Help(){
    echo "$ baley bash [OPTIONNAL DOCKER]        # Begin a bash session on ${main_docker} or given argument."
    echo "$ baley build-ui                       # Build / Rebuild AWX's User Interface."
    echo "$ baley certs PUBLIC_CERT PRIVATE_KEY  # Copy both arguments as 'nginx.crt' and 'nginx.key' on ${main_docker}."
    echo "$ baley deploy                         # Deploy or Re-Deploy AWX Cluster."
    echo "$ baley destroy                        # Destroy every trace of AWX-Related Docker and Volumes."
    echo "$ baley edit [ls]                      # Edit docker-compose.yml.j2 while creating a backup file or list backup files."
    echo "$ baley fix (issue)                    # Apply an automated fix for a know issue."
    echo "  ├─── nginx                            ~ Fix Unreachable Web UI caused by nginx service not launching."
    echo "  ├─── markupsafe                       ~ Fix Web UI being reachable but not usable even after build."
    echo "  └─── docker_config                    ~ Fix error when loading docker config file."
    echo "$ baley help                           # Display help without error."
    echo "$ baley ls                             # Display list of awx-related running dockers."
    echo "$ baley kill [OPTIONNAL DOCKER]        # Kill gracefully all AWX-related docker or given argument."
    echo "$ baley logs [OPTIONNAL DOCKER]        # Display logs of ${main_docker} or given argument."
    echo "$ baley network                        # Display network information about AWX cluster."
    echo "$ baley pkg                            # Install and Upgrade all dependencies."
    echo "$ baley ports http=NUM | https=NUM     # Change HTTP and/or HTTPS ports."
}

##############
# Main

# -> Checking if the delimiterTF variable is true. If it is, it will run the delimiter function.
if [ ${delimiterTF} == true ]; then delimiter ; fi

# -> Checking if the argument is "bash" and if it is, it will enter the docker container.
if [ "${argument,,}" == "bash" ]; then
    # ~> Checking if the number of arguments is 1 or 2. If it is 1, then it will enter the main docker
    #    container. If it is 2, then it will enter the second argument.
    if [ "${#}" -eq "1" ]; then
        echo "Entering ${main_docker} /bin/bash"
        docker exec -it "${main_docker}" /bin/bash || exit 1
    elif  [ "${#}" -eq "2" ]; then
        echo "Entering ${2} /bin/bash"
        docker exec -it "${2}" /bin/bash || exit 1
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is build-ui and if it is, it is running the command make clean-ui ui-devel
elif [ "${argument,,}" == "build-ui" ]; then
    # ~> Checking if the number of arguments is equal to 1. If it is, it will execute the command "docker exec
    #    make clean-ui ui-devel". If the number of arguments is not equal to 1, it will print
    #    an error message and exit with the error code 1.
    if [ "${#}" -eq "1" ]; then
        echo -e "Cleaning and (re)creating UI from ${main_docker}"
        waiting "${waiting_interval}"
        docker exec "${main_docker}" make clean-ui ui-devel
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is "certs" and if it is, it is copying them to the docker container.
elif [ "${argument,,}" == "certs" ]; then
    # ~> Checking if the number of arguments is equal to 3. If it is, it will check if the
    #    second and third arguments are files. If they are, it will copy the files to the docker container.
    #    If the number of arguments is not equal to 3, it will print an error message.
    if [ "${#}" -eq "3" ]; then
        if [ -f "${2}" ] && [ -f "${3}" ]; then
            docker cp "${2}" "${main_docker}:/etc/nginx/nginx.crt"
            docker cp "${3}" "${main_docker}:/etc/nginx/nginx.key"
            docker exec -it "${2}" nginx -s stop
        else
            error_print "${2} or ${3} have an invalid path"
        fi
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is deploy, if it is, it will deploy the docker-compose environment.
elif [ "${argument,,}" == "deploy" ]; then
    # ~> Checking if the current working directory is the same as the awx_path variable. If it is not, it
    #    will change the directory to the awx_path variable. Then it will check if the number of arguments is
    #    equal to 1. If it is, it will deploy the docker-compose environment.
    if [ "$(pwd)" != "${awx_path}" ]; then
        echo -e "Going into ${awx_path} folder..."
        cd "${awx_path}" || exit 1
        waiting "${waiting_interval}"
    fi
    if [ "${#}" -eq "1" ]; then
        echo -e "Deploying docker-compose environment..."
        waiting "${waiting_interval}"
        make "docker-compose" COMPOSE_UP_OPTS="-d" || exit 1
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is "destroy" and if it is, it will kill all the docker containers and
#    remove all the docker volumes.
elif [ "${argument,,}" == "destroy" ]; then
    # ~> It Will kill all docker containers and remove all AWX-Related Docker or Volumes
    for warnings in $(seq 0 $1); do
        echo "$((3 - warnings)) Security Warning left..."
        echo "Are you SURE you want to continue? (y/n)"
        read -r answer
        if [ "${answer,,}" == "n" ] || [ "${answer,,}" == "no" ]; then
            echo "Aborting..."
            waiting 3
            exit 0
        fi
    done
    docker kill $(docker --filter ${ps_filter} ps -q)
    docker system prune -af
    docker volume prune -f

# -> Checking if the argument is "edit" and if it is, open it in a text editor.
elif [ "${argument,,}" == "edit" ]; then
    # ~> Checking if the docker-compose.yml.j2 file exists. If it does, it is checking if there is one or two arguments.
    #    If there is one argument, it is rotating the backup files and creating a new backup file and open it in a text editor.
    #    If there is two arguments, it is checking if the second argument is "ls". If it is, it is listing the backup files.
    #    If there is more than two arguments, it is printing an error message and exiting.
    if [ ! -f "${docker_compose_path}" ]; then
        >&2 echo "baley: docker-compose.yml.j2 path is invalid"
        exit 1
    else
        if [ "${#}" -eq "1" ]; then
            # - Rotate Backup
            ls -a "${docker_compose_folder}" | grep ".docker-compose" | sort | head -n -"$save" |  sed "s@^@${docker_compose_folder}/@g" | xargs -rd '\n' rm -fr
            # - Create Backup
            cp "${docker_compose_path}" "${docker_compose_folder}/.docker-compose.$(date '+%H:%M:%S-%d_%m_%Y').yml.j2"
            vi "${docker_compose_path}"
        elif  [ "${#}" -eq "2" ]; then
            if [ "${2,,}" == "ls" ]; then
                echo "Most Recent Backup first:"
                ls -a "${docker_compose_folder}" | grep ".docker-compose" | sort -r |  sed "s@^@${docker_compose_folder}/@g"
            else
                error_print "Invalid argument"
            fi
        else
            error_print "Invalid number of arguments"
        fi
    fi

# -> Checking if the argument is "fix" and if it is, it is checking if the second argument is "nginx",
#    "markupsafe" or "config". If it is, it is executing the corresponding command.
elif [ "${argument,,}" == "fix" ]; then
    # ~> Apply an automated fix for a know issue
    if [ "${#}" -ne "2" ]; then
        error_print "Invalid number of arguments"
    elif [ "${2,,}" == "nginx" ]; then
        docker exec "${main_docker}" useradd -s /sbin/nologin -M nginx -g nginx
        docker exec "${main_docker}" nginx
    elif [ "${2,,}" == "markupsafe" ]; then
        docker exec "${main_docker}" pip uninstall -y 'markupsafe'
        docker exec "${main_docker}" pip install 'markupsafe'=='2.0.1'
    elif [ "${2,,}" == "config" ]; then
        chown "$USER":"$USER" /home/"$USER"/.docker -R
        chmod g+rwx "/home/$USER/.docker" -R
    else
        error_print "Invalid argument"
    fi
    printf "\n/!\\ It is recommanded to redeploy !\n\n"

# -> Checking if the argument is equal to "help" in lowercase.
elif [ "${argument,,}" == "help" ]; then
    # ~> Display help without error
    Help

# -> Checking if the argument is "ls" and if it is, it is running a docker command to list all the
#    running dockers.
elif [ "${argument,,}" == "ls" ]; then
    # ~> Display list of awx-related running dockers
    if [ "${#}" -eq "1" ]; then
        docker ps --filter "${ps_filter}" --format "- '{{ .Names }}' \trunning since {{ .RunningFor }}\twith ID: {{ .ID }}" \
        | sed "s/ ago//g"
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is "kill" and if it is, it is stopping the docker containers that match the ps_filter
elif [ "${argument,,}" == "kill" ]; then
    # ~> Checking if there is one or two arguments. If there is one argument, it is stopping all
    #    the docker containers that match the ps_filter. If there is two arguments, it is stopping
    #    the docker container that matches the second argument.
    if [ "${#}" -eq "1" ]; then
        docker stop $(docker ps --filter "${ps_filter}" -q) || exit 1
    elif  [ "${#}" -eq "2" ]; then
        docker stop "${2}" || exit 1
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is logs and if it is, it will run docker logs
elif [ "${argument,,}" == "logs" ]; then
    # ~> Checking if the number of arguments is 1 or 2. If it is 1, it will display the logs of the main
    #    docker. If it is 2, it will display the logs of the second argument.
    if [ "${#}" -eq "1" ]; then
        docker logs -f "${main_docker}" || exit 1
    elif  [ "${#}" -eq "2" ]; then
        docker logs -f "${2}" || exit 1
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is "network" and if it is, it is displaying the network information about
#    the AWX cluster.
elif [ "${argument,,}" == "network" ]; then
    # ~> Checking if the number of arguments is equal to 1. If it is, it will run the docker ps command with
    #    the filter and format options. The sed commands are used to format the output. if the number of arguments
    #    is less than or equal to 1. If it is, it will print an error message and call the help function.
    if [ "${#}" -eq "1" ]; then
        docker ps --filter "${ps_filter}" --format "[{{ .Names }}]\nNetwork: {{ .Networks }}\nPorts:\t - {{ .Ports }}\n" \
        | sed "s/,/\n\t -/g" \
        | sed "s/:::/localhost:/g" \
        | sed "s/->/ -> docker:/g"
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is "pkg" and if it is, it will install and upgrade all dependencies.
elif [ "${argument,,}" == "pkg" ]; then
    # ~> Install and Upgrade all dependencies
    if [ "${#}" -eq "1" ]; then
        echo "Checking dependencies"
        waiting "${waiting_interval}"
        apt-get update -y > /dev/null
        pkgs=("python3.9" "python3-pip" "docker-compose" "docker.io" "ansible" "openssl" "pass" "gnupg2" "gzip" "conntrack")
        for package in ${pkgs[@]}; do
            pkg_check "${package}"
        done
        echo -e "\nUpgrading dependencies"
        waiting "${waiting_interval}"
        apt-get upgrade -y > /dev/null
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is "ports" and if it is, it is changing the ports.
elif [ "${argument,,}" == "ports" ]; then
    # ~> Checking if the argument is "ports" and if it is, it is checking if the number of arguments is less
    #    than or equal to 3. If it is, it is checking if the arguments are valid. If they are, it is changing
    #    the ports.
    if [ "${#}" -le "3" ]; then
        if echo "${2}" | grep -zoP "((http[s]*=[0-9]*)|())" 1> /dev/null && echo "${3}" grep -zoP "((http[s]*=[0-9]*)|())" 1> /dev/null; then
            count=$(echo -e "${2}\n${3}" \
            | sed "s/http=[0-9]*/http/g" \
            | sed "s/https=[0-9]*/https/g" \
            |  uniq -c | sort -r | head -n 1 \
            |  sed "s/ [a-zA-Z]*//g")
            if [ "$count" -eq "1" ]; then
                http=$(echo "${2} ${3}" \
                | grep -zoP -m 1 "(http=[0-9]*)" \
                | tr -d '\0' \
                | sed "s/http=//g")
                https=$(echo "${2} ${3}" \
                | grep -zoP -m 1 "(https=[0-9]*)" \
                | tr -d '\0'\
                | sed "s/https=//g")
                if [ -n "${http}" ]; then
                    echo -e "Changing Port 8013 -> ${http}\n"
                    waiting "${waiting_interval}"
                    sed -i -e "s/[0-9]*:8013/${http}:8013/g" "${docker_compose_path}" || exit 1
                fi
                if [ -n "${https}" ]; then
                    echo -e "Changing Port 8043 -> ${https}\n"
                    waiting "${waiting_interval}"
                    sed -i -e "s/[0-9]*:8043/${https}:8043/g" "${docker_compose_path}" || exit 1
                fi
                echo -e "Done!\nYou should Re-Deploy to apply changes."
            else
                error_print "Don't use same arguments twice"
            fi
        else
            error_print "Invalid arguments"
        fi
    else
        error_print "Invalid number of arguments"
    fi

# -> Checking if the argument is not recognized
else
    # ~> Checking if the user has entered any arguments. If not, it will display the help message with an
    #    error.
    if [ "${#}" -eq "0" ]; then
        error_print "USAGE: $ baley COMMAND [OPTIONNAL ARGS]"
    else
        error_print "Invalid arguments"
    fi
fi

# -> Checking if the current working directory is the same as the working_dir variable. If it is not, it
#    will change the directory to the working_dir variable.
if [ "$(pwd)" != "${working_dir}" ]; then
    echo -e "Going into ${working_dir} folder"
    cd "${working_dir}" || exit 1
fi
exit 0
