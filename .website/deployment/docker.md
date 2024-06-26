# Docker

Serinus can be run in a Docker container and the creation of the Dockerfile is automated by the `serinus` command line tool.

To create a Dockerfile for your Serinus application, run the following command:

```bash
serinus deploy
```

The deploy command has the following options:

- `--port`: The port to expose the application on. Default is `3000`.
- `--output`: The output file for the application. Default is `app`.

## Build and Run the Docker Image

```bash
docker build -t myapp .
docker run -d -p 3000:3000 myapp
```

This will build the Docker image and run the container on port `3000`.

And that's it! Your Serinus application is now running in a Docker container.
