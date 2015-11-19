#
# Command line stopwatch written in Nim with split / lap support.  Based on
# the ideas of the C-based code from Ciaron Rider
#        https://github.com/ridernator/stopwatch
#

import termios
import times, os
import strutils
import threadpool

# ICANON seems to be mis-declared in termios?  This seems to be the correct
# value, at least for OS X (or I'm misunderstanding the Nim termios).
const ICANON = 0x00000100

###############
# Global variables shared by functions.  This just keeps us from having to
# pass them around
#
var
  startTime, lastTime: float   # Starting and latest lap times
  lapTimes: seq[float]         # Collection of all the lap times



###############
# Support functions

# Set stdin to "non-canonical", raw mode.  Turns off buffering so we see each
# character as it is entered rather than waiting for a newloine.  Also disbales
# interrupts (^c) so we can re-set the terminal before exiting.  Interrupt is
# seen as normal characters (^c)
proc turnOffLineBuffering: void =
  let fd = getFileHandle(stdin)
  var mode: Termios
  discard fd.tcgetattr(addr mode)
  mode.c_lflag = mode.c_lflag and not Cflag(ECHO or ICANON or BRKINT or ICRNL or IXON)
  discard fd.tcsetattr(TCSANOW, addr mode)


# Return stdio to normal buffered mode.  Need to do this before we exit or we
# could leave the terminal in the raw state.
proc turnOnLineBuffering =
  let fd = getFileHandle(stdin)
  var mode: Termios
  discard fd.tcgetattr(addr mode)
  mode.c_lflag = mode.c_lflag or Cflag(ECHO or ICANON or BRKINT or ICRNL or IXON)
  discard fd.tcsetattr(TCSANOW, addr mode)


# Timer display update thread.  This thread runs autonomously continually
# updating and writing the elapsed time to stdout.  We use a carriage Return
# to continually update the same line on stdout (no newline).
proc timeDisplayThread(interval: int) {.thread.} =
  while true:
    sleep(milsecs = interval)
    let t2 = epochTime()
    var millisecs = t2-startTime
    var str = "\rElapsed: $#".format( millisecs.formatFloat(format=ffDecimal, precision=4) )
    stdout.write str
    stdout.flushFile

# Reports the time (lap and split) for a lap.  Adds the lap time to the global
# 'lapTimes' sequence
proc recordLap(t2: float) =
  var split = t2-startTime
  var lap = t2-lastTime
  lapTimes.add(lap)
  lastTime = t2
  var str = "\rLap $#: $#  Split: $#\n".format( lapTimes.len(),
                  lap.formatFloat(format=ffDecimal, precision=4),
                  split.formatFloat(format=ffDecimal, precision=4) )
  stdout.write str
  stdout.flushFile



###############
# Main module processing
# Uses the 'docopt' module to parse the command line parameters.
#
when isMainModule:
  import docopt, tables, strutils

  let doc = """
  stopwatch is non-graphical software designed to measure the amount of time
  elapsed from its activation to the time when it is deactivated.    In
  addition to the total elapsed time a set of "lap"  and "split" times can be
  reported.  A split time is the elapsed between activation and the pressing of
  the lap button.  The lap time is the time that has elapsed between presses of
  the lap button.

  Any key except the <esc> acts as the lap button, recording and reporting the
  lap time.  Pressing the <esc> deactivates the stopwatch and quits.  The final
  elapsed times are reported as well as the summary statistics for the recorded
  laps - reported as "Lap: (minimum/mean/maximum)"

  Usage:
    stopwatch [-i 10 | --interval=10]
    stopwatch (-h    | --help)
    stopwatch (-v    | --version)

  Options:
    -i --interval The interval in ms to print out elapsed time (default 10)
    -h --help     Show this screen.
    -v --version  Show version.
  """

  let args = docopt(doc, version = "stopwatch 1.0")

  var interval = 10
  if args["--interval"]:
    try:
      interval = parse_int($args["--interval"])
    except:
      echo "\nInvalid interval.  Must be integer in milliseconds.\n"
      echo doc
      quit(0)


  turnOffLineBuffering()

  # Create and start the timer display thread
  var thr: Thread[int]
  createThread(thr, timeDisplayThread, interval)

  # Main loop...  Grab the start time and monitor the keyboard looking for
  # key presses.  Any key press except <esc> will mark a lap.  Pressing the
  # <esc> key ends the program.
  startTime = epochTime()
  lastTime = startTime
  lapTimes = @[]
  while true:
    var c = stdin.readChar()
    case c
      of '\e': # if escape, stop
        let t2 = epochTime()
        var totalTime = t2-startTime
        recordLap(t2)

        var avgLap = 0.0
        var minLap = lapTimes[0]
        var maxLap = lapTimes[0]
        for i in low(lapTimes)..high(lapTimes):
          avgLap += lapTimes[i]
          if lapTimes[i] < minLap:
            minLap = lapTimes[i]
          if lapTimes[i] > maxLap:
            maxLap = lapTimes[i]

        avgLap /= float(lapTimes.len())

        var str1 = "\rTotal time:  $#   Lap: ($#/$#/$#)\n".format(
                        totalTime.formatFloat(format=ffDecimal, precision=4),
                        minLap.formatFloat(format=ffDecimal, precision=4),
                        avgLap.formatFloat(format=ffDecimal, precision=4),
                        maxLap.formatFloat(format=ffDecimal, precision=4) )
        stdout.write str1
        stdout.flushFile
        break
      else:
        let t2 = epochTime()
        recordLap(t2)


  turnOnLineBuffering()
