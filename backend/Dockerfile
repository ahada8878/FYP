# Dockerfile for Main Backend (No ML)
FROM node:18-slim

# 1. Install system tools, Tesseract, & ZBar
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    tesseract-ocr \
    libzbar0 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# 2. Install Python packages
COPY requirements.txt .
RUN pip3 install -r requirements.txt --break-system-packages

# 3. Set up Node.js
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install --omit=dev

# 4. Copy code (will be fast with .dockerignore)
COPY . .

# 5. Start
CMD ["node", "server.js"]