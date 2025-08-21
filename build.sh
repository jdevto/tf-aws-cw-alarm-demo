#!/bin/bash

echo "Building Lambda function..."

# Navigate to lambda directory
cd lambda

# Install dependencies
echo "Installing dependencies..."
npm install

# Package the function
echo "Packaging Lambda function..."
npm run package

# Return to root directory
cd ..

echo "Build complete! Lambda function packaged as lambda_function.zip"
