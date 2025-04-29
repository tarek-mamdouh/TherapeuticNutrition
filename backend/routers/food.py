from fastapi import APIRouter, File, UploadFile, HTTPException, Depends, Body
from typing import List
import sqlite3
from models.food_classifier import food_classifier
from database.init_db import get_db_connection
from database.schema import FoodDetection, NutritionResponse, Food

router = APIRouter()

@router.post("/predict", response_model=List[FoodDetection])
async def predict_food(file: UploadFile = File(...)):
    """
    Accept an image and return predicted food items with confidence scores
    """
    try:
        content = await file.read()
        results = food_classifier.predict(content)
        
        if isinstance(results, dict) and "error" in results:
            raise HTTPException(status_code=500, detail=results["error"])
            
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@router.get("/nutrition/{food_name}", response_model=NutritionResponse)
async def get_nutrition(food_name: str):
    """
    Get nutritional information for a specified food
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Case-insensitive search
        cursor.execute("SELECT * FROM foods WHERE LOWER(name) = LOWER(?)", (food_name,))
        food_data = cursor.fetchone()
        
        conn.close()
        
        if not food_data:
            raise HTTPException(status_code=404, detail=f"Food '{food_name}' not found")
        
        # Convert to Food model
        food_info = Food(
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
        
        # Generate suitability explanation
        explanation = generate_suitability_explanation(food_info)
        
        return NutritionResponse(
            food_info=food_info,
            suitability_explanation=explanation
        )
        
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

def generate_suitability_explanation(food: Food) -> str:
    """Generate an explanation of why a food is suitable/unsuitable for diabetics"""
    
    suitability = food.diabetic_suitability
    explanations = {
        "Safe": f"{food.name} is generally safe for diabetic patients. ",
        "Moderate": f"{food.name} should be consumed in moderation by diabetic patients. ",
        "Avoid": f"{food.name} should generally be avoided by diabetic patients. "
    }
    
    base_explanation = explanations.get(suitability, "")
    
    # Add details based on nutritional values
    details = []
    
    if food.glycemic_index > 0:
        if food.glycemic_index < 55:
            details.append(f"It has a low glycemic index of {food.glycemic_index}, which means it will cause a slower rise in blood sugar.")
        elif food.glycemic_index < 70:
            details.append(f"It has a medium glycemic index of {food.glycemic_index}, so monitor your portion sizes.")
        else:
            details.append(f"It has a high glycemic index of {food.glycemic_index}, which can cause rapid blood sugar spikes.")
    
    if food.sugar > 10:
        details.append(f"It contains {food.sugar}g of sugar per serving, which is relatively high.")
    elif food.sugar > 5:
        details.append(f"It contains a moderate amount of sugar ({food.sugar}g per serving).")
    else:
        details.append(f"It's low in sugar ({food.sugar}g per serving).")
    
    if food.carbs > 30:
        details.append(f"With {food.carbs}g of carbs, this is a high-carb food that should be carefully portioned.")
    elif food.carbs > 15:
        details.append(f"It contains a moderate amount of carbs ({food.carbs}g).")
    else:
        details.append(f"It's relatively low in carbs ({food.carbs}g).")
    
    if food.protein > 15:
        details.append(f"It's high in protein ({food.protein}g), which is beneficial for steady blood sugar.")
    elif food.protein > 5:
        details.append(f"It contains a moderate amount of protein ({food.protein}g).")
    
    if food.fiber > 5 if hasattr(food, 'fiber') else False:
        details.append(f"It's high in fiber, which helps slow down sugar absorption.")
    
    return base_explanation + " ".join(details)

@router.get("/foods", response_model=List[Food])
async def list_foods():
    """
    Get a list of all foods in the database
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM foods ORDER BY name")
        foods_data = cursor.fetchall()
        
        conn.close()
        
        foods = []
        for food_data in foods_data:
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
            foods.append(food)
        
        return foods
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
