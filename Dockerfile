# FROM python:3.10-slim

# # Install system dependencies (compiler + Python headers)
# RUN apt-get update && \
#     apt-get install -y build-essential python3-dev && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*

# # Set working directory
# WORKDIR /app

# # Install Python dependencies (use requirements.txt if available)
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt

# # Copy the rest of the project
# COPY . .

# # Collect static files
# RUN python manage.py collectstatic --noinput

# # Start with uWSGI
# CMD ["uwsgi", "--ini", "uwsgi.ini"]


# --------- Stage 1: Build Django static files ----------
# FROM python:3.10-slim as builder

# ENV PYTHONDONTWRITEBYTECODE=1
# ENV PYTHONUNBUFFERED=1
# RUN apt-get update && \
#     apt-get install -y build-essential python3-dev && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*


# WORKDIR /app
# COPY . .
# RUN pip install -r requirements.txt
# RUN python manage.py collectstatic --noinput

# # --------- Stage 2: Final container with Django + Nginx ----------
# FROM nginx:latest

# # Copy static files from builder
# COPY --from=builder /app/static /usr/share/nginx/html/static

# # Copy nginx config
# COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# # Copy Django project
# COPY --from=builder /app /app

# WORKDIR /app

# # Start uWSGI and Nginx
# CMD ["uwsgi", "--ini", "uwsgi.ini"]



FROM python:3.11-slim as base

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    nginx \
    curl \
    python3-dev \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy project files
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Copy custom nginx config
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

COPY nginx/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Remove default site if it exists
RUN rm -f /etc/nginx/sites-enabled/default

# Expose ports
EXPOSE 8080

# Start nginx and uwsgi together
CMD ["/usr/bin/supervisord"]
