#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Log function that only outputs if LOG_LEVEL=debug
function log(...args) {
  if (process.env.LOG_LEVEL === 'debug') {
    console.log(...args);
  }
}

// Parse command line arguments
const args = process.argv.slice(2);

if (args.length !== 2) {
  console.error('Usage: node script_req.js <file_path> <request_json>');
  console.error('Example: node script_req.js myfile.js \'{"method":"GET","url":"http://localhost:46725{{A_var}}?hello=world"}\'');
  process.exit(1);
}

const [filePath, requestJson] = args;

// Parse the request JSON
let req;
try {
  req = JSON.parse(requestJson);
} catch (error) {
  console.error('Error parsing request JSON:', error.message);
  process.exit(1);
}

// Validate required fields
if (!req.method || !req.url) {
  console.error('Request must contain method and url fields');
  process.exit(1);
}

// Check if the file exists
if (!fs.existsSync(filePath)) {
  console.error(`File not found: ${filePath}`);
  process.exit(1);
}

// Create a context object with all the variables and request data
const scriptContext = {
  // Original request with variables
  req: req,

  // Individual variables for easy access
  vars: req.vars || [],

  // Helper function to get variable value by name
  getVar: (name) => {
    const variable = req.vars?.find(v => v.name === name && v.enabled);
    return variable ? variable.value : null;
  },

  // Common Node.js modules
  fs: fs,
  path: path,

  // Console for output
  console: console,

  // Process object
  process: process,

  // Log function
  log: log
};

// Output the request
log('Request:');
log(JSON.stringify(req, null, 2));

// Here you would typically make the actual HTTP request
// For now, we'll just show what would be sent
log('\nRequest Details:');
log(`Method: ${req.method}`);
log(`URL: ${req.url}`);
log(`Mode: ${req.mode || 'default'}`);

if (req.auth) {
  log(`Auth Type: ${req.auth.type}`);
  log(`Auth Key: ${req.auth.key}`);
  log(`Auth Placement: ${req.auth.placement}`);
}

if (req.vars) {
  log('\nVariables:');
  req.vars.forEach(variable => {
    if (variable.enabled) {
      log(`  ${variable.name}: ${variable.value} ${variable.secret ? '(secret)' : ''}`);
    }
  });
}

log('\nFile to run:', filePath);
log('Script completed successfully!');

// Read and evaluate the target script
try {
  const scriptContent = fs.readFileSync(filePath, 'utf8');

  // Create a function wrapper to provide the context
  const scriptFunction = new Function('ctx', `
        // Make all context properties available in scope
        const {
            req,
            vars,
            getVar,
            fs,
            path,
            console,
            process,
            log
        } = ctx;

        // Execute the script content
        ${scriptContent}
    `);

  log('\n=== Executing target script ===');
  scriptFunction(scriptContext);
  log('=== Target script completed ===');

} catch (error) {
  console.error('Error executing target script:', error.message);
  process.exit(1);
}
