FROM node:20 AS build

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

RUN npm run docs:build

FROM nginx:alpine

COPY --from=build /app/.vitepress/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]