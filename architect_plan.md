# Architect Plan: Remove Unnecessary Comments in Codebase

## Business Context
Code readability, maintainability, and signal-to-noise ratio are fundamental quality attributes of long-term software health. Over time and across iterative development cycles, source files often accumulate redundant inline explanations, restatements of obvious language constructs, noisy banner dividers, and trivial doc comments that mirror self-explanatory function signatures.

In the Pomodoro terminal application codebase (`src/`), several modules have accrued comment clutter:
1. **Redundant Step/Block Comments**: Numbered comments describing obvious procedural sequences (e.g., `// 1. Processa entrada do teclado`, `// 2. Atualiza o relógio`).
2. **Obvious Enum/Constant Explanations**: Comments repeating the name or basic value of constants (e.g., `// 0`, `// 1`, `// : (Separador)`, `// C5`, `// E5`, `case 27: return Key.Escape; // ESC`).
3. **Redundant Docstrings/Ddoc**: Method comments that merely translate self-evident method names into Portuguese or English without providing additional non-obvious domain knowledge (e.g., `/// Reinicia a fase atual` above `void resetCurrent()`).
4. **Noisy Section Banners**: ASCII divider lines (e.g., `// =========================================================================`) separating code sections that should instead be delineated by natural language constructs (classes, structs, functions).
5. **Redundant Struct Field Categorizations**: Header comments inside structs that merely group fields (e.g., `// Help text`, `// Phases`, `// Sound status`) where well-named struct fields already provide crystal-clear intent.

Removing this noise aligns the repository with Clean Code principles (Uncle Bob / Robert C. Martin: *"Don't comment bad code—rewrite it"* and *"Comments are often apologies for not making code self-explanatory"*), reduces visual clutter, and minimizes the risk of comments drifting out of sync with future code changes.

---

## Business Rules

1. **Rule 1 — Zero Functional Regression**: Stripping comments must not alter application behavior, runtime logic, string literals, CLI argument parsing, terminal rendering, sound synthesis, or unit test outcomes in any way.
2. **Rule 2 — Removal of Redundant & Noise Comments**:
   - Comments that merely restate what code does in natural language must be removed.
   - Numbered step annotations (e.g., `// 1. ...`, `// 2. ...`) must be removed.
   - Banner separators and decorative ASCII art dividers that divide functional blocks must be removed.
   - Obvious inline annotations beside self-explanatory expressions (e.g., `// ESC`, `// :`, `// 100%`) must be removed.
   - Trivial Ddoc comments on self-explanatory functions (`resetCurrent`, `nextPhase`) must be removed.
3. **Rule 3 — Preservation of Essential Technical Context**:
   - Comments providing critical hardware/OS/POSIX rationale that cannot be inferred from code identifiers (e.g., low-level terminal ioctl/termios behaviors, POSIX signal semantics, or specific DSP mathematical formulas) should be preserved or simplified to remain strictly informative.
   - String literals, translation tables, help messages, UI text, and user-facing copy containing slashes or dashes must remain 100% untouched.
4. **Rule 4 — Clean Formatting & Whitespace Normalization**:
   - Removing comments must not leave dangling whitespace, unnecessary double blank lines, or misaligned indentation.
   - The file structure must adhere to idiomatic D formatting conventions.
5. **Rule 5 — Test Suite Integrity**:
   - All unit tests (`dub test`) must continue to pass before and after changes.
   - Test descriptions and assertions must remain intact.

---

## Design Choices

1. **Target Scope**:
   The scope is restricted to the D source code under `src/`:
   - `src/main.d`
   - `src/pomodoro.d`
   - `src/sound.d`
   - `src/terminal.d`
   - `src/ui.d`
   - `src/i18n.d`
   External files (`dub.json`, `Makefile`, `README.md`, `README.pt.md`, `.gitignore`) are configuration/documentation files and will not be altered unless explicitly required.

