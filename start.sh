#!/bin/bash

echo "pod started"
source /workspace/EveryDream2trainer/venv/bin/activate

if [[ $PUBLIC_KEY ]]
then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    cd ~/.ssh
    echo $PUBLIC_KEY >> authorized_keys
    chmod 700 -R ~/.ssh
    cd /
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
