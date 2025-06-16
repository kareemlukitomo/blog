# Stage 1: Hugo build
FROM git.kareem.one/kareem/blog:base AS builder

WORKDIR /app

# Copy the rest of the site (excluding files already copied in base)
COPY . .

# Build the site
RUN hugo --minify --gc --cleanDestinationDir

# Stage 2: NGINX
FROM nginx:stable-alpine-slim

# Copy static site to nginx
COPY --from=builder /app/public /usr/share/nginx/html

# Optional: custom nginx config
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
