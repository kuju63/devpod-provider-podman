# DevPod Podman Provider

DevPod向けのPodmanプロバイダー実装 / Podman Provider for DevPod

## 概要

このプロジェクトは、[DevPod](https://devpod.sh/)向けのPodmanコンテナエンジン用プロバイダーを提供します。DevPodはクライアントサイドで動作するオープンソースの開発環境管理ツールで、このプロバイダーを使用することでPodmanコンテナを使った開発ワークスペースを管理できます。

## ステータス

🚧 **開発初期段階** - 現在、プロバイダー設定（`provider.yaml`）を実装中です。

## 要件

- [Podman](https://podman.io/) - コンテナエンジン
- [DevPod CLI](https://devpod.sh/docs/getting-started/install) - DevPodコマンドラインツール

## インストール

プロバイダーの実装が完了したら、以下のコマンドでDevPodに追加できます：

```bash
devpod provider add https://github.com/kuju63/devpod-provider-podman
```

## 機能

- Podmanコンテナを使用した開発環境の作成と管理
- Docker互換モードでの動作
- DevPodの標準機能（ワークスペース作成、削除、コマンド実行など）のサポート

## ライセンス

このプロジェクトは[Apache License 2.0](LICENSE)の下でライセンスされています。

## 参考リンク

- [DevPod公式サイト](https://devpod.sh/)
- [DevPod Provider開発ガイド](https://devpod.sh/docs/developing-providers/quickstart)
- [Podman公式サイト](https://podman.io/)

## 開発

プロジェクトへの貢献を歓迎します。詳細は[CLAUDE.md](CLAUDE.md)を参照してください。

新しい機能やプラットフォームのサポートを追加する際は、必ずGitHub Issueを作成してissue駆動開発を行ってください。
