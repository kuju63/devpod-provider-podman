# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

DevPod向けのPodmanプロバイダー実装。DevPodはオープンソースのクライアントサイド開発環境管理ツールで、このプロバイダーはPodmanコンテナエンジンを利用してワークスペースを管理する。

## 開発ステータス

- ✅ **Phase 1完成** (v0.0.1): 基本的なプロバイダー機能
- ✅ **Phase 2完成** (v0.1.0): macOS Podman Machine自動管理とリソース設定
- ✅ **Phase 3完成**: リソース設定ミスマッチ警告
- ✅ **Phase 4完成** (v0.2.0): in-placeリソース更新（`podman machine set`対応）
- ✅ **v0.2.1リリース**: Machine名検出バグ修正（アスタリスク除去対応）

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

- **プラットフォーム差異**: macOSではPodman MachineのVM管理が必要、LinuxではコンテナDaemonへの直接接続
- **driver設定**: agent.driverは`docker`互換モードを使用（docker CLI互換）
- **Machine管理**: macOS環境では`exec.init`スクリプトで自動Machine管理を実装

### Phase 2で追加された機能

1. **オプション管理**:
   - `optionGroups`で3つのカテゴリに分類（Basic、Machine Management、Machine Resources）
   - 合計10個のオプション（Phase 1の2個 + Phase 2の8個）

2. **initスクリプトの拡張**:
   - プラットフォーム検出（`$OSTYPE`）
   - Machine名の自動検出または指定
   - Machine存在確認と自動作成
   - Machine状態確認と自動起動
   - タイムアウト付き起動待機ループ
   - 詳細なエラーメッセージとガイダンス

3. **リソース設定**:
   - CPU、メモリ、ディスクサイズの設定
   - rootful/rootlessモードの選択
   - 設定はMachine作成時のみ適用

4. **エラーハンドリング**:
   - 各エラー状態で手動解決方法と自動化オプションを提示
   - タイムアウト設定の調整ガイダンス

### Phase 3で追加された機能

1. **リソース設定ミスマッチ検出**:
   - Machine起動時に現在の設定と要求された設定を比較
   - CPU、メモリ、ディスクサイズ、rootfulモードの不一致を検出
   - 詳細な警告メッセージを表示

2. **ミスマッチ時の対応ガイダンス**:
   - 手動でのMachine再作成手順
   - DevPodを使った自動再作成手順
   - 設定値の確認とデバッグ情報

### Phase 4で追加された機能

1. **新オプション**:
   - `PODMAN_MACHINE_AUTO_RESOURCE_UPDATE` (デフォルト: `false`)
   - 有効化するとリソース設定を自動的にin-place更新

2. **非破壊的リソース更新**:
   - `podman machine set`コマンドを使用してMachine再作成を回避
   - Machine停止 → リソース更新 → Machine起動のフロー
   - データ損失なしでCPU、メモリ、ディスク、rootfulモードを更新可能

3. **改善された警告メッセージ**:
   - OPTION 1: `podman machine set`を使った非破壊的更新手順（推奨）
   - OPTION 2: 従来の破壊的な再作成手順
   - 実行可能なコマンド例を自動生成

4. **エラーハンドリングの強化**:
   - ディスクサイズ減少の試みを検出して警告（増加のみサポート）
   - 部分的な更新失敗に対する適切な処理
   - 更新前後の設定値を詳細にログ出力
   - Machine起動失敗時の明確なエラーメッセージ

## 参考リソース

- [DevPod Provider Quickstart](https://devpod.sh/docs/developing-providers/quickstart)
- [Provider Configuration](https://devpod.sh/docs/developing-providers/agent)
- [Provider Options](https://devpod.sh/docs/developing-providers/options)
