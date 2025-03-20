# Akeyless Nu Shell Example Scripts

This repository contains a collection of Nu shell scripts that demonstrate how to interact with the Akeyless API using the Nu shell. These scripts are designed to help people automate common tasks and integrate with Akeyless services.

## Prerequisites

- [Nu](https://www.nushell.sh/book/installation.html)
- Akeyless API Token (for Akeyless-related scripts)
- OpenAI API Key (for vector store scripts)
- ReadMe.com API Key (for documentation scripts)

## Environment Setup

1. Copy the `.env.example` file to `.env`:
```bash
cp .env.example .env
```

2. Fill in your API keys in the `.env` file:
```bash
OPENAI_API_KEY="your-openai-api-key"
VECTOR_STORE_ID="your-vector-store-id"
```

## Available Scripts

### 1. `docs-download.nu`

Downloads documentation from the Akeyless ReadMe.com account and saves it locally in a structured format.

**Usage:**
```bash
./docs-download.nu
```

**Requirements:**
- `README_API_KEY` environment variable set with your ReadMe.com API key

**Output:**
- Creates a `data/docs` directory
- Downloads all documentation in markdown format
- Creates corresponding JSON files with metadata
- Organizes docs by category and hierarchy

### 2. `akeyless-reference-archive.nu`

Creates a comprehensive archive of your Akeyless configuration including:
- Authentication methods
- Roles
- Targets
- Items

**Usage:**
```bash
./akeyless-reference-archive.nu
```

**Requirements:**
- `AKEYLESS_TOKEN` environment variable set with your Akeyless API token
- Token must be valid for at least 10 minutes

**Output:**
- Creates JSON archives in the `data` directory:
  - `akeyless-auth-methods-archive.json`
  - `akeyless-roles-archive.json`
  - `akeyless-targets-archive.json`
  - `akeyless-items-archive.json`

### 3. `docs-vectorize.nu`

Processes downloaded documentation and uploads it to an OpenAI vector store for semantic search capabilities.

**Usage:**
```bash
./docs-vectorize.nu
```

**Requirements:**
- `OPENAI_API_KEY` environment variable set
- `VECTOR_STORE_ID` environment variable set
- Must be run after `docs-download.nu` has been executed

**Output:**
- Uploads markdown files to the specified OpenAI vector store
- Maintains metadata and relationships between documents

### 4. `upload_vector_store.py`

A Python script that handles the actual upload of files to OpenAI's vector store with proper error handling and retries.

**Usage:**
```bash
python upload_vector_store.py <file_path> [attributes_json]
```

**Requirements:**
- Python 3.11 or higher
- OpenAI API key
- Vector store ID

## Script Dependencies

The scripts use the following dependencies:
- `dotenv` - For environment variable management
- `openai` - For OpenAI API interactions
- `uv` - For Python package management

## Error Handling

All scripts include robust error handling:
- API key validation
- Token expiration checks
- Retry mechanisms for API calls
- Proper error messages and status reporting

## Contributing

Feel free to submit issues and enhancement requests!



