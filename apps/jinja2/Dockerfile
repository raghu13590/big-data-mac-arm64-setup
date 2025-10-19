FROM python:3.11-slim

# Install dependencies
RUN pip install --no-cache-dir jinja2 python-dotenv pyyaml

# Set working directory
WORKDIR /app

# Copy scripts and templates
COPY . /app

# Default command: show help
CMD ["python3", "render.py", "--help"]
