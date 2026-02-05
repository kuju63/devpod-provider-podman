# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

DevPod向けのPodmanプロバイダー実装。DevPodはオープンソースのクライアントサイド開発環境管理ツールで、このプロバイダーはPodmanコンテナエンジンを利用してワークスペースを管理する。

## 開発フロー

新しいプラットフォームやフィーチャーを追加する際は、必ずGitHub issueを作成してissue駆動開発を行う。

## リント

YAMLファイルのリントのみを使用：
```bash
# YAML lintコマンド（プロジェクト固有のコマンドはまだ未定義）
yamllint .
```

## DevPodプロバイダーの構造

DevPodプロバイダーは`provider.yaml`ファイルで定義される。主な構成要素：

### provider.yamlの主要セクション

1. **メタデータ**: name, version, description, icon（オプション）
2. **options**: ユーザーが設定可能なプロバイダーオプション（環境変数として渡される）
3. **agent**: プロバイダー設定（driver, inactivityTimeout, credentials injectionなど）
4. **binaries**: プロバイダー実行に必要な追加ヘルパーバイナリ
5. **exec**: DevPodが環境とやり取りするために実行するコマンド
   - `command`: 必須 - 環境内でコマンドを実行する方法を定義
   - `init`, `create`, `delete`: オプションコマンド

### Podman固有の考慮事項

Podmanはnon-machineプロバイダーとして実装される（VMではなくコンテナを直接操作）。
agent.driverは`docker`互換モードまたはPodman専用の実装を使用する可能性がある。

## 参考リソース

- [DevPod Provider Quickstart](https://devpod.sh/docs/developing-providers/quickstart)
- [Provider Configuration](https://devpod.sh/docs/developing-providers/agent)
- [Provider Options](https://devpod.sh/docs/developing-providers/options)
