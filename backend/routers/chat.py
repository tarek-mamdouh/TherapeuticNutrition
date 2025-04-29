from fastapi import APIRouter, HTTPException, Body
from typing import List, Optional
import sqlite3
import re
from database.init_db import get_db_connection
from database.schema import ChatQuestion, ChatResponse, Food

router = APIRouter()

@router.post("/chat", response_model=ChatResponse)
async def chat(question: ChatQuestion = Body(...)):
    """
    Process a user's dietary question and return a response
    """
    try:
        language = question.language.lower()
        if language not in ["en", "ar"]:
            language = "en"  # Default to English
            
        query = question.question.strip()
        
        # Connect to database
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # First, try to find an exact match
        if language == "en":
            cursor.execute(
                "SELECT question, answer, tags FROM qa WHERE LOWER(question) = LOWER(?)", 
                (query,)
            )
        else:
            cursor.execute(
                "SELECT question_ar as question, answer_ar as answer, tags FROM qa WHERE LOWER(question_ar) = LOWER(?)", 
                (query,)
            )
        
        result = cursor.fetchone()
        
        # If no exact match, try keyword matching
        if not result:
            # Extract keywords (3+ letter words)
            keywords = re.findall(r'\b\w{3,}\b', query.lower())
            
            if keywords:
                # Search by keywords in question or tags
                search_conditions = []
                search_params = []
                
                for keyword in keywords:
                    if language == "en":
                        search_conditions.append("LOWER(question) LIKE ? OR LOWER(tags) LIKE ?")
                    else:
                        search_conditions.append("LOWER(question_ar) LIKE ? OR LOWER(tags) LIKE ?")
                    search_params.extend([f"%{keyword}%", f"%{keyword}%"])
                
                search_query = " OR ".join(search_conditions)
                
                if language == "en":
                    cursor.execute(
                        f"SELECT question, answer, tags FROM qa WHERE {search_query} ORDER BY length(question) ASC LIMIT 1", 
                        search_params
                    )
                else:
                    cursor.execute(
                        f"SELECT question_ar as question, answer_ar as answer, tags FROM qa WHERE {search_query} ORDER BY length(question_ar) ASC LIMIT 1", 
                        search_params
                    )
                
                result = cursor.fetchone()
        
        # If still no result, provide a generic response
        if not result:
            if language == "en":
                generic_answer = "I don't have specific information about that. Please try asking about specific foods, nutritional advice for diabetics, or general diabetes dietary guidelines."
            else:
                generic_answer = "ليس لدي معلومات محددة حول ذلك. يرجى محاولة السؤال عن أطعمة محددة، أو نصائح غذائية لمرضى السكري، أو إرشادات غذائية عامة لمرض السكري."
            
            return ChatResponse(
                answer=generic_answer,
                related_foods=[]
            )
        
        answer = result["answer"]
        
        # Get related foods if there are food-related tags
        related_foods = []
        if result["tags"]:
            tags = result["tags"].split(",")
            food_tags = [tag for tag in tags if not tag.startswith(("carbs", "sugar", "protein", "nutrition", "glycemic", "meal", "diet"))]
            
            if food_tags:
                # Build query to find related foods
                food_conditions = []
                food_params = []
                
                for tag in food_tags:
                    food_conditions.append("LOWER(name) LIKE ? OR LOWER(name_ar) LIKE ?")
                    food_params.extend([f"%{tag}%", f"%{tag}%"])
                
                food_query = " OR ".join(food_conditions)
                
                cursor.execute(
                    f"SELECT * FROM foods WHERE {food_query} LIMIT 3", 
                    food_params
                )
                
                food_results = cursor.fetchall()
                
                for food_data in food_results:
                    food = Food(
                        id=food_data['id'],
                        name=food_data['name'],
                        name_ar=food_data['name_ar'],
                        calories=food_data['calories'],
                        carbs=food_data['carbs'],
                        protein=food_data['protein'],
                        sugar=food_data['sugar'],
                        fat=food_data['fat'],
                        glycemic_index=food_data['glycemic_index'],
                        diabetic_suitability=food_data['diabetic_suitability']
                    )
                    related_foods.append(food)
        
        conn.close()
        
        return ChatResponse(
            answer=answer,
            related_foods=related_foods
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat error: {str(e)}")
