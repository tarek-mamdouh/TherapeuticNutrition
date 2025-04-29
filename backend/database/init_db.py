import sqlite3
import os
import json

def get_db_connection():
    """Create a connection to the SQLite database"""
    db_path = os.path.join(os.path.dirname(__file__), 'diabetic_nutrition.db')
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn

def initialize_database():
    """Initialize the database with tables and sample data"""
    conn = get_db_connection()
    
    # Create tables
    conn.executescript('''
    CREATE TABLE IF NOT EXISTS foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_ar TEXT NOT NULL,
        calories REAL,
        carbs REAL,
        protein REAL,
        sugar REAL,
        fat REAL,
        glycemic_index INTEGER,
        diabetic_suitability TEXT
    );
    
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        diabetes_type TEXT,
        preferences TEXT
    );
    
    CREATE TABLE IF NOT EXISTS qa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        question_ar TEXT NOT NULL,
        answer TEXT NOT NULL,
        answer_ar TEXT NOT NULL,
        tags TEXT
    );
    ''')
    
    # Check if data already exists
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM foods")
    food_count = cursor.fetchone()[0]
    
    # Only populate if no data exists
    if food_count == 0:
        # Sample food data
        foods = [
            # Name, Name in Arabic, Calories, Carbs, Protein, Sugar, Fat, GI, Suitability
            ("Apple", "تفاحة", 52, 14, 0.3, 10, 0.2, 36, "Moderate"),
            ("Banana", "موزة", 96, 23, 1.1, 12, 0.2, 51, "Moderate"),
            ("Grilled Chicken Breast", "صدر دجاج مشوي", 165, 0, 31, 0, 3.6, 0, "Safe"),
            ("Brown Rice", "أرز بني", 112, 24, 2.3, 0.7, 0.8, 50, "Moderate"),
            ("White Bread", "خبز أبيض", 75, 13, 2.6, 1.3, 1, 75, "Avoid"),
            ("Oatmeal", "الشوفان", 68, 12, 2.5, 0.5, 1.5, 55, "Moderate"),
            ("Eggs", "بيض", 78, 0.6, 6.3, 0.6, 5.3, 0, "Safe"),
            ("Lentils", "عدس", 116, 20, 9, 1.8, 0.4, 29, "Safe"),
            ("Yogurt (plain)", "زبادي", 59, 5, 3.5, 4, 3, 35, "Safe"),
            ("Orange", "برتقال", 62, 15, 1.2, 12, 0.2, 43, "Moderate"),
            ("Dates", "تمر", 282, 75, 2.5, 63, 0.4, 103, "Avoid"),
            ("Watermelon", "بطيخ", 30, 8, 0.6, 6, 0.2, 76, "Avoid"),
            ("Potato", "بطاطا", 77, 17, 2, 1.2, 0.1, 85, "Avoid"),
            ("Sweet Potato", "بطاطا حلوة", 86, 20, 1.6, 4.2, 0.1, 54, "Moderate"),
            ("Spinach", "سبانخ", 23, 3.6, 2.9, 0.4, 0.4, 15, "Safe"),
            ("Broccoli", "بروكلي", 34, 7, 2.8, 1.7, 0.4, 15, "Safe"),
            ("Salmon", "سلمون", 208, 0, 20, 0, 13, 0, "Safe"),
            ("Avocado", "أفوكادو", 160, 8.5, 2, 0.7, 14.7, 15, "Safe"),
            ("Almonds", "لوز", 579, 22, 21, 4.2, 49.9, 15, "Safe"),
            ("Cheese", "جبن", 402, 1.3, 25, 0.1, 33, 0, "Safe"),
            ("White Rice", "أرز أبيض", 130, 28, 2.7, 0.1, 0.3, 73, "Avoid"),
            ("Pasta", "معكرونة", 131, 25, 5, 0.9, 1.1, 55, "Moderate"),
            ("Hummus", "حمص", 166, 14, 7.9, 0.4, 9.6, 6, "Safe"),
            ("Falafel", "فلافل", 333, 31, 13.3, 0, 17.8, 32, "Moderate"),
            ("Shawarma (Chicken)", "شاورما دجاج", 392, 41, 15, 0, 20, 42, "Moderate")
        ]
        
        cursor.executemany('''
        INSERT INTO foods (name, name_ar, calories, carbs, protein, sugar, fat, glycemic_index, diabetic_suitability) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', foods)
        
        # Sample QA data
        qa_data = [
            # Question, Question in Arabic, Answer, Answer in Arabic, Tags
            (
                "Can diabetics eat bananas?", 
                "هل يمكن لمرضى السكري تناول الموز؟",
                "Bananas can be consumed in moderation by diabetics. They have a moderate glycemic index (51), and contain fiber which helps slow sugar absorption. Limit to small or medium-sized bananas and consider pairing with protein.",
                "يمكن لمرضى السكري تناول الموز باعتدال. لديه مؤشر جلايسيمي معتدل (51)، ويحتوي على الألياف التي تساعد على إبطاء امتصاص السكر. حدد تناولك للموز صغير أو متوسط الحجم وفكر في تناوله مع البروتين.",
                "fruit,banana,glycemic index"
            ),
            (
                "What fruits are best for diabetics?", 
                "ما هي أفضل الفواكه لمرضى السكري؟",
                "Best fruits for diabetics include berries (strawberries, blueberries), apples, pears, oranges, and peaches. These have lower glycemic indexes and sugar content. Always eat in moderation and pair with protein when possible.",
                "أفضل الفواكه لمرضى السكري تشمل التوت (الفراولة، التوت الأزرق)، التفاح، الكمثرى، البرتقال، والخوخ. هذه الفواكه لها مؤشرات جلايسيمية وكمية سكر أقل. تناولها دائمًا باعتدال ومع البروتين إن أمكن.",
                "fruit,glycemic index,sugar"
            ),
            (
                "Is brown rice better than white rice for diabetics?", 
                "هل الأرز البني أفضل من الأرز الأبيض لمرضى السكري؟",
                "Yes, brown rice is better for diabetics than white rice. Brown rice has a lower glycemic index (50 vs. 73 for white rice), more fiber, and causes a slower rise in blood sugar. Still, portion control is important.",
                "نعم، الأرز البني أفضل لمرضى السكري من الأرز الأبيض. الأرز البني له مؤشر جلايسيمي أقل (50 مقابل 73 للأرز الأبيض)، وألياف أكثر، ويسبب ارتفاعًا أبطأ في نسبة السكر في الدم. ومع ذلك، ضبط الكمية مهم.",
                "rice,carbs,glycemic index"
            ),
            (
                "How many carbs should a diabetic eat per day?", 
                "كم عدد الكربوهيدرات التي يجب أن يتناولها مريض السكري يوميًا؟",
                "Carb needs vary by individual, but generally 45-60g per meal and 15-20g per snack is recommended. This is typically 130-230g total per day, depending on activity level, medications, and blood sugar control. Consult with your healthcare provider for personalized advice.",
                "تختلف احتياجات الكربوهيدرات حسب الفرد، ولكن بشكل عام يوصى بتناول 45-60 جرام لكل وجبة و15-20 جرام لكل وجبة خفيفة. هذا عادة 130-230 جرام إجمالي يوميًا، حسب مستوى النشاط والأدوية والتحكم في سكر الدم. استشر مقدم الرعاية الصحية للحصول على نصيحة شخصية.",
                "carbs,nutrition,daily"
            ),
            (
                "Can diabetics eat dates?", 
                "هل يمكن لمرضى السكري أكل التمر؟",
                "Dates should be limited or avoided by diabetics as they have very high sugar content and glycemic index (103). If consumed, limit to 1-2 dates occasionally and pair with protein. During Ramadan, consider alternatives for breaking fast.",
                "يجب تقييد أو تجنب التمر لمرضى السكري لأنه يحتوي على نسبة عالية جدًا من السكر ومؤشر جلايسيمي مرتفع (103). إذا تم تناوله، فحدد تناولك لـ 1-2 تمرة في بعض الأحيان وتناولها مع البروتين. أثناء رمضان، فكر في بدائل لكسر الصيام.",
                "dates,sugar,glycemic index,Ramadan"
            ),
            (
                "Is hummus good for diabetics?", 
                "هل الحمص جيد لمرضى السكري؟",
                "Yes, hummus is a good food choice for diabetics. Made from chickpeas, it's high in protein and fiber, has a low glycemic index (6), and helps regulate blood sugar. Use vegetable sticks instead of bread for dipping to reduce carb intake.",
                "نعم، الحمص هو خيار غذائي جيد لمرضى السكري. مصنوع من الحمص، وهو غني بالبروتين والألياف، وله مؤشر جلايسيمي منخفض (6)، ويساعد على تنظيم نسبة السكر في الدم. استخدم أعواد الخضار بدلاً من الخبز للغمس لتقليل تناول الكربوهيدرات.",
                "hummus,protein,fiber,middle eastern"
            ),
            (
                "What is the best breakfast for a diabetic?", 
                "ما هي أفضل وجبة إفطار لمريض السكري؟",
                "A balanced diabetic breakfast should include protein (eggs, Greek yogurt), healthy fats (avocado, nuts), and limited complex carbs (oatmeal, whole grain bread). Avoid fruit juices, sweet cereals, and pastries. Examples include eggs with vegetables, Greek yogurt with berries and nuts, or avocado toast on whole grain bread.",
                "يجب أن تشمل وجبة إفطار متوازنة لمريض السكري البروتين (البيض، الزبادي اليوناني)، والدهون الصحية (الأفوكادو، المكسرات)، والكربوهيدرات المعقدة المحدودة (الشوفان، خبز الحبوب الكاملة). تجنب عصائر الفاكهة والحبوب المحلاة والمعجنات. تشمل الأمثلة البيض مع الخضراوات، أو الزبادي اليوناني مع التوت والمكسرات، أو توست الأفوكادو على خبز الحبوب الكاملة.",
                "breakfast,protein,carbs,morning"
            ),
            (
                "How can I calculate carbs in my meal?", 
                "كيف يمكنني حساب الكربوهيدرات في وجبتي؟",
                "To calculate carbs: 1) Check nutrition labels for carb content, 2) Use measuring cups/scale for accurate portions, 3) Reference carb counting guides for foods without labels, 4) Use a food tracking app, 5) Remember to count total carbs, not just sugar. Most vegetables = 5g per serving, fruit = 15g, bread slice = 15g, rice/pasta (1/3 cup) = 15g.",
                "لحساب الكربوهيدرات: 1) تحقق من ملصقات التغذية لمعرفة محتوى الكربوهيدرات، 2) استخدم أكواب القياس/الميزان للحصول على حصص دقيقة، 3) راجع أدلة حساب الكربوهيدرات للأطعمة بدون ملصقات، 4) استخدم تطبيق تتبع الطعام، 5) تذكر حساب إجمالي الكربوهيدرات، وليس السكر فقط. معظم الخضراوات = 5 جرام لكل حصة، الفاكهة = 15 جرام، شريحة الخبز = 15 جرام، الأرز/المعكرونة (1/3 كوب) = 15 جرام.",
                "carbs,counting,measurement,nutrition"
            ),
            (
                "What should I eat when my blood sugar is high?", 
                "ماذا يجب أن آكل عندما يكون مستوى السكر في الدم مرتفعًا؟",
                "When blood sugar is high: 1) Drink water to help flush excess sugar, 2) Avoid all carbs and sugars, 3) Eat protein (chicken, eggs, tofu) and non-starchy vegetables (greens, broccoli, peppers), 4) Consider healthy fats like avocado or nuts, 5) Take medication as prescribed. Most importantly, follow your doctor's emergency plan if levels are dangerous.",
                "عندما يكون مستوى السكر في الدم مرتفعًا: 1) اشرب الماء للمساعدة في إزالة السكر الزائد، 2) تجنب جميع الكربوهيدرات والسكريات، 3) تناول البروتين (الدجاج، البيض، التوفو) والخضروات غير النشوية (الخضر، البروكلي، الفلفل)، 4) فكر في الدهون الصحية مثل الأفوكادو أو المكسرات، 5) تناول الدواء كما هو موصوف. الأهم من ذلك، اتبع خطة الطوارئ الخاصة بطبيبك إذا كانت المستويات خطيرة.",
                "high blood sugar,emergency,protein,water"
            ),
            (
                "Is fasting good for diabetics?", 
                "هل الصيام جيد لمرضى السكري؟",
                "Fasting effects vary by diabetes type and treatment. Some studies show intermittent fasting may improve insulin sensitivity for Type 2 diabetes, but it can be dangerous for Type 1 or those on insulin/sulfonylureas due to hypoglycemia risk. Ramadan fasting requires special precautions. Always consult your doctor before starting any fasting regimen.",
                "تختلف آثار الصيام حسب نوع السكري والعلاج. تظهر بعض الدراسات أن الصيام المتقطع قد يحسن حساسية الأنسولين لمرضى السكري من النوع 2، ولكنه يمكن أن يكون خطيرًا للنوع 1 أو الذين يتناولون الأنسولين/السلفونيل يوريا بسبب خطر انخفاض نسبة السكر في الدم. يتطلب صيام رمضان احتياطات خاصة. استشر طبيبك دائمًا قبل البدء في أي نظام صيام.",
                "fasting,Ramadan,insulin,blood sugar"
            )
        ]
        
        cursor.executemany('''
        INSERT INTO qa (question, question_ar, answer, answer_ar, tags) 
        VALUES (?, ?, ?, ?, ?)
        ''', qa_data)
        
        conn.commit()
    
    conn.close()

if __name__ == "__main__":
    initialize_database()
