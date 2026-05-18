from contextlib import contextmanager
from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Optional
import pyodbc

CONNECTION_STRING = (
    'DRIVER={ODBC Driver 18 for SQL Server};'
    'SERVER=.;'
    'DATABASE=clinical_system;'
    'Trusted_Connection=yes;'
    'TrustServerCertificate=yes;'
)

app = FastAPI()


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for error in exc.errors():
        locs = [str(loc) for loc in error["loc"] if loc != "body"]
        field = " → ".join(locs) if locs else None
        msg = error["msg"]
        errors.append(f"{field}: {msg}" if field else msg)
    return JSONResponse(
        status_code=422,
        content={"detail": "; ".join(errors)},
    )


@contextmanager
def db(autocommit=True):
    conn = pyodbc.connect(CONNECTION_STRING)
    conn.autocommit = autocommit
    try:
        yield conn
        if not autocommit:
            conn.commit()
    except Exception:
        if not autocommit:
            conn.rollback()
        raise
    finally:
        conn.close()

# ── Pydantic models ────────────────────────────────────────────────────────────

class BranchIn(BaseModel):
    branch_name: str


class ScheduleIn(BaseModel):
    day_of_week: str
    start_time: str           # e.g. "09:00:00"
    end_time: str             # e.g. "14:00:00"
    branch_id: Optional[int] = None
    is_active: bool = True


class ServiceIn(BaseModel):
    service_name: str          # e.g. "كشف", "استشارة"
    price: float
    doctor_commission_percentage: Optional[float] = 70.0


class DoctorIn(BaseModel):
    doctor_name: str
    specialty: str
    doctor_phone_number: str
    branches: List[int]            # list of branch_ids
    doctor_balance: float = 0.0
    schedules: List[ScheduleIn] = []
    services: List[ServiceIn] = []


class DoctorUpdate(BaseModel):
    doctor_name: Optional[str] = None
    specialty: Optional[str] = None
    doctor_phone_number: Optional[str] = None
    branches: Optional[List[int]] = None   # if provided, replaces all existing branch links
    doctor_balance: Optional[float] = None
    schedules: Optional[List[ScheduleIn]] = None  # if provided, replaces all existing schedules
    services: Optional[List[ServiceIn]] = None    # if provided, replaces all existing services


class PatientIn(BaseModel):
    patient_name: str
    phone: str
    birth_date: Optional[str] = None  # e.g. "1990-05-20"


class ExaminationIn(BaseModel):
    doctor_id: int
    patient: PatientIn
    service_id: int        # links to doctor_services; price is derived from the service
    branch_id: int
    exam_date: str         # e.g. "2026-03-28 10:00:00"
    exam_number: str
    status: str = "مؤقت"


class ExaminationUpdate(BaseModel):
    doctor_id: Optional[int] = None
    service_id: Optional[int] = None
    branch_id: Optional[int] = None
    exam_date: Optional[str] = None
    exam_number: Optional[str] = None
    status: Optional[str] = None


class SystemUserIn(BaseModel):
    username: str
    role: str
    password: str


class SystemUserUpdate(BaseModel):
    role: Optional[str] = None
    password: Optional[str] = None


class ActionIn(BaseModel):
    username: str
    action_description: str


class PurchaseLineIn(BaseModel):
    name: str
    price: float
    quantity: float


class PurchaseIn(BaseModel):
    username: str
    description: Optional[str] = None
    category_id: int
    status: str = "مديونية"
    branch_id: int
    created_date: Optional[str] = None
    lines: List[PurchaseLineIn]


class PurchaseUpdate(BaseModel):
    username: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None
    status: Optional[str] = None
    branch_id: Optional[int] = None
    lines: Optional[List[PurchaseLineIn]] = None


class InvoiceIn(BaseModel):
    username: str
    name: str
    price: float
    branch_id: int
    description: Optional[str] = None
    status: str = "مديونية"
    category_id: int
    created_date: Optional[str] = None


class InvoiceUpdate(BaseModel):
    username: Optional[str] = None
    name: Optional[str] = None
    price: Optional[float] = None
    branch_id: Optional[int] = None
    description: Optional[str] = None
    status: Optional[str] = None
    category_id: Optional[int] = None


class DebtUpdate(BaseModel):
    amount: Optional[float] = None
    payment_date: Optional[str] = None
    description: Optional[str] = None


class TreasuryUpdate(BaseModel):
    amount: Optional[float] = None
    transaction_type: Optional[str] = None
    description: Optional[str] = None


# ── Routes ─────────────────────────────────────────────────────────────────────
@app.get("/")
async def root():
    return {
        "message": "Clinical System API is running",
        "docs": "/docs"
    }
@app.get("/branches")
async def get_branches():
    with db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT b.branch_id, b.branch_name, COUNT(db.doctor_id) AS doctor_count
            FROM branches b
            LEFT JOIN doctor_branches db ON b.branch_id = db.branch_id
            GROUP BY b.branch_id, b.branch_name
            ORDER BY b.branch_name
        """)
        return [{"branch_id": row[0], "branch_name": row[1], "doctor_count": row[2]} for row in cursor.fetchall()]


@app.post("/add_branches")
async def create_branch(data: BranchIn):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO branches (branch_name) OUTPUT INSERTED.branch_id VALUES (?)",
            (data.branch_name,)
        )
        branch_id = cursor.fetchone()[0]
    return {"branch_id": branch_id, "branch_name": data.branch_name}


@app.put("/edit_branch/{branch_id}")
async def update_branch(branch_id: int, data: BranchIn):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT branch_id FROM branches WHERE branch_id = ?", (branch_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Branch {branch_id} not found")
        cursor.execute(
            "UPDATE branches SET branch_name = ? WHERE branch_id = ?",
            (data.branch_name, branch_id)
        )
    return {"branch_id": branch_id, "branch_name": data.branch_name}


@app.delete("/delete_branch/{branch_id}")
async def delete_branch(branch_id: int):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT branch_id FROM branches WHERE branch_id = ?", (branch_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Branch {branch_id} not found")
        cursor.execute("DELETE FROM branches WHERE branch_id = ?", (branch_id,))
    return {"message": f"Branch {branch_id} deleted successfully"}


@app.get("/specialties")
async def get_specialties():
    with db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT DISTINCT specialty FROM doctors ORDER BY specialty")
        return {"specialties": [row[0] for row in cursor.fetchall()]}


@app.get("/all_doctors")
async def get_all_doctors(branch: str = None, specialty: str = None):
    with db() as conn:
        cursor = conn.cursor()

        filters = []
        params = []

        if branch:
            filters.append("EXISTS (SELECT 1 FROM doctor_branches db2 JOIN branches b2 ON db2.branch_id = b2.branch_id WHERE db2.doctor_id = d.doctor_id AND b2.branch_name = ?)")
            params.append(branch)

        if specialty:
            filters.append("d.specialty = ?")
            params.append(specialty)

        where_clause = ("WHERE " + " AND ".join(filters)) if filters else ""

        cursor.execute(f"""
            SELECT d.doctor_id, d.doctor_name, d.specialty, d.doctor_phone_number, d.doctor_balance,
                   STRING_AGG(b.branch_name, ',') AS branches
            FROM doctors d
            LEFT JOIN doctor_branches db ON d.doctor_id = db.doctor_id
            LEFT JOIN branches b ON db.branch_id = b.branch_id
            {where_clause}
            GROUP BY d.doctor_id, d.doctor_name, d.specialty, d.doctor_phone_number, d.doctor_balance
            ORDER BY d.doctor_id
        """, params)

        columns = [col[0] for col in cursor.description]
        doctors = []
        doctor_index = {}
        for row in cursor.fetchall():
            doc = dict(zip(columns, row))
            doc["branches"] = doc["branches"].split(",") if doc["branches"] else []
            doc["schedules"] = []
            doc["services"] = []
            doctor_index[doc["doctor_id"]] = doc
            doctors.append(doc)

        if doctors:
            doctor_ids = list(doctor_index.keys())
            placeholders = ",".join("?" * len(doctor_ids))

            cursor.execute(f"""
                SELECT s.doctor_id, s.day_of_week, s.start_time, s.end_time,
                       s.branch_id, b.branch_name, s.is_active
                FROM doctor_schedules s
                LEFT JOIN branches b ON s.branch_id = b.branch_id
                WHERE s.doctor_id IN ({placeholders})
                ORDER BY s.doctor_id, s.schedule_id
            """, doctor_ids)
            for row in cursor.fetchall():
                doc_id, day, start, end, branch_id, branch_name, is_active = row
                doctor_index[doc_id]["schedules"].append({
                    "day_of_week": day,
                    "start_time": str(start),
                    "end_time": str(end),
                    "branch_id": branch_id,
                    "branch_name": branch_name,
                    "is_active": bool(is_active),
                })

            cursor.execute(f"""
                SELECT doctor_id, service_id, service_name, price, doctor_commission_percentage
                FROM doctor_services
                WHERE doctor_id IN ({placeholders})
                ORDER BY doctor_id, service_id
            """, doctor_ids)
            for row in cursor.fetchall():
                doc_id, service_id, service_name, price, commission = row
                doctor_index[doc_id]["services"].append({
                    "service_id": service_id,
                    "service_name": service_name,
                    "price": float(price),
                    "doctor_commission_percentage": float(commission),
                })

        return doctors


@app.post("/add_doctor_schedules")
async def add_doctor_schedules(doctor_id: int, schedules: List[ScheduleIn]):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT doctor_id FROM doctors WHERE doctor_id = ?", (doctor_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Doctor {doctor_id} not found")
        for s in schedules:
            cursor.execute("""
                INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time, branch_id, is_active)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (doctor_id, s.day_of_week, s.start_time, s.end_time, s.branch_id, int(s.is_active)))
    return {"message": f"Schedules added successfully to doctor {doctor_id}"}


