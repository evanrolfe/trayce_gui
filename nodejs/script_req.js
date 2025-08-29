#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const vm = require('vm');
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

// Load and evaluate the target script using a VM context with a custom require function
(async () => {
  try {
    const scriptContent = fs.readFileSync(filePath, 'utf8');

    const asyncScript = `(async () => { ${scriptContent} })()`;

    // customRequire is needed to include relative requires from the collection folder
    // and to ensure that those required modules also require from the same collection folder + node path
    const customRequire = (id) => {
      if (id.startsWith("./") || id.startsWith("../")) {
        const newPath = path.resolve(config.collectionPath, id);

        const moduleContent = fs.readFileSync(newPath, 'utf8');

        // Create a module wrapper similar to Node.js CommonJS
        const moduleWrapper = `
          (function(exports, require, module, __filename, __dirname) {
            ${moduleContent}
          })
        `;
        const moduleObj = { exports: {} };
        const moduleDir = path.dirname(newPath);

        // Create a require function for this module that also uses customRequire
        const moduleRequire = (moduleId) => {
          if (moduleId.startsWith("./") || moduleId.startsWith("../")) {
            const modulePath = path.resolve(moduleDir, moduleId);
            const subModuleContent = fs.readFileSync(modulePath, 'utf8');

            const subModuleWrapper = `
              (function(exports, require, module, __filename, __dirname) {
                ${subModuleContent}
              })
            `;

            const subModuleObj = { exports: {} };
            const subModuleDir = path.dirname(modulePath);

            const subModuleContext = {
              ...context,
              exports: subModuleObj.exports,
              require: moduleRequire, // Recursive require
              module: subModuleObj,
              __filename: modulePath,
              __dirname: subModuleDir
            };

            vm.runInNewContext(subModuleWrapper, subModuleContext);
            return subModuleObj.exports;
          }
          return require(moduleId);
        };

        const moduleContext = {
          ...context,
          exports: moduleObj.exports,
          require: moduleRequire,
          module: moduleObj,
          __filename: newPath,
          __dirname: moduleDir
        };

        // Run the module in VM context
        vm.runInNewContext(moduleWrapper, moduleContext);
        return moduleObj.exports;
      }
      return require(id);
    };

    // Create the context with the custom require function
    const context = {
      req: req,
      res: res,
      bru: bru,
      fs: fs,
      path: path,
      console: console,
      process: process,
      require: customRequire
    };

    await vm.runInNewContext(asyncScript, context, {
      timeout: 30000,
      displayErrors: true
    });

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
