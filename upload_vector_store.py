# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "dotenv",
#     "openai",
# ]
# ///
import os
import sys
import json
import dotenv
from openai import OpenAI
from openai.types.vector_stores.vector_store_file import VectorStoreFile

dotenv.load_dotenv()

# Constants for OpenAI Client
MAX_RETRIES = 5 # Up from the default of 2

# Constants for attribute validation
MAX_ATTRIBUTES = 16  # Maximum number of attribute keys allowed
MAX_KEY_LENGTH = 64  # Maximum length of attribute key in characters
MAX_VALUE_LENGTH = 512  # Maximum length of attribute value in characters

client = OpenAI(
    max_retries=MAX_RETRIES
)

# validate that the OPENAI_API_KEY is set
if not os.getenv("OPENAI_API_KEY"):
    raise ValueError("OPENAI_API_KEY is not set")

# validate that the VECTOR_STORE_ID is set
if not os.getenv("VECTOR_STORE_ID"):
    raise ValueError("VECTOR_STORE_ID is not set")

# Check if file path is provided as an argument
if len(sys.argv) < 2:
    print("Error: Please provide a file path as an argument.")
    print("Usage: python upload_vector_store.py <file_path> [attributes_json]")
    sys.exit(1)

file_path = sys.argv[1]

# Validate that the file exists
if not os.path.exists(file_path):
    print(f"Error: File '{file_path}' does not exist.")
    sys.exit(1)

# Default attributes
attributes = {
    "source": os.path.basename(file_path),
    "upload_date": os.path.getmtime(file_path)
}

# We need to validate the attributes JSON here
# - the JSON can have a maximum of 16 keys
# - the keys must be strings with a length between 1 and 64 characters
# - the values must be strings with a maximum length of 512 characters, or booleans, or numbers
# Check if attributes JSON is provided as a second argument
def validate_attributes(attributes: dict):
    if len(attributes) > MAX_ATTRIBUTES:
        raise ValueError(f"Attributes must have a maximum of {MAX_ATTRIBUTES} keys.")
    for key, value in attributes.items():
        if not isinstance(key, str) or len(key) > MAX_KEY_LENGTH:
            raise ValueError(f"Key must be a string with a maximum length of {MAX_KEY_LENGTH} characters.")
        if not len(value) <= MAX_VALUE_LENGTH:
            raise ValueError(f"Value must be a string with a maximum length of {MAX_VALUE_LENGTH} characters.")

if len(sys.argv) > 2:
    try:
        custom_attributes = json.loads(sys.argv[2])
        if not isinstance(custom_attributes, dict):
            print("Error: Attributes must be a valid JSON object.")
            sys.exit(1)
        validate_attributes(custom_attributes)
    except json.JSONDecodeError:
        print("Error: Invalid JSON format for attributes.")
        print("""Example: '{"key1": "value1", "key2": "value2"}' """)
        sys.exit(1)

# Upload the file to the vector store
vector_store_file: VectorStoreFile = client.vector_stores.files.upload_and_poll(
    vector_store_id=os.getenv("VECTOR_STORE_ID"),
    file=open(file_path, "rb")
)

# Update the vector store with attribute properties
updated_vector_store: VectorStoreFile = client.vector_stores.files.update(
    vector_store_id=vector_store_file.vector_store_id,
    file_id=vector_store_file.id,
    attributes=attributes
)
print(updated_vector_store.model_dump_json())
