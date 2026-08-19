module comment_cleanliness_test;

import std.file : readText, exists;
import std.algorithm.searching : canFind;
import std.string : indexOf;
import std.format : format;
import i18n;
import sound;
import pomodoro;

unittest
{
    // =========================================================================
    // TS-CLI: Argument Parsing & Help Text Fidelity
    // =========================================================================

    // TC-CLI-01: Portuguese Help Output Fidelity
    const(TranslationStrings)* pt = getTranslations(Language.PT);
    assert(pt.helpTitle.canFind("POMODORO TIMER PARA TERMINAL (EM D)"));
    assert(pt.helpOptWork.canFind("--work"));
    assert(pt.helpOptShortBreak.canFind("--short-break"));
    assert(pt.helpOptLongBreak.canFind("--long-break"));
    assert(pt.helpOptCycles.canFind("--cycles"));
    assert(pt.helpOptLang.canFind("--lang"));
    assert(pt.helpOptNoSound.canFind("--no-sound"));
    assert(pt.helpOptTestSound.canFind("--test-sound"));
    assert(pt.helpOptAscii.canFind("--ascii"));
    assert(pt.helpOptHelp.canFind("--help"));
    assert(pt.helpShortcuts[0].canFind("Espaço"));
    assert(pt.helpShortcuts[6].canFind("ESC"));

    // TC-CLI-02: English Help Output Fidelity
    const(TranslationStrings)* en = getTranslations(Language.EN);
    assert(en.helpTitle.canFind("TERMINAL POMODORO TIMER (IN D)"));
    assert(en.helpOptWork.canFind("--work"));
    assert(en.helpOptShortBreak.canFind("--short-break"));
    assert(en.helpOptLongBreak.canFind("--long-break"));
    assert(en.helpOptCycles.canFind("--cycles"));
    assert(en.helpOptLang.canFind("--lang"));
    assert(en.helpOptNoSound.canFind("--no-sound"));
    assert(en.helpOptTestSound.canFind("--test-sound"));
    assert(en.helpOptAscii.canFind("--ascii"));
    assert(en.helpOptHelp.canFind("--help"));
    assert(en.helpShortcuts[0].canFind("Space"));
    assert(en.helpShortcuts[6].canFind("ESC"));

    // TC-CLI-03: Sound Test Mode Messages
    assert(pt.soundTestStart.canFind("Testando sintetizador procedural"));
    assert(pt.soundTestWork.canFind("1/2"));
    assert(pt.soundTestBreak.canFind("2/2"));
    assert(pt.soundTestSuccess.canFind("Teste de som concluído com sucesso!"));

    assert(en.soundTestStart.canFind("Testing stereo procedural audio synthesizer"));
    assert(en.soundTestWork.canFind("1/2"));
    assert(en.soundTestBreak.canFind("2/2"));
    assert(en.soundTestSuccess.canFind("Sound test completed successfully!"));

    // =========================================================================
    // TS-REGRESSION: TC-REG-01 Comment Cleanliness Verification
    // =========================================================================

    // 1. src/main.d
    if (exists("src/main.d"))
    {
        string mainSrc = readText("src/main.d");
        string[] prohibitedMain = [
            "// Modo de teste sonoro procedural",
            "// Inicialização do Terminal e Estado",
            "// 1. Processa entrada do teclado (não-bloqueante)",
            "// 2. Atualiza o relógio do Pomodoro",
            "// Dispara alarme procedural relaxante",
            "// 3. Atualiza frame de animação rústica",
            "// 4. Renderiza a tela",
            "// 5. Descanso para baixíssimo uso de CPU (~15 FPS)"
        ];
        foreach (comment; prohibitedMain)
        {
            assert(!mainSrc.canFind(comment),
                format("Prohibited comment found in src/main.d: '%s'", comment));
        }
    }

    // 2. src/pomodoro.d
    if (exists("src/pomodoro.d"))
    {
        string pomoSrc = readText("src/pomodoro.d");
        string[] prohibitedPomo = [
            "/// Atualiza o timer com base no tempo monotônico. Retorna true se a fase acabou agora.",
            "/// Avança para a próxima fase do ciclo",
            "/// Reinicia a fase atual",
            "// Getters"
        ];
        foreach (comment; prohibitedPomo)
        {
            assert(!pomoSrc.canFind(comment),
                format("Prohibited comment found in src/pomodoro.d: '%s'", comment));
        }

        // Retained comment must be present
        assert(pomoSrc.canFind("// Se já resta menos de 1 minuto, limita ao mínimo de 10s"),
            "Retained comment missing in src/pomodoro.d: '// Se já resta menos de 1 minuto, limita ao mínimo de 10s'");
    }

    // 3. src/sound.d
    if (exists("src/sound.d"))
    {
        string soundSrc = readText("src/sound.d");
        string[] prohibitedSound = [
            "// Chime zen arpejado relaxante",
            "// Sino suave de retorno ao foco",
            "// Toque sutil de madeira",
            "// RIFF Chunk",
            "// \"fmt \" subchunk",
            "// Subchunk1Size = 16 para PCM",
            "// AudioFormat = 1 (PCM)",
            "// NumChannels = 2 (Stereo)",
            "// \"data\" subchunk",
            "// Harmônicos rústicos de sino de vento / tigela tibetana",
            "// Fundamental",
            "// Primeiro harmônico de campânula",
            "// Segundo harmônico",
            "// Brilho suave",
            "// Attack suave (4ms) para evitar estalos de início",
            "// C5 (523Hz)",
            "// Sino duplo calmo",
            "// Toque sutil e rápido de madeira (35ms)",
            "/// Gerenciador de Áudio Procedural",
            "/// Toca um som de forma assíncrona em uma thread secundária sem travar a UI",
            "// Fallback silencioso / não trava execução",
            "/// Toca sincronicamente (usado para testes do alarme)",
            "// 1. Tenta PipeWire",
            "// 2. Tenta PulseAudio",
            "// 3. Tenta ffplay"
        ];
        foreach (comment; prohibitedSound)
        {
            assert(!soundSrc.canFind(comment),
                format("Prohibited comment found in src/sound.d: '%s'", comment));
        }

        // Retained comments in sound.d
        assert(soundSrc.canFind("/// Gera cabeçalho WAV de 44 bytes para dados PCM 16-bit Stereo (2 canais)"),
            "Retained comment missing in src/sound.d: WAV header ddoc");
        assert(soundSrc.canFind("/// Adiciona um tom harmônico de sino acústico/chime com distribuição estéreo"),
            "Retained comment missing in src/sound.d: addChimeTone ddoc");
        assert(soundSrc.canFind("/// Normaliza os canais de áudio para volume ótimo e limpo (90% do máximo)"),
            "Retained comment missing in src/sound.d: normalizeAudio ddoc");
        assert(soundSrc.canFind("/// Gera o buffer de áudio WAV para o som solicitado"),
            "Retained comment missing in src/sound.d: generateProceduralSound ddoc");
        assert(soundSrc.canFind("// Salva na memória RAM (/dev/shm) para leitura instantânea e sem desgaste de disco"),
            "Retained comment missing in src/sound.d: RAM /dev/shm comment");
        assert(soundSrc.canFind("// Fallback para campainha de terminal caso nenhum servidor de áudio responda"),
            "Retained comment missing in src/sound.d: Terminal bell fallback comment");
    }

    // 4. src/terminal.d
    if (exists("src/terminal.d"))
    {
        string termSrc = readText("src/terminal.d");
        string[] prohibitedTerm = [
            "// Registra manipuladores de sinal",
            "case 27: return Key.Escape; // ESC",
            "// Sequências de escape como setas"
        ];
        foreach (comment; prohibitedTerm)
        {
            assert(!termSrc.canFind(comment),
                format("Prohibited comment found in src/terminal.d: '%s'", comment));
        }

        // Retained comments in terminal.d
        assert(termSrc.canFind("enum SIGWINCH = 28; // Window size change signal (POSIX)"),
            "Retained comment missing in src/terminal.d: SIGWINCH");
        assert(termSrc.canFind("// Restaura terminal em caso de SIGINT/SIGTERM"),
            "Retained comment missing in src/terminal.d: restore on SIGINT");
        assert(termSrc.canFind("// ANSI reset cursor and screen"),
            "Retained comment missing in src/terminal.d: ANSI reset");
    }

    // 5. src/ui.d
    if (exists("src/ui.d"))
    {
        string uiSrc = readText("src/ui.d");
        string[] prohibitedUi = [
            "// Cores ANSI rústicas (Tons quentes de âmbar, madeira, cobre e pergaminho)",
            "// Tons de madeira e pergaminho",
            "// Castanho escuro",
            "// Carvalho / canela",
            "// Destaques de fase",
            "// Laranja terracota / fogo",
            "// Dígitos grandes estilizados em blocos texturizados (5 linhas de altura)",
            "// 0\n",
            "// Fallback ASCII para compatibilidade total",
            "// Animação de Fogueira / Brasas Rústicas (8 frames)",
            "// Símbolos de ampulheta giratória",
            "// =========================================================================",
            "// Ignora sequências de escape ANSI (\\033[...m, etc.)",
            "// Se o tamanho da janela mudou, limpa a tela inteira para evitar caracteres fantasmas",
            "// Cores e descrições da fase",
            "// Seleciona layout adaptativo de acordo com o espaço disponível no terminal",
            "// Escreve todo o buffer atômico para evitar flicker",
            "// Limpa qualquer resíduo vertical abaixo",
            "// Título",
            "// Ciclos e Som",
            "// 2 espaços entre cycle e sound",
            "int d3 = 10; // :",
            "// 5 digitos + 4 espacos",
            "int clockVis = cast(int)visibleWidth(app.data) + 4; // \"[ \" e \" ]\"",
            "int badgeVis = cast(int)visibleWidth(label) + 4; // \"[ \" e \" ]\"",
            "// 3 (left \"║ \") + 1 (open) + barWidth",
            "// 3 (left \"║ \") + (barWidth + 2)",
            "// 3 (left \"║ \") + textVis + pad + 1 (right \"║\") = width",
            "// Fogueira animada",
            "int fireVis = cast(int)visibleWidth(fireFrame[row]); // 11",
            "// 3 (left \"║ \") + fireVis",
            "// 2 (left \"║ \") + totalVis + pad + 2 (right \" ║\") = width"
        ];
        foreach (comment; prohibitedUi)
        {
            assert(!uiSrc.canFind(comment),
                format("Prohibited comment found in src/ui.d: '%s'", comment));
        }

        // Retained comments in ui.d
        assert(uiSrc.canFind("// Helper para cálculo exato de largura visual no terminal (Unicode / Emojis / ANSI)"),
            "Retained comment missing in src/ui.d: visibleWidth helper comment");
    }

    // 6. src/i18n.d
    if (exists("src/i18n.d"))
    {
        string i18nSrc = readText("src/i18n.d");
        string[] prohibitedI18n = [
            "    // Help text\n    string helpTitle;",
            "    // Sound test\n    string soundTestStart;",
            "    // Phases\n    string phaseWork;",
            "    // Sound status\n    string soundOn;",
            "    // Cycle indicators\n    string cycleLabelFull;",
            "    // Status badges\n    string statusActivePrefix;",
            "    // Stats\n    string statsElapsedFull;",
            "    // Quotes and atmospheric text\n    string[4] sideQuotes;",
            "    // Responsive shortcuts\n    string[6] shortcutsFull;"
        ];
        foreach (comment; prohibitedI18n)
        {
            assert(!i18nSrc.canFind(comment),
                format("Prohibited comment found in src/i18n.d: '%s'", comment));
        }

        // Retained unit test labels in i18n.d
        assert(i18nSrc.canFind("// TC-I18N-01"), "Retained unit test comment missing: TC-I18N-01");
        assert(i18nSrc.canFind("// TC-I18N-08"), "Retained unit test comment missing: TC-I18N-08");
    }
}
