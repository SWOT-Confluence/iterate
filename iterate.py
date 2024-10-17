"""AWS Lambda Function that iterates over Job Array submissions.

- Determines index of current Job Array to execute on.
- Links the number of child jobs in the job array to the number of elements in 
  the current batch.
- Determines the total number of job arrays to submit.
"""

# Standard imports
import glob
import json
import logging
import pathlib

# Third-party imports
import boto3


logging.getLogger().setLevel(logging.INFO)
logging.basicConfig(
    format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
    datefmt='%Y-%m-%dT%H:%M:%S',
    level=logging.INFO
)


EFS_DIR = pathlib.Path("/mnt/input")


def handler(event, context):
    """Determine the data needed to iterate over job batches."""

    index = event["iterator"]["index"]
    step = event["iterator"]["step"]
    count = event["iterator"]["count"]
    json_file = EFS_DIR.joinpath(event["iterator"]["json_file"])

    logging.info("index: %s", index)
    logging.info("step: %s", step)
    logging.info("count: %s", count)
    logging.info("json_file: %s", json_file)

    index += step

    with open(json_file) as jf:
        json_data = json.load(jf)

    if count == -1:
        json_glob = str(EFS_DIR.joinpath(f"{json_file.name.split('.')[0]}_batch_*.json"))
        print(glob.glob(json_glob))
        print(list(glob.glob(json_glob)))
        count = len(glob.glob(json_glob))

    num_elements = len(json_data)

    output = {
        "index": index,
        "step": step,
        "count": count,
        "num_elements": num_elements,
        "continue": index < count
    }

    sf = boto3.client("stepfunctions")
    try:
        response = sf.send_task_success(
            taskToken=event["token"],
            output=json.dumps(output)
        )
        logging.info("Sent task success.")
    
    except botocore.exceptions.ClientError as err:
        response = sf.send_task_failure(
            taskToken=event["token"],
            error=err.response['Error']['Code'],
            cause=err.response['Error']['Message']
        )
        logging.error("Sent task failure.")
