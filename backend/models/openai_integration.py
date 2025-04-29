import os
import base64
import json
from typing import List, Dict, Any, Union

# The newest OpenAI model is "gpt-4o" which was released May 13, 2024.
# Do not change this unless explicitly requested by the user

try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    print("WARNING: OpenAI package not installed. Will use fallback methods.")

class OpenAIIntegration:
    def __init__(self):
        if not OPENAI_AVAILABLE:
            self.client = None
            return
            
        self.api_key = os.environ.get("OPENAI_API_KEY")
        if not self.api_key:
            print("WARNING: OpenAI API key not found in environment variables.")
            self.client = None
        else:
            self.client = OpenAI(api_key=self.api_key)
        
    def is_available(self) -> bool:
        """Check if OpenAI integration is available"""
        return self.client is not None
        
    def analyze_food_image(self, image_data: bytes) -> List[Dict[str, Any]]:
        """
        Analyze food image using OpenAI Vision.
        Returns list of food items with confidence scores.
        """
        if not self.is_available():
            return [{"food": "unknown", "confidence": 0.0, "error": "OpenAI API key not configured"}]
            
        try:
            # Convert image to base64
            base64_image = base64.b64encode(image_data).decode('utf-8')
            
            # Call OpenAI API
            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a nutritional expert specialized in identifying food items in images, "
                                   "particularly for diabetic patients. Analyze the image and identify all food items "
                                   "present. For each food item, provide a confidence score (between 0 and 1) of your "
                                   "identification. Return your analysis as a JSON array with objects containing 'food' "
                                   "and 'confidence' fields. Be specific - prefer detailed descriptions (e.g., 'grilled "
                                   "chicken breast' instead of just 'chicken'). Limit to maximum 3 main food items, "
                                   "from highest to lowest confidence."
                    },
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text", 
                                "text": "What food items do you see in this image? Return only JSON."
                            },
                            {
                                "type": "image_url",
                                "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}
                            }
                        ]
                    }
                ],
                response_format={"type": "json_object"},
                max_tokens=500,
            )
            
            # Extract and parse the response
            result = json.loads(response.choices[0].message.content)
            
            # Ensure response is in expected format 
            if isinstance(result, list):
                return result
            elif "results" in result:
                return result["results"]
            elif "foods" in result:
                return result["foods"]
            else:
                # Try to find any array in the response
                for key, value in result.items():
                    if isinstance(value, list) and len(value) > 0:
                        if isinstance(value[0], dict) and "food" in value[0]:
                            return value
                
                # Convert to expected format if needed
                foods = []
                for key, value in result.items():
                    if isinstance(value, (int, float)) and 0 <= value <= 1:
                        foods.append({"food": key, "confidence": value})
                
                if foods:
                    return foods
                    
                # Last resort, create a single entry with the whole response as an error
                return [{"food": "unidentified", "confidence": 0.5, "raw_response": str(result)}]
                
        except Exception as e:
            print(f"Error analyzing food image with OpenAI: {e}")
            return [{"food": "error", "confidence": 0.0, "error": str(e)}]

# Singleton instance
openai_integration = OpenAIIntegration()