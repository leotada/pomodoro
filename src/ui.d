module ui;

import std.array : Appender, appender;
import std.format : formattedWrite;
import std.stdio : write, stdout;
import std.algorithm : max, min;
import std.string : indexOf;

import pomodoro;
import terminal;
import sound;
import i18n;

// Cores ANSI rústicas (Tons quentes de âmbar, madeira, cobre e pergaminho)
struct RusticColors
{
    enum Reset       = "\033[0m";
    enum Bold        = "\033[1m";
    enum Dim         = "\033[2m";
    enum Italic      = "\033[3m";

    // Tons de madeira e pergaminho
    enum WoodDark    = "\033[38;5;94m";   // Castanho escuro
    enum WoodMed     = "\033[38;5;137m";  // Carvalho / canela
    enum Amber       = "\033[38;5;214m";  // Âmbar dourado
    enum GoldBright  = "\033[1;38;5;220m";// Ouro brilhante
    enum Cream       = "\033[38;5;230m";  // Creme suave

    // Destaques de fase
    enum FocusColor  = "\033[1;38;5;208m";// Laranja terracota / fogo
    enum ShortBrkCol = "\033[1;38;5;108m";// Verde sálvia / musgo
    enum LongBrkCol  = "\033[1;38;5;73m"; // Azul chá / lago sereno
    enum PauseCol    = "\033[1;38;5;221m";// Amarelo mostarda
    enum Muted       = "\033[38;5;242m";  // Cinza pedra rústica
}

// Dígitos grandes estilizados em blocos texturizados (5 linhas de altura)
private immutable string[5][11] DIGITS_UNICODE = [
    // 0
    [
        " ████ ",
        "█░  ░█",
        "█░  ░█",
        "█░  ░█",
        " ████ "
    ],
    // 1
    [
        "  ██  ",
        " ░██  ",
        "  ██  ",
        "  ██  ",
        " ████ "
    ],
    // 2
    [
        " ████ ",
        "░   ░█",
        " ████ ",
        "█░    ",
        "██████"
    ],
    // 3
    [
        " ████ ",
        "░   ░█",
        "  ███ ",
        "░   ░█",
        " ████ "
    ],
    // 4
    [
        "█░  ░█",
        "█░  ░█",
        "██████",
        "░   ░█",
        "    ░█"
    ],
    // 5
    [
        "██████",
        "█░    ",
        "█████ ",
        "░   ░█",
        "██████"
    ],
    // 6
    [
        " ████ ",
        "█░    ",
        "█████ ",
        "█░  ░█",
        " ████ "
    ],
    // 7
    [
        "██████",
        "░   ░█",
        "   ░█ ",
        "  ░█  ",
        "  ██  "
    ],
    // 8
    [
        " ████ ",
        "█░  ░█",
        " ████ ",
        "█░  ░█",
        " ████ "
    ],
    // 9
    [
        " ████ ",
        "█░  ░█",
        " █████",
        "░   ░█",
        " ████ "
    ],
    // : (Separador)
    [
        "      ",
        "  ▓▓  ",
        "      ",
        "  ▓▓  ",
        "      "
    ]
];

// Fallback ASCII para compatibilidade total
private immutable string[5][11] DIGITS_ASCII = [
    [" ### ", "#   #", "#   #", "#   #", " ### "],
    ["  #  ", " ##  ", "  #  ", "  #  ", " ### "],
    [" ### ", "    #", " ### ", "#    ", "#####"],
    [" ### ", "    #", "  ## ", "    #", " ### "],
    ["#   #", "#   #", "#####", "    #", "    #"],
    ["#####", "#    ", "#### ", "    #", "#### "],
    [" ### ", "#    ", "#### ", "#   #", " ### "],
    ["#####", "    #", "   # ", "  #  ", "  #  "],
    [" ### ", "#   #", " ### ", "#   #", " ### "],
    [" ### ", "#   #", " ####", "    #", " ### "],
    ["     ", "  #  ", "     ", "  #  ", "     "]
];

