@echo off
echo Compiling VectorDB...
g++ -std=c++17 -O2 main.cpp -o db -lws2_32

if %errorlevel% neq 0 (
    echo.
    echo Compilation failed! Please check the errors above.
    pause
    exit /b %errorlevel%
)

echo Compilation successful! Starting server...
echo.
db.exe
pause
