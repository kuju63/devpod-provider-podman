# DevPod Podman Provider

DevPod向けのPodmanプロバイダー実装 / Podman Provider for DevPod

## 概要

このプロジェクトは、[DevPod](https://devpod.sh/)向けのPodmanコンテナエンジン用プロバイダーを提供します。DevPodはクライアントサイドで動作するオープンソースの開発環境管理ツールで、このプロバイダーを使用することでPodmanコンテナを使った開発ワークスペースを管理できます。

## ステータス

✅ **Phase 2完成** - 自動Machine管理とリソース設定機能を含む完全版が動作します。

**機能:**
- Podmanコンテナでの開発環境作成
- macOSでのPodman Machine自動管理
- リソース設定（CPU、メモリ、ディスク）のカスタマイズ
- 非アクティブタイムアウトによる自動停止

## 前提条件

### macOS

1. **Podmanのインストール**:
   ```bash
   brew install podman
   ```

2. **DevPod CLIのインストール**:
   ```bash
   brew install devpod
   ```

**注意**: Podman Machineの初期化と起動は、デフォルトで自動的に行われます（`PODMAN_MACHINE_AUTO_START=true`）。初回実行時にMachineを自動作成したい場合は、`PODMAN_MACHINE_AUTO_INIT=true`を設定してください。

## 使い方

### プロバイダーの追加

#### ローカル開発版
```bash
cd /path/to/podman-provider
devpod provider add ./provider.yaml
devpod provider use podman
```

#### GitHub経由（公開後）
```bash
devpod provider add https://github.com/kuju63/devpod-provider-podman
devpod provider use podman
```

### ワークスペースの作成
```bash
# サンプルリポジトリで試す
devpod up https://github.com/loft-sh/devpod-example-go --provider podman

# 自分のリポジトリを使う
devpod up https://github.com/your/repository --provider podman
```

### ワークスペースへの接続
```bash
devpod ssh <workspace-name>
```

### ワークスペースの削除
```bash
devpod delete <workspace-name>
```

## 設定オプション

### 基本オプション

| オプション | 説明 | デフォルト値 |
|-----------|------|-------------|
| `PODMAN_PATH` | Podmanバイナリのパス | `podman` |
| `INACTIVITY_TIMEOUT` | 非アクティブ時の自動停止時間（例: 10m, 1h） | なし |

### Machine管理（macOSのみ）

| オプション | 説明 | デフォルト値 |
|-----------|------|-------------|
| `PODMAN_MACHINE_AUTO_START` | 停止中のMachineを自動起動 | `true` |
| `PODMAN_MACHINE_AUTO_INIT` | Machine未作成時に自動作成 | `false` |
| `PODMAN_MACHINE_NAME` | 使用するMachine名（空白で自動検出） | 自動検出 |
| `PODMAN_MACHINE_START_TIMEOUT` | 起動タイムアウト（秒） | `60` |

### Machineリソース設定（作成時のみ適用）

| オプション | 説明 | デフォルト値 |
|-----------|------|-------------|
| `PODMAN_MACHINE_CPUS` | CPU数 | `2` |
| `PODMAN_MACHINE_MEMORY` | メモリ（MB） | `4096` |
| `PODMAN_MACHINE_DISK_SIZE` | ディスク（GB） | `100` |
| `PODMAN_MACHINE_ROOTFUL` | rootfulモード（特権操作許可、低セキュリティ） | `false` |

### オプションの設定例

```bash
# 基本設定
devpod provider set-options podman PODMAN_PATH=/opt/homebrew/bin/podman

# 完全自動化の有効化
devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true

# リソース設定（次回Machine作成時に適用）
devpod provider set-options podman \
  PODMAN_MACHINE_CPUS=4 \
  PODMAN_MACHINE_MEMORY=8192 \
  PODMAN_MACHINE_DISK_SIZE=200
```

## 自動Machine管理（macOS）

このプロバイダーは、macOSでPodman Machineを自動的に管理します：

### デフォルト動作

- **自動起動**: 停止中のMachineを自動起動（`PODMAN_MACHINE_AUTO_START=true`）
- **手動作成**: Machine未作成時はエラー表示（`PODMAN_MACHINE_AUTO_INIT=false`）

### 完全自動化

初回実行時にMachineを自動作成したい場合:

```bash
devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true
```

この設定により、Podman Machineの手動セットアップが不要になります。

### Machine名の指定

複数のMachineを使い分ける場合:

```bash
devpod provider set-options podman PODMAN_MACHINE_NAME=my-machine
```

指定しない場合は、最初に見つかったMachineを自動的に使用します。

## リソース設定

### 用途別推奨設定

**軽量開発（フロントエンドなど）:**
```bash
devpod provider set-options podman \
  PODMAN_MACHINE_CPUS=2 \
  PODMAN_MACHINE_MEMORY=2048 \
  PODMAN_MACHINE_DISK_SIZE=50
```

**標準開発（バックエンド、フルスタック）:**
```bash
devpod provider set-options podman \
  PODMAN_MACHINE_CPUS=4 \
  PODMAN_MACHINE_MEMORY=4096 \
  PODMAN_MACHINE_DISK_SIZE=100
```

**ヘビー開発（ビルド、マルチサービス）:**
```bash
devpod provider set-options podman \
  PODMAN_MACHINE_CPUS=8 \
  PODMAN_MACHINE_MEMORY=8192 \
  PODMAN_MACHINE_DISK_SIZE=200
```

### リソース変更方法

リソース設定は**Machine作成時のみ適用**されます。既存Machineのリソースを変更するには、Machineを再作成する必要があります:

```bash
# 1. オプションを設定
devpod provider set-options podman PODMAN_MACHINE_MEMORY=8192

# 2. 既存のMachineを削除
podman machine stop
podman machine rm

# 3. 新しいMachineを作成（次回のdevpod up時に自動作成）
devpod up <your-repo> --provider podman
```

**注意**: 自動作成（`AUTO_INIT=true`）を有効にしている場合、Machine削除後に次回の`devpod up`で新しい設定が適用されたMachineが自動作成されます。

## トラブルシューティング

### "No Podman Machine found" エラー

**原因**: Podman Machineが作成されていない（macOS）

**解決方法1 - 手動作成**:
```bash
podman machine init
podman machine start
```

**解決方法2 - 自動作成の有効化**:
```bash
devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true
```

### "Podman Machine is not running" エラー

**原因**: Machineが停止している

**解決方法1 - 手動起動**:
```bash
podman machine start
```

**解決方法2 - 自動起動の有効化（デフォルトで有効）**:
```bash
devpod provider set-options podman PODMAN_MACHINE_AUTO_START=true
```

### "Machine start timed out" エラー

**原因**: Machineの起動に時間がかかっている

**解決方法**:
```bash
# タイムアウトを120秒に延長
devpod provider set-options podman PODMAN_MACHINE_START_TIMEOUT=120
```

**診断**:
```bash
# Machine の状態確認
podman machine list
podman machine inspect <machine-name>

# 手動起動でログ確認
podman machine start <machine-name>
```

### Machine作成/起動が失敗する

**解決方法**:
```bash
# 既存のMachineを削除して再作成
podman machine stop
podman machine rm

# 手動で再作成
podman machine init
podman machine start

# または自動作成に任せる
devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true
devpod up <your-repo> --provider podman
```

### 複数Machineの管理

複数のPodman Machineを使い分ける場合:

```bash
# Machine一覧表示
podman machine list

# 特定のMachineを指定
devpod provider set-options podman PODMAN_MACHINE_NAME=my-machine

# デフォルトに戻す（自動検出）
devpod provider set-options podman PODMAN_MACHINE_NAME=""
```

## 機能

### Phase 2 - 自動Machine管理とリソース設定
- ✅ macOSでのPodman Machine自動起動
- ✅ Machine自動作成（オプション）
- ✅ リソース設定（CPU、メモリ、ディスク）
- ✅ rootful/rootlessモードの選択
- ✅ 詳細なエラーメッセージとガイダンス

### Phase 1 - 基本機能
- ✅ Podmanコンテナでの開発環境作成と管理
- ✅ Docker互換モードでの動作
- ✅ DevPodの標準機能サポート
- ✅ 非アクティブタイムアウトによる自動停止

## ライセンス

このプロジェクトは[Apache License 2.0](LICENSE)の下でライセンスされています。

## 参考リンク

- [DevPod公式サイト](https://devpod.sh/)
- [DevPod Provider開発ガイド](https://devpod.sh/docs/developing-providers/quickstart)
- [Podman公式サイト](https://podman.io/)

## 開発

プロジェクトへの貢献を歓迎します。詳細は[CLAUDE.md](CLAUDE.md)を参照してください。

新しい機能やプラットフォームのサポートを追加する際は、必ずGitHub Issueを作成してissue駆動開発を行ってください。
