module pomodoro;

import core.time : Duration, dur, MonoTime;
import i18n;

enum PomodoroMode
{
    Work,
    ShortBreak,
    LongBreak
}

struct PomodoroConfig
{
    float workMinutes = 25.0f;
    float shortBreakMinutes = 5.0f;
    float longBreakMinutes = 15.0f;
    int cyclesBeforeLongBreak = 4;
    bool enableSound = true;
    bool asciiMode = false;
    Language lang = Language.PT;
}

class Pomodoro
{
    private PomodoroConfig config;
    private PomodoroMode mode = PomodoroMode.Work;
    private int currentCycle = 1;
    private int completedCycles = 0;
    private bool paused = false;

    private Duration totalDuration;
    private Duration timeRemaining;
    private MonoTime lastUpdateTime;

    this(PomodoroConfig config)
    {
        this.config = config;
        this.mode = PomodoroMode.Work;
        this.currentCycle = 1;
        this.completedCycles = 0;
        this.paused = false;
        
        setupCurrentPhase();
        this.lastUpdateTime = MonoTime.currTime;
    }

    private void setupCurrentPhase()
    {
        final switch (mode)
        {
            case PomodoroMode.Work:
                totalDuration = dur!"hnsecs"(cast(long)(config.workMinutes * 60_0000_000));
                break;
            case PomodoroMode.ShortBreak:
                totalDuration = dur!"hnsecs"(cast(long)(config.shortBreakMinutes * 60_0000_000));
                break;
            case PomodoroMode.LongBreak:
                totalDuration = dur!"hnsecs"(cast(long)(config.longBreakMinutes * 60_0000_000));
                break;
        }
        timeRemaining = totalDuration;
    }

    bool tick()
    {
        MonoTime now = MonoTime.currTime;
        Duration delta = now - lastUpdateTime;
        lastUpdateTime = now;

        if (paused) return false;

        if (timeRemaining > delta)
        {
            timeRemaining -= delta;
            return false;
        }
        else
        {
            timeRemaining = Duration.zero;
            return true;
        }
    }

    void nextPhase()
    {
        final switch (mode)
        {
            case PomodoroMode.Work:
                completedCycles++;
                if (currentCycle >= config.cyclesBeforeLongBreak)
                {
                    mode = PomodoroMode.LongBreak;
                }
                else
                {
                    mode = PomodoroMode.ShortBreak;
                }
                break;

            case PomodoroMode.ShortBreak:
                currentCycle++;
                mode = PomodoroMode.Work;
                break;

            case PomodoroMode.LongBreak:
                currentCycle = 1;
                mode = PomodoroMode.Work;
                break;
        }

        setupCurrentPhase();
        lastUpdateTime = MonoTime.currTime;
    }

    void resetCurrent()
    {
        setupCurrentPhase();
        lastUpdateTime = MonoTime.currTime;
    }

    void togglePause()
    {
        paused = !paused;
        lastUpdateTime = MonoTime.currTime;
    }

    void addMinutes(int deltaMinutes)
    {
        Duration d = dur!"minutes"(deltaMinutes);
        if (deltaMinutes < 0 && timeRemaining <= dur!"minutes"(1))
        {
            // Se já resta menos de 1 minuto, limita ao mínimo de 10s
            timeRemaining = dur!"seconds"(10);
        }
        else if (deltaMinutes < 0 && timeRemaining + d < dur!"seconds"(10))
        {
            timeRemaining = dur!"seconds"(10);
        }
        else
        {
            timeRemaining += d;
            if (timeRemaining > totalDuration)
            {
                totalDuration = timeRemaining;
            }
        }
        lastUpdateTime = MonoTime.currTime;
    }

    PomodoroMode getMode() const { return mode; }
    int getCurrentCycle() const { return currentCycle; }
    int getCompletedCycles() const { return completedCycles; }
    int getMaxCycles() const { return config.cyclesBeforeLongBreak; }
    bool isPaused() const { return paused; }

    float getProgress() const
    {
        if (totalDuration == Duration.zero) return 1.0f;
        long totalHn = totalDuration.total!"hnsecs";
        long remHn = timeRemaining.total!"hnsecs";
        float p = 1.0f - (cast(float)remHn / cast(float)totalHn);
        if (p < 0.0f) return 0.0f;
        if (p > 1.0f) return 1.0f;
        return p;
    }

    long getRemainingSeconds() const
    {
        return timeRemaining.total!"seconds";
    }

    long getElapsedSeconds() const
    {
        return (totalDuration - timeRemaining).total!"seconds";
    }

