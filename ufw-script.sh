#!/bin/bash

set -euo pipefail

#######################################
# Root check
#######################################
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Please run this script with sudo or as root."
    exit 1
fi

#######################################
# Globals
#######################################
declare -a RULES_APPLIED=()
LOG_LEVEL="medium"
LANG_CHOICE="en"

#######################################
# i18n
#######################################
tr() {
    local key="$1"

    case "$LANG_CHOICE:$key" in
        de:run_as_root) echo "Bitte mit sudo oder als root ausführen." ;;
        en:run_as_root) echo "Please run this script with sudo or as root." ;;

        de:press_enter) echo "Weiter mit Enter..." ;;
        en:press_enter) echo "Press Enter to continue..." ;;

        de:please_enter_y_n) echo "Bitte j oder n eingeben." ;;
        en:please_enter_y_n) echo "Please enter y or n." ;;

        de:invalid_selection) echo "Ungültige Auswahl." ;;
        en:invalid_selection) echo "Invalid selection." ;;

        de:invalid_menu_selection) echo "Ungültige Auswahl. Bitte Zahlen aus dem Menü eingeben." ;;
        en:invalid_menu_selection) echo "Invalid selection. Please enter numbers from the menu." ;;

        de:invalid_port) echo "Ungültiger Port." ;;
        en:invalid_port) echo "Invalid port." ;;

        de:invalid_protocol) echo "Ungültiges Protokoll." ;;
        en:invalid_protocol) echo "Invalid protocol." ;;

        de:invalid_source) echo "Ungültige Quelle." ;;
        en:invalid_source) echo "Invalid source." ;;

        de:invalid_source_target) echo "Ungültige Quelle/Zielangabe." ;;
        en:invalid_source_target) echo "Invalid source/target value." ;;

        de:applying_base_rules) echo "Setze Basisregeln..." ;;
        en:applying_base_rules) echo "Applying base rules..." ;;

        de:continue_q) echo "Fortfahren?" ;;
        en:continue_q) echo "Continue?" ;;

        de:aborted) echo "Abgebrochen." ;;
        en:aborted) echo "Aborted." ;;

        de:warning_reset_1) echo "- Das Skript setzt UFW vollständig zurück." ;;
        en:warning_reset_1) echo "- This script fully resets UFW." ;;

        de:warning_reset_2) echo "- Bestehende Regeln gehen verloren." ;;
        en:warning_reset_2) echo "- Existing rules will be lost." ;;

        de:warning_reset_3) echo "- Das Basisprofil wird immer gesetzt." ;;
        en:warning_reset_3) echo "- The base profile is always applied." ;;

        de:select_language) echo "Sprache auswählen / Select language" ;;
        en:select_language) echo "Sprache auswählen / Select language" ;;

        de:lang_german) echo "Deutsch" ;;
        en:lang_german) echo "German" ;;

        de:lang_english) echo "Englisch" ;;
        en:lang_english) echo "English" ;;

        de:selection) echo "Auswahl" ;;
        en:selection) echo "Selection" ;;

        de:multiple_hint_1) echo "Mehrfachauswahl möglich, z. B.: 1 3 5" ;;
        en:multiple_hint_1) echo "Multiple selections are allowed, for example: 1 3 5" ;;

        de:multiple_hint_2) echo "Leer lassen = keine Auswahl" ;;
        en:multiple_hint_2) echo "Leave empty = no selection" ;;

        de:main_title) echo "Komfortables UFW-Setup mit Untermenüs" ;;
        en:main_title) echo "Comfortable UFW setup with submenus" ;;

        de:modules_title) echo "Welche Module sollen aktiviert werden?" ;;
        en:modules_title) echo "Which modules should be enabled?" ;;

        de:module_web) echo "Webserver (80/443 eingehend)" ;;
        en:module_web) echo "Web server (80/443 inbound)" ;;

        de:module_admin81) echo "Port 81/Admin" ;;
        en:module_admin81) echo "Port 81/Admin" ;;

        de:module_mail) echo "Mail-Out (25/465/587 ausgehend)" ;;
        en:module_mail) echo "Mail-Out (25/465/587 outbound)" ;;

        de:module_dns) echo "DNS-Server (53 tcp/udp eingehend)" ;;
        en:module_dns) echo "DNS server (53 tcp/udp inbound)" ;;

        de:module_ntp) echo "NTP-Server (123/udp eingehend)" ;;
        en:module_ntp) echo "NTP server (123/udp inbound)" ;;

        de:module_monitoring) echo "Monitoring-Untermenü" ;;
        en:module_monitoring) echo "Monitoring submenu" ;;

        de:module_custom) echo "Custom-Ports-Untermenü" ;;
        en:module_custom) echo "Custom ports submenu" ;;

        de:monitoring_title) echo "Welche Monitoring-Ports sollen geöffnet werden?" ;;
        en:monitoring_title) echo "Which monitoring ports should be opened?" ;;

        de:monitoring_node) echo "Prometheus Node Exporter (9100/tcp)" ;;
        en:monitoring_node) echo "Prometheus Node Exporter (9100/tcp)" ;;

        de:monitoring_snmp) echo "SNMP (161/udp)" ;;
        en:monitoring_snmp) echo "SNMP (161/udp)" ;;

        de:monitoring_grafana) echo "Grafana (3000/tcp)" ;;
        en:monitoring_grafana) echo "Grafana (3000/tcp)" ;;

        de:monitoring_zabbix) echo "Zabbix Agent (10050/tcp)" ;;
        en:monitoring_zabbix) echo "Zabbix Agent (10050/tcp)" ;;

        de:monitoring_custom) echo "Benutzerdefiniert" ;;
        en:monitoring_custom) echo "Custom" ;;

        de:restrict_port81) echo "Port 81 auf Quelle/IP/Subnetz beschränken?" ;;
        en:restrict_port81) echo "Restrict port 81 to a specific source IP/subnet?" ;;

        de:port81_source) echo "Quelle für Port 81 (IPv4 oder CIDR, z. B. 10.10.0.0/24): " ;;
        en:port81_source) echo "Source for port 81 (IPv4 or CIDR, for example 10.10.0.0/24): " ;;

        de:dns_restrict) echo "DNS-Server nur für bestimmtes Netz öffnen?" ;;
        en:dns_restrict) echo "Restrict DNS server to a specific network?" ;;

        de:dns_source) echo "Quelle für DNS-Server (IPv4/CIDR): " ;;
        en:dns_source) echo "Source for DNS server (IPv4/CIDR): " ;;

        de:ntp_restrict) echo "NTP-Server nur für bestimmtes Netz öffnen?" ;;
        en:ntp_restrict) echo "Restrict NTP server to a specific network?" ;;

        de:ntp_source) echo "Quelle für NTP-Server (IPv4/CIDR): " ;;
        en:ntp_source) echo "Source for NTP server (IPv4/CIDR): " ;;

        de:monitoring_menu) echo "Monitoring-Untermenü:" ;;
        en:monitoring_menu) echo "Monitoring submenu:" ;;

        de:monitoring_restrict) echo "Monitoring-Regeln auf Quelle/IP/Subnetz beschränken?" ;;
        en:monitoring_restrict) echo "Restrict monitoring rules to a specific source IP/subnet?" ;;

        de:monitoring_source) echo "Quelle für Monitoring (IPv4/CIDR): " ;;
        en:monitoring_source) echo "Source for monitoring (IPv4/CIDR): " ;;

        de:custom_ports_menu) echo "Custom-Ports-Menü" ;;
        en:custom_ports_menu) echo "Custom ports menu" ;;

        de:custom_in) echo "Eingehende Ports hinzufügen" ;;
        en:custom_in) echo "Add inbound ports" ;;

        de:custom_out) echo "Ausgehende Ports hinzufügen" ;;
        en:custom_out) echo "Add outbound ports" ;;

        de:back) echo "Zurück" ;;
        en:back) echo "Back" ;;

        de:port_prompt) echo "Port (leer = fertig): " ;;
        en:port_prompt) echo "Port (empty = finish): " ;;

        de:proto_prompt) echo "Protokoll tcp/udp/both [tcp]: " ;;
        en:proto_prompt) echo "Protocol tcp/udp/both [tcp]: " ;;

        de:source_prompt_in) echo "Quelle erlauben [any|IPv4|CIDR] (Standard any): " ;;
        en:source_prompt_in) echo "Allowed source [any|IPv4|CIDR] (default any): " ;;

        de:source_prompt_out) echo "Allowed destination [any|IPv4|CIDR] (default any): " ;;
        en:source_prompt_out) echo "Allowed destination [any|IPv4|CIDR] (default any): " ;;

        de:comment_prompt) echo "Kommentar (optional): " ;;
        en:comment_prompt) echo "Comment (optional): " ;;

        de:logging_title) echo "Logging-Level wählen" ;;
        en:logging_title) echo "Choose logging level" ;;

        de:summary_title) echo "Zusammenfassung der geplanten Regeln" ;;
        en:summary_title) echo "Summary of planned rules" ;;

        de:logging_level) echo "Logging-Level" ;;
        en:logging_level) echo "Logging level" ;;

        de:apply_enable_q) echo "Regeln jetzt anwenden und UFW aktivieren?" ;;
        en:apply_enable_q) echo "Apply rules now and enable UFW?" ;;

        de:rules_left_local) echo "Bereits gesetzte UFW-Regeln bleiben lokal erhalten." ;;
        en:rules_left_local) echo "Already configured UFW rules remain in place locally." ;;

        de:check_manual) echo "Du kannst jetzt manuell prüfen mit: ufw status numbered" ;;
        en:check_manual) echo "You can now manually check with: ufw status numbered" ;;

        de:enabling) echo "Aktiviere UFW..." ;;
        en:enabling) echo "Enabling UFW..." ;;

        de:done) echo "UFW-Konfiguration abgeschlossen." ;;
        en:done) echo "UFW configuration completed." ;;

        *) echo "$key" ;;
    esac
}

