# スタートアップスクリプト
ConoHaで提供しているスタートアップスクリプトを公開しています。  
テンプレートで選択できるスクリプトの中身を確認することができます。  
詳しくは[こちら](https://www.conoha.jp/vps/function/startupscript/)をご確認ください。

## スクリプト一覧

|  名前  |  スクリプト  | 要編集 |
| -- | -- | -- |
| KUSANAGI初期設定(提供終了) | [setup_kusanagi.sh](./scripts/setup_kusanagi.sh) | - |
| オブジェクトストレージクライアント | [install_swift_client.yaml](./scripts/install_swift_client.yaml) | 「$API_USERNAME」を「APIユーザー名」<br/>「$API_TENANT_NAME」を「テナント名」<br/>「$API_PASSWORD」を「APIパスワード」<br>「$API_AUTH_URL」を「Identity Service」 |
| Let's Encrypt インストール | [setup_lamp_and_letsencrypt.sh](./scripts/setup_lamp_and_letsencrypt.sh) | 「$API_TENANT_ID」を「テナントID」<br/>「$API_USERNAME」を「APIユーザー名」<br/>「$API_PASSWORD」を「APIパスワード」<br>「$DOMAIN_NAME」を「設定したいドメイン」<br/>「$MAIL_ADDRESS」を「設定したいメールアドレス」|
| 追加ディスクセットアップ | [setup_external_storage.sh](./scripts/setup_external_storage.sh) |「$MOUNT_POINT」を「マウントしたいパス」 |
| Nextcloudインストール | [setup_nextcloud.sh](./scripts/setup_nextcloud.sh) | - |
| CentOSパッケージアップデート | [update_all_package_rpm.sh](./scripts/update_all_package_rpm.sh) | - |
