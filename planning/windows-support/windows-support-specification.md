# Windows対応仕様書

## 概要

DevPod Podman ProviderをWindows 11環境に対応させるための技術仕様書。

## 前提条件

### 対象環境
- **OS**: Windows 11（22H2以降）
- **Podman**: Podman Desktop 1.0以降、またはPodman CLI 4.0以降
- **バックエンド**: WSL2（Windows Subsystem for Linux 2）
- **シェル**: PowerShell 7.x または Windows PowerShell 5.1
- **DevPod**: 最新版がインストール済み

### 除外する環境
- Windows 10（WSL2の安定性の観点から）
- Hyper-Vバックエンド（WSL2がデフォルトかつ推奨のため）
- Git Bash/MSYS2（DevPodのシェル実行環境として非標準）

## Windows環境でのPodman Machineの特性

### WSL2バックエンドの動作
1. **VM管理**: macOSと同様にVMベースだが、WSL2ディストリビューション内で動作
2. **マシン名**: `podman-machine-default`がデフォルト名
3. **コマンド互換性**: `podman machine` サブコマンドはmacOSとほぼ同等
4. **リソース管理**: CPU、メモリ、ディスクサイズの設定が可能

### macOSとの主な違い

| 項目 | macOS | Windows (WSL2) |
|------|-------|----------------|
| VM技術 | QEMU/HVF | WSL2 |
| デフォルトマシン名 | `podman-machine-default` | `podman-machine-default` |
| `podman machine init` | ✅ サポート | ✅ サポート |
| `podman machine start` | ✅ サポート | ✅ サポート |
| `podman machine set` | ✅ サポート (v4.0+) | ✅ サポート (v4.0+) |
| `podman machine inspect` | ✅ JSON出力 | ✅ JSON出力 |
| Rootful/Rootless | 両対応 | 両対応 |

### 検証が必要な項目
- [ ] `podman machine list`の出力フォーマット（アクティブマシンの`*`表記）
- [ ] `podman machine inspect`のJSONスキーマ（macOSと同一か）
- [ ] `podman machine set`の動作（停止→設定変更→起動の流れ）
- [ ] リソース設定の上限値（WSL2の制約）

## シェル環境の対応

### PowerShellでの課題と対応

#### 1. 環境変数の参照
**課題**: Bashの`${VAR}`とPowerShellの`$env:VAR`の違い

**対応方針**: 
- DevPodはプロバイダーのexec.initをbashスクリプトとして実行する
- Windows環境でもGit for WindowsのbashまたはWSL内のbashが使用される
- したがって、既存のbash構文をそのまま使用可能

#### 2. OSタイプの判定
**課題**: `$OSTYPE`変数の値がWindows環境で異なる

**Bash on Windows (Git Bash)の場合**:
```bash
$OSTYPE = "msys"  # Git Bash (MSYS2)
```

**WSL内のBashの場合**:
```bash
$OSTYPE = "linux-gnu"  # WSL2内のLinux
```

**対応方針**:
```bash
# Windows判定の追加
if [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
  # Windows環境（Git Bash/MSYS2）
  PLATFORM="windows"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS環境
  PLATFORM="darwin"
else
  # Linux環境（WSL含む）
  PLATFORM="linux"
fi
```

#### 3. パス表記
**課題**: Windowsのバックスラッシュ vs Unix形式のスラッシュ

**対応方針**:
- Podmanコマンドは内部でパス変換を行うため、Unix形式のパスを使用
- DevPodが提供する環境変数もUnix形式
- 特別な変換処理は不要

## 実装方針

### 1. プラットフォーム判定ロジックの追加

現在の実装:
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: Podman Machine管理が必要
fi
# それ以外: Linux（Machine管理不要）
```

新しい実装:
```bash
# プラットフォーム判定
PLATFORM="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  PLATFORM="darwin"
elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
  PLATFORM="windows"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  PLATFORM="linux"
fi

# Podman Machine管理が必要なプラットフォーム
if [[ "$PLATFORM" == "darwin" ]] || [[ "$PLATFORM" == "windows" ]]; then
  # Machine管理ロジック（既存のmacOS用コードを流用）
else
  # Linux: 直接デーモン接続
fi
```

### 2. Windows固有の調整

#### マシン名のデフォルト値
```bash
# Windows環境でのデフォルトマシン名
if [[ "$PLATFORM" == "windows" ]]; then
  DEFAULT_MACHINE_NAME="podman-machine-default"