press_enter() {
    read -r -p "$(tr press_enter)"
}

#######################################
# Helper
#######################################
ask_yes_no() {
    local prompt="$1"
    local answer
    while true; do
        if [[ "$LANG_CHOICE" == "de" ]]; then
            read -r -p "$prompt [j/n]: " answer
            case "${answer,,}" in
                j|ja|y|yes) return 0 ;;
                n|nein|no)  return 1 ;;
                *) echo "$(tr please_enter_y_n)" ;;
            esac
        else
            read -r -p "$prompt [y/n]: " answer
            case "${answer,,}" in
                y|yes) return 0 ;;
                n|no)  return 1 ;;
                *) echo "$(tr please_enter_y_n)" ;;
            esac
        fi
    done
}

validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 ))
}

validate_proto() {
    local proto="${1,,}"
    [[ "$proto" == "tcp" || "$proto" == "udp" || "$proto" == "both" ]]
}

validate_source() {
    local src="$1"
    [[ "$src" == "any" ]] && return 0
    [[ "$src" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && return 0
    [[ "$src" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]] && return 0
    return 1
}

add_rule_note() {
    RULES_APPLIED+=("$1")
}

run_ufw_allow() {
    local direction="$1"
    local port="$2"
    local proto="$3"
    local source="${4:-any}"
    local comment="${5:-custom rule}"

    if [[ "$proto" == "both" ]]; then
        run_ufw_allow "$direction" "$port" "tcp" "$source" "$comment"
        run_ufw_allow "$direction" "$port" "udp" "$source" "$comment"
        return 0
    fi

    if [[ "$direction" == "in" ]]; then
        if [[ "$source" == "any" ]]; then
            ufw allow in "$port"/"$proto" comment "$comment"
            add_rule_note "ALLOW IN  any  -> port $port/$proto    ($comment)"
        else
            ufw allow in from "$source" to any port "$port" proto "$proto" comment "$comment"
            add_rule_note "ALLOW IN  $source -> port $port/$proto    ($comment)"
        fi
    else
        if [[ "$source" == "any" ]]; then
            ufw allow out "$port"/"$proto" comment "$comment"
            add_rule_note "ALLOW OUT any  -> port $port/$proto    ($comment)"
        else
            ufw allow out to "$source" port "$port" proto "$proto" comment "$comment"
            add_rule_note "ALLOW OUT -> $source port $port/$proto    ($comment)"
        fi
    fi
}

choose_single() {
    local title="$1"
    shift
    local options=("$@")
    local choice

    echo
    echo "$title"
    local i
    for i in "${!options[@]}"; do
        printf "  %d) %s\n" "$((i+1))" "${options[$i]}"
    done

    while true; do
        read -r -p "$(tr selection): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            echo "$choice"
            return 0
        fi
        echo "$(tr invalid_selection)"
    done
}

choose_multi() {
    local title="$1"
    shift
    local options=("$@")
    local input
    local token

    echo
    echo "$title"
    local i
    for i in "${!options[@]}"; do
        printf "  %d) %s\n" "$((i+1))" "${options[$i]}"
    done
    echo "$(tr multiple_hint_1)"
    echo "$(tr multiple_hint_2)"

    while true; do
        read -r -p "$(tr selection): " input
        [[ -z "$input" ]] && { echo ""; return 0; }

        local valid=1
        for token in $input; do
            if ! [[ "$token" =~ ^[0-9]+$ ]] || (( token < 1 || token > ${#options[@]} )); then
                valid=0
                break
            fi
        done

        if (( valid )); then
            echo "$input"
            return 0
        fi

        echo "$(tr invalid_menu_selection)"
    done
}

#######################################
# Language selection
#######################################
select_language() {
    local choice
    echo "==========================================="
    echo "        UFW Wizard / UFW Assistent"
    echo "==========================================="
    echo
    echo "$(tr select_language)"
    echo "  1) Deutsch"
    echo "  2) English"

    while true; do
        read -r -p "Selection/Auswahl: " choice
        case "$choice" in
            1) LANG_CHOICE="de"; break ;;
            2) LANG_CHOICE="en"; break ;;
            *) echo "Please choose 1 or 2 / Bitte 1 oder 2 wählen." ;;
        esac
    done
}

#######################################
# Base rules
#######################################
apply_base_rules() {
    echo
    echo "$(tr applying_base_rules)"

    ufw --force reset
    add_rule_note "RESET UFW"

    ufw default deny incoming
    ufw default deny outgoing
    add_rule_note "DEFAULT deny incoming"
    add_rule_note "DEFAULT deny outgoing"

    ufw allow in on lo comment 'loopback in'
    ufw allow out on lo comment 'loopback out'
    add_rule_note "ALLOW IN  loopback"
    add_rule_note "ALLOW OUT loopback"

    ufw allow out 53/udp comment 'DNS UDP'
    ufw allow out 53/tcp comment 'DNS TCP fallback'
    ufw allow out 80/tcp comment 'HTTP updates'
    ufw allow out 443/tcp comment 'HTTPS updates'
    ufw allow out 123/udp comment 'NTP client'
    ufw allow out proto icmp comment 'ICMP outbound'
    add_rule_note "ALLOW OUT any -> port 53/udp"
    add_rule_note "ALLOW OUT any -> port 53/tcp"
    add_rule_note "ALLOW OUT any -> port 80/tcp"
    add_rule_note "ALLOW OUT any -> port 443/tcp"
    add_rule_note "ALLOW OUT any -> port 123/udp"
    add_rule_note "ALLOW OUT proto icmp"

    ufw limit 22/tcp comment 'SSH rate limit'
    add_rule_note "LIMIT IN  any -> port 22/tcp"
}

#######################################
# Modules
#######################################
module_webserver() {
    run_ufw_allow "in" 80 tcp any "HTTP"
    run_ufw_allow "in" 443 tcp any "HTTPS"
}

module_admin81() {
    local src="any"
    if ask_yes_no "$(tr restrict_port81)"; then
        while true; do
            read -r -p "$(tr port81_source)" src
            if validate_source "$src" && [[ "$src" != "any" ]]; then
                break
            fi
            echo "$(tr invalid_source)"
        done
    fi
    run_ufw_allow "in" 81 tcp "$src" "Admin Port 81"
}

module_mail_out() {
    run_ufw_allow "out" 25 tcp any "SMTP relay optional"
    run_ufw_allow "out" 465 tcp any "SMTPS"
    run_ufw_allow "out" 587 tcp any "SMTP submission"
}

module_dns_server() {
    local src="any"
    if ask_yes_no "$(tr dns_restrict)"; then
        while true; do
            read -r -p "$(tr dns_source)" src
            if validate_source "$src" && [[ "$src" != "any" ]]; then
                break
            fi
            echo "$(tr invalid_source)"
        done
    fi
    run_ufw_allow "in" 53 tcp "$src" "DNS server TCP"
    run_ufw_allow "in" 53 udp "$src" "DNS server UDP"
}

module_ntp_server() {
    local src="any"
    if ask_yes_no "$(tr ntp_restrict)"; then
        while true; do
            read -r -p "$(tr ntp_source)" src
            if validate_source "$src" && [[ "$src" != "any" ]]; then
                break
            fi
            echo "$(tr invalid_source)"
        done
    fi
    run_ufw_allow "in" 123 udp "$src" "NTP server"
}

module_monitoring() {
    echo
    echo "$(tr monitoring_menu)"
    local msel
    msel=$(choose_multi "$(tr monitoring_title)" \
        "$(tr monitoring_node)" \
        "$(tr monitoring_snmp)" \
        "$(tr monitoring_grafana)" \
        "$(tr monitoring_zabbix)" \
        "$(tr monitoring_custom)")

    [[ -z "$msel" ]] && return 0

    local item src="any"
    if ask_yes_no "$(tr monitoring_restrict)"; then
        while true; do
            read -r -p "$(tr monitoring_source)" src
            if validate_source "$src" && [[ "$src" != "any" ]]; then
                break
            fi
            echo "$(tr invalid_source)"
        done
    fi

    for item in $msel; do
        case "$item" in
            1) run_ufw_allow "in" 9100 tcp "$src" "Prometheus Node Exporter" ;;
            2) run_ufw_allow "in" 161 udp "$src" "SNMP" ;;
            3) run_ufw_allow "in" 3000 tcp "$src" "Grafana" ;;
            4) run_ufw_allow "in" 10050 tcp "$src" "Zabbix Agent" ;;
            5) custom_ports_menu ;;
        esac
    done
}

