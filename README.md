# OpenSearch-docker-compose

Docker イメージによる OpenSearch 環境構築

## 環境構築

### .env ファイル設定

```
# OpenSearchのADMINパスワード、暗号強度の高いパスワードでないと起動できない。
OPENSEARCH_INITIAL_ADMIN_PASSWORD=<admin password>

# OpenSearchホスト名
OPENSEARCH_HOST=localhost

# OpenSearchポート番号
OPENSEARCH_PORT=9200

# elasticdumpスクリプト用 インデックスダンプデータ格納先
DUMP_DIR=./dump
```

### OpenSearch 起動

```

# 2ノード + ダッシュボード
$ docker-compose -f docker-compose.cluster.yml up -d

# 1ノード + ダッシュボード
$ docker-compose -f docker-compose.single.yml up -d

# 1ノード単体
$ docker-compose -f docker-compose.small.yml up -d

# 1ノード + ダッシュボード 開発環境
$ docker-compose -f docker-compose.dev.yml up -d

```

### OpenSearch 起動確認

```
# 標準環境
$ curl -XGET https://localhost:9200 -u 'admin:<OPENSEARCH_INITIAL_ADMIN_PASSWORD>' --insecure

# 開発環境
$ curl -XGET http://localhost:9200

```

### Dashboards を表示

```
http://localhost:5601
```

## OpenSearch にカスタムモデルをデプロイする

docker-compose.e5-large.yml で構築した OpenSearch のダッシュボードのコンソールで作業

```
# セマンティック検索を実行できるようにクラスタ設定を更新
PUT _cluster/settings
{
    "persistent": {
      "plugins": {
        "ml_commons": {
          "only_run_on_ml_node": "false",
          "model_access_control_enabled": "true",
          "native_memory_threshold": "99",
          "rag_pipeline_feature_enabled": "true",
          "memory_feature_enabled": "true",
          "allow_registering_model_via_local_file": "true",
          "allow_registering_model_via_url": "true",
          "model_auto_redeploy.enable":"true",
          "model_auto_redeploy.lifetime_retry_times": 10
        }
      }
    }
}

# モデルグループの登録
POST /_plugins/_ml/model_groups/_register
{
  "name": "local_model_group",
  "description": "A model group for local models"
}
res:
{
  "model_group_id": <モデルグループID>,
  "status": "CREATED"
}

# モデルの登録
POST /_plugins/_ml/models/_register
{
    "name": "intfloat/multilingual-e5-large-instruct-v1",
    "version": "1.0.0",
    "model_group_id": "<モデルグループID>",
	"description": "This is a multilingual-e5-large-instruct model: It maps sentences & paragraphs to a 1024 dimensional dense vector space and can be used for tasks like clustering or semantic search.",
    "model_task_type": "TEXT_EMBEDDING",
    "model_format": "ONNX",
    "model_content_size_in_bytes": 1313606304,
    "model_content_hash_value": "1e8fa78f6425f19fe93954998e216b52512758f9411f8d8cd14a00cbb0981515",
    "model_config": {
        "pooling_mode": "mean",
        "normalize_result": "true",
        "model_type": "xlm-roberta",
        "embedding_dimension": 1024,
        "framework_type": "huggingface_transformers",
        "all_config": "{\"_name_or_path\": \"intfloat/multilingual-e5-large-instruct\", \"architectures\": [\"XLMRobertaModel\"], \"attention_probs_dropout_prob\": 0.1,\"bos_token_id\": 0, \"classifier_dropout\": null, \"eos_token_id\": 2, \"export_model_type\": \"transformer\",\"hidden_act\": \"gelu\",\"hidden_dropout_prob\": 0.1,\"hidden_size\": 1024,\"initializer_range\": 0.02, \"intermediate_size\": 4096,\"layer_norm_eps\": 1e-05, \"max_position_embeddings\": 514,\"model_type\": \"xlm-roberta\", \"num_attention_heads\": 16,\"num_hidden_layers\": 24, \"output_past\": true,\"pad_token_id\": 1,\"position_embedding_type\": \"absolute\", \"torch_dtype\": \"float16\", \"transformers_version\": \"4.39.3\", \"type_vocab_size\": 1, \"use_cache\": true, \"vocab_size\": 250002 }"
    },
    "created_time": 1676072210947,
    "url":"http://fastapi_for_model/get_file/model/multilingual-e5-large-instruct_v1.zip"
}
res:
{
  "task_id": "<タスクID>",
  "status": "CREATED"
}

# 登録ステータスを確認
GET /_plugins/_ml/tasks/<タスクID>
res:
{
  "model_id": "<モデルID>",
  "task_type": "REGISTER_MODEL",
  "function_name": "TEXT_EMBEDDING",
  "state": "COMPLETED",
  "worker_node": [
    "0Hic_MLcR1WQhLq3zCgMuw"
  ],
  "create_time": 1712552074058,
  "last_update_time": 1712552118631,
  "is_async": true
}

# モデルをデプロイ
POST /_plugins/_ml/models/<モデルID>/_deploy
res:
{
  "task_id": "<タスクID>",
  "task_type": "DEPLOY_MODEL",
  "status": "CREATED"
}

# Ingestionパイプラインの作成
PUT /_ingest/pipeline/nlp-e5-ingest-pipeline
{
  "description": "A text neural search pipeline",
  "processors": [
    {
      "text_embedding": {
        "model_id": "<モデルID>",
        "field_map": {
          "full_text": "vector_field"
        }
      }
    }
  ]
}
res:
{
  "acknowledged": true
}

#

```

## インデックス dump/restore

OpenSearch のインデックスのバックアップとレストアを行うシェルスクリプト

### 事前準備

elasticdump と jq コマンドをインストール  
https://github.com/elasticsearch-dump/elasticsearch-dump

.env に dump データの格納先を DUMP_DIR で指定

### インデックスをダンプ

```
# 標準環境
$ ./esdump.sh <インデックス名>

# 開発環境
$ ./esdump.dev.sh <インデックス名>

```

### インデックスをレストア

```
# 標準環境
$ ./esrestore.sh <インデックス名>

# 開発環境
$ ./esrestore.dev.sh <インデックス名>

```
