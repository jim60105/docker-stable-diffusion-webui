#!/bin/sh

ln_scripts() {
    echo "Linking scripts..."
    mkdir -p /data/scripts /app/scripts
    ln -sv /data/scripts/* /app/scripts 2>/dev/null
}

create_ui_config() {
    if [ ! -f /data/ui-config.json ]; then
        echo "Creating empty UI config..."
        echo "{}" >/data/ui-config.json
    fi
}

data_dir_fallback() {
    echo "Setting up data directory fallback..."
    ln -svT /data/ui-config.json /app/ui-config.json 2>/dev/null

    mkdir -p /data/config_states /data/extensions /data/models
    mkdir -p /app/config_states /app/extensions /app/models
    ln -svT /data/config_states/* /app/config_states 2>/dev/null
    ln -svd /data/extensions/* /app/extensions 2>/dev/null

    find ./models -type f -name 'Put*here.txt' -exec rm {} \;
    find ./models -type d -empty -delete
    ln -svd /data/models/* /app/models 2>/dev/null
}

install_requirements() {
    if ! pip show torch 2>/dev/null | grep -q Name; then
        echo "Installing torch and related packages... (This will only run once and might take some time)"
        uv venv --system-site-packages /venv && \
        uv pip install -U \
            -r requirements_versions.txt \
            setuptools==69.5.1 \
            wheel \
            torch==2.7.0 torchvision \
            xformers==0.0.30 \
            numpy==1.26.2 \
            pillow==9.5.0
    fi
}

correct_permissions() {
    echo "Correcting user data permissions... Please wait a second."
    chmod -R 775 /data 2>/dev/null
    echo "Done."
}

handle_sigint() {
    kill -s INT $python_pid
    wait $python_pid

    echo "WebUI stopped."
    correct_permissions
    exit 0
}

ln_scripts
create_ui_config
data_dir_fallback
install_requirements

trap handle_sigint INT

echo "Starting WebUI with arguments: $*"
python3 /app/launch.py --listen --port 7860 --data-dir /data --gradio-allowed-path "." "$@" &
python_pid=$!
wait $python_pid

echo "WebUI stopped."
correct_permissions
