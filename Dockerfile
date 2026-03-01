FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Build wheels for runtime-only installation (no compilers in final image)
COPY app/requirements.txt .
RUN python -m pip install --upgrade pip wheel && \
    pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt


##########
# Runtime
##########
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create non-root user/group
ARG USER=appuser
ARG UID=10001
ARG GID=10001
RUN addgroup --system --gid ${GID} ${USER} && \
    adduser --system --uid ${UID} --ingroup ${USER} --home /home/${USER} ${USER}

WORKDIR /app
# Install runtime deps from wheels (keeps image small)
COPY --from=builder /wheels /wheels
COPY app/requirements.txt .
RUN python -m pip install --no-cache-dir --find-links=/wheels -r requirements.txt && \
    rm -rf /wheels

# Copy source
COPY app/ /app/

# Make sure files are owned by non-root user
RUN chown -R ${UID}:${GID} /app

# Expose service port
EXPOSE 8000

# Healthcheck without installing curl/wget (keeps image small)
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import os,urllib.request,sys;port=os.getenv('PORT','8000'); \
  sys.exit(0) if urllib.request.urlopen(f'http://127.0.0.1:{port}/healthz',timeout=2).getcode()==200 else sys.exit(1)"

# Drop privileges
USER ${UID}:${GID}

# Default port (overridable via env)
ENV PORT=8000

# Run with Gunicorn in production
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT} --workers 2 --threads 4 --timeout 30 app:app"]