// Animação de Fogueira / Brasas Rústicas (8 frames)
private immutable string[4][8] FIRE_FRAMES = [
    [
        "   ( . )   ",
        "  ( : ∴ )  ",
        " ( * . : ) ",
        "  \\=====/  "
    ],
    [
        "  ( : . )  ",
        " ( . ∴ * ) ",
        " ( : * . ) ",
        "  \\=====/  "
    ],
    [
        "   ( * )   ",
        "  ( ∴ : )  ",
        " ( . * : ) ",
        "  \\=====/  "
    ],
    [
        "  ( . : )  ",
        " ( * . ∴ ) ",
        " ( * : . ) ",
        "  \\=====/  "
    ],
    [
        "   ( ∴ )   ",
        "  ( : * )  ",
        " ( : . ∴ ) ",
        "  \\=====/  "
    ],
    [
        "  ( * : )  ",
        " ( ∴ . : ) ",
        " ( . * * ) ",
        "  \\=====/  "
    ],
    [
        "   ( . )   ",
        "  ( * ∴ )  ",
        " ( * : . ) ",
        "  \\=====/  "
    ],
    [
        "  ( : * )  ",
        " ( . : ∴ ) ",
        " ( : * . ) ",
        "  \\=====/  "
    ]
];

// Símbolos de ampulheta giratória
private immutable string[4] HOURGLASS_FRAMES = ["⏳", "◴", "⌛", "◶"];
private immutable string[4] HOURGLASS_ASCII  = ["\\", "|", "/", "-"];

// =============================================================================
// Helper para cálculo exato de largura visual no terminal (Unicode / Emojis / ANSI)
// =============================================================================
import std.utf : decode;

extern(C) int wcwidth(dchar c) nothrow @nogc;

size_t visibleWidth(string s)
{
    size_t w = 0;
    size_t i = 0;
    while (i < s.length)
    {
        // Ignora sequências de escape ANSI (\033[...m, etc.)
        if (s[i] == '\033' && i + 1 < s.length && s[i + 1] == '[')
        {
            i += 2;
            while (i < s.length && ((s[i] >= '0' && s[i] <= '9') || s[i] == ';'))
            {
                i++;
            }
            if (i < s.length) i++;
            continue;
        }

        dchar c = decode(s, i);
        if (c < 32 || (c >= 0x7F && c < 0xA0))
            continue;

        int cw = wcwidth(c);
        if (cw > 0)
            w += cw;
        else if (cw < 0)
            w += 1;
    }
    return w;
}

class Renderer
{
    private bool asciiMode;
    private Language lang;
    private const(TranslationStrings)* tr;
    private int animFrame = 0;
    private TerminalSize lastSize;
    private int leftMargin = 0;
    private Appender!string buffer;

    this(bool asciiMode = false, Language lang = Language.PT)
    {
        this.asciiMode = asciiMode;
        this.lang = lang;
        this.tr = getTranslations(lang);
        this.buffer = appender!string();
        this.lastSize = TerminalSize(0, 0);
    }

    void updateAnim()
    {
        animFrame = (animFrame + 1) % 64;
    }

    private void putMargin()
    {
        foreach (_; 0 .. leftMargin) buffer.put(" ");
    }

    private void endLine()
    {
        buffer.put("\033[K\n");
    }

