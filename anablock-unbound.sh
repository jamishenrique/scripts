#!/bin/bash

# URL do arquivo na web
URL="https://api.anablock.net.br/domains/all?output=unbound"

# Nome do arquivo local
ARQUIVO_LOCAL="rpz.block.hosts.zone"

# Função para baixar o arquivo da web, extrair as informações dentro das aspas e adicionar ao arquivo local
baixar_e_adicionar() {
    conteudo=$(curl -s "$URL")  # Baixa o conteúdo do arquivo da web
    if [ $? -eq 0 ]; then
        # Extrai as informações dentro das aspas usando o comando awk
        while IFS= read -r linha; do
            dominio=$(echo "$linha" | awk -F'"' '{print $2}')
            if [ -n "$dominio" ]; then
                echo "*.$dominio CNAME ." >> "$ARQUIVO_LOCAL"
                echo "$dominio CNAME ." >> "$ARQUIVO_LOCAL"
            fi
        done <<< "$conteudo"
        echo "Registros adicionados com sucesso ao arquivo $ARQUIVO_LOCAL."
    else
        echo "Falha ao baixar o arquivo da web."
    fi
}

# Função para remover as informações após a linha ; RPZ manual block hosts
remover_apos_linha() {
    if grep -q "; RPZ manual block hosts" "$ARQUIVO_LOCAL"; then
        sed -i -e "/; RPZ manual block hosts/q" "$ARQUIVO_LOCAL"
        echo "Registros removidos após a linha ; RPZ manual block hosts."
    else
        echo "A linha ; RPZ manual block hosts não foi encontrada no arquivo $ARQUIVO_LOCAL."
    fi
}

# Verifica se o arquivo local já existe
if [ -f "$ARQUIVO_LOCAL" ]; then
    # Se existir, remove as informações após a linha ; RPZ manual block hosts e adiciona o conteúdo do arquivo da web
    remover_apos_linha
    baixar_e_adicionar
else
    # Se não existir, cria o arquivo local e adiciona o conteúdo do arquivo da web
    touch "$ARQUIVO_LOCAL"
    echo "\$TTL 2h" > "$ARQUIVO_LOCAL"
    echo "@ IN SOA localhost. root.localhost. (2 6h 1h 1w 2h)" >> "$ARQUIVO_LOCAL"
    echo "  IN NS  localhost." >> "$ARQUIVO_LOCAL"
    echo "; RPZ manual block hosts" >> "$ARQUIVO_LOCAL"
    baixar_e_adicionar
fi

/usr/sbin/unbound-control reload_keep_cache
