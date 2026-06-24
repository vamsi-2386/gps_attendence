from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np
from PIL import Image
import io
from typing import Optional

from src.pipelines.face_pipeline import predict_attendance
from src.database.db import get_all_employees, get_company_by_id, employee_gps_checkin, get_employee_attendance, get_subjects_for_employee, create_leave_request

app = FastAPI(title="Lumenor API")

# Configure CORS for mobile app access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Lumenor API is running"}

@app.post("/api/employee/login")
async def employee_login(photo: UploadFile = File(...)):
    """
    Login endpoint using FaceID. Receives an image and returns employee data if matched.
    """
    try:
        contents = await photo.read()
        image = Image.open(io.BytesIO(contents)).convert('RGB')
        img_np = np.array(image)
        
        detected, all_ids, num_faces = predict_attendance(img_np)
        
        if num_faces == 0:
            raise HTTPException(status_code=401, detail="Face not found")
        elif num_faces > 1:
            raise HTTPException(status_code=400, detail="Multiple faces found")
            
        if detected:
            employee_id = list(detected.keys())[0]
            decision = detected[employee_id]['decision']
            
            if decision == 'Accepted':
                all_employees = get_all_employees()
                employee = next((s for s in all_employees if s['employee_id'] == employee_id), None)
                if employee:
                    return {"status": "success", "employee": employee}
            elif decision == 'Review':
                raise HTTPException(status_code=403, detail="Identity match borderline. Flagged for review.")
            else:
                raise HTTPException(status_code=401, detail="Face match score too low.")
                
        raise HTTPException(status_code=401, detail="Face not recognized")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class CheckInRequest(BaseModel):
    employee_id: int
    subject_id: int
    latitude: float
    longitude: float
    status_text: str
    is_present: bool

@app.post("/api/employee/checkin")
def checkin(data: CheckInRequest):
    try:
        import datetime
        timestamp = datetime.datetime.now().isoformat()
        employee_gps_checkin(
            data.employee_id, 
            data.subject_id, 
            timestamp, 
            data.latitude, 
            data.longitude, 
            data.status_text, 
            data.is_present
        )
        return {"status": "success", "message": "Checked in successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/employee/{employee_id}/history")
def get_history(employee_id: int):
    try:
        logs = get_employee_attendance(employee_id)
        return {"status": "success", "logs": logs}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/employee/{employee_id}/projects")
def get_projects(employee_id: int):
    try:
        projects = get_subjects_for_employee(employee_id)
        return {"status": "success", "projects": projects}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class LeaveRequest(BaseModel):
    employee_id: int
    company_id: int
    start_date: str
    end_date: str
    reason: str

@app.post("/api/employee/leave")
def apply_leave(data: LeaveRequest):
    try:
        create_leave_request(
            data.employee_id,
            data.company_id,
            data.start_date,
            data.end_date,
            data.reason
        )
        return {"status": "success", "message": "Leave request submitted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
