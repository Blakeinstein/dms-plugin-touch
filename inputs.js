.pragma library

const EXTERNAL_BUSES = ["0003", "0005"];
// KEY_ESC, KEY_ENTER, KEY_Q, KEY_A, KEY_Z
const REQUIRED_KEYS = [1, 28, 16, 30, 44];
const SCAN_SCRIPT = 'for d in /sys/class/input/event*; do [ -e "$d" ] || continue; v=$d/device; printf "%s\\t%s\\t%s\\t%s\\n" "${d##*/}" "$(cat "$v/id/bustype" 2>/dev/null)" "$(cat "$v/name" 2>/dev/null)" "$(cat "$v/capabilities/key" 2>/dev/null)"; done';

// sysfs prints the bitmap as space separated longs, most significant first, unpadded
function hasKey(bitmap, code, wordBits) {
    const bits = wordBits || 64;
    const words = String(bitmap ?? "").trim().split(/\s+/).filter(w => w.length).reverse();
    const word = words[Math.floor(code / bits)];
    if (!word)
        return false;
    const bit = code % bits;
    const nibble = word.length - 1 - Math.floor(bit / 4);
    if (nibble < 0)
        return false;
    return ((parseInt(word[nibble], 16) >> (bit % 4)) & 1) === 1;
}

function isExternalKeyboard(device) {
    if (!EXTERNAL_BUSES.includes(String(device?.bus ?? "").toLowerCase()))
        return false;
    return REQUIRED_KEYS.every(code => hasKey(device.keys, code));
}

function parseScan(text) {
    return String(text ?? "").split("\n").filter(line => line.length).map(line => {
        const [node, bus, name, keys] = line.split("\t");
        return {
            "node": node ?? "",
            "bus": bus ?? "",
            "name": name ?? "",
            "keys": keys ?? ""
        };
    });
}

function externalKeyboards(text) {
    return parseScan(text).filter(isExternalKeyboard);
}

// libinput debug-events masks key codes unless --show-keycodes, so a press only says which device
function parseLibinputLine(line) {
    const m = /^[-\s]*(event\d+)\s+(DEVICE_ADDED|DEVICE_REMOVED|KEYBOARD_KEY|SWITCH_TOGGLE)\s+(.*)$/.exec(String(line ?? ""));
    if (!m)
        return null;
    switch (m[2]) {
    case "DEVICE_ADDED":
    case "DEVICE_REMOVED":
        return {
            "type": "devices",
            "node": m[1]
        };
    case "KEYBOARD_KEY":
        return /\bpressed\b/.test(m[3]) ? {
            "type": "key",
            "node": m[1]
        } : null;
    case "SWITCH_TOGGLE":
        {
            const s = /switch tablet-mode state (\d)/.exec(m[3]);
            return s ? {
                "type": "tabletSwitch",
                "node": m[1],
                "on": s[1] === "1"
            } : null;
        }
    }
    return null;
}

// The plugin only undoes tablet mode it turned on itself, so a manual choice is never overridden.
// Returns the next {tabletMode, managed} or null when nothing changes.
function tabletDecision(wantTablet, state) {
    if (wantTablet) {
        if (state.tabletMode)
            return null;
        return {
            "tabletMode": true,
            "managed": true
        };
    }
    if (!state.tabletMode || !state.managed)
        return null;
    return {
        "tabletMode": false,
        "managed": false
    };
}
