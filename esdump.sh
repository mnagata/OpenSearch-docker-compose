#!/bin/bash

# .env読み込み
source ./.env

# OpenSearchの自己証明書対応
export NODE_TLS_REJECT_UNAUTHORIZED=0

function backup () {
    local -r idx_name="$1"
    local -r enc_passwords=$(echo $OPENSEARCH_INITIAL_ADMIN_PASSWORD | jq -Rr '@uri')
    local -r in="https://admin:${enc_passwords}@${OPENSEARCH_HOST}:${OPENSEARCH_PORT}/${idx_name}"

    echo $in

    elasticdump \
        --input="$in" \
        --output="${DUMP_DIR}/${idx_name}_index.json" \
        --type=index

    elasticdump \
        --type=data \
        --input="$in" \
        --output="${DUMP_DIR}/${idx_name}.json" \
        --limit=6000
}

function print_usage () {
    echo "usage: $0 <index-name>"
}

function main () {
    ## Arg parsing
    ##
    if [ -z ${1+x} ] || [[ ${1} = *"help"* ]]
    then
        print_usage
        exit 1
    fi

    backup "$1"
}

main "${@}"