
rm -rf dist
mkdir dist

npm install
npx tsc

for folder in hello*/; do
    mkdir -p dist/"$folder"
    cp "$folder"*.js "$folder"*.json dist/"$folder"/ 2>/dev/null
done

cp host.json package.json dist/

cd dist
zip -r ../function.zip *
cd ..
unzip -l function.zip
