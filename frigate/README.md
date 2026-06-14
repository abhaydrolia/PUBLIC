# Frigate config

Optimized Frigate configuration for a Proxmox VM (Intel i7, 30 GB RAM, Google
Coral USB TPU) running Frigate 0.17.x with four Reolink cameras.

## Files
- `config.yml` — the Frigate config. No real secrets in it.
- `frigate.env.example` — template for the environment variables Frigate
  substitutes into the `{FRIGATE_*}` placeholders. Copy to `frigate.env`, fill
  in real values, and pass it to the container (`--env-file` / compose
  `env_file:`). Kept out of git via `.gitignore`.

## How secrets work in Frigate (important)
Frigate does **not** read a `secrets.yaml` file. It replaces `{FRIGATE_*}`
placeholders in the config with **environment variables** of the same name.
So `password: "{FRIGATE_MQTT_PASSWORD}"` requires an env var
`FRIGATE_MQTT_PASSWORD` on the container. Missing vars crash startup with
`KeyError` / `Invalid substitution found`.

## What changed vs. the original (and why)

| Area | Before | After |
|------|--------|-------|
| Secrets | MQTT/camera passwords + Gemini key in plaintext | Moved to `{FRIGATE_*}` env-var substitution; key removed |
| go2rtc | Streams defined but cameras pulled cameras directly (extra connections, DTS errors) | Cameras consume the `127.0.0.1:8554` restream — each camera pulled once |
| go2rtc backyard | Pointed at the wrong IPs (`.249`/`.227`) | Uses the camera's real IP (`.183`) |
| Usernames | `admin` vs `admin2` mismatched between go2rtc and cameras | Made consistent per camera |
| LPR | `car` not in any `track` list, so plates never read | `car` added to `rdriveway` tracking |
| person `max_area` | `100000` filtered out close-up people | removed |
| `improve_contrast` | `'true'` (string) | `true` (bool) |
| Detect | No explicit fps; placeholder 1280x720 | `fps: 5`; sizes set to each camera's real substream resolution (ffprobe) |
| rdriveway path | `h265Preview_01_main` → `404 Stream Not Found` | `h264Preview_01_main` (Reolink serves HEVC 4K on that path) |
| GenAI IP | `192.168.1.162` (stale Ethernet IP) | `192.168.1.62` (Mac mini's current Wi-Fi IP) |

## Confirmed camera streams (ffprobe)

| Camera | IP | Record (main) | Detect (sub) |
|--------|----|---------------|--------------|
| rdriveway | .233 | `h264Preview_01_main` — HEVC 3840x2160 | `h264Preview_01_sub` — 640x360 |
| rdoorbell | .205 | `h265Preview_01_main` | `h264Preview_01_sub` — 640x480 |
| backyard  | .183 | `h265Preview_01_main` | `h264Preview_01_sub` — 640x360 |
| dining    | .249 | `h265Preview_01_main` | `h264Preview_01_sub` — 640x360 |

## Before this will fully work

1. **Rotate the leaked credentials** (MQTT password + the Gemini API key that
   was in the old config) and set the env vars in `frigate.env`. Camera
   usernames confirmed: rdriveway/rdoorbell/backyard use `admin`, dining uses
   `admin2`. Put real passwords only in `frigate.env` on the host — URL-encode
   any `@`→`%40` and `#`→`%23` in the camera-password values (they go inside
   RTSP URLs); the MQTT password is raw.
2. **Pin the Mac mini's IP** — it runs Ollama and moved Ethernet→Wi-Fi, changing
   `.162`→`.62`. Set a UniFi Fixed-IP reservation on its Wi-Fi MAC so GenAI's
   `base_url` (`192.168.1.62`) can't drift again.
3. **Ollama (GenAI)**: managed by a launchd agent (`com.ollama.serve`,
   `OLLAMA_HOST=0.0.0.0:11434`) so it auto-starts and is reachable on the LAN.
   Must be up *before* Frigate starts, else GenAI stays disabled until restart.
4. **Semantic search**: downloads `jina-clip-v1` from huggingface.co on first
   run — the Frigate host's internet was being blocked by UniFi (now resolved);
   keep that host allowed out, or disable `semantic_search`.
5. **Reserve camera IPs too** — rdriveway (`.233`) was dropping offline; give all
   four cameras DHCP reservations so paths/IPs stay stable.
