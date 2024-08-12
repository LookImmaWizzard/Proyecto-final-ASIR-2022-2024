#!/bin/bash

#Intro

# Bienvenida
clear
cat banner
echo 'AUTOR: Ismael Carrasco Cubero'
echo 'Antes de comenzar, asegurate de que este directorio y todo su contenido estan en la ruta /root/podman y de haber creado en podman una red llamada "instancia_nextcloud"'
echo 'puedes crear dicha red lanzando "podman network create instancia_nextcloud"'
echo "Por razones de compatibilidad de permisos con los volumenes, este asistente debe ejecutarse como root"
echo
echo "PULSA INTRO PARA CONTINUAR"

read

# Comprueba si el usuario es root
if [ "$(whoami)" != "root" ]; then
    echo "Este script debe ser ejecutado como root por razones de compatibilidad. Saliendo..."
    exit 1
fi

# Comprueba si el directorio es /root
if [ "$(pwd)" != "/root/podman/instancia_nextcloud" ]; then
    echo "El directorio "proyecto" debe ser emplazado en /root/podman. Saliendo..."
    exit 1
fi

clear

while true; do
    # Menú de opciones
    echo "MENU PRINCIPAL"

    echo "Por favor, elige una opción:"
    echo "1. Despliegue inicial"
    echo "2. Redespliegue"
    echo "3. Iniciar todos los contenedores"
    echo "4. Parar todos los contenedores"
    echo "5. Reiniciar todos los contenedores"
    echo "6. Eliminar todos los pods y contenedores"
    echo "7. Poblar servicio de directorio"
    echo "8. Formatear volumenes"
    echo "9. Mostrar consejos"
    echo "10. Readme"
    echo "11. Salir"
    read -p "Introduce el número de tu elección: " opcion

    case $opcion in #Se usa un control de flujo case para las opciones del menu
        1)  # Despliegue inicial
            echo "Despliegue inicial!!"
	    echo "Esta opcion realiza una instalacion nueva de toda la pila y la deja lista para funcionar."
	    echo "Se te solicitaran los datos de tu instancia para realizar el despliegue"
