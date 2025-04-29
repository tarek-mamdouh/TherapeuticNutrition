# Therapeutic Nutrition App for Diabetic Patients - Setup Guide

This document provides instructions on setting up and running the Therapeutic Nutrition App for Diabetic Patients with its backend and mobile components.

## Prerequisites

1. Python 3.11 or higher
2. Flutter 3.0 or higher (for mobile app development)
3. An OpenAI API key (optional, for enhanced food recognition)

## Backend Setup

The backend is built with FastAPI and provides APIs for food recognition, nutrition data, and a diabetic-friendly chatbot.

### 1. Clone the Repository

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Set Up Environment Variables

Create a `.env` file in the project root with the following variables:

```
OPENAI_API_KEY=your_openai_api_key  # Optional
```

### 3. Install Dependencies

```bash
cd backend
pip install fastapi uvicorn sqlalchemy pydantic python-multipart pillow numpy openai
```

### 4. Run the Backend Server

```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 5000 --reload
```

The backend will be available at `http://0.0.0.0:5000`

## Mobile App Setup

The mobile app is built with Flutter and provides a user-friendly interface for food recognition, nutritional information display, and chatbot interaction.

### 1. Install Flutter Dependencies

```bash
cd mobile
flutter pub get
```

### 2. Configure API Endpoint

Make sure the API endpoint in the Flutter app matches your backend URL. Check the file `mobile/lib/utils/constants.dart` and update the `BASE_URL` constant if needed.

### 3. Run the Mobile App

```bash
cd mobile
flutter run
```

## Testing the Application

### Backend API Testing

You can test the backend APIs using curl commands:

1. Health Check:
```bash
curl http://0.0.0.0:5000/health
```

2. Food Recognition (requires an image file):
```bash
curl -X POST -F "file=@/path/to/food/image.jpg" http://0.0.0.0:5000/api/predict
```

3. Get Nutritional Information:
```bash
curl http://0.0.0.0:5000/api/nutrition/apple
```

4. Chat with the Nutritional Advisor:
```bash
curl -X POST -H "Content-Type: application/json" -d '{"question": "Can diabetics eat bananas?", "language": "en"}' http://0.0.0.0:5000/api/chat
```

### Mobile App Testing

1. Launch the app on your device or emulator
2. Navigate to the image upload screen
3. Upload a food image or take a photo
4. View nutritional information
5. Chat with the nutritional advisor

## Running in Replit

This project is configured to run in Replit:

1. The backend workflow is already set up to run on port 5000
2. The required Python packages are already installed
3. To test the APIs, use the terminal to run the curl commands shown above
4. For mobile app testing, you'll need to run Flutter locally and point it to the Replit backend URL

## Troubleshooting

### Backend Issues

- If you encounter database errors, ensure the SQLite database is properly initialized by checking `backend/database/init_db.py`
- If OpenAI integration fails, the system will fall back to a built-in classifier

### Mobile App Issues

- If the app fails to connect to the backend, check the API URL in `mobile/lib/utils/constants.dart`
- For accessibility issues, ensure text-to-speech and speech-to-text services are properly configured

## Next Steps

After successful setup, you can:

1. Add more food items to the database
2. Enhance the AI model with more training data
3. Add more user profile information
4. Implement meal planning features