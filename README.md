#Simple app: Flask service with / and /healthz.
Dockerfile: Multi‑stage (builder → runtime), small base (slim), no cache, minimal layers.
Multi-stage build: Wheels built in builder; final image contains only runtime deps + app.
docker-compose: Port mapping, .env injection, restart policy, security options.
Healthcheck: Implemented in both Dockerfile and Compose using Python stdlib—no extra packages.
.env handling: Read via Compose (env_file) and used by the app (os.getenv).
Non-root user: UID/GID 10001; USER set in Dockerfile; Compose enforces too.
Optimized size: Slim base, no curl/wget, wheel-based install, PIP_NO_CACHE_DIR=1.

pip wheel && \
    pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt
Reads all dependencies from requirements.txt
Builds wheels for every dependency
Stores all generated wheels into /wheels
--no-cache-dir ensures pip does NOT use previously cached packages; it builds everything fresh.

the result:
You end up with a directory /wheels containing wheel files for:

All packages listed in requirements.txt
Any transitive dependencies those packages need

These wheels can later be used for offline installation using:
This is commonly used to:
✔ Build wheels in a Docker build step
So image builds are reproducible and faster.
✔ Prepare offline installation bundles
Useful when deploying to air‑gapped or restricted environments.
✔ Create precompiled wheels to avoid slow builds
This helps avoid compiling dependencies repeatedly.

*****************************************
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1
This sets three environment variables. Each one changes how Python or pip behaves.
✅ 1. PYTHONDONTWRITEBYTECODE=1
Purpose:
Prevents Python from creating .pyc files (compiled bytecode).
Effect:

Python normally creates files like:
__pycache__/module.cpython-310.pyc


These are not needed inside Docker images.
Disabling them:

Reduces image size
Makes file system cleaner



Why useful in Docker?
Containers should be lightweight and immutable. .pyc files are unnecessary and just add extra clutter.
✅ 2. PYTHONUNBUFFERED=1
Purpose:
Forces Python to flush output immediately — no buffering.
Effect:

print() output shows up instantly in Docker logs.
Without this, Python may buffer output, and logs appear late.

Why useful?
When running apps in Docker (like Django, FastAPI, Flask), real‑time logs are important for debugging and monitoring.
✅ 3. PIP_NO_CACHE_DIR=1
Purpose:
Tells pip not to store its download cache.
Effect:

Prevents saving cached packages in:
~/.cache/pip


Keeps Docker image smaller.

Why useful?
Every MB counts in container images. The pip cache can easily add 50–200 MB.
