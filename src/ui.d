module ui;

import std.array : Appender, appender;
import std.format : formattedWrite;
import std.stdio : write, stdout;
import std.algorithm : max, min;

import pomodoro;
import terminal;
import sound;

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

class Renderer
{
    private bool asciiMode;
    private int animFrame = 0;
    private Appender!string buffer;

    this(bool asciiMode = false)
    {
        this.asciiMode = asciiMode;
        this.buffer = appender!string();
    }

    void updateAnim()
    {
        animFrame = (animFrame + 1) % 64;
    }

    void render(Pomodoro pomo, SoundEngine sound, TerminalSize termSize)
    {
        buffer = appender!string();

        // Posiciona cursor no canto superior esquerdo para redesenho fluido (sem flicker)
        buffer.put("\033[H");

        long remSec = pomo.getRemainingSeconds();
        if (remSec < 0) remSec = 0;
        long minutes = remSec / 60;
        long seconds = remSec % 60;

        float progress = pomo.getProgress();
        PomodoroMode mode = pomo.getMode();
        bool paused = pomo.isPaused();

        // Determina cores da fase atual
        string phaseColor;
        string phaseName;
        string phaseBadge;

        final switch (mode)
        {
            case PomodoroMode.Work:
                phaseColor = RusticColors.FocusColor;
                phaseName  = "TRABALHO / FOCO";
                phaseBadge = asciiMode ? "[ FOCO ]" : "☕ [ FOCO ]";
                break;
            case PomodoroMode.ShortBreak:
                phaseColor = RusticColors.ShortBrkCol;
                phaseName  = "PAUSA CURTA";
                phaseBadge = asciiMode ? "[ PAUSA ]" : "🌿 [ PAUSA CURTA ]";
                break;
            case PomodoroMode.LongBreak:
                phaseColor = RusticColors.LongBrkCol;
                phaseName  = "PAUSA LONGA";
                phaseBadge = asciiMode ? "[ DESCANSO ]" : "🍃 [ PAUSA LONGA ]";
                break;
        }

        int width = 64;
        if (termSize.columns < width + 4)
        {
            width = max(40, termSize.columns - 4);
        }

        // Borda superior da caixa rústica
        renderBoxTop(width);

        // Cabeçalho: Título + Ciclos + Status de Som
        renderHeader(pomo, sound, width);

        // Divisória rústica
        renderBoxDivider(width);

        // Espaço em branco decorativo
        renderBlankLine(width);

        // Relógio com Dígitos Grandes em Arte de Caracteres
        renderBigClock(minutes, seconds, phaseColor, width);

        // Espaço em branco
        renderBlankLine(width);

        // Badge de Estado Central (Foco / Pausa / Pausado)
        renderStatusBadge(phaseName, phaseColor, paused, width);

        // Espaço
        renderBlankLine(width);

        // Barra de Progresso Rústica Texturizada
        renderProgressBar(progress, phaseColor, width);

        // Linha de textura decorativa (~ ~ ~ ~)
        renderSubBarTexture(width);

        // Informações de tempo e estatísticas
        renderStats(pomo, width);

        // Animação de Fogueira/Brasas rústicas e Ampulheta
        renderAnimationSection(pomo, width);

        // Divisória inferior
        renderBoxDivider(width);

        // Rodapé com atalhos de comando
        renderFooter(width);

        // Borda inferior da caixa rústica
        renderBoxBottom(width);

        // Escreve todo o buffer de uma só vez para evitar qualquer cintilação
        write(buffer.data);
        stdout.flush();
    }

    private void renderBoxTop(int width)
    {
        buffer.put(RusticColors.WoodDark);
        if (asciiMode)
        {
            buffer.put("+");
            foreach (_; 0 .. width - 2) buffer.put("-");
            buffer.put("+\n");
        }
        else
        {
            buffer.put("╔");
            foreach (_; 0 .. width - 2) buffer.put("═");
            buffer.put("╗\n");
        }
        buffer.put(RusticColors.Reset);
    }

    private void renderBoxBottom(int width)
    {
        buffer.put(RusticColors.WoodDark);
        if (asciiMode)
        {
            buffer.put("+");
            foreach (_; 0 .. width - 2) buffer.put("-");
            buffer.put("+\n");
        }
        else
        {
            buffer.put("╚");
            foreach (_; 0 .. width - 2) buffer.put("═");
            buffer.put("╝\n");
        }
        buffer.put(RusticColors.Reset);
    }

    private void renderBoxDivider(int width)
    {
        buffer.put(RusticColors.WoodDark);
        if (asciiMode)
        {
            buffer.put("+");
            foreach (_; 0 .. width - 2) buffer.put("-");
            buffer.put("+\n");
        }
        else
        {
            buffer.put("╠");
            foreach (_; 0 .. width - 2) buffer.put("═");
            buffer.put("╣\n");
        }
        buffer.put(RusticColors.Reset);
    }

