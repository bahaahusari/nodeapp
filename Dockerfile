FROM node:17-alpine

WORKDIR /usr/src/app

COPY package.json ./

RUN npm install

COPY . .

<<<<<<< HEAD
EXPOSE 3000

=======
# Install production dependencies.
RUN npm install

# Copy local code to the container image.

COPY . ./

# Run the web service on container startup.
>>>>>>> 74378935973a276153ff22f0fab7b17806114d6d
CMD [ "npm", "start" ]