    void render(Pomodoro pomo, SoundEngine sound, TerminalSize termSize)
    {
        buffer = appender!string();

        // Se o tamanho da janela mudou, limpa a tela inteira para evitar caracteres fantasmas
        if (termSize.columns != lastSize.columns || termSize.rows != lastSize.rows)
        {
            buffer.put("\033[2J\033[H");
            lastSize = termSize;
        }
        else
        {
            buffer.put("\033[H");
        }

        long remSec = pomo.getRemainingSeconds();
        if (remSec < 0) remSec = 0;
        long minutes = remSec / 60;
        long seconds = remSec % 60;

        float progress = pomo.getProgress();
        PomodoroMode mode = pomo.getMode();
        bool paused = pomo.isPaused();

        // Cores e descrições da fase
        string phaseColor;
        string phaseName;
        final switch (mode)
        {
            case PomodoroMode.Work:
                phaseColor = RusticColors.FocusColor;
                phaseName  = tr.phaseWork;
                break;
            case PomodoroMode.ShortBreak:
                phaseColor = RusticColors.ShortBrkCol;
                phaseName  = tr.phaseShortBreak;
                break;
            case PomodoroMode.LongBreak:
                phaseColor = RusticColors.LongBrkCol;
                phaseName  = tr.phaseLongBreak;
                break;
        }

        int cols = termSize.columns;
        int rows = termSize.rows;

        // Seleciona layout adaptativo de acordo com o espaço disponível no terminal
        if (cols < 36 || rows < 6)
        {
            renderUltraMini(pomo, sound, minutes, seconds, progress, phaseName, phaseColor, paused, cols);
        }
        else if (cols < 48 || rows < 14)
        {
            renderMini(pomo, sound, minutes, seconds, progress, phaseName, phaseColor, paused, cols, rows);
        }
        else if (cols < 58 || rows < 20)
        {
            renderCompact(pomo, sound, minutes, seconds, progress, phaseName, phaseColor, paused, cols, rows);
        }
        else
        {
            renderFull(pomo, sound, minutes, seconds, progress, phaseName, phaseColor, paused, cols, rows);
        }

        // Escreve todo o buffer atômico para evitar flicker
        write(buffer.data);
        stdout.flush();
    }

    // =========================================================================
    // LAYOUT COMPLETO (Desktop / Janelas Padrão: cols >= 58 e rows >= 20)
    // =========================================================================
    private void renderFull(Pomodoro pomo, SoundEngine sound, long minutes, long seconds, float progress, string phaseName, string phaseColor, bool paused, int cols, int rows)
    {
        int width = min(78, cols - 4);
        int boxHeight = 21;

        leftMargin = max(0, (cols - width) / 2);
        int topMargin = max(0, (rows - boxHeight) / 2);

        foreach (_; 0 .. topMargin) buffer.put("\033[K\n");

        renderBoxTop(width);
        renderHeader(pomo, sound, width);
        renderBoxDivider(width);
        renderBlankLine(width);
        renderBigClock(minutes, seconds, phaseColor, width);
        renderBlankLine(width);
        renderStatusBadge(phaseName, phaseColor, paused, width);
        renderBlankLine(width);
        renderProgressBar(progress, phaseColor, width);
        renderSubBarTexture(width);
        renderStats(pomo, width);
        renderAnimationSection(pomo, width);
        renderBoxDivider(width);
        renderFooter(width);
        renderBoxBottom(width);

        buffer.put("\033[J"); // Limpa qualquer resíduo vertical abaixo
    }

    // =========================================================================
    // LAYOUT COMPACTO (Janelas Médias: cols >= 48 e rows >= 14)
    // =========================================================================
    private void renderCompact(Pomodoro pomo, SoundEngine sound, long minutes, long seconds, float progress, string phaseName, string phaseColor, bool paused, int cols, int rows)
    {
        int width = min(66, cols - 2);
        int boxHeight = 13;

        leftMargin = max(0, (cols - width) / 2);
        int topMargin = max(0, (rows - boxHeight) / 2);

        foreach (_; 0 .. topMargin) buffer.put("\033[K\n");

        renderBoxTop(width);
        renderHeader(pomo, sound, width);
        renderBoxDivider(width);
        renderBigClock(minutes, seconds, phaseColor, width);
        renderStatusBadge(phaseName, phaseColor, paused, width);
        renderProgressBar(progress, phaseColor, width);
        renderStats(pomo, width);
        renderBoxDivider(width);
        renderFooter(width);
        renderBoxBottom(width);

        buffer.put("\033[J");
    }

