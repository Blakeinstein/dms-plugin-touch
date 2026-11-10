.pragma library

const COLOR_FLAGS = [["bg", "--bg"], ["fg", "--fg"], ["fgSp", "--fg-sp"], ["press", "--press"], ["pressSp", "--press-sp"], ["swipe", "--swipe"], ["swipeSp", "--swipe-sp"], ["text", "--text"], ["textSp", "--text-sp"]];

function channel(v) {
    const n = Math.round(Math.min(1, Math.max(0, Number(v) || 0)) * 255);
    return n.toString(16).padStart(2, "0");
}

function hex(c) {
    if (!c)
        return "";
    return channel(c.r) + channel(c.g) + channel(c.b) + channel(c.a ?? 1);
}

function argv(o) {
    const args = [o.binary || "wvkbd-mobintl"];
    if (o.height > 0)
        args.push("-H", String(o.height));
    if (o.landscapeHeight > 0)
        args.push("-L", String(o.landscapeHeight));
    if (o.radius > 0)
        args.push("-R", String(Math.round(o.radius)));
    if (o.font)
        args.push("--fn", o.fontSize > 0 ? `${o.font} ${Math.round(o.fontSize)}` : o.font);
    if (o.layers)
        args.push("-l", o.layers);
    for (const [key, flag] of COLOR_FLAGS) {
        const value = hex(o.colors?.[key]);
        if (value)
            args.push(flag, value);
    }
    if (o.hidden)
        args.push("--hidden");
    if (o.auto)
        args.push("--auto");
    return args;
}
