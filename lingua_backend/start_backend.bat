@echo off
cd /d %~dp0

if not exist ".venv\Scripts\python.exe" (
  py -3 -m venv .venv
)

call ".venv\Scripts\activate"

python -m pip install -U pip
python -m pip install -r requirements.txt

echo Starting backend...
python -m uvicorn app:app --host 127.0.0.1 --port 8000 --reload

pause
