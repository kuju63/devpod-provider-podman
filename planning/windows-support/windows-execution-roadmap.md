# Windows対応実行ロードマップ

## 実行計画の概要

このドキュメントは、Windows対応を段階的に実装するための具体的な実行計画です。

## 前提条件の確認

### 必要な情報・リソース

#### 確認済み
- ✅ Podman MachineのWindows対応状況（WSL2バックエンド）
- ✅ macOSとの機能互換性（`podman machine`コマンド）
- ✅ 既存コードの構造と変更箇所

#### 確認が必要
- ⚠️ DevPodがWindows環境で使用するシェル（Git Bash/WSL bash/その他）
- ⚠️ Windows環境でのgrep/awkの利用可能性
- ⚠️ Podman Desktop vs Podman CLIの動作差異

#### 実機テストが必要
- ⚠️ Windows 11 + Podman Desktop環境の構築
- ⚠️ `podman machine inspect`のJSON出力フォーマット
- ⚠️ `podman machine set`の動作確認

## 実装の段階的アプローチ

### Phase 0: 事前調査（0.5-1日）

**目的**: 実装に必要な技術情報の収集

**タスク**:
1. DevPodのソースコード確認
   - Windows環境でのシェル実行方法
   - プロバイダースクリプトの実行環境
   - 参考: http://github.com/skevetter/devpod

2. Podman公式ドキュメント確認
   - Windows版の制約事項
   - WSL2バックエンドの詳細
   - 参考: https://podman.io/docs/installation#windows

3. 実機環境の準備（可能であれば）
   - Windows 11 VMまたは実機
   - Podman Desktopのインストール
   - DevPodのインストール

**成果物**:
- [ ] DevPodのシェル実行環境の確認結果
- [ ] Podman Windowsの動作確認レポート
- [ ] 実機テスト環境の構築（オプション）

**判断基準**:
- DevPodがGit Bashを使用することが確認できれば、既存のbash構文をそのまま使用可能
- WSL bashを使用する場合、`$OSTYPE`が`linux-gnu`となるため、別の判定方法が必要

---

### Phase 1: コア機能の実装（1-2日）

**目的**: Windows環境でDevPodワークスペースが起動できる最小限の実装

#### Task 1.1: プラットフォーム判定ロジックの実装

**変更ファイル**: `provider.yaml` (lines 94-96)

**実装内容**:
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

**検証方法**:
```bash
# macOS環境でのテスト
OSTYPE="darwin22.0" bash -c 'source provider.yaml exec.init section'

# Windows環境でのテスト（シミュレーション）
OSTYPE="msys" bash -c 'source provider.yaml exec.init section'

# Linux環境でのテスト
OSTYPE="linux-gnu" bash -c 'source provider.yaml exec.init section'
```

**完了条件**:
- [ ] 3つのプラットフォームで正しく判定される
- [ ] 既存のmacOS/Linux動作に影響がない
- [ ] yamllintでエラーが出ない

#### Task 1.2: Machine管理ロジックの条件分岐更新

**変更ファイル**: `provider.yaml` (line 448)

**実装内容**:
```bash
    fi  # End of Machine management section (macOS/Windows)
  else
    # Linux: Direct daemon connection (no Machine management)
    echo "Platform: Linux (native containers)"
  fi
```

**検証方法**:
- macOS環境: Machine管理ロジックが実行される
- Windows環境: Machine管理ロジックが実行される
- Linux環境: Machine管理ロジックがスキップされる

**完了条件**:
- [ ] 条件分岐が正しく動作する
- [ ] 既存のテストが通過する

#### Task 1.3: 基本的なエラーメッセージの対応

**変更ファイル**: `provider.yaml` (lines 84-87)

**実装内容**:
```bash
if ! command -v ${PODMAN_PATH} &> /dev/null; then
  >&2 echo "Error: Podman binary not found at '${PODMAN_PATH}'"
  
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

**完了条件**:
- [ ] 各プラットフォームで適切なメッセージが表示される
- [ ] エラーメッセージが明確で実行可能

---

### Phase 2: エラーハンドリングの充実（1日）

**目的**: ユーザーフレンドリーなエラーメッセージとWindows固有の調整

#### Task 2.1: デフォルトマシン名の調整

**変更ファイル**: `provider.yaml` (lines 112-113)

**実装内容**:
```bash
echo "Creating new Podman Machine..."

