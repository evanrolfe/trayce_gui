#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { get } = require('@usebruno/query');
const axios = require('axios');

// Log function that only outputs if LOG_LEVEL=debug
function log(...args) {
  if (process.env.LOG_LEVEL === 'debug') {
    console.log(...args);
  }
}

// Request class to encapsulate all request properties
class Request {
  constructor(data) {
    this.method = data.method;
    this.url = data.url;
    this.mode = data.mode || 'none';
    this.vars = data.vars || [];
    this.auth = data.auth || null;
    this.body = data.body || null;
    this.name = data.name || null;
    this.authMode = data.authMode || null;
    this.headers = data.headers || {};
    this.timeout = data.timeout;
    this.executionMode = data.executionMode || 'standalone';
    this.executionPlatform = data.executionPlatform || 'app';
  }

  getUrl() {
    return this.url;
  }

  getMethod() {
    return this.method;
  }

  getHeaders() {
    return this.headers;
  }

  getHeader(name) {
    return this.headers[name] || null;
  }

  /**
   * Get the body of the request
   *
   * We automatically parse and return the JSON body if the content type is JSON
   * If the user wants the raw body, they can pass the raw option as true
   */
  getBody(options = {}) {
    if (options.raw) {
      return this.body;
    }

    const isJson = this.hasJSONContentType(this.headers);
    if (isJson) {
      return this.__safeParseJSON(this.body);
    }

    return this.body;
  }

  getName() {
    return this.name;
  }


  getAuthMode() {
    return this.authMode;
  }

  getTimeout() {
    return this.timeout;
  }

  setUrl(url) {
    this.url = url;
  }

  setMethod(method) {
    this.method = method;
  }

  setHeader(name, value) {
    this.headers[name] = value;
  }

  setHeaders(headers) {
    this.headers = headers;
  }

  setTimeout(timeout) {
    this.timeout = timeout;
  }

  setMaxRedirects(maxRedirects) {
    console.log('WARNING: setMaxRedirects() is not yet implemented');
  }

  setBody(body) {
    this.body = body;
  }

  getExecutionMode() {
    return this.executionMode; // standalone / runner
  }

  getExecutionPlatform() {
    return this.executionPlatform; // app / cli
  }

  /**
   * If the content type is JSON and if the data is an object
   *  - We set the body property as the object itself
   *  - We set the request data as the stringified JSON as it is what gets sent over the network
   * Otherwise
   *  - We set the request data as the data itself
   *  - We set the body property as the data itself
   *
   * If the user wants to override this behavior, they can pass the raw option as true
   */
  setBody(data, options = {}) {
    if (options.raw) {
      this.body = data;
      return;
    }

    const isJson = this.hasJSONContentType(this.headers);
    if (isJson && this.__isObject(data)) {
      this.body = __safeStringifyJSON(data);
      return;
    }

    this.body = data;
  }

  onFail(callback) {
    console.log('WARNING: onFail() is not yet implemented');
  }

  hasJSONContentType(headers) {
    const contentType = headers?.['Content-Type'] || headers?.['content-type'] || '';
    return contentType.includes('json');
  }

  toMap() {
    const body = this.getBody();
    return {
      method: this.method,
      url: this.url,
      mode: this.mode,
      vars: this.vars,
      auth: this.auth,
      body: body,
      name: this.name,
      authMode: this.authMode,
      headers: this.headers,
      timeout: this.timeout,
      executionMode: this.executionMode,
      executionPlatform: this.executionPlatform,
    };
  }

  __safeParseJSON(str) {
    try {
      return JSON.parse(str);
    } catch (e) {
      return str;
    }
  }

  __safeStringifyJSON(obj) {
    try {
      return JSON.stringify(obj);
    } catch (e) {
      return obj;
    }
  }

  __isObject(obj) {
    return obj !== null && typeof obj === 'object';
  }
}

// Response class to encapsulate all response properties
class Response {
  constructor(data) {
    this.status = data.status;
    this.statusText = data.statusText;
    this.body = data.body || null;
    this.headers = data.headers || {};
    this.url = data.url || null;
    this.statusText = data.statusText || null;
    this.size = data.size || null;
    this.responseTime = data.responseTime || null;


    // Make the instance callable
    const callable = (...args) => get(this.getBody(), ...args);
    Object.setPrototypeOf(callable, this.constructor.prototype);
    Object.assign(callable, this);

    return callable;
  }

  getStatus() {
    return this.status;
  }

  getStatusText() {
    return this.statusText;
  }

  /**
   * Get the parsed JSON body if the content type is JSON
   * If the user wants the raw body, they can pass the raw option as true
   */
  getBody(options = {}) {
    if (options.raw) {
      return this.body;
    }

    const isJson = this.hasJSONContentType(this.headers);
    if (isJson) {
      return this.__safeParseJSON(this.body);
    }

    return this.body;
  }

  getHeaders() {
    return this.headers;
  }

  getHeader(name) {
    // Case-insensitive header lookup
    const lowerName = name.toLowerCase();
    for (const [key, value] of Object.entries(this.headers)) {
      if (key.toLowerCase() === lowerName) {
        return value;
      }
    }
    return null;
  }

  getUrl() {
    return this.url;
  }

  getStatusText() {
    return this.statusText;
  }