#######################################
# Custom ports
#######################################
add_custom_rule_interactive() {
    local direction="$1"
    local port proto src comment

    while true; do
        read -r -p "$(tr port_prompt)" port
        [[ -z "$port" ]] && break

        if ! validate_port "$port"; then
            echo "$(tr invalid_port)"
            continue
        fi

        while true; do
            read -r -p "$(tr proto_prompt)" proto
            proto="${proto:-tcp}"
            if validate_proto "$proto"; then
                break
            fi
            echo "$(tr invalid_protocol)"
        done

        while true; do
            if [[ "$direction" == "in" ]]; then
                read -r -p "$(tr source_prompt_in)" src
            else
                read -r -p "$(tr source_prompt_out)" src
            fi
            src="${src:-any}"
            if validate_source "$src"; then
                break
            fi
            echo "$(tr invalid_source_target)"
        done

        read -r -p "$(tr comment_prompt)" comment
        comment="${comment:-custom ${direction} ${port}/${proto}}"

        run_ufw_allow "$direction" "$port" "$proto" "$src" "$comment"
    done
}

custom_ports_menu() {
    while true; do
        local csel
        csel=$(choose_single "$(tr custom_ports_menu)" \
            "$(tr custom_in)" \
            "$(tr custom_out)" \
            "$(tr back)")
        case "$csel" in
            1) add_custom_rule_interactive "in" ;;
            2) add_custom_rule_interactive "out" ;;
            3) break ;;
        esac
    done
}

