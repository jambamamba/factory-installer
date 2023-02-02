#!/bin/bash -xe
set -xe

dockertag="v17"

function parseArgs()
{
   for change in "$@"; do
      name="${change%%=*}"
      value="${change#*=}"
      eval $name="$value"
   done
}


function installDocker()
{
   local docker_installed=$(which docker)
   if [ "$docker_installed" == "" ]; then
   	sudo apt install -y docker.io
      sudo chmod 666 /var/run/docker.sock
      sudo groupadd docker && true
      sudo usermod -aG docker ${USER}
   fi
}

function loadDockerImage()
{
   local docker_loaded=$(docker image ls steno-docker-image:$dockertag| grep "steno-docker-image")
   if [ "$docker_loaded" == "" ]; then
      if [ ! -f "/home/$USER/Downloads/steno-docker-image:$dockertag.tar.gz" ]; then
      	      echo "You do not have latest docker image $dockertag . Will attempt to download it, please wait..."
	      pushd ~/Downloads
	      wget https://10.57.3.4/artifacts/steno-docker-image:$dockertag.tar.gz --no-check-certificate
	      popd
	      if [ ! -f "/home/$USER/Downloads/steno-docker-image:$dockertag.tar.gz" ]; then
	         echo "You need latest steno-docker-image:$dockertag.tar.gz in /home/$USER/Downloads/ , cannot continue."
	         exit -1
	      fi
      fi
      docker load < "/home/$USER/Downloads/steno-docker-image:$dockertag.tar.gz"
   fi
}

function replaceSlashWithHyphen()
{
   parseArgs $@
   if [ "$job_name" != "" ]; then 
      job_name=$(echo $job_name | sed -r 's/\//_/g');
      job_name=$(echo $job_name | sed -r 's/%2F/_/g'); 
   fi
}

function main()
{
   local build=""
   local build_number=""
   local job_name=""
   local current_branch=""
   local artifacts_dir=""
   local project_path=""
   parseArgs $@
   installDocker
   loadDockerImage
   
   local dockerimage="steno-docker-image:$dockertag"
   export DOCKER_HOST=""
   replaceSlashWithHyphen job_name="$job_name"

	local git_user="$(git config --get user.name)"
	if [ "$git_user" == "" ]; then git_user="builder"; fi
	   local git_email="$(git config --get user.email)"
	if [ "$git_email" == "" ]; then git_email="builder@stenograph.com"; fi
	#	   local uid="$(id -u)"
	#	   local gid="$(id -g)"

	 local container_path=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


	 local cmd_run_in_docker="cd $container_path && ./build.sh"
	 

      xhost + && true
      local container_name="jambamamba$job_name$build_number"
      
      local params=(
    --rm 
    #--device=/dev/ttyUSB0
    -e DOCKERUSER=$USER 
    -e USER=$USER
    -e UID=$(id -u) 
    -e GID=$(id -g)
    -e DISPLAY=$DISPLAY
    -e GITUSER="$git_user"
    -e GITEMAIL="$git_email"
    -v /tmp/.X11-unix:/tmp/.X11-unix
    -v $HOME/.Xauthority:/home/dev/.Xauthority
    -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket
    -v /run/user/1000:/run/user/1000
    -v "$project_path:$container_path"
    -v /datadisk:/datadisk
    --name $container_name
    --privileged -v /dev/bus/usb:/dev/bus/usbs
    $dockerimage
    )
    
    
      echo "docker run -it ${params[@]} bash -c \"$cmd_run_in_docker; bash\"" > $container_path/docker-run-cmd
      docker run ${params[@]} bash -c "$cmd_run_in_docker"

}

export DOCKER_HOST=""
main $@
