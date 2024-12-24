FROM python:3.12-slim

# Set the working directory
WORKDIR /DATESPOT

# Copy the application folder
COPY ./fastapi ./fastapi

# Set the working directory for the app
WORKDIR /DATESPOT/fastapi

# Install dependencies
COPY ./fastapi/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# ENV DATESPOT_DB=""
# ENV DATESPOT_DB_USER=""
# ENV DATESPOT_DB_PASSWORD=""
# ENV DATESPOT_DB_TABLE=""
# ENV DATESPOT_PORT=""
# ENV REDIS_HOST=""
# ENV REDIS_PORT=""
# ENV REDIS_PASSWORD=""

# Expose the port the app runs on
EXPOSE 6003

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "6003"]