  getSize() {
    return this.size;
  }

  getResponseTime() {
    return this.responseTime;
  }

  hasJSONContentType() {
    const contentType = this.headers?.['Content-Type'] || this.headers?.['content-type'] || '';
    return contentType.includes('json');
  }

  setBody(data) {
    this.body = data;
  }

  toMap() {
    return {
      status: this.status,
      body: this.body,
      headers: this.headers,
      url: this.url,
      statusText: this.statusText,
      size: this.size,
    };
  }

  __safeParseJSON(str) {
    try {
      return JSON.parse(str);
    } catch (e) {
      return str;
    }
  }
}

class Bru {
  constructor(requestMap, vars) {
    this.requestMap = requestMap;
    this.runtimeVars = vars.runtimeVars;
    this.requestVars = vars.requestVars;
    this.folderVars = vars.folderVars;
    this.collectionVars = vars.collectionVars;
    this.envVars = vars.envVars;
  }

  async runRequest(requestPath) {
    const request = this.requestMap[requestPath];
    if (!request) {
      throw new Error(`Request not found: ${requestPath}`);
    }

    // Create axios request config from the request object
    const axiosConfig = {
      method: request.method || 'GET',
      url: request.url,
      headers: request.headers || {},
      timeout: request.timeout || 30000,
    };

    // Handle different body formats
    if (request.data) {
      // For JSON data
      axiosConfig.data = request.data;
    } else if (request.body) {
      // For raw body
      axiosConfig.data = request.body;
    }

    // Handle query parameters
    if (request.params) {
      axiosConfig.params = request.params;
    }

    // Make the request
    const response = await axios(axiosConfig);

    // Create Response object from axios response
    const responseData = {
      status: response.status,
      statusText: response.statusText,
      body: response.data,
      headers: response.headers,
      url: response.config.url,
      size: JSON.stringify(response.data).length,
      responseTime: response.headers['x-response-time'] || null,
    };

    return new Response(responseData);
  }

  async sendRequest(config, callback) {
    try {
      // Create axios request config
      const axiosConfig = {
        method: config.method || 'GET',
        url: config.url,
        headers: config.headers || {},
        timeout: config.timeout || 30000,
      };

      // Handle different body formats
      if (config.data) {
        // For JSON data
        axiosConfig.data = config.data;
      } else if (config.body) {
        // For raw body
        axiosConfig.data = config.body;
      }

      // Handle query parameters
      if (config.params) {
        axiosConfig.params = config.params;
      }

      // Make the request
      const response = await axios(axiosConfig);

      // If callback is provided, use callback pattern
      if (typeof callback === 'function') {
        callback(null, response);
        return;
      }

      // Otherwise return the response for promise-based usage
      return res;

    } catch (error) {
      // Handle axios errors
      const errorResponse = {
        status: error.response?.status || 0,
        statusText: error.response?.statusText || 'Network Error',
        body: error.response?.data || error.message,
        headers: error.response?.headers || {},
        url: error.config?.url || config.url,
        size: 0,
        responseTime: null,
      };

      const res = new Response(errorResponse);

      // If callback is provided, use callback pattern
      if (typeof callback === 'function') {
        callback(error, res);
        return;
      }

      // Otherwise throw the error for promise-based usage
      throw error;
    }
  }

  setVar(name, value) {
    const varr = this.runtimeVars.find(varr => varr.name === name);
    if (varr) {
      varr.value = value;
    } else {
      this.runtimeVars.push({ name, value });
    }
  }

  setEnvVar(name, value) {
    const varr = this.envVars.find(varr => varr.name === name);
    if (varr) {
      varr.value = value;
    } else {
      this.envVars.push({ name, value });
    }
  }

  getVar(name) {
    return this.runtimeVars.find(varr => varr.name === name)?.value;
  }

  getRequestVar(name) {
    return this.requestVars.find(varr => varr.name === name)?.value;
  }

  getFolderVar(name) {
    return this.folderVars.find(varr => varr.name === name)?.value;
  }

  getCollectionVar(name) {
    return this.collectionVars.find(varr => varr.name === name)?.value;
  }

  getEnvVar(name) {
    return this.envVars.find(varr => varr.name === name)?.value;
  }

  deleteVar(name) {
    this.runtimeVars = this.runtimeVars.filter(varr => varr.name !== name);
  }

  toMap() {
    return { runtimeVars: this.runtimeVars, envVars: this.envVars };
  }
}

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
let scriptType = 'req';
if (config.response) {
  res = new Response(config.response);
  scriptType = 'res';
}

// Create the Bru instance
const bru = new Bru(config.requestMap, config.vars);

// Check if the file exists
if (!fs.existsSync(filePath)) {
  console.error(`File not found: ${filePath}`);
  process.exit(1);
}

// Create a context object with all the variables and request data
const scriptContext = {
  req: req,
  res: res,
  vars: req.vars,
  getVar: (name) => req.getVar(name),
  fs: fs,
  path: path,
  console: console,
  process: process,
  bru: bru,
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
              vars,
              getVar,
              fs,
              path,
              console,
              process,
              log,
              bru
          } = ctx;

          // Execute the script content as an async function
          return (async () => {
              ${scriptContent}
          })();
      `);

    await scriptFunction(scriptContext);

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
