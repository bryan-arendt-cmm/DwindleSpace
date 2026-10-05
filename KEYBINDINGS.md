# Keybindings (bare `cmd` scheme)

Personal setup notes for running DwindleSpace with Hyprland/Omarchy-style muscle
memory on macOS, where `cmd` alone plays the role of Hyprland's `SUPER`.

Live config: `~/.aerospace.toml`. Edits apply on save (`auto-reload-config = true`),
except `after-startup-command`, which needs an AeroSpace restart.

## Bindings

### Focus / move

| Keys | Command |
| --- | --- |
| `cmd+←↓↑→` | `focus left/down/up/right` |
| `cmd+shift+←↓↑→` | `move left/down/up/right` |

### Workspaces

| Keys | Command |
| --- | --- |
| `cmd+1`…`cmd+9` | `workspace 1`…`9` |
| `cmd+shift+1`…`cmd+shift+9` | `move-node-to-workspace N --focus-follows-window` |
| ``cmd+` `` | `workspace-back-and-forth` |

### Monitors

| Keys | Command |
| --- | --- |
| `cmd+,` | `move-workspace-to-monitor --wrap-around prev` |
| `cmd+.` | `move-workspace-to-monitor --wrap-around next` |

`move-workspace-to-monitor` fails for any workspace pinned with
`workspace-to-monitor-force-assignment`. Pinning and moving are mutually exclusive.

### Window ops

| Keys | Command |
| --- | --- |
| `cmd+f` | `fullscreen` |
| `cmd+shift+f` | `layout floating tiling` |
| `cmd+q` | `close` |
| `cmd+r` | `flatten-workspace-tree` (reset layout) |
| `cmd+e` | `layout tiles horizontal vertical` |
| `cmd+a` | `layout accordion horizontal vertical` |
| `cmd+-` / `cmd+=` | `resize smart -50` / `+50` |
| `cmd+enter` | new WezTerm window |
| `cmd+shift+r` | `reload-config` |

## How conflicts resolve

AeroSpace registers every binding as a global Carbon hotkey via
`RegisterEventHotKey` (`HotKeysController.swift:60`, through the HotKey package).
A registered hotkey intercepts the combo at the event dispatcher, before the
focused app's menu key equivalents or responder chain. Bindings are global and
unconditional — there is no per-app exemption.

Precedence, highest first:

1. macOS system symbolic hotkeys (screenshots, Spotlight, Mission Control)
2. Carbon global hotkeys (AeroSpace, Raycast, Alfred, skhd)
3. Application shortcuts

So: **against an app, AeroSpace wins. Against a system shortcut, macOS wins.**

### Silent failure

If a combo is already held by another process, `RegisterEventHotKey` returns an
error and HotKey's registration path is:

```swift
guard registerError == noErr, eventHotKey != nil else {
    return
}
```

No error, no log, no tray warning. The binding simply does nothing. AeroSpace does
not check the result either. See `docs/guide.adoc` — "Common pitfall: keyboard keys
handling".

Consequence: `aerospace config --all-keys` counts bindings **parsed from the
config**, not hotkeys successfully **registered** with the OS. A combo lost to
Raycast or macOS looks identical to a working one from the CLI. `trigger-binding`
invokes the command directly and bypasses the keyboard, so it cannot detect this
either. Pressing the key is the only real test.

## Conflicts to clear manually

### Must unbind in System Settings

System shortcuts outrank AeroSpace. Until these are disabled, the AeroSpace
binding never fires.

**Keyboard → Keyboard Shortcuts → Screenshots**

- `cmd+shift+3` — save picture of screen as file
- `cmd+shift+4` — save picture of selected area as file
- `cmd+shift+5` — screenshot and recording options

**Keyboard → Keyboard Shortcuts → Keyboard**

- ``cmd+` `` — "Move focus to next window"

Also check Raycast (or Alfred/Hammerspoon/skhd) for overlapping global hotkeys —
those losses are silent.

### Cannot be unbound

- `cmd+tab` — the App Switcher has no System Settings entry and is hardcoded.
  This is why ``cmd+` `` is used for `workspace-back-and-forth`. Only
  Karabiner-Elements can reclaim it.

### Lost everywhere, no setting to restore

AeroSpace wins these outright.

| Key | Given up |
| --- | --- |
| `cmd+1`…`9` | Browser tabs, Finder view modes, Slack/Teams sections |
| `cmd+←/→` | Start/end of line, in every text field |
| `cmd+↑/↓` | Document top/bottom; Finder enclosing folder / open |
| `cmd+shift+←→↑↓` | Select to line/document start/end |
| `cmd+a` | Select All |
| `cmd+q` | Quit application |
| `cmd+f` | Find |
| `cmd+r` | Reload |
| `cmd+,` | Settings, in every app |
| `cmd+.` | Cancel |
| `cmd+-` / `cmd+=` | Zoom out / in |
| `cmd+e` | Use Selection for Find |
| `cmd+enter` | Open in new tab from the address bar |
| `cmd+shift+f` | Find in Files (VS Code) |
| `cmd+shift+r` | Hard reload |

Expect `cmd+a`, `cmd+q`, `cmd+←/→` (with their shift variants) and `cmd+,` to bite
hardest. Moving any single one to `cmd+shift+<letter>` stays within the no-`cmd+alt`
rule.

## Why not other modifiers

- `cmd+alt` — safe (only `cmd+opt+←/→` browser tab cycling and `cmd+opt+↑` in
  Finder collide), but rejected in favour of bare `cmd`.
- `alt` alone — collides with word-wise cursor movement in text fields.
- `ctrl` — collides with Mission Control.
- Hyper key (Caps Lock → `ctrl+alt+cmd+shift` via Karabiner-Elements) — zero
  collisions, but needs a third-party tool.

There is no free single modifier for arrow keys on macOS, which is why upstream's
default config uses `hjkl`.
