import QtQuick
import QtTest
import "../wvkbd.js" as Wvkbd

TestCase {
    name: "DuxTouchWvkbd"

    function test_hexKeepsAlpha() {
        compare(Wvkbd.hex(Qt.rgba(1, 0, 0.5, 0.5)), "ff008080");
        compare(Wvkbd.hex(Qt.rgba(0, 0, 0, 1)), "000000ff");
    }

    function test_argvMapsColorsAndModes() {
        const args = Wvkbd.argv({
            "binary": "wvkbd-deskintl",
            "height": 300,
            "font": "Inter",
            "fontSize": 16.4,
            "colors": {
                "fg": Qt.rgba(1, 1, 1, 1)
            },
            "hidden": true,
            "auto": true
        });
        compare(args, ["wvkbd-deskintl", "-H", "300", "--fn", "Inter 16", "--fg", "ffffffff", "--hidden", "--auto"]);
    }
}
