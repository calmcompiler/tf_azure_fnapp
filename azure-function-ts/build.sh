#!/bin/bash -xe
################################################################################
# Azure Function Build Script
# - Cleans old build artifacts
# - Installs dependencies
# - Compiles TypeScript → JavaScript
# - Copies required Azure Function config files
# - Packages everything into function.zip for deployment
################################################################################

# -----------------------------------------------
# 1️⃣ Clean Previous Build Artifacts
# -----------------------------------------------
# Remove old dist folder and ZIP (if they exist)
rm -rf dist function.zip

# Recreate fresh dist directory
mkdir -p dist

# -----------------------------------------------
# 2️⃣ Install Project Dependencies
# -----------------------------------------------
# Installs all npm packages defined in package.json
npm install

# -----------------------------------------------
# 3️⃣ Compile TypeScript → JavaScript
# -----------------------------------------------
# Runs the TypeScript compiler using local config (tsconfig.json)
npx tsc

# -----------------------------------------------
# 4️⃣ Copy Azure Function Configuration Files
# -----------------------------------------------
# Copy function.json from each function source folder
# NOTE: We explicitly copy from SOURCE folders (not compiled output)
for func in hello*
do
  cp $func/function.json dist/$func/
done

# -----------------------------------------------
# 5️⃣ Copy Host-Level Configuration Files
# -----------------------------------------------
# Copy global Azure Functions runtime configuration
cp host.json dist/

# Copy package.json (required for runtime dependencies)
cp package.json dist/

# -----------------------------------------------
# 6️⃣ Create Deployment ZIP Package
# -----------------------------------------------
# Move into dist directory and zip everything
cd dist
zip -r ../function.zip .
cd ..

# -----------------------------------------------
# ✅ Build Completion & Verification
# -----------------------------------------------
echo "⭐ function.zip created successfully!"

# Display ZIP contents for verification
unzip -l function.zip
