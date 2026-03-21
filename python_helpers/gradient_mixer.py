"""
gradient.py — Hex color gradient tool + GUI

Importable API:
    from gradient import Gradient, make_gradient

Run directly for the interactive GUI (uses tkinter — ships with Python):
    python gradient.py
"""

from __future__ import annotations
import re
import tkinter as tk
from tkinter import ttk, colorchooser


# ═══════════════════════════════════════════════════════════════════════════════
# Core gradient engine
# ═══════════════════════════════════════════════════════════════════════════════

def _parse_hex(hex_color: str) -> tuple[int, int, int]:
    """Parse a hex color string to an (R, G, B) tuple."""
    hex_color = hex_color.strip().lstrip("#")
    if len(hex_color) == 3:
        hex_color = "".join(c * 2 for c in hex_color)
    if len(hex_color) != 6 or not re.fullmatch(r"[0-9a-fA-F]{6}", hex_color):
        raise ValueError(f"Invalid hex color: #{hex_color!r}")
    return int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)


def _to_hex(r: int | float, g: int | float, b: int | float) -> str:
    """Convert (R, G, B) to an uppercase hex string."""
    return "#{:02X}{:02X}{:02X}".format(
        max(0, min(255, round(r))),
        max(0, min(255, round(g))),
        max(0, min(255, round(b))),
    )


def _lerp_rgb(
    a: tuple[int, int, int], b: tuple[int, int, int], t: float
) -> tuple[float, float, float]:
    return (
        a[0] + t * (b[0] - a[0]),
        a[1] + t * (b[1] - a[1]),
        a[2] + t * (b[2] - a[2]),
    )


class Gradient:
    """
    A multi-stop color gradient defined by hex colors at percentage positions.

    Usage
    -----
    >>> g = Gradient()
    >>> g.add_stop(0,   "#FF0000")
    >>> g.add_stop(50,  "#00FF00")
    >>> g.add_stop(100, "#0000FF")
    >>> g.sample(25)
    '#7F7F00'

    Or shorthand:
    >>> g = Gradient.from_stops([(0, "#000"), (100, "#FFF")])
    """

    def __init__(self) -> None:
        self._stops: list[tuple[float, tuple[int, int, int]]] = []

    # ── building ──────────────────────────────────────────────────────────────

    def add_stop(self, percentage: float, hex_color: str) -> "Gradient":
        """Add (or replace) a color stop at *percentage* (0–100)."""
        if not (0.0 <= percentage <= 100.0):
            raise ValueError(f"Percentage must be in [0, 100], got {percentage}")
        rgb = _parse_hex(hex_color)
        self._stops = [s for s in self._stops if s[0] != percentage]
        self._stops.append((float(percentage), rgb))
        self._stops.sort(key=lambda s: s[0])
        return self

    def remove_stop(self, percentage: float) -> "Gradient":
        """Remove the stop at *percentage* (if it exists)."""
        self._stops = [s for s in self._stops if s[0] != percentage]
        return self

    def clear(self) -> "Gradient":
        """Remove all stops."""
        self._stops.clear()
        return self

    @classmethod
    def from_stops(cls, stops: list[tuple[float, str]]) -> "Gradient":
        """Create a Gradient from a list of ``(percentage, hex_color)`` tuples."""
        g = cls()
        for pct, color in stops:
            g.add_stop(pct, color)
        return g

    # ── querying ──────────────────────────────────────────────────────────────

    def sample(self, percentage: float) -> str:
        """Return the interpolated hex color at *percentage* (0–100)."""
        if not (0.0 <= percentage <= 100.0):
            raise ValueError(f"Percentage must be in [0, 100], got {percentage}")
        if len(self._stops) < 2:
            raise ValueError(
                f"A gradient needs at least 2 stops; currently has {len(self._stops)}."
            )
        pct = float(percentage)
        for stop_pct, rgb in self._stops:
            if stop_pct == pct:
                return _to_hex(*rgb)
        if pct <= self._stops[0][0]:
            return _to_hex(*self._stops[0][1])
        if pct >= self._stops[-1][0]:
            return _to_hex(*self._stops[-1][1])
        for i in range(len(self._stops) - 1):
            a_pct, a_rgb = self._stops[i]
            b_pct, b_rgb = self._stops[i + 1]
            if a_pct <= pct <= b_pct:
                t = (pct - a_pct) / (b_pct - a_pct)
                return _to_hex(*_lerp_rgb(a_rgb, b_rgb, t))
        return _to_hex(*self._stops[-1][1])

    def sample_many(self, percentages: list[float]) -> list[tuple[float, str]]:
        """Sample multiple percentages; returns ``[(pct, hex), …]``."""
        return [(p, self.sample(p)) for p in percentages]

    def sample_range(
        self, start: float = 0.0, end: float = 100.0, steps: int = 11
    ) -> list[tuple[float, str]]:
        """Sample *steps* evenly spaced positions from *start* to *end*."""
        if steps < 2:
            raise ValueError("steps must be >= 2")
        interval = (end - start) / (steps - 1)
        return self.sample_many([start + i * interval for i in range(steps)])

    def steps(self, n: int) -> list[tuple[float, str]]:
        """
        Return *n* evenly spaced colors always including 0 % and 100 %.

        ``steps(6)`` → positions 0, 20, 40, 60, 80, 100 %.
        """
        return self.sample_range(start=0.0, end=100.0, steps=n)

    # ── introspection ─────────────────────────────────────────────────────────

    @property
    def stops(self) -> list[tuple[float, str]]:
        """Return stops as ``[(percentage, hex_color), …]``."""
        return [(pct, _to_hex(*rgb)) for pct, rgb in self._stops]

    def __len__(self) -> int:
        return len(self._stops)

    def __repr__(self) -> str:
        stops_repr = ", ".join(f"{p}%→{_to_hex(*rgb)}" for p, rgb in self._stops)
        return f"Gradient([{stops_repr}])"


