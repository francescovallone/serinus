FROM node:20 AS build

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

RUN mkdir /md_only && \
    find . -type f -name "*.md" -exec sh -c '
        for filepath do
            mkdir -p /md_only/$(dirname "$filepath") &&
            cp "$filepath" /md_only/"$filepath"
        done
    ' sh {} +

RUN npm run docs:build

FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=build /app/.vitepress/dist /usr/share/nginx/html
COPY --from=build /md_only /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]