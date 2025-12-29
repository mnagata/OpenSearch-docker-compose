if [ ! -e '/check' ]; then
    touch /check
    bin/opensearch-plugin install analysis-icu
    bin/opensearch-plugin install analysis-kuromoji
    echo "セットアップ"
else
    echo "セットアップ済"
fi