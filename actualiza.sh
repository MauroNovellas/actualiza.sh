#!/bin/bash

# Variables de configuración
LOG_DIR="/home/mus3r/Documents/"
LOG_FILE="${LOG_DIR}RegistroActualizaciones"

# Función para comprobar y crear el archivo de registro
initialize_log_file() {
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
    fi
}

# Función para registrar mensajes
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

# Función para ejecutar comandos con sudo y registrar su salida
execute_and_log_with_sudo() {
    log_message "Ejecutando con sudo: $1"
    if sudo bash -c "$1"; then
        log_message "Éxito: $1"
    else
        log_message "Error: $1"
        exit 1
    fi
}

# Función para verificar el estado de salida de un comando
check_exit_status() {
    if [ $1 -ne 0 ]; then
        log_message "Error en la ejecución del comando. Salida con código de error: $1"
        exit 1
    fi
}

# Función para manejar actualizaciones del kernel
handle_kernel_updates() {
    kernel_update_available=$(sudo apt list --upgradable 2>/dev/null | grep -i linux-image)
    if [ ! -z "$kernel_update_available" ]; then
        log_message "Actualizaciones del kernel disponibles: $kernel_update_available"
        read -p "¿Actualizar el kernel? (s/n): " update_kernel_choice
        if [ "$update_kernel_choice" = "s" ]; then
            execute_and_log_with_sudo "apt-get install $kernel_update_available -y"
            check_exit_status $?
        fi
    else
        log_message "No hay actualizaciones del kernel disponibles."
    fi
}

# Función para manejar versiones antiguas del kernel
handle_old_kernels() {
    old_kernels=$(sudo dpkg -l | grep -E 'linux-image-[0-9]+' | grep -Fv $(uname -r) | awk '{print $2}')
    if [ ! -z "$old_kernels" ]; then
        log_message "Versiones antiguas del kernel encontradas: $old_kernels"
        read -p "¿Eliminar versiones antiguas? (s/n): " remove_old_kernels_choice
        if [ "$remove_old_kernels_choice" = "s" ]; then
            execute_and_log_with_sudo "apt-get purge $old_kernels -y"
            check_exit_status $?
        fi
    else
        log_message "No se encontraron versiones antiguas del kernel para desinstalar."
    fi
}

# Inicializar archivo de registro
initialize_log_file

# Actualizaciones
execute_and_log_with_sudo "apt-get update"
check_exit_status $?
execute_and_log_with_sudo "apt-get upgrade -y"
check_exit_status $?
execute_and_log_with_sudo "apt-get dist-upgrade -y"
check_exit_status $?

# Comprobación y manejo de actualizaciones del kernel
log_message "Comprobando actualizaciones del kernel..."
handle_kernel_updates

# Limpieza del sistema
execute_and_log_with_sudo "apt-get autoremove -y"
check_exit_status $?
execute_and_log_with_sudo "apt-get autoclean"
check_exit_status $?

# Manejo de versiones antiguas del kernel
handle_old_kernels

log_message "Proceso completado."