#######################################
# Logging
#######################################
set_logging_level() {
    local lsel
    lsel=$(choose_single "$(tr logging_title)" \
        "off" \
        "low" \
        "medium" \
        "high" \
        "full")

    case "$lsel" in
        1) LOG_LEVEL="off" ;;
        2) LOG_LEVEL="low" ;;
        3) LOG_LEVEL="medium" ;;
        4) LOG_LEVEL="high" ;;
        5) LOG_LEVEL="full" ;;
    esac

    ufw logging "$LOG_LEVEL"
    add_rule_note "LOGGING $LOG_LEVEL"
}

#######################################
# Review
#######################################
show_summary() {
    echo
    echo "==========================================="
    echo "$(tr summary_title)"
    echo "==========================================="
    local item
    for item in "${RULES_APPLIED[@]}"; do
        echo "- $item"
    done
    echo "-------------------------------------------"
    echo "$(tr logging_level): $LOG_LEVEL"
    echo "-------------------------------------------"
}

#######################################
# Main menu
#######################################
main_modules_menu() {
    local selection item
    selection=$(choose_multi "$(tr modules_title)" \
        "$(tr module_web)" \
        "$(tr module_admin81)" \
        "$(tr module_mail)" \
        "$(tr module_dns)" \
        "$(tr module_ntp)" \
        "$(tr module_monitoring)" \
        "$(tr module_custom)")

    [[ -z "$selection" ]] && return 0

    for item in $selection; do
        case "$item" in
            1) module_webserver ;;
            2) module_admin81 ;;
            3) module_mail_out ;;
            4) module_dns_server ;;
            5) module_ntp_server ;;
            6) module_monitoring ;;
            7) custom_ports_menu ;;
        esac
    done
}

#######################################
# Run
#######################################
clear
select_language

echo "==========================================="
echo "   $(tr main_title)"
echo "==========================================="
echo
echo "$(tr warning_reset_1)"
echo "$(tr warning_reset_2)"
echo "$(tr warning_reset_3)"
echo

if ! ask_yes_no "$(tr continue_q)"; then
    echo "$(tr aborted)"
    exit 0
fi

apply_base_rules
main_modules_menu
set_logging_level
show_summary

echo
if ! ask_yes_no "$(tr apply_enable_q)"; then
    echo "$(tr aborted) $(tr rules_left_local)"
    echo "$(tr check_manual)"
    exit 0
fi

echo
echo "$(tr enabling)"
ufw --force enable

echo
echo "-------------------------------------------"
ufw status numbered
echo "-------------------------------------------"
ufw status verbose
echo "-------------------------------------------"
echo "$(tr done)"
