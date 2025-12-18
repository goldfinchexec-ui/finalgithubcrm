# Use official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the app
COPY . .

# Build web app
RUN flutter build web --release --web-renderer canvaskit

# Use nginx to serve the built files
FROM nginx:alpine

# Copy built web files to nginx html directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 8080 (required by Firebase App Hosting)
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
