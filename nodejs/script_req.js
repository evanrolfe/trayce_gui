#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const Request = require('./request.js');
const Response = require('./response.js');
const Bru = require('./bru.js');

// Parse command line arguments
const args = process.argv.slice(2);
if (args.length !== 2) {
  console.error('Usage: node script_req.js <file_path> <config_json>');
  console.error('Example: node script_req.js myfile.js \'{"request":{"method":"GET","url":"http://localhost:46725"},"requestMap":{},"response":{"status":200,"body":"Hello World"}}\'');
  process.exit(1);
}

const [filePath, configJson] = args;

// Parse the config JSON
let config;
try {
  config = JSON.parse(configJson);
} catch (error) {
  console.error('Error parsing config JSON:', error.message);
  process.exit(1);
}

// Validate required fields
if (!config.request || !config.request.method || !config.request.url) {
  console.error('Config must contain request object with method and url fields');
  process.exit(1);
}

if (!config.requestMap) {
  console.error('Config must contain requestMap field');
  process.exit(1);
}

// Create Request instance
const req = new Request(config.request);

// Create Response instance if response is provided
let res = null;
if (config.response) {
  res = new Response(config.response);
}

// Create the Bru instance
const bru = new Bru(config.requestMap, config.collectionName, config.vars);

// Check if the file exists
if (!fs.existsSync(filePath)) {
  console.error(`File not found: ${filePath}`);
  process.exit(1);
}

// Create a context object with all the variables and request data
const scriptContext = {
  req: req,
  res: res,
  bru: bru,
  fs: fs,
  path: path,
  console: console,
  process: process,
};

// Read and evaluate the target script
(async () => {
  try {
    const scriptContent = fs.readFileSync(filePath, 'utf8');

    // Create an async function wrapper to provide the context
    const scriptFunction = new Function('ctx', `
          // Make all context properties available in scope
          const {
              req,
              res,
              bru,
              fs,
              path,
              console,
              process
          } = ctx;

          // Execute the script content as an async function
          return (async () => {
              ${scriptContent}
          })();
      `);

    await scriptFunction(scriptContext);

    const bruMap = bru.toMap();
    const output = { 'req': req.toMap(), 'runtimeVars': bruMap.runtimeVars, 'envVars': bruMap.envVars, 'globalEnvVars': bruMap.globalEnvVars };

    if (res) {
      output['res'] = res.toMap();
    }

    console.log(JSON.stringify(output, null, 0));

  } catch (error) {
    console.error('Error executing target script:', error.message);
    process.exit(1);
  }
})();
