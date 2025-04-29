# Diabetes Nutrition App

A therapeutic nutrition mobile application to assist diabetic patients in analyzing meals and receiving instant nutritional guidance. The app includes food recognition, voice feedback, and bilingual support for Arabic and English.

## Features

- **Food Image Recognition**: Analyzes food images to identify and provide nutritional information
- **Nutritional Analysis**: Evaluates food suitability for diabetic patients based on nutritional content
- **Voice Feedback**: Provides audio responses for visually impaired users
- **Manual Food Entry**: Option to manually enter foods when image recognition is unavailable
- **Chatbot Assistant**: Answers dietary questions about foods and diabetes management
- **Bilingual Support**: Full support for Arabic (primary) and English languages
- **Accessibility Features**: High contrast mode, adjustable text size, and screen reader support
- **Offline Functionality**: Works with minimal internet connectivity

## Tech Stack

### Frontend (Mobile App)
- Flutter (Dart) for cross-platform mobile development
- Text-to-speech and speech-to-text for accessibility
- Local SQLite database for offline data access
- Internationalization for Arabic and English support

### Backend
- Python with FastAPI for the REST API
- Image recognition using a lightweight CNN model
- SQLite database for food nutrition data and chatbot Q&A

## Project Structure

The project consists of two main components:

### Backend
- `backend/main.py`: Main FastAPI application
- `backend/models/food_classifier.py`: Food image recognition model
- `backend/database/`: Database configuration and initialization
- `backend/routers/`: API endpoints for food recognition and chat

### Mobile App
- `mobile/lib/main.dart`: Entry point for the Flutter application
- `mobile/lib/screens/`: UI screens for the app (home, image upload, nutrition, chatbot, profile)
- `mobile/lib/models/`: Data models (food, user)
- `mobile/lib/services/`: Business logic and API services
- `mobile/lib/widgets/`: Reusable UI components
- `mobile/lib/l10n/`: Internationalization files for Arabic and English

## Setup and Running

### Backend

1. Ensure Python 3.7+ is installed
2. Install dependencies:
   ```
   pip install fastapi uvicorn sqlalchemy pydantic python-multipart pillow numpy tensorflow
   ```
3. Run the server:
   ```
   cd backend
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

### Mobile App

1. Ensure Flutter SDK is installed
2. Install dependencies:
   ```
   cd mobile
   flutter pub get
   ```
3. Run the app:
   ```
   flutter run
   