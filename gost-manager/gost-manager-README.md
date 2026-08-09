# GOST Manager

A small interactive helper for running a [GOST](https://github.com/go-gost/gost) SOCKS5 proxy chain on a local port: frees the port if something else is holding it, starts GOST from a pasted initiator command, confirms the listener came up, and optionally runs a live connectivity test through it.

By **Daniel Murimi Njiraini**

## Why

Starting a GOST tunnel manually usually means three separate steps done by hand: checking whether the target port is already in use, killing whatever's squatting on it, then starting GOST and eyeballing `ss`/`curl` output to confirm it actually came up. This wraps all three into one guided run.

## What it does

1. **Port check** — prompts for a local port (default `8080`), lists any process bound to it via `lsof`, and offers to kill it
2. **Free-port confirmation** — re-checks with `ss` and bails out with a warning if the port is still occupied
3. **Start GOST** — kills any existing `gost` process, then prompts you to paste a GOST initiator command (e.g. `gost -L=socks5://127.0.0.1:8080 -F=socks5://user:pass@host:port`) and launches it in the background via `nohup`
4. **Listener check** — confirms GOST is actually listening on the chosen port
5. **Optional SOCKS5 test** — runs `curl --socks5-hostname` through the tunnel to `ifconfig.me`; if it fails once, restarts GOST and retries before printing `gost.log` on a second failure

## Requirements

- `gost` binary available on `$PATH` (not distributed via apt — install from the [GOST releases page](https://github.com/go-gost/gost/releases) or your own build)
- `lsof`, `iproute2` (for `ss`), `curl`, `sudo`

## Installation

```bash
sudo dpkg -i gost-manager.sh_<version>_all.deb
sudo apt --fix-broken install   # only if apt reports missing deps
```

### Uninstall

```bash
sudo dpkg -r gost-manager.sh
```

## Usage

```bash
gost-manager.sh
```

Follow the prompts:

```
Enter proxy port to check [8080]:
Kill these processes? (y/n):
Paste GOST initiator command:
Run SOCKS5 test? (y/n):
```

A log of the running GOST process is written to `gost.log` in the current working directory — check it if a connectivity test fails twice.

## Security notes

- The script pastes and executes whatever command you give it via `bash -c`, including any embedded proxy credentials — don't run it with initiator commands from untrusted sources.
- It calls `sudo` for port inspection and process killing; review the source before running if you're not the one who wrote it.

## Building from source

```bash
dpkg-deb --build --root-owner-group <package-root-dir> gost-manager.sh_<version>_all.deb
```

Where `<package-root-dir>` contains `DEBIAN/control` plus the `usr/...` tree matching what's installed (`usr/bin/gost-manager.sh`, desktop entry, icon, copyright).

## Project Structure

```
.
├── gost-manager.sh   # the script (installed to /usr/bin/gost-manager.sh)
├── DEBIAN/control     # package metadata
└── README.md
```

## License

MIT — see `usr/share/doc/gost-manager.sh/copyright` inside the built package.

## Author

Daniel Murimi Njiraini ("Dan M.Njrn.")
