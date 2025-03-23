FROM node:lts-alpine3.17

# add project files to /app
ADD ./ /app
WORKDIR /app

# install node dependencies
RUN npm ci

EXPOSE 8080