@app.get("/doctor_services/{doctor_id}")
async def get_doctor_services(doctor_id: int):
    with db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT doctor_id FROM doctors WHERE doctor_id = ?", (doctor_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Doctor {doctor_id} not found")
        cursor.execute("""
            SELECT service_id, service_name, price, doctor_commission_percentage
            FROM doctor_services
            WHERE doctor_id = ?
            ORDER BY service_id
        """, (doctor_id,))
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.post("/add_doctor_services")
async def add_doctor_services(doctor_id: int, services: List[ServiceIn]):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT doctor_id FROM doctors WHERE doctor_id = ?", (doctor_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Doctor {doctor_id} not found")
        for svc in services:
            cursor.execute("""
                INSERT INTO doctor_services (doctor_id, service_name, price, doctor_commission_percentage)
                VALUES (?, ?, ?, ?)
            """, (doctor_id, svc.service_name, svc.price, svc.doctor_commission_percentage))
    return {"message": f"Services added successfully to doctor {doctor_id}"}


@app.put("/edit_doctor_service/{service_id}")
async def edit_doctor_service(service_id: int, data: ServiceIn):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT service_id FROM doctor_services WHERE service_id = ?", (service_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Service {service_id} not found")
        cursor.execute("""
            UPDATE doctor_services SET service_name = ?, price = ?, doctor_commission_percentage = ?
            WHERE service_id = ?
        """, (data.service_name, data.price, data.doctor_commission_percentage, service_id))
    return {"message": f"Service {service_id} updated successfully"}


@app.delete("/delete_doctor_service/{service_id}")
async def delete_doctor_service(service_id: int):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT service_id FROM doctor_services WHERE service_id = ?", (service_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Service {service_id} not found")
        cursor.execute("DELETE FROM doctor_services WHERE service_id = ?", (service_id,))
    return {"message": f"Service {service_id} deleted successfully"}


@app.get("/doctor_schedules")
async def get_doctor_schedules(day: str = None, specialty: str = None, branch: str = None):
    with db() as conn:
        cursor = conn.cursor()

        filters = ["s.is_active = 1"]
        params = []

        if day:
            filters.append("s.day_of_week = ?")
            params.append(day)
        if specialty:
            filters.append("d.specialty = ?")
            params.append(specialty)
        if branch:
            filters.append("b.branch_name = ?")
            params.append(branch)

        cursor.execute(f"""
            SELECT d.doctor_id, d.doctor_name, d.specialty,
                   s.day_of_week, s.start_time, s.end_time,
                   s.branch_id, b.branch_name
            FROM doctors d
            JOIN doctor_schedules s ON d.doctor_id = s.doctor_id
            LEFT JOIN branches b ON s.branch_id = b.branch_id
            WHERE {" AND ".join(filters)}
        """, params)

        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.post("/generate_doctor", status_code=201)
async def create_doctor(doctor: DoctorIn):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO doctors (doctor_name, specialty, doctor_phone_number, doctor_balance)
            OUTPUT INSERTED.doctor_id
            VALUES (?, ?, ?, ?)
        """, (doctor.doctor_name, doctor.specialty, doctor.doctor_phone_number, doctor.doctor_balance))
        doctor_id = cursor.fetchone()[0]

        for branch_id in doctor.branches:
            cursor.execute(
                "INSERT INTO doctor_branches (doctor_id, branch_id) VALUES (?, ?)",
                (doctor_id, branch_id),
            )

        for s in doctor.schedules:
            cursor.execute("""
                INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time, branch_id, is_active)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (doctor_id, s.day_of_week, s.start_time, s.end_time, s.branch_id, int(s.is_active)))

        for svc in doctor.services:
            cursor.execute("""
                INSERT INTO doctor_services (doctor_id, service_name, price, doctor_commission_percentage)
                VALUES (?, ?, ?, ?)
            """, (doctor_id, svc.service_name, svc.price, svc.doctor_commission_percentage))

        return {"doctor_id": doctor_id, "message": "Doctor created successfully"}


@app.put("/doctor_edit/{doctor_id}")
async def update_doctor(doctor_id: int, data: DoctorUpdate):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT doctor_id FROM doctors WHERE doctor_id = ?", (doctor_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Doctor {doctor_id} not found")

        fields = {
            "doctor_name":    data.doctor_name,
            "specialty":      data.specialty,
            "doctor_phone_number":  data.doctor_phone_number,
            "doctor_balance": data.doctor_balance,
        }
        updates = {k: v for k, v in fields.items() if v is not None}
        if updates:
            set_clause = ", ".join(f"{col} = ?" for col in updates)
            cursor.execute(
                f"UPDATE doctors SET {set_clause} WHERE doctor_id = ?",
                list(updates.values()) + [doctor_id],
            )

        if data.branches is not None:
            cursor.execute("DELETE FROM doctor_branches WHERE doctor_id = ?", (doctor_id,))
            for branch_id in data.branches:
                cursor.execute(
                    "INSERT INTO doctor_branches (doctor_id, branch_id) VALUES (?, ?)",
                    (doctor_id, branch_id),
                )

        if data.schedules is not None:
            cursor.execute("DELETE FROM doctor_schedules WHERE doctor_id = ?", (doctor_id,))
            for s in data.schedules:
                cursor.execute("""
                    INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time, branch_id, is_active)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (doctor_id, s.day_of_week, s.start_time, s.end_time, s.branch_id, int(s.is_active)))

        if data.services is not None:
            cursor.execute("DELETE FROM doctor_services WHERE doctor_id = ?", (doctor_id,))
            for svc in data.services:
                cursor.execute("""
                    INSERT INTO doctor_services (doctor_id, service_name, price, doctor_commission_percentage)
                    VALUES (?, ?, ?, ?)
                """, (doctor_id, svc.service_name, svc.price, svc.doctor_commission_percentage))

        return {"message": f"Doctor {doctor_id} updated successfully"}


@app.delete("/doctor_delete/{doctor_id}")
async def delete_doctor(doctor_id: int):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT doctor_id FROM doctors WHERE doctor_id = ?", (doctor_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Doctor {doctor_id} not found")

        # doctor_branches, doctor_schedules, doctor_services, and examinations
        # are all deleted automatically via ON DELETE CASCADE
        cursor.execute("DELETE FROM doctors WHERE doctor_id = ?", (doctor_id,))

        return {"message": f"Doctor {doctor_id} deleted successfully"}


@app.get("/patients")
async def get_patients():
    with db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT patient_id, patient_name, phone, branch_id, birth_date
            FROM patients
            ORDER BY patient_id
        """)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.post("/generate_examination", status_code=201)
