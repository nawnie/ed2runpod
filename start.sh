#!/bin/bash
echo "Container Started"
export PYTHONUNBUFFERED=1
echo "Container Started"
echo "conda activate ldm" >> ~/.bashrc
source ~/.bashrc

# This is a workaround specifically for running this image in RunPod.
# Install the openssh service so that SCP can be used to copy files to/from the image.
# This is not an *explicit* test for RunPod, but RunPod sets this environment variable
# if the public key is configured in settings.
# consider exposing a separate env var or another control for this purpose?
if [[ -v "PUBLIC_KEY" ]] && [[ ! -d "${HOME}/.ssh" ]]; then
    apt-get update
    apt-get install -y openssh-server
    pushd $HOME
    mkdir -p .ssh
    echo ${PUBLIC_KEY} > .ssh/authorized_keys
    chmod -R 700 .ssh
    popd
    service ssh start
fi

tensorboard --logdir /workspace/EveryDream2trainer/logs --host 0.0.0.0 &

if [[ $JUPYTER_PASSWORD ]]
then
    cd /
    jupyter lab --allow-root --no-browser --port=8888 --ip=* --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' --ServerApp.token=$JUPYTER_PASSWORD --ServerApp.allow_origin=* --ServerApp.preferred_dir=/workspace/EveryDream2trainer
else
    sleep infinity
fi
