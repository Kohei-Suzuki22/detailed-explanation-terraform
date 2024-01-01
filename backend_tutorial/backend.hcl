# backendの共通の設定をこのファイルに抽出する。


# tfstateファイルを置くs3バケットを指定
bucket = "hello-terraform-remote-state"
region = "ap-northeast-1"
# lockを管理するdynamo_tableを指定
dynamodb_table = "hello-terraform-remote-state-locks"
encrypt = true