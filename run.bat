@echo off
echo ========================================================
echo Starting SkyWings Airline Reservation System...
echo ========================================================
echo.

echo Cleaning up any old running instances on ports 8000 and 8501...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8000" ^| findstr "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8501" ^| findstr "LISTENING"') do taskkill /f /pid %%a >nul 2>&1

timeout /t 1 /nobreak >nul

echo [1/2] Launching FastAPI Backend on http://127.0.0.1:8000 ...
start "SkyWings - FastAPI Backend" cmd /k "python -m uvicorn backend.main:app --reload --port 8000"

timeout /t 3 /nobreak >nul

echo [2/2] Launching Streamlit Web App ...
start "SkyWings - Streamlit Frontend" cmd /k "python -m streamlit run frontend/app.py"

echo.
echo ========================================================
echo Both Backend and Frontend launched successfully!
echo ========================================================
