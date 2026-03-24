# OnMint Upload Demo

This repository demonstrates how to automatically upload a repository to the [OnMint](https://onmint.io) platform from a CI/CD pipeline using API keys.

## How it works

On every push to `main`, the GitHub Action:

1. Zips the entire repository (excluding `.git/`, `.github/`, `node_modules/`, etc.)
2. Creates a data attachment on the OnMint platform
3. Uploads the zip via a presigned URL
4. Polls until the attachment is processed and stored on IPFS

## Setup

### 1. Create an API key

In the OnMint web app, go to **Settings > API Keys** and create a new key. Save the key and secret.

### 2. Configure repository secrets

Add these as **repository secrets** in GitHub (Settings > Secrets and variables > Actions):

| Secret | Description |
|--------|-------------|
| `ONMINT_API_KEY` | Your OnMint API key |
| `ONMINT_API_SECRET` | Your OnMint API secret |

### 3. Configure repository variables

Add these as **repository variables**:

| Variable | Description |
|----------|-------------|
| `ONMINT_STREAM_ID` | The stream ID to upload artifacts to |

### 4. Push to main

Every push to `main` triggers the upload workflow automatically.

## Project Structure

```
.
├── .github/
│   ├── actions/onmint-upload/   # Reusable upload action
│   │   ├── action.yml
│   │   └── upload.sh
│   └── workflows/
│       └── upload.yml           # Workflow that runs on push
├── src/
│   └── index.html               # Sample project file
└── README.md
```

## Results

After a successful run, the workflow outputs:
- **Attachment ID** — unique identifier for the upload
- **CID** — IPFS content identifier for the uploaded file
- **Status** — `FILEDGR_DATA_ATTACHMENT_COMPLETED` on success