# Platform-specific default machine name
if [[ "$PLATFORM" == "windows" ]]; then
  MACHINE_NAME="podman-machine-default"
else
  MACHINE_NAME="devpod-machine"
fi
```

**理由**:
- Podman Desktop for Windowsは`podman-machine-default`をデフォルトで使用
- 既存のマシンとの競合を避ける

**完了条件**:
- [ ] Windows環境で正しいデフォルト名が使用される
- [ ] macOS/Linux環境に影響がない

#### Task 2.2: 追加のエラーメッセージ対応

**変更箇所**:
1. Line 129-130: Machine未作成時
2. Line 172: Machine未起動時
3. Line 456-460: Podman接続エラー時

**実装パターン**:
```bash
if [[ "$PLATFORM" == "darwin" ]]; then
  >&2 echo "macOS specific instructions"
elif [[ "$PLATFORM" == "windows" ]]; then
  >&2 echo "Windows specific instructions"
else
  >&2 echo "Linux specific instructions"
fi
```

**完了条件**:
- [ ] 全てのエラーメッセージがプラットフォーム対応
- [ ] メッセージが実行可能で明確

#### Task 2.3: オプション説明の更新

**変更ファイル**: `provider.yaml` (lines 35-41)

**実装内容**:
```yaml
PODMAN_MACHINE_AUTO_START:
  description: "Automatically start Podman Machine if it is stopped (macOS/Windows only)."
  default: "true"

PODMAN_MACHINE_AUTO_INIT:
  description: "Automatically initialize Podman Machine if it does not exist (macOS/Windows only)."
  default: "false"
```

**完了条件**:
- [ ] オプション説明が正確
- [ ] yamllintでエラーが出ない

---

### Phase 3: テストとドキュメント（1-2日）

**目的**: 完全なテストカバレッジとドキュメント

#### Task 3.1: Windows用テストスクリプトの作成

**新規ファイル**: `tests/test_windows_init.sh`

**実装内容**: `docs/windows-implementation-plan.md`を参照

**検証方法**:
```bash
# CI環境でのテスト（OSタイプのシミュレーション）
OSTYPE="msys" bash tests/test_windows_init.sh

# 実機環境でのテスト（可能であれば）
bash tests/test_windows_init.sh
```

**完了条件**:
- [ ] 全てのテストケースが通過
- [ ] CI環境で実行可能

#### Task 3.2: 統合テストスクリプトの作成

**新規ファイル**: `tests/integration_test_windows.sh`

**実装内容**: `docs/windows-implementation-plan.md`を参照

**完了条件**:
- [ ] Windows環境での実行手順が明確
- [ ] 手動テストシナリオが文書化されている

#### Task 3.3: README.md の更新

**変更ファイル**: `README.md`

**追加セクション**:
1. Prerequisites - Windows (after line 34)
2. Configuration Options - Machine Management の説明更新 (line 83)

**完了条件**:
- [ ] Windows環境のセットアップ手順が明確
- [ ] 必要要件が正確に記載されている
- [ ] コード例が動作する

#### Task 3.4: README.ja.md の更新

**変更ファイル**: `README.ja.md`

**追加セクション**: README.mdと同様

**完了条件**:
- [ ] 日本語訳が正確
- [ ] 英語版と内容が一致
- [ ] 用語が`.claude/skills/translate/glossary.md`に準拠

#### Task 3.5: AGENTS.md の更新

**変更ファイル**: `AGENTS.md`

**更新セクション**:
1. Platform-Specific Branching (lines 13-16)
2. 新規: Windows-Specific Considerations (after line 121)
3. Known Limitations (after line 47)

**完了条件**:
- [ ] Windows固有の制約が明確
- [ ] テスト要件が文書化されている
- [ ] エラーメッセージパターンが定義されている

---

## 検証とテスト計画

### 単体テスト

#### UT-1: プラットフォーム判定
```bash
# Test case 1: macOS
OSTYPE="darwin22.0" bash -c '[test script]'
# Expected: PLATFORM="darwin"

# Test case 2: Windows (Git Bash)
OSTYPE="msys" bash -c '[test script]'
# Expected: PLATFORM="windows"

