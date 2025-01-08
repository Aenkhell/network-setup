#!/bin/bash

# Configuración de red
configure_network() {
    echo "Configurando la red..."
    nmcli con mod ens33 ipv4.addresses 192.168.1.10/24
    nmcli con mod ens33 ipv4.gateway 192.168.1.1
    nmcli con mod ens33 ipv4.dns "8.8.8.8 8.8.4.4"
    nmcli con mod ens33 ipv4.method manual
    nmcli con up ens33
    echo "Red configurada con IP estática."
}

# Gestión de usuarios
configure_users() {
    echo "Creando usuarios y configurando permisos..."

    # Crear usuario developer
    useradd -m -c "Nombre Apellido" -s /bin/bash developer
    mkdir -p /home/developer
    chmod 700 /home/developer
    echo "Usuario developer creado y configurado."

    # Configurar restricciones para developer
    echo "Configurando acceso a red interna para developer..."
    iptables -A OUTPUT -m owner --uid-owner developer -d 192.168.1.0/24 -j ACCEPT
    iptables -A OUTPUT -m owner --uid-owner developer -j DROP

    # Crear usuario tester
    useradd -m -c "Nombre Docente" -s /bin/bash tester
    mkdir -p /home/tester
    chmod 700 /home/tester
    echo "Usuario tester creado y configurado."

    # Configurar restricciones para tester
    echo "Bloqueando acceso a Internet para tester..."
    iptables -A OUTPUT -m owner --uid-owner tester -d 0.0.0.0/0 -j DROP
}

# Script de pruebas de red
create_network_test_script() {
    echo "Creando script de pruebas de red..."
    cat << 'EOF' > /home/admin/network_test.sh
#!/bin/bash
log_file="/home/admin/network_tests.log"
echo "Prueba de conectividad - $(date)" >> $log_file
ping -c 4 8.8.8.8 >> $log_file 2>&1
EOF
    chmod +x /home/admin/network_test.sh
    echo "Script de pruebas de red creado."
}

# Configurar tarea cron
configure_cron() {
    echo "Configurando tarea cron para ejecutar el script de pruebas cada hora..."
    (crontab -l 2>/dev/null; echo "0 * * * * /home/admin/network_test.sh") | crontab -
    echo "Tarea cron configurada."
}

# Generar reporte final
generate_report() {
    echo "Generando reporte final..."
    report_file="/home/admin/network_report.txt"
    echo "Reporte de configuración de red y usuarios" > $report_file
    echo "-----------------------------------------" >> $report_file
    echo "Configuración de red actual:" >> $report_file
    nmcli dev show ens33 | grep -E "IP4.ADDRESS|IP4.GATEWAY|IP4.DNS" >> $report_file

    echo "\nUsuarios creados y permisos:" >> $report_file
    echo "Usuario: developer - Acceso solo a la red interna (192.168.1.0/24)" >> $report_file
    echo "Usuario: tester - Bloqueo de acceso a Internet, permite pruebas internas" >> $report_file

    echo "\nResultados de las pruebas de red:" >> $report_file
    cat /home/admin/network_tests.log >> $report_file
    echo "Reporte final generado en $report_file."
}

# Ejecución del script
configure_network
configure_users
create_network_test_script
configure_cron
generate_report

echo "Script completado. Todo configurado exitosamente."
