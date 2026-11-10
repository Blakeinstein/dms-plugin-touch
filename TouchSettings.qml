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

    StringSetting {
        settingKey: "keyboardBinary"
        label: I18n.trFor("duxTouch", "Keyboard program")
        description: I18n.trFor("duxTouch", "wvkbd variant to run, for example wvkbd-mobintl or wvkbd-deskintl")
        placeholder: "wvkbd-mobintl"
        defaultValue: ""
    }

    SliderSetting {
        settingKey: "keyboardHeight"
        label: I18n.trFor("duxTouch", "Portrait height")
        defaultValue: 250
        minimum: 100
        maximum: 600
        unit: "px"
    }

    SliderSetting {
        settingKey: "keyboardLandscapeHeight"
        label: I18n.trFor("duxTouch", "Landscape height")
        defaultValue: 200
        minimum: 100
        maximum: 500
        unit: "px"
    }

    StringSetting {
        settingKey: "keyboardLayers"
        label: I18n.trFor("duxTouch", "Layers")
        description: I18n.trFor("duxTouch", "Comma separated wvkbd layers. Leave empty for the default set.")
        placeholder: "full,special,emoji"
        defaultValue: ""
    }

    ToggleSetting {
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
        settingKey: "keyboardAuto"
        label: I18n.trFor("duxTouch", "Show on text focus")
        description: I18n.trFor("duxTouch", "In tablet mode, open the keyboard when a text field is focused")
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
