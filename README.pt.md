🌐 Language / Idioma: [English](README.md) | [Português](README.pt.md)

# ⌛ Pomodoro Timer para Terminal (em D)

Um temporizador Pomodoro simples, elegante e de **baixíssimo consumo de memória RAM (< 3.5 MB)** e CPU, desenvolvido na linguagem **D (Dlang)**.

Apresenta uma estética limpa de terminal com caracteres texturizados (`░ ▒ ▓ █`), animações acolhedoras de fogueira/ampulheta ASCII, relógio de dígitos grandes e um **sintetizador de alarme procedural harmônico relaxante** (estilo sino tibetano / chime zen / marimba).

---

## 📸 Recursos

- ⏱️ **Interface Visual no Console**: Relógio com dígitos grandes texturizados, molduras organizadas e tons quentes (âmbar, terracota, musgo).
- ⏳ **Barra de Progresso Fluida**: Sub-blocos graduais (`░`, `▒`, `▓`, `█`) e indicador dinâmico percentual.
- 🔥 **Animações em Caracteres**: Fogueira/brasas animadas em ASCII e contador visual de ciclos.
- 🎵 **Alarme Procedural Relaxante**: Sintetizador matemático embutido gerando ondas senoidais harmônicas com decaimento exponencial (sem arquivos pesados gravados, gerado sob demanda em memória e executado assincronamente).
- ⚡ **Extremamente Leve**: Consumo típico de ~3.4 MB de RAM e ~0% de CPU.
- ⌨️ **Controles Interativos em Tempo Real**: Pausa, pulo de fase, ajuste de minutos e mute instantâneos.
- 🌐 **Internacionalização (i18n)**: Suporte completo para Português (`pt`) e Inglês (`en`).

---

## 🛠️ Como Compilar e Executar

### Pré-requisitos
- Compilador D (`dmd` ou `ldc2`) e o gerenciador de pacotes `dub`.

### Compilando e Executando com DUB:
```bash
# Execução direta com DUB:
dub run

# Ou compilar binário otimizado de release:
dub build --build=release
./bin/pomodoro
```

---

## 🎮 Controles no Terminal

| Tecla | Ação |
| :--- | :--- |
| **`Espaço`** | Pausar ou Retomar a contagem |
| **`N`** ou **`Enter`** | Pular para a próxima fase (Foco ➔ Pausa ➔ ...) |
| **`R`** | Reiniciar a fase atual |
| **`+`** | Adicionar 1 minuto ao tempo restante |
| **`-`** | Subtrair 1 minuto do tempo restante |
| **`M`** | Alternar Som (Ativar / Mudo) |
| **`Q`** ou **`ESC`** | Sair do programa e restaurar o terminal |

---

## ⚙️ Opções de Linha de Comando (CLI)

| Opção | Descrição | Padrão |
| :--- | :--- | :--- |
| `-w, --work <min>` | Duração do foco em minutos | `25` |
| `-s, --short-break <min>` | Duração da pausa curta em minutos | `5` |
| `-l, --long-break <min>` | Duração da pausa longa em minutos | `15` |
| `-c, --cycles <qtd>` | Ciclos de foco antes da pausa longa | `4` |
| `-L, --lang <pt\|en>` | Idioma da interface (`pt` ou `en`) | `pt` |
| `--no-sound` | Iniciar com som desativado | Desativado |
| `--test-sound` | Testar o sintetizador de áudio e sair | - |
| `--ascii` | Modo compatibilidade (apenas ASCII 7-bit) | Desativado |
| `-h, --help` | Exibir mensagem de ajuda | - |

### Exemplos de Uso:
```bash
# Definir tempos customizados (ex: 50 min foco, 10 min pausa curta, 30 min pausa longa, 3 ciclos)
dub run -- -w 50 -s 10 -l 30 -c 3

# Definir idioma da interface (pt ou en):
dub run -- -L en
dub run -- --lang en

# Testar apenas o sintetizador procedural de áudio:
dub run -- --test-sound

# Iniciar no modo silencioso:
dub run -- --no-sound

# Iniciar em modo ASCII estrito:
dub run -- --ascii
```

---

## 📜 Licença
Distribuído sob a licença MIT.
