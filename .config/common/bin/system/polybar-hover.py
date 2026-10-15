#!/usr/bin/env python3
"""Hover tooltips for polybar that follow the mouse.

Polybar has no hover events, so this watches the mouse. When it rests on the bar for a moment,
it works out which module is under it and shows a tooltip (text from polybar-details.sh <module>
text) in a small window that follows the cursor until it leaves that module.

Modules are found by reading the bar: the divider between modules (separator in config.ini) is a
thin, tall, blue-grey line, so the columns that look like that split the bar into one region per
visible module. The visible modules, in order, come from polybar-collapse.sh visible. If the
counts don't match, no tooltip is shown.

HOVER_DELAY, BAR_HEIGHT and BIN can be overridden with environment variables for testing.
"""
import os
import subprocess
import sys
import time
from collections import Counter

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gio, GLib, Gtk  # noqa: E402
from PIL import ImageGrab  # noqa: E402

DELAY = float(os.environ.get("HOVER_DELAY", "0.12"))  # rest time before a tooltip appears.
PREFETCH_AFTER = 0.04  # rest time before we start looking up the module.
QUICK_WINDOW = 1.5  # seconds after a tooltip during which the next one appears with no wait.
CACHE_SECONDS = 4.0
REFRESH_SECONDS = 2.0  # how often the layout and texts are refreshed while on the bar.
BAR_HEIGHT = int(os.environ.get("BAR_HEIGHT", "32"))
BIN = os.environ.get("BIN", os.path.expanduser("~/bin/system"))
LEFT_BLOCK_END = 700  # separators left of this belong to the workspace area.
SEP_MIN_HEIGHT = 10  # the divider is a thin, tall, blue-grey line.
SEP_MAX_WIDTH = 3
TICK_MS = 25

CSS = b"""
window { background: #282a36; border: 1px solid #6272a4; }
label { color: #f8f8f2; font-family: monospace; font-size: 10pt; padding: 8px 12px; }
"""


def visible():
    out = subprocess.run([f"{BIN}/polybar-collapse.sh", "visible"], capture_output=True, text=True).stdout
    return out.split()