# Test case 3: Windows (Cygwin)
OSTYPE="cygwin" bash -c '[test script]'
# Expected: PLATFORM="windows"

# Test case 4: Linux
OSTYPE="linux-gnu" bash -c '[test script]'
# Expected: PLATFORM="linux"

# Test case 5: Unknown
OSTYPE="unknown" bash -c '[test script]'
# Expected: PLATFORM="linux" (fallback)
```

#### UT-2: デフォルトマシン名
```bash
# Test case 1: Windows
PLATFORM="windows" bash -c '[test script]'
# Expected: MACHINE_NAME="podman-machine-default"

# Test case 2: macOS
PLATFORM="darwin" bash -c '[test script]'
# Expected: MACHINE_NAME="devpod-machine"

# Test case 3: Linux
PLATFORM="linux" bash -c '[test script]'
# Expected: No machine name (not used)
```

### 統合テスト（実機環境）

#### IT-1: Windows 11 + Podman Desktop
```powershell
# Prerequisites
- Windows 11 22H2+
- WSL2 enabled
- Podman Desktop installed
- DevPod installed

# Test steps
1. devpod provider add ./provider.yaml
2. devpod provider use podman
3. devpod up https://github.com/loft-sh/devpod-example-go --provider podman
4. devpod ssh <workspace>
5. devpod delete <workspace>

# Expected results
- Machine created automatically (if AUTO_INIT=true)
- Workspace starts successfully
- SSH connection works
- Workspace deletion succeeds
```

#### IT-2: リソース設定変更
```powershell
# Test steps
1. devpod provider set-options podman PODMAN_MACHINE_CPUS=4
2. devpod provider set-options podman PODMAN_MACHINE_MEMORY=8192
3. devpod up <workspace> --provider podman

# Expected results
- Resource mismatch warning displayed
- Manual update instructions shown
- Or automatic update if AUTO_RESOURCE_UPDATE=true
```

### リグレッションテスト

#### RT-1: macOS環境
```bash
# Verify existing macOS functionality
1. Run all existing tests
2. Create/delete workspace
3. Resource update scenarios

# Expected results
- All tests pass
- No behavior changes
- No new errors
```

#### RT-2: Linux環境
```bash
# Verify existing Linux functionality
1. Run all existing tests
2. Create/delete workspace
3. Verify no Machine management