async def create_examination(data: ExaminationIn):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT doctor_id FROM doctors WHERE doctor_id = ?", (data.doctor_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Doctor {data.doctor_id} not found")

        cursor.execute(
            "SELECT service_id FROM doctor_services WHERE service_id = ? AND doctor_id = ?",
            (data.service_id, data.doctor_id)
        )
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Service {data.service_id} not found for doctor {data.doctor_id}")

        cursor.execute("SELECT patient_id FROM patients WHERE phone = ?", (data.patient.phone,))
        row = cursor.fetchone()
        if row:
            patient_id = row[0]
            patient_created = False
        else:
            cursor.execute("""
                INSERT INTO patients (patient_name, phone, birth_date)
                OUTPUT INSERTED.patient_id
                VALUES (?, ?, ?)
            """, (data.patient.patient_name, data.patient.phone,
                  data.patient.birth_date))
            patient_id = cursor.fetchone()[0]
            patient_created = True

        cursor.execute("SELECT branch_id FROM branches WHERE branch_id = ?", (data.branch_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Branch {data.branch_id} not found")

        cursor.execute("""
            INSERT INTO examinations (doctor_id, patient_id, service_id, branch_id, exam_date, exam_number, status)
            OUTPUT INSERTED.exam_id
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (data.doctor_id, patient_id, data.service_id, data.branch_id,
              data.exam_date, data.exam_number, data.status))
        exam_id = cursor.fetchone()[0]

        return {
            "exam_id": exam_id,
            "patient_id": patient_id,
            "patient_created": patient_created,
            "message": "Examination created successfully",
        }


@app.get("/examinations")
async def get_examinations(status: str = None, date: str = None, doctor_name: str = None):
    with db() as conn:
        cursor = conn.cursor()

        filters = []
        params = []
        if status:
            filters.append("e.status = ?")
            params.append(status)
        if date:
            filters.append("CAST(e.exam_date AS DATE) = ?")
            params.append(date)
        if doctor_name:
            filters.append("d.doctor_name LIKE ?")
            params.append(f"%{doctor_name}%")

        where_clause = ("WHERE " + " AND ".join(filters)) if filters else ""
        cursor.execute(f"""
            SELECT e.exam_id, e.exam_number, e.exam_date, e.status,
                   svc.service_id, svc.service_name, svc.price,
                   d.doctor_name, d.specialty,
                   p.patient_name, p.phone,
                   e.branch_id, b.branch_name
            FROM examinations e
            JOIN doctors d ON e.doctor_id = d.doctor_id
            JOIN patients p ON e.patient_id = p.patient_id
            JOIN doctor_services svc ON e.service_id = svc.service_id
            JOIN branches b ON e.branch_id = b.branch_id
            {where_clause}
            ORDER BY e.exam_date DESC
        """, params)

        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.put("/exam_edit/{exam_id}")
async def update_examination(exam_id: int, data: ExaminationUpdate):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT exam_id FROM examinations WHERE exam_id = ?", (exam_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Examination {exam_id} not found")

        if data.doctor_id is not None:
            cursor.execute("SELECT doctor_id FROM doctors WHERE doctor_id = ?", (data.doctor_id,))
            if not cursor.fetchone():
                raise HTTPException(status_code=404, detail=f"Doctor {data.doctor_id} not found")

        fields = {
            "doctor_id":   data.doctor_id,
            "service_id":  data.service_id,
            "branch_id":   data.branch_id,
            "exam_date":   data.exam_date,
            "exam_number": data.exam_number,
            "status":      data.status,
        }
        updates = {k: v for k, v in fields.items() if v is not None}
        if updates:
            set_clause = ", ".join(f"{col} = ?" for col in updates)
            cursor.execute(
                f"UPDATE examinations SET {set_clause} WHERE exam_id = ?",
                list(updates.values()) + [exam_id],
            )

        return {"message": f"Examination {exam_id} updated successfully"}


@app.put("/exam_confirm/{exam_id}")
async def confirm_examination(exam_id: int, username: str = None):
    if not username:
        raise HTTPException(status_code=422, detail="username is required")
    with db(autocommit=False) as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT exam_id, status, branch_id FROM examinations WHERE exam_id = ?", (exam_id,))
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail=f"Examination {exam_id} not found")
        if row[1] == 'مؤكد':
            raise HTTPException(status_code=409, detail=f"Examination {exam_id} is already confirmed")
        branch_id = row[2]

        cursor.execute("""
            SELECT ds.price, ds.doctor_commission_percentage, p.patient_name, ds.service_name, d.doctor_name
            FROM examinations e
            JOIN doctor_services ds ON e.service_id = ds.service_id
            JOIN patients p ON e.patient_id = p.patient_id
            JOIN doctors d ON e.doctor_id = d.doctor_id
            WHERE e.exam_id = ?
        """, (exam_id,))
        detail_row = cursor.fetchone()
        if not detail_row:
            raise HTTPException(status_code=404, detail=f"Service not found for examination {exam_id}")
        price, commission_pct, patient_name, service_name, doctor_name = detail_row
        commission_amount = float(price) * (float(commission_pct) / 100)

        cursor.execute("SELECT category_id FROM expense_categories WHERE category_name = N'زيارات'")
        cat_row = cursor.fetchone()
        if not cat_row:
            raise HTTPException(status_code=404, detail="Expense category 'زيارات' not found")
        category_id = cat_row[0]

        debt_desc = f"عمولة طبيب - كشف #{exam_id} - طبيب: {doctor_name} - مريض: {patient_name} - خدمة: {service_name} ({commission_pct}%)"
        treasury_desc = f"تأكيد كشف #{exam_id} - مريض: {patient_name} - خدمة: {service_name}"

        cursor.execute("UPDATE examinations SET status = N'مؤكد' WHERE exam_id = ?", (exam_id,))

        cursor.execute("""
            INSERT INTO debts (amount, status, username, category_id, branch_id, exam_id, purchase_id, invoice_id, description)
            OUTPUT INSERTED.debt_id
            VALUES (?, N'مديونية', ?, ?, ?, ?, NULL, NULL, ?)
        """, (commission_amount, username, category_id, branch_id, exam_id, debt_desc))
        debt_id = cursor.fetchone()[0]

        cursor.execute("""
            INSERT INTO treasury (amount, transaction_type, username, category_id, branch_id, description)
            OUTPUT INSERTED.treasury_id
            VALUES (?, N'دخل', ?, ?, ?, ?)
        """, (price, username, category_id, branch_id, treasury_desc))
        treasury_id = cursor.fetchone()[0]

        return {
            "exam_id": exam_id,
            "debt_id": debt_id,
            "treasury_id": treasury_id,
            "amount": float(price),
            "message": f"Examination {exam_id} confirmed successfully",
        }


@app.put("/exam_cancel/{exam_id}")
async def cancel_examination(exam_id: int):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT exam_id FROM examinations WHERE exam_id = ?", (exam_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Examination {exam_id} not found")

        cursor.execute("UPDATE examinations SET status = N'ملغي' WHERE exam_id = ?", (exam_id,))
        return {"message": f"Examination {exam_id} cancelled successfully"}


# ── Debts ─────────────────────────────────────────────────────────────────────

@app.get("/debts")
async def get_debts(
    created_date: str = None,
    payment_date: str = None,
    status: str = None,
    username: str = None,
    branch_id: int = None,
):
    with db() as conn:
        cursor = conn.cursor()

        filters = []
        params = []

        if created_date:
            filters.append("CONVERT(NVARCHAR, d.creation_date, 23) LIKE ?")
            params.append(f"{created_date}%")
        if payment_date:
            filters.append("CONVERT(NVARCHAR, d.payment_date, 23) LIKE ?")
            params.append(f"{payment_date}%")
        if status:
            filters.append("d.status = ?")
            params.append(status)
        if username:
            filters.append("d.username = ?")
            params.append(username)
        if branch_id is not None:
            filters.append("d.branch_id = ?")
            params.append(branch_id)

        where_clause = ("WHERE " + " AND ".join(filters)) if filters else ""

        cursor.execute(f"""
            SELECT d.debt_id, d.creation_date, d.payment_date, d.amount, d.status,
                   d.username, d.category_id, ec.category_name,
                   d.branch_id, b.branch_name,
                   d.purchase_id, d.exam_id, d.invoice_id, d.description
            FROM debts d
            JOIN expense_categories ec ON d.category_id = ec.category_id
            JOIN branches b ON d.branch_id = b.branch_id
            {where_clause}
            ORDER BY d.creation_date DESC
        """, params)

        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.get("/debts/total")
async def get_debts_total():
    with db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT
                ISNULL(SUM(CASE WHEN status = N'مديونية'  THEN amount ELSE 0 END), 0),
                ISNULL(SUM(CASE WHEN status = N'تم السداد' THEN amount ELSE 0 END), 0),
                ISNULL(SUM(amount), 0)
            FROM debts
        """)
        row = cursor.fetchone()
        return {
            "total_outstanding": float(row[0]),
            "total_paid":        float(row[1]),
            "total_debts":       float(row[2]),
        }


@app.put("/debt_pay/{debt_id}")
async def pay_debt(debt_id: int, username: str):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()

        cursor.execute(
            "SELECT debt_id, amount, status, category_id, branch_id, exam_id, purchase_id, invoice_id FROM debts WHERE debt_id = ?",
            (debt_id,)
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail=f"Debt {debt_id} not found")
        _, amount, status, category_id, branch_id, exam_id, purchase_id, invoice_id = row
        if status == "تم السداد":
            raise HTTPException(status_code=409, detail=f"Debt {debt_id} is already paid")

        # all debt payments are expenses (خرج) — exam_confirm already recorded the دخل
        transaction_type = "خرج"

        # for exam debts, treasury amount = doctor's commission share only; also build description
        if exam_id is not None:
            cursor.execute("""
                SELECT p.patient_name, ds.service_name
                FROM examinations e
                JOIN doctor_services ds ON e.service_id = ds.service_id
                JOIN patients p ON e.patient_id = p.patient_id
                WHERE e.exam_id = ?
            """, (exam_id,))
            comm_row = cursor.fetchone()
            treasury_amount = float(amount)  # debt.amount is already price × commission% from exam_confirm
            if comm_row:
                treasury_desc = f"سداد عمولة كشف #{exam_id} - مريض: {comm_row[0]} - خدمة: {comm_row[1]}"
            else:
                treasury_desc = f"سداد دين كشف #{exam_id}"
        elif purchase_id is not None:
            treasury_amount = float(amount)
            cursor.execute("SELECT description FROM purchases WHERE purchase_id = ?", (purchase_id,))
            p_row = cursor.fetchone()
            p_desc = p_row[0] or '' if p_row else ''
            treasury_desc = f"سداد مشتريات #{purchase_id}" + (f" - {p_desc}" if p_desc else "")
        else:
            treasury_amount = float(amount)
            cursor.execute("SELECT name FROM invoices WHERE invoice_id = ?", (invoice_id,))
            i_row = cursor.fetchone()
            invoice_name = i_row[0] if i_row else ''
            treasury_desc = f"سداد فاتورة #{invoice_id} - {invoice_name}"

        cursor.execute(
            "UPDATE debts SET status = N'تم السداد', payment_date = SYSDATETIME() WHERE debt_id = ?",
            (debt_id,)
        )
        cursor.execute("""
            INSERT INTO treasury (amount, transaction_type, username, category_id, branch_id, description)
            OUTPUT INSERTED.treasury_id
            VALUES (?, ?, ?, ?, ?, ?)
        """, (treasury_amount, transaction_type, username, category_id, branch_id, treasury_desc))
        treasury_id = cursor.fetchone()[0]

        if exam_id is not None:
            cursor.execute("""
                UPDATE doctors SET doctor_balance = doctor_balance + ?
                WHERE doctor_id = (SELECT doctor_id FROM examinations WHERE exam_id = ?)
            """, (treasury_amount, exam_id))
        elif purchase_id is not None:
            cursor.execute(
                "UPDATE purchases SET status = N'تم السداد' WHERE purchase_id = ?",
                (purchase_id,)
            )
        elif invoice_id is not None:
            cursor.execute(
                "UPDATE invoices SET status = N'تم السداد' WHERE invoice_id = ?",
                (invoice_id,)
            )

    return {
        "debt_id": debt_id,
        "treasury_id": treasury_id,
        "full_amount": float(amount),
        "treasury_amount": treasury_amount,
        "transaction_type": transaction_type,
        "message": f"Debt {debt_id} paid successfully",
    }


@app.put("/debts/{debt_id}")
async def update_debt(debt_id: int, data: DebtUpdate):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT debt_id FROM debts WHERE debt_id = ?", (debt_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Debt {debt_id} not found")
        fields = {"amount": data.amount, "payment_date": data.payment_date, "description": data.description}
        updates = {k: v for k, v in fields.items() if v is not None}
        if updates:
            set_clause = ", ".join(f"{col} = ?" for col in updates)
            cursor.execute(
                f"UPDATE debts SET {set_clause} WHERE debt_id = ?",
                list(updates.values()) + [debt_id],
            )
    return {"message": f"Debt {debt_id} updated successfully"}


@app.delete("/debts/{debt_id}")
async def delete_debt(debt_id: int):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT debt_id FROM debts WHERE debt_id = ?", (debt_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Debt {debt_id} not found")
        cursor.execute("DELETE FROM debts WHERE debt_id = ?", (debt_id,))
    return {"message": f"Debt {debt_id} deleted successfully"}


