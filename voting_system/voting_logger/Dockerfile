FROM python:3.9
RUN pip install google-cloud-pubsub redis
ADD main.py .
CMD ["python","-u", "./main.py"] 