2. **Classification Framework (Comment Taxonomy)**:
   - **Type A (Pure Noise / Redundant)**: *Action: Remove.* Comments explaining what the very next line of code does using identical semantics (e.g., `// Inicialização do Terminal e Estado`, `// Getters`, `// Modo de teste sonoro procedural`).
   - **Type B (Structural / Divider Banners)**: *Action: Remove.* Horizontal rules such as `// =========================================================================`.
   - **Type C (Obvious Inline Annotations)**: *Action: Remove.* Annotations beside array elements, enum members, or switch cases (e.g., `// 0`, `// 1`, `// C5`, `// Fundamental`, `// Primeiro harmônico`).
   - **Type D (Low-Level Technical Rationale)**: *Action: Retain / Clean.* Explanations of non-obvious POSIX syscalls, signal handling quirks, or memory-mapped audio fallbacks where omitting context harms maintainability.

3. **Validation Strategy**:
   - Automated compilation check (`dub build`).
   - Automated unit test suite execution (`dub test`).
   - Regression verification across all CLI flags (`--help`, `--lang`, `--no-sound`, `--test-sound`, `--ascii`).
   - Diff auditing to ensure no code lines, logic expressions, or strings were modified or deleted.

---

## 1. Test Specification Plan

This section defines the test strategy and test cases to be executed and verified by the Test Developer to guarantee that comment removal introduces zero defects.

### 1.1 Test Suite Overview

| Test Suite | Target Component | Purpose |
| :--- | :--- | :--- |
| **TS-BUILD** | Build System & Compiler | Verify clean compilation without warnings or errors |
| **TS-UNIT** | `dub test` (i18n, ui, pomodoro) | Verify all embedded unit tests pass with zero regressions |
| **TS-CLI** | CLI Arguments & Help Output | Verify help messages and argument parsing are unmodified |
| **TS-SOUND** | Procedural Audio Engine | Verify sound synthesis pipeline and WAV generation |
| **TS-UI** | UI Rendering & Layouts | Verify visual width calculation, responsive breakpoints, and frames |
| **TS-STATE** | Pomodoro State Machine | Verify cycle advancement, timer tick, pause, and phase transitions |

---

### 1.2 Detailed Test Cases

#### TS-BUILD: Compilation and Build Integrity
* **Test Case ID**: `TC-BUILD-01`
* **Test Name**: Full Project Build
* **Target**: Entire repository
* **Input**: Execute `dub build`
* **Expected Output**: Exit code `0`, binary produced at `./bin/pomodoro` or root, zero compilation errors or syntax issues.
* **Edge Cases**: Broken D tokens due to incorrect comment delimiter removal (e.g. leaving unmatched `*/` or removing a closing brace/parenthesis).

* **Test Case ID**: `TC-BUILD-02`
* **Test Name**: Unit Test Suite Compilation and Execution
* **Target**: Entire repository
* **Input**: Execute `dub test`
* **Expected Output**: Exit code `0`, output reports `All unit tests passed for 'pomodoro'` (e.g. `2 modules passed unittests`).
* **Edge Cases**: Unittest blocks in `i18n.d` and `ui.d` must remain fully functional.

---

#### TS-CLI: Argument Parsing & Help Text Fidelity
* **Test Case ID**: `TC-CLI-01`
* **Test Name**: Portuguese Help Output Fidelity
* **Target**: `src/main.d`, `src/i18n.d`
* **Input**: Execute `./bin/pomodoro --help` (or `dub run -- --help`)
* **Expected Output**:
  - Contains `POMODORO TIMER PARA TERMINAL (EM D)`
  - Contains all options (`--work`, `--short-break`, `--long-break`, `--cycles`, `--lang`, `--no-sound`, `--test-sound`, `--ascii`, `--help`)
  - Contains shortcut reference list
* **Edge Cases**: Ensure strings in `PT_TRANSLATIONS` were not altered when cleaning comments in `i18n.d`.

