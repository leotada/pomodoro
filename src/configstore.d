module configstore;

import i18n;
import pomodoro;

import std.conv : to;
import std.file : exists, mkdirRecurse, readText, write;
import std.format : format;
import std.path : buildPath, dirName;
import std.process : environment;
import std.string : indexOf, splitLines, strip;

/// Path of `$XDG_CONFIG_HOME/pomodoro/durations`, or `~/.config/pomodoro/durations`.
string durationsPath()
{
    string xdg = environment.get("XDG_CONFIG_HOME", "");
    if (xdg.length == 0)
    {
        string home = environment.get("HOME", "");
        if (home.length == 0)
            return null;
        xdg = buildPath(home, ".config");
    }
    return buildPath(xdg, "pomodoro", "durations");
}

/// Fill durations and language from the user file. A missing or unreadable file leaves `config` unchanged.
void loadDurations(ref PomodoroConfig config)
{
    loadDurationsFrom(config, durationsPath());
}

void loadDurationsFrom(ref PomodoroConfig config, string path)
{
    if (path.length == 0)
        return;

    string text;
    try
    {
        if (!exists(path))
            return;
        text = readText(path);
    }
    catch (Exception)
    {
        return;
    }

    applyDurationsText(config, text);
}

/// Write durations and language. Disk failures do not propagate.
void saveDurations(PomodoroConfig config)
{
    saveDurationsTo(config, durationsPath());
}

void saveDurationsTo(PomodoroConfig config, string path)
{
    if (path.length == 0)
        return;

    try
    {
        string dir = dirName(path);
        if (dir.length > 0 && !exists(dir))
            mkdirRecurse(dir);

        string body = format!"work=%g\nshort=%g\nlong=%g\nlang=%s\n"(
            config.workMinutes,
            config.shortBreakMinutes,
            config.longBreakMinutes,
            languageCode(config.lang));
        write(path, body);
    }
    catch (Exception)
    {
    }
}

/// Store `lang` without rewriting duration overrides from this run.
void saveLanguage(Language lang)
{
    saveLanguageTo(durationsPath(), lang);
}

void saveLanguageTo(string path, Language lang)
{
    if (path.length == 0)
        return;

    PomodoroConfig stored;
    loadDurationsFrom(stored, path);
    stored.lang = lang;
    saveDurationsTo(stored, path);
}

private string languageCode(Language lang)
{
    final switch (lang)
    {
        case Language.PT:
            return "pt";
        case Language.EN:
            return "en";
    }
}

private void applyDurationsText(ref PomodoroConfig config, string text)
{
    foreach (line; text.splitLines())
    {
        string trimmed = line.strip();
        if (trimmed.length == 0)
            continue;

        ptrdiff_t eq = trimmed.indexOf('=');
        if (eq <= 0)
            continue;

        string key = trimmed[0 .. eq].strip();
        string value = trimmed[eq + 1 .. $].strip();

        if (key == "lang")
        {
            try
                config.lang = parseLanguage(value);
            catch (Exception)
            {
            }
            continue;
        }

        float minutes;
        try
        {
            minutes = to!float(value);
        }
        catch (Exception)
        {
            continue;
        }

        if (!(minutes >= 1.0f && minutes <= 180.0f))
            continue;

        switch (key)
        {
            case "work":
                config.workMinutes = minutes;
                break;
            case "short":
                config.shortBreakMinutes = minutes;
                break;
            case "long":
                config.longBreakMinutes = minutes;
                break;
            default:
                break;
        }
    }
}

unittest
{
    import std.file : rmdirRecurse, tempDir;
    import std.process : thisProcessID;

    string dir = buildPath(tempDir(), format!"pomodoro-configstore-%s"(thisProcessID));
    string path = buildPath(dir, "durations");
    scope (exit)
    {
        if (exists(dir))
            rmdirRecurse(dir);
    }

    PomodoroConfig missing;
    loadDurationsFrom(missing, path);
    assert(missing.workMinutes == 25.0f);
    assert(missing.shortBreakMinutes == 5.0f);
    assert(missing.longBreakMinutes == 15.0f);

    PomodoroConfig parsed;
    applyDurationsText(parsed, "work=50\nshort=10\nlong=30\n");
    assert(parsed.workMinutes == 50.0f);
    assert(parsed.shortBreakMinutes == 10.0f);
    assert(parsed.longBreakMinutes == 30.0f);

    PomodoroConfig bounded;
    applyDurationsText(bounded, "work=1\nshort=180\nlong=12.5\n");
    assert(bounded.workMinutes == 1.0f);
    assert(bounded.shortBreakMinutes == 180.0f);
    assert(bounded.longBreakMinutes == 12.5f);

    PomodoroConfig ignored;
    applyDurationsText(ignored, "work=0\nshort=999\nlong=abc\nwork=nan\n");
    assert(ignored.workMinutes == 25.0f);
    assert(ignored.shortBreakMinutes == 5.0f);
    assert(ignored.longBreakMinutes == 15.0f);

    PomodoroConfig saved;
    saved.workMinutes = 40.0f;
    saved.shortBreakMinutes = 8.0f;
    saved.longBreakMinutes = 20.0f;
    saveDurationsTo(saved, path);

    PomodoroConfig loaded;
    loadDurationsFrom(loaded, path);
    assert(loaded.workMinutes == 40.0f);
    assert(loaded.shortBreakMinutes == 8.0f);
    assert(loaded.longBreakMinutes == 20.0f);

    loadDurationsFrom(loaded, buildPath(dir, "missing"));
    assert(loaded.workMinutes == 40.0f);
    assert(loaded.lang == Language.PT);

    PomodoroConfig withLang;
    applyDurationsText(withLang, "lang=en\nwork=50\n");
    assert(withLang.lang == Language.EN);
    assert(withLang.workMinutes == 50.0f);

    PomodoroConfig badLang;
    applyDurationsText(badLang, "lang=es\nlang=\n");
    assert(badLang.lang == Language.PT);

    PomodoroConfig prior;
    prior.workMinutes = 50.0f;
    prior.shortBreakMinutes = 10.0f;
    prior.longBreakMinutes = 30.0f;
    saveDurationsTo(prior, path);

    saveLanguageTo(path, Language.EN);
    PomodoroConfig afterLang;
    loadDurationsFrom(afterLang, path);
    assert(afterLang.lang == Language.EN);
    assert(afterLang.workMinutes == 50.0f);
    assert(afterLang.shortBreakMinutes == 10.0f);
    assert(afterLang.longBreakMinutes == 30.0f);
}
