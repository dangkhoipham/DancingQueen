FROM node:6

# Deps
RUN apt-get update && apt-get install -y ca-certificates git-core ssh nginx

# Our source
WORKDIR /var/www/html/
ADD . /var/www/html
ADD default /etc/nginx/sites-available

# Start nginx
RUN service nginx start
# Install node deps for each app
RUN npm install --quiet
CMD ["npm","start"]
EXPOSE 5000/tcp
