# DevPod Podman Provider

DevPod向けのPodmanプロバイダー実装 / Podman Provider for DevPod

## 概要

このプロジェクトは、[DevPod](https://devpod.sh/)向けのPodmanコンテナエンジン用プロバイダーを提供します。DevPodはクライアントサイドで動作するオープンソースの開発環境管理ツールで、このプロバイダーを使用することでPodmanコンテナを使った開発ワークスペースを管理できます。

## ステータス

✅ **Phase 1 MVP完成** - 基本的なプロバイダー機能が動作します。

## 前提条件

### macOS

1. **Podmanのインストール**:
   ```bash
   brew install podman
   ```

2. **Podman Machineの初期化と起動**:
   ```bash
   podman machine init
   podman machine start
   ```

3. **DevPod CLIのインストール**:
   ```bash
   brew install devpod
   ```

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

| オプション | 説明 | デフォルト値 |
|-----------|------|-------------|
| PODMAN_PATH | Podmanバイナリのパス | `podman` |
| INACTIVITY_TIMEOUT | 非アクティブ時の自動停止時間（例: 10m, 1h） | なし |

オプションの設定例:
```bash
devpod provider set-options podman PODMAN_PATH=/opt/homebrew/bin/podman
```

## トラブルシューティング

### "Podman is not reachable" エラー

**原因**: Podman Machineが起動していない（macOS）

**解決方法**:
```bash
# Machineの状態確認
podman machine list

# Machineを起動
podman machine start

# 接続テスト
podman ps
```

### Podman Machineが起動しない

**解決方法**:
```bash
# 既存のMachineを削除して再作成
podman machine stop
podman machine rm
podman machine init
podman machine start
```

## 機能

- Podmanコンテナを使用した開発環境の作成と管理
- Docker互換モードでの動作
- DevPodの標準機能（ワークスペース作成、削除、コマンド実行など）のサポート
- 非アクティブタイムアウトによる自動コンテナ停止

## ライセンス

このプロジェクトは[Apache License 2.0](LICENSE)の下でライセンスされています。

## 参考リンク

- [DevPod公式サイト](https://devpod.sh/)
- [DevPod Provider開発ガイド](https://devpod.sh/docs/developing-providers/quickstart)
- [Podman公式サイト](https://podman.io/)

## 開発

プロジェクトへの貢献を歓迎します。詳細は[CLAUDE.md](CLAUDE.md)を参照してください。

新しい機能やプラットフォームのサポートを追加する際は、必ずGitHub Issueを作成してissue駆動開発を行ってください。