def make_gradient(*stops: tuple[float, str]) -> Gradient:
    """
    Shorthand constructor.

    >>> g = make_gradient((0, "#FF0000"), (50, "#FFFF00"), (100, "#00FF00"))
    """
    return Gradient.from_stops(list(stops))


# ═══════════════════════════════════════════════════════════════════════════════
# GUI  (tkinter — ships with Python on Windows, Mac, and Linux)
# ═══════════════════════════════════════════════════════════════════════════════

# ── colour helpers ─────────────────────────────────────────────────────────────

def _luminance(r: int, g: int, b: int) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def _fg_for(hex_color: str) -> str:
    """Return black or white — whichever is more legible on *hex_color*."""
    try:
        r, g, b = _parse_hex(hex_color)
        return "#000000" if _luminance(r, g, b) > 140 else "#ffffff"
    except Exception:
        return "#ffffff"


# ── design tokens ──────────────────────────────────────────────────────────────

BG        = "#1a1a1a"   # window background
SURFACE   = "#242424"   # card / panel background
BORDER    = "#333333"   # subtle border
TEXT      = "#e8e8e8"   # primary text
TEXT_MUTED= "#888888"   # labels / hints
ACCENT    = "#4a90d9"   # active tab, focus ring
FONT      = ("Segoe UI", 10)
FONT_MONO = ("Consolas", 10)
FONT_SM   = ("Segoe UI", 9)
FONT_LG   = ("Segoe UI", 14, "bold")
RADIUS    = 6           # canvas arc radius for rounded rects
BAR_H     = 48          # gradient bar height in px
STRIP_H   = 24          # preview strip height in px
PAD       = 16          # outer padding


# ── rounded rectangle helper ───────────────────────────────────────────────────

def _rrect(canvas, x1, y1, x2, y2, r=RADIUS, **kwargs):
    """Draw a rounded rectangle on *canvas*."""
    canvas.create_arc(x1,     y1,     x1+2*r, y1+2*r, start= 90, extent=90, style="pieslice", **kwargs)
    canvas.create_arc(x2-2*r, y1,     x2,     y1+2*r, start=  0, extent=90, style="pieslice", **kwargs)
    canvas.create_arc(x2-2*r, y2-2*r, x2,     y2,     start=270, extent=90, style="pieslice", **kwargs)
    canvas.create_arc(x1,     y2-2*r, x1+2*r, y2,     start=180, extent=90, style="pieslice", **kwargs)
    canvas.create_rectangle(x1+r, y1, x2-r, y2, **kwargs)
    canvas.create_rectangle(x1, y1+r, x2, y2-r, **kwargs)


# ── HSL ↔ RGB helpers ──────────────────────────────────────────────────────────

def _rgb_to_hsl(r: int, g: int, b: int) -> tuple[float, float, float]:
    """Return (h 0-360, s 0-1, l 0-1) from 8-bit RGB."""
    r_, g_, b_ = r / 255, g / 255, b / 255
    cmax, cmin = max(r_, g_, b_), min(r_, g_, b_)
    delta = cmax - cmin
    l = (cmax + cmin) / 2
    s = 0.0 if delta == 0 else delta / (1 - abs(2 * l - 1))
    if delta == 0:
        h = 0.0
    elif cmax == r_:
        h = 60 * (((g_ - b_) / delta) % 6)
    elif cmax == g_:
        h = 60 * (((b_ - r_) / delta) + 2)
    else:
        h = 60 * (((r_ - g_) / delta) + 4)
    return h, s, l


def _hsl_to_rgb(h: float, s: float, l: float) -> tuple[int, int, int]:
    """Return 8-bit RGB from (h 0-360, s 0-1, l 0-1)."""
    h = h % 360
    s = max(0.0, min(1.0, s))
    l = max(0.0, min(1.0, l))
    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = l - c / 2
    if   h < 60:  r_, g_, b_ = c, x, 0
    elif h < 120: r_, g_, b_ = x, c, 0
    elif h < 180: r_, g_, b_ = 0, c, x
    elif h < 240: r_, g_, b_ = 0, x, c
    elif h < 300: r_, g_, b_ = x, 0, c
    else:         r_, g_, b_ = c, 0, x
    return round((r_ + m) * 255), round((g_ + m) * 255), round((b_ + m) * 255)


