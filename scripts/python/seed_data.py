
import json
import random
import datetime
import uuid

# Constants
FIRST_NAMES = [
    'Alex', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Avery', 'Quinn',
    'Parker', 'Cameron', 'Skyler', 'Blake', 'Drew', 'Reese', 'Dakota',
    'Sage', 'River', 'Phoenix', 'Rowan', 'Charlie', 'Sam', 'Jamie',
    'Hayden', 'Peyton', 'Emerson'
]

LAST_NAMES = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
    'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez',
    'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
    'Lee', 'Thompson', 'White', 'Harris', 'Clark'
]

BRANCHES = [
    'Computer Engineering',
    'Information Technology',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
    'Electronics & Telecom',
    'AI & DS'
]

BRANCH_CODES = ['CS', 'DS', 'EC', 'ME', 'CE', 'EE']

SEMESTER_NAMES = [
    'Fall 2021', 'Spring 2022', 'Fall 2022', 'Spring 2023',
    'Fall 2023', 'Spring 2024', 'Fall 2024'
]

SUBJECTS_POOL = [
    {'name': 'Mathematics IV', 'code': 'MTH-401', 'credits': 4},
    {'name': 'Database Systems', 'code': 'CS-302', 'credits': 3},
    {'name': 'Software Engineering', 'code': 'SE-201', 'credits': 3},
]

GRADES = ['A', 'A-', 'B+', 'B', 'B-', 'C+']

def get_branch_code(index):
    return BRANCH_CODES[index % len(BRANCH_CODES)]

def get_year_suffix(year):
    if year == 1: return 'st'
    if year == 2: return 'nd'
    if year == 3: return 'rd'
    return 'th'

def generate_subjects():
    subjects = []
    for subj in SUBJECTS_POOL:
        subjects.append({
            'name': subj['name'],
            'code': subj['code'],
            'credits': subj['credits'],
            'grade': random.choice(GRADES),
            'attendance': random.randint(70, 100)
        })
    return subjects

def generate_semesters(year):
    semesters = []
    num_semesters = year * 2
    for i in range(num_semesters):
        if i >= len(SEMESTER_NAMES): break
        
        cgpa = 2.5 + (random.random() * 1.5)
        attendance = 70 + random.randint(0, 30)
        
        semesters.append({
            'semesterName': SEMESTER_NAMES[i],
            'cgpa': round(cgpa, 2),
            'attendance': float(attendance),
            'subjects': generate_subjects()
        })
    return semesters

def main():
    students = []
    
    print("🌱 Generating 25 student records...")
    
    for i in range(1, 26):
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        name = f"{first_name} {last_name}"
        
        branch_code = get_branch_code(i)
        student_id = f"2024{branch_code}{str(i).zfill(4)}"
        email = f"{first_name.lower()}.{last_name.lower()}{i}@university.edu"
        password = "Test@123"
        user_id = str(uuid.uuid4())
        
        branch = BRANCHES[i % len(BRANCHES)]
        year = (i % 4) + 1
        passout_year = 2024 + (4 - year)
        
        phone = f"+1 (555) {random.randint(100, 999)}-{random.randint(1000, 9999)}"
        
        timestamp = datetime.datetime.now().isoformat()
        
        # Data generation
        cgpa = 2.5 + (random.random() * 1.5)
        attendance = 70 + random.randint(0, 30)
        family_income = random.randint(50000, 1500000)
        category = random.choice(['General', 'OBC', 'SC', 'ST', 'EWS'])
        
        student_data = {
            "userId": user_id,
            "email": email,
            "password": password,
            "role": "student",
            "studentUID": student_id,
            "profile": {
                "studentUID": student_id,
                "name": name,
                "email": email,
                "course": branch,
                "year": year,
                "category": category,
                "familyIncome": float(family_income),
                "cgpa": round(cgpa, 2),
                "attendance": float(attendance),
                "contactNumber": phone,
                "createdAt": timestamp,
                "updatedAt": timestamp
            },
            "academicInfo": {
                "course": branch,
                "year": year,
                "events": [], # Placeholder for events
                "updatedBy": "system",
                "updatedAt": timestamp
            }
        }
        
        students.append(student_data)
        print(f"✅ Generated: {name} ({student_id})")

    output_file = "students.json"
    with open(output_file, "w") as f:
        json.dump(students, f, indent=2)
        
    print(f"\n🎉 Successfully wrote {len(students)} records to {output_file}")

if __name__ == "__main__":
    main()
