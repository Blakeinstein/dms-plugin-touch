import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets

Column {
    id: quick

    required property Item host
    signal closeRequested

    readonly property var opts: host.pluginData
    readonly property Item daemon: host.daemon
    readonly property bool keyboardVisible: daemon?.keyboardVisible ?? false
    readonly property bool hasInputAccess: (daemon?.inputTier ?? "") === "libinput"

    function setOption(key, value) {
        daemon?.setOption(key, value);
    }

    spacing: Theme.spacingS

    DButton {
        width: parent.width
        text: quick.keyboardVisible ? I18n.trFor("duxTouch", "Hide keyboard") : I18n.trFor("duxTouch", "Show keyboard")
        iconName: quick.keyboardVisible ? "keyboard_hide" : "keyboard"
        onClicked: {
            quick.daemon?.toggleKeyboard();
            quick.closeRequested();
        }
    }

    DToggle {
        width: parent.width
        text: I18n.trFor("duxTouch", "Tablet mode")
        checked: quick.opts.tabletMode ?? false
        onToggled: checked => quick.setOption("tabletMode", checked)
    }

    DToggle {
        width: parent.width
        text: I18n.trFor("duxTouch", "Automatic tablet mode")
        description: I18n.trFor("duxTouch", "Turn tablet mode on when the keyboard is detached")
        checked: quick.opts.autoTabletMode ?? true
        onToggled: checked => quick.setOption("autoTabletMode", checked)
    }

    DToggle {
        width: parent.width
        text: I18n.trFor("duxTouch", "Show on text focus")
        checked: quick.opts.keyboardAuto ?? true
        onToggled: checked => quick.setOption("keyboardAuto", checked)
    }

    DToggle {
        width: parent.width
        visible: quick.hasInputAccess
        text: I18n.trFor("duxTouch", "Hide on key press")
        description: I18n.trFor("duxTouch", "Hide the on-screen keyboard when you type on a physical keyboard")
        checked: quick.opts.hideOnKeyPress ?? true
        onToggled: checked => quick.setOption("hideOnKeyPress", checked)
    }

    DToggle {
        width: parent.width
        text: I18n.trFor("duxTouch", "Auto-rotate")
        checked: quick.opts.rotationEnabled ?? false
        onToggled: checked => quick.setOption("rotationEnabled", checked)
    }

    DToggle {
        width: parent.width
        visible: quick.opts.rotationEnabled ?? false
        text: I18n.trFor("duxTouch", "Rotation lock")
        checked: quick.opts.rotationLocked ?? false
        onToggled: checked => quick.setOption("rotationLocked", checked)
    }

    DToggle {
        width: parent.width
        visible: CompositorService.isHyprland
        text: I18n.trFor("duxTouch", "Touch gestures")
        checked: quick.opts.gesturesEnabled ?? true
        onToggled: checked => quick.setOption("gesturesEnabled", checked)
    }

    DButton {
        width: parent.width
        variant: "tonal"
        text: I18n.trFor("duxTouch", "More settings")
        iconName: "settings"
        onClicked: {
            PopoutService.openSettingsWithTab("plugin:duxTouch");
            quick.closeRequested();
        }
    }
}
