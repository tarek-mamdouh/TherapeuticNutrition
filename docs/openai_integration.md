# OpenAI Integration Guide

This document explains how the OpenAI API is integrated into the Therapeutic Nutrition App for Diabetic Patients to enhance food recognition capabilities.

## Overview

The app uses OpenAI's multimodal capabilities (GPT-4o) to provide accurate food recognition from images. When a user uploads a food image, the system:

1. First attempts to analyze the image using OpenAI's vision capabilities
2. Falls back to a built-in food classifier if OpenAI is unavailable or fails

## Setup

### 1. Obtain an OpenAI API Key

To use OpenAI features, you need an API key:

1. Visit [OpenAI Platform](https://platform.openai.com/signup)
2. Create an account or sign in
3. Navigate to the API keys section
4. Create a new secret key
5. Copy the key (you will only see it once)

### 2. Configure the Environment

Add your OpenAI API key to the project:

- In Replit: Use the Secrets tool to add a secret named `OPENAI_API_KEY` with your key value
- For local development: Add it to your `.env` file: `OPENAI_API_KEY=your_key_here`

## How It Works

### 1. Image Analysis Process

When a user uploads a food image:

```
User -> Upload Image -> Backend -> OpenAI (if available) -> Process Results -> Return to User
                                -> Local Classifier (fallback)
```

### 2. Implementation Details

The OpenAI integration is implemented in the `backend/models/openai_integration.py` file:

1. The `OpenAIIntegration` class handles communication with the OpenAI API
2. The `analyze_food_image` method is the core function that:
   - Converts the image to base64 format
   - Sends the image to OpenAI with a prompt asking to identify food items
   - Parses the response into a consistent format with food names and confidence scores
   
### 3. Fallback Mechanism

The system uses a seamless fallback mechanism:

1. First attempts to use OpenAI for accurate food recognition
2. If OpenAI is unavailable (due to missing API key or quota limits), automatically falls back to the local classifier
3. The user experience remains uninterrupted, though recognition quality may vary
4. All fallbacks are logged for monitoring

## Testing the OpenAI Integration

You can test if the OpenAI integration is working correctly:

### Using the API directly:

```bash
curl -X POST -F "file=@test_images/apple.jpg" http://0.0.0.0:5000/api/predict
```

A successful response with OpenAI will be more detailed than the fallback classifier:

```json
[
  {"food": "red apple", "confidence": 0.98},
  {"food": "granny smith apple", "confidence": 0.87},
  {"food": "fruit platter", "confidence": 0.65}
]
```

### Interpreting the Response

- If the response contains specific food descriptions (like "granny smith apple" instead of just "apple"), OpenAI was likely used
- If the response contains generic food names from a limited set, the fallback classifier was used
- Check server logs for messages like "Using OpenAI for food recognition..." or "Using fallback food recognition model..."

## Troubleshooting

### Common Issues

1. **API Key Invalid or Expired**
   - Error message: "Authentication error with OpenAI API"
   - Solution: Generate a new API key and update the environment variable

2. **Quota Exceeded**
   - Error message: "You exceeded your current quota, please check your plan and billing details"
   - Solution: Check your OpenAI billing and usage on their dashboard

3. **Connection Issues**
   - Error message: "Failed to establish a connection to the OpenAI API"
   - Solution: Check internet connection and firewall settings

### Support Information

If you encounter persistent issues with the OpenAI integration, please contact the development team with:
1. The exact error message from the logs
2. The image you tried to analyze (if applicable)
3. Your current OpenAI plan type