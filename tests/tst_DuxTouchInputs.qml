import QtQuick
import QtTest
import "../inputs.js" as Inputs

TestCase {
    name: "DuxTouchInputs"

    readonly property string fullKeys: "1000000000007 ff9f207ac14057ff febeffdfffefffff fffffffffffffffe"

    function test_isExternalKeyboard_data() {
        return [
            {
                "tag": "usb detachable keyboard",
                "bus": "0003",
                "keys": fullKeys,
                "external": true
            },
            {
                "tag": "bluetooth keyboard",
                "bus": "0005",
                "keys": fullKeys,
                "external": true
            },
            {
                "tag": "built-in i8042 keyboard",
                "bus": "0011",
                "keys": "402000007 ff803078f800d001 feffffdfffcfffff fffffffffffffffe",
                "external": false
            },
            {
                "tag": "usb hotkey device without letters",
                "bus": "0003",
                "keys": "733eff 0 20000 483ffff17aff32d bfd4444600000000 1 1b30c730b17cc00 9fa67bfad9715fed 9e168000004400 10000002",
                "external": false
            },
            {
                "tag": "uinput keyboard",
                "bus": "0006",
                "keys": fullKeys,
                "external": false
            }
        ];
    }

    function test_isExternalKeyboard(data) {
        compare(Inputs.isExternalKeyboard({
            "bus": data.bus,
            "keys": data.keys
        }), data.external);
    }

    function test_externalKeyboardsFromScan() {
        const scan = "event2\t0011\tAT Translated Set 2 keyboard\t402000007 ff803078f800d001 feffffdfffcfffff fffffffffffffffe\n" + "event11\t0003\tGZ302EA-Keyboard\t" + fullKeys + "\n" + "event17\t0019\tgpio-keys\t10000000000000 0\n";
        compare(Inputs.externalKeyboards(scan).map(d => d.node), ["event11"]);
    }

    function test_parseLibinputLine_data() {
        return [
            {
                "tag": "added",
                "line": "-event11  DEVICE_ADDED            GZ302EA-Keyboard                  seat0 default group5  cap:k",
                "event": {
                    "type": "devices",
                    "node": "event11"
                }
            },
            {
                "tag": "masked press",
                "line": " event11  KEYBOARD_KEY            +3.421s\t*** (-1) pressed",
                "event": {
                    "type": "key",
                    "node": "event11"
                }
            },
            {
                "tag": "release ignored",
                "line": " event11  KEYBOARD_KEY            +3.501s\t*** (-1) released",
                "event": null
            },
            {
                "tag": "tablet switch",
                "line": " event4   SWITCH_TOGGLE           +9.000s\tswitch tablet-mode state 1",
                "event": {
                    "type": "tabletSwitch",
                    "node": "event4",
                    "on": true
                }
            },
            {
                "tag": "lid switch ignored",
                "line": " event0   SWITCH_TOGGLE           +9.000s\tswitch lid state 1",
                "event": null
            },
            {
                "tag": "motion ignored",
                "line": " event18  TOUCH_MOTION            +1.000s\t0 (0) 50.00/50.00",
                "event": null
            }
        ];
    }

    function test_parseLibinputLine(data) {
        compare(Inputs.parseLibinputLine(data.line), data.event);
    }

    function test_tabletDecision_data() {
        return [
            {
                "tag": "detach turns tablet on and takes ownership",
                "want": true,
                "state": {
                    "tabletMode": false,
                    "managed": false
                },
                "next": {
                    "tabletMode": true,
                    "managed": true
                }
            },
            {
                "tag": "detach leaves manual tablet mode alone",
                "want": true,
                "state": {
                    "tabletMode": true,
                    "managed": false
                },
                "next": null
            },
            {
                "tag": "attach undoes plugin tablet mode",
                "want": false,
                "state": {
                    "tabletMode": true,
                    "managed": true
                },
                "next": {
                    "tabletMode": false,
                    "managed": false
                }
            },
            {
                "tag": "attach keeps manual tablet mode",
                "want": false,
                "state": {
                    "tabletMode": true,
                    "managed": false
                },
                "next": null
            }
        ];
    }

    function test_tabletDecision(data) {
        compare(Inputs.tabletDecision(data.want, data.state), data.next);
    }
}
