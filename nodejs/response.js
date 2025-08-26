const { get } = require('@usebruno/query');

// Response class to encapsulate all response properties
class Response {
  constructor(data) {
    this.status = data.status;
    this.statusText = data.statusText;
    this.bodyRaw = data.body || null;
    if (this.bodyRaw) {
      this.body = this.__safeParseJSON(this.bodyRaw);
    }
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
      return this.bodyRaw;
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
    this.bodyRaw = JSON.stringify(data);
  }

  toMap() {
    return {
      status: this.status,
      body: this.bodyRaw,
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

module.exports = Response;
