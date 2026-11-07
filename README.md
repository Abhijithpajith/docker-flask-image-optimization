# Flask App – Docker Image Optimization

Containerized a Python Flask API twice — once with a basic Dockerfile and once with a production-grade Dockerfile — to compare image size, security, and best practices.

**Result: image size reduced from 1.63 GB to 187 MB (88.5% smaller), running as a non-root user with a health check.**

## Project Structure

```
project1-dockerfile/
├── app/
│   ├── app.py              # Flask API with / and /health routes
│   └── requirements.txt    # flask, gunicorn
├── Dockerfile.basic        # Beginner version (for comparison)
├── Dockerfile              # Optimized production version
├── .dockerignore
└── README.md
```

## Results

| | Basic | Optimized |
|---|---|---|
| Base image | `python:3.12` | `python:3.12-slim` |
| Build | Single stage | Multi-stage |
| Image size (disk) | 1.63 GB | **187 MB** |
| Download size (compressed) | 419 MB | **45.4 MB** |
| Runs as | root | `appuser` (non-root) |
| Web server | Flask dev server | Gunicorn (production server) |
| Health check | No | Yes |

**Size reduced by 88.5%** (download size reduced by 89%).

## How to Run

```bash
# Basic version
docker build -f Dockerfile.basic -t flask-basic .
docker run -d -p 5000:5000 --name basic flask-basic

# Optimized version
docker build -t flask-optimized .
docker run -d -p 5000:5000 --name optimized flask-optimized

# Test
curl localhost:5000            # {"message":"Hello from Docker!"}
curl localhost:5000/health     # {"status":"ok"}
docker ps                      # STATUS shows (healthy)
docker exec optimized whoami   # appuser

# Compare sizes
docker images | grep flask

# Clean up
docker rm -f basic optimized
```

## Optimizations Explained

- **Slim base image** – `python:3.12-slim` removes compilers, docs and extra system libraries that the app never uses. This gave the biggest size reduction.
- **Multi-stage build** – dependencies are installed in a `builder` stage, and only the installed packages are copied into the final image with `COPY --from=builder`. Build leftovers never reach the final image.
- **`--no-cache-dir`** – pip does not keep its download cache inside the image.
- **Layer caching** – `requirements.txt` is copied and installed before the app code, so code changes don't trigger a full reinstall of dependencies.
- **Non-root user** – the container runs as `appuser` instead of root, so a compromised app has limited access.
- **Gunicorn** – a production WSGI server instead of Flask's built-in development server.
- **HEALTHCHECK** – Docker calls `/health` every 30 seconds and marks the container `healthy` or `unhealthy`, so problems are detected even when the process is still running.
- **.dockerignore** – keeps cache files, git history, docs and `.env` secrets out of the build context and the image.

## Challenges I Faced

- **Wrong COPY path** – `COPY requirements.txt .` failed because the file is in `app/`. Paths in `COPY` are relative to the build context, not the Dockerfile.
- **Two `CMD` lines** – only the last `CMD` runs. The health check had to use the `HEALTHCHECK` instruction instead.
- **Gunicorn not reachable** – by default Gunicorn listens on `127.0.0.1:8000`; it needs `--bind 0.0.0.0:5000` to be reachable from outside the container.

## What I Learned

- The difference between **slim images** (smaller starting point) and **multi-stage builds** (leaving build tools behind) — and that they work best together.
- **`EXPOSE` only documents a port**; `docker run -p host:container` is what actually publishes it.
- **`HEALTHCHECK`** checks whether the app responds, not just whether the process is alive. 
- A Dockerfile combines **Docker instructions** (`FROM`, `COPY`, `RUN`, `CMD`…) with **normal Linux and language commands** (`useradd`, `pip`, `gunicorn`) inside them.
- In real projects you write only the optimized Dockerfile — the basic one here exists to show the before/after.

## Tech Used

Docker · Python 3.12 · Flask · Gunicorn · Linux (WSL Ubuntu)
