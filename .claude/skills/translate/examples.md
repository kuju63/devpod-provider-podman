# Translation Examples

These examples demonstrate the expected quality and structure preservation for translations.

## 1. README Structure Preservation

### English (README.md)

```markdown
## Usage

How to use the Podman provider with DevPod.

### Installation

1. Install DevPod
2. Add the provider

### Configuration

Configure the provider options.
```

### Japanese (README.ja.md)

```markdown
## 使い方

DevPodでPodmanプロバイダーを使用する方法です。

### インストール

1. DevPodをインストール
2. プロバイダーを追加

### 設定

プロバイダーオプションを設定します。
```

**Key points**:
- Section headings translated
- Same structure maintained
- Numbered lists preserved

## 2. Code Block Preservation

Code blocks must be IDENTICAL in both versions.

### English

```markdown
Run the following command:

```bash
devpod provider add ./provider.yaml
devpod provider use podman
```

This will register the provider.
```

### Japanese

```markdown
以下のコマンドを実行します：

```bash
devpod provider add ./provider.yaml
devpod provider use podman
```

これによりプロバイダーが登録されます。
```

**Key points**:
- Code block is IDENTICAL
- Only surrounding text is translated
- Command names remain in English

## 3. Technical Term Application

### Software Development Terms

| Context | English | Japanese | Reason |
|---------|---------|----------|--------|
| Proper noun | Docker | Docker | Keep unchanged |
| Acronym | OCI | OCI | Keep acronym |
| Technical term | container | コンテナ | Use glossary |
| Technical term | workspace | ワークスペース | Use glossary |
| Code identifier | `provider.yaml` | `provider.yaml` | Keep unchanged |

### Example Sentences

**English**: "The provider manages Docker containers using the OCI runtime."
**Japanese**: "プロバイダーはOCIランタイムを使用してDockerコンテナを管理します。"

**English**: "Configure the workspace in `provider.yaml`."
**Japanese**: "`provider.yaml`でワークスペースを設定します。"

## 4. Link Handling

### Internal Links to Language-Specific Files

**English (README.md)**:
```markdown
[日本語版はこちら](README.ja.md)

See the [test guide](tests/README.md) for details.
```

**Japanese (README.ja.md)**:
```markdown
[English version](README.md)

詳細は[テストガイド](tests/README.ja.md)を参照してください。
```

**Key points**:
- Language selector links updated
- Content-specific links point to translated versions
- External URLs remain unchanged

## 5. Table Translation

### English

| Feature | Description | Status |
|---------|-------------|--------|
| Automatic startup | Start machine automatically | ✅ Supported |
| Resource configuration | CPU and memory settings | ✅ Supported |

### Japanese

| 機能 | 説明 | ステータス |
|-----|------|---------|
| 自動起動 | Machineを自動的に起動 | ✅ サポート済み |
| リソース設定 | CPUとメモリの設定 | ✅ サポート済み |

**Key points**:
- Table structure preserved
- Headers translated
- Technical terms use glossary
- Emojis preserved

## 6. DevOps/CI/CD Terminology

### Example: GitHub Actions Documentation

**English**:
```markdown
## GitHub Actions Integration

The workflow triggers on pull requests and runs code review automatically.

Configure the pipeline in `.github/workflows/claude-code-review.yml`.
```

**Japanese**:
```markdown
## GitHub Actions統合

ワークフローはプルリクエスト時にトリガーされ、コードレビューを自動的に実行します。

`.github/workflows/claude-code-review.yml`でパイプラインを設定します。
```

**Key points**:
- "GitHub Actions" unchanged
- "workflow" → "ワークフロー"
- "pull requests" → "プルリクエスト"
- "pipeline" → "パイプライン"
- File path unchanged

## 7. Container Technology Terminology

### Example: Docker/Podman Documentation

**English**:
```markdown
## Container Management

Podman manages OCI-compliant containers in rootless mode. The daemon runs without root privileges.

### Image Management

Pull images from registries and manage volumes.
```

**Japanese**:
```markdown
## コンテナ管理

PodmanはrootlessモードでOCI準拠のコンテナを管理します。デーモンはroot権限なしで実行されます。

### イメージ管理

レジストリからイメージをpullし、ボリュームを管理します。
```

**Key points**:
- "Podman", "OCI" unchanged (proper nouns/acronyms)
- "containers" → "コンテナ"
- "rootless mode" → "rootlessモード"
- "daemon" → "デーモン"
- "pull" unchanged (git/container command)
- "images" → "イメージ"
- "volumes" → "ボリューム"
