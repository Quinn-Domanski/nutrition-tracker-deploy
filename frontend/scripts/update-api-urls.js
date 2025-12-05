#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pagesDir = path.join(__dirname, '../src/pages');
const componentsDir = path.join(__dirname, '../src/components');

function updateFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Skip if already updated
  if (content.includes('import { api }')) {
    console.log(`✓ Already updated: ${filePath}`);
    return;
  }

  // Add import at the top (after first import)
  if (content.includes('import ')) {
    const firstImportMatch = content.match(/import[^;]+;/);
    if (firstImportMatch) {
      const firstImport = firstImportMatch[0];
      const importIndex = content.indexOf(firstImport);
      const insertPos = importIndex + firstImport.length;
      content = content.slice(0, insertPos) + '\nimport { api } from "../utils/api";' + content.slice(insertPos);
    }
  }

  // Replace fetch calls with hardcoded URLs
  content = content.replace(/fetch\("http:\/\/localhost:5000\/([^"]+)"/g, 'api.get("/$1"');
  content = content.replace(/fetch\(`http:\/\/localhost:5000\/([^`]+)`/g, 'api.get("/$1"');
  
  // Handle template literals with VITE_API_URL
  content = content.replace(/fetch\(`\$\{import\.meta\.env\.VITE_API_URL \|\| [^}]+\}\/([^`]+)`/g, 'api.get("/$1"');
  
  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`✓ Updated: ${filePath}`);
}

function processDirectory(dir) {
  if (!fs.existsSync(dir)) {
    console.log(`⚠️  Directory not found: ${dir}`);
    return;
  }

  fs.readdirSync(dir).forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    
    if (stat.isDirectory()) {
      processDirectory(filePath);
    } else if (file.endsWith('.jsx')) {
      updateFile(filePath);
    }
  });
}

console.log('Updating API calls across all components...');
processDirectory(pagesDir);
processDirectory(componentsDir);
console.log('Done!');