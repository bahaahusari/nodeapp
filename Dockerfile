FROM node:lts-jessie

# Set the work directory
RUN mkdir -p /var/www/nodeapp
WORKDIR /var/www/nodeapp

# Add our nodeapp.js and install *before* adding our application files
ADD nodeapp.js ./
RUN npm i --production

# Install pm2 *globally* so we can run our application
RUN npm i -g pm2

# Add application files
ADD nodeapp /var/www/nodeapp

EXPOSE 4000

CMD ["pm2", "start", "process.json", "--no-daemon"]