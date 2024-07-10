#!/bin/bash

# Directorio de origen
SRC="/root/podman/proyecto"

# Directorio de destino de las copias
DEST="/root/discos/2TB/backup_proyecto"

# Obtener la fecha y la hora de la copia
FECHA=$(date +%Y%m%d_%H%M%S)

# Patron para el nombre de la copia de seguridad
BACKUP_DIR="${DEST}/srv_backup_${FECHA}"

# Ejecucion de rsync
rsync -a ${SRC} ${BACKUP_DIR}

# Mantener las copias de seguridad de los últimos 3 días y eliminar las más antiguas
find ${DEST} -maxdepth 1 -type d -mtime +2 | xargs rm -rfv
