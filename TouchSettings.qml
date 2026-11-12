import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "touchlua.js" as TouchLua

PluginSettings {
    id: root
    pluginId: "duxTouch"

    readonly property bool hyprland: CompositorService.isHyprland
    readonly property string hyprDir: HyprlandService.configDir + "/hypr"
    property bool hyprgrassLoaded: false

    readonly property var touchInstance: root.pluginService?.pluginDaemonInstances?.[root.pluginId] ?? null
    readonly property string keyboardBackend: touchInstance?.keyboardBackend ?? "wvkbd"
    readonly property bool wvkbdAvailable: touchInstance?.wvkbdAvailable ?? false
    readonly property bool virtualKeyboardAvailable: touchInstance?.virtualKeyboardAvailable ?? false
    readonly property var keyboardBackendOptions: {
        const opts = [];
        if (wvkbdAvailable)
            opts.push({
                "label": I18n.trFor("duxTouch", "wvkbd"),
                "value": "wvkbd"
            });
        if (virtualKeyboardAvailable)
            opts.push({
                "label": I18n.trFor("duxTouch", "Virtual Keyboard plugin"),
                "value": "virtualKeyboard"
            });
        return opts;
    }
    property bool touchRequired: true
    property int _bindingsRevision: 0
    readonly property var bindings: {
        void _bindingsRevision;
        const stored = pluginService?.loadPluginData(pluginId, "bindings", null);
        return Array.isArray(stored) ? stored : TouchLua.DEFAULT_BINDINGS;
    }

    readonly property var kindOptions: [
        {
            "label": I18n.trFor("duxTouch", "Edge swipe"),
            "value": "edge"
        },
        {
            "label": I18n.trFor("duxTouch", "Swipe"),
            "value": "swipe"
        },
        {
            "label": I18n.trFor("duxTouch", "Tap"),
            "value": "tap"
        },
        {
            "label": I18n.trFor("duxTouch", "Pinch"),
            "value": "pinch"
        },
        {
            "label": I18n.trFor("duxTouch", "Long press"),
            "value": "longpress"
        }
    ]
    readonly property var directionOptions: [
        {
            "label": I18n.trFor("duxTouch", "Left"),
            "value": "left"
        },
        {
            "label": I18n.trFor("duxTouch", "Right"),
            "value": "right"
        },
        {
            "label": I18n.trFor("duxTouch", "Up"),
            "value": "up"
        },
        {
            "label": I18n.trFor("duxTouch", "Down"),
            "value": "down"
        }
    ]
    readonly property var pinchOptions: [
        {
            "label": I18n.trFor("duxTouch", "Pinch in"),
            "value": "pinchin"
        },
        {
            "label": I18n.trFor("duxTouch", "Pinch out"),
            "value": "pinchout"
        }
    ]
    readonly property var actionOptions: [
        {
            "label": I18n.trFor("duxTouch", "Next workspace"),
            "value": "workspaceNext"
        },
        {
            "label": I18n.trFor("duxTouch", "Previous workspace"),
            "value": "workspacePrev"
        },
        {
            "label": I18n.trFor("duxTouch", "Close window"),
            "value": "close"
        },
        {
            "label": I18n.trFor("duxTouch", "Toggle fullscreen"),
            "value": "fullscreen"
        },
        {
            "label": I18n.trFor("duxTouch", "Toggle floating"),
            "value": "float"
        },
        {
            "label": I18n.trFor("duxTouch", "Drag window"),
            "value": "drag"
        },
        {
            "label": I18n.trFor("duxTouch", "Toggle keyboard"),
            "value": "keyboard"
        },
        {
            "label": I18n.trFor("duxTouch", "Control center"),
            "value": "controlCenter"
        },
        {
            "label": I18n.trFor("duxTouch", "Launcher"),
            "value": "launcher"
        },
        {
            "label": I18n.trFor("duxTouch", "Notifications"),
            "value": "notifications"
        },
        {
            "label": I18n.trFor("duxTouch", "Run command"),
            "value": "exec"
        }
    ]
    readonly property var fingerOptions: ["1", "2", "3", "4", "5"]

    function refreshStatus() {
        if (!hyprland)
            return;
        Proc.runCommand("duxtouch-hyprgrass", ["hyprctl", "plugin", "list"], (output, exitCode) => {
            hyprgrassLoaded = exitCode === 0 && /hyprgrass/i.test(output);
        });
        Proc.runCommand("duxtouch-require", ["grep", "-qs", "dms.touch", hyprDir + "/hyprland.lua", hyprDir + "/dms/binds-user.lua"], (output, exitCode) => {
            touchRequired = exitCode === 0;
        });
    }

    function installHyprgrass() {
        const script = "hyprpm update && { hyprpm add https://github.com/horriblename/hyprgrass; hyprpm enable hyprgrass && hyprpm reload -n; }; printf '\\nPress Enter to close'; read _";
        Quickshell.execDetached([MuxService.terminal].concat(MuxService.getTerminalFlag(MuxService.terminal), ["sh", "-c", script]));
    }

    function enableTouchConfig() {
        const file = hyprDir + "/dms/binds-user.lua";
        Proc.runCommand("duxtouch-append-require", ["sh", "-c", 'mkdir -p "${1%/*}" && printf \'\\n-- dux-touch gestures\\npcall(require, "dms.touch")\\n\' >> "$1"', "sh", file], (output, exitCode) => {
            if (exitCode !== 0) {
                ToastService.showError(I18n.trFor("duxTouch", "Could not update binds-user.lua"), output);
                return;
            }
            touchRequired = true;
            HyprlandService.reloadConfig();
        });
    }

    function editBinding(index, patch) {
        const next = bindings.slice();
        next[index] = Object.assign({}, next[index], patch);
        saveBindings(next);
    }

    function saveBindings(next) {
        saveValue("bindings", next);
        _bindingsRevision++;
    }

    Component.onCompleted: refreshStatus()

    StyledText {
        width: parent.width
        text: I18n.trFor("duxTouch", "Keyboard")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Theme.fontWeightMedium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: root.keyboardBackendOptions.length === 0
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.warning
        text: I18n.trFor("duxTouch", "No on-screen keyboard backend is installed. Install wvkbd, or enable the Virtual Keyboard plugin.")
    }

    SelectionSetting {
        visible: root.keyboardBackendOptions.length > 0
        settingKey: "keyboardBackend"
        label: I18n.trFor("duxTouch", "Keyboard backend")
        description: I18n.trFor("duxTouch", "Which on-screen keyboard to show. Only installed backends are listed.")
        defaultValue: "wvkbd"
        options: root.keyboardBackendOptions
    }

    StringSetting {
        visible: root.keyboardBackend === "wvkbd"
        settingKey: "keyboardBinary"
        label: I18n.trFor("duxTouch", "Keyboard program")
        description: I18n.trFor("duxTouch", "wvkbd variant to run, for example wvkbd-mobintl or wvkbd-deskintl")
        placeholder: "wvkbd-mobintl"
        defaultValue: ""
    }

    SliderSetting {
        visible: root.keyboardBackend === "wvkbd"
        settingKey: "keyboardHeight"
        label: I18n.trFor("duxTouch", "Portrait height")
        defaultValue: 250
        minimum: 100
        maximum: 600
        unit: "px"
    }

    SliderSetting {
        visible: root.keyboardBackend === "wvkbd"
        settingKey: "keyboardLandscapeHeight"
        label: I18n.trFor("duxTouch", "Landscape height")
        defaultValue: 200
        minimum: 100
        maximum: 500
        unit: "px"
    }

    StringSetting {
        visible: root.keyboardBackend === "wvkbd"
        settingKey: "keyboardLayers"
        label: I18n.trFor("duxTouch", "Layers")
        description: I18n.trFor("duxTouch", "Comma separated wvkbd layers. Leave empty for the default set.")
        placeholder: "full,special,emoji"
        defaultValue: ""
    }

    ToggleSetting {
        visible: root.keyboardBackend === "wvkbd"
        settingKey: "keyboardFollowTheme"
        label: I18n.trFor("duxTouch", "Follow shell theme")
        defaultValue: true
    }

    StyledText {
        width: parent.width
        text: I18n.trFor("duxTouch", "Tablet mode")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Theme.fontWeightMedium
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "tabletMode"
        label: I18n.trFor("duxTouch", "Tablet mode")
        description: I18n.trFor("duxTouch", "Keep the keyboard running in the background so it opens instantly")
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "physicalKeyboard"
        label: I18n.trFor("duxTouch", "Physical keyboard detection")
        description: I18n.trFor("duxTouch", "Hide the on-screen keyboard when a keyboard is attached, and allow the options below")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "autoTabletMode"
        label: I18n.trFor("duxTouch", "Automatic tablet mode")
        description: I18n.trFor("duxTouch", "Turn tablet mode on when the last external keyboard is detached, and off again when one is attached, unless you turned it on yourself")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "hideOnKeyPress"
        label: I18n.trFor("duxTouch", "Hide on key press")
        description: I18n.trFor("duxTouch", "Hide the on-screen keyboard when you type on a physical keyboard")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "followTabletSwitch"
        label: I18n.trFor("duxTouch", "Follow tablet mode switch")
        description: I18n.trFor("duxTouch", "Use the hardware tablet mode switch on convertibles")
        defaultValue: true
    }

    ToggleSetting {
        visible: root.keyboardBackend === "wvkbd"
        settingKey: "showHideButton"
        label: I18n.trFor("duxTouch", "Hide button")
        description: I18n.trFor("duxTouch", "Show a button above the keyboard that hides it")
        defaultValue: true
    }

    StyledText {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: (root.touchInstance?.inputTier ?? "") !== "libinput"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.warning
        text: I18n.trFor("duxTouch", "Only keyboard attach and detach are followed. For key presses and the tablet switch, add yourself to the input group and install libinput-tools.")
    }

    ToggleSetting {
        visible: (root.touchInstance?.inputTier ?? "") === "libinput"
        settingKey: "libinputWatcherEnabled"
        label: I18n.trFor("duxTouch", "Follow key presses and the tablet switch")
        description: I18n.trFor("duxTouch", "Keeps a libinput watcher resident. It can read every input device, including keystrokes typed into other apps and the lock screen, so it is off by default.")
        defaultValue: false
    }

    ToggleSetting {
        visible: root.keyboardBackend === "wvkbd" && root.hyprland
        settingKey: "keyboardAuto"
        label: I18n.trFor("duxTouch", "Show on text focus")
        description: I18n.trFor("duxTouch", "In tablet mode, open the keyboard when a text field is focused. Hyprland only: elsewhere there's no way to track wvkbd's own --auto visibility, so it stays off.")
        defaultValue: true
    }

    StyledText {
        width: parent.width
        text: I18n.trFor("duxTouch", "Rotation")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Theme.fontWeightMedium
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "rotationEnabled"
        label: I18n.trFor("duxTouch", "Auto-rotate")
        description: I18n.trFor("duxTouch", "Rotate the screen with the accelerometer. Needs iio-sensor-proxy.")
        defaultValue: false
    }

    SelectionSetting {
        settingKey: "rotationOutput"
        label: I18n.trFor("duxTouch", "Rotated display")
        defaultValue: "auto"
        options: [
            {
                "label": I18n.trFor("duxTouch", "Built-in display"),
                "value": "auto"
            }
        ].concat(WlrOutputService.outputs.map(o => ({
                    "label": o.name,
                    "value": o.name
                })))
    }

    StyledText {
        width: parent.width
        visible: root.hyprland
        text: I18n.trFor("duxTouch", "Gestures")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Theme.fontWeightMedium
        color: Theme.surfaceText
    }

    Row {
        width: parent.width
        visible: root.hyprland
        spacing: Theme.spacingM

        StyledText {
            width: parent.width - installButton.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            wrapMode: Text.WordWrap
            text: root.hyprgrassLoaded ? I18n.trFor("duxTouch", "hyprgrass is loaded") : I18n.trFor("duxTouch", "hyprgrass is not loaded. Touch gestures need it.")
            color: root.hyprgrassLoaded ? Theme.surfaceVariantText : Theme.warning
            font.pixelSize: Theme.fontSizeMedium
        }

        DButton {
            id: installButton
            text: root.hyprgrassLoaded ? I18n.trFor("duxTouch", "Refresh") : I18n.trFor("duxTouch", "Install")
            iconName: root.hyprgrassLoaded ? "refresh" : "download"
            onClicked: root.hyprgrassLoaded ? root.refreshStatus() : root.installHyprgrass()
        }
    }

    Row {
        width: parent.width
        visible: root.hyprland && !root.touchRequired
        spacing: Theme.spacingM

        StyledText {
            width: parent.width - enableButton.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            wrapMode: Text.WordWrap
            text: I18n.trFor("duxTouch", "Your Hyprland config does not load dms/touch.lua yet")
            color: Theme.warning
            font.pixelSize: Theme.fontSizeMedium
        }

        DButton {
            id: enableButton
            text: I18n.trFor("duxTouch", "Enable")
            onClicked: root.enableTouchConfig()
        }
    }

    ToggleSetting {
        visible: root.hyprland
        settingKey: "gesturesEnabled"
        label: I18n.trFor("duxTouch", "Touch gestures")
        defaultValue: true
    }

    ToggleSetting {
        visible: root.hyprland
        settingKey: "workspaceSwipeTouch"
        label: I18n.trFor("duxTouch", "Swipe between workspaces")
        description: I18n.trFor("duxTouch", "Hyprland's built-in touchscreen workspace swipe")
        defaultValue: true
    }

    SliderSetting {
        visible: root.hyprland
        settingKey: "sensitivity"
        label: I18n.trFor("duxTouch", "Sensitivity")
        description: I18n.trFor("duxTouch", "Higher makes swipes more reliable but taps and holds less precise")
        defaultValue: 40
        minimum: 5
        maximum: 100
    }

    SliderSetting {
        visible: root.hyprland
        settingKey: "longPressDelay"
        label: I18n.trFor("duxTouch", "Long press delay")
        defaultValue: 400
        minimum: 100
        maximum: 1500
        unit: "ms"
    }

    SliderSetting {
        visible: root.hyprland
        settingKey: "edgeMargin"
        label: I18n.trFor("duxTouch", "Edge size")
        defaultValue: 10
        minimum: 2
        maximum: 100
        unit: "px"
    }

    ToggleSetting {
        visible: root.hyprland
        settingKey: "holdTouches"
        label: I18n.trFor("duxTouch", "Hold touches")
        description: I18n.trFor("duxTouch", "Delay touches briefly so apps do not see the start of a gesture")
        defaultValue: true
    }

    SliderSetting {
        visible: root.hyprland
        settingKey: "holdTouchesDelay"
        label: I18n.trFor("duxTouch", "Hold delay")
        defaultValue: 40
        minimum: 0
        maximum: 200
        unit: "ms"
    }

    Column {
        width: parent.width
        visible: root.hyprland
        spacing: Theme.spacingS

        Repeater {
            model: root.bindings

            delegate: Flow {
                id: row
                required property var modelData
                required property int index
                readonly property string kind: modelData.kind ?? "edge"
                readonly property bool directional: kind === "edge" || kind === "swipe" || kind === "pinch"

                width: parent.width
                spacing: Theme.spacingS

                DDropdown {
                    compactMode: true
                    dropdownWidth: Theme.fontSizeMedium * 9
                    options: root.kindOptions.map(o => o.label)
                    optionValues: root.kindOptions.map(o => o.value)
                    currentValue: row.kind
                    onValueChanged: value => {
                        const direction = value === "pinch" ? "pinchin" : "down";
                        root.editBinding(row.index, {
                            "kind": value,
                            "direction": direction,
                            "origin": "down"
                        });
                    }
                }

                DDropdown {
                    compactMode: true
                    visible: row.kind !== "edge"
                    dropdownWidth: Theme.fontSizeMedium * 5
                    options: root.fingerOptions.map(f => I18n.trFor("duxTouch", "%1 fingers").arg(f))
                    optionValues: root.fingerOptions
                    currentValue: String(row.modelData.fingers ?? (row.kind === "tap" ? 2 : 3))
                    onValueChanged: value => root.editBinding(row.index, {
                            "fingers": Number(value)
                        })
                }

                DDropdown {
                    compactMode: true
                    visible: row.kind === "edge"
                    dropdownWidth: Theme.fontSizeMedium * 7
                    options: root.directionOptions.map(o => I18n.trFor("duxTouch", "From %1").arg(o.label))
                    optionValues: root.directionOptions.map(o => o.value)
                    currentValue: row.modelData.origin ?? "down"
                    onValueChanged: value => root.editBinding(row.index, {
                            "origin": value
                        })
                }

                DDropdown {
                    compactMode: true
                    visible: row.directional
                    readonly property var choices: row.kind === "pinch" ? root.pinchOptions : root.directionOptions
                    dropdownWidth: Theme.fontSizeMedium * 7
                    options: choices.map(o => o.label)
                    optionValues: choices.map(o => o.value)
                    currentValue: row.modelData.direction ?? ""
                    onValueChanged: value => root.editBinding(row.index, {
                            "direction": value
                        })
                }

                DDropdown {
                    compactMode: true
                    dropdownWidth: Theme.fontSizeMedium * 11
                    options: root.actionOptions.map(o => o.label)
                    optionValues: root.actionOptions.map(o => o.value)
                    currentValue: row.modelData.action ?? ""
                    onValueChanged: value => root.editBinding(row.index, {
                            "action": value
                        })
                }

                DTextField {
                    visible: row.modelData.action === "exec"
                    width: Theme.fontSizeMedium * 16
                    placeholderText: I18n.trFor("duxTouch", "Command")
                    text: row.modelData.command ?? ""
                    // Saving per keystroke would rebuild the row and drop focus
                    onEditingFinished: {
                        if (text !== (row.modelData.command ?? ""))
                            root.editBinding(row.index, {
                                "command": text
                            });
                    }
                }

                DIconButton {
                    iconName: "delete"
                    Accessible.name: I18n.trFor("duxTouch", "Remove")
                    onClicked: {
                        const next = root.bindings.slice();
                        next.splice(row.index, 1);
                        root.saveBindings(next);
                    }
                }
            }
        }

        Row {
            spacing: Theme.spacingS

            DButton {
                text: I18n.trFor("duxTouch", "Add gesture")
                iconName: "add"
                onClicked: root.saveBindings(root.bindings.concat([
                    {
                        "kind": "swipe",
                        "fingers": 3,
                        "direction": "up",
                        "action": "launcher"
                    }
                ]))
            }

            DButton {
                text: I18n.trFor("duxTouch", "Reset gestures")
                iconName: "restart_alt"
                variant: "tonal"
                onClicked: root.saveBindings(TouchLua.DEFAULT_BINDINGS)
            }
        }
    }
}
