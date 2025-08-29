# How are NodeJS scripts run

In `lib/editor/repo/send_request.dart` it extracts the pre & post response scripts from the Request and writes them to a temporary file i.e. (linux): `~/.local/share/trayce/nodejs/trayce_post_resp-$uuid.js`.

It then runs `nodejs/script_req.js` with that file path as a CLI arg, along with a json object containing all the necessary data:
```
    final cliArgs = {
    'request': request.toMap(),
    'response': _httpResponseToMap(response, responseTime),
    'requestMap': requestMap,
    'collectionName': collectionNode.collection!.dir.path,
    'collectionPath': collectionNode.collection!.absolutePath(),
    'vars': _getVarsMap(node),
    };
```

- request: used for the `req` json class
- response: used for the `res` json class (only available in post-response scripts)
- requestMap: used to generate functions for making collection requests within scripts with `bru.runRequest()`
- collectionName - obvious
- collectionPath - used to determine where node `require()` statements should import from
- vars - used for getVar(), getEnvVar() etc. functions

`script_req.js`  parses the json object into classes and then runs the script file inside a nodejs vm. It passes the req, res and bru instances to the vm context. It then prints an output json object to stdout, this contains the variables after modification, response after modification etc.

`send_request.dart` then parses the json object from stdout and applies any modifications to the vars, response etc.

## customRequire()

In `script_req.js` we pass a custom `require()` function to the vm context. This is so we can modify the import paths based on this rule:
- in-built packages (faker, uuid, chai etc.) resolves to the app node_modules dir (i.e. `~/.local/share/trayce/nodejs/node_modules` in linux)
- relative imports resolves to the collection dir
- all other imports (these are usually the ones made from within a collection's node_module packages) resolves to collection dir + /node_modules

The last rule is made so that relative imports from with a collection's node_modules package can still work.

## Why is it done this way?

I've investigated various nodejs binding packages for dart but none of them looked adequate, most seemed poorly maintained and none did exactly what I needed them to do. So I opted to simply run nodejs from the command line, with dart passing a json object to it and receiving a json object via stdout.