* **Test Case ID**: `TC-CLI-02`
* **Test Name**: English Help Output Fidelity
* **Target**: `src/main.d`, `src/i18n.d`
* **Input**: Execute `dub run -- --help --lang=en`
* **Expected Output**:
  - Contains `TERMINAL POMODORO TIMER (IN D)`
  - Contains English options and shortcuts
* **Edge Cases**: Verify case insensitivity and whitespace handling in `--lang`.

* **Test Case ID**: `TC-CLI-03`
* **Test Name**: Sound Test Mode Execution
* **Target**: `src/main.d`, `src/sound.d`
* **Input**: Execute `dub run -- --test-sound --no-sound`
* **Expected Output**:
  - Exit code `0`
  - Output displays test progress messages: `Testando sintetizador procedural de áudio estéreo...`, `1/2...`, `2/2...`, `Teste de som concluído com sucesso!`
* **Edge Cases**: Sound engine handles `no-sound` flag gracefully in test mode.

---

#### TS-UNIT: Internal Unit Test Validation
* **Test Case ID**: `TC-UNIT-01`
* **Test Name**: `i18n.d` Unit Tests
* **Target**: `src/i18n.d`
* **Test Scope**:
  - `parseLanguage("pt") == Language.PT`
  - `parseLanguage("en") == Language.EN`
  - `parseLanguage("PT") == Language.PT`
  - `parseLanguage("  en  ") == Language.EN`
  - `assertThrown!Exception(parseLanguage("invalid"))`
  - `getTranslations(Language.PT)` non-null pointer check
  - Translation string non-empty validations
* **Expected Output**: All assertions in `unittest` block in `src/i18n.d` pass.

* **Test Case ID**: `TC-UNIT-02`
* **Test Name**: `ui.d` Unit Tests
* **Target**: `src/ui.d`
* **Test Scope**:
  - `visibleWidth` calculation on ASCII, Unicode, emoji, and ANSI color escape sequences.
  - Layout breakpoint rendering across all 4 responsive sizes (`80x24`, `60x16`, `40x8`, `30x4`) for both PT and EN languages, ASCII and Unicode modes, unpaused and paused states, and all Pomodoro phases (Work, Short Break, Long Break).
* **Expected Output**: All assertions in `unittest` block in `src/ui.d` pass with zero buffer corruption.

---

#### TS-REGRESSION: Functional Diff & AST Regression Guardrails
* **Test Case ID**: `TC-REG-01`
* **Test Name**: AST & Logic Diff Check
* **Target**: All files in `src/`
* **Input**: Run `git diff -w -b` (ignoring whitespace differences) and inspect changes.
* **Expected Output**: The diff MUST ONLY show deletions of comment lines or inline comment tokens. No executable statements, variable declarations, struct fields, or string literals may be modified or removed.
* **Edge Cases**:
  - Slashes in URLs or paths (e.g. `/dev/shm`, `/tmp`).
  - Slashes in ANSI escape strings (e.g. `\033[...]`).
  - Regex or formatting delimiters.

---

## 2. Implementation Plan

This section provides the architectural design, comment classification, exact file modification instructions, and guidelines for the Developer.

### 2.1 Architectural Cleanup Strategy

To ensure clean code without risking regressions, comments will be removed systematically by file and category:
1. **Remove Noisy Block Headers & Step Counters**: Replace comments that describe sequential steps with clean, well-spaced code.
2. **Remove Redundant Inline Comments**: Eliminate obvious labels beside enum members, constants, and math terms.
3. **Remove Redundant Ddoc/Docstrings**: Remove trivial documentation comments where the function name and type signature already convey full meaning.
4. **Preserve Legitimate Technical Clarifications**: Retain comments that explain low-level system interactions (e.g., POSIX termios flag explanations, signal handler ANSI resets, RAM-based audio fallback).

---

