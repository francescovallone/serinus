FROM node:24-alpine AS build

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

RUN npm run docs:build

FROM nginx:alpine as md_only

WORKDIR /app

COPY . .

RUN mkdir -p /md_only && \
    find . -type f -name "*.md" | while read filepath; do \
        mkdir -p /md_only/$(dirname "$filepath") && \
        cp "$filepath" /md_only/"$filepath"; \
    done

FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=build /app/.vitepress/dist /usr/share/nginx/html
COPY --from=md_only /md_only /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]