else
  DEFAULT_MACHINE_NAME="devpod-machine"
fi
```

#### エラーメッセージの調整
```bash
if [[ "$PLATFORM" == "windows" ]]; then
  >&2 echo "Please install Podman Desktop: https://podman-desktop.io/"
else
  >&2 echo "Please install Podman: brew install podman"
fi
```

### 3. JSON解析の互換性確保

現在の実装（grep/awk）:
```bash
CURRENT_CPUS=$(echo "$MACHINE_INFO" | grep -o '"CPUs": *[0-9]*' | awk '{print $2}')
```

この方法はWindows環境でも動作するが、以下を確認:
- [ ] Git Bashにgrep/awkが含まれているか
- [ ] WSL内のbashで実行される場合の動作

代替案（jqの使用）:
```bash
# jqが利用可能な場合
if command -v jq &> /dev/null; then
  CURRENT_CPUS=$(echo "$MACHINE_INFO" | jq -r '.CPUs')
else
  # フォールバック: 既存のgrep/awk
  CURRENT_CPUS=$(echo "$MACHINE_INFO" | grep -o '"CPUs": *[0-9]*' | awk '{print $2}')
fi
```

## 設定オプションの変更

### 新規オプション（不要）
Windows対応のために新しいオプションを追加する必要はない。既存のオプションをそのまま使用可能。

### ドキュメントの更新が必要なオプション

#### PODMAN_MACHINE_AUTO_START
```yaml
description: "Automatically start Podman Machine if it is stopped (macOS/Windows only)."
```

#### PODMAN_MACHINE_AUTO_INIT
```yaml
description: "Automatically initialize Podman Machine if it does not exist (macOS/Windows only)."
```

## テスト戦略

### 単体テスト
1. **プラットフォーム判定テスト**
   - `$OSTYPE`の各値でのPLATFORM変数の設定確認
   - Windows/macOS/Linuxの3パターン

2. **Machine管理ロジックテスト**
   - Windows環境でのマシン作成・起動・停止
   - リソース設定の適用確認

### 統合テスト
1. **Windows 11 + Podman Desktop環境**
   - DevPodワークスペースの作成・削除
   - リソース設定の変更と適用
   - 自動起動・自動初期化の動作確認

2. **エラーハンドリング**
   - Podman未インストール時のエラーメッセージ
   - Machine未作成時の警告表示
   - リソース不一致時の警告・自動更新

### 手動テストシナリオ

#### TS-W1: 初回セットアップ（自動初期化OFF）
```powershell
# 前提: Podman Desktopインストール済み、Machine未作成
devpod provider add ./provider.yaml
devpod provider use podman
devpod up https://github.com/loft-sh/devpod-example-go --provider podman

# 期待結果: Machine未作成エラー、手動作成手順の表示
```

#### TS-W2: 初回セットアップ（自動初期化ON）
```powershell
devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true
devpod up https://github.com/loft-sh/devpod-example-go --provider podman

# 期待結果: Machine自動作成、ワークスペース起動成功
```

#### TS-W3: リソース設定変更
```powershell
devpod provider set-options podman PODMAN_MACHINE_CPUS=4
devpod provider set-options podman PODMAN_MACHINE_MEMORY=8192
devpod up <workspace> --provider podman

# 期待結果: リソース不一致警告、手動更新手順の表示
```

#### TS-W4: 自動リソース更新
```powershell
devpod provider set-options podman PODMAN_MACHINE_AUTO_RESOURCE_UPDATE=true
devpod up <workspace> --provider podman

# 期待結果: Machine停止→リソース更新→再起動→ワークスペース起動
```

## 既知の制約事項

### Windows固有の制約

1. **WSL2の前提**
   - WSL2が有効化されている必要がある
   - Windows 11 22H2以降を推奨

2. **リソース制限**
   - WSL2自体のリソース制限（.wslconfig）の影響を受ける
   - Podman Machineの設定値がWSL2の上限を超えることはできない

3. **ネットワーク**
   - WSL2のネットワークモード（NAT/mirrored）の影響を受ける
   - ポートフォワーディングの動作がmacOSと異なる可能性

4. **ファイルシステム**
   - Windows側のファイルシステム（NTFS）とWSL2内（ext4）の違い
   - パフォーマンスへの影響（特にクロスファイルシステムアクセス）

### 対応しない機能

1. **Hyper-Vバックエンド**
   - WSL2がデフォルトかつ推奨のため対応しない
   - Hyper-V使用時は手動でWSL2に切り替えを促す

2. **Windows 10**
   - WSL2の安定性の観点から対応しない
   - Windows 11へのアップグレードを推奨

3. **Git Bash以外のシェル**
   - PowerShell/CMDでの直接実行は対応しない
   - DevPodがbashを使用する前提

## ドキュメント更新計画

### README.md / README.ja.md

#### 追加セクション: Prerequisites - Windows

```markdown
### Windows

