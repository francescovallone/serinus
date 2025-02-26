# Serinus on your server

If you want to run Serinus on your server without the need for a service like Globe, you can do so by following these steps.

## Getting Started

To run your application on your server there are more ways to do it. You can see the possibilities listed below.

- Run the [Docker](docker) container on your server.
- Compile your application to a standalone executable and run it on your server.
- Run your application using the Dart SDK on your server like you would on your local machine.

## Running the Docker container

To run your application in a Docker container, you will need to have Docker installed on your server. If you don't have Docker installed, you can follow the instructions on the [Docker website](https://docs.docker.com/get-docker/).

You will also need Nginx or another web server to serve your application. You can install Nginx by running the following command:

```bash
sudo apt-get install nginx
```

To create a Dockerfile for your project, run the following command:

```bash
serinus deploy
```

You can now build the image and run the container on your server.

```bash
docker build -t myapp .
docker run -d -p 8080:8080 myapp
```

### Configure Nginx

To configure Nginx to serve your application, create a new configuration file in the `/etc/nginx/sites-available` directory.

```nginx
server {
    server_name your_domain;

    location / {
        proxy_pass http://localhost:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

server {
    listen 80;
    server_name your_domain;
    return 404; # managed by Certbot
}
```

Enable the configuration file by creating a symbolic link in the `/etc/nginx/sites-enabled` directory.

```bash
sudo ln -s /etc/nginx/sites-available/your_domain /etc/nginx/sites-enabled/
```

Reload Nginx to apply the changes.

```bash
sudo systemctl reload nginx
```

You can now access your application by visiting your domain in a web browser.

## Compiling to a standalone executable

To compile your application to a standalone executable, you can use the `dart compile exe` command.

```bash
dart compile exe bin/entrypoint.dart
```

This will create an executable file in the `bin` directory that you can run on your server.

```bash
./bin/entrypoint
```

## Running with the Dart SDK

To run your application using the Dart SDK on your server, you can use the `dart run` command.

```bash
dart run bin/entrypoint.dart
```

This will start your application on your server.

## Conclusion

You now have multiple ways to run your Serinus application on your server. Choose the method that best fits your needs and get your application up and running on your server.

### More Information

To create this guide we used the following resources:

- [Docker](https://docs.docker.com/get-docker/)
- [Nginx](https://nginx.org/en/docs/)
- [Dart](https://dart.dev/guides)
- [Learn Dart](https://learndart.dev/server/deploy-dart-server-to-vps/)