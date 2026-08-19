module terminal;

import core.sys.posix.termios;
import core.sys.posix.unistd;
import core.sys.posix.sys.ioctl;
import core.sys.posix.signal;
import std.stdio : stdout;
static import std.stdio;

enum SIGWINCH = 28; // Window size change signal (POSIX)

enum Key
{
    None,
    Space,
    Enter,
    Char_n,
    Char_r,
    Char_q,
    Char_m,
    Plus,
    Minus,
    Up,
    Down,
    Left,
    Right,
    Escape,
    Other
}

struct TerminalSize
{
    int columns = 80;
    int rows = 24;
}

private termios originalTermios;
private bool rawModeActive = false;
private bool inAlternateScreen = false;
private __gshared bool windowResized = false;

extern(C) void winchHandler(int sig) nothrow @nogc
{
    windowResized = true;
}

extern(C) void signalHandler(int sig) nothrow @nogc
{
    // Restaura terminal em caso de SIGINT/SIGTERM
    if (rawModeActive)
    {
        tcsetattr(STDIN_FILENO, TCSANOW, &originalTermios);
        // ANSI reset cursor and screen
        writeEscUnsafe("\033[?1049l\033[?25h\033[0m\n");
    }
    _exit(0);
}

private void writeEscUnsafe(string s) nothrow @nogc
{
    core.sys.posix.unistd.write(STDERR_FILENO, s.ptr, s.length);
}

class Terminal
{
    this()
    {
        signal(SIGINT, &signalHandler);
        signal(SIGTERM, &signalHandler);
        signal(SIGWINCH, &winchHandler);
    }

    ~this()
    {
        restore();
    }

    void enableRawMode()
    {
        if (rawModeActive) return;

        if (tcgetattr(STDIN_FILENO, &originalTermios) == -1)
            return;

        termios raw = originalTermios;
        // Desativa ECHO e modo canônico (leitura caractere a caractere)
        raw.c_lflag &= ~(ECHO | ICANON | IEXTEN);
        // Desativa controle de fluxo e tradução de nova linha
        raw.c_iflag &= ~(IXON | ICRNL | INPCK | ISTRIP);
        raw.c_cflag |= (CS8);
        // Leitura não-bloqueante
        raw.c_cc[VMIN] = 0;
        raw.c_cc[VTIME] = 0;

        if (tcsetattr(STDIN_FILENO, TCSANOW, &raw) != -1)
        {
            rawModeActive = true;
        }
    }

    void disableRawMode()
    {
        if (!rawModeActive) return;
        tcsetattr(STDIN_FILENO, TCSANOW, &originalTermios);
        rawModeActive = false;
    }

    void enterAlternateScreen()
    {
        if (!inAlternateScreen)
        {
            std.stdio.write("\033[?1049h\033[H\033[?25l");
            stdout.flush();
            inAlternateScreen = true;
        }
    }

    void exitAlternateScreen()
    {
        if (inAlternateScreen)
        {
            std.stdio.write("\033[?1049l\033[?25h\033[0m");
            stdout.flush();
            inAlternateScreen = false;
        }
    }

    void hideCursor()
    {
        std.stdio.write("\033[?25l");
        stdout.flush();
    }

    void showCursor()
    {
        std.stdio.write("\033[?25h");
        stdout.flush();
    }

    void clearScreen()
    {
        std.stdio.write("\033[2J\033[H");
        stdout.flush();
    }

    void moveCursor(int row, int col)
    {
        import std.format : formattedWrite;
        import std.array : appender;
        auto app = appender!string();
        formattedWrite(app, "\033[%d;%dH", row, col);
        std.stdio.write(app.data);
    }

    TerminalSize getSize()
    {
        winsize ws;
        if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0)
        {
            return TerminalSize(ws.ws_col, ws.ws_row);
        }
        return TerminalSize(80, 24);
    }

    bool hasResized()
    {
        if (windowResized)
        {
            windowResized = false;
            return true;
        }
        return false;
    }

    Key readKey()
    {
        ubyte[32] buf;
        auto n = core.sys.posix.unistd.read(STDIN_FILENO, buf.ptr, buf.length);
        if (n <= 0) return Key.None;

        if (n == 1)
        {
            ubyte c = buf[0];
            switch (c)
            {
                case ' ':  return Key.Space;
                case '\r':
                case '\n': return Key.Enter;
                case 'n':
                case 'N':  return Key.Char_n;
                case 'r':
                case 'R':  return Key.Char_r;
                case 'q':
                case 'Q':  return Key.Char_q;
                case 'm':
                case 'M':  return Key.Char_m;
                case '+':
                case '=':  return Key.Plus;
                case '-':
                case '_':  return Key.Minus;
                case 27:   return Key.Escape;
                default:   return Key.Other;
            }
        }
        else if (n >= 3 && buf[0] == 27 && buf[1] == '[')
        {
            switch (buf[2])
            {
                case 'A': return Key.Up;
                case 'B': return Key.Down;
                case 'C': return Key.Right;
                case 'D': return Key.Left;
                default:  return Key.Other;
            }
        }

        return Key.Other;
    }

    void restore()
    {
        exitAlternateScreen();
        disableRawMode();
        showCursor();
        std.stdio.write("\033[0m");
        stdout.flush();
    }
}