def _shift_hue(hex_color: str, degrees: float) -> str:
    h, s, l = _rgb_to_hsl(*_parse_hex(hex_color))
    return _to_hex(*_hsl_to_rgb((h + degrees) % 360, s, l))


# ── stop row widget ────────────────────────────────────────────────────────────

class StopRow(tk.Frame):
    """One editable row representing a gradient stop, with drag-reorder and HSL nudge."""

    def __init__(self, parent, pct: float, hex_color: str,
                 on_change, on_remove, on_drag_start, on_drag_motion, on_drag_end,
                 can_remove: bool):
        super().__init__(parent, bg=SURFACE)
        self._on_change     = on_change
        self._on_remove     = on_remove
        self._on_drag_start  = on_drag_start
        self._on_drag_motion = on_drag_motion
        self._on_drag_end    = on_drag_end
        self._pct       = pct
        self._hex       = hex_color
        self._updating  = False
        self._expanded  = False
        self._nudge_frame: tk.Frame | None = None
        self._nudge_origin: str = hex_color
        self._hue_var: tk.DoubleVar | None = None
        self._r_var:   tk.DoubleVar | None = None
        self._g_var:   tk.DoubleVar | None = None
        self._b_var:   tk.DoubleVar | None = None
        self._build(can_remove)

    def _build(self, can_remove: bool) -> None:
        # ── main row ──────────────────────────────────────────────────────
        main = tk.Frame(self, bg=SURFACE)
        main.pack(fill="x")

        # drag handle — only this widget initiates reorder drags
        handle = tk.Label(main, text="⠿", bg=SURFACE, fg=TEXT_MUTED,
                          font=("Segoe UI", 12), cursor="fleur", padx=4)
        handle.pack(side="left")
        handle.bind("<ButtonPress-1>",   self._drag_press)
        handle.bind("<B1-Motion>",       self._drag_motion)
        handle.bind("<ButtonRelease-1>", self._drag_release)

        # swatch / color picker
        self._swatch = tk.Label(main, width=3, bg=self._hex,
                                relief="flat", cursor="hand2")
        self._swatch.pack(side="left", padx=(2, 8), ipady=6)
        self._swatch.bind("<Button-1>", self._pick_color)

        # hex entry
        self._hex_var = tk.StringVar(value=self._hex.lstrip("#"))
        hex_entry = tk.Entry(
            main, textvariable=self._hex_var, width=8,
            font=FONT_MONO, bg="#2d2d2d", fg=TEXT,
            insertbackground=TEXT, relief="flat",
            highlightthickness=1, highlightbackground=BORDER,
            highlightcolor=ACCENT,
        )
        hex_entry.pack(side="left", padx=(0, 6))
        self._hex_var.trace_add("write", self._hex_edited)

        tk.Label(main, text="at", bg=SURFACE, fg=TEXT_MUTED,
                 font=FONT_SM).pack(side="left", padx=4)

        # pct entry
        self._pct_var = tk.StringVar(value=f"{self._pct:.1f}")
        tk.Entry(
            main, textvariable=self._pct_var, width=6,
            font=FONT_MONO, bg="#2d2d2d", fg=TEXT,
            insertbackground=TEXT, relief="flat",
            highlightthickness=1, highlightbackground=BORDER,
            highlightcolor=ACCENT,
        ).pack(side="left", padx=(0, 2))
        self._pct_var.trace_add("write", self._pct_edited)

        tk.Label(main, text="%", bg=SURFACE, fg=TEXT_MUTED,
                 font=FONT_SM).pack(side="left")

        # nudge toggle button
        self._nudge_btn = tk.Label(main, text="✦", bg=SURFACE, fg=TEXT_MUTED,
                                   font=FONT_SM, cursor="hand2", padx=4)
        self._nudge_btn.pack(side="left", padx=(6, 0))
        self._nudge_btn.bind("<Button-1>", self._toggle_nudge)
        self._nudge_btn.bind("<Enter>",    lambda _e: self._nudge_btn.config(fg=TEXT))
        self._nudge_btn.bind("<Leave>",    lambda _e: self._nudge_btn.config(
            fg=ACCENT if self._expanded else TEXT_MUTED))

        # remove button
        if can_remove:
            btn = tk.Label(main, text="✕", bg=SURFACE, fg=TEXT_MUTED,
                           font=FONT_SM, cursor="hand2", padx=4)
            btn.pack(side="right")
            btn.bind("<Button-1>", lambda _e: self._on_remove(self._pct))
            btn.bind("<Enter>",    lambda _e: btn.config(fg=TEXT))
            btn.bind("<Leave>",    lambda _e: btn.config(fg=TEXT_MUTED))

    # ── nudge panel ───────────────────────────────────────────────────────

    def _toggle_nudge(self, _event=None) -> None:
        self._expanded = not self._expanded
        self._nudge_btn.config(fg=ACCENT if self._expanded else TEXT_MUTED)
        if self._expanded:
            self._build_nudge_panel()
        else:
            if self._nudge_frame:
                self._nudge_frame.destroy()
                self._nudge_frame = None

    def _build_nudge_panel(self) -> None:
        if self._nudge_frame:
            self._nudge_frame.destroy()

        f = tk.Frame(self, bg="#1e1e1e", padx=10, pady=8)
        f.pack(fill="x", padx=4, pady=(0, 4))
        self._nudge_frame = f

        # store the original color when the panel opens so sliders are relative
        self._nudge_origin = self._hex

        # hue offset: −180 … +180 degrees
        self._hue_var = tk.DoubleVar(value=0.0)
        # per-channel offsets: −128 … +128
        self._r_var = tk.DoubleVar(value=0.0)
        self._g_var = tk.DoubleVar(value=0.0)
        self._b_var = tk.DoubleVar(value=0.0)

        PANEL_BG = "#1e1e1e"
        TRACK_BG = "#2d2d2d"

        def _slider_row(parent, label, variable, from_, to, color):
            row = tk.Frame(parent, bg=PANEL_BG)
            row.pack(fill="x", pady=3)

            tk.Label(row, text=label, bg=PANEL_BG, fg=color,
                     font=FONT_SM, width=2, anchor="w").pack(side="left")

            slider = ttk.Scale(row, from_=from_, to=to, orient="horizontal",
                               variable=variable,
                               command=lambda _v: self._apply_nudge_sliders())
            slider.pack(side="left", fill="x", expand=True, padx=(4, 8))

            val_lbl = tk.Label(row, text=" 0", bg=PANEL_BG, fg=TEXT_MUTED,
                               font=FONT_MONO, width=5, anchor="e")
            val_lbl.pack(side="left")

            # keep value label in sync
            def _update_lbl(*_):
                v = variable.get()
                val_lbl.config(text=f"{v:+.0f}" if v != 0 else " 0")
            variable.trace_add("write", _update_lbl)

            return slider

        # section: hue
        tk.Label(f, text="HUE", bg=PANEL_BG, fg=TEXT_MUTED,
                 font=FONT_SM).pack(anchor="w", pady=(0, 2))
        _slider_row(f, "H", self._hue_var, -180, 180, "#cc88ff")

        tk.Frame(f, bg=BORDER, height=1).pack(fill="x", pady=6)

        # section: RGB channels
        tk.Label(f, text="RGB", bg=PANEL_BG, fg=TEXT_MUTED,
                 font=FONT_SM).pack(anchor="w", pady=(0, 2))
        _slider_row(f, "R", self._r_var, -128, 128, "#ff6666")
        _slider_row(f, "G", self._g_var, -128, 128, "#66cc66")
        _slider_row(f, "B", self._b_var, -128, 128, "#6699ff")

        # reset button
        reset_row = tk.Frame(f, bg=PANEL_BG)
        reset_row.pack(fill="x", pady=(6, 0))
        reset_btn = tk.Label(reset_row, text="reset", bg=TRACK_BG, fg=TEXT_MUTED,
                             font=FONT_SM, padx=8, pady=2, cursor="hand2")
        reset_btn.pack(side="right")
        reset_btn.bind("<Button-1>", self._reset_nudge)
        reset_btn.bind("<Enter>",    lambda _e: reset_btn.config(fg=TEXT))
        reset_btn.bind("<Leave>",    lambda _e: reset_btn.config(fg=TEXT_MUTED))

    def _apply_nudge_sliders(self) -> None:
        try:
            origin = self._nudge_origin
            # 1. apply hue rotation to the origin color
            hue_shifted = _shift_hue(origin, self._hue_var.get())
            # 2. apply RGB channel offsets on top
            r, g, b = _parse_hex(hue_shifted)
            r = max(0, min(255, round(r + self._r_var.get())))
            g = max(0, min(255, round(g + self._g_var.get())))
            b = max(0, min(255, round(b + self._b_var.get())))
            new_hex = _to_hex(r, g, b)
            self._hex = new_hex
            self._updating = True
            self._hex_var.set(new_hex.lstrip("#"))
            self._swatch.config(bg=new_hex)
            self._updating = False
            self._on_change(self._pct, self._pct, new_hex)
        except Exception:
            pass

    def _reset_nudge(self, _event=None) -> None:
        for var in (self._hue_var, self._r_var, self._g_var, self._b_var):
            var.set(0.0)
        # snap back to the color the panel opened with
        self._hex = self._nudge_origin
        self._updating = True
        self._hex_var.set(self._nudge_origin.lstrip("#"))
        self._swatch.config(bg=self._nudge_origin)
        self._updating = False
        self._on_change(self._pct, self._pct, self._nudge_origin)

    # ── drag reorder ──────────────────────────────────────────────────────

    def _drag_press(self, event) -> None:
        self._on_drag_start(self, event)

    def _drag_motion(self, event) -> None:
        self._on_drag_motion(self, event)

    def _drag_release(self, event) -> None:
        self._on_drag_end(self, event)

    # ── color / hex / pct editing ─────────────────────────────────────────

    def _pick_color(self, _event=None) -> None:
        result = colorchooser.askcolor(color=self._hex, title="Pick colour")
        if result and result[1]:
            new_hex = result[1].upper()
            self._hex = new_hex
            self._updating = True
            self._hex_var.set(new_hex.lstrip("#"))
            self._swatch.config(bg=new_hex)
            self._updating = False
            self._on_change(self._pct, self._pct, new_hex)

    def _hex_edited(self, *_) -> None:
        if self._updating:
            return
        val = self._hex_var.get().strip().lstrip("#")
        try:
            norm = _to_hex(*_parse_hex(val))
            self._hex = norm
            self._swatch.config(bg=norm)
            self._on_change(self._pct, self._pct, norm)
        except ValueError:
            pass

    def _pct_edited(self, *_) -> None:
        if self._updating:
            return
        val = self._pct_var.get().strip().rstrip("%")
        try:
            new_pct = float(val)
            if 0.0 <= new_pct <= 100.0:
                old_pct = self._pct
                self._pct = new_pct
                self._on_change(old_pct, new_pct, self._hex)
        except ValueError:
            pass