    PomodoroConfig getConfig() const
    {
        return config;
    }
}

unittest
{
    // TC-STATE-01: Initial state validation
    PomodoroConfig cfg;
    cfg.workMinutes = 25.0f;
    cfg.shortBreakMinutes = 5.0f;
    cfg.longBreakMinutes = 15.0f;
    cfg.cyclesBeforeLongBreak = 4;
    cfg.lang = Language.PT;

    auto p = new Pomodoro(cfg);
    assert(p.getMode() == PomodoroMode.Work);
    assert(p.getCurrentCycle() == 1);
    assert(p.getCompletedCycles() == 0);
    assert(p.getMaxCycles() == 4);
    assert(!p.isPaused());
    assert(p.getRemainingSeconds() >= 24 * 60 && p.getRemainingSeconds() <= 25 * 60);
    assert(p.getElapsedSeconds() == 0);
    assert(p.getProgress() == 0.0f);
    assert(p.getConfig().workMinutes == 25.0f);

    // TC-STATE-02: Pause and resume toggle
    p.togglePause();
    assert(p.isPaused());
    bool tickedWhilePaused = p.tick();
    assert(!tickedWhilePaused);
    p.togglePause();
    assert(!p.isPaused());

    // TC-STATE-03: State transitions through cycles
    // Cycle 1: Work -> Short Break
    p.nextPhase();
    assert(p.getMode() == PomodoroMode.ShortBreak);
    assert(p.getCurrentCycle() == 1);
    assert(p.getCompletedCycles() == 1);
    assert(p.getRemainingSeconds() >= 4 * 60 && p.getRemainingSeconds() <= 5 * 60);

    // Cycle 1 Short Break -> Cycle 2 Work
    p.nextPhase();
    assert(p.getMode() == PomodoroMode.Work);
    assert(p.getCurrentCycle() == 2);
    assert(p.getCompletedCycles() == 1);

    // Cycle 2 Work -> Cycle 2 Short Break
    p.nextPhase();
    assert(p.getMode() == PomodoroMode.ShortBreak);
    assert(p.getCurrentCycle() == 2);
    assert(p.getCompletedCycles() == 2);

    // Cycle 2 Short Break -> Cycle 3 Work
    p.nextPhase();
    assert(p.getMode() == PomodoroMode.Work);
    assert(p.getCurrentCycle() == 3);
    assert(p.getCompletedCycles() == 2);

    // Cycle 3 Work -> Cycle 3 Short Break
    p.nextPhase();
    assert(p.getMode() == PomodoroMode.ShortBreak);
    assert(p.getCurrentCycle() == 3);
    assert(p.getCompletedCycles() == 3);

    // Cycle 3 Short Break -> Cycle 4 Work
    p.nextPhase();
    assert(p.getMode() == PomodoroMode.Work);
    assert(p.getCurrentCycle() == 4);
    assert(p.getCompletedCycles() == 3);

    // Cycle 4 Work -> Long Break (since currentCycle >= cyclesBeforeLongBreak)
    p.nextPhase();
    assert(p.getMode() == PomodoroMode.LongBreak);
    assert(p.getCurrentCycle() == 4);
    assert(p.getCompletedCycles() == 4);
    assert(p.getRemainingSeconds() >= 14 * 60 && p.getRemainingSeconds() <= 15 * 60);

    // Long Break -> Cycle 1 Work
    p.nextPhase();
    assert(p.getMode() == PomodoroMode.Work);
    assert(p.getCurrentCycle() == 1);
    assert(p.getCompletedCycles() == 4);

    // TC-STATE-04: Reset current phase
    p.addMinutes(-10);
    p.resetCurrent();
    assert(p.getRemainingSeconds() >= 24 * 60 && p.getRemainingSeconds() <= 25 * 60);

    // TC-STATE-05: addMinutes adjustments and boundary floor
    long curRem = p.getRemainingSeconds();
    p.addMinutes(5);
    assert(p.getRemainingSeconds() >= curRem + 4 * 60);
    p.addMinutes(-10);
    assert(p.getRemainingSeconds() >= curRem - 6 * 60);
    p.addMinutes(-30); // Excessive reduction should floor at 10 seconds
    assert(p.getRemainingSeconds() == 10);
    p.addMinutes(-5); // Negative delta when <= 1 min floors at 10s
    assert(p.getRemainingSeconds() == 10);

    // TC-STATE-06: Progress calculation
    assert(p.getProgress() >= 0.0f && p.getProgress() <= 1.0f);
}


