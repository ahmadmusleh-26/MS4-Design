import glob                             # for searching for json file
import os                               # for setting and reading environment variables
from google.cloud import pubsub_v1      # pip install google-cloud-pubsub  ##to install
import json                             # to deal with json objects

# The service account key is optional (key creation is blocked by the organization policy).
# Without a key, the credentials of the GKE node service account are used.
files = glob.glob("*.json")
if len(files) > 0:
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = files[0]

# Get the configuration from environment variables (set in design.yaml)
project_id = os.environ["GCP_PROJECT"]
subscription_id = os.environ["FILTER_SUB_ID"]
topic_name = os.environ["TOPIC_NAME"]

# The measurements that must all be present in a reading
MEASUREMENTS = ['temperature', 'humidity', 'pressure']

# create a publisher and get the topic path for the publisher
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_name)

# The callback function for handling received messages
def callback(message: pubsub_v1.subscriber.message.Message) -> None:
    reading = json.loads(message.data)

    if all(reading.get(m) is not None for m in MEASUREMENTS):
        # Complete reading: forward it to the ConvertReading service (function="filtered reading")
        future = publisher.publish(topic_path, json.dumps(reading).encode('utf-8'), function="filtered reading")
        future.result()   # make sure it is published before the ack
        print(f"Passed:  {reading}")
    else:
        # A measurement is missing (None): the reading is dropped
        print(f"Dropped: {reading}")

    # Report to Pub/Sub that the message was processed successfully
    message.ack()

# create a subscriber and a filtered subscription that receives only the raw readings
subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(project_id, subscription_id)
sub_filter = "attributes.function=\"raw reading\""

print(f"FilterReading is listening for messages on {subscription_path}..\n")

with subscriber:
    # Create the subscription with the filter the first time. If it already exists, this fails and is ignored.
    try:
        subscriber.create_subscription(
            request={"name": subscription_path, "topic": topic_path, "filter": sub_filter}
        )
    except Exception:
        pass

    streaming_pull_future = subscriber.subscribe(subscription_path, callback=callback)
    try:
        streaming_pull_future.result()
    except KeyboardInterrupt:
        streaming_pull_future.cancel()
