import QtQuick
import QtTest
import "../touchlua.js" as TouchLua

TestCase {
    name: "DuxTouchLua"

    function test_bindLine_data() {
        return [
            {
                "tag": "edge defaults to one finger",
                "binding": {
                    "kind": "edge",
                    "origin": "right",
                    "direction": "left",
                    "action": "workspaceNext"
                },
                "line": 'hl.plugin.hyprgrass.bind({ pattern = { kind = "edge", origin = "right", direction = "left", fingers = 1 }, action = hl.dsp.focus({ workspace = "e+1" }) })'
            },
            {
                "tag": "pinch keeps pinch direction",
                "binding": {
                    "kind": "pinch",
                    "fingers": 3,
                    "direction": "pinchout",
                    "action": "fullscreen"
                },
                "line": 'hl.plugin.hyprgrass.bind({ pattern = { kind = "pinch", fingers = 3, direction = "pinchout" }, action = hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }) })'
            },
            {
                "tag": "ipc preset runs dms",
                "binding": {
                    "kind": "tap",
                    "fingers": 4,
                    "action": "keyboard"
                },
                "line": 'hl.plugin.hyprgrass.bind({ pattern = { kind = "tap", fingers = 4 }, action = hl.dsp.exec_cmd("dms ipc call duxTouch toggleKeyboard") })'
            },
            {
                "tag": "command is escaped",
                "binding": {
                    "kind": "swipe",
                    "fingers": 3,
                    "direction": "up",
                    "action": "exec",
                    "command": 'notify-send "a\\b"\nrm'
                },
                "line": 'hl.plugin.hyprgrass.bind({ pattern = { kind = "swipe", fingers = 3, direction = "up" }, action = hl.dsp.exec_cmd("notify-send \\"a\\\\b\\"\\nrm") })'
            },
            {
                "tag": "longpress drag is a mouse bind",
                "binding": {
                    "kind": "longpress",
                    "fingers": 3,
                    "action": "drag"
                },
                "line": 'hl.plugin.hyprgrass.bind({ pattern = { kind = "longpress", fingers = 3 }, action = hl.dsp.window.drag(), mouse = true })'
            },
            {
                "tag": "drag outside longpress is dropped",
                "binding": {
                    "kind": "swipe",
                    "fingers": 3,
                    "direction": "up",
                    "action": "drag"
                },
                "line": ""
            },
            {
                "tag": "swipe needs a single direction",
                "binding": {
                    "kind": "swipe",
                    "fingers": 3,
                    "direction": "horizontal",
                    "action": "close"
                },
                "line": ""
            },
            {
                "tag": "empty command is dropped",
                "binding": {
                    "kind": "tap",
                    "fingers": 2,
                    "action": "exec",
                    "command": "  "
                },
                "line": ""
            }
        ];
    }

    function test_bindLine(data) {
        compare(TouchLua.bindLine(data.binding), data.line);
    }

    function test_generateGuardsPluginAndSkipsBadRows() {
        const lua = TouchLua.generate([
            {
                "kind": "tap",
                "fingers": 2,
                "action": "close"
            },
            {
                "kind": "bogus"
            }
        ], {
            "sensitivity": 4
        });
        const lines = lua.split("\n");
        const guard = lines.indexOf("if hl.plugin and hl.plugin.hyprgrass then");
        verify(guard > 0);
        verify(lines.indexOf("\t\tsensitivity = 4.0,") > guard);
        compare(lines.filter(l => l.includes("hyprgrass.bind")).length, 1);
        compare(lines[lines.length - 2], "end");
    }
}
