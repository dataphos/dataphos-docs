FROM klakegg/hugo:0.101.0-ext-alpine

WORKDIR /app

COPY . .

WORKDIR ./themes/hugo-geekdoc
RUN npm install
RUN npm run build

WORKDIR /app 

CMD ["server"]