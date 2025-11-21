---
outline: [2, 4]
---

# Cloud Run Deployment

Serinus applications can be easily deployed to Google Cloud Run, allowing you to leverage the scalability and reliability of Google's infrastructure for your applications.

## Prerequisites

Before deploying your Serinus application to Cloud Run, ensure you have the following:

- A Google Cloud account with billing enabled.
- The Google Cloud SDK installed and configured on your local machine.
- Docker installed on your local machine.
- A Serinus application ready for deployment.

## Steps to Deploy

### 1. Build the Docker Image

First, create a Dockerfile for your Serinus application if you haven't already. You can use the `serinus deploy` command to generate a Dockerfile automatically:

```bash
serinus deploy
```

This command will create a Dockerfile in your project directory with all the necessary configurations.

Next, build the Docker image using the following command:

```bash
docker build -t gcr.io/[PROJECT-ID]/[IMAGE-NAME] .
```

Replace `[PROJECT-ID]` with your Google Cloud project ID and `[IMAGE-NAME]` with a name for your Docker image.

### 2. Push the Docker Image to Google Container Registry

Login to the Google Cloud Container Registry:

```bash
gcloud auth configure-docker
```

Push the Docker image to Google Container Registry using the following command:

```bash
docker push gcr.io/[PROJECT-ID]/[IMAGE-NAME]
```

### 3. Deploy to Cloud Run

Finally, deploy your Docker image to Cloud Run with the following command:

```bash
gcloud run deploy [SERVICE-NAME] --image=gcr.io/[PROJECT-ID]/[IMAGE-NAME]
```

Replace `[SERVICE-NAME]` with the name you want for your Cloud Run service.

A prompt will appear asking you to select a region and whether you want to allow unauthenticated invocations. Choose the appropriate options based on your requirements.

### 4. Access Your Application

Once the deployment is complete, you will receive a URL for your Cloud Run service. You can access your Serinus application by navigating to this URL in your web browser.
And that's it! Your Serinus application is now deployed and running on Google Cloud Run.
