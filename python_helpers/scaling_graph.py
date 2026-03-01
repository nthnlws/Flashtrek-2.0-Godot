"""
Flashtrek Scaling Curve Visualizer
===================================
Visualizes three progression curves:
  1. System / Enemy Difficulty
  2. Player Ship Unlock Cost
  3. Player Stat Scaling

Toggle curve methods and tweak parameters live using the control panel.
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.widgets import RadioButtons, Slider, CheckButtons
from matplotlib.patches import FancyBboxPatch
import warnings
warnings.filterwarnings("ignore")

# ─────────────────────────────────────────────
#  CURVE FUNCTIONS
# ─────────────────────────────────────────────

def curve_power(t, min_v, max_v, exp):
    """Power curve: slow start, steep finish. Good for enemy difficulty."""
    return min_v + (max_v - min_v) * np.power(np.clip(t, 0, 1), exp)

def curve_log(t, min_v, max_v, strength):
    """Logarithmic: fast start, flattens out. Good for player stats (diminishing returns)."""
    return min_v + (max_v - min_v) * np.log1p(np.clip(t, 0, 1) * strength) / np.log1p(strength)

def curve_sigmoid(t, min_v, max_v, steepness, midpoint):
    """S-curve: slow → fast → slow. Good for unlock cost pacing."""
    k = steepness
    x0 = midpoint
    s = 1.0 / (1.0 + np.exp(-k * (np.clip(t, 0, 1) - x0)))
    s_min = 1.0 / (1.0 + np.exp(-k * (0.0 - x0)))
    s_max = 1.0 / (1.0 + np.exp(-k * (1.0 - x0)))
    s_norm = (s - s_min) / (s_max - s_min)
    return min_v + (max_v - min_v) * s_norm

def curve_linear(t, min_v, max_v):
    """Flat linear baseline."""
    return min_v + (max_v - min_v) * np.clip(t, 0, 1)

def curve_stepped(t, min_v, max_v, steps):
    """Hard-stepped progression. Simulates faction zone jumps."""
    n = max(2, int(steps))
    stepped_t = np.floor(np.clip(t, 0, 0.9999) * n) / (n - 1)
    return min_v + (max_v - min_v) * stepped_t

def curve_inv_power(t, min_v, max_v, exp):
    """Inverse power (root): fast early, slow late. Feels like player mastery curve."""
    return min_v + (max_v - min_v) * np.power(np.clip(t, 0, 1), 1.0 / max(0.1, exp))


# ─────────────────────────────────────────────
#  DEFAULT PARAMETERS  (edit these freely)
# ─────────────────────────────────────────────

DEFAULTS = {
    # ── Enemy / System Difficulty ────────────────────────────────────────
    "enemy_method":        "power",   # power | log | sigmoid | stepped | linear
    "enemy_min":           1.0,
    "enemy_max":           4.0,
    "enemy_exp":           1.5,       # used by power
    "enemy_log_strength":  9.0,       # used by log
    "enemy_sig_steep":     8.0,       # used by sigmoid
    "enemy_sig_mid":       0.6,       # used by sigmoid
    "enemy_steps":         5,         # used by stepped

    # ── Player Unlock Cost ───────────────────────────────────────────────
    "unlock_method":       "power",   # power | log | sigmoid | stepped | linear
    "unlock_min":          1.0,
    "unlock_max":          10.0,
    "unlock_exp":          2.0,
    "unlock_log_strength": 9.0,
    "unlock_sig_steep":    10.0,
    "unlock_sig_mid":      0.5,
    "unlock_steps":        6,

    # ── Player Stat Scaling ──────────────────────────────────────────────
    "player_method":       "inv_power",  # power | inv_power | log | sigmoid | stepped | linear
    "player_min":          1.0,
    "player_max":          4.0,
    "player_exp":          1.5,          # used by power & inv_power
    "player_log_strength": 9.0,
    "player_sig_steep":    8.0,
    "player_sig_mid":      0.4,
    "player_steps":        5,
}

METHODS_ENEMY  = ["power", "log", "sigmoid", "stepped", "linear"]
METHODS_UNLOCK = ["power", "log", "sigmoid", "stepped", "linear"]
METHODS_PLAYER = ["power", "inv_power", "log", "sigmoid", "stepped", "linear"]

# Galaxy layout for faction zone shading
FACTION_ZONES = [
    (0.0,  0.33, "#4488cc", "Federation",  0.08),
    (0.33, 0.66, "#44cc88", "Romulan",     0.06),
    (0.66, 1.0,  "#cc4444", "Klingon",     0.08),
]

NUM_POINTS = 400
T = np.linspace(0, 1, NUM_POINTS)


# ─────────────────────────────────────────────
#  COMPUTE HELPERS
# ─────────────────────────────────────────────

def compute_enemy(p):
    m = p["enemy_method"]
    if m == "power":    return curve_power(T, p["enemy_min"], p["enemy_max"], p["enemy_exp"])
    if m == "log":      return curve_log(T, p["enemy_min"], p["enemy_max"], p["enemy_log_strength"])
    if m == "sigmoid":  return curve_sigmoid(T, p["enemy_min"], p["enemy_max"], p["enemy_sig_steep"], p["enemy_sig_mid"])
    if m == "stepped":  return curve_stepped(T, p["enemy_min"], p["enemy_max"], p["enemy_steps"])
    return curve_linear(T, p["enemy_min"], p["enemy_max"])

def compute_unlock(p):
    m = p["unlock_method"]
    if m == "power":    return curve_power(T, p["unlock_min"], p["unlock_max"], p["unlock_exp"])
    if m == "log":      return curve_log(T, p["unlock_min"], p["unlock_max"], p["unlock_log_strength"])
    if m == "sigmoid":  return curve_sigmoid(T, p["unlock_min"], p["unlock_max"], p["unlock_sig_steep"], p["unlock_sig_mid"])
    if m == "stepped":  return curve_stepped(T, p["unlock_min"], p["unlock_max"], p["unlock_steps"])
    return curve_linear(T, p["unlock_min"], p["unlock_max"])

def compute_player(p):
    m = p["player_method"]
    if m == "power":     return curve_power(T, p["player_min"], p["player_max"], p["player_exp"])
    if m == "inv_power": return curve_inv_power(T, p["player_min"], p["player_max"], p["player_exp"])
    if m == "log":       return curve_log(T, p["player_min"], p["player_max"], p["player_log_strength"])
    if m == "sigmoid":   return curve_sigmoid(T, p["player_min"], p["player_max"], p["player_sig_steep"], p["player_sig_mid"])
    if m == "stepped":   return curve_stepped(T, p["player_min"], p["player_max"], p["player_steps"])
    return curve_linear(T, p["player_min"], p["player_max"])


# ─────────────────────────────────────────────
#  FIND CROSSOVER POINTS
# ─────────────────────────────────────────────

def find_crossovers(y1, y2):
    diff = y1 - y2
    crossovers = []
    for i in range(len(diff) - 1):
        if diff[i] * diff[i+1] < 0:
            # Linear interpolation
            frac = -diff[i] / (diff[i+1] - diff[i])
            tx = T[i] + frac * (T[i+1] - T[i])
            yx = y1[i] + frac * (y1[i+1] - y1[i])
            crossovers.append((tx, yx))
    return crossovers


# ─────────────────────────────────────────────
#  LAYOUT & FIGURE SETUP
# ─────────────────────────────────────────────

plt.style.use("dark_background")

DARK_BG    = "#0d1117"
PANEL_BG   = "#161b22"
ACCENT1    = "#58a6ff"   # blue  – enemy
ACCENT2    = "#3fb950"   # green – unlock
ACCENT3    = "#f78166"   # red   – player
GRID_COLOR = "#21262d"
TEXT_COLOR = "#e6edf3"
MID_COLOR  = "#8b949e"

fig = plt.figure(figsize=(18, 10), facecolor=DARK_BG)
fig.canvas.manager.set_window_title("Flashtrek Scaling Visualizer")

# Main plot area + comparison plot
gs_main = gridspec.GridSpec(
    2, 2,
    left=0.04, right=0.60,
    top=0.93, bottom=0.07,
    hspace=0.35, wspace=0.3
)
ax_main  = fig.add_subplot(gs_main[0, :])   # Combined overlay
ax_enemy = fig.add_subplot(gs_main[1, 0])   # Enemy detail
ax_play  = fig.add_subplot(gs_main[1, 1])   # Player vs enemy delta

# Right panel: controls
gs_ctrl = gridspec.GridSpec(
    1, 1,
    left=0.62, right=0.99,
    top=0.97, bottom=0.03
)
ax_ctrl = fig.add_subplot(gs_ctrl[0, 0])
ax_ctrl.set_facecolor(PANEL_BG)
ax_ctrl.set_xticks([])
ax_ctrl.set_yticks([])
for spine in ax_ctrl.spines.values():
    spine.set_edgecolor("#30363d")

for ax in [ax_main, ax_enemy, ax_play]:
    ax.set_facecolor(PANEL_BG)
    ax.tick_params(colors=MID_COLOR, labelsize=8)
    ax.xaxis.label.set_color(MID_COLOR)
    ax.yaxis.label.set_color(MID_COLOR)
    for spine in ax.spines.values():
        spine.set_edgecolor("#30363d")
    ax.grid(True, color=GRID_COLOR, linewidth=0.6, linestyle="--", alpha=0.7)

def shade_factions(ax, ymin, ymax):
    for (x0, x1, color, label, alpha) in FACTION_ZONES:
        ax.axvspan(x0, x1, color=color, alpha=alpha, zorder=0)
        ax.text((x0 + x1) / 2, ymax * 0.97, label,
                ha="center", va="top", fontsize=7, color=color,
                alpha=0.7, style="italic")

def add_faction_vlines(ax):
    for x in [0.333, 0.666]:
        ax.axvline(x, color="#30363d", linewidth=1.2, linestyle=":", zorder=1)


# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────

params = dict(DEFAULTS)

# Lines we'll update
line_enemy,  = ax_main.plot([], [], color=ACCENT1, lw=2.2, label="Enemy Difficulty", zorder=3)
line_unlock, = ax_main.plot([], [], color=ACCENT2, lw=2.2, label="Unlock Cost",      zorder=3, linestyle="--")
line_player, = ax_main.plot([], [], color=ACCENT3, lw=2.5, label="Player Stats",     zorder=3)

line_enemy_d,  = ax_enemy.plot([], [], color=ACCENT1, lw=2)
line_player_d, = ax_enemy.plot([], [], color=ACCENT3, lw=2, linestyle="--")

line_delta, = ax_play.plot([], [], color="#d2a8ff", lw=2)
ax_play.axhline(0, color=MID_COLOR, lw=0.8, linestyle=":")

crossover_scatter = ax_main.scatter([], [], color="yellow", s=80, zorder=5, marker="D",
                                    label="Crossover")

ax_main.set_title("Progression Overview — All Curves", color=TEXT_COLOR, fontsize=11,
                  pad=8, fontweight="bold")
ax_main.set_xlabel("Galaxy Progress (0 = start, 1 = deep Klingon)", fontsize=9)
ax_main.set_ylabel("Multiplier / Cost", fontsize=9)

ax_enemy.set_title("Enemy vs Player Stat", color=TEXT_COLOR, fontsize=9, pad=5)
ax_enemy.set_xlabel("Progress", fontsize=8)

ax_play.set_title("Player Advantage (player − enemy)", color=TEXT_COLOR, fontsize=9, pad=5)
ax_play.set_xlabel("Progress", fontsize=8)

legend = ax_main.legend(loc="upper left", facecolor=PANEL_BG, edgecolor="#30363d",
                         labelcolor=TEXT_COLOR, fontsize=8)


# ─────────────────────────────────────────────
#  CONTROL WIDGETS
#  (positioned manually in figure coords)
# ─────────────────────────────────────────────

ctrl_x = 0.635   # left edge of controls
ctrl_w = 0.34

def make_radio(fig, rect, labels, active_label, color):
    ax = fig.add_axes(rect, facecolor="#0d1117")
    r = RadioButtons(ax, labels, active=labels.index(active_label) if active_label in labels else 0,
                     activecolor=color)
    for lbl in r.labels:
        lbl.set_color(TEXT_COLOR)
        lbl.set_fontsize(8)
    return r, ax

def make_slider(fig, rect, label, vmin, vmax, valinit, color, valstep=None):
    ax = fig.add_axes(rect, facecolor=DARK_BG)
    kw = dict(valmin=vmin, valmax=vmax, valinit=valinit,
              color=color, track_color="#21262d")
    if valstep: kw["valstep"] = valstep
    s = Slider(ax, label, **kw)
    s.label.set_color(MID_COLOR)
    s.label.set_fontsize(7.5)
    s.valtext.set_color(TEXT_COLOR)
    s.valtext.set_fontsize(7.5)
    return s

# ── Section headers ──────────────────────────
section_style = dict(transform=fig.transFigure, fontsize=9, fontweight="bold",
                     ha="left", va="center")

# ENEMY section
fig.text(ctrl_x, 0.935, "① ENEMY DIFFICULTY", color=ACCENT1, **section_style)
r_enemy, _ = make_radio(fig, [ctrl_x, 0.845, 0.16, 0.085],
                        METHODS_ENEMY, params["enemy_method"], ACCENT1)
s_enemy_min  = make_slider(fig, [ctrl_x+0.17, 0.905, ctrl_w-0.19, 0.018], "Min",  0.5, 3.0, params["enemy_min"],  ACCENT1)
s_enemy_max  = make_slider(fig, [ctrl_x+0.17, 0.883, ctrl_w-0.19, 0.018], "Max",  1.5, 8.0, params["enemy_max"],  ACCENT1)
s_enemy_exp  = make_slider(fig, [ctrl_x+0.17, 0.861, ctrl_w-0.19, 0.018], "Exp",  0.5, 4.0, params["enemy_exp"],  ACCENT1)
s_enemy_log  = make_slider(fig, [ctrl_x+0.17, 0.839, ctrl_w-0.19, 0.018], "LogK", 1.0,20.0, params["enemy_log_strength"], ACCENT1)
s_enemy_smid = make_slider(fig, [ctrl_x+0.17, 0.817, ctrl_w-0.19, 0.018], "SigM", 0.1, 0.9, params["enemy_sig_mid"],   ACCENT1)
s_enemy_sst  = make_slider(fig, [ctrl_x+0.17, 0.795, ctrl_w-0.19, 0.018], "SigK", 2.0,20.0, params["enemy_sig_steep"], ACCENT1)
s_enemy_st   = make_slider(fig, [ctrl_x+0.17, 0.773, ctrl_w-0.19, 0.018], "Steps",2.0,12.0, params["enemy_steps"],     ACCENT1, valstep=1)

# UNLOCK section
fig.text(ctrl_x, 0.745, "② UNLOCK COST", color=ACCENT2, **section_style)
r_unlock, _ = make_radio(fig, [ctrl_x, 0.655, 0.16, 0.085],
                         METHODS_UNLOCK, params["unlock_method"], ACCENT2)
s_unlock_min  = make_slider(fig, [ctrl_x+0.17, 0.715, ctrl_w-0.19, 0.018], "Min",  0.5,  3.0, params["unlock_min"],  ACCENT2)
s_unlock_max  = make_slider(fig, [ctrl_x+0.17, 0.693, ctrl_w-0.19, 0.018], "Max",  2.0, 20.0, params["unlock_max"],  ACCENT2)
s_unlock_exp  = make_slider(fig, [ctrl_x+0.17, 0.671, ctrl_w-0.19, 0.018], "Exp",  0.5,  4.0, params["unlock_exp"],  ACCENT2)
s_unlock_log  = make_slider(fig, [ctrl_x+0.17, 0.649, ctrl_w-0.19, 0.018], "LogK", 1.0, 20.0, params["unlock_log_strength"], ACCENT2)
s_unlock_smid = make_slider(fig, [ctrl_x+0.17, 0.627, ctrl_w-0.19, 0.018], "SigM", 0.1,  0.9, params["unlock_sig_mid"],   ACCENT2)
s_unlock_sst  = make_slider(fig, [ctrl_x+0.17, 0.605, ctrl_w-0.19, 0.018], "SigK", 2.0, 20.0, params["unlock_sig_steep"], ACCENT2)
s_unlock_st   = make_slider(fig, [ctrl_x+0.17, 0.583, ctrl_w-0.19, 0.018], "Steps",2.0, 12.0, params["unlock_steps"],     ACCENT2, valstep=1)

# PLAYER section
fig.text(ctrl_x, 0.555, "③ PLAYER STAT SCALING", color=ACCENT3, **section_style)
r_player, _ = make_radio(fig, [ctrl_x, 0.455, 0.16, 0.095],
                         METHODS_PLAYER, params["player_method"], ACCENT3)
s_player_min  = make_slider(fig, [ctrl_x+0.17, 0.525, ctrl_w-0.19, 0.018], "Min",  0.5,  3.0, params["player_min"],  ACCENT3)
s_player_max  = make_slider(fig, [ctrl_x+0.17, 0.503, ctrl_w-0.19, 0.018], "Max",  1.5,  8.0, params["player_max"],  ACCENT3)
s_player_exp  = make_slider(fig, [ctrl_x+0.17, 0.481, ctrl_w-0.19, 0.018], "Exp",  0.5,  4.0, params["player_exp"],  ACCENT3)
s_player_log  = make_slider(fig, [ctrl_x+0.17, 0.459, ctrl_w-0.19, 0.018], "LogK", 1.0, 20.0, params["player_log_strength"], ACCENT3)
s_player_smid = make_slider(fig, [ctrl_x+0.17, 0.437, ctrl_w-0.19, 0.018], "SigM", 0.1,  0.9, params["player_sig_mid"],   ACCENT3)
s_player_sst  = make_slider(fig, [ctrl_x+0.17, 0.415, ctrl_w-0.19, 0.018], "SigK", 2.0, 20.0, params["player_sig_steep"], ACCENT3)
s_player_st   = make_slider(fig, [ctrl_x+0.17, 0.393, ctrl_w-0.19, 0.018], "Steps",2.0, 12.0, params["player_steps"],     ACCENT3, valstep=1)

# Info box
info_ax = fig.add_axes([ctrl_x, 0.07, ctrl_w, 0.30], facecolor="#0d1117")
info_ax.set_xticks([]); info_ax.set_yticks([])
for sp in info_ax.spines.values(): sp.set_edgecolor("#30363d")
info_text = info_ax.text(0.05, 0.95, "", transform=info_ax.transAxes,
                          color=TEXT_COLOR, fontsize=7.5, va="top", fontfamily="monospace",
                          linespacing=1.6)

fig.text(ctrl_x, 0.375, "📊  LIVE STATS", color=MID_COLOR,
         transform=fig.transFigure, fontsize=8.5, fontweight="bold")


# ─────────────────────────────────────────────
#  UPDATE FUNCTION
# ─────────────────────────────────────────────

def update(_=None):
    # Read all widget values
    params["enemy_method"]       = r_enemy.value_selected
    params["enemy_min"]          = s_enemy_min.val
    params["enemy_max"]          = s_enemy_max.val
    params["enemy_exp"]          = s_enemy_exp.val
    params["enemy_log_strength"] = s_enemy_log.val
    params["enemy_sig_mid"]      = s_enemy_smid.val
    params["enemy_sig_steep"]    = s_enemy_sst.val
    params["enemy_steps"]        = int(s_enemy_st.val)

    params["unlock_method"]       = r_unlock.value_selected
    params["unlock_min"]          = s_unlock_min.val
    params["unlock_max"]          = s_unlock_max.val
    params["unlock_exp"]          = s_unlock_exp.val
    params["unlock_log_strength"] = s_unlock_log.val
    params["unlock_sig_mid"]      = s_unlock_smid.val
    params["unlock_sig_steep"]    = s_unlock_sst.val
    params["unlock_steps"]        = int(s_unlock_st.val)

    params["player_method"]       = r_player.value_selected
    params["player_min"]          = s_player_min.val
    params["player_max"]          = s_player_max.val
    params["player_exp"]          = s_player_exp.val
    params["player_log_strength"] = s_player_log.val
    params["player_sig_mid"]      = s_player_smid.val
    params["player_sig_steep"]    = s_player_sst.val
    params["player_steps"]        = int(s_player_st.val)

    ye = compute_enemy(params)
    yu = compute_unlock(params)
    yp = compute_player(params)

    # Normalize unlock to enemy range for overlay comparison
    e_range = params["enemy_max"] - params["enemy_min"]
    u_range = params["unlock_max"] - params["unlock_min"]
    yu_norm = params["enemy_min"] + (yu - params["unlock_min"]) / max(u_range, 0.01) * e_range

    # ── Main plot ────────────────────────────────────────────────────────
    ax_main.cla()
    ax_main.set_facecolor(PANEL_BG)
    ax_main.grid(True, color=GRID_COLOR, linewidth=0.6, linestyle="--", alpha=0.7)

    ymax_main = max(ye.max(), yp.max(), yu_norm.max()) * 1.12
    shade_factions(ax_main, 0, ymax_main)
    add_faction_vlines(ax_main)

    ax_main.plot(T, ye,      color=ACCENT1, lw=2.2, label=f"Enemy Difficulty [{params['enemy_method']}]", zorder=3)
    ax_main.plot(T, yu_norm, color=ACCENT2, lw=2.0, label=f"Unlock Cost (scaled) [{params['unlock_method']}]",
                 linestyle="--", zorder=3)
    ax_main.plot(T, yp,      color=ACCENT3, lw=2.5, label=f"Player Stats [{params['player_method']}]", zorder=3)

    # Crossover markers: player vs enemy
    crossovers = find_crossovers(yp, ye)
    for (cx, cy) in crossovers:
        ax_main.scatter([cx], [cy], color="yellow", s=90, zorder=5, marker="D")
        ax_main.annotate(f"⚡ t={cx:.2f}", (cx, cy),
                         xytext=(cx + 0.03, cy + ymax_main * 0.04),
                         color="yellow", fontsize=7.5,
                         arrowprops=dict(arrowstyle="->", color="yellow", lw=0.8))

    ax_main.set_ylim(0, ymax_main)
    ax_main.set_xlim(0, 1)
    ax_main.set_title("Progression Overview — All Curves", color=TEXT_COLOR, fontsize=11,
                       pad=8, fontweight="bold")
    ax_main.set_xlabel("Galaxy Progress", fontsize=9, color=MID_COLOR)
    ax_main.set_ylabel("Multiplier", fontsize=9, color=MID_COLOR)
    ax_main.tick_params(colors=MID_COLOR, labelsize=8)
    for sp in ax_main.spines.values(): sp.set_edgecolor("#30363d")
    ax_main.legend(loc="upper left", facecolor=PANEL_BG, edgecolor="#30363d",
                   labelcolor=TEXT_COLOR, fontsize=8)

    # ── Enemy detail plot ────────────────────────────────────────────────
    ax_enemy.cla()
    ax_enemy.set_facecolor(PANEL_BG)
    ax_enemy.grid(True, color=GRID_COLOR, linewidth=0.6, linestyle="--", alpha=0.7)
    for sp in ax_enemy.spines.values(): sp.set_edgecolor("#30363d")

    ymax_d = max(ye.max(), yp.max()) * 1.12
    shade_factions(ax_enemy, 0, ymax_d)
    add_faction_vlines(ax_enemy)
    ax_enemy.plot(T, ye, color=ACCENT1, lw=2,   label="Enemy")
    ax_enemy.plot(T, yp, color=ACCENT3, lw=2,   label="Player", linestyle="--")
    ax_enemy.fill_between(T, ye, yp,
                           where=(yp >= ye), color=ACCENT3, alpha=0.15, label="Player ahead")
    ax_enemy.fill_between(T, ye, yp,
                           where=(yp < ye),  color=ACCENT1, alpha=0.15, label="Enemy ahead")
    ax_enemy.set_ylim(0, ymax_d)
    ax_enemy.set_xlim(0, 1)
    ax_enemy.set_title("Enemy vs Player Stat", color=TEXT_COLOR, fontsize=9, pad=5)
    ax_enemy.set_xlabel("Progress", fontsize=8, color=MID_COLOR)
    ax_enemy.tick_params(colors=MID_COLOR, labelsize=7)
    ax_enemy.legend(facecolor=PANEL_BG, edgecolor="#30363d", labelcolor=TEXT_COLOR, fontsize=7)

    # ── Delta plot ────────────────────────────────────────────────────────
    ax_play.cla()
    ax_play.set_facecolor(PANEL_BG)
    ax_play.grid(True, color=GRID_COLOR, linewidth=0.6, linestyle="--", alpha=0.7)
    for sp in ax_play.spines.values(): sp.set_edgecolor("#30363d")

    delta = yp - ye
    add_faction_vlines(ax_play)
    ax_play.axhline(0, color=MID_COLOR, lw=0.8, linestyle=":")
    ax_play.plot(T, delta, color="#d2a8ff", lw=2)
    ax_play.fill_between(T, delta, 0, where=(delta >= 0), color="#d2a8ff", alpha=0.2, label="Player ahead")
    ax_play.fill_between(T, delta, 0, where=(delta <  0), color=ACCENT1,   alpha=0.2, label="Enemy ahead")
    ax_play.set_xlim(0, 1)
    ax_play.set_title("Player Advantage (player − enemy)", color=TEXT_COLOR, fontsize=9, pad=5)
    ax_play.set_xlabel("Progress", fontsize=8, color=MID_COLOR)
    ax_play.tick_params(colors=MID_COLOR, labelsize=7)
    ax_play.legend(facecolor=PANEL_BG, edgecolor="#30363d", labelcolor=TEXT_COLOR, fontsize=7)

    # ── Info panel ────────────────────────────────────────────────────────
    # Sample values at key points
    sample_t = [0.0, 0.167, 0.333, 0.5, 0.666, 0.833, 1.0]
    labels_t  = ["Start", "Fed½", "FedEnd", "Rom½", "RomEnd", "Kling½", "End"]

    lines = ["  t      Enemy  Player  Unlock  Δ(P-E)", "  " + "─"*42]
    for ti, lbl in zip(sample_t, labels_t):
        idx = int(ti * (NUM_POINTS - 1))
        e_v = ye[idx]; p_v = yp[idx]; u_v = yu[idx]
        d_v = p_v - e_v
        sign = "▲" if d_v >= 0 else "▼"
        lines.append(f"  {lbl:<7} {e_v:5.2f}  {p_v:5.2f}  {u_v:6.2f}  {sign}{abs(d_v):.2f}")

    crossover_t_strs = [f"t={cx:.3f}" for (cx, _) in crossovers]
    lines += ["", f"  Crossovers: {', '.join(crossover_t_strs) if crossovers else 'none'}"]

    endgame_advantage = yp[-1] - ye[-1]
    lines += [f"  Endgame advantage: {endgame_advantage:+.3f}"]

    info_text.set_text("\n".join(lines))

    fig.canvas.draw_idle()


# ─────────────────────────────────────────────
#  WIRE UP CALLBACKS
# ─────────────────────────────────────────────

all_sliders = [
    s_enemy_min, s_enemy_max, s_enemy_exp, s_enemy_log, s_enemy_smid, s_enemy_sst, s_enemy_st,
    s_unlock_min, s_unlock_max, s_unlock_exp, s_unlock_log, s_unlock_smid, s_unlock_sst, s_unlock_st,
    s_player_min, s_player_max, s_player_exp, s_player_log, s_player_smid, s_player_sst, s_player_st,
]
for s in all_sliders:
    s.on_changed(update)

r_enemy.on_clicked(update)
r_unlock.on_clicked(update)
r_player.on_clicked(update)

# Initial draw
update()

plt.show()
