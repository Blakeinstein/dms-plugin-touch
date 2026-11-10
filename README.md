# Touch (duxTouch)

On-screen keyboard, tablet mode, auto-rotation and Hyprland touch gestures.

| Feature | Compositors | Needs |
| --- | --- | --- |
| On-screen keyboard | any with layer-shell and virtual-keyboard | `wvkbd` |
| Tablet mode | same | `wvkbd` |
| Auto-rotation | any with wlr-output-management | `iio-sensor-proxy` |
| Touch gestures | Hyprland (Lua config) | [hyprgrass](https://github.com/horriblename/hyprgrass) |

## Install

```sh
git clone https://github.com/Blakeinstein/dms-plugin-touch ~/.config/dms/plugins/dux-touch
dms restart
dms ipc call plugins enable duxTouch
```

Add the Touch tile to the control center or the Touch widget to a bar.

## Keyboard and tablet mode

Outside tablet mode wvkbd only runs while it is shown. Tablet mode keeps it running hidden, so it opens instantly. With "Show on text focus" it also opens when a text field takes focus (`wvkbd --auto`). Colors, font and corner radius follow the shell theme.

## Gestures

Settings write `~/.config/hypr/dms/touch.lua`. If your Hyprland config does not load it yet, press **Enable** on the settings page. That appends `pcall(require, "dms.touch")` to `dms/binds-user.lua`.

**Install** opens a terminal that runs `hyprpm update`, `hyprpm add` and `hyprpm enable hyprgrass`. touch.lua runs `hyprpm reload -n` when Hyprland starts.

## Rotation

The plugin claims the accelerometer only while auto-rotate is on and unlocked. Each orientation change is applied to the chosen output through wlr-output-management. On niri, also set `map-to-output` in the `touch` input block so touches follow the rotated panel.

## IPC

```sh
dms ipc call duxTouch toggleKeyboard | showKeyboard | hideKeyboard
dms ipc call duxTouch toggleTabletMode | setTabletMode true
dms ipc call duxTouch toggleRotationLock | setRotationLocked true
dms ipc call duxTouch status
```

## Tests

```sh
QT_QPA_PLATFORM=offscreen qmltestrunner -input tests
```
