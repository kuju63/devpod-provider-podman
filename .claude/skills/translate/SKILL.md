---
name: translate
description: Translate documentation between English and Japanese while preserving code, links, and structure. Automatically uses software development terminology glossary (56 terms including Docker, K8s, OCI, API, CLI, SDK, etc.) for consistency. Use when translating README files, test guides, or documentation updates. Usage: /translate [filename] [source-lang-code] [target-lang-code]
---

# Translation Skill

Translate documentation files between English and Japanese while maintaining technical accuracy and consistency with existing translations.

## Guidelines

### Translation Glossary

**IMPORTANT**: Before starting translation, read the complete translation glossary:
- **File**: `.claude/skills/translate/glossary.md`
- **Terms**: 56 software development terms including:
  - Container technology: Docker, Podman, OCI, K8s, image, volume, daemon, etc.
  - DevOps/CI/CD: GitHub Actions, workflow, pipeline, deployment, PR, etc.
  - General software development: API, CLI, SDK, library, framework, dependency, etc.

### Software Development Terms

When translating software development terms:
1. **Acronyms**: Keep acronyms in English (API, CLI, SDK, OCI, K8s)
2. **Proper nouns**: Keep proper nouns unchanged (Docker, Podman, GitHub, Kubernetes)
3. **Technical terms**: Use glossary translations (workspace → ワークスペース, container → コンテナ)
4. **Code-related**: Keep code identifiers, variable names, and command names in English

### Translation Rules

1. **Code blocks**: Keep identical (no translation)
   - Bash scripts, YAML, JSON, code examples must be unchanged
   - Comments in code blocks may be translated if appropriate

2. **Links and URLs**: Preserve exactly
   - Update relative links if pointing to language-specific files
   - Example: `README.md` → `README.ja.md` in language selector links

3. **Section headings**: Translate consistently
   - Use existing translations from parallel documentation as reference
   - Maintain heading hierarchy (same number of #)

4. **Code identifiers**: Keep unchanged
   - File paths, variable names, function names, command names
   - Example: `provider.yaml`, `PODMAN_MACHINE_NAME`, `devpod up`

5. **Technical abbreviations**: Keep in English with Japanese explanation if needed
   - Good: "OCI (Open Container Initiative)"
   - Bad: "オーシーアイ"

### File Structure

Maintain identical structure between English and Japanese versions:
- Same section ordering
- Same heading hierarchy
- Same code examples (identical)
- Same links (update paths only if pointing to language-specific content)

### Quality Checklist

Before considering the translation complete, verify:
- [ ] All technical terms match the glossary
- [ ] Code blocks are identical in both versions
- [ ] Links are functional in both versions
- [ ] Language selection links point to correct files
- [ ] Section structure matches between versions
- [ ] Acronyms and proper nouns are preserved correctly

## Task

Translate the file specified in the arguments from the source language to the target language.

**Arguments**:
- `$ARGUMENTS[0]`: Filename to translate (e.g., `README.md`)
- `$ARGUMENTS[1]`: Source language code (`en` or `ja`)
- `$ARGUMENTS[2]`: Target language code (`en` or `ja`)

## Steps

### 0. Validate language codes

Validate the language code arguments:
- `$ARGUMENTS[1]` (source) must be `en` or `ja`
- `$ARGUMENTS[2]` (target) must be `en` or `ja`
- If invalid, display error message with usage example

**Language code mappings**:
- `en`: English
- `ja`: Japanese (日本語)

### 1. Read source file

Use the Read tool to read the complete source file.
- Identify all sections and their content
- Note code blocks, links, and special formatting
- Identify the file structure

### 2. Load translation glossary

Read the translation glossary to ensure terminology consistency:
- File: `.claude/skills/translate/glossary.md`
- Pay attention to software development terms
- Note any special translation rules

### 3. Plan translation approach

Before editing, explain your approach:
- Identify technical terms that should use the glossary
- Identify sections that have parallel translations in existing files
- Plan how to maintain structure
- Note any links that need path updates

### 4. Perform translation

Create or edit the target file:
- Maintain identical structure to source
- Use consistent terminology from glossary
- Preserve all code examples without changes
- Keep all links (update paths only if language-specific)
- Maintain all formatting (bold, italic, lists, tables)

**Target filename**:
- `en` → `ja`: Add `.ja` before extension (e.g., `README.md` → `README.ja.md`)
- `ja` → `en`: Remove `.ja` from filename (e.g., `README.ja.md` → `README.md`)

### 5. Verification

Check the translation quality:
- [ ] All code blocks are identical to source
- [ ] Section structure matches source exactly
- [ ] Technical terms are consistent with glossary
- [ ] Links are appropriate for the target language
- [ ] Language selector links are updated
- [ ] No untranslated sections remain (except code)

### 6. Report

Provide a summary of the translation:
- Source file and target file paths
- Number of sections translated
- Notable technical terms used
- Any manual review recommendations

## Examples

For detailed examples of expected translation quality, see [examples.md](examples.md).
