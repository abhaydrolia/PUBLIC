# Frigate config

Optimized Frigate configuration for a Proxmox VM (Intel i7, 30 GB RAM, Google
Coral USB TPU) running Frigate 0.17.x with four Reolink cameras.

## Files
- `config.yml` — the Frigate config. No real secrets in it.
- `secrets.yaml.example` — template; copy to `/config/secrets.yaml` on the host
  and fill in real values (kept out of git via `.gitignore`).

## What changed vs. the original (and why)

| Area | Before | After |
|------|--------|-------|
| Secrets | MQTT/camera passwords + Gemini key in plaintext | Moved to `secrets.yaml`; key removed |
| go2rtc | Streams defined but cameras pulled cameras directly (extra connections, DTS errors) | Cameras consume the `127.0.0.1:8554` restream — each camera pulled once |
| go2rtc backyard | Pointed at the wrong IPs (`.249`/`.227`) | Uses the camera's real IP (`.183`) |
| Usernames | `admin` vs `admin2` mismatched between go2rtc and cameras | Made consistent per camera |
| LPR | `car` not in any `track` list, so plates never read | `car` added to `rdriveway` tracking |
| person `max_area` | `100000` filtered out close-up people | removed |
| `improve_contrast` | `'true'` (string) | `true` (bool) |
| Detect | No explicit fps; placeholder 1280x720 | `fps: 5`; TODO to match real substream size |

## Before this will fully work

1. **Rotate the leaked credentials** (MQTT password + the Gemini API key that
   was in the old config) and fill in `secrets.yaml`.
2. **rdriveway**: verify the real RTSP path (old one returned `404 Stream Not
   Found`) and confirm the camera has a stable static IP — it was also dropping
   offline (`No route to host` / `Connection refused`).
   ```bash
   docker exec -it frigate ffprobe -rtsp_transport tcp \
     "rtsp://admin:PASSWORD@192.168.1.233:554/h264Preview_01_main"
   ```
3. **Ollama (GenAI)**: must be running with `llama3.2-vision` pulled *before*
   Frigate starts, otherwise GenAI stays disabled for the whole session.
4. **Semantic search**: needs a one-time internet window to download the
   `jina-clip-v1` model from huggingface.co, or disable `semantic_search`.