### 2.2 File-by-File Modification Specifications

#### 1. `src/main.d`
* **File Purpose**: CLI entrypoint, argument parsing, main event loop, and high-level coordinator.
* **Comments to Remove**:
  - Line 80: `// Modo de teste sonoro procedural` (Redundant, immediately follows `if (testSound)`)
  - Line 99: `// Inicialização do Terminal e Estado` (Redundant, precedes standard instantiation)
  - Line 119: `// 1. Processa entrada do teclado (não-bloqueante)` (Step counter noise)
  - Line 169: `// 2. Atualiza o relógio do Pomodoro` (Step counter noise)
  - Line 175: `// Dispara alarme procedural relaxante` (Redundant noise)
  - Line 188: `// 3. Atualiza frame de animação rústica` (Step counter noise)
  - Line 195: `// 4. Renderiza a tela` (Step counter noise)
  - Line 199: `// 5. Descanso para baixíssimo uso de CPU (~15 FPS)` (Step counter noise)
* **Rationale**: The event loop is concise and self-explanatory. Numbered comments clutter the loop body.

---

#### 2. `src/pomodoro.d`
* **File Purpose**: Core Pomodoro domain model, state transitions, time tracking, and progress calculation.
* **Comments to Remove**:
  - Line 65: `/// Atualiza o timer com base no tempo monotônico. Retorna true se a fase acabou agora.` (Redundant Ddoc on `bool tick()`)
  - Line 86: `/// Avança para a próxima fase do ciclo` (Redundant Ddoc on `void nextPhase()`)
  - Line 118: `/// Reinicia a fase atual` (Redundant Ddoc on `void resetCurrent()`)
  - Line 154: `// Getters` (Redundant section divider)
* **Comments to Retain / Clean**:
  - Line 136: `// Se já resta menos de 1 minuto, limita ao mínimo de 10s` (Preserve/clean as it explains business rule boundary condition of 10-second floor).

---

#### 3. `src/sound.d`
* **File Purpose**: Procedural audio synthesizer, stereo WAV generation, and playback dispatcher.
* **Comments to Remove**:
  - Lines 13-15: `// Chime zen arpejado relaxante`, `// Sino suave de retorno ao foco`, `// Toque sutil de madeira` (Inline noise on enum `SoundType`)
  - Line 31: `// RIFF Chunk` (Obvious WAV chunk label)
  - Line 37: `// "fmt " subchunk` (Obvious WAV chunk label)
  - Lines 39-41: `// Subchunk1Size = 16 para PCM`, `// AudioFormat = 1 (PCM)`, `// NumChannels = 2 (Stereo)` (Obvious WAV specification comments)
  - Line 49: `// "data" subchunk` (Obvious WAV chunk label)
  - Line 84: `// Harmônicos rústicos de sino de vento / tigela tibetana` (Subjective noise)
  - Lines 87-90: `// Fundamental`, `// Primeiro harmônico de campânula`, `// Segundo harmônico`, `// Brilho suave` (Inline noise on table constants)
  - Line 104: `// Attack suave (4ms) para evitar estalos de início` (Noise / obvious DSP envelope)
  - Lines 157-158: `// Acorde Zen...`, `// C5 (523Hz)...` (Redundant description of notes)
  - Lines 166-170: `// C5`, `// E5`, `// G5`, `// B5`, `// C6` (Inline note labels)
  - Line 174: `// Sino duplo calmo...` (Subjective noise)
  - Lines 182-183: `// A4`, `// E5` (Inline note labels)
  - Line 187: `// Toque sutil e rápido de madeira (35ms)` (Subjective noise)
  - Line 203: `/// Gerenciador de Áudio Procedural` (Redundant Ddoc before `class SoundEngine`)
  - Line 228: `/// Toca um som de forma assíncrona em uma thread secundária sem travar a UI` (Redundant Ddoc)
  - Line 241: `// Fallback silencioso / não trava execução` (Obvious empty catch comment)
  - Line 248: `/// Toca sincronicamente (usado para testes do alarme)` (Redundant Ddoc)
  - Lines 276, 285, 294: `// 1. Tenta PipeWire...`, `// 2. Tenta PulseAudio...`, `// 3. Tenta ffplay...` (Numbered step noise)
