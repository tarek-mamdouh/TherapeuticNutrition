from pydantic import BaseModel, Field
from typing import List, Optional

class Food(BaseModel):
    id: Optional[int] = None
    name: str
    name_ar: str
    calories: float
    carbs: float
    protein: float
    sugar: float
    fat: float
    glycemic_index: int
    diabetic_suitability: str

class FoodDetection(BaseModel):
    food: str
    confidence: float

class NutritionResponse(BaseModel):
    food_info: Food
    suitability_explanation: str

class ChatQuestion(BaseModel):
    question: str
    language: str = "en"

class ChatResponse(BaseModel):
    answer: str
    related_foods: Optional[List[Food]] = None

class User(BaseModel):
    id: Optional[int] = None
    name: str
    age: Optional[int] = None
    diabetes_type: Optional[str] = None
    preferences: Optional[str] = None

class QAPair(BaseModel):
    id: Optional[int] = None
    question: str
    question_ar: str
    answer: str
    answer_ar: str
    tags: str
