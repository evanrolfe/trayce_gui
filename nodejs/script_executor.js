const fs = require('fs');
const path = require('path');
const vm = require('vm');

const inbuiltPackages = [
  'ajv',
  'atob',
  'axios',
  'btoa',
  'chai',
  'cheerio',
  'crypto-js',
  'faker',
  'lodash',
  'moment',
  'nanoid',
  'node-fetch',
  'tv4',
  'uuid',
  'xml2js'
];

// Read and evaluate the target script
// (async () => {
//   await executeScript(config.script, config, req, res, bru);
// })();

/**
 * Executes a script file with the provided context and configuration
 * @param {string} scriptContent - The JS script to run
 * @param {Object} config - Configuration object containing collectionPath
 * @param {Object} req - Request instance
 * @param {Object} res - Response instance (can be null)
 * @param {Object} bru - Bru instance
 */
function executeScript(scriptContent, config, req, res, bru) {
  // Execute the script content using vm.runInNewContext with async wrapper
  const asyncScript = `(async () => { ${scriptContent} })()`;

  // Create the context first
  const context = {
    req: req,
    res: res,
    bru: bru,
    fs: fs,
    path: path,
    console: console,
    process: process
  };

  // Create a custom require function that handles relative paths and node_modules
  const customRequire = (id, callerPath = null) => {
    if (inbuiltPackages.includes(id)) {
      return require(id);
    }

    // Check if it's a relative path
    if (id.startsWith("./") || id.startsWith("../")) {
      // Handle relative paths from the collection-scripts directory
      const modulePath = path.join(config.collectionPath, id);

      // Load the module content
      const moduleContent = fs.readFileSync(modulePath, 'utf8');

      // Create module object
      const moduleObj = { exports: {} };
      const moduleDir = path.dirname(modulePath);

      // Create context for this module with access to customRequire
      const moduleContext = {
        ...context,
        exports: moduleObj.exports,
        require: customRequire, // Pass the same customRequire function
        module: moduleObj,
        __filename: modulePath,
        __dirname: moduleDir
      };

      // Run the module in VM context
      vm.runInNewContext(moduleContent, moduleContext, {
        timeout: 30000,
        displayErrors: true
      });

      return moduleObj.exports;
    } else {
      // Handle package imports from node_modules
      return require(path.join(config.collectionPath, "node_modules", id));
    }
  };

  // Add the custom require to the context
  context.require = customRequire;

  return vm.runInNewContext(asyncScript, context, {
    timeout: 30000,
    displayErrors: true
  });
}

module.exports = { executeScript };