def read_layout():
    """Read the bar once: returns (start, dividers, modules, width) or None."""
    img = ImageGrab.grab(bbox=(0, 0, 1920, BAR_HEIGHT)).convert("RGB")
    w, h = img.size
    px = img.load()
    bg = Counter(px[i, h // 2] for i in range(LEFT_BLOCK_END, w)).most_common(1)[0][0]
    cols, start = [], None
    for i in range(LEFT_BLOCK_END, w):
        col = [px[i, j] for j in range(h)]
        if start is None and any(c != bg for c in col):
            start = i
        # blue-grey pixels: blue clearly above red and green (text is white or other colours).
        if sum(1 for r, g, b in col if b - r >= 40 and b - g >= 30) >= SEP_MIN_HEIGHT:
            cols.append(i)
    # group neighbouring columns; only thin groups are dividers (wider ones are blue icons).
    seps, group = [], []
    for i in cols + [None]:
        if group and (i is None or i - group[-1] > 1):
            if len(group) <= SEP_MAX_WIDTH:
                seps.append(group[0])
            group = []
        if i is not None:
            group.append(i)
    mods = visible()
    if start is None or len(seps) + 1 != len(mods):
        print(f"hover: {len(seps) + 1} regions but {len(mods)} modules", file=sys.stderr)
        return None
    return start, seps, mods, w


def lookup(layout, x):
    """Return (module, left, right) for the module under x, or None."""
    if not layout:
        return None
    start, seps, mods, w = layout
    if x < start:
        return None
    i = sum(1 for s in seps if s < x)
    return mods[i], (seps[i - 1] if i > 0 else start), (seps[i] if i < len(seps) else w)


def module_at(x):
    return lookup(read_layout(), x)


def tip_text(module):
    return subprocess.run([f"{BIN}/polybar-details.sh", module, "text"], capture_output=True, text=True).stdout.strip()


class Hover:
    def __init__(self):
        self.win = Gtk.Window(type=Gtk.WindowType.POPUP)
        self.win.set_decorated(False)
        self.win.set_accept_focus(False)
        self.win.set_type_hint(Gdk.WindowTypeHint.TOOLTIP)
        self.label = Gtk.Label()
        self.win.add(self.label)
        css = Gtk.CssProvider()
        css.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        seat = Gdk.Display.get_default().get_default_seat()
        self.pointer = seat.get_pointer()
        self.root = Gdk.get_default_root_window()
        self.last_x = -100
        self.rested = 0.0  # seconds the pointer has been still.
        self.region = None  # (module, lo, hi) of the tooltip being shown.
        self.hit = None  # (module, lo, hi) under the pointer, once looked up.
        self.text = None  # its tooltip text, once fetched.
        self.probed = False
        self.cache = {}
        self.layout = None
        self.refreshed_at = -1e9
        self.hidden_at = -1e9
        self.suppressed = None  # region we stopped showing for (clicked), until the pointer leaves it.
        GLib.timeout_add(TICK_MS, self.tick)

    def place(self, x):
        """Put the tooltip next to the cursor, kept inside the screen."""
        screen = Gdk.Screen.get_default()
        width, _ = self.win.get_size()
        self.win.move(max(0, min(x + 14, screen.get_width() - width - 4)), BAR_HEIGHT + 6)

    def hide(self):
        if self.region:
            self.hidden_at = time.monotonic()
        self.win.hide()
        self.region = None
        self.hit, self.text, self.probed = None, None, False

    def tick(self):
        _, x, y, mask = self.root.get_device_position(self.pointer)
        clicked = bool(mask & (Gdk.ModifierType.BUTTON1_MASK | Gdk.ModifierType.BUTTON2_MASK | Gdk.ModifierType.BUTTON3_MASK))
        if not 0 <= y < BAR_HEIGHT:
            self.hide()
            self.suppressed, self.last_x, self.rested = None, -100, 0.0
            self.refreshed_at = -1e9  # refresh again the moment the pointer is back on the bar.
            return True
        if self.region:
            _, lo, hi = self.region
            if clicked or not lo <= x < hi:
                if clicked:
                    self.suppressed = self.region
                self.hide()
                self.last_x, self.rested = x, 0.0
            else:
                self.place(x)  # follow the cursor along the bar, below it.
            return True
        if self.suppressed and self.suppressed[1] <= x < self.suppressed[2]:
            return True
        self.suppressed = None
        now = time.monotonic()
        if now - self.refreshed_at > REFRESH_SECONDS:
            self.refresh(now)
        if abs(x - self.last_x) > 4:
            self.last_x, self.rested, self.probed = x, 0.0, False
            if self.hit and not self.hit[1] <= x < self.hit[2]:
                self.hit, self.text = None, None  # moved to another module.
            return True
        self.rested += TICK_MS / 1000
        # as soon as the pointer is (nearly) still, work out the module and start fetching its text,
        # so both are ready by the time the delay is over.
        if self.hit is None and self.rested >= PREFETCH_AFTER and not self.probed:
            self.probed = True
            hit = lookup(self.layout, x)
            if hit and hit[0] != "separator":
                self.hit = hit
                self.fetch(hit[0])
        # no wait at all when moving between modules just after a tooltip.
        delay = 0.0 if now - self.hidden_at < QUICK_WINDOW else DELAY
        if self.hit and self.text and self.rested >= delay and not clicked:
            self.label.set_text(self.text)
            self.win.resize(1, 1)
            self.win.show_all()
            self.place(x)
            self.region = self.hit
        return True

    def refresh(self, now):
        """While the pointer is on the bar, keep the layout and every module's text ready."""
        self.refreshed_at = now
        self.layout = read_layout()
        if self.layout:
            for module in self.layout[2]:
                if module != "separator":
                    self.fetch(module, store_only=True)

    def fetch(self, module, store_only=False):
        """Get the tooltip text without blocking; cached briefly so repeat hovers are instant."""
        cached = self.cache.get(module)
        if cached and time.monotonic() - cached[0] < CACHE_SECONDS and not store_only:
            self.text = cached[1]
            return
        proc = Gio.Subprocess.new([f"{BIN}/polybar-details.sh", module, "text"], Gio.SubprocessFlags.STDOUT_PIPE)

        def done(p, res):
            _, out, _ = p.communicate_utf8_finish(res)
            text = (out or "").strip()
            if text:
                self.cache[module] = (time.monotonic(), text)
                if not store_only and self.hit and self.hit[0] == module:
                    self.text = text

        proc.communicate_utf8_async(None, None, done)


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--at":  # debugging: print the module at x.
        print(module_at(int(sys.argv[2])))
    else:
        Hover()
        Gtk.main()
