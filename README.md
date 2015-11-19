# Stopwatch

*stopwatch* is non-graphical software designed to measure the amount of time
elapsed from its activation to the time when it is deactivated.    In
addition to the total elapsed time a set of "lap" and "split" times can be
reported.  A split time is the elapsed between activation and the pressing of
the lap button.  The lap time is the time that has elapsed between presses of
the lap button.

Any key except the <esc> acts as the lap button, recording and reporting the lap
time.  Pressing the <esc> deactivates the stopwatch and quits.  The final
elapsed times are reported as well as the summary statistics for the recorded
laps - reported as "Lap: (minimum/mean/maximum)"
```
Usage:
  stopwatch [-i 10 | --interval=10]
  stopwatch (-h    | --help)
  stopwatch (-v    | --version)

Options:
  -i --interval The interval (in ms) to print out elapsed time (default 10)
  -h --help     Show this screen.
  -v --version  Show version.
```

# Outputs:
All output times are in seconds.  Each press of the lap button (or <esc>)
results in a reported lap and split time.  For example, pressing the lap
button may result in a line such as
`Lap 1: 2.8917  Split: 2.8917`
Here, a single event was recorded at 2.8917 seconds.  The "lap" time is the time
since the last lap was pressed which in this case was the start.  The split time
is the total time elapsed since the program started.

A more interesting example is shown below:
```
> ./stopwatch
Lap 1: 3.1655  Split: 3.1655
Lap 2: 2.1116  Split: 5.2771
Lap 3: 2.2078  Split: 7.4850
Lap 4: 2.2400  Split: 9.7250
Lap 5: 2.7117  Split: 12.4367
Total time:  12.4367   Lap: (2.1116/2.4873/3.1655)
```
Here the lap button was pressed 4 times and the <esc> button was pressed once
resultin in the 5th lap report.  The total elapsed time was, here, 12.4367
seconds.  The lap time statistics are shown as (minimum/mean/maximum) so we can
see the minimum lap time was 2.1116 seconds (lap number 2), the longest was
3.1655 seconds (lap 1) and the mean, or average, was 2.4873 seconds.

# Compilation:
Stopwatch is a threaded Nim program contained in a single source file.  There
are no external module dependencies so the source file should compile cleanly
and easily with the command
```
nim compile --threads:on stopwatch.nim
```
Note, since the application is threaded it is necessary to use the compiler
option `--threads:on`.
