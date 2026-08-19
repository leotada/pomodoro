module i18n;

import std.string : strip, toLower;
import std.format : format;

enum Language
{
    PT,
    EN
}

struct TranslationStrings
{
    string helpTitle;
    string helpUsage;
    string helpOptionsHeader;
    string helpOptWork;
    string helpOptShortBreak;
    string helpOptLongBreak;
    string helpOptCycles;
    string helpOptLang;
    string helpOptNoSound;
    string helpOptTestSound;
    string helpOptAscii;
    string helpOptHelp;
    string helpShortcutsHeader;
    string[7] helpShortcuts;

    string soundTestStart;
    string soundTestWork;
    string soundTestBreak;
    string soundTestSuccess;

    string phaseWork;
    string phaseShortBreak;
    string phaseLongBreak;

    string soundOn;
    string soundOff;
    string soundOnShort;
    string soundOffShort;

    string cycleLabelFull;
    string cycleLabelShort;

    string statusActivePrefix;
    string statusPausedFull;
    string statusPausedShort;
    string statusPausedMini;
    string statusPausedUltra;

    string statsElapsedFull;
    string statsElapsedShort;

    string[4] sideQuotes;
    string quotePaused;
    string quoteRunning;

    string[6] shortcutsFull;
    string[6] shortcutsMedium;
    string[4] shortcutsSmall;
    string shortcutsUltra;
}

immutable TranslationStrings PT_TRANSLATIONS = TranslationStrings(
    "  POMODORO TIMER PARA TERMINAL (EM D)",
    "Uso: dub run -- [opções]\n  ou ./bin/pomodoro [opções]",
    "Opções:",
    "  -w, --work <min>        Duração do tempo de foco em minutos (padrão: 25)",
    "  -s, --short-break <min> Duração da pausa curta em minutos (padrão: 5)",
    "  -l, --long-break <min>  Duração da pausa longa em minutos (padrão: 15)",
    "  -c, --cycles <qtd>      Ciclos de foco antes da pausa longa (padrão: 4)",
    "  -L, --lang <pt|en>      Idioma da interface (padrão: pt)",
    "  --no-sound              Inicia com som desativado",
    "  --test-sound            Testa o sintetizador procedural de áudio e sai",
    "  --ascii                 Modo compatibilidade (apenas caracteres ASCII 7-bit)",
    "  -h, --help              Exibe esta mensagem de ajuda",
    "Atalhos no Terminal:",
    [
        "  [Espaço]   Pausar ou Retomar o temporizador",
        "  [N]/[Enter] Pular para a próxima fase",
        "  [R]        Reiniciar a fase atual",
        "  [+]        Adicionar 1 minuto ao tempo atual",
        "  [-]        Subtrair 1 minuto do tempo atual",
        "  [M]        Ligar / Desligar alarme procedural (Mute)",
        "  [Q]/[ESC]  Sair do programa"
    ],

    "\n🎵 Testando sintetizador procedural de áudio estéreo...",
    "1/2 - Tocando acorde zen relaxante de Fim de Foco (C5 -> E5 -> G5 -> B5 -> C6)...",
    "2/2 - Tocando sino duplo suave de Retorno ao Foco (A4 -> E5)...",
    "✅ Teste de som concluído com sucesso!\n",

    "TRABALHO / FOCO",
    "PAUSA CURTA",
    "PAUSA LONGA",

    "[SOM: ON]",
    "[SOM: OFF]",
    "[ON]",
    "[OFF]",

    "Ciclo: [ ",
    "Ciclo %d/%d",

    "FASE ATUAL: ",
    "PAUSADO - [Espaço para Retomar]",
    "PAUSADO",
    " (PAUSADO)",
    " [PAUSA]",

    "Decorrido: %02d:%02d  │  Pomodoros Concluídos: %d",
    "Decorrido: %02d:%02d  │  Feitos: %d",

    [
        "\"O tempo flui como a madeira que se esculpe.\"",
        "\"Foco no presente, passo a passo.\"",
        "\"Mente calma, trabalho constante.\"",
        "\"Aqueça sua concentração na forja do foco.\""
    ],
    "Timer em pausa. Respire fundo.",
    "Forjando progresso em seu dia...",

    [
        "[Espaço] Pausar",
        "[N] Próximo",
        "[R] Reiniciar",
        "[+/-] Ajustar",
        "[M] Mute",
        "[Q] Sair"
    ],
    [
        "[Esp]Pausa",
        "[N]Próx",
        "[R]Reset",
        "[+/-]Min",
        "[M]Mute",
        "[Q]Sair"
    ],
    [
        "[Esp]Pausa",
        "[N]Próx",
        "[R]Reset",
        "[Q]Sair"
    ],
    "[Espaço]Pausa [Q]Sair"
);

