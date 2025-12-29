#!/bin/bash

# .env読み込み
source ./.env

# OpenSearchの自己証明書対応
export NODE_TLS_REJECT_UNAUTHORIZED=0

function restore () {
    local -r idx_name="$1"
    local -r enc_passwords=$(echo $OPENSEARCH_INITIAL_ADMIN_PASSWORD | jq -Rr '@uri')
    local -r out="https://admin:${enc_passwords}@${OPENSEARCH_HOST}:${OPENSEARCH_PORT}/${idx_name}"

    elasticdump \
        --input="${DUMP_DIR}/${idx_name}_index.json" \
        --output="$out" \
        --type=index

    elasticdump \
        --input="${DUMP_DIR}/${idx_name}.json" \
        --output="$out" \
        --limit=1000 \
        --type=data
}

function print_usage () {
    echo "usage: $0 <index-name>"
}

function main () {
    ## Arg parsing
    ##
    if [ -z ${1+x} ] || [[ ${1} = *"help"* ]]; then
        print_usage
        exit 1
    fi

    # Prepare
    #local -r idx_name="$1"
    #cp $DUMP_DIR/$idx_name* .
    #gzip -d $idx_name.json.gz

    # Restore
    restore "$1"
}

main "${@}"