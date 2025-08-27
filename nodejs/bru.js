const axios = require('axios');
const mockDataFunctions = require('./random');

class Bru {
  constructor(requestMap, vars) {
    this.requestMap = requestMap;
    this.runtimeVars = vars.runtimeVars;
    this.requestVars = vars.requestVars;
    this.folderVars = vars.folderVars;
    this.envVars = vars.envVars;
    this.collectionVars = vars.collectionVars;
    this.globalEnvVars = vars.globalEnvVars;
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

  setGlobalEnvVar(name, value) {
    const varr = this.globalEnvVars.find(varr => varr.name === name);
    if (varr) {
      varr.value = value;
    } else {
      this.globalEnvVars.push({ name, value });
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

  getGlobalEnvVar(name) {
    return this.globalEnvVars.find(varr => varr.name === name)?.value;
  }

  getProcessEnv(name) {
    return this.collectionVars.find(varr => varr.name === `process.env.${name}`)?.value;
  }

  deleteVar(name) {
    this.runtimeVars = this.runtimeVars.filter(varr => varr.name !== name);
  }

  toMap() {
    return { runtimeVars: this.runtimeVars, envVars: this.envVars, globalEnvVars: this.globalEnvVars };
  }

  interpolate(str) {
    if (typeof str !== 'string') {
      return str;
    }

    return str.replace(/\{\{([^}]+)\}\}/g, (match, varName) => {
      if (varName.startsWith('$')) {
        return mockDataFunctions[varName.slice(1)]();
      }

      // Check variables in order of precedence
      let value = this.getVar(varName);
      if (value !== undefined) return value;

      value = this.getRequestVar(varName);
      if (value !== undefined) return value;

      value = this.getFolderVar(varName);
      if (value !== undefined) return value;

      value = this.getEnvVar(varName);
      if (value !== undefined) return value;

      value = this.getCollectionVar(varName);
      if (value !== undefined) return value;

      // If variable not found, return the original placeholder
      return match;
    });
  }
}

module.exports = Bru;