# ── main application window ────────────────────────────────────────────────────

class GradientApp(tk.Tk):

    def __init__(self, gradient: Gradient | None = None):
        super().__init__()
        self.gradient = gradient or make_gradient(
            (0,   "#FF4500"),
            (50,  "#FFD700"),
            (100, "#0D0221"),
        )
        self.title("Gradient Tool")
        self.configure(bg=BG)
        self.resizable(True, True)
        self.minsize(520, 560)

        self._sample_pct = tk.DoubleVar(value=50.0)
        self._steps_n    = tk.IntVar(value=6)
        self._active_tab = tk.StringVar(value="sample")
        self._drag_row: StopRow | None = None
        self._drag_ghost: tk.Toplevel | None = None

        self._build()
        self.after(50, self._refresh)

    # ── layout ────────────────────────────────────────────────────────────────

    def _build(self) -> None:
        outer = tk.Frame(self, bg=BG, padx=PAD, pady=PAD)
        outer.pack(fill="both", expand=True)

        # gradient bar
        self._bar_label = tk.Label(outer, text="GRADIENT", bg=BG,
                                   fg=TEXT_MUTED, font=FONT_SM)
        self._bar_label.pack(anchor="w", pady=(0, 4))

        self._bar_canvas = tk.Canvas(
            outer, height=BAR_H, bg=BG, highlightthickness=0, cursor="crosshair"
        )
        self._bar_canvas.pack(fill="x", pady=(0, PAD))
        self._bar_canvas.bind("<Configure>", lambda _e: self._draw_bar())
        self._bar_canvas.bind("<Button-1>",  self._bar_click)

        # stop marker drag state
        self._drag_pct: float | None = None

        # stops section
        tk.Label(outer, text="STOPS", bg=BG, fg=TEXT_MUTED,
                 font=FONT_SM).pack(anchor="w", pady=(0, 4))

        self._stops_frame = tk.Frame(outer, bg=BG)
        self._stops_frame.pack(fill="x", pady=(0, 6))

        add_btn = tk.Label(outer, text="+ add stop", bg=BG, fg=TEXT_MUTED,
                           font=FONT_SM, cursor="hand2")
        add_btn.pack(anchor="w", pady=(0, PAD))
        add_btn.bind("<Button-1>", lambda _e: self._add_stop())
        add_btn.bind("<Enter>",    lambda _e: add_btn.config(fg=TEXT))
        add_btn.bind("<Leave>",    lambda _e: add_btn.config(fg=TEXT_MUTED))

        # tab bar
        tabs_frame = tk.Frame(outer, bg=BG)
        tabs_frame.pack(fill="x", pady=(0, 2))
        self._tab_btns: dict[str, tk.Label] = {}
        for key, label in (("sample", "sample at %"), ("steps", "n steps")):
            btn = tk.Label(tabs_frame, text=f" {label} ", bg=BG, fg=TEXT_MUTED,
                           font=FONT, cursor="hand2", padx=6, pady=4)
            btn.pack(side="left")
            btn.bind("<Button-1>", lambda _e, k=key: self._switch_tab(k))
            self._tab_btns[key] = btn
        ttk.Separator(outer, orient="horizontal").pack(fill="x", pady=(0, 8))

        # panel container
        self._panel_frame = tk.Frame(outer, bg=BG)
        self._panel_frame.pack(fill="both", expand=True)

        self._build_sample_panel()
        self._build_steps_panel()

        # preview strip
        tk.Label(outer, text="PREVIEW", bg=BG, fg=TEXT_MUTED,
                 font=FONT_SM).pack(anchor="w", pady=(PAD, 4))
        self._strip_canvas = tk.Canvas(
            outer, height=STRIP_H, bg=BG, highlightthickness=0
        )
        self._strip_canvas.pack(fill="x", pady=(0, 4))
        self._strip_canvas.bind("<Configure>", lambda _e: self._draw_strip())

        self._switch_tab("sample")

    def _build_sample_panel(self) -> None:
        self._sample_panel = tk.Frame(self._panel_frame, bg=BG)

        row = tk.Frame(self._sample_panel, bg=BG)
        row.pack(fill="x", pady=(0, 10))
        tk.Label(row, text="position", bg=BG, fg=TEXT_MUTED,
                 font=FONT_SM).pack(side="left", padx=(0, 8))

        slider = ttk.Scale(row, from_=0, to=100, orient="horizontal",
                           variable=self._sample_pct,
                           command=lambda _v: self._refresh_sample())
        slider.pack(side="left", fill="x", expand=True, padx=(0, 8))

        self._sample_pct_lbl = tk.Label(row, text="50.0%", bg=BG, fg=TEXT,
                                        font=FONT_MONO, width=6)
        self._sample_pct_lbl.pack(side="left")

        # result card
        card = tk.Frame(self._sample_panel, bg=SURFACE,
                        highlightthickness=1, highlightbackground=BORDER)
        card.pack(fill="x", pady=(0, 8))
        card.pack_propagate(False)
        card.config(height=54)

        self._sample_swatch = tk.Label(card, width=5, bg="#808080", relief="flat")
        self._sample_swatch.pack(side="left", fill="y", padx=(12, 14), pady=10)

        info = tk.Frame(card, bg=SURFACE)
        info.pack(side="left", fill="both", expand=True, pady=10)

        self._sample_hex_lbl = tk.Entry(
            info, font=FONT_LG, bg=SURFACE, fg=TEXT,
            relief="flat", bd=0, highlightthickness=0,
            readonlybackground=SURFACE, state="readonly",
        )
        self._sample_hex_lbl.pack(anchor="w")

        self._sample_rgb_lbl = tk.Entry(
            info, font=FONT_SM, bg=SURFACE, fg=TEXT_MUTED,
            relief="flat", bd=0, highlightthickness=0,
            readonlybackground=SURFACE, state="readonly",
        )
        self._sample_rgb_lbl.pack(anchor="w")

    def _build_steps_panel(self) -> None:
        self._steps_panel = tk.Frame(self._panel_frame, bg=BG)

        row = tk.Frame(self._steps_panel, bg=BG)
        row.pack(fill="x", pady=(0, 10))
        tk.Label(row, text="steps", bg=BG, fg=TEXT_MUTED,
                 font=FONT_SM).pack(side="left", padx=(0, 8))

        slider = ttk.Scale(row, from_=2, to=20, orient="horizontal",
                           variable=self._steps_n,
                           command=lambda v: (
                               self._steps_n.set(round(float(v))),
                               self._refresh_steps(),
                           ))
        slider.pack(side="left", fill="x", expand=True, padx=(0, 8))

        self._steps_n_lbl = tk.Label(row, text="n = 6", bg=BG, fg=TEXT,
                                     font=FONT_MONO, width=6)
        self._steps_n_lbl.pack(side="left")

        # scrollable results list
        list_outer = tk.Frame(self._steps_panel, bg=BG)
        list_outer.pack(fill="both", expand=True)

        self._steps_canvas = tk.Canvas(list_outer, bg=BG, highlightthickness=0)
        scrollbar = ttk.Scrollbar(list_outer, orient="vertical",
                                  command=self._steps_canvas.yview)
        self._steps_inner = tk.Frame(self._steps_canvas, bg=BG)

        self._steps_inner.bind(
            "<Configure>",
            lambda _e: self._steps_canvas.configure(
                scrollregion=self._steps_canvas.bbox("all")
            )
        )
        self._steps_canvas.create_window((0, 0), window=self._steps_inner, anchor="nw")
        self._steps_canvas.configure(yscrollcommand=scrollbar.set)

        self._steps_canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

    # ── tab switching ─────────────────────────────────────────────────────────

    def _switch_tab(self, key: str) -> None:
        self._active_tab.set(key)
        for k, btn in self._tab_btns.items():
            if k == key:
                btn.config(fg=TEXT, font=(*FONT[:1], FONT[1], "bold"),
                           relief="flat")
            else:
                btn.config(fg=TEXT_MUTED, font=FONT, relief="flat")

        self._sample_panel.pack_forget()
        self._steps_panel.pack_forget()

        if key == "sample":
            self._sample_panel.pack(fill="both", expand=True)
            self._refresh_sample()
        else:
            self._steps_panel.pack(fill="both", expand=True)
            self._refresh_steps()

    # ── gradient bar ──────────────────────────────────────────────────────────

    def _draw_bar(self) -> None:
        c = self._bar_canvas
        c.delete("all")
        w = c.winfo_width()
        h = BAR_H
        if w < 2 or len(self.gradient) < 2:
            return

        # draw gradient as vertical pixel columns
        for col in range(w):
            pct = col * 100 / (w - 1)
            try:
                color = self.gradient.sample(pct)
                c.create_line(col, 0, col, h, fill=color)
            except Exception:
                pass

        # draw stop markers
        for pct, hex_color in self.gradient.stops:
            x = round(pct * (w - 1) / 100)
            fg = _fg_for(hex_color)
            # white pin with colored dot
            c.create_oval(x-6, h-13, x+6, h-1, fill=hex_color, outline=fg, width=1.5,
                          tags=("marker", f"stop_{pct}"))
            c.create_line(x, 0, x, h-14, fill=fg, width=1, dash=(2, 2))

        c.tag_bind("marker", "<ButtonPress-1>",   self._marker_press)
        c.tag_bind("marker", "<B1-Motion>",       self._marker_drag)
        c.tag_bind("marker", "<ButtonRelease-1>", self._marker_release)

    def _bar_click(self, event) -> None:
        # Ignore if we clicked a marker
        if self._bar_canvas.find_withtag("current") and \
           "marker" in self._bar_canvas.gettags("current"):
            return
        w = self._bar_canvas.winfo_width()
        if w < 2:
            return
        pct = round(event.x * 100 / (w - 1), 1)
        pct = max(0.0, min(100.0, pct))
        try:
            new_hex = self.gradient.sample(pct)
        except Exception:
            new_hex = "#808080"
        self.gradient.add_stop(pct, new_hex)
        self._refresh()

    def _marker_press(self, event) -> None:
        tags = self._bar_canvas.gettags("current")
        for t in tags:
            if t.startswith("stop_"):
                try:
                    self._drag_pct = float(t[5:])
                except ValueError:
                    pass
                return

    def _marker_drag(self, event) -> None:
        if self._drag_pct is None:
            return
        w = self._bar_canvas.winfo_width()
        if w < 2:
            return
        new_pct = round(max(0.0, min(100.0, event.x * 100 / (w - 1))), 1)
        old_pct = self._drag_pct
        # find the stop's hex
        for pct, hex_color in self.gradient.stops:
            if abs(pct - old_pct) < 0.05:
                self.gradient.remove_stop(old_pct)
                self.gradient.add_stop(new_pct, hex_color)
                self._drag_pct = new_pct
                self._refresh()
                return

    def _marker_release(self, _event) -> None:
        self._drag_pct = None

    # ── stops panel ───────────────────────────────────────────────────────────

    def _rebuild_stops_panel(self) -> None:
        for w in self._stops_frame.winfo_children():
            w.destroy()
        stops = self.gradient.stops
        can_remove = len(stops) > 2
        for pct, hex_color in stops:
            row = StopRow(
                self._stops_frame,
                pct, hex_color,
                on_change=self._stop_changed,
                on_remove=self._remove_stop,
                on_drag_start=self._drag_start,
                on_drag_motion=self._drag_motion,
                on_drag_end=self._drag_end,
                can_remove=can_remove,
            )
            row.pack(fill="x", pady=2, padx=2, ipady=4, ipadx=6)

    # ── drag-to-reorder ───────────────────────────────────────────────────────

    def _drag_start(self, row: "StopRow", event) -> None:
        self._drag_row   = row
        self._drag_ghost = tk.Toplevel(self)
        self._drag_ghost.overrideredirect(True)
        self._drag_ghost.attributes("-alpha", 0.75)
        ghost_lbl = tk.Label(
            self._drag_ghost,
            text=f"  {row._hex.lstrip('#')}  at  {row._pct:.1f}%  ",
            bg=row._hex, fg=_fg_for(row._hex),
            font=FONT_MONO, relief="flat", padx=6, pady=4,
        )
        ghost_lbl.pack()
        self._drag_ghost.geometry(f"+{event.x_root+10}+{event.y_root+10}")
        row.config(relief="sunken")

    def _drag_motion(self, row: "StopRow", event) -> None:
        if not hasattr(self, "_drag_ghost") or self._drag_ghost is None:
            return
        self._drag_ghost.geometry(f"+{event.x_root+10}+{event.y_root+10}")

        # highlight the row the cursor is currently over
        for child in self._stops_frame.winfo_children():
            child.config(highlightthickness=0)
        target = self._row_at_y(event.y_root)
        if target and target is not row:
            target.config(highlightbackground=ACCENT, highlightthickness=1)

    def _drag_end(self, row: "StopRow", event) -> None:
        if hasattr(self, "_drag_ghost") and self._drag_ghost:
            self._drag_ghost.destroy()
            self._drag_ghost = None

        for child in self._stops_frame.winfo_children():
            child.config(highlightthickness=0, relief="flat")

        target = self._row_at_y(event.y_root)
        if target and target is not row:
            # swap the colors between the two stops, keeping percentages fixed
            self.gradient.remove_stop(row._pct)
            self.gradient.remove_stop(target._pct)
            self.gradient.add_stop(row._pct,    target._hex)
            self.gradient.add_stop(target._pct, row._hex)
            self._refresh()

        self._drag_row = None

    def _row_at_y(self, y_root: int) -> "StopRow | None":
        """Return the StopRow whose screen position contains y_root."""
        for child in self._stops_frame.winfo_children():
            if not isinstance(child, StopRow):
                continue
            try:
                cy = child.winfo_rooty()
                ch = child.winfo_height()
                if cy <= y_root <= cy + ch:
                    return child
            except Exception:
                pass
        return None

    def _stop_changed(self, old_pct: float, new_pct: float, new_hex: str) -> None:
        self.gradient.remove_stop(old_pct)
        try:
            self.gradient.add_stop(new_pct, new_hex)
        except Exception:
            pass
        # Color-only change: just redraw visuals, don't rebuild stop rows.
        # Rebuilding destroys the nudge panel mid-slider-drag.
        if old_pct == new_pct:
            self._draw_bar()
            self._draw_strip()
            if self._active_tab.get() == "sample":
                self._refresh_sample()
            else:
                self._refresh_steps()
        else:
            self._refresh()

    def _remove_stop(self, pct: float) -> None:
        if len(self.gradient) > 2:
            self.gradient.remove_stop(pct)
            self._refresh()

    def _add_stop(self) -> None:
        stops = self.gradient.stops
        best_mid, best_gap = 50.0, 0.0
        for i in range(len(stops) - 1):
            gap = stops[i + 1][0] - stops[i][0]
            if gap > best_gap:
                best_gap = gap
                best_mid = (stops[i][0] + stops[i + 1][0]) / 2
        try:
            new_hex = self.gradient.sample(best_mid)
        except Exception:
            new_hex = "#808080"
        self.gradient.add_stop(round(best_mid, 1), new_hex)
        self._refresh()

    # ── sample panel ──────────────────────────────────────────────────────────

    def _refresh_sample(self) -> None:
        pct = self._sample_pct.get()
        self._sample_pct_lbl.config(text=f"{pct:.1f}%")
        try:
            color = self.gradient.sample(pct)
            r, g, b = _parse_hex(color)
            self._sample_swatch.config(bg=color)
            for widget, text in (
                (self._sample_hex_lbl, color.lstrip("#")),
                (self._sample_rgb_lbl, f"rgb({r}, {g}, {b})"),
            ):
                widget.config(state="normal")
                widget.delete(0, "end")
                widget.insert(0, text)
                widget.config(state="readonly")
        except Exception:
            pass

    # ── steps panel ───────────────────────────────────────────────────────────

    def _refresh_steps(self) -> None:
        n = int(self._steps_n.get())
        self._steps_n_lbl.config(text=f"n = {n}")
        for w in self._steps_inner.winfo_children():
            w.destroy()
        try:
            results = self.gradient.steps(n)
        except Exception:
            return

        def _ro_entry(parent, text, width, fg=TEXT, font=FONT_MONO):
            """A read-only, selectable, borderless Entry."""
            e = tk.Entry(
                parent, font=font, width=width,
                fg=fg, bg=SURFACE, readonlybackground=SURFACE,
                relief="flat", bd=0, highlightthickness=0,
                state="normal",
            )
            e.insert(0, text)
            e.config(state="readonly")
            return e

        for pct, hex_color in results:
            row = tk.Frame(self._steps_inner, bg=SURFACE,
                           highlightthickness=1, highlightbackground=BORDER)
            row.pack(fill="x", pady=2)

            swatch = tk.Label(row, width=3, bg=hex_color, relief="flat")
            swatch.pack(side="left", fill="y", ipadx=1, padx=(8, 10), pady=6)

            _ro_entry(row, f"{pct:5.1f}%", 7, fg=TEXT_MUTED).pack(side="left")
            _ro_entry(row, hex_color.lstrip("#"), 7).pack(side="left", padx=8)
            try:
                r, g, b = _parse_hex(hex_color)
                _ro_entry(row, f"rgb({r:3d}, {g:3d}, {b:3d})", 18,
                          fg=TEXT_MUTED, font=FONT_SM).pack(side="left")
            except Exception:
                pass

    # ── preview strip ─────────────────────────────────────────────────────────

    def _draw_strip(self) -> None:
        c = self._strip_canvas
        c.delete("all")
        w = c.winfo_width()
        if w < 2 or len(self.gradient) < 2:
            return
        for col in range(w):
            pct = col * 100 / (w - 1)
            try:
                color = self.gradient.sample(pct)
                c.create_line(col, 0, col, STRIP_H, fill=color)
            except Exception:
                pass

    # ── full refresh ──────────────────────────────────────────────────────────

    def _refresh(self) -> None:
        self._draw_bar()
        self._draw_strip()
        self._rebuild_stops_panel()
        if self._active_tab.get() == "sample":
            self._refresh_sample()
        else:
            self._refresh_steps()


# ── public entry point ────────────────────────────────────────────────────────

def run_ui(gradient: Gradient | None = None) -> None:
    """Launch the interactive GUI (blocks until the window is closed)."""
    app = GradientApp(gradient)
    app.mainloop()


# ═══════════════════════════════════════════════════════════════════════════════
# Entry point
# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    run_ui()