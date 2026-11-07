FROM python:3.12-slim As builder
WORKDIR /app
COPY app/requirements.txt .
RUN pip install  --prefix=/install  --no-cache-dir -r requirements.txt 

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY ./app .
RUN useradd --create-home appuser
USER appuser
EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"
CMD ["gunicorn","--bind", "0.0.0.0:5000","app:app"]
