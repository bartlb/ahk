/** 
 * The QPC class implements standard windows performance counters to accurately capture
 * application timing -- whether it be the total time spent executing a script, or the
 * precise time that an application took to execute a function, or single line of code.
 * 
 * All methods used to start/stop or return a counter's elapsed time have performance in
 * mind. As such, the call to QueryPerformanceCounter() is made first in foremost in a
 * method (where relevant and possible).
 *
 * The implementation of this class allows the user to Initialize, Stop and Swap* QPC
 * counters at will, as well as providing a static `app_start` property that is set once
 * the application is executed. Note that for the sake of accuracy, the QPC script should
 * be the first in an application's #Include declarations (or similarly, placed directly
 * at the top of the main script).
 *
 * Further information about QPC: https://goo.gl/rNKKea
 *
 * @remarks PLEASE NOTE THE FOLLOWING CONFIGURATION AND USAGE GUIDELINES!
 *          1 Adding QPC to your application:
 *            a. `#Include <QPC>` (recommended)
 *               This should be the first Include declaration in the application.
 *            b. If the application does not utilize the #Include directive, the QPC
 *               class can be placed directly withing the existing script.
 *          2 You must call `QPC.Stop()` in order to get the elapsed time for the base --
 *            "application"-level -- counter. This will be changed in later versions, see
 *            TODO for further information.
 *
 * @class   QPC
 * @version v0.09_rc0528
 * @author  bartlb <brian.p.bartlett@gmail.com>
 *
 * @todo    v1.0.00
 *          - Refactor *ReturnAs() methods.
 *          - Reclassify GetElapsedTimeUS() to be a 'private' class-util method.
 *          - Move DllCall's to a centralized class-util method ??? (performance hit?)
 *          - Condence `Counter` methods where possible.
 *          - Combine functionality of GetIntervalAs() and SwapCounterAndReturnAs() where
 *            possible.
 *          - Add uniform functionality for returning all counter's elapsed time 'on
 *            counter stop', including the application counter (app_[start|end]).
 */
class QPC
{
  static pcFreq     := (f, DllCall("QueryPerformanceFrequency", "Int64*", f), f)
  static app_start  := (s, DllCall("QueryPerformanceCounter", "Int64*"  , s), s)
  static counters   := {}

  Stop() {
    QPC.app_end := (e, DllCall("QueryPerformanceCounter", "Int64*", e), e)
    QPC.elapsed := QPC.GetElapsedTimeUS()
    return QPC.app_end
  }

  GetElapsedTimeUS(counter=false) {
    elapsed_ := ((((! counter) ? (QPC.app_end - QPC.app_start) 
                               : (counter.end - counter.start)) 
                * 1000000) / QPC.pcFreq)
    return (counter ? (counter.elapsed := elapsed_) : elapsed_)
  }

  GetElapsedTimeAs(unit="us", fstring="{1}", counter=false) {
    funit := (unit == "us" ? 1 : unit == "ms" ? 1000 : 1000000)
    return Format(fstring, ((counter ? counter.elapsed : QPC.elapsed) / funit))
  }

  GetIntervalAs(unit="us", fstring="{1}", new_uid=false) {
    int_end := (e, DllCall("QueryPerformanceCounter", "Int64*", e), e)
    int_elp := (((int_end - QPC.app_start) * 1000000) / QPC.pcFreq)
    funit   := (unit == "us" ? 1 : unit == "ms" ? 1000 : 1000000)

    if (new_uid)
      QPC.counters[new_uid] := {start: int_end}

    return Format(fstring, (int_elp / funit))
  }

  InitCounter(uid) {
    QPC.counters[uid] := {start: (s, DllCall("QueryPerformanceCounter", "Int64*", s), s)}
    return (! ErrorLevel)
  }

  StopCounter(uid) {
    QPC.counters[uid].end := (e, DllCall("QueryPerformanceCounter", "Int64*", e), e)
    QPC.GetElapsedTimeUS(QPC.counters[uid])
    return QPC.counters[uid].end
  }

  CounterGetElapsedTimeAs(uid, unit="us", fstring="{1}") {
    return QPC.GetElapsedTimeAs(unit, fstring, QPC.counters[uid])
  }

  StopCounterAndReturnAs(uid, unit="us", fstring="{1}") {
    QPC.StopCounter(uid)
    return QPC.GetElapsedTimeAs(unit, fstring, QPC.counters[uid])
  }

  SwapCounterAndReturnAs(cntr_arr, unit="us", fstring="{1}") {
    QPC.counters[cntr_arr[2]] := {start: QPC.StopCounter(cntr_arr[1])}
    return QPC.GetElapsedTimeAs(unit, fstring, QPC.counters[cntr_arr[1]])
  }
}
