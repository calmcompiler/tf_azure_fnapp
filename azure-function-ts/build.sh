#!/bin/bash -xe

rm -rf dist function.zip
mkdir -p dist

npm install
npx tsc

for func in hello*
do
  cp $func/function.json dist/$func/
done

cp host.json dist/
cp package.json dist/

cd dist
zip -r ../function.zip .
cd ..

echo "function.zip created successfully!"
unzip -l function.zip