1. **Enable WSL2**:
   ```powershell
   wsl --install
   ```

2. **Install Podman Desktop**:
   Download from [podman-desktop.io](https://podman-desktop.io/)

3. **Install DevPod CLI**:
   ```powershell
   winget install loft-sh.devpod
   ```

**Note**: Podman Machine initialization and startup are handled automatically by default (`PODMAN_MACHINE_AUTO_START=true`). If you want to automatically create the Machine on first run, set `PODMAN_MACHINE_AUTO_INIT=true`.
```

#### 更新セクション: Configuration Options

Machine Management の説明を更新:
```markdown
### Machine Management (macOS/Windows Only)
```

### AGENTS.md

#### 更新セクション: Platform-Specific Branching

```markdown
### Platform-Specific Branching
- macOS: Requires Podman Machine VM management (`[[ "$OSTYPE" == "darwin"* ]]`)
- Windows: Requires Podman Machine VM management via WSL2 (`[[ "$OSTYPE" == "msys"* ]]`)
- Linux: Direct daemon connection (no Machine management)
- **Do not assume cross-platform behavior** - test all three paths separately
```

#### 新規セクション: Windows-Specific Considerations

```markdown
## Windows-Specific Considerations

### WSL2 Backend
- Podman Machine runs inside WSL2 distribution
- Resource limits are constrained by WSL2 configuration (.wslconfig)
- Network behavior may differ from macOS due to WSL2 NAT

### Shell Environment
- DevPod executes provider scripts using Git Bash or WSL bash
- PowerShell/CMD direct execution is not supported
- Bash syntax and tools (grep, awk) are available

### Known Limitations
- Windows 10 is not supported (Windows 11 22H2+ required)
- Hyper-V backend is not supported (WSL2 only)
- Cross-filesystem performance may be slower than native Linux
```

## 実装の優先順位

### Phase 1: コア機能の実装（必須）
1. ✅ プラットフォーム判定ロジックの追加
2. ✅ Windows環境でのMachine管理ロジックの適用
3. ✅ エラーメッセージのWindows対応

### Phase 2: テストとドキュメント（必須）
4. ✅ Windows環境でのテストスクリプト作成
5. ✅ README.md/README.ja.mdの更新
6. ✅ AGENTS.mdの更新

### Phase 3: 最適化と改善（オプション）
7. ⚠️ jqを使用したJSON解析の改善（フォールバック付き）
8. ⚠️ Windows固有のパフォーマンス最適化
9. ⚠️ WSL2設定の自動検証と推奨設定の提示

## リスクと対策

### リスク1: WSL2の動作環境の多様性
**リスク**: ユーザーのWSL2設定（ディストリビューション、.wslconfig）が多様

**対策**:
- 最小限の前提条件のみを要求
- WSL2の設定は変更せず、Podman Machineの設定のみを管理
- 問題発生時の診断情報を充実させる

### リスク2: Podman DesktopとCLIの違い
**リスク**: Podman DesktopとPodman CLIで動作が異なる可能性

**対策**:
- 両方の環境でテストを実施
- ドキュメントで推奨環境を明記
- CLIコマンドの互換性を優先

### リスク3: DevPodのシェル実行環境
**リスク**: DevPodがどのシェルを使用するか不明確

**対策**:
- DevPodのドキュメント・ソースコードを確認
- 複数のシェル環境でテストを実施
- 最悪の場合、Git Bashの明示的なインストールを要求

## 次のステップ

1. **技術検証**（1-2日）
   - Windows 11 + Podman Desktop環境の構築
   - `podman machine`コマンドの動作確認
   - DevPodのシェル実行環境の特定

2. **実装**（2-3日）
   - provider.yamlの修正
   - テストスクリプトの作成
   - ドキュメントの更新

3. **テスト**（1-2日）
   - 単体テスト・統合テストの実施
   - 手動テストシナリオの実行
   - バグ修正

4. **リリース準備**（1日）
   - CHANGELOG.mdの更新
   - バージョン番号の決定（v0.5.0を推奨）
   - リリースノートの作成

**合計見積もり**: 5-8日