import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property Item daemon: pluginService?.pluginDaemonInstances?.[pluginId] ?? null
    readonly property bool keyboardVisible: daemon?.keyboardVisible ?? false
    readonly property bool tabletMode: pluginData.tabletMode ?? false
    readonly property string modeIcon: tabletMode ? "tablet_android" : "laptop"
    property bool _quickRequested: false

    // triggerPopout() runs pillClickAction when one is set, so it is nulled for the one call that opens the popout
    function openQuickSettings() {
        _quickRequested = true;
        triggerPopout();
        _quickRequested = false;
    }

    // Never empty: the control center only lists plugins whose probe instance has an icon
    ccWidgetIcon: modeIcon
    ccWidgetPrimaryText: I18n.trFor("duxTouch", "Keyboard")
    ccWidgetSecondaryText: {
        const mode = tabletMode ? I18n.trFor("duxTouch", "Tablet mode") : I18n.trFor("duxTouch", "Laptop mode");
        const keyboard = keyboardVisible ? I18n.trFor("duxTouch", "Shown") : I18n.trFor("duxTouch", "Hidden");
        return mode + " · " + keyboard;
    }
    ccWidgetIsActive: keyboardVisible

    onCcWidgetToggled: daemon?.toggleKeyboard()

    pillClickAction: _quickRequested ? null : (() => root.daemon?.toggleKeyboard())
    pillRightClickAction: () => root.openQuickSettings()

    popoutWidth: Theme.fontSizeMedium * 24
    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: I18n.trFor("duxTouch", "Touch")

            QuickSettings {
                width: parent.width
                host: root
                onCloseRequested: popout.closePopout()
            }
        }
    }

    horizontalBarPill: Component {
        PillIcon {}
    }

    verticalBarPill: Component {
        PillIcon {}
    }

    // The shell's pill reacts on press and has no long press, so the icon handles both itself
    component PillIcon: DIcon {
        name: root.modeIcon
        size: root.iconSize
        color: root.keyboardVisible ? Theme.primary : Theme.surfaceText

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.openQuickSettings();
                else
                    root.daemon?.toggleKeyboard();
            }
            onPressAndHold: root.openQuickSettings()
        }
    }

    ccDetailContent: Component {
        Item {
            readonly property string title: I18n.trFor("duxTouch", "Touch")
            implicitHeight: quick.implicitHeight + Theme.spacingM * 2

            DFlickable {
                anchors.fill: parent
                contentHeight: quick.implicitHeight + Theme.spacingM * 2
                clip: true

                QuickSettings {
                    id: quick
                    x: Theme.spacingM
                    y: Theme.spacingM
                    width: parent.width - Theme.spacingM * 2
                    host: root
                }
            }
        }
    }
}
