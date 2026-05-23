#!/usr/bin/env bash
set -Eeuo pipefail

ozbox_user="john"
ozbox_home="$(getent passwd "${ozbox_user}" | cut -d: -f6)"
runtime_config="/etc/ssh/sshd_config.d/99-ozbox-runtime.conf"

configure_identity() {
    local current_uid current_gid
    current_uid="$(id -u "${ozbox_user}")"
    current_gid="$(id -g "${ozbox_user}")"

    if [[ -n "${OZBOX_GID:-}" && "${OZBOX_GID}" != "${current_gid}" ]]; then
        groupmod --gid "${OZBOX_GID}" "${ozbox_user}"
    fi

    if [[ -n "${OZBOX_UID:-}" && "${OZBOX_UID}" != "${current_uid}" ]]; then
        usermod --uid "${OZBOX_UID}" "${ozbox_user}"
    fi

    chown -R "${ozbox_user}:${ozbox_user}" "${ozbox_home}"
}

configure_auth_keys() {
    local ssh_dir auth_file
    ssh_dir="${ozbox_home}/.ssh"
    auth_file="${ssh_dir}/authorized_keys"

    install -d -m 0700 -o "${ozbox_user}" -g "${ozbox_user}" "${ssh_dir}"

    if [[ -n "${OZBOX_AUTHORIZED_KEY:-}" ]]; then
        printf '%s\n' "${OZBOX_AUTHORIZED_KEY}" > "${auth_file}"
    fi

    if [[ -f /run/secrets/ozbox_authorized_keys ]]; then
        cat /run/secrets/ozbox_authorized_keys >> "${auth_file}"
    fi

    if [[ -f /config/authorized_keys ]]; then
        cat /config/authorized_keys >> "${auth_file}"
    fi

    if [[ -f "${auth_file}" ]]; then
        chown "${ozbox_user}:${ozbox_user}" "${auth_file}"
        chmod 0600 "${auth_file}"
    fi
}

configure_password_auth() {
    if [[ -n "${OZBOX_PASSWORD:-}" ]]; then
        printf '%s:%s\n' "${ozbox_user}" "${OZBOX_PASSWORD}" | chpasswd
        cat > "${runtime_config}" <<'EOF'
PasswordAuthentication yes
KbdInteractiveAuthentication no
EOF
    else
        passwd --lock "${ozbox_user}" >/dev/null
        cat > "${runtime_config}" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
    fi
}

configure_identity
configure_auth_keys
configure_password_auth
ssh-keygen -A >/dev/null

if [[ "$#" -eq 0 ]]; then
    set -- /usr/sbin/sshd -D -e
fi

exec "$@"
