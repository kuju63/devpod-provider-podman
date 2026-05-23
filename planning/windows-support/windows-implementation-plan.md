# Windows対応実装計画

## 実装の全体像

### 変更が必要なファイル

1. **provider.yaml** (lines 77-463: exec.init section)
   - プラットフォーム判定ロジックの追加
   - Windows環境でのMachine管理ロジックの適用
   - エラーメッセージのWindows対応

2. **README.md / README.ja.md**
   - Windows環境のPrerequisitesセクション追加
   - Configuration Optionsの説明更新

3. **AGENTS.md**
   - Platform-Specific Branchingセクションの更新
   - Windows-Specific Considerationsセクションの追加

4. **tests/** (新規作成)
   - `tests/test_windows_init.sh` - Windows環境用テストスクリプト
   - `tests/integration_test_windows.sh` - Windows統合テスト

## provider.yaml の詳細変更計画

### 変更箇所1: プラットフォーム判定ロジック (lines 94-96)

**現在のコード:**
```bash
# Podman Machine management (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Checking Podman Machine status..."
```

**変更後のコード:**
```bash
# Detect platform
PLATFORM="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  PLATFORM="darwin"
  echo "Detected platform: macOS"
elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
  PLATFORM="windows"
  echo "Detected platform: Windows (WSL2)"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  PLATFORM="linux"
  echo "Detected platform: Linux"
else
  >&2 echo "Warning: Unknown platform ($OSTYPE), assuming Linux"
  PLATFORM="linux"
fi

# Podman Machine management (macOS and Windows)
if [[ "$PLATFORM" == "darwin" ]] || [[ "$PLATFORM" == "windows" ]]; then
  echo "Checking Podman Machine status..."
```

**影響範囲:**
- 行数: 約15行増加
- 既存ロジックへの影響: 最小限（条件分岐の変更のみ）

### 変更箇所2: エラーメッセージのプラットフォーム対応 (lines 84-87)

**現在のコード:**
```bash
if ! command -v ${PODMAN_PATH} &> /dev/null; then
  >&2 echo "Error: Podman binary not found at '${PODMAN_PATH}'"
  >&2 echo "Please install Podman: brew install podman"
  >&2 echo "Or set PODMAN_PATH option to the correct location."
  exit 1
fi
```

**変更後のコード:**
```bash
if ! command -v ${PODMAN_PATH} &> /dev/null; then
  >&2 echo "Error: Podman binary not found at '${PODMAN_PATH}'"
  
  # Platform-specific installation instructions
  if [[ "$OSTYPE" == "darwin"* ]]; then
    >&2 echo "Please install Podman: brew install podman"
  elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
    >&2 echo "Please install Podman Desktop: https://podman-desktop.io/"
    >&2 echo "Or install Podman CLI: winget install RedHat.Podman"
  else
    >&2 echo "Please install Podman: https://podman.io/getting-started/installation"
  fi
  
  >&2 echo "Or set PODMAN_PATH option to the correct location."
  exit 1
fi
```

### 変更箇所3: Machine名のデフォルト値 (lines 112-113)

**現在のコード:**
```bash
echo "Creating new Podman Machine..."
MACHINE_NAME="devpod-machine"
```

**変更後のコード:**
```bash
echo "Creating new Podman Machine..."

# Platform-specific default machine name
if [[ "$PLATFORM" == "windows" ]]; then
  MACHINE_NAME="podman-machine-default"
else
  MACHINE_NAME="devpod-machine"
fi
```

**理由:**
- Windows版Podman Desktopはデフォルトで`podman-machine-default`を使用
- 既存のマシンとの競合を避けるため

### 変更箇所4: エラーメッセージの追加対応 (複数箇所)

以下の箇所でプラットフォーム別のメッセージを追加:

1. **Line 129-130**: Machine未作成時の手動作成手順
2. **Line 172**: Machine未起動時の手動起動手順
3. **Line 456-460**: Podman接続エラー時のメッセージ

**実装パターン:**
```bash
if [[ "$PLATFORM" == "darwin" ]]; then
  >&2 echo "macOS specific message"
elif [[ "$PLATFORM" == "windows" ]]; then
  >&2 echo "Windows specific message"
else
  >&2 echo "Linux specific message"
fi
```

### 変更箇所5: 条件分岐の終了 (line 448)

**現在のコード:**
```bash
    fi  # End of macOS-specific section
```

**変更後のコード:**
```bash
    fi  # End of Machine management section (macOS/Windows)
  else
    # Linux: Direct daemon connection (no Machine management)
    echo "Platform: Linux (native containers)"
  fi
```

## オプション定義の更新

### PODMAN_MACHINE_AUTO_START (line 35-37)

**現在:**
```yaml
PODMAN_MACHINE_AUTO_START:
  description: "Automatically start Podman Machine if it is stopped (macOS only)."
  default: "true"
```

**変更後:**
```yaml
PODMAN_MACHINE_AUTO_START:
  description: "Automatically start Podman Machine if it is stopped (macOS/Windows only)."
  default: "true"
```

### PODMAN_MACHINE_AUTO_INIT (line 39-41)

**現在:**
```yaml
PODMAN_MACHINE_AUTO_INIT:
  description: "Automatically initialize Podman Machine if it does not exist (macOS only)."
  default: "false"
```

**変更後:**
```yaml
PODMAN_MACHINE_AUTO_INIT:
  description: "Automatically initialize Podman Machine if it does not exist (macOS/Windows only)."
  default: "false"
```

## テストスクリプトの作成

### tests/test_windows_init.sh

```bash
#!/bin/bash
# Windows environment test script for Podman provider
set -e

echo "=== Windows Environment Test ==="
echo ""

# Simulate Windows environment
export OSTYPE="msys"
export PODMAN_PATH="podman"
export PODMAN_MACHINE_NAME=""
export PODMAN_MACHINE_AUTO_START="true"
export PODMAN_MACHINE_AUTO_INIT="false"
export PODMAN_MACHINE_START_TIMEOUT="60"
export PODMAN_MACHINE_CPUS="2"
export PODMAN_MACHINE_MEMORY="4096"
export PODMAN_MACHINE_DISK_SIZE="100"
export PODMAN_MACHINE_ROOTFUL="false"

# Test 1: Platform detection
echo "Test 1: Platform detection"
if [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
  PLATFORM="windows"
  echo "✓ Platform detected as Windows"
else
  echo "✗ Platform detection failed"
  exit 1
fi

# Test 2: Podman command availability
echo ""
echo "Test 2: Podman command availability"
if command -v ${PODMAN_PATH} &> /dev/null; then
  PODMAN_VERSION=$(${PODMAN_PATH} --version | awk '{print $3}')
  echo "✓ Podman found: version ${PODMAN_VERSION}"
else
  echo "⚠ Podman not found (expected in CI environment)"
fi

# Test 3: Machine name default
echo ""
echo "Test 3: Machine name default for Windows"
if [[ "$PLATFORM" == "windows" ]]; then
  DEFAULT_MACHINE_NAME="podman-machine-default"
  echo "✓ Default machine name: $DEFAULT_MACHINE_NAME"
else
  echo "✗ Platform is not Windows"
  exit 1
fi

echo ""
echo "=== All Windows-specific tests passed ==="
```

### tests/integration_test_windows.sh

```bash
#!/bin/bash
# Windows integration test script
set -e

echo "=== Windows Integration Test ==="
echo ""

# Prerequisites check
echo "Checking prerequisites..."

# Check if running on Windows
if [[ ! "$OSTYPE" == "msys"* ]] && [[ ! "$OSTYPE" == "cygwin"* ]]; then
  echo "⚠ Not running on Windows, skipping integration test"
  exit 0
fi

# Check Podman installation
if ! command -v podman &> /dev/null; then
  echo "✗ Podman not installed"
  echo "Please install Podman Desktop: https://podman-desktop.io/"
  exit 1
fi

echo "✓ Podman installed"

# Check DevPod installation
if ! command -v devpod &> /dev/null; then
  echo "✗ DevPod not installed"
  echo "Please install DevPod: winget install loft-sh.devpod"
  exit 1
fi

echo "✓ DevPod installed"

# Test scenarios
echo ""
echo "Running integration tests..."

# TS-W1: Check provider installation
echo ""
echo "TS-W1: Provider installation"
devpod provider list | grep -q "podman" && echo "✓ Provider installed" || echo "⚠ Provider not installed"

# TS-W2: Check Podman Machine status
echo ""
echo "TS-W2: Podman Machine status"
podman machine list

# TS-W3: Test workspace creation (dry-run)
echo ""
echo "TS-W3: Workspace creation test (dry-run)"
echo "Manual test required: devpod up <repo> --provider podman"

echo ""
echo "=== Integration test completed ==="
echo "Please run manual tests for full validation"
```

## ドキュメント更新計画

### README.md の変更

#### 1. Prerequisites セクションに Windows を追加 (after line 34)

```markdown
### Windows

1. **Enable WSL2**:
   ```powershell
   wsl --install
   ```
   Restart your computer after installation.

2. **Install Podman Desktop**:
   Download and install from [podman-desktop.io](https://podman-desktop.io/)
   
   Or install Podman CLI via winget:
   ```powershell
   winget install RedHat.Podman
   ```

3. **Install DevPod CLI**:
   ```powershell
   winget install loft-sh.devpod
   ```

**Note**: Podman Machine initialization and startup are handled automatically by default (`PODMAN_MACHINE_AUTO_START=true`). If you want to automatically create the Machine on first run, set `PODMAN_MACHINE_AUTO_INIT=true`.

**Requirements**:
- Windows 11 (22H2 or later)
- WSL2 enabled
- At least 8GB RAM (16GB recommended)
- At least 50GB free disk space
```

#### 2. Configuration Options セクションの更新 (line 83)

**現在:**
```markdown
### Machine Management (macOS Only)
```

**変更後:**
```markdown
### Machine Management (macOS/Windows Only)
```

### README.ja.md の変更

同様の変更を日本語版にも適用:

```markdown
### Windows

1. **WSL2を有効化**:
   ```powershell
   wsl --install
   ```
   インストール後、コンピュータを再起動してください。

2. **Podman Desktopをインストール**:
   [podman-desktop.io](https://podman-desktop.io/)からダウンロードしてインストール
   
   またはwinget経由でPodman CLIをインストール:
   ```powershell
   winget install RedHat.Podman
   ```

3. **DevPod CLIをインストール**:
   ```powershell
   winget install loft-sh.devpod
   ```

**注意**: Podman Machineの初期化と起動はデフォルトで自動的に処理されます（`PODMAN_MACHINE_AUTO_START=true`）。初回実行時にMachineを自動作成したい場合は、`PODMAN_MACHINE_AUTO_INIT=true`を設定してください。

**必要要件**:
- Windows 11（22H2以降）
- WSL2が有効化されていること
- 最低8GBのRAM（16GB推奨）
- 最低50GBの空きディスク容量
```

### AGENTS.md の変更

#### 1. Platform-Specific Branching セクションの更新 (lines 13-16)

**現在:**
```markdown
### Platform-Specific Branching
- macOS: Requires Podman Machine VM management (`[[ "$OSTYPE" == "darwin"* ]]`)
- Linux: Direct daemon connection (no Machine management)
- **Do not assume cross-platform behavior** - test both paths separately
```

**変更後:**
```markdown
### Platform-Specific Branching
- macOS: Requires Podman Machine VM management (`[[ "$OSTYPE" == "darwin"* ]]`)
- Windows: Requires Podman Machine VM management via WSL2 (`[[ "$OSTYPE" == "msys"* ]]` or `[[ "$OSTYPE" == "cygwin"* ]]`)
- Linux: Direct daemon connection (no Machine management)
- **Do not assume cross-platform behavior** - test all three paths separately
```

#### 2. 新規セクションの追加 (after line 121)

```markdown
## Windows-Specific Considerations

### WSL2 Backend Architecture
- Podman Machine runs inside WSL2 distribution (typically `podman-machine-default`)
- VM management commands are identical to macOS (`podman machine init/start/stop/set`)
- Resource limits are constrained by WSL2 configuration (`.wslconfig` in user home directory)

### Platform Detection
- Git Bash: `$OSTYPE = "msys"`
- Cygwin: `$OSTYPE = "cygwin"`
- WSL2 bash: `$OSTYPE = "linux-gnu"` (treated as Linux, not Windows)

### Shell Environment
- DevPod executes provider scripts using Git Bash (MSYS2) on Windows
- Bash syntax and common Unix tools (grep, awk, sed) are available
- PowerShell/CMD direct execution is not supported by DevPod provider model

### Default Machine Name
- Windows: `podman-machine-default` (matches Podman Desktop default)
- macOS: `devpod-machine` (custom name to avoid conflicts)
- This difference is intentional to align with platform conventions

### Known Limitations

#### Cannot Support
- **Windows 10**: WSL2 stability issues, Windows 11 22H2+ required
- **Hyper-V backend**: WSL2 is the default and recommended backend
- **Native Windows containers**: Podman Machine (Linux containers) only

#### Platform-Specific Constraints
- **Network**: WSL2 NAT mode may affect port forwarding behavior
- **Filesystem**: Cross-filesystem access (Windows ↔ WSL2) has performance overhead
- **Resource limits**: Podman Machine settings cannot exceed WSL2 limits (`.wslconfig`)

### Testing Requirements

#### When Adding Windows Support
1. Test on clean Windows 11 installation
2. Test with both Podman Desktop and Podman CLI
3. Verify WSL2 integration (machine creation, resource updates)
4. Test error messages and installation instructions
5. Validate cross-platform compatibility (macOS/Linux should not be affected)

#### Manual Test Scenarios for Windows
- TS-W1: First-time setup without Machine (AUTO_INIT=false)
- TS-W2: First-time setup with auto-init (AUTO_INIT=true)
- TS-W3: Resource configuration mismatch detection
- TS-W4: Automatic resource update (AUTO_RESOURCE_UPDATE=true)
- TS-W5: Workspace creation and SSH connection
- TS-W6: Workspace deletion and cleanup

### Error Message Patterns for Windows

All Windows-specific error messages should follow this pattern:

```bash
>&2 echo "Error: [Problem description]"
>&2 echo ""
>&2 echo "Manual fix:"
>&2 echo "  [Windows-specific command or action]"
>&2 echo ""
>&2 echo "Or enable automation:"
>&2 echo "  devpod provider set-options podman [OPTION]=true"
```

Example:
```bash
>&2 echo "Error: Podman binary not found"
>&2 echo ""
>&2 echo "Manual fix:"
>&2 echo "  Install Podman Desktop: https://podman-desktop.io/"
>&2 echo "  Or install CLI: winget install RedHat.Podman"
>&2 echo ""
>&2 echo "Or set custom path:"
>&2 echo "  devpod provider set-options podman PODMAN_PATH=/path/to/podman"
```
```

#### 3. Known Limitations セクションの更新 (after line 47)

**追加:**
```markdown
### Windows Support (v0.5.0+)
- Requires Windows 11 22H2 or later
- WSL2 backend only (Hyper-V not supported)
- Git Bash environment required for provider script execution
```

## 実装の段階的アプローチ

### Phase 1: 最小限の動作実装（1-2日）

**目標**: Windows環境でDevPodワークスペースが起動できる

**実装内容**:
1. プラットフォーム判定ロジックの追加
2. Windows環境でのMachine管理ロジックの適用
3. 基本的なエラーメッセージの対応

**検証方法**:
- Windows 11 + Podman Desktop環境でワークスペース作成
- 既存のmacOS/Linux環境で動作確認（リグレッションテスト）

### Phase 2: エラーハンドリングの充実（1日）

**目標**: ユーザーフレンドリーなエラーメッセージ

**実装内容**:
1. Windows固有のインストール手順の表示
2. プラットフォーム別のエラーメッセージ
3. デフォルトマシン名の調整

**検証方法**:
- 各種エラーシナリオでのメッセージ確認
- ドキュメントとの整合性確認

### Phase 3: テストとドキュメント（1-2日）

**目標**: 完全なドキュメントとテストカバレッジ

**実装内容**:
1. Windows用テストスクリプトの作成
2. README.md/README.ja.mdの更新
3. AGENTS.mdの更新
4. 統合テストの実施

**検証方法**:
- 全テストスクリプトの実行
- ドキュメントのレビュー
- 手動テストシナリオの完遂

## リスク管理

### 高リスク項目

1. **DevPodのシェル実行環境が不明**
   - **対策**: DevPodのソースコード確認、実機テストで特定
   - **代替案**: 複数のシェル環境で動作するよう汎用的に実装

2. **WSL2環境の多様性**
   - **対策**: 最小限の前提条件のみを要求、診断情報の充実
   - **代替案**: トラブルシューティングガイドの作成

3. **Podman DesktopとCLIの動作差異**
   - **対策**: 両環境でのテスト実施
   - **代替案**: 推奨環境の明記、既知の問題のドキュメント化

### 中リスク項目

1. **JSON解析の互換性**
   - **対策**: grep/awkの動作確認、jqフォールバックの実装
   - **代替案**: より堅牢なJSON解析方法の採用

2. **パス表記の違い**
   - **対策**: Unix形式パスの使用、Podmanの内部変換に依存
   - **代替案**: 必要に応じてパス変換ロジックの追加

## 成功基準

### 必須要件
- ✅ Windows 11環境でDevPodワークスペースが作成できる
- ✅ Machine管理（作成・起動・停止）が正常に動作する
- ✅ リソース設定の変更と適用が動作する
- ✅ 既存のmacOS/Linux環境に影響がない（リグレッションなし）

### 推奨要件
- ✅ エラーメッセージがWindows環境に適している
- ✅ ドキュメントが完全で正確
- ✅ テストスクリプトが整備されている
- ✅ 既知の制約事項が明確に文書化されている

### オプション要件
- ⚠️ jqを使用した高度なJSON解析
- ⚠️ WSL2設定の自動検証
- ⚠️ パフォーマンス最適化

## 次のアクション

1. **即座に実行可能**:
   - provider.yamlのプラットフォーム判定ロジック実装
   - テストスクリプトの作成
   - ドキュメントの更新

2. **実機テストが必要**:
   - Windows 11環境でのDevPod動作確認
   - Podman Machineコマンドの動作検証
   - エラーシナリオのテスト

3. **コミュニティフィードバックが必要**:
   - Windows環境での実際の使用感
   - 未発見のエッジケース
   - パフォーマンスの問題

## まとめ

Windows対応は、既存のmacOS用Machine管理ロジックをほぼそのまま流用できるため、実装の複雑さは低い。主な変更点は：

1. プラットフォーム判定の追加（`$OSTYPE`の分岐）
2. エラーメッセージのWindows対応
3. デフォルトマシン名の調整

実装の見積もり: **3-5日**
- Phase 1: 1-2日
- Phase 2: 1日
- Phase 3: 1-2日

リスクは中程度だが、段階的なアプローチと十分なテストにより管理可能。