* **Comments to Retain / Clean**:
  - Line 18: `/// Gera cabeçalho WAV de 44 bytes para dados PCM 16-bit Stereo (2 canais)` (Retain concise description of binary format)
  - Line 78: `/// Adiciona um tom harmônico de sino acústico/chime com distribuição estéreo` (Retain concise function header)
  - Line 120: `/// Normaliza os canais de áudio para volume ótimo e limpo (90% do máximo)` (Retain concise function header)
  - Line 146: `/// Gera o buffer de áudio WAV para o som solicitado` (Retain concise function header)
  - Line 258: `// Salva na memória RAM (/dev/shm) para leitura instantânea e sem desgaste de disco` (Retain technical rationale for `/dev/shm` vs `/tmp`)
  - Line 303: `// Fallback para campainha de terminal caso nenhum servidor de áudio responda` (Retain terminal bell `\a` fallback context)

---

#### 4. `src/terminal.d`
* **File Purpose**: Low-level POSIX terminal control, raw mode switching, signals, and key decoding.
* **Comments to Remove**:
  - Line 68: `// Registra manipuladores de sinal` (Redundant noise above `signal(...)`)
  - Line 202: `case 27: return Key.Escape; // ESC` (Obvious inline comment)
  - Line 208: `// Sequências de escape como setas` (Redundant comment)
* **Comments to Retain / Clean**:
  - Line 10: `enum SIGWINCH = 28; // Window size change signal (POSIX)` (Retain POSIX signal constant clarification)
  - Line 49: `// Restaura terminal em caso de SIGINT/SIGTERM` (Retain safety-critical handler context)
  - Line 53: `// ANSI reset cursor and screen` (Retain escape sequence context)
  - Lines 87, 89, 92: POSIX termios flag descriptions (`raw.c_lflag &= ~(ECHO | ICANON | IEXTEN)`, etc.) (Retain concise low-level POSIX configuration context).

---

