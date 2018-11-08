Cloudnative-Bash
----------------

You can use this docker container as bash with all you pre installed
tools you need for running this training.

Installes tool:

* AWS-CLi
* kubecli
* KOPS
* HELM
* Python
* Other tools like curl, jq etc.

# Buid docker

Build the docker with to following command:

    docker build -t cloudnative_bash .

For convenience reasons this command is added to the follwoing shell
script:

    ./buildCloudnativeBash.sh

# Useage

To use this bash run the following command in the project folder to
start the bash with your project:

    docker run -it -v ${pwd}:/project -v $HOME/.aws:/root/.aws:ro -v $HOME/.ssh:/root/.ssh:ro -v $HOME/.kube:/root/.kube  cloudnative_bash:latest

This command contains some volume bindings:
*  -v ${pwd}:/project : Bind the current folder as /project folder
   inside the container
*  -v $HOME/.aws:/root/.aws:ro : Bind you AWS credentions read-only to
   the container
*  -v $HOME/.ssh:/root/.ssh:ro : Bind you ssh creadentials read-only to
   the container
*  -v $HOME/.kube:/root/.kube : Bind the .kube folder in which the
   kubernetes config will be stored.

For convenience reasons we although created an shell file (called form
project root):

    ./docker/runCloudnativeBash.sh