immutable TranslationStrings EN_TRANSLATIONS = TranslationStrings(
    "  TERMINAL POMODORO TIMER (IN D)",
    "Usage: dub run -- [options]\n  or   ./bin/pomodoro [options]",
    "Options:",
    "  -w, --work <min>        Focus work duration in minutes (default: 25)",
    "  -s, --short-break <min> Short break duration in minutes (default: 5)",
    "  -l, --long-break <min>  Long break duration in minutes (default: 15)",
    "  -c, --cycles <count>    Focus cycles before long break (default: 4)",
    "  -L, --lang <pt|en>      Interface language (default: pt)",
    "  --no-sound              Start with sound disabled",
    "  --test-sound            Test the procedural audio synthesizer and exit",
    "  --ascii                 Compatibility mode (ASCII 7-bit characters only)",
    "  -h, --help              Show this help message",
    "Terminal Shortcuts:",
    [
        "  [Space]    Pause or Resume the timer",
        "  [N]/[Enter] Skip to next phase",
        "  [R]        Reset current phase",
        "  [+]        Add 1 minute to current time",
        "  [-]        Subtract 1 minute from current time",
        "  [M]        Toggle procedural alarm sound (Mute)",
        "  [Q]/[ESC]  Quit program"
    ],

    "\n🎵 Testing stereo procedural audio synthesizer...",
    "1/2 - Playing relaxing zen chime for Work End (C5 -> E5 -> G5 -> B5 -> C6)...",
    "2/2 - Playing gentle double bell for Focus Return (A4 -> E5)...",
    "✅ Sound test completed successfully!\n",

    "WORK / FOCUS",
    "SHORT BREAK",
    "LONG BREAK",

    "[SOUND: ON]",
    "[SOUND: OFF]",
    "[ON]",
    "[OFF]",

    "Cycle: [ ",
    "Cycle %d/%d",

    "CURRENT PHASE: ",
    "PAUSED - [Space to Resume]",
    "PAUSED",
    " (PAUSED)",
    " [PAUSED]",

    "Elapsed: %02d:%02d  │  Completed Pomodoros: %d",
    "Elapsed: %02d:%02d  │  Done: %d",

    [
        "\"Time flows like carved wood.\"",
        "\"Focus on the present, step by step.\"",
        "\"Calm mind, steady work.\"",
        "\"Warm your concentration in the forge of focus.\""
    ],
    "Timer paused. Take a deep breath.",
    "Forging progress in your day...",

    [
        "[Space] Pause",
        "[N] Next",
        "[R] Reset",
        "[+/-] Adjust",
        "[M] Mute",
        "[Q] Quit"
    ],
    [
        "[Spc]Pause",
        "[N]Next",
        "[R]Reset",
        "[+/-]Min",
        "[M]Mute",
        "[Q]Quit"
    ],
    [
        "[Spc]Pause",
        "[N]Next",
        "[R]Reset",
        "[Q]Quit"
    ],
    "[Space]Pause [Q]Quit"
);

const(TranslationStrings)* getTranslations(Language lang) nothrow @nogc @safe
{
    final switch (lang)
    {
        case Language.PT:
            return &PT_TRANSLATIONS;
        case Language.EN:
            return &EN_TRANSLATIONS;
    }
}

Language parseLanguage(string input, Language defaultLang = Language.PT)
{
    string s = input.strip().toLower();
    if (s == "pt")
    {
        return Language.PT;
    }
    else if (s == "en")
    {
        return Language.EN;
    }
    else
    {
        throw new Exception(format("Unsupported language code '%s'. Supported options: 'pt', 'en'.", input));
    }
}

