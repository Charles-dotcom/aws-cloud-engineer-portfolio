# =============================================================================
# Multi-stage Dockerfile for Cloud Engineer Portfolio Demo App
# Small, secure, production-ready image
# =============================================================================

# ---- Builder Stage ----
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies if needed (kept minimal)
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ---- Final Stage ----
FROM python:3.12-slim

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /home/appuser/.local
ENV PATH=/home/appuser/.local/bin:$PATH

# Copy application code
COPY --chown=appuser:appuser app.py .

USER appuser

EXPOSE 8080

# Use gunicorn for production WSGI server
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "4", "app:app"]
