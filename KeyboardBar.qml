import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.DCommon.Widgets

// Zero exclusive zone with Normal exclusion makes the compositor place this above wvkbd's reserved strip
PanelWindow {
    id: bar

    required property Item daemon

    screen: CompositorService.getFocusedScreen()
    WlrLayershell.namespace: "dms:duxtouch-keyboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    anchors {
        bottom: true
        right: true
    }
    margins {
        right: Theme.spacingS
        bottom: Theme.spacingXS
    }
    color: "transparent"
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    StyledRect {
        id: pill
        implicitWidth: hideButton.width + Theme.spacingXS * 2
        implicitHeight: hideButton.height + Theme.spacingXS * 2
        radius: height / 2
        color: Theme.surfaceContainerHigh

        DIconButton {
            id: hideButton
            anchors.centerIn: parent
            iconName: "keyboard_hide"
            Accessible.name: I18n.trFor("duxTouch", "Hide keyboard")
            onClicked: bar.daemon.hideKeyboard()
        }
    }
}