echo
		echo "PULSA INTRO PARA CONTINUAR"
		read
            sleep 1
	    echo 'Aprovisionando el contenedor LDAP Account manager...'
                cp -R stack_ldap/tar/ldap-account-manager-8.6/config/* stack_ldap/volumes/lam/lam_config
	   sleep 1
                echo 'Estableciendo permisos en volumenes...'
                chown -R 33:33 ./stack_nextcloud/volumes/nextcloud_data
                chown -R 5050:5050 ./stack_nextcloud/volumes/pgadmin_data
                chown -R 911:911 ./stack_ldap/volumes/openldap
                chown -R 33:33 ./stack_ldap/volumes/lam
                chown -R 472:472 ./stack_grafana/volumes/grafana
                chown -R nobody:nobody ./stack_grafana/volumes/prometheus
                chmod -R 700 ./stack_grafana/volumes/prometheus
	    sleep 1
	    echo 'A continuacion se le solicitaran los datos de configuracion del servicio de directorio'
	    sleep 1
	    read -p "Introduzca el FQDN de su dominio en formato example.local: " LDAP_DOMAIN
	    read -p "Introduzca la raiz de su dominio en formato dc=example,dc=local: " LDAP_BASE_DN
	    read -p "Introduzca el nombre de su organizacion: " LDAP_ORGANISATION
		#Bucle while para comprobar la contraseña introducida
		while true; do 
    		read -s -p "Introduzca la contraseña de usuario administrador de LDAP: " LDAP_ADMIN_PASSWORD
    			echo
    		read -s -p "Confirme la contraseña de usuario administrador de LDAP: " LDAP_ADMIN_PASSWORD_CONFIRM
    			echo
    			[ "$LDAP_ADMIN_PASSWORD" = "$LDAP_ADMIN_PASSWORD_CONFIRM" ] && break
    			echo "Las contraseñas no coinciden. Por favor, inténtelo de nuevo."
			done
		#Bucle while para comprobar la contraseña introducida
			while true; do
    		read -s -p "Introduzca la contraseña de configuracion de LDAP: " LDAP_CONFIG_PASSWORD
    			echo
    		read -s -p "Confirme la contraseña de configuracion de LDAP: " LDAP_CONFIG_PASSWORD_CONFIRM
    			echo
    			[ "$LDAP_CONFIG_PASSWORD" = "$LDAP_CONFIG_PASSWORD_CONFIRM" ] && break
    			echo "Las contraseñas no coinciden. Por favor, inténtelo de nuevo."
			done
		#Bucle while para comprobar la contraseña introducida
			while true; do
    		read -s -p "Introduzca la contraseña para el perfil de LAM" LAM_PASSWORD
    			echo
    		read -s -p "Confirme la contraseña para el perfil de LAM" LAM_PASSWORD_CONFIRM
    			echo
    			[ "$LAM_PASSWORD" = "$LAM_PASSWORD_CONFIRM" ] && break
    			echo "Las contraseñas no coinciden. Por favor, inténtelo de nuevo."
			done

echo "Generando configuracion del servicio de directorio..."
sleep 1
#Se genera un manifiesto yaml temporal usando los datos introducidos en las variables, y se redirige la salida del EOF hacia el temporal
cat <<EOF > stack_ldap/tmp.yml
apiVersion: v1
kind: Pod
metadata:
 labels:
   app: stackldap
 name: stackldap
spec:
 volumes:
 - name: lam_config
   hostPath:
     path: /root/podman/instancia_nextcloud/stack_ldap/volumes/lam/lam_config
 - name: openldap_config
   hostPath:
     path: /root/podman/instancia_nextcloud/stack_ldap/volumes/openldap/config
 - name: openldap_database
   hostPath:
     path: /root/podman/instancia_nextcloud/stack_ldap/volumes/openldap/database
 containers:
 - env:
   - name: LDAP_DOMAIN
     value: $LDAP_DOMAIN
   - name: LDAP_BASE_DN
     value: $LDAP_BASE_DN
   - name: LDAP_SERVER
     value: ldap://127.0.0.1:389
   - name: LAM_PASSWORD
     value: $LAM_PASSWORD
   - name: LAM_LANG
     value: es_ES
   - name: LAM_SKIP_PRECONFIGURE
     value: false
   image: ghcr.io/ldapaccountmanager/lam:latest #o 8.6
   securityContext:
    fsGroup: 33
   name: lam
   tty: true
   volumeMounts:
   - mountPath: /var/lib/ldap-account-manager/config:Z
     name: lam_config
 - env:
   - name: LDAP_DOMAIN
     value: $LDAP_DOMAIN
   - name: LDAP_ADMIN_PASSWORD
     value: $LDAP_ADMIN_PASSWORD
   - name: KEEP_EXISTING_CONFIG
     value: "true"
   - name: LDAP_ORGANISATION
     value: $LDAP_ORGANISATION
   - name: LDAP_CONFIG_PASSWORD
     value: $LDAP_CONFIG_PASSWORD
   image: docker.io/osixia/openldap:latest
   securityContext:
   name: openldap
   tty: true
   volumeMounts:
   - mountPath: /etc/ldap/slapd.d:Z
     name: openldap_config
   - mountPath: /var/lib/ldap:Z
     name: openldap_database
EOF

echo "Desplegando sevicio de directorio"
sleep 1
podman kube play --network instancia_nextcloud stack_ldap/tmp.yml

sleep 5

echo "Activando memberOf Overlay"

cp stack_ldap/add_memberof_overlay.ldif stack_ldap/volumes/openldap/database/add_memberof_overlay.ldif
cp stack_ldap/load_memberof.ldif stack_ldap/volumes/openldap/database/load_memberof.ldif
podman exec stackldap-openldap ldapmodify -Y EXTERNAL -H ldapi:/// -f /var/lib/ldap/load_memberof.ldif
podman exec stackldap-openldap ldapmodify -Y EXTERNAL -H ldapi:/// -f /var/lib/ldap/add_memberof_overlay.ldif

sleep 1
#Se elimina el yml temporal generado por el cat EOF
echo "Limpiando..."
rm stack_ldap/tmp.yml
rm stack_ldap/volumes/openldap/database/add_memberof_overlay.ldif
rm stack_ldap/volumes/openldap/database/load_memberof.ldif

sleep 1

echo 'A continuacion se le solicitaran los datos de configuracion para Nextcloud y la instancia de base de datos'
sleep 1

read -p "Introduzca el usuario administrador de PostgreSQL: " POSTGRES_USER
read -p "Introduzca el email del usuario predeterminado para PGAdmin: " PGADMIN_DEFAULT_EMAIL
#Bucle while para comprobar la contraseña introducida
while true; do
      read -s -p "Introduzca la contraseña para el usuario administrador de PostgreSQL: " POSTGRES_PASSWORD
           echo
      read -s -p "Confirme la contraseña : " POSTGRES_PASSWORD_CONFIRM
           echo
                [ "$POSTGRES_PASSWORD" = "$POSTGRES_PASSWORD_CONFIRM" ] && break
           echo "Las contraseñas no coinciden. Por favor, inténtelo de nuevo."
done
#Bucle while para comprobar la contraseña introducida
while true; do
      read -s -p "Introduzca la contraseña para el usuario predeterminado de PGAdmin: " PGADMIN_DEFAULT_PASSWORD
           echo
      read -s -p "Confirme la contraseña : " PGADMIN_DEFAULT_PASSWORD_CONFIRM
           echo
                [ "$PGADMIN_DEFAULT_PASSWORD" = "$PGADMIN_DEFAULT_PASSWORD_CONFIRM" ] && break
           echo "Las contraseñas no coinciden. Por favor, inténtelo de nuevo."
done

#Bucle while para comprobar la contraseña introducida
while true; do
      read -s -p "Introduzca la contraseña para el usuario predeterminado de REDIS: " REDIS_PASSWORD
           echo
      read -s -p "Confirme la contraseña : " REDIS_PASSWORD_CONFIRM
           echo
                [ "$REDIS_PASSWORD" = "$REDIS_PASSWORD_CONFIRM" ] && break
           echo "Las contraseñas no coinciden. Por favor, inténtelo de nuevo."
done

#Despliegue del pod nextcloud
echo "Generando configuracion para Nextcloud y la base de datos..."
sleep 1
#Se genera un manifiesto yaml temporal usando los datos introducidos en las variables, y se redirige la salida del EOF hacia el temporal
cat <<EOF > stack_nextcloud/tmp.yml
apiVersion: v1
kind: Pod
metadata:
  name: stacknc
spec:
  volumes:
  - name: nextcloud-data
    hostPath:
      path: /root/podman/instancia_nextcloud/stack_nextcloud/volumes/nextcloud_data
  - name: postgres-data
    hostPath:
      path: /root/podman/instancia_nextcloud/stack_nextcloud/volumes/postgres_data
  - name: pgadmin-data
    hostPath:
      path: /root/podman/instancia_nextcloud/stack_nextcloud/volumes/pgadmin_data
  containers:
  - name: nextcloud
    image: docker.io/library/nextcloud:stable-apache
    env:
    - name: REDIS_HOST
      value: localhost
    - name: REDIS_HOST_PORT
      value: 6379
    - name: REDIS_HOST_PASSWORD
      value: $REDIS_PASSWORD
    volumeMounts:
    - mountPath: /var/www/html:z
      name: nextcloud-data
  - name: postgres
    image: postgres:latest
    env:
    - name: POSTGRES_PASSWORD
      value: $POSTGRES_PASSWORD
    - name: POSTGRES_USER
      value: $POSTGRES_USER
    volumeMounts:
    - mountPath: /var/lib/postgresql/data:z
      name: postgres-data
  - name: pgadmin
    image: dpage/pgadmin4
    env:
    - name: PGADMIN_DEFAULT_EMAIL
      value: $PGADMIN_DEFAULT_EMAIL
    - name: PGADMIN_DEFAULT_PASSWORD
      value: $PGADMIN_DEFAULT_PASSWORD
    - name: PGADMIN_LISTEN_PORT
      value: "81"
    volumeMounts:
    - mountPath: /var/lib/pgadmin:z
      name: pgadmin-data
  - name: redis
    image: docker.io/library/redis:latest
    args:
    - /bin/sh
    - -c
    - redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    env:
    - name: REDIS_PASSWORD
      value: $REDIS_PASSWORD
EOF

echo "Desplegando Nextcloud y la base de datos..."
sleep 1
podman kube play --network instancia_nextcloud stack_nextcloud/tmp.yml

sleep 1
#Se elimina el yml temporal generado por el cat EOF
echo "Limpiando..."
rm stack_nextcloud/tmp.yml

#Despliegue del stack de monitorizacion
echo 'Desplegando Grafana...'
cp stack_grafana/prometheus.yml stack_grafana/volumes/prometheus/etc/prometheus.yml
chown -R nobody:nobody stack_grafana/volumes/prometheus/etc/prometheus.yml
chmod 700 stack_grafana/volumes/prometheus/etc/prometheus.yml
podman kube play --network instancia_nextcloud stack_grafana/stack_grafana.yml

#Despliegue del proxy
echo 'Desplegando proxy reverso Caddy Server...'

podman run -d \
  --name=proxy \
  --network=instancia_nextcloud \
  -p 80:80 \
  -p 443:443 \
  -v /root/podman/instancia_nextcloud/caddy_proxy/volumes/Caddyfile:/etc/caddy/Caddyfile:z \
  -v /root/podman/instancia_nextcloud/caddy_proxy/volumes/data:/data:z \
  -v /root/podman/instancia_nextcloud/caddy_proxy/volumes/config:/config:z \
  caddy:latest

echo "Reiniciando proxy inverso..."
sleep 2
podman container restart proxy

echo "Despliegue completado! El proxy inverso necesita algo de tiempo para obtener los certificados https. Si recibes errores al acceder a las aplicaciones espera unos minutos"
echo
echo "PULSA INTRO PARA CONTINUAR..."
read
clear
            ;;
        2)   #Correccion de permisos
	     echo "Esta opcion realiza el despliegue de una instancia previamente configurada que ya contiene configuraciones almacenadas en los volumenes"
	     echo "Resulta util si has eliminado los contenedores, y deseas redesplegarlos conservando todos sus datos para por ejemplo actualizar las aplicaciones a sus nuevas imagenes"
	     echo "PULSA INTRO PARA CONTINUAR..."
		read
             echo 'Estableciendo permisos en volumenes...'

                chown -R 33:33 ./stack_nextcloud/volumes/nextcloud_data
                chown -R 5050:5050 ./stack_nextcloud/volumes/pgadmin_data
                chown -R 911:911 ./stack_ldap/volumes/openldap
                chown -R 33:33 ./stack_ldap/volumes/lam
                chown -R 472:472 ./stack_grafana/volumes/grafana
                chown -R nobody:nobody ./stack_grafana/volumes/prometheus
                chmod -R 700 ./stack_grafana/volumes/prometheus

	# Redespliegue
            echo "Ejecutando comandos de redespliegue."
                sleep 1
                echo 'Desplegando el servicio de directorio'
                podman kube play --network instancia_nextcloud ./stack_ldap/redeploy.yml
                echo 'Desplegando Nextcloud y base de datos'
                podman kube play --network instancia_nextcloud ./stack_nextcloud/redeploy.yml
                echo 'Desplegando Grafana y Prometheus' 
                podman kube play --network instancia_nextcloud ./stack_grafana/redeploy.yml
                echo 'Desplegando proxy inverso Caddy'
podman run -d \
  --name=proxy \
  --network=instancia_nextcloud \
  -p 80:80 \
  -p 443:443 \
  -v /root/podman/instancia_nextcloud/caddy_proxy/volumes/Caddyfile:/etc/caddy/Caddyfile:z \
  -v /root/podman/instancia_nextcloud/caddy_proxy/volumes/data:/data:z \
  -v /root/podman/instancia_nextcloud/caddy_proxy/volumes/config:/config:z \
  caddy:latest

echo
echo "Despliegue completado! PULSA INTRO PARA CONTINUAR..."
read
clear 
            ;;
        3)  # Iniciar los contenedores y pods
	    echo "Usa esta opcion para iniciar los contenedores si los has detenido"
echo
	    echo "PULSA INTRO PARA CONTINUAR"
		read
            echo "Iniciando contenedores y pods..."
            podman pod start stacknc stackldap stackgrafana && podman container start proxy
echo
            echo "Todos los contenedores y pods han sido Iniciados! PULSA INTRO PARA CONTINUAR..."
read
clear 
            ;;
        4)  # Parar los contenedores y pods
            echo "Usa esta opcion si deseas detener los servicios de la pila"
echo
            echo "PULSA INTRO PARA CONTINUAR"
		read
            echo "Parando contenedores y pods..."
            podman pod stop stacknc stackldap stackgrafana && podman container stop proxy
echo
            echo "Todos los contenedores y pods han sido detenidos! PULSA INTRO PARA CONTINUAR..."
read
clear 
            ;;
        5)  # Reiniciar los contenedores y pods
            echo "Usa esta opcion si deseas reiniciar los contenedores, si por ejemplo alguno de ellos esta fallando"
echo
            echo "PULSA INTRO PARA CONTINUAR"
                read
            echo "Reiniciando contenedores y pods..."
            podman pod restart stacknc stackldap stackgrafana && podman container restart proxy
echo
            echo "Todos los contenedores y pods han sido reiniciados! PULSA INTRO PARA CONTINUAR..."
read
clear 
            ;;


        6)  # Borrar pods y contenedores
            echo "Eliminando contenedores..."
	    podman pod stop stacknc stackldap stackgrafana && podman container stop proxy
	    podman pod rm stacknc stackldap stackgrafana && podman container rm proxy
echo
            echo "Todos los contenedores y pods han sido eliminados! PULSA INTRO PARA CONTINUAR..."
read
clear 
            ;;
        7)  # Poblar servicio de directorio
	echo "Esta opcion automatiza la importacion de datos LDIF al servicio de directorio LDAP desplegado"
	echo "El archivo LDIF adjunto solo es valido para el dominio ismael-server.ddns.net, por lo que si deseas importar tu propio ldif, renombralo a directorio.ldif"
	echo "y añadelo al directorio /root/podman/instancia_nextcloud/stack_ldap"
echo
	echo "PULSA INTRO PARA CONTINUAR..."
	read
            read -p "Introduzca el usuario administrador del directorio en formato cn (cn=admin,dc=example,dc=com) : " LDAP_ADMIN_USER_DN
            read -s -p "Introduzca la contraseña del administrador del directorio: " LDAP_ADMIN_USER_PASS
            cp stack_ldap/directorio.ldif stack_ldap/volumes/openldap/database/directorio.ldif
            podman exec proyecto_stackldap-openldap ldapadd -x -D $LDAP_ADMIN_USER_DN -w $LDAP_ADMIN_USER_PASS -f /var/lib/ldap/directorio.ldif
            rm stack_ldap/volumes/openldap/database/directorio.ldif
echo
            echo "Entradas añadidas al directorio! PULSA INTRO PARA CONTINUAR..."
read
clear  
            ;;
        8)  # Formatear volumenes
	    echo "Usa esta opcion si deseas eliminar todos los datos y configuraciones de la pila de software"
echo
            echo "PULSA INTRO PARA CONTINUAR..."
        	read
            echo "Formateando volumenes..."
            podman pod stop stackldap stacknc stackgrafana && podman container stop proxy
	    podman pod rm stackldap stacknc stackgrafana && podman container rm proxy
            rm -rf stack_nextcloud/volumes/postgres_data/*
            rm -rf stack_nextcloud/volumes/pgadmin_data/*
            rm -rf stack_nextcloud/volumes/nextcloud_data/*
            rm -rf stack_ldap/volumes/lam/lam_config/*
            rm -rf stack_ldap/volumes/openldap/config/*
            rm -rf stack_ldap/volumes/openldap/database/*
            rm -rf stack_grafana/volumes/prometheus/etc/*
            rm -rf stack_grafana/volumes/prometheus/data/*
            rm -rf stack_grafana/volumes/grafana/data/*
            rm -rf caddy_proxy/volumes/config/*
            rm -rf caddy_proxy/volumes/data/*
            echo "Todos los datos de los volumenes han sido eliminados!"
	    echo "Redespliega la instancia con la opcion Despliegue inicial desde el menu principal" 
echo
	    echo "PULSA INTRO PARA CONTINUAR..."
read
clear  
            ;;
        9)  # Consejos
clear
cat <<EOF
 CONSEJOS
 
 - Las teclas del teclado numerico (De haberlo) introducen caracteres de escape durante introduccion de parametros y contraseñas del asistente si el bloq num esta desactivado. Asegurate de activarlo o utilizar numeros de la
 parte superior del teclado

 - Tras realiazar un despliegue inicial, las aplicaciones aun necesitan ciertas configuraciones adicionales que este asistente no puede cubrir. Consulta la guia tecnica del proyecto para realizar dichas
 configuraciones

 - Si deseas realizar una copia de toda la instancia para su despliegue en otra maquina o una restauracion en la misma, debes restaurar el directorio /root/podman/instancia_nextcloud en la maquina objetivo y elegir
 la opcion de redespliegue de este asistente. El script se encargara de corregir todos los permisos en los volumenes y la instancia quedara lista para su ejecucion

- El servidor en el que desplegar este proyecto necesita tener abiertos al exterior los puertos 80 http y 443 https. Asegurate de que tu firewall permite las conexiones entrantes y salientes por dichos puertos

- Este proyecto esta pensado para ser utilizado exclusivamente con Podman y no funciona con otros runtimes de contenedores como Docker. Asegurate de tener instalados en el servidor los paquetes podman y podman kube

- Por defecto el servicio de directorio no contiene ninguna entrada. Si deseas realizar pruebas, utiliza la opcion "Poblar servicio de directorio" en el menu principal para añadirle entradas de prueba

- Si deseas mantener la instancia desplegada pero deseas "Resetearla", utiliza la opcion "Formatear volumenes" en el menu principal. Tras el formateo, debes usar la opcion de "Despliegue inicial"

- Este asistente tiene algunas limitaciones por falta de tiempo para completarse, como no distinguir entre numeros o letras en las entradas de nombres de usuario, email o contraseñas por lo que ten precaucion durante la entrada de
parametros durante el despiegue inicial o la introduccion de datos en el directorio.

EOF


echo
            echo 'PULSA INTRO PARA CONTINUAR...'
	    read
	    clear
            ;;
        10)  # Mostar el readme
clear
cat ./README.md
            echo 'PULSA INTRO PARA CONTINUAR...'
            read
            clear
            ;;

        11)  # Cancelar
	    clear
            echo "Salir..."
            break
            ;;

        *)  # Opción no válida
            echo "Por favor, introduce una opción válida."
            ;;
    esac
done
#Termina el control del flujo case

#FIN DEL SCRIPT