    // =========================================================================
    // LAYOUT MINI (Split panes / Janelas Pequenas: cols >= 36 e rows >= 6)
    // =========================================================================
    private void renderMini(Pomodoro pomo, SoundEngine sound, long minutes, long seconds, float progress, string phaseName, string phaseColor, bool paused, int cols, int rows)
    {
        int width = min(54, cols - 2);
        int boxHeight = 7;

        leftMargin = max(0, (cols - width) / 2);
        int topMargin = max(0, (rows - boxHeight) / 2);

        foreach (_; 0 .. topMargin) buffer.put("\033[K\n");

        renderBoxTop(width);
        renderMiniHeader(pomo, sound, phaseName, phaseColor, width);
        renderBoxDivider(width);
        renderMiniClock(minutes, seconds, phaseColor, paused, width);
        renderProgressBar(progress, phaseColor, width);
        renderMiniFooter(width);
        renderBoxBottom(width);

        buffer.put("\033[J");
    }

    // =========================================================================
    // LAYOUT ULTRA-MINI (Extremamente Pequeno / Terminal estreito: cols < 36 ou rows < 6)
    // =========================================================================
    private void renderUltraMini(Pomodoro pomo, SoundEngine sound, long minutes, long seconds, float progress, string phaseName, string phaseColor, bool paused, int cols)
    {
        leftMargin = 0;
        buffer.put(RusticColors.GoldBright);
        buffer.put(asciiMode ? "[*] " : "⏳ ");
        buffer.put(phaseColor);
        buffer.put(RusticColors.Bold);
        formattedWrite(buffer, "%02d:%02d", minutes, seconds);
        buffer.put(RusticColors.Reset);

        if (paused)
        {
            buffer.put(RusticColors.PauseCol);
            buffer.put(tr.statusPausedUltra);
        }
        else
        {
            buffer.put(RusticColors.WoodMed);
            formattedWrite(buffer, " (%d%%) %d/%d", cast(int)(progress * 100), pomo.getCurrentCycle(), pomo.getMaxCycles());
        }
        buffer.put(RusticColors.Reset);
        endLine();

        buffer.put(RusticColors.Muted);
        buffer.put(tr.shortcutsUltra);
        buffer.put(RusticColors.Reset);
        endLine();

        buffer.put("\033[J");
    }

    // =========================================================================
    // COMPONENTES DE RENDERIZAÇÃO
    // =========================================================================

