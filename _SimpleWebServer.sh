#!/bin/bash

URL="127.0.0.1:8080"
IP="${URL%%:*}"
PORT="${URL#*:}"
EXECUTABLE_NAME="_SimpleWebServer.sh"
LOG_FILE="_php_server_output.log"
t=1
first_page="index.html"
browser="firefox" # google-chrome

# checa as dependências
check_dependencies() {
    for dep in php lsof xterm firefox; do
        if ! command -v $dep > /dev/null 2>&1; then
            echo ":: $dep não encontrado. Instalando $dep..."
            sudo apt install $dep -y || { echo "Falha ao instalar $dep. Saindo..."; exit 1; }
        fi
    done
}

# mata processos PHP pré-existentes
kill_processes() {
    echo "Verificando e matando o processo $EXECUTABLE_NAME..."

    # Verificando o PID do processo _SimpleWebServer.sh
    PID=$(ps aux | grep "$EXECUTABLE_NAME" | grep -v grep | grep -v "$0" | awk '{print $2}')
    echo "PID encontrado para $EXECUTABLE_NAME: $PID"

    if [ -n "$PID" ]; then
        echo "Matando o processo com PID $PID..."
        kill $PID
        echo "Processo $EXECUTABLE_NAME (PID: $PID) morto com sucesso."
    else
        echo "Nenhum processo encontrado para matar."
    fi

    echo "Verificando e matando processos relacionados ao endereço $URL..."
    PIDS_PHP=$(lsof -t -iTCP:$PORT -sTCP:LISTEN)

    for PID in $PIDS_PHP; do
        PROCESS_INFO=$(netstat -tuln | grep ":$PORT" | grep $IP)
        echo "Verificando o processo escutando em $URL: $PROCESS_INFO"
        if [[ -n "$PROCESS_INFO" ]]; then
            echo "Matando processo com PID $PID que está escutando em $URL..."
            kill -9 $PID
            echo "Processo com PID $PID foi encerrado."
        else
            echo "Nenhum processo encontrado escutando em $URL."
        fi
    done
}

# inicia o servidor PHP
start_php_server() {
    echo "Iniciando o servidor PHP..."
    php -S $IP:$PORT -t $PWD > $LOG_FILE 2>&1 &
    PHP_PID=$!  # Pega o PID do processo PHP
    echo "Servidor PHP iniciado com PID $PHP_PID"
    sleep $t
    PIDS_PHP=$(lsof -t -i:$PORT)
    if [ -z "$PIDS_PHP" ]; then
        echo "Erro: O servidor PHP não está escutando na porta $URL"
        exit 1
    else
        echo "Servidor PHP está escutando na porta $URL."
    fi
    echo "PID do servidor PHP: $PHP_PID" >> $LOG_FILE
}

monitor_log() {
    echo "Iniciando monitoramento do log..."
    tail -f $LOG_FILE &
    TAIL_PID=$!  # Salva o PID do processo tail
    echo "Monitoramento do log iniciado (PID: $TAIL_PID)."
}

stop_log_monitoring() {
    echo "Encerrando monitoramento do log..."
    if [ -n "$TAIL_PID" ]; then
        kill $TAIL_PID 2>/dev/null
        echo "Monitoramento do log encerrado."
    else
        echo "Nenhum processo de log para encerrar."
    fi
}

cleanup() {
    echo "Encerrando monitoramento e processos..."

    stop_log_monitoring # Encerra o monitoramento do log

    pkill -P $$ 2>/dev/null # Mata todos os subprocessos iniciados pelo script

    echo "Todos os subprocessos encerrados. Saindo..."
    exit
}


# monitora alterações e atualizar o servidor PHP
monitor_changes() {
    monitor_log # Inicia o monitoramento do log
}

sanitize() {
    echo "Inicializando o ambiente..."
    kill_processes  # Encerra processos antigos
    if [ -f "$LOG_FILE" ]; then
        > "$LOG_FILE"  # Limpa logs antigos
        echo "Logs antigos limpos."
    else
        echo "Arquivo de log não encontrado, criando um novo..."
        touch "$LOG_FILE"
    fi
    echo "Ambiente sanitizado."
}

start_browser() {
    $browser $URL/$first_page
}


main() {
    trap cleanup SIGINT SIGTERM # Configura a limpeza em caso de interrupção

    check_dependencies # verifica dependências

    sanitize # remove a chamada para matar processos temporariamente

    start_php_server # iniciar servidor PHP

    start_browser # invoca o browser

    sleep $t # aguarda t segundos

    monitor_changes # monitora alterações
}

# verifica se o script foi iniciado no xterm
if [[ -z "$TERMINAL_EXECUTED" ]]; then
    export TERMINAL_EXECUTED=1
    xterm -geometry 110x10+0+0 -hold -e "bash $PWD/$EXECUTABLE_NAME"
    exit 0
fi

# invoca a função principal
main



# caso queira manter o apache2 instalado, mas evitar incialização automática:

# sudo update-rc.d apache2 disable
# sudo update-rc.d -f apache2 remove
# sudo systemctl status apache2
# sudo systemctl is-enabled apache2
# sudo systemctl disable apache2
# sudo systemctl stop apache2
# sudo systemctl mask apache2
