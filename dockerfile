FROM python:3.11-slim

# Set work directory
WORKDIR /app

# Install dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir gunicorn

# Copy app and test code
COPY helloworld.py ./


# Expose port (matches Flask default and ECS config)
EXPOSE 5000

# Run the Flask app with Gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "helloworld:app"]
