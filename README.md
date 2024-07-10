## COMO APROXIMARSE AL PROYECTO

En este directorio esta contenido todo lo necesario para la ejecucion y despliegue del proyecto.

La mejor forma de usar el mismo es utilizando el script **asistente.sh**, presente en este mismo directorio.

Se puede realizar el despliegue usando el comando **podman kube play** y los yaml de ejemplo que se adjuntan, no obstante estos ultimos son simplemente documentacion del proyecto y requieren de edicion. Si deseas probar a realizar el proceso manualmente, consulta la memoria del proyecto para obtener toda la informacion necesaria

## PROCESO DE DESPLIEGUE

1. Aprovisionar el **Caddyfile** con los FQDN que deseemos. Dicho archivo se encuentra en la ruta: **/root/podman/proyecto/caddy_proxy/volumes/Caddyfile**
2. Ejecutar **asistente.sh**
3. Seleccionar la opcion "**Despliegue inicial"**
4. Poblar el servicio de directorio usando **asistente.sh** (Opcional)
5. Crear la base de datos para Nextcloud y el rol (usuario) para el mismo. Dicho rol debe tener permisos sobre la nueva base de datos, por lo que es recomendable que sea el propietario de la base de datos y el esquema.

   Se puede usar **PgAdmin** a tal efecto.
6. Configurar Nextcloud con su asistente inicial, introduciendo los ajustes de la base de datos.
7. Una vez listo Nextcloud, activar y configurar el **backend LDAP** 
8. Para usar la recopilacion de metricas de Grafana, se ha de configurar **Prometheus** y añadir un **Dashboard.** Es un proceso muy rapido y sencillo. Consulta la memoria para obtener mas informacion.

## UBICACION DE LOS ARCHIVOS IMPORTANTES

- Manifiestos yaml de ejemplo: En este mismo directorio
- Manifiestos yaml de redespliegue: En el directorio de cada uno de los **pods**
- Caddyfile: **/root/podman/proyecto/caddy_proxy/volumes/Caddyfile**
- Archivo de configruacion de **Prometheus:**   
  **/root/podman/proyecto/stack_grafana/prometheus.yml**
- LDIF con objetos de prueba para el LDAP:

  **/root/podman/proyecto/stack_ldap/directorio.ldif**
- LDIF para activar memberOf overlay: 

  **/root/podman/proyecto/stack_ldap/add_memberof_overlay.ldif**

  **/root/podman/proyecto/stack_ldap/load_memberof.ldif**

## NOTAS IMPORTANTES

- El proyecto esta pensado para ser ejecutado como el usuario root del servidor en el que se despliegue. Podman es un runtime daemonless que a diferencia de Docker permite la ejecucion de pods y contenedores a usuarios normales no administradores, sin embargo se ha elegido el uso de **root** para evitar problemas con los permisos en los volumenes de persistencia. Se puede modificar facilmente el script **asistente.sh** para que no sea necesario el uso de **root** y cambiar la ruta del directorio **proyecto** aunque no garantizo que todo funcione correctamente. El hecho de que todo sea ejecutado como **root** no vuelve al proyecto intrinsecamente inseguro, pues la ausencia de **daemon** de control de contenedores de **Podman** hace que los contendores queden aislados del sistema. Ejecutarlos como **root** unicamente implica que dicho usuario es el propietario de los elementos desplegados pues estos se ejecutan en modo **unprivileged**, es decir: Sin privilegios de sistema.
- Los puertos **80** y **443** deben estar abiertos, y el servidor debe poder "escuchar" y "responder" a traves de ellos. De lo contrario el proxy inverso **Caddy** no funcionara correctamente y no podra obtener los certificados.
- Aprovisionando correctamente el **Caddyfile** se pueden utilizar los FQDN que se deseen para todas las aplicaciones desplegadas. Informacion sobre como aprovisionarlo en la memoria del proyecto.
