FROM node:18-alpine

WORKDIR /usr/src/node-app

COPY package.json ./

RUN npm install

COPY . .

EXPOSE 5555

CMD ["node", "app.js"]