#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const Request = require('./request.js');
const Response = require('./response.js');
const Bru = require('./bru.js');
const { executeScript } = require('./script_executor.js');

// Parse command line arguments
const args = process.argv.slice(2);
if (args.length !== 1) {
  console.log("incorrect args");
  process.exit(1);
}

const [configJson] = args;

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

// Create Response instance
let res = new Response(config.response);

// Create the Bru instance
const bru = new Bru(config.requestMap, config.collectionName, config.vars);

// Read and evaluate the target script
(async () => {
  try {
    for (const responseVar of config.vars.responseVars) {
      // Create an async function wrapper to provide the context
      const scriptFunction = `return ${responseVar.value}`;

      const result = await executeScript(scriptFunction, config, req, res, bru);
      if (result !== undefined) {
        bru.setVar(responseVar.name, result.toString());
      }
    }

    const bruMap = bru.toMap();
    const output = { 'req': req.toMap(), 'runtimeVars': bruMap.runtimeVars, 'envVars': bruMap.envVars };

    if (res) {
      output['res'] = res.toMap();
    }

    console.log(JSON.stringify(output, null, 0));

  } catch (error) {
    console.error('Error executing target script:', error.message);
    process.exit(1);
  }
})();
