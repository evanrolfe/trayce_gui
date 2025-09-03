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

module.exports = Request;
