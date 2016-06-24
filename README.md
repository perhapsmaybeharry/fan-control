# fan-control
Inspired by @hholtmann's smcFanControl and built on @beltex's SMCKit. Provides a UI to control fan rpm and some other functionality.

---

**fan-control** is a utility that provides a simple UI to control the fan speeds on the fly and allows monitoring of computer temperature and fan rpm.

It's very similar to [smcFanControl](https://github.com/hholtmann/smcFanControl), but is built on Swift 2.2, and utilises [SMCKit](https://github.com/beltex/SMCKit). Both projects are exceptionally cool and you should check them out.

---

## Features
  - in-application commands for quicker access than using a menu
  - graphical configuration menu
  - slider for quick RPM control
  - textfield for even greater RPM precision
  - menu shortcuts for full and return-to-automatic speeds
  - keyboard shortcut integration once application is in focus

---

## In-Application Commands
  - `rpm`: toggle display of rpm in the menubar
  - `temp`: toggle display of temperature in the menubar
  - `unit`: toggle between Celsius or Fahrenheit as temperature unit in the menubar
  - `auto`: return RPM control to your computer
  - `full`: quick shortcut for full speed ahead

---

## Note
The application must be run within an AppleScript wrapper that allows it to run with administrator privileges. As of current, this wrapper is not available, but will be added shortly.

<sub>I can't seem to figure out AuthorizationServices</sub>

---

Features that will be added soon (hopefully):
  - [x] runtime configurability for behavior (options)
  - [x] GUI menu for options
  - [ ] presets!
  - [ ] thermal sensor choice
