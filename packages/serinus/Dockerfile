FROM dart:latest AS build


WORKDIR /app

COPY . ./
COPY pubspec.* ./
RUN dart pub get
COPY . .

RUN dart pub get --offline
RUN dart compile exe bin/serinus.dart -o bin/serinus

FROM scratch
EXPOSE 3000
COPY --from=build /runtime/ /
COPY --from=build /app/bin/serinus /app/bin/

CMD ["/app/bin/serinus"]

