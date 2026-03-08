# Stage 1: Hugo build
FROM git.kareem.one/shaquille/blog:base AS builder

WORKDIR /app

# Copy only the site sources needed for the production build.
COPY go.mod go.sum package.json package-lock.json theme.toml ./
COPY config/ config/
COPY assets/ assets/
COPY content/ content/
COPY layouts/ layouts/

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
