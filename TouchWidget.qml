import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property QtObject daemon: pluginService?.pluginDaemonInstances?.[pluginId] ?? null
    readonly property bool keyboardVisible: daemon?.keyboardVisible ?? false
    readonly property bool tabletMode: pluginData.tabletMode ?? false
    readonly property bool rotationEnabled: pluginData.rotationEnabled ?? false
    readonly property bool rotationLocked: pluginData.rotationLocked ?? false

    // Static literal: the control center probes plugins before pluginData loads
    ccWidgetIcon: "keyboard"
    ccWidgetPrimaryText: I18n.trFor("duxTouch", "Keyboard")
    ccWidgetSecondaryText: {
        if (tabletMode)
            return I18n.trFor("duxTouch", "Tablet mode");
        return keyboardVisible ? I18n.trFor("duxTouch", "Shown") : I18n.trFor("duxTouch", "Hidden");
    }
    ccWidgetIsActive: keyboardVisible

    onCcWidgetToggled: daemon?.toggleKeyboard()

    pillClickAction: () => root.daemon?.toggleKeyboard()
    pillRightClickAction: () => root.daemon?.setTabletMode(!root.tabletMode)

    horizontalBarPill: Component {
        DIcon {
            name: root.tabletMode ? "tablet" : "keyboard"
            size: root.iconSize
            color: root.keyboardVisible ? Theme.primary : Theme.surfaceText
        }
    }

    verticalBarPill: Component {
        DIcon {
            name: root.tabletMode ? "tablet" : "keyboard"
            size: root.iconSize
            color: root.keyboardVisible ? Theme.primary : Theme.surfaceText
        }
    }

    ccDetailContent: Component {
        Item {
            readonly property string title: I18n.trFor("duxTouch", "Touch")
            implicitHeight: detailColumn.implicitHeight + Theme.spacingM * 2

            Column {
                id: detailColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                DToggle {
                    width: parent.width
                    text: I18n.trFor("duxTouch", "Tablet mode")
                    description: I18n.trFor("duxTouch", "Keep the keyboard ready and show it when a text field is focused")
                    checked: root.tabletMode
                    onToggled: checked => root.daemon?.setTabletMode(checked)
                }

                DToggle {
                    width: parent.width
                    visible: root.rotationEnabled
                    text: I18n.trFor("duxTouch", "Rotation lock")
                    checked: root.rotationLocked
                    onToggled: checked => root.daemon?.setRotationLocked(checked)
                }
            }
        }
    }
}