#### 5. `src/ui.d`
* **File Purpose**: UI rendering engine, responsive layouts, texturing, animations, and ANSI color styling.
* **Comments to Remove**:
  - Line 14: `// Cores ANSI rústicas (Tons quentes de âmbar, madeira, cobre e pergaminho)`
  - Lines 22-27: `// Tons de madeira e pergaminho`, `// Castanho escuro`, `// Carvalho / canela`, etc.
  - Lines 29-34: `// Destaques de fase`, `// Laranja terracota / fogo`, etc.
  - Line 37: `// Dígitos grandes estilizados em blocos texturizados (5 linhas de altura)`
  - Lines 39, 47, 55, 63, 71, 79, 87, 95, 103, 111, 119: `// 0`, `// 1`, `// 2`, ..., `// : (Separador)`
  - Line 129: `// Fallback ASCII para compatibilidade total`
  - Line 144: `// Animação de Fogueira / Brasas Rústicas (8 frames)`
  - Line 196: `// Símbolos de ampulheta giratória`
  - Lines 200-202: `// =========================================================================` banner
  - Line 213: `// Ignora sequências de escape ANSI (\033[...m, etc.)`
  - Line 276: `// Se o tamanho da janela mudou, limpa a tela inteira para evitar caracteres fantasmas`
  - Line 296: `// Cores e descrições da fase`
  - Line 318: `// Seleciona layout adaptativo de acordo com o espaço disponível no terminal`
  - Line 336: `// Escreve todo o buffer atômico para evitar flicker`
  - Lines 341-343: `// =========================================================================` banner
  - Line 370: `buffer.put("\033[J"); // Limpa qualquer resíduo vertical abaixo`
  - Lines 373-375: `// =========================================================================` banner
  - Lines 400-402: `// =========================================================================` banner
  - Lines 424-426: `// =========================================================================` banner
  - Lines 458-460: `// =========================================================================` banner
  - Lines 541, 546: `// Título`, `// Ciclos e Som`
  - Line 553: `int contentVis = titleVis + cycleVis + soundVis + 2; // 2 espaços entre cycle e sound`
  - Line 643: `int d3 = 10; // :`
  - Line 649: `int totalClockWidth = digitWidth * 5 + 4; // 5 digitos + 4 espacos`
  - Line 696: `int clockVis = cast(int)visibleWidth(app.data) + 4; // "[ " e " ]"`
  - Line 737: `int badgeVis = cast(int)visibleWidth(label) + 4; // "[ " e " ]"`
  - Line 813: `// 3 (left "║ ") + 1 (open) + barWidth + ...`
  - Line 839: `// 3 (left "║ ") + (barWidth + 2) + ...`
  - Line 876: `// 3 (left "║ ") + textVis + pad + 1 (right "║") = width`
  - Line 899: `// Fogueira animada`
  - Line 907: `int fireVis = cast(int)visibleWidth(fireFrame[row]); // 11`
  - Line 927: `// 3 (left "║ ") + fireVis + ...`
  - Line 978: `// 2 (left "║ ") + totalVis + pad + 2 (right " ║") = width`
  - Line 1015: `// 2 (left "║ ") + totalVis + pad + 2 (right " ║") = width`
  - Lines 1065, 1069, 1073, 1075, 1080, 1086 in `unittest`: `// Test unpaused`, `// Test paused`, `// revert`, etc.
* **Comments to Retain / Clean**:
  - Line 201: `// Helper para cálculo exato de largura visual no terminal (Unicode / Emojis / ANSI)` (Retain concise header for `visibleWidth`)
  - Lines 1030, 1039-1044: Test case identifiers in `unittest` block (`// TC-UI-01: visibleWidth calculations`, breakpoint definitions).

---

#### 6. `src/i18n.d`
* **File Purpose**: Internationalization translation catalogs and language parser.
* **Comments to Remove**:
  - Struct field comments: Lines 14, 30, 36, 41, 47, 51, 58, 62, 67 (`// Help text`, `// Sound test`, `// Phases`, `// Sound status`, `// Cycle indicators`, `// Status badges`, `// Stats`, `// Quotes and atmospheric text`, `// Responsive shortcuts`).
  - Table section comments: Lines 75, 99, 105, 110, 116, 120, 127, 131, 141 in `PT_TRANSLATIONS`.
  - Table section comments: Lines 168, 192, 198, 203, 209, 213, 220, 224, 234 in `EN_TRANSLATIONS`.
* **Comments to Retain / Clean**:
  - Unit test case labels in `unittest` (Lines 292, 296, 302, 306, 314, 322, 362) for clear test specification traceability (`TC-I18N-01` through `TC-I18N-08`).

---

### 2.3 Developer Guidelines & Execution Checklist

1. **Strict Non-Destructive Editing**:
   - Never alter string literal contents when removing comments.
   - Do not touch translation text or command-line help text.
   - Do not modify runtime logic, control flows, loops, or conditionals.
2. **Formatting & Whitespace Hygiene**:
   - Avoid creating multiple consecutive blank lines when removing comment lines.
   - Ensure clean vertical spacing: maximum 1 blank line between statements/struct fields, maximum 2 blank lines between top-level functions/classes.
3. **Verification Steps**:
   - Run `dub build` to verify compilation.
   - Run `dub test` to verify all unittests pass.
   - Run `git diff` to verify only comment lines were deleted.
   - Test CLI execution (`./bin/pomodoro --help`, `dub run -- --test-sound --no-sound`).
