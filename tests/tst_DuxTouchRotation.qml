import QtQuick
import QtTest
import "../rotation.js" as Rotation

TestCase {
    name: "DuxTouchRotation"

    readonly property var outputs: [
        {
            "name": "eDP-1",
            "enabled": true,
            "x": 0,
            "y": 0,
            "scale": 1.5,
            "transform": 0,
            "currentMode": {
                "id": 7
            }
        },
        {
            "name": "HDMI-A-1",
            "enabled": false,
            "transform": 0
        },
        {
            "name": "DP-2",
            "enabled": true,
            "x": 1920,
            "y": 0,
            "scale": 1,
            "transform": 2,
            "adaptiveSyncSupported": true,
            "adaptiveSync": 1,
            "currentMode": {
                "id": 9
            }
        }
    ]

    function test_transformFor_data() {
        return [
            {
                "tag": "normal",
                "orientation": "normal",
                "transform": 0
            },
            {
                "tag": "left-up",
                "orientation": "left-up",
                "transform": 1
            },
            {
                "tag": "bottom-up",
                "orientation": "bottom-up",
                "transform": 2
            },
            {
                "tag": "right-up",
                "orientation": "right-up",
                "transform": 3
            },
            {
                "tag": "undefined",
                "orientation": "undefined",
                "transform": null
            }
        ];
    }

    function test_transformFor(data) {
        compare(Rotation.transformFor(data.orientation), data.transform);
    }

    function test_defaultOutputPrefersInternalPanel() {
        compare(Rotation.defaultOutput(outputs.slice().reverse()), "eDP-1");
    }

    function test_headsConfigureEveryOutputAndOnlyRotateTarget() {
        const heads = Rotation.headsWithTransform(outputs, "eDP-1", 1);
        compare(heads.length, 3);
        compare(heads[0].transform, 1);
        compare(heads[0].modeId, 7);
        compare(heads[0].scale, 1.5);
        compare(heads[1], {
            "name": "HDMI-A-1",
            "enabled": false
        });
        compare(heads[2].transform, 2);
        compare(heads[2].adaptiveSync, 1);
    }

    function test_headsSkipNoOpAndMissingOutput() {
        compare(Rotation.headsWithTransform(outputs, "eDP-1", 0), null);
        compare(Rotation.headsWithTransform(outputs, "HDMI-A-1", 1), null);
        compare(Rotation.headsWithTransform(outputs, "nope", 1), null);
    }
}
