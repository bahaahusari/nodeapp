FROM node:17-alpine

WORKDIR /usr/src/app

COPY package.json ./

RUN npm install

COPY . .

EXPOSE 3000

=======
# Install  dependencies.
RUN node nodeapp.js

# Copy local code to the container image.

COPY . ./

# Run the web service on container startup.
CMD [ "npm", "start" ]