    private void renderBlankLine(int width)
    {
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");
        buffer.put(RusticColors.Reset);
        foreach (_; 0 .. width - 2) buffer.put(" ");
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|\n" : "║\n");
        buffer.put(RusticColors.Reset);
    }

    private void renderHeader(Pomodoro pomo, SoundEngine sound, int width)
    {
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "| " : "║ ");
        
        // Título estático
        buffer.put(RusticColors.GoldBright);
        string titleStr = asciiMode ? "[*] POMODORO RÚSTICO" : "⏳ POMODORO RÚSTICO";
        buffer.put(titleStr);
        
        // Espaçamento e Ciclo
        string cycleStr = formatCycleTokens(pomo);
        string soundStr = sound.isEnabled() ? (asciiMode ? "[SOM: ON]" : "🔊 ON") : (asciiMode ? "[SOM: OFF]" : "🔇 OFF");

        int titleLen = 20;
        int contentLen = titleLen + cast(int)cycleStr.length + cast(int)soundStr.length + 3;
        int pad = max(1, width - 4 - contentLen);

        foreach (_; 0 .. pad) buffer.put(" ");

        buffer.put(RusticColors.WoodMed);
        buffer.put(cycleStr);
        buffer.put("  ");
        buffer.put(RusticColors.Amber);
        buffer.put(soundStr);

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? " |\n" : " ║\n");
        buffer.put(RusticColors.Reset);
    }

    private string formatCycleTokens(Pomodoro pomo)
    {
        int cur = pomo.getCurrentCycle();
        int maxC = pomo.getMaxCycles();
        auto app = appender!string();
        
        app.put("Ciclo: [ ");
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
        int digitWidth = cast(int)digits[0][0].length;
        int totalClockWidth = digitWidth * 5 + 4; // 5 digitos + 4 espacos

        int leftPad = max(1, (width - 2 - totalClockWidth) / 2);
        int rightPad = max(0, width - 2 - totalClockWidth - leftPad);

        foreach (row; 0 .. 5)
        {
            buffer.put(RusticColors.WoodDark);
            buffer.put(asciiMode ? "|" : "║");
            
            foreach (_; 0 .. leftPad) buffer.put(" ");

            buffer.put(color);
            buffer.put(RusticColors.Bold);

            // Desenha os 5 blocos do relógio nesta linha
            buffer.put(digits[d1][row]);
            buffer.put(" ");
            buffer.put(digits[d2][row]);
            buffer.put(" ");
            
            // Dois pontos estáticos e sólidos (sem piscar)
            buffer.put(digits[d3][row]);
            
            buffer.put(" ");
            buffer.put(digits[d4][row]);
            buffer.put(" ");
            buffer.put(digits[d5][row]);

            buffer.put(RusticColors.Reset);
            foreach (_; 0 .. rightPad) buffer.put(" ");

            buffer.put(RusticColors.WoodDark);
            buffer.put(asciiMode ? "|\n" : "║\n");
            buffer.put(RusticColors.Reset);
        }
    }

    private void renderStatusBadge(string phaseName, string color, bool paused, int width)
    {
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|" : "║");

        string label;
        string badgeColor;
        if (paused)
        {
            label = "⏸  PAUSADO - [Espaço para Retomar]";
            badgeColor = RusticColors.PauseCol;
        }
        else
        {
            label = "⚙  FASE ATUAL: " ~ phaseName;
            badgeColor = color;
        }

        int labelLen = cast(int)label.length; // aprox
        int leftPad = max(1, (width - 2 - labelLen - 4) / 2);
        int rightPad = max(0, width - 2 - labelLen - 4 - leftPad);

        foreach (_; 0 .. leftPad) buffer.put(" ");

        buffer.put(badgeColor);
        buffer.put(RusticColors.Bold);
        buffer.put("[ ");
        buffer.put(label);
        buffer.put(" ]");
        buffer.put(RusticColors.Reset);

        foreach (_; 0 .. rightPad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|\n" : "║\n");
        buffer.put(RusticColors.Reset);
    }

    private void renderProgressBar(float progress, string color, int width)
    {
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|   " : "║   ");

        int percent = cast(int)(progress * 100.0f);
        if (percent > 100) percent = 100;
        if (percent < 0) percent = 0;

        // Comprimento da barra
        int barWidth = width - 18; // Deixa espaço para margem e " 100%"
        if (barWidth < 10) barWidth = 10;

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
                // Caracteres graduais de preenchimento rústico
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

        int used = 3 + 1 + barWidth + 1 + 5;
        int remainingPad = max(0, width - 2 - used);
        foreach (_; 0 .. remainingPad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|\n" : "║\n");
        buffer.put(RusticColors.Reset);
    }

    private void renderSubBarTexture(int width)
    {
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|   " : "║   ");

        int barWidth = width - 18;
        if (barWidth < 10) barWidth = 10;

        buffer.put(RusticColors.Muted);
        foreach (i; 0 .. barWidth + 2)
        {
            buffer.put((i % 2 == 0) ? "~" : " ");
        }

        int used = 3 + barWidth + 2;
        int remainingPad = max(0, width - 2 - used);
        foreach (_; 0 .. remainingPad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|\n" : "║\n");
        buffer.put(RusticColors.Reset);
    }

    private void renderStats(Pomodoro pomo, int width)
    {
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|   " : "║   ");

        long elSec = pomo.getElapsedSeconds();
        long elMin = elSec / 60;
        long elRemainder = elSec % 60;

        int totalSessions = pomo.getCompletedCycles();

        auto app = appender!string();
        formattedWrite(app, "Decorrido: %02d:%02d  │  Pomodoros Concluídos: %d", elMin, elRemainder, totalSessions);

        buffer.put(RusticColors.Cream);
        buffer.put(app.data);
        buffer.put(RusticColors.Reset);

        int contentLen = cast(int)app.data.length + 3;
        int pad = max(0, width - 2 - contentLen);
        foreach (_; 0 .. pad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "|\n" : "║\n");
        buffer.put(RusticColors.Reset);
    }

    private void renderAnimationSection(Pomodoro pomo, int width)
    {
        int frameIdx = (animFrame / 2) % 8;
        auto fireFrame = FIRE_FRAMES[frameIdx];

        // Seção rústica com brasas e citação/motivação vintage
        string[4] sideQuotes = [
            "\"O tempo flui como a madeira que se esculpe.\"",
            "\"Foco no presente, passo a passo.\"",
            "\"Mente calma, trabalho constante.\"",
            "\"Aqueça sua concentração na forja do foco.\""
        ];
        string currentQuote = sideQuotes[(animFrame / 16) % 4];

        foreach (row; 0 .. 4)
        {
            buffer.put(RusticColors.WoodDark);
            buffer.put(asciiMode ? "|  " : "║  ");

            // Fogueira animada
            buffer.put(RusticColors.Amber);
            buffer.put(RusticColors.Bold);
            buffer.put(fireFrame[row]);
            buffer.put(RusticColors.Reset);

            buffer.put("  ");

            if (row == 1)
            {
                buffer.put(RusticColors.WoodMed);
                buffer.put(RusticColors.Italic);
                buffer.put(currentQuote);
                buffer.put(RusticColors.Reset);
                int pad = max(0, width - 2 - 2 - 11 - 2 - cast(int)currentQuote.length);
                foreach (_; 0 .. pad) buffer.put(" ");
            }
            else if (row == 2)
            {
                string statusMsg = pomo.isPaused() ? "Timer em pausa. Respire fundo." : "Forjando progresso em seu dia...";
                buffer.put(RusticColors.Muted);
                buffer.put(statusMsg);
                buffer.put(RusticColors.Reset);
                int pad = max(0, width - 2 - 2 - 11 - 2 - cast(int)statusMsg.length);
                foreach (_; 0 .. pad) buffer.put(" ");
            }
            else
            {
                int pad = max(0, width - 2 - 2 - 11 - 2);
                foreach (_; 0 .. pad) buffer.put(" ");
            }

            buffer.put(RusticColors.WoodDark);
            buffer.put(asciiMode ? "|\n" : "║\n");
            buffer.put(RusticColors.Reset);
        }
    }

    private void renderFooter(int width)
    {
        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? "| " : "║ ");

        string[6] shortcuts = [
            "[Espaço] Pausar",
            "[N] Próximo",
            "[R] Reiniciar",
            "[+/-] Ajustar",
            "[M] Mute",
            "[Q] Sair"
        ];

        buffer.put(RusticColors.WoodMed);
        int totalLen = 0;
        foreach (i, s; shortcuts)
        {
            if (i > 0) { buffer.put(" "); totalLen += 1; }
            buffer.put(RusticColors.Amber);
            buffer.put(s[0..s.indexOf(']') + 1]);
            buffer.put(RusticColors.Cream);
            buffer.put(s[s.indexOf(']') + 1 .. $]);
            totalLen += s.length;
        }

        int pad = max(0, width - 4 - totalLen);
        foreach (_; 0 .. pad) buffer.put(" ");

        buffer.put(RusticColors.WoodDark);
        buffer.put(asciiMode ? " |\n" : " ║\n");
        buffer.put(RusticColors.Reset);
    }
}

import std.string : indexOf;
