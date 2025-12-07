@echo off
REM ================================================================================
REM  Azure Function Build Script (Windows CMD)
REM  - Cleans old build artifacts
REM  - Installs dependencies
REM  - Compiles TypeScript → JavaScript
REM  - Copies required Azure Function configuration files
REM  - Packages everything into function.zip for deployment
REM ================================================================================

REM -----------------------------------------------
REM 1️⃣ Clean Previous Build Artifacts
REM -----------------------------------------------
echo Cleaning old build artifacts...

IF EXIST dist rmdir /s /q dist
IF EXIST function.zip del /f /q function.zip

mkdir dist

REM -----------------------------------------------
REM 2️⃣ Install Project Dependencies
REM -----------------------------------------------
echo Installing npm dependencies...
npm install

REM -----------------------------------------------
REM 3️⃣ Compile TypeScript → JavaScript
REM -----------------------------------------------
echo Compiling TypeScript sources...
npx tsc

REM -----------------------------------------------
REM 4️⃣ Copy Azure Function Configuration Files
REM -----------------------------------------------
echo Copying function.json files...

FOR /D %%F IN (hello*) DO (
  IF EXIST "%%F\function.json" (
    mkdir "dist\%%F" 2>nul
    copy "%%F\function.json" "dist\%%F\" >nul
  )
)

REM -----------------------------------------------
REM 5️⃣ Copy Host-Level Configuration Files
REM -----------------------------------------------
echo Copying host.json and package.json...
copy host.json dist\ >nul
copy package.json dist\ >nul

REM -----------------------------------------------
REM 6️⃣ Create Deployment ZIP Package
REM -----------------------------------------------
echo Creating function.zip package...

cd dist
powershell -Command "Compress-Archive -Path * -DestinationPath ../function.zip -Force"
cd ..

REM -----------------------------------------------
REM ✅ Build Completion & Verification
REM -----------------------------------------------
echo ⭐ function.zip created successfully!

REM Display ZIP contents for verification
powershell -Command "Get-ChildItem function.zip | Select-Object Name, Length"

pause
