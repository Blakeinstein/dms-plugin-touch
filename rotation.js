.pragma library

// wl_output transforms rotate counter-clockwise, which is what iio-sensor-proxy's "left-up" needs
const ORIENTATIONS = {
    "normal": 0,
    "left-up": 1,
    "bottom-up": 2,
    "right-up": 3
};

function transformFor(orientation) {
    return ORIENTATIONS[orientation] ?? null;
}

function defaultOutput(outputs) {
    const internal = (outputs ?? []).find(o => o.enabled && /^(eDP|LVDS|DSI)/.test(o.name ?? ""));
    return internal?.name ?? "";
}

// wlr-output-management rejects a configuration that leaves any head unconfigured, so every head is sent.
// Returns null when the output is missing, off, or already at the transform.
function headsWithTransform(outputs, name, transform) {
    const target = (outputs ?? []).find(o => o.name === name);
    if (!target?.enabled || target.transform === transform)
        return null;
    return outputs.map(o => {
        if (!o.enabled)
            return {
                "name": o.name,
                "enabled": false
            };
        const head = {
            "name": o.name,
            "enabled": true,
            "position": {
                "x": o.x ?? 0,
                "y": o.y ?? 0
            },
            "scale": o.scale ?? 1,
            "transform": o.name === name ? transform : (o.transform ?? 0)
        };
        if (o.currentMode?.id !== undefined)
            head.modeId = o.currentMode.id;
        if (o.adaptiveSyncSupported)
            head.adaptiveSync = o.adaptiveSync ?? 0;
        return head;
    });
}