# Expected results
- All tests pass
- No behavior changes
- No new errors
```

---

## リスク管理と対策

### 高リスク項目

#### R-1: DevPodのシェル実行環境が不明
**影響**: 実装方針が大きく変わる可能性

**対策**:
1. DevPodのソースコード確認（優先度: 高）
2. 実機テストでの確認（優先度: 高）
3. 複数のシェル環境で動作する汎用実装（フォールバック）

**判断基準**:
- Git Bash使用: 既存のbash構文をそのまま使用可能 → 実装継続
- WSL bash使用: `$OSTYPE`が`linux-gnu`となる → 別の判定方法が必要
- PowerShell使用: bash構文が使えない → 大幅な設計変更が必要

**タイムライン**: Phase 0で確認、Phase 1開始前に判断

#### R-2: Podman DesktopとCLIの動作差異
**影響**: 一部の環境で動作しない可能性

**対策**:
1. 両環境でのテスト実施
2. 推奨環境の明記（Podman Desktop優先）
3. 既知の問題のドキュメント化

**判断基準**:
- 重大な差異がある場合: 対応環境を限定
- 軽微な差異の場合: ドキュメントで注記

**タイムライン**: Phase 3の統合テストで確認

### 中リスク項目

#### R-3: WSL2環境の多様性
**影響**: 一部のユーザー環境で問題が発生する可能性

**対策**:
1. 最小限の前提条件のみを要求
2. 診断情報の充実
3. トラブルシューティングガイドの作成

**タイムライン**: Phase 3でドキュメント化

#### R-4: JSON解析の互換性
**影響**: リソース設定の検出が失敗する可能性

**対策**:
1. 既存のgrep/awk方式を維持
2. 必要に応じてjqフォールバックを追加
3. エラーハンドリングの強化

**タイムライン**: Phase 1で基本動作確認、Phase 2で改善

---

## 成功基準

### 必須要件（Phase 1-2で達成）
- ✅ Windows 11環境でDevPodワークスペースが作成できる
- ✅ Machine管理（作成・起動・停止）が正常に動作する
- ✅ リソース設定の変更と適用が動作する
- ✅ 既存のmacOS/Linux環境に影響がない

### 推奨要件（Phase 3で達成）
- ✅ エラーメッセージがWindows環境に適している
- ✅ ドキュメントが完全で正確
- ✅ テストスクリプトが整備されている
- ✅ 既知の制約事項が明確に文書化されている

### オプション要件（将来の改善）
- ⚠️ jqを使用した高度なJSON解析
- ⚠️ WSL2設定の自動検証
- ⚠️ パフォーマンス最適化

---

## タイムライン

### 最短シナリオ（3日）
- Day 1: Phase 0 (0.5日) + Phase 1 (0.5日)
- Day 2: Phase 2 (1日)
- Day 3: Phase 3 (1日)

**前提条件**:
- DevPodがGit Bashを使用することが確認済み
- 実機テスト環境が利用可能
- リグレッションテストが自動化されている

### 標準シナリオ（5日）
- Day 1: Phase 0 (1日)
- Day 2-3: Phase 1 (2日)
- Day 4: Phase 2 (1日)
- Day 5: Phase 3 (1日)

**前提条件**:
- 技術調査に時間がかかる
- 実機テスト環境の構築が必要
- 手動テストが必要

### 最長シナリオ（8日）
- Day 1-2: Phase 0 (2日) - 技術調査と環境構築
- Day 3-4: Phase 1 (2日) - コア機能実装
- Day 5-6: Phase 2 (2日) - エラーハンドリング
- Day 7-8: Phase 3 (2日) - テストとドキュメント

**前提条件**:
- 技術的な不確実性が高い
- 実機テスト環境の構築に時間がかかる
- 予期しない問題が発生する

---

## 次のアクション

### 即座に実行可能（Phase 0）
1. ✅ 仕様書の作成（完了）
2. ✅ 実装計画の作成（完了）
3. ✅ 実行ロードマップの作成（完了）
4. ⏳ DevPodのソースコード確認
5. ⏳ Podman公式ドキュメント確認

### 実装開始前に必要（Phase 0）
1. ⏳ DevPodのシェル実行環境の特定
2. ⏳ 実機テスト環境の準備（オプション）
3. ⏳ 技術的な不確実性の解消

### 実装フェーズ（Phase 1-3）
1. ⏳ provider.yamlの修正
2. ⏳ テストスクリプトの作成
3. ⏳ ドキュメントの更新
4. ⏳ 統合テストの実施

---

## 意思決定ポイント

### DP-1: Phase 0完了時
**判断内容**: 実装を継続するか、設計を見直すか

**判断基準**:
- DevPodがGit Bashを使用 → 実装継続
- DevPodがWSL bashを使用 → 判定方法の見直し
- DevPodがPowerShellを使用 → 大幅な設計変更

**期限**: Phase 0完了時（1-2日以内）

### DP-2: Phase 1完了時
**判断内容**: Phase 2に進むか、Phase 1を改善するか

**判断基準**:
- 基本動作が確認できた → Phase 2へ進む
- 重大な問題が発見された → Phase 1を改善
- リグレッションが発生した → 原因調査と修正

**期限**: Phase 1完了時（3-4日以内）

### DP-3: Phase 3完了時
**判断内容**: リリースするか、追加改善するか

**判断基準**:
- 全ての必須要件を満たす → リリース準備
- 推奨要件が不足 → 追加作業
- 重大な問題が残存 → 修正作業

**期限**: Phase 3完了時（5-8日以内）

---

## まとめ

Windows対応は、既存のmacOS用Machine管理ロジックを活用できるため、実装の複雑さは低い。主な課題は：

1. **技術的不確実性**: DevPodのシェル実行環境の特定
2. **テスト環境**: Windows実機でのテスト実施
3. **ドキュメント**: 正確で完全なドキュメントの作成

段階的なアプローチにより、リスクを管理しながら確実に実装を進めることができる。

**推奨タイムライン**: 5日（標準シナリオ）
**最小タイムライン**: 3日（最短シナリオ、条件付き）
**最大タイムライン**: 8日（最長シナリオ、余裕を持った計画）