# DevPod Podman Provider - テストスイート

このディレクトリには、Phase 2実装のテストスクリプトが含まれています。

## テストスクリプト

### 1. `test_init_script.sh`
初期化スクリプトの基本動作をテストします。

**テスト内容:**
- Podmanバイナリの存在確認
- Podmanバージョン取得
- プラットフォーム検出（macOS/Linux）
- Machine名の自動検出
- Machine状態確認
- 接続テスト

**実行方法:**
```bash
cd tests
chmod +x test_init_script.sh
./test_init_script.sh
```

**期待される結果:**
- すべてのチェックマーク（✓）が表示される
- エラーなく完了

### 2. `integration_test.sh`
DevPodプロバイダーとしての統合テストを実行します。

**テスト内容:**
- プロバイダー登録
- オプション一覧の確認
- カスタムオプション設定
- オプション値の検証
- クリーンアップ

**実行方法:**
```bash
cd tests
chmod +x integration_test.sh
./integration_test.sh
```

**期待される結果:**
- 4つのテストすべてが成功（✓）
- クリーンアップ完了

### 3. `test_mismatch_detection.sh`
リソース設定の不一致検出ロジックをテストします（Phase 3追加）。

**テスト内容:**
- CPU設定の不一致検出
- メモリ設定の不一致検出
- ディスクサイズの不一致検出
- rootfulモード設定の不一致検出
- 複数の不一致同時検出
- 設定が一致する場合の判定
- rootful値の正規化（true/false/1の正規化）

**実行方法:**
```bash
cd tests
chmod +x test_mismatch_detection.sh
./test_mismatch_detection.sh
```

**期待される結果:**
- すべてのテストが成功（✓ 7/7）
- 各テストで正しく不一致/一致を検出

## 前提条件

テストを実行する前に、以下がインストールされている必要があります：

- **Podman**: `brew install podman`
- **DevPod**: `brew install devpod`
- **macOS**: Podman Machine機能をテストするため（Linuxでも基本テストは動作）

## テスト環境

テストは以下の環境で検証済みです：

- macOS (Darwin)
- Podman 5.x以降
- DevPod 0.5.x以降

## トラブルシューティング

### テストが失敗する場合

1. **Podman Machineが起動していない**
   ```bash
   podman machine start
   ```

2. **古いテストプロバイダーが残っている**
   ```bash
   devpod provider delete podman-phase2-test
   ```

3. **権限エラー**
   ```bash
   chmod +x tests/*.sh
   ```

## CI/CD統合

これらのテストは、GitHub ActionsなどのCI/CDパイプラインに統合できます。

```yaml
# .github/workflows/test.yml の例
- name: Run tests
  run: |
    chmod +x tests/*.sh
    ./tests/test_init_script.sh
    ./tests/integration_test.sh
```

## 手動テストシナリオ

自動化されたテストに加えて、以下のシナリオも手動でテストすることを推奨します：

### TS1: Machine未作成環境
```bash
# Machineを削除
podman machine stop
podman machine rm

# AUTO_INIT=false（デフォルト）でエラーメッセージ確認
devpod provider add ./provider.yaml

# AUTO_INIT=trueで自動作成
devpod provider set-options podman -o PODMAN_MACHINE_AUTO_INIT=true
```

### TS2: カスタムリソース設定
```bash
devpod provider set-options podman \
  -o PODMAN_MACHINE_CPUS=4 \
  -o PODMAN_MACHINE_MEMORY=8192 \
  -o PODMAN_MACHINE_DISK_SIZE=200 \
  -o PODMAN_MACHINE_AUTO_INIT=true

# Machineを再作成
podman machine rm
devpod up <test-repo> --provider podman

# リソース確認
podman machine inspect
```

### TS3: 停止中Machine自動起動
```bash
# Machineを停止
podman machine stop

# DevPodでワークスペース作成（自動起動される）
devpod up <test-repo> --provider podman
```

### TS4: 複数Machine環境
```bash
# 複数のMachineを作成
podman machine init machine1
podman machine init machine2

# 特定のMachineを指定
devpod provider set-options podman -o PODMAN_MACHINE_NAME=machine1
```

### TS5: タイムアウトテスト
```bash
# 短いタイムアウトを設定
devpod provider set-options podman -o PODMAN_MACHINE_START_TIMEOUT=5

# Machineを停止して起動テスト
podman machine stop
devpod up <test-repo> --provider podman
```

### TS6: rootfulモード
```bash
# rootfulモードでMachine作成
devpod provider set-options podman \
  -o PODMAN_MACHINE_ROOTFUL=true \
  -o PODMAN_MACHINE_AUTO_INIT=true

# Machine削除後に再作成
podman machine rm
devpod up <test-repo> --provider podman

# rootful設定確認
podman machine inspect | grep -i rootful
```

### TS7: リソース設定変更警告（Phase 3追加）
```bash
# 前提：既存のMachineがCPU=2, Memory=2048で稼働中

# リソース設定を変更（AUTO_INIT=falseのため警告を表示）
devpod provider set-options podman \
  -o PODMAN_MACHINE_CPUS=8 \
  -o PODMAN_MACHINE_MEMORY=4096

# ワークスペース起動時に警告が表示される
devpod up <test-repo> --provider podman

# 期待される警告メッセージ：
# ⚠️  WARNING: Machine resource configuration mismatch detected
# Configuration differences:
#   • CPUs: Current=2, Desired=8
#   • Memory: Current=2048MB, Desired=4096MB
```

### TS8: 新規Machine作成時の警告非表示（Phase 3追加）
```bash
# Machineを削除
podman machine stop
podman machine rm

# AUTO_INIT有効化
devpod provider set-options podman \
  -o PODMAN_MACHINE_AUTO_INIT=true \
  -o PODMAN_MACHINE_CPUS=8 \
  -o PODMAN_MACHINE_MEMORY=4096

# ワークスペース起動時に新規Machine作成
devpod up <test-repo> --provider podman

# 期待される動作：
# - 新規Machine作成（警告なし）
# - 作成時に指定リソース（CPU=8, Memory=4096）が適用される
```

## レポート

テスト結果は標準出力に表示されます。エラーが発生した場合は、詳細なエラーメッセージとガイダンスが表示されます。