# ── Treasury ──────────────────────────────────────────────────────────────────

@app.get("/treasury")
async def get_treasury(
    created_date: str = None,
    transaction_type: str = None,
    username: str = None,
    branch_id: int = None,
):
    with db() as conn:
        cursor = conn.cursor()

        filters = []
        params = []

        if created_date:
            filters.append("CONVERT(NVARCHAR, t.creation_date, 23) LIKE ?")
            params.append(f"{created_date}%")
        if transaction_type:
            filters.append("t.transaction_type = ?")
            params.append(transaction_type)
        if username:
            filters.append("t.username = ?")
            params.append(username)
        if branch_id is not None:
            filters.append("t.branch_id = ?")
            params.append(branch_id)

        where_clause = ("WHERE " + " AND ".join(filters)) if filters else ""

        cursor.execute(f"""
            SELECT t.treasury_id, t.creation_date, t.amount, t.transaction_type,
                   t.username, t.category_id, ec.category_name,
                   t.branch_id, b.branch_name, t.description
            FROM treasury t
            JOIN expense_categories ec ON t.category_id = ec.category_id
            JOIN branches b ON t.branch_id = b.branch_id
            {where_clause}
            ORDER BY t.creation_date DESC
        """, params)

        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.get("/treasury/total")
async def get_treasury_total():
    with db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT ISNULL(SUM(amount), 0)
            FROM treasury
            WHERE transaction_type = N'دخل'
        """)
        total_income = float(cursor.fetchone()[0])
        cursor.execute("""
            SELECT ISNULL(SUM(amount), 0)
            FROM debts
            WHERE status = N'تم السداد'
        """)
        total_expense = float(cursor.fetchone()[0])
        return {
            "total_income": total_income,
            "total_expense": total_expense,
            "balance": total_income - total_expense,
        }


@app.put("/treasury/{treasury_id}")
async def update_treasury(treasury_id: int, data: TreasuryUpdate):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT treasury_id FROM treasury WHERE treasury_id = ?", (treasury_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Treasury record {treasury_id} not found")
        fields = {"amount": data.amount, "transaction_type": data.transaction_type, "description": data.description}
        updates = {k: v for k, v in fields.items() if v is not None}
        if updates:
            set_clause = ", ".join(f"{col} = ?" for col in updates)
            cursor.execute(
                f"UPDATE treasury SET {set_clause} WHERE treasury_id = ?",
                list(updates.values()) + [treasury_id],
            )
    return {"message": f"Treasury record {treasury_id} updated successfully"}


@app.delete("/treasury/{treasury_id}")
async def delete_treasury(treasury_id: int):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT treasury_id FROM treasury WHERE treasury_id = ?", (treasury_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Treasury record {treasury_id} not found")
        cursor.execute("DELETE FROM treasury WHERE treasury_id = ?", (treasury_id,))
    return {"message": f"Treasury record {treasury_id} deleted successfully"}


# ── Expense Categories ────────────────────────────────────────────────────────

@app.get("/expense_categories")
async def get_expense_categories():
    with db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT category_id, category_name FROM expense_categories ORDER BY category_id")
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


# ── System Users ───────────────────────────────────────────────────────────────

@app.get("/system_users")
async def get_system_users():
    with db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT username, role, password, createdat FROM system_users ORDER BY username")
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.post("/system_users", status_code=201)
async def create_system_user(data: SystemUserIn):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT username FROM system_users WHERE username = ?", (data.username,))
        if cursor.fetchone():
            raise HTTPException(status_code=409, detail=f"Username '{data.username}' already exists")
        cursor.execute(
            "INSERT INTO system_users (username, role, password) VALUES (?, ?, ?)",
            (data.username, data.role, data.password)
        )
    return {"username": data.username, "message": "User created successfully"}


@app.put("/system_users/{username}")
async def update_system_user(username: str, data: SystemUserUpdate):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT username FROM system_users WHERE username = ?", (username,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"User '{username}' not found")
        fields = {"role": data.role, "password": data.password}
        updates = {k: v for k, v in fields.items() if v is not None}
        if updates:
            set_clause = ", ".join(f"{col} = ?" for col in updates)
            cursor.execute(
                f"UPDATE system_users SET {set_clause} WHERE username = ?",
                list(updates.values()) + [username]
            )
    return {"message": f"User '{username}' updated successfully"}


@app.delete("/system_users/{username}")
async def delete_system_user(username: str):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT username FROM system_users WHERE username = ?", (username,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"User '{username}' not found")
        cursor.execute("DELETE FROM system_users WHERE username = ?", (username,))
    return {"message": f"User '{username}' deleted successfully"}


# ── Actions History ────────────────────────────────────────────────────────────

@app.get("/actions_history")
async def get_actions_history(username: str = None):
    with db() as conn:
        cursor = conn.cursor()
        if username:
            cursor.execute("SELECT username FROM system_users WHERE username = ?", (username,))
            if not cursor.fetchone():
                raise HTTPException(status_code=404, detail=f"User '{username}' not found")
            cursor.execute("""
                SELECT action_id, username, action_description, action_date
                FROM actions_history
                WHERE username = ?
                ORDER BY action_date DESC
            """, (username,))
        else:
            cursor.execute("""
                SELECT action_id, username, action_description, action_date
                FROM actions_history
                ORDER BY action_date DESC
            """)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.post("/actions_history", status_code=201)
async def create_action(data: ActionIn):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT username FROM system_users WHERE username = ?", (data.username,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"User '{data.username}' not found")
        cursor.execute("""
            INSERT INTO actions_history (username, action_description)
            OUTPUT INSERTED.action_id, INSERTED.action_date
            VALUES (?, ?)
        """, (data.username, data.action_description))
        row = cursor.fetchone()
    return {"action_id": row[0], "action_date": str(row[1]), "message": "Action recorded successfully"}


# ── Invoices ──────────────────────────────────────────────────────────────────

@app.get("/invoices")
async def get_invoices(
    branch_id: int = None,
    status: str = None,
    created_date: str = None,
    username: str = None,
):
    with db() as conn:
        cursor = conn.cursor()
        filters = []
        params = []
        if branch_id is not None:
            filters.append("i.branch_id = ?")
            params.append(branch_id)
        if status:
            filters.append("i.status = ?")
            params.append(status)
        if created_date:
            filters.append("CAST(i.created_date AS NVARCHAR) LIKE ?")
            params.append(created_date + "%")
        if username:
            filters.append("i.username = ?")
            params.append(username)
        where_clause = ("WHERE " + " AND ".join(filters)) if filters else ""
        cursor.execute(f"""
            SELECT i.invoice_id, i.created_date, i.username, i.name, i.price,
                   i.branch_id, b.branch_name, i.description, i.status,
                   i.category_id, ec.category_name,
                   su.role AS user_role
            FROM invoices i
            JOIN branches b ON i.branch_id = b.branch_id
            JOIN expense_categories ec ON i.category_id = ec.category_id
            JOIN system_users su ON i.username = su.username
            {where_clause}
            ORDER BY i.created_date DESC
        """, params)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.post("/invoices", status_code=201)
async def create_invoice(data: InvoiceIn):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT username FROM system_users WHERE username = ?", (data.username,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"User '{data.username}' not found")
        cursor.execute("SELECT branch_id FROM branches WHERE branch_id = ?", (data.branch_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Branch {data.branch_id} not found")
        cursor.execute("SELECT category_id FROM expense_categories WHERE category_id = ?", (data.category_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Category {data.category_id} not found")

        if data.created_date:
            cursor.execute("""
                INSERT INTO invoices (created_date, username, name, price, branch_id, description, status, category_id)
                OUTPUT INSERTED.invoice_id
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (data.created_date, data.username, data.name, data.price,
                  data.branch_id, data.description, data.status, data.category_id))
        else:
            cursor.execute("""
                INSERT INTO invoices (username, name, price, branch_id, description, status, category_id)
                OUTPUT INSERTED.invoice_id
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (data.username, data.name, data.price,
                  data.branch_id, data.description, data.status, data.category_id))

        invoice_id = cursor.fetchone()[0]

        debt_desc = f"فاتورة #{invoice_id} - {data.name}"
        cursor.execute("""
            INSERT INTO debts (amount, status, username, category_id, branch_id, invoice_id, purchase_id, exam_id, description)
            OUTPUT INSERTED.debt_id
            VALUES (?, N'مديونية', ?, ?, ?, ?, NULL, NULL, ?)
        """, (data.price, data.username, data.category_id, data.branch_id, invoice_id, debt_desc))
        debt_id = cursor.fetchone()[0]

    return {"invoice_id": invoice_id, "debt_id": debt_id, "message": "Invoice created successfully"}


@app.put("/invoices/{invoice_id}")
async def update_invoice(invoice_id: int, data: InvoiceUpdate):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT invoice_id FROM invoices WHERE invoice_id = ?", (invoice_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Invoice {invoice_id} not found")
        fields = {
            "username": data.username,
            "name": data.name,
            "price": data.price,
            "branch_id": data.branch_id,
            "description": data.description,
            "status": data.status,
            "category_id": data.category_id,
        }
        updates = {k: v for k, v in fields.items() if v is not None}
        if updates:
            set_clause = ", ".join(f"{col} = ?" for col in updates)
            cursor.execute(
                f"UPDATE invoices SET {set_clause} WHERE invoice_id = ?",
                list(updates.values()) + [invoice_id],
            )

        # sync relevant fields to the linked unpaid debt
        debt_fields = {k: v for k, v in {
            "amount":      data.price,
            "username":    data.username,
            "branch_id":   data.branch_id,
            "category_id": data.category_id,
            "status":      data.status,
        }.items() if v is not None}
        if debt_fields:
            debt_set = ", ".join(f"{col} = ?" for col in debt_fields)
            cursor.execute(
                f"UPDATE debts SET {debt_set} WHERE invoice_id = ? AND status = N'مديونية'",
                list(debt_fields.values()) + [invoice_id],
            )
    return {"message": f"Invoice {invoice_id} updated successfully"}


@app.delete("/invoices/{invoice_id}")
async def delete_invoice(invoice_id: int):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT invoice_id FROM invoices WHERE invoice_id = ?", (invoice_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Invoice {invoice_id} not found")
        # delete linked debt first (FK has ON DELETE SET NULL which would break the single-source constraint)
        cursor.execute("DELETE FROM debts WHERE invoice_id = ?", (invoice_id,))
        cursor.execute("DELETE FROM invoices WHERE invoice_id = ?", (invoice_id,))
    return {"message": f"Invoice {invoice_id} deleted successfully"}


@app.put("/invoice_pay/{invoice_id}")
async def pay_invoice(invoice_id: int, username: str):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT invoice_id, price, status, category_id, branch_id, name FROM invoices WHERE invoice_id = ?",
            (invoice_id,),
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail=f"Invoice {invoice_id} not found")
        _, price, status, category_id, branch_id, invoice_name = row
        if status == "تم السداد":
            raise HTTPException(status_code=409, detail=f"Invoice {invoice_id} is already paid")
        cursor.execute(
            "UPDATE invoices SET status = N'تم السداد' WHERE invoice_id = ?",
            (invoice_id,),
        )
        cursor.execute("""
            INSERT INTO treasury (amount, transaction_type, username, category_id, branch_id, description)
            OUTPUT INSERTED.treasury_id
            VALUES (?, N'خرج', ?, ?, ?, ?)
        """, (price, username, category_id, branch_id, f"سداد فاتورة #{invoice_id} - {invoice_name}"))
        treasury_id = cursor.fetchone()[0]
    return {
        "invoice_id": invoice_id,
        "treasury_id": treasury_id,
        "message": f"Invoice {invoice_id} paid successfully",
    }


# ── Purchases ─────────────────────────────────────────────────────────────────

@app.get("/purchases")
async def get_purchases(
    created_date: str = None,
    branch_id: int = None,
    username: str = None,
    status: str = None,
):
    with db() as conn:
        cursor = conn.cursor()
        filters = []
        params = []
        if created_date:
            filters.append("CAST(p.created_date AS NVARCHAR) LIKE ?")
            params.append(created_date + "%")
        if branch_id is not None:
            filters.append("p.branch_id = ?")
            params.append(branch_id)
        if username:
            filters.append("p.username = ?")
            params.append(username)
        if status:
            filters.append("p.status = ?")
            params.append(status)
        where_clause = ("WHERE " + " AND ".join(filters)) if filters else ""
        cursor.execute(f"""
            SELECT p.purchase_id, p.created_date, p.username, p.description,
                   p.category_id, ec.category_name,
                   p.status, p.branch_id, b.branch_name,
                   (SELECT ISNULL(SUM(pl.total),0) FROM purchases_lines pl
                    WHERE pl.purchase_id = p.purchase_id) AS total_amount
            FROM purchases p
            JOIN branches b ON p.branch_id = b.branch_id
            JOIN expense_categories ec ON p.category_id = ec.category_id
            {where_clause}
            ORDER BY p.created_date DESC
        """, params)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.post("/purchases", status_code=201)
async def create_purchase(data: PurchaseIn):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT username FROM system_users WHERE username = ?", (data.username,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"User '{data.username}' not found")
        cursor.execute("SELECT branch_id FROM branches WHERE branch_id = ?", (data.branch_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Branch {data.branch_id} not found")
        cursor.execute("SELECT category_id FROM expense_categories WHERE category_id = ?", (data.category_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Category {data.category_id} not found")

        if data.created_date:
            cursor.execute("""
                INSERT INTO purchases (created_date, username, description, category_id, status, branch_id)
                OUTPUT INSERTED.purchase_id
                VALUES (?, ?, ?, ?, ?, ?)
            """, (data.created_date, data.username, data.description,
                  data.category_id, data.status, data.branch_id))
        else:
            cursor.execute("""
                INSERT INTO purchases (username, description, category_id, status, branch_id)
                OUTPUT INSERTED.purchase_id
                VALUES (?, ?, ?, ?, ?)
            """, (data.username, data.description,
                  data.category_id, data.status, data.branch_id))

        purchase_id = cursor.fetchone()[0]

        for line in data.lines:
            cursor.execute("""
                INSERT INTO purchases_lines (purchase_id, name, price, quantity)
                VALUES (?, ?, ?, ?)
            """, (purchase_id, line.name, line.price, line.quantity))

        # compute total and create a pending debt record
        cursor.execute(
            "SELECT ISNULL(SUM(total),0) FROM purchases_lines WHERE purchase_id = ?",
            (purchase_id,)
        )
        total_amount = float(cursor.fetchone()[0])
        debt_desc = f"مشتريات #{purchase_id}" + (f" - {data.description}" if data.description else "")
        cursor.execute("""
            INSERT INTO debts (amount, status, username, category_id, branch_id, purchase_id, exam_id, invoice_id, description)
            OUTPUT INSERTED.debt_id
            VALUES (?, N'مديونية', ?, ?, ?, ?, NULL, NULL, ?)
        """, (total_amount, data.username, data.category_id, data.branch_id, purchase_id, debt_desc))
        debt_id = cursor.fetchone()[0]

    return {"purchase_id": purchase_id, "debt_id": debt_id, "message": "Purchase created successfully"}


@app.get("/purchases/{purchase_id}/lines")
async def get_purchase_lines(purchase_id: int):
    with db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT purchase_id FROM purchases WHERE purchase_id = ?", (purchase_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Purchase {purchase_id} not found")
        cursor.execute("""
            SELECT line_id, name, price, quantity, total
            FROM purchases_lines
            WHERE purchase_id = ?
            ORDER BY line_id
        """, (purchase_id,))
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


@app.delete("/purchases/{purchase_id}")
async def delete_purchase(purchase_id: int):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT purchase_id FROM purchases WHERE purchase_id = ?", (purchase_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Purchase {purchase_id} not found")
        # delete linked debt first (ON DELETE SET NULL would break single-source constraint)
        cursor.execute("DELETE FROM debts WHERE purchase_id = ?", (purchase_id,))
        cursor.execute("DELETE FROM purchases WHERE purchase_id = ?", (purchase_id,))
    return {"message": f"Purchase {purchase_id} deleted successfully"}


@app.put("/purchases/{purchase_id}")
async def update_purchase(purchase_id: int, data: PurchaseUpdate):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT purchase_id FROM purchases WHERE purchase_id = ?", (purchase_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail=f"Purchase {purchase_id} not found")

        fields = {
            "username": data.username,
            "description": data.description,
            "category_id": data.category_id,
            "status": data.status,
            "branch_id": data.branch_id,
        }
        updates = {k: v for k, v in fields.items() if v is not None}
        if updates:
            set_clause = ", ".join(f"{col} = ?" for col in updates)
            cursor.execute(
                f"UPDATE purchases SET {set_clause} WHERE purchase_id = ?",
                list(updates.values()) + [purchase_id],
            )

        if data.lines is not None:
            cursor.execute("DELETE FROM purchases_lines WHERE purchase_id = ?", (purchase_id,))
            for line in data.lines:
                cursor.execute("""
                    INSERT INTO purchases_lines (purchase_id, name, price, quantity)
                    VALUES (?, ?, ?, ?)
                """, (purchase_id, line.name, line.price, line.quantity))

        # sync header fields and recomputed total to the linked unpaid debt
        debt_fields = {k: v for k, v in {
            "username":    data.username,
            "branch_id":   data.branch_id,
            "category_id": data.category_id,
            "status":      data.status,
        }.items() if v is not None}

        # recalculate total if lines were changed, otherwise keep existing amount
        if data.lines is not None:
            cursor.execute(
                "SELECT ISNULL(SUM(total),0) FROM purchases_lines WHERE purchase_id = ?",
                (purchase_id,)
            )
            debt_fields["amount"] = float(cursor.fetchone()[0])

        if debt_fields:
            debt_set = ", ".join(f"{col} = ?" for col in debt_fields)
            cursor.execute(
                f"UPDATE debts SET {debt_set} WHERE purchase_id = ? AND status = N'مديونية'",
                list(debt_fields.values()) + [purchase_id],
            )

    return {"message": f"Purchase {purchase_id} updated successfully"}


@app.put("/purchase_pay/{purchase_id}")
async def pay_purchase(purchase_id: int, username: str):
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT purchase_id, status, category_id, branch_id, description FROM purchases WHERE purchase_id = ?",
            (purchase_id,),
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail=f"Purchase {purchase_id} not found")
        _, status, category_id, branch_id, purchase_desc = row
        if status == "تم السداد":
            raise HTTPException(status_code=409, detail=f"Purchase {purchase_id} is already paid")

        cursor.execute(
            "SELECT ISNULL(SUM(total),0) FROM purchases_lines WHERE purchase_id = ?",
            (purchase_id,),
        )
        total_amount = float(cursor.fetchone()[0])

        treasury_desc = f"سداد مشتريات #{purchase_id}" + (f" - {purchase_desc}" if purchase_desc else "")

        cursor.execute(
            "UPDATE purchases SET status = N'تم السداد' WHERE purchase_id = ?",
            (purchase_id,),
        )
        cursor.execute("""
            INSERT INTO treasury (amount, transaction_type, username, category_id, branch_id, description)
            OUTPUT INSERTED.treasury_id
            VALUES (?, N'خرج', ?, ?, ?, ?)
        """, (total_amount, username, category_id, branch_id, treasury_desc))
        treasury_id = cursor.fetchone()[0]

        cursor.execute(
            "UPDATE debts SET status = N'تم السداد', payment_date = SYSDATETIME() WHERE purchase_id = ? AND status = N'مديونية'",
            (purchase_id,)
        )
    return {
        "purchase_id": purchase_id,
        "treasury_id": treasury_id,
        "total_amount": total_amount,
        "message": f"Purchase {purchase_id} paid successfully",
    }


# ── System restart ─────────────────────────────────────────────────────────────

DROP_STATEMENTS = [
    "IF OBJECT_ID('debts',            'U') IS NOT NULL DROP TABLE debts",
    "IF OBJECT_ID('treasury',         'U') IS NOT NULL DROP TABLE treasury",
    "IF OBJECT_ID('purchases_lines',  'U') IS NOT NULL DROP TABLE purchases_lines",
    "IF OBJECT_ID('purchases',        'U') IS NOT NULL DROP TABLE purchases",
    "IF OBJECT_ID('invoices',         'U') IS NOT NULL DROP TABLE invoices",
    "IF OBJECT_ID('actions_history',  'U') IS NOT NULL DROP TABLE actions_history",
    "IF OBJECT_ID('examinations',     'U') IS NOT NULL DROP TABLE examinations",
    "IF OBJECT_ID('doctor_services',  'U') IS NOT NULL DROP TABLE doctor_services",
    "IF OBJECT_ID('doctor_schedules', 'U') IS NOT NULL DROP TABLE doctor_schedules",
    "IF OBJECT_ID('doctor_branches',  'U') IS NOT NULL DROP TABLE doctor_branches",
    "IF OBJECT_ID('doctors',          'U') IS NOT NULL DROP TABLE doctors",
    "IF OBJECT_ID('patients',         'U') IS NOT NULL DROP TABLE patients",
    "IF OBJECT_ID('expense_categories','U') IS NOT NULL DROP TABLE expense_categories",
    "IF OBJECT_ID('system_users',     'U') IS NOT NULL DROP TABLE system_users",
    "IF OBJECT_ID('branches',         'U') IS NOT NULL DROP TABLE branches",
]

CREATE_STATEMENTS = [
    """CREATE TABLE branches (
        branch_id   INT IDENTITY(1,1) PRIMARY KEY,
        branch_name NVARCHAR(30) NOT NULL UNIQUE
    )""",

    """CREATE TABLE doctors (
        doctor_id           INT IDENTITY(1,1) PRIMARY KEY,
        doctor_name         NVARCHAR(100) NOT NULL,
        specialty           NVARCHAR(100) NOT NULL,
        doctor_phone_number NVARCHAR(30)  NOT NULL,
        doctor_balance      DECIMAL(30,3),
        CONSTRAINT UQ_doctors_name_phone UNIQUE (doctor_name, doctor_phone_number)
    )""",

    """CREATE TABLE doctor_branches (
        doctor_id INT NOT NULL,
        branch_id INT NOT NULL,
        PRIMARY KEY (doctor_id, branch_id),
        CONSTRAINT FK_doctor_branches_doctors  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)  ON DELETE CASCADE,
        CONSTRAINT FK_doctor_branches_branches FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE CASCADE
    )""",

    """CREATE TABLE patients (
        patient_id   INT IDENTITY(1,1) PRIMARY KEY,
        patient_name NVARCHAR(100) NOT NULL,
        phone        NVARCHAR(20)  NOT NULL,
        branch_id    INT           NULL,
        birth_date   DATE          NULL,
        CONSTRAINT FK_patients_branches FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    )""",

    """CREATE TABLE doctor_schedules (
        schedule_id INT IDENTITY(1,1) PRIMARY KEY,
        doctor_id   INT          NOT NULL,
        day_of_week NVARCHAR(20) NOT NULL,
        start_time  TIME         NOT NULL,
        end_time    TIME         NOT NULL,
        branch_id   INT          NULL,
        is_active   BIT          DEFAULT 1,
        CONSTRAINT FK_doctor_schedules_doctors   FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)  ON DELETE CASCADE,
        CONSTRAINT FK_doctor_schedules_branches  FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE CASCADE
    )""",

    """CREATE TABLE doctor_services (
        service_id                   INT IDENTITY(1,1) PRIMARY KEY,
        doctor_id                    INT           NOT NULL,
        service_name                 NVARCHAR(100) NOT NULL,
        price                        DECIMAL(10,2) NOT NULL,
        doctor_commission_percentage DECIMAL(5,2)  NOT NULL DEFAULT 70.00,
        CONSTRAINT FK_doctor_services_doctors FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
    )""",

    """CREATE TABLE examinations (
        exam_id     INT IDENTITY(1,1) PRIMARY KEY,
        doctor_id   INT          NOT NULL,
        patient_id  INT          NOT NULL,
        service_id  INT          NOT NULL,
        branch_id   INT          NOT NULL,
        exam_date   DATETIME     NOT NULL,
        exam_number NVARCHAR(50) NOT NULL,
        status      NVARCHAR(20) NOT NULL,
        CONSTRAINT FK_examinations_doctors   FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id)         ON DELETE CASCADE,
        CONSTRAINT FK_examinations_patients  FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
        CONSTRAINT FK_examinations_services  FOREIGN KEY (service_id) REFERENCES doctor_services(service_id),
        CONSTRAINT FK_examinations_branches  FOREIGN KEY (branch_id)  REFERENCES branches(branch_id)
    )""",

    """CREATE TABLE system_users (
        username  NVARCHAR(30) PRIMARY KEY,
        role      NVARCHAR(30) NOT NULL,
        password  NVARCHAR(50) NOT NULL,
        createdat DATE         DEFAULT SYSDATETIME()
    )""",

    """CREATE TABLE actions_history (
        action_id          INT IDENTITY(1,1) PRIMARY KEY,
        username           NVARCHAR(30)  NOT NULL,
        action_description NVARCHAR(255) NOT NULL,
        action_date        DATETIME      DEFAULT SYSDATETIME(),
        CONSTRAINT FK_actions_history_system_users FOREIGN KEY (username) REFERENCES system_users(username) ON DELETE CASCADE
    )""",

    """CREATE TABLE expense_categories (
        category_id   INT IDENTITY(1,1) PRIMARY KEY,
        category_name NVARCHAR(100) NOT NULL UNIQUE
    )""",

    """CREATE TABLE purchases (
        purchase_id  INT IDENTITY(1,1) PRIMARY KEY,
        created_date DATETIME      NOT NULL DEFAULT SYSDATETIME(),
        username     NVARCHAR(30)  NOT NULL,
        description  NVARCHAR(255) NULL,
        category_id  INT           NOT NULL,
        status       NVARCHAR(20)  NOT NULL,
        branch_id    INT           NOT NULL,
        CONSTRAINT FK_purchases_system_users FOREIGN KEY (username)    REFERENCES system_users(username),
        CONSTRAINT FK_purchases_categories   FOREIGN KEY (category_id) REFERENCES expense_categories(category_id),
        CONSTRAINT FK_purchases_branches     FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
        CONSTRAINT CHK_purchases_status      CHECK (status IN (N'مديونية', N'تم السداد'))
    )""",

    """CREATE TABLE purchases_lines (
        line_id     INT IDENTITY(1,1) PRIMARY KEY,
        purchase_id INT           NOT NULL,
        name        NVARCHAR(100) NOT NULL,
        price       DECIMAL(18,3) NOT NULL,
        quantity    DECIMAL(18,3) NOT NULL,
        total       AS (quantity * price) PERSISTED,
        CONSTRAINT FK_purchases_lines_purchases FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id) ON DELETE CASCADE
    )""",

    """CREATE TABLE invoices (
        invoice_id   INT IDENTITY(1,1) PRIMARY KEY,
        created_date DATETIME      NOT NULL DEFAULT SYSDATETIME(),
        username     NVARCHAR(30)  NOT NULL,
        name         NVARCHAR(100) NOT NULL,
        price        DECIMAL(18,3) NOT NULL,
        branch_id    INT           NOT NULL,
        description  NVARCHAR(255) NULL,
        status       NVARCHAR(20)  NOT NULL,
        category_id  INT           NOT NULL,
        CONSTRAINT FK_invoices_system_users FOREIGN KEY (username)    REFERENCES system_users(username),
        CONSTRAINT FK_invoices_branches     FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
        CONSTRAINT FK_invoices_categories   FOREIGN KEY (category_id) REFERENCES expense_categories(category_id),
        CONSTRAINT CHK_invoices_status      CHECK (status IN (N'مديونية', N'تم السداد'))
    )""",

    """CREATE TABLE treasury (
        treasury_id      INT IDENTITY(1,1) PRIMARY KEY,
        creation_date    DATETIME      NOT NULL DEFAULT SYSDATETIME(),
        amount           DECIMAL(18,3) NOT NULL,
        transaction_type NVARCHAR(10)  NOT NULL,
        username         NVARCHAR(30)  NOT NULL,
        category_id      INT           NOT NULL,
        branch_id        INT           NOT NULL,
        description      NVARCHAR(500) NULL,
        CONSTRAINT FK_treasury_system_users FOREIGN KEY (username)    REFERENCES system_users(username),
        CONSTRAINT FK_treasury_categories   FOREIGN KEY (category_id) REFERENCES expense_categories(category_id),
        CONSTRAINT FK_treasury_branches     FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
        CONSTRAINT CHK_treasury_type        CHECK (transaction_type IN (N'دخل', N'خرج'))
    )""",

    """CREATE TABLE debts (
        debt_id       INT IDENTITY(1,1) PRIMARY KEY,
        creation_date DATETIME      NOT NULL DEFAULT SYSDATETIME(),
        payment_date  DATETIME      NULL,
        amount        DECIMAL(18,3) NOT NULL,
        status        NVARCHAR(20)  NOT NULL,
        username      NVARCHAR(30)  NOT NULL,
        category_id   INT           NOT NULL,
        branch_id     INT           NOT NULL,
        purchase_id   INT           NULL,
        exam_id       INT           NULL,
        invoice_id    INT           NULL,
        description   NVARCHAR(500) NULL,
        CONSTRAINT FK_debts_system_users FOREIGN KEY (username)    REFERENCES system_users(username),
        CONSTRAINT FK_debts_categories   FOREIGN KEY (category_id) REFERENCES expense_categories(category_id),
        CONSTRAINT FK_debts_branches     FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
        CONSTRAINT FK_debts_purchases    FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id)   ON DELETE SET NULL,
        CONSTRAINT FK_debts_examinations FOREIGN KEY (exam_id)     REFERENCES examinations(exam_id)    ON DELETE SET NULL,
        CONSTRAINT FK_debts_invoices     FOREIGN KEY (invoice_id)  REFERENCES invoices(invoice_id)     ON DELETE SET NULL,
        CONSTRAINT CHK_debts_status      CHECK (status IN (N'مديونية', N'تم السداد')),
        CONSTRAINT CHK_debts_single_source CHECK (
            (purchase_id IS NOT NULL AND exam_id IS NULL     AND invoice_id IS NULL) OR
            (purchase_id IS NULL     AND exam_id IS NOT NULL AND invoice_id IS NULL) OR
            (purchase_id IS NULL     AND exam_id IS NULL     AND invoice_id IS NOT NULL)
        )
    )""",
]

SEED_STATEMENTS = [
    ("INSERT INTO system_users (username, role, password) VALUES (?, ?, ?)",
     ("tawaky", "manager", "tawaky")),
    ("INSERT INTO expense_categories (category_name) VALUES (N'زيارات')", ()),
    ("INSERT INTO expense_categories (category_name) VALUES (N'فواتير')", ()),
    ("INSERT INTO expense_categories (category_name) VALUES (N'مشتريات')", ()),
]


def _reset_schema(cursor):
    for stmt in DROP_STATEMENTS:
        cursor.execute(stmt)
    for stmt in CREATE_STATEMENTS:
        cursor.execute(stmt)
    for stmt, params in SEED_STATEMENTS:
        cursor.execute(stmt, params) if params else cursor.execute(stmt)


@app.post("/migrate/debts_payment_date_nullable")
async def migrate_debts_payment_date_nullable():
    """One-time migration: remove DEFAULT SYSDATETIME() and NOT NULL from debts.payment_date."""
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        # Drop the default constraint if it exists
        cursor.execute("""
            DECLARE @cname NVARCHAR(200)
            SELECT @cname = dc.name
            FROM sys.default_constraints dc
            JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
            JOIN sys.tables t ON c.object_id = t.object_id
            WHERE t.name = 'debts' AND c.name = 'payment_date'
            IF @cname IS NOT NULL
                EXEC('ALTER TABLE debts DROP CONSTRAINT [' + @cname + ']')
        """)
        # Make the column nullable
        cursor.execute("ALTER TABLE debts ALTER COLUMN payment_date DATETIME NULL")
        # Clear any existing payment_date values for unpaid debts
        cursor.execute("UPDATE debts SET payment_date = NULL WHERE status = N'مديونية'")
    return {"message": "Migration complete: debts.payment_date is now nullable with no default."}


@app.post("/restart_system")
async def restart_system():
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        _reset_schema(cursor)
    return {
        "message": "System restarted successfully. All tables recreated and initial data seeded.",
        "seeded_user": "tawaky",
    }


@app.post("/restart_with_dummy")
async def restart_with_dummy():
    with db(autocommit=False) as conn:
        cursor = conn.cursor()
        _reset_schema(cursor)

        # ── Branches ──────────────────────────────────────────────────────────
        branch_names = ["فرع المعادي", "فرع مدينة نصر", "فرع الزمالك", "فرع الدقي", "فرع المهندسين"]
        branch_ids = []
        for name in branch_names:
            cursor.execute(
                "INSERT INTO branches (branch_name) OUTPUT INSERTED.branch_id VALUES (?)", (name,)
            )
            branch_ids.append(cursor.fetchone()[0])

        # ── Doctors + branch links + schedules + services ─────────────────────
        dummy_doctors = [
            {
                "name": "أحمد محمد",
                "specialty": "باطنة",
                "phone": "01001000001",
                "branches": [branch_ids[0], branch_ids[1]],
                "schedules": [
                    ("السبت",    "09:00:00", "14:00:00", branch_ids[0]),
                    ("الاثنين",  "10:00:00", "15:00:00", branch_ids[1]),
                    ("الأربعاء", "09:00:00", "13:00:00", branch_ids[0]),
                ],
                "services": [
                    ("كشف باطنة",    200.0, 70.0),
                    ("استشارة باطنة", 150.0, 70.0),
                ],
            },
            {
                "name": "سارة علي",
                "specialty": "أطفال",
                "phone": "01001000002",
                "branches": [branch_ids[1], branch_ids[2]],
                "schedules": [
                    ("الأحد",    "08:00:00", "13:00:00", branch_ids[1]),
                    ("الثلاثاء", "09:00:00", "14:00:00", branch_ids[2]),
                ],
                "services": [
                    ("كشف أطفال",     250.0, 65.0),
                    ("متابعة أطفال",  180.0, 65.0),
                    ("تطعيمات",       100.0, 60.0),
                ],
            },
            {
                "name": "محمود حسن",
                "specialty": "عيون",
                "phone": "01001000003",
                "branches": [branch_ids[2], branch_ids[3]],
                "schedules": [
                    ("السبت",    "10:00:00", "15:00:00", branch_ids[2]),
                    ("الاثنين",  "09:00:00", "14:00:00", branch_ids[3]),
                    ("الخميس",   "11:00:00", "16:00:00", branch_ids[2]),
                ],
                "services": [
                    ("كشف عيون",       300.0, 70.0),
                    ("قياس نظر",       150.0, 70.0),
                    ("استشارة عيون",   200.0, 70.0),
                ],
            },
            {
                "name": "نور الدين سعيد",
                "specialty": "جراحة عامة",
                "phone": "01001000004",
                "branches": [branch_ids[3], branch_ids[4]],
                "schedules": [
                    ("الأحد",    "09:00:00", "14:00:00", branch_ids[3]),
                    ("الأربعاء", "10:00:00", "15:00:00", branch_ids[4]),
                ],
                "services": [
                    ("كشف جراحة",      350.0, 75.0),
                    ("استشارة جراحة",  250.0, 75.0),
                ],
            },
            {
                "name": "ريم إبراهيم",
                "specialty": "نساء وتوليد",
                "phone": "01001000005",
                "branches": [branch_ids[0], branch_ids[4]],
                "schedules": [
                    ("الثلاثاء", "09:00:00", "14:00:00", branch_ids[0]),
                    ("الخميس",   "10:00:00", "15:00:00", branch_ids[4]),
                    ("السبت",    "08:00:00", "12:00:00", branch_ids[0]),
                ],
                "services": [
                    ("كشف نساء",        300.0, 70.0),
                    ("متابعة حمل",      250.0, 70.0),
                    ("استشارة توليد",   200.0, 70.0),
                ],
            },
        ]

        doctor_ids = []
        for doc in dummy_doctors:
            cursor.execute(
                """INSERT INTO doctors (doctor_name, specialty, doctor_phone_number, doctor_balance)
                   OUTPUT INSERTED.doctor_id VALUES (?, ?, ?, 0)""",
                (doc["name"], doc["specialty"], doc["phone"]),
            )
            doc_id = cursor.fetchone()[0]
            doctor_ids.append(doc_id)

            for branch_id in doc["branches"]:
                cursor.execute(
                    "INSERT INTO doctor_branches (doctor_id, branch_id) VALUES (?, ?)",
                    (doc_id, branch_id),
                )

            for day, start, end, branch_id in doc["schedules"]:
                cursor.execute(
                    """INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time, branch_id, is_active)
                       VALUES (?, ?, ?, ?, ?, 1)""",
                    (doc_id, day, start, end, branch_id),
                )

            for svc_name, price, commission in doc["services"]:
                cursor.execute(
                    """INSERT INTO doctor_services (doctor_id, service_name, price, doctor_commission_percentage)
                       VALUES (?, ?, ?, ?)""",
                    (doc_id, svc_name, price, commission),
                )

    return {
        "message": "System restarted with dummy data.",
        "seeded_user": "tawaky",
        "branches": branch_names,
        "doctors": [d["name"] for d in dummy_doctors],
    }
