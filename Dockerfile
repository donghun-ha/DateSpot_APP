FROM python:3.12-slim

# Set the working directory
WORKDIR /DATESPOT

# Copy the application folder
COPY ./fastapi ./fastapi

# Copy the requirements file first to leverage Docker cache
COPY ./requirements.txt ./requirements.txt

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set the working directory for the app
WORKDIR /DATESPOT/fastapi

# Expose the port the app runs on
EXPOSE 6004

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "6004"]