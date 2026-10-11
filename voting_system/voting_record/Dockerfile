FROM python:3.9
RUN pip install google-cloud-pubsub psycopg2-binary
ADD main.py .
CMD ["python","-u", "./main.py"] 