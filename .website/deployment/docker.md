# Docker

Serinus can be run in a Docker container and the creation of the Dockerfile is automated by the `serinus` command line tool.

We can use the following code for the Dockerfile:

```dockerfile
FROM dart:latest AS build


WORKDIR /app

COPY . ./
COPY pubspec.* ./
RUN dart pub get
COPY . .

RUN dart pub get --offline
RUN dart compile exe bin/${ENTRYPOINT}.dart -o bin/${OUTPUT}

FROM scratch
EXPOSE ${PORT}
COPY --from=build /runtime/ /
COPY --from=build /app/bin/${OUTPUT} /app/bin/

CMD ["/app/bin/${OUTPUT}"]
```

To use it we need to replace `${ENTRYPOINT}` with the name of the entrypoint file and `${OUTPUT}` with the name of the output file and `${PORT}` with the port that the application will run on.

Perfect! We are set to build the image and run the container on our server.

```bash
docker build -t myapp .
docker run -d -p 8080:8080 myapp
```