    private void renderBoxTop(int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        if (asciiMode)
        {
            buffer.put("+");
            foreach (_; 0 .. width - 2) buffer.put("-");
            buffer.put("+");
        }
        else
        {
            buffer.put("╔");
            foreach (_; 0 .. width - 2) buffer.put("═");
            buffer.put("╗");
        }
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderBoxBottom(int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        if (asciiMode)
        {
            buffer.put("+");
            foreach (_; 0 .. width - 2) buffer.put("-");
            buffer.put("+");
        }
        else
        {
            buffer.put("╚");
            foreach (_; 0 .. width - 2) buffer.put("═");
            buffer.put("╝");
        }
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderBoxDivider(int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        if (asciiMode)
        {
            buffer.put("+");
            foreach (_; 0 .. width - 2) buffer.put("-");
            buffer.put("+");
        }
        else
        {
            buffer.put("╠");
            foreach (_; 0 .. width - 2) buffer.put("═");
            buffer.put("╣");
        }
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderBlankLine(int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");
        buffer.put(RusticColors.Reset);
        foreach (_; 0 .. width - 2) buffer.put(" ");
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderHeader(Pomodoro pomo, SoundEngine sound, int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "| " : "║ ");
        
        // Título
        buffer.put(RusticColors.GoldBright);
        string titleStr = asciiMode ? "[*] POMODORO" : "◈ POMODORO";
        buffer.put(titleStr);
        
        // Ciclos e Som
        string cycleStr = formatCycleTokens(pomo, width);
        string soundStr = sound.isEnabled() ? tr.soundOn : tr.soundOff;

        int titleVis = cast(int)visibleWidth(titleStr);
        int cycleVis = cast(int)visibleWidth(cycleStr);
        int soundVis = cast(int)visibleWidth(soundStr);
        int contentVis = titleVis + cycleVis + soundVis + 2; // 2 espaços entre cycle e sound
        int pad = max(1, (width - 4) - contentVis);

        foreach (_; 0 .. pad) buffer.put(" ");

        buffer.put(RusticColors.WoodMed);
        buffer.put(cycleStr);
        buffer.put("  ");
        buffer.put(RusticColors.Amber);
        buffer.put(soundStr);

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? " |" : " ║");
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderMiniHeader(Pomodoro pomo, SoundEngine sound, string phaseName, string phaseColor, int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "| " : "║ ");

        buffer.put(RusticColors.GoldBright);
        string iconStr = asciiMode ? "[*] " : "◈ ";
        buffer.put(iconStr);
        buffer.put(phaseColor);
        buffer.put(RusticColors.Bold);
        string shortPhase = phaseName.length > 8 ? phaseName[0..8] : phaseName;
        buffer.put(shortPhase);
        buffer.put(RusticColors.Reset);

        auto app = appender!string();
        formattedWrite(app, "%d/%d", pomo.getCurrentCycle(), pomo.getMaxCycles());
        string soundStr = sound.isEnabled() ? tr.soundOnShort : tr.soundOffShort;

        int titleVis = cast(int)(visibleWidth(iconStr) + visibleWidth(shortPhase));
        int rightVis = cast(int)(visibleWidth(app.data) + 1 + visibleWidth(soundStr));
        int pad = max(1, (width - 4) - titleVis - rightVis);
        foreach (_; 0 .. pad) buffer.put(" ");

        buffer.put(RusticColors.WoodMed);
        buffer.put(app.data);
        buffer.put(" ");
        buffer.put(RusticColors.Amber);
        buffer.put(soundStr);

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? " |" : " ║");
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private string formatCycleTokens(Pomodoro pomo, int width)
    {
        int cur = pomo.getCurrentCycle();
        int maxC = pomo.getMaxCycles();
        auto app = appender!string();
        
        if (width >= 56)
        {
            app.put(tr.cycleLabelFull);
            foreach (i; 1 .. maxC + 1)
            {
                if (i < cur)
                {
                    app.put(asciiMode ? "# " : "● ");
                }
                else if (i == cur)
                {
                    app.put(asciiMode ? "* " : "◈ ");
                }
                else
                {
                    app.put(asciiMode ? "- " : "○ ");
                }
            }
            formattedWrite(app, "] %d/%d", cur, maxC);
        }
        else
        {
            formattedWrite(app, tr.cycleLabelShort, cur, maxC);
        }
        return app.data;
    }

    private void renderBigClock(long minutes, long seconds, string color, int width)
    {
        int d1 = cast(int)(minutes / 10);
        int d2 = cast(int)(minutes % 10);
        int d3 = 10; // :
        int d4 = cast(int)(seconds / 10);
        int d5 = cast(int)(seconds % 10);

        auto digits = asciiMode ? DIGITS_ASCII : DIGITS_UNICODE;
        int digitWidth = asciiMode ? 5 : 6;
        int totalClockWidth = digitWidth * 5 + 4; // 5 digitos + 4 espacos

        int innerSpace = width - 2;
        int leftPad = max(1, (innerSpace - totalClockWidth) / 2);
        int rightPad = max(0, innerSpace - totalClockWidth - leftPad);

        foreach (row; 0 .. 5)
        {
            putMargin();
            buffer.put(RusticColors.WoodDark);
            buffer.put(asciiMode ? "|" : "║");
            
            foreach (_; 0 .. leftPad) buffer.put(" ");

            buffer.put(color);
            buffer.put(RusticColors.Bold);

            buffer.put(digits[d1][row]);
            buffer.put(" ");
            buffer.put(digits[d2][row]);
            buffer.put(" ");
            buffer.put(digits[d3][row]);
            buffer.put(" ");
            buffer.put(digits[d4][row]);
            buffer.put(" ");
            buffer.put(digits[d5][row]);

            buffer.put(RusticColors.Reset);
            foreach (_; 0 .. rightPad) buffer.put(" ");

            buffer.put(RusticColors.WoodDark);
            buffer.put(asciiMode ? "|" : "║");
            buffer.put(RusticColors.Reset);
            endLine();
        }
    }

    private void renderMiniClock(long minutes, long seconds, string color, bool paused, int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");

        auto app = appender!string();
        formattedWrite(app, "%02d : %02d", minutes, seconds);
        if (paused) app.put(tr.statusPausedMini);

        int clockVis = cast(int)visibleWidth(app.data) + 4; // "[ " e " ]"
        int innerSpace = width - 2;
        int leftPad = max(1, (innerSpace - clockVis) / 2);
        int rightPad = max(0, innerSpace - clockVis - leftPad);

        foreach (_; 0 .. leftPad) buffer.put(" ");

        buffer.put(color);
        buffer.put(RusticColors.Bold);
        buffer.put("[ ");
        buffer.put(app.data);
        buffer.put(" ]");
        buffer.put(RusticColors.Reset);

        foreach (_; 0 .. rightPad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderStatusBadge(string phaseName, string color, bool paused, int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");

        string label;
        string badgeColor;
        if (paused)
        {
            label = (width >= 56) ? tr.statusPausedFull : tr.statusPausedShort;
            badgeColor = RusticColors.PauseCol;
        }
        else
        {
            label = (width >= 56) ? tr.statusActivePrefix ~ phaseName : phaseName;
            badgeColor = color;
        }

        int badgeVis = cast(int)visibleWidth(label) + 4; // "[ " e " ]"
        int innerSpace = width - 2;
        int leftPad = max(1, (innerSpace - badgeVis) / 2);
        int rightPad = max(0, innerSpace - badgeVis - leftPad);

        foreach (_; 0 .. leftPad) buffer.put(" ");

        buffer.put(badgeColor);
        buffer.put(RusticColors.Bold);
        buffer.put("[ ");
        buffer.put(label);
        buffer.put(" ]");
        buffer.put(RusticColors.Reset);

        foreach (_; 0 .. rightPad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderProgressBar(float progress, string color, int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|  " : "║  ");

        int percent = cast(int)(progress * 100.0f);
        if (percent > 100) percent = 100;
        if (percent < 0) percent = 0;

        int barWidth = width - 16;
        if (barWidth < 8) barWidth = 8;

        float filledF = progress * barWidth;
        int fullBlocks = cast(int)filledF;
        float frac = filledF - fullBlocks;

        buffer.put(RusticColors.WoodMed);
        buffer.put(asciiMode ? "[" : "╢");

        buffer.put(color);
        foreach (_; 0 .. fullBlocks)
        {
            buffer.put(asciiMode ? "#" : "█");
        }

        if (fullBlocks < barWidth)
        {
            if (asciiMode)
            {
                buffer.put(frac > 0.5f ? "=" : "-");
            }
            else
            {
                if (frac >= 0.75f) buffer.put("▓");
                else if (frac >= 0.50f) buffer.put("▒");
                else if (frac >= 0.25f) buffer.put("░");
                else buffer.put("░");
            }

            buffer.put(RusticColors.Muted);
            foreach (_; (fullBlocks + 1) .. barWidth)
            {
                buffer.put(asciiMode ? "." : "░");
            }
        }

        buffer.put(RusticColors.WoodMed);
        buffer.put(asciiMode ? "]" : "╟");

        buffer.put(RusticColors.GoldBright);
        formattedWrite(buffer, " %3d%%", percent);
        buffer.put(RusticColors.Reset);

        // 3 (left "║  ") + 1 (open) + barWidth + 1 (close) + 5 (" 100%") + pad + 1 (right "║") = width
        int used = 3 + 1 + barWidth + 1 + 5 + 1;
        int remainingPad = max(0, width - used);
        foreach (_; 0 .. remainingPad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderSubBarTexture(int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|  " : "║  ");

        int barWidth = width - 16;
        if (barWidth < 8) barWidth = 8;

        buffer.put(RusticColors.Muted);
        foreach (i; 0 .. barWidth + 2)
        {
            buffer.put((i % 2 == 0) ? "~" : " ");
        }

        // 3 (left "║  ") + (barWidth + 2) + pad + 1 (right "║") = width
        int used = 3 + (barWidth + 2) + 1;
        int remainingPad = max(0, width - used);
        foreach (_; 0 .. remainingPad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderStats(Pomodoro pomo, int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|  " : "║  ");

        long elSec = pomo.getElapsedSeconds();
        long elMin = elSec / 60;
        long elRemainder = elSec % 60;
        int totalSessions = pomo.getCompletedCycles();

        auto app = appender!string();
        if (width >= 56)
        {
            formattedWrite(app, tr.statsElapsedFull, elMin, elRemainder, totalSessions);
        }
        else
        {
            formattedWrite(app, tr.statsElapsedShort, elMin, elRemainder, totalSessions);
        }

        buffer.put(RusticColors.Cream);
        buffer.put(app.data);
        buffer.put(RusticColors.Reset);

        int textVis = cast(int)visibleWidth(app.data);
        // 3 (left "║  ") + textVis + pad + 1 (right "║") = width
        int pad = max(0, width - (3 + textVis + 1));
        foreach (_; 0 .. pad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderAnimationSection(Pomodoro pomo, int width)
    {
        int frameIdx = (animFrame / 2) % 8;
        auto fireFrame = FIRE_FRAMES[frameIdx];

        string currentQuote = tr.sideQuotes[(animFrame / 16) % tr.sideQuotes.length];

        foreach (row; 0 .. 4)
        {
            putMargin();
            buffer.put(RusticColors.WoodDark);
            buffer.put(asciiMode ? "|  " : "║  ");

            // Fogueira animada
            buffer.put(RusticColors.Amber);
            buffer.put(RusticColors.Bold);
            buffer.put(fireFrame[row]);
            buffer.put(RusticColors.Reset);

            buffer.put("  ");

            int fireVis = cast(int)visibleWidth(fireFrame[row]); // 11
            int textVis = 0;

            if (row == 1)
            {
                buffer.put(RusticColors.WoodMed);
                buffer.put(RusticColors.Italic);
                buffer.put(currentQuote);
                buffer.put(RusticColors.Reset);
                textVis = cast(int)visibleWidth(currentQuote);
            }
            else if (row == 2)
            {
                string statusMsg = pomo.isPaused() ? tr.quotePaused : tr.quoteRunning;
                buffer.put(RusticColors.Muted);
                buffer.put(statusMsg);
                buffer.put(RusticColors.Reset);
                textVis = cast(int)visibleWidth(statusMsg);
            }

            // 3 (left "║  ") + fireVis + 2 ("  ") + textVis + pad + 1 (right "║") = width
            int pad = max(0, width - (3 + fireVis + 2 + textVis + 1));
            foreach (_; 0 .. pad) buffer.put(" ");

            buffer.put(RusticColors.WoodDark);
            buffer.put(asciiMode ? "|" : "║");
            buffer.put(RusticColors.Reset);
            endLine();
        }
    }

    private void renderFooter(int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "| " : "║ ");

        const(string)[] shortcuts;
        if (width >= 78)
        {
            shortcuts = tr.shortcutsFull;
        }
        else if (width >= 60)
        {
            shortcuts = tr.shortcutsMedium;
        }
        else
        {
            shortcuts = tr.shortcutsSmall;
        }

        buffer.put(RusticColors.WoodMed);
        int totalVis = 0;
        foreach (i, s; shortcuts)
        {
            if (i > 0) { buffer.put(" "); totalVis += 1; }
            buffer.put(RusticColors.Amber);
            auto closeBracket = s.indexOf(']');
            if (closeBracket != -1)
            {
                buffer.put(s[0 .. closeBracket + 1]);
                buffer.put(RusticColors.Cream);
                buffer.put(s[closeBracket + 1 .. $]);
            }
            else
            {
                buffer.put(s);
            }
            totalVis += visibleWidth(s);
        }

        // 2 (left "║ ") + totalVis + pad + 2 (right " ║") = width
        int pad = max(0, width - (2 + totalVis + 2));
        foreach (_; 0 .. pad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? " |" : " ║");
        buffer.put(RusticColors.Reset);
        endLine();
    }

    private void renderMiniFooter(int width)
    {
        putMargin();
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "| " : "║ ");

        const(string)[] shortcuts = tr.shortcutsSmall;
        buffer.put(RusticColors.WoodMed);
        int totalVis = 0;
        foreach (i, s; shortcuts)
        {
            if (i > 0) { buffer.put(" "); totalVis += 1; }
            buffer.put(RusticColors.Amber);
            auto closeBracket = s.indexOf(']');
            if (closeBracket != -1)
            {
                buffer.put(s[0 .. closeBracket + 1]);
                buffer.put(RusticColors.Cream);
                buffer.put(s[closeBracket + 1 .. $]);
            }
            else
            {
                buffer.put(s);
            }
            totalVis += visibleWidth(s);
        }

        // 2 (left "║ ") + totalVis + pad + 2 (right " ║") = width
        int pad = max(0, width - (2 + totalVis + 2));
        foreach (_; 0 .. pad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? " |" : " ║");
        buffer.put(RusticColors.Reset);
        endLine();
    }
}

unittest
{
    import std.string : splitLines;

    // TC-UI-01: visibleWidth calculations
    assert(visibleWidth("Hello") == 5);
    assert(visibleWidth("\033[1;38;5;208mWORK / FOCUS\033[0m") == 12);
    assert(visibleWidth("╔════════╗") == 10);
    assert(visibleWidth("[Espaço] Pausar") == 15);
    assert(visibleWidth("[Space] Pause") == 13);
    assert(visibleWidth("[SOM: ON]") == 9);
    assert(visibleWidth("[SOUND: ON]") == 11);

    // Layout breakpoints test across PT and EN, ascii and unicode, running and paused
    TerminalSize[4] breakpoints = [
        TerminalSize(80, 24), // Desktop Full
        TerminalSize(60, 16), // Medium Compact
        TerminalSize(40, 8),  // Split Mini
        TerminalSize(30, 4)   // Ultra Mini
    ];

    PomodoroConfig cfgPT;
    cfgPT.lang = Language.PT;
    auto pomoPT = new Pomodoro(cfgPT);
    auto sound = new SoundEngine(false);

    PomodoroConfig cfgEN;
    cfgEN.lang = Language.EN;
    auto pomoEN = new Pomodoro(cfgEN);

    foreach (bp; breakpoints)
    {
        foreach (lang; [Language.PT, Language.EN])
        {
            foreach (ascii; [false, true])
            {
                auto r = new Renderer(ascii, lang);
                auto pomo = (lang == Language.PT) ? pomoPT : pomoEN;

                // Test unpaused
                r.render(pomo, sound, bp);
                assert(r.buffer.data.length > 0);

                // Test paused
                pomo.togglePause();
                r.render(pomo, sound, bp);
                assert(r.buffer.data.length > 0);
                pomo.togglePause(); // revert

                // Test short break
                pomo.nextPhase();
                r.render(pomo, sound, bp);
                assert(r.buffer.data.length > 0);

                // Test long break
                pomo.nextPhase();
                pomo.nextPhase();
                pomo.nextPhase();
                r.render(pomo, sound, bp);
                assert(r.buffer.data.length > 0);
                pomo.nextPhase(); // back to work
            }
        }
    }
}
