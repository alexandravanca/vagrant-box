#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

PUPHPET_CORE_DIR=/opt/puphpet
PUPHPET_STATE_DIR=/opt/puphpet-state

OS=$(/bin/bash "${PUPHPET_CORE_DIR}/shell/os-detect.sh" ID)
VAGRANT_SSH_USERNAME=$(echo "$1")

function create_key()
{
    BASE_KEY_NAME=$(echo "$1")

    if [[ ! -f "${PUPHPET_CORE_DIR}/files/dot/ssh/${BASE_KEY_NAME}" ]]; then
        ssh-keygen -f "${PUPHPET_CORE_DIR}/files/dot/ssh/${BASE_KEY_NAME}" -P ""

        if [[ ! -f "${PUPHPET_CORE_DIR}/files/dot/ssh/${BASE_KEY_NAME}.ppk" ]]; then
            puttygen "${PUPHPET_CORE_DIR}/files/dot/ssh/${BASE_KEY_NAME}" \
                -O private -o "${PUPHPET_CORE_DIR}/files/dot/ssh/${BASE_KEY_NAME}.ppk"
        fi

        echo "Your private key for SSH-based authentication has been saved to 'puphpet/files/dot/ssh/${BASE_KEY_NAME}'!"
    else
        echo "Pre-existing private key found at 'puphpet/files/dot/ssh/${BASE_KEY_NAME}'"
    fi
}

if [[ ! -f "${PUPHPET_STATE_DIR}/install-putty-tools" ]]; then
    if [[ "${OS}" == 'debian' || "${OS}" == 'ubuntu' ]]; then
        apt-get update
        apt-get -y install putty-tools
        touch "${PUPHPET_STATE_DIR}/install-putty-tools"
    fi
fi

create_key 'root_id_rsa'
create_key 'id_rsa'

ROOT_PUBLIC_SSH_KEY=$(cat "${PUPHPET_CORE_DIR}/files/dot/ssh/root_id_rsa.pub")
PUBLIC_SSH_KEY=$(cat "${PUPHPET_CORE_DIR}/files/dot/ssh/id_rsa.pub")

echo 'Adding generated root key to /root/.ssh/id_rsa'
echo 'Adding generated root key to /root/.ssh/id_rsa.pub'
echo 'Adding generated root key to /root/.ssh/authorized_keys'

mkdir -p /root/.ssh

cp "${PUPHPET_CORE_DIR}/files/dot/ssh/root_id_rsa" '/root/.ssh/id_rsa'
cp "${PUPHPET_CORE_DIR}/files/dot/ssh/root_id_rsa.pub" '/root/.ssh/id_rsa.pub'

if [[ ! -f '/root/.ssh/authorized_keys' ]] || ! grep -q "${ROOT_PUBLIC_SSH_KEY}" '/root/.ssh/authorized_keys'; then
    cat "${PUPHPET_CORE_DIR}/files/dot/ssh/root_id_rsa.pub" >> '/root/.ssh/authorized_keys'
fi

chown -R root '/root/.ssh'
chgrp -R root '/root/.ssh'
chmod 700 '/root/.ssh'
chmod 644 '/root/.ssh/id_rsa.pub'
chmod 600 '/root/.ssh/id_rsa'
chmod 600 '/root/.ssh/authorized_keys'

if [ "${VAGRANT_SSH_USERNAME}" != 'root' ]; then
    VAGRANT_SSH_FOLDER="/home/${VAGRANT_SSH_USERNAME}/.ssh";

    mkdir -p "${VAGRANT_SSH_FOLDER}"

    echo "Adding generated key to ${VAGRANT_SSH_FOLDER}/id_rsa"
    echo "Adding generated key to ${VAGRANT_SSH_FOLDER}/id_rsa.pub"
    echo "Adding generated key to ${VAGRANT_SSH_FOLDER}/authorized_keys"

    cp "${PUPHPET_CORE_DIR}/files/dot/ssh/id_rsa" "${VAGRANT_SSH_FOLDER}/id_rsa"
    cp "${PUPHPET_CORE_DIR}/files/dot/ssh/id_rsa.pub" "${VAGRANT_SSH_FOLDER}/id_rsa.pub"

    if [[ ! -f "${VAGRANT_SSH_FOLDER}/authorized_keys" ]] || ! grep -q "${PUBLIC_SSH_KEY}" "${VAGRANT_SSH_FOLDER}/authorized_keys"; then
        cat "${PUPHPET_CORE_DIR}/files/dot/ssh/id_rsa.pub" >> "${VAGRANT_SSH_FOLDER}/authorized_keys"
    fi

    chown -R "${VAGRANT_SSH_USERNAME}" "${VAGRANT_SSH_FOLDER}"
    chgrp -R "${VAGRANT_SSH_USERNAME}" "${VAGRANT_SSH_FOLDER}"
    chmod 700 "${VAGRANT_SSH_FOLDER}"
    chmod 644 "${VAGRANT_SSH_FOLDER}/id_rsa.pub"
    chmod 600 "${VAGRANT_SSH_FOLDER}/id_rsa"
    chmod 600 "${VAGRANT_SSH_FOLDER}/authorized_keys"

    passwd -d "${VAGRANT_SSH_USERNAME}" >/dev/null
fi
