FROM python:3.12-slim
RUN pip install --no-cache-dir google-cloud-pubsub
COPY main.py .
CMD ["python", "-u", "./main.py"]
