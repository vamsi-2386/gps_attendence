import sqlite3
conn = sqlite3.connect('app/src/database/app.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()
subs = c.execute("SELECT * FROM subjects").fetchall()
print('Subjects:')
for s in subs: print(dict(s))
emp = c.execute("SELECT employee_id, company_id, name FROM employees").fetchall()
print('Employees:')
for e in emp: print(dict(e))
pe = c.execute("SELECT * FROM project_employees").fetchall()
print('Project Employees:')
for p in pe: print(dict(p))