unittest
{
    import std.exception : assertThrown;

    // TC-I18N-01: Lowercase parsing
    assert(parseLanguage("pt") == Language.PT);
    assert(parseLanguage("en") == Language.EN);

    // TC-I18N-02: Uppercase and mixed-case parsing
    assert(parseLanguage("PT") == Language.PT);
    assert(parseLanguage("EN") == Language.EN);
    assert(parseLanguage("Pt") == Language.PT);
    assert(parseLanguage("En") == Language.EN);

    // TC-I18N-03: Padded strings with whitespace
    assert(parseLanguage("  en  ") == Language.EN);
    assert(parseLanguage("  pt\t\n") == Language.PT);

    // TC-I18N-04 & TC-I18N-05: Invalid values and empty string
    assertThrown!Exception(parseLanguage("es"));
    assertThrown!Exception(parseLanguage("fr"));
    assertThrown!Exception(parseLanguage("de"));
    assertThrown!Exception(parseLanguage(""));
    assertThrown!Exception(parseLanguage("   "));
    assertThrown!Exception(parseLanguage("123"));

    // TC-I18N-06: Zero-allocation pointer retrieval
    const(TranslationStrings)* trPT = getTranslations(Language.PT);
    const(TranslationStrings)* trEN = getTranslations(Language.EN);
    assert(trPT !is null);
    assert(trEN !is null);
    assert(trPT == &PT_TRANSLATIONS);
    assert(trEN == &EN_TRANSLATIONS);

    // TC-I18N-07: Catalog non-empty field checks
    assert(trPT.phaseWork.length > 0);
    assert(trEN.phaseWork.length > 0);
    assert(trPT.phaseShortBreak.length > 0);
    assert(trEN.phaseShortBreak.length > 0);
    assert(trPT.phaseLongBreak.length > 0);
    assert(trEN.phaseLongBreak.length > 0);
    assert(trPT.soundOn.length > 0);
    assert(trEN.soundOn.length > 0);
    assert(trPT.soundOff.length > 0);
    assert(trEN.soundOff.length > 0);
    assert(trPT.soundOnShort.length > 0);
    assert(trEN.soundOnShort.length > 0);
    assert(trPT.soundOffShort.length > 0);
    assert(trEN.soundOffShort.length > 0);
    assert(trPT.cycleLabelFull.length > 0);
    assert(trEN.cycleLabelFull.length > 0);
    assert(trPT.cycleLabelShort.length > 0);
    assert(trEN.cycleLabelShort.length > 0);
    assert(trPT.statusActivePrefix.length > 0);
    assert(trEN.statusActivePrefix.length > 0);
    assert(trPT.statusPausedFull.length > 0);
    assert(trEN.statusPausedFull.length > 0);
    assert(trPT.statusPausedShort.length > 0);
    assert(trEN.statusPausedShort.length > 0);
    assert(trPT.statusPausedMini.length > 0);
    assert(trEN.statusPausedMini.length > 0);
    assert(trPT.statusPausedUltra.length > 0);
    assert(trEN.statusPausedUltra.length > 0);
    assert(trPT.statsElapsedFull.length > 0);
    assert(trEN.statsElapsedFull.length > 0);
    assert(trPT.statsElapsedShort.length > 0);
    assert(trEN.statsElapsedShort.length > 0);
    assert(trPT.quotePaused.length > 0);
    assert(trEN.quotePaused.length > 0);
    assert(trPT.quoteRunning.length > 0);
    assert(trEN.quoteRunning.length > 0);
    assert(trPT.shortcutsUltra.length > 0);
    assert(trEN.shortcutsUltra.length > 0);

    // TC-I18N-08: Parity assertions for quotes and shortcut lengths
    assert(trPT.sideQuotes.length == 4);
    assert(trEN.sideQuotes.length == 4);
    foreach (q; trPT.sideQuotes) assert(q.length > 0);
    foreach (q; trEN.sideQuotes) assert(q.length > 0);

    assert(trPT.shortcutsFull.length == 6);
    assert(trEN.shortcutsFull.length == 6);
    assert(trPT.shortcutsMedium.length == 6);
    assert(trEN.shortcutsMedium.length == 6);
    assert(trPT.shortcutsSmall.length == 4);
    assert(trEN.shortcutsSmall.length == 4);
    assert(trPT.helpShortcuts.length == 7);
    assert(trEN.helpShortcuts.length == 7);
}
