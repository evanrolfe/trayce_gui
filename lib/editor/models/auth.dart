import 'utils.dart';

abstract class Auth {
  String get type;
  String toBru();
  bool equals(Auth other);
  Auth deepCopy();
  bool isEmpty();
}

class AwsV4Auth extends Auth {
  @override
  final String type = 'awsv4';
  String accessKeyId;
  String secretAccessKey;
  String sessionToken;
  String service;
  String region;
  String profileName;

  AwsV4Auth({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.sessionToken,
    required this.service,
    required this.region,
    required this.profileName,
  });

  @override
  bool equals(Auth other) {
    if (other is! AwsV4Auth) return false;
    return accessKeyId == other.accessKeyId &&
        secretAccessKey == other.secretAccessKey &&
        sessionToken == other.sessionToken &&
        service == other.service &&
        region == other.region &&
        profileName == other.profileName;
  }

  @override
  Auth deepCopy() {
    return AwsV4Auth(
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      sessionToken: sessionToken,
      service: service,
      region: region,
      profileName: profileName,
    );
  }

  @override
  String toBru() {
    return '''auth:awsv4 {
${indentString('accessKeyId: $accessKeyId')}
${indentString('secretAccessKey: $secretAccessKey')}
${indentString('sessionToken: $sessionToken')}
${indentString('service: $service')}
${indentString('region: $region')}
${indentString('profileName: $profileName')}
}''';
  }

  @override
  bool isEmpty() {
    return accessKeyId.isEmpty &&
        secretAccessKey.isEmpty &&
        sessionToken.isEmpty &&
        service.isEmpty &&
        region.isEmpty &&
        profileName.isEmpty;
  }
}

class BasicAuth extends Auth {
  @override
  final String type = 'basic';
  String username;
  String password;

  BasicAuth({required this.username, required this.password});

  @override
  bool equals(Auth other) {
    if (other is! BasicAuth) return false;
    return username == other.username && password == other.password;
  }

  @override
  Auth deepCopy() {
    return BasicAuth(username: username, password: password);
  }

  @override
  String toBru() {
    return '''auth:basic {
${indentString('username: $username')}
${indentString('password: $password')}
}''';
  }

  @override
  bool isEmpty() {
    return username.isEmpty && password.isEmpty;
  }
}

class BearerAuth extends Auth {
  @override
  final String type = 'bearer';
  String token;

  BearerAuth({required this.token});

  @override
  bool equals(Auth other) {
    if (other is! BearerAuth) return false;
    return token == other.token;
  }

  @override
  String toBru() {
    return '''auth:bearer {
${indentString('token: $token')}
}''';
  }

  @override
  Auth deepCopy() {
    return BearerAuth(token: token);
  }

  @override
  bool isEmpty() {
    return token.isEmpty;
  }
}

class DigestAuth extends Auth {
  @override
  final String type = 'digest';
  String username;
  String password;

  DigestAuth({required this.username, required this.password});

  @override
  bool equals(Auth other) {
    if (other is! DigestAuth) return false;
    return username == other.username && password == other.password;
  }

  @override
  String toBru() {
    return '''auth:digest {
${indentString('username: $username')}
${indentString('password: $password')}
}''';
  }

  @override
  Auth deepCopy() {
    return DigestAuth(username: username, password: password);
  }

  @override
  bool isEmpty() {
    return username.isEmpty && password.isEmpty;
  }
}

class OAuth2Auth extends Auth {
  @override
  final String type = 'oauth2';
  String accessTokenUrl;
  String authorizationUrl;
  bool autoFetchToken;
  bool autoRefreshToken;
  String callbackUrl;
  String clientId;
  String clientSecret;
  String credentialsId;
  String credentialsPlacement;
  String grantType;
  bool pkce;
  String refreshTokenUrl;
  String scope;
  String state;
  String tokenHeaderPrefix;
  String tokenPlacement;
  String tokenQueryKey;

  OAuth2Auth({
    required this.accessTokenUrl,
    required this.authorizationUrl,
    required this.autoFetchToken,
    required this.autoRefreshToken,
    required this.callbackUrl,
    required this.clientId,
    required this.clientSecret,
    required this.credentialsId,
    required this.credentialsPlacement,
    required this.grantType,
    required this.pkce,
    required this.refreshTokenUrl,
    required this.scope,
    required this.state,
    required this.tokenHeaderPrefix,
    required this.tokenPlacement,
    required this.tokenQueryKey,
  });

  @override
  bool equals(Auth other) {
    if (other is! OAuth2Auth) return false;
    return accessTokenUrl == other.accessTokenUrl &&
        authorizationUrl == other.authorizationUrl &&
        autoFetchToken == other.autoFetchToken &&
        autoRefreshToken == other.autoRefreshToken &&
        callbackUrl == other.callbackUrl &&
        clientId == other.clientId &&
        clientSecret == other.clientSecret &&
        credentialsId == other.credentialsId &&
        credentialsPlacement == other.credentialsPlacement &&
        grantType == other.grantType &&
        pkce == other.pkce &&
        refreshTokenUrl == other.refreshTokenUrl &&
        scope == other.scope &&
        state == other.state &&
        tokenHeaderPrefix == other.tokenHeaderPrefix &&
        tokenPlacement == other.tokenPlacement &&
        tokenQueryKey == other.tokenQueryKey;
  }

  @override
  Auth deepCopy() {
    return OAuth2Auth(
      accessTokenUrl: accessTokenUrl,
      authorizationUrl: authorizationUrl,
      autoFetchToken: autoFetchToken,
      autoRefreshToken: autoRefreshToken,
      callbackUrl: callbackUrl,
      clientId: clientId,
      clientSecret: clientSecret,
      credentialsId: credentialsId,
      credentialsPlacement: credentialsPlacement,
      grantType: grantType,
      pkce: pkce,
      refreshTokenUrl: refreshTokenUrl,
      scope: scope,
      state: state,
      tokenHeaderPrefix: tokenHeaderPrefix,
      tokenPlacement: tokenPlacement,
      tokenQueryKey: tokenQueryKey,
    );
  }

  @override
  String toBru() {
    var bru = 'auth:oauth2 {\n';

    switch (grantType) {
      case 'password':
        bru += '''${indentString('grant_type: password')}
${indentString('access_token_url: $accessTokenUrl')}
${indentString('refresh_token_url: $refreshTokenUrl')}
${indentString('client_id: $clientId')}
${indentString('client_secret: $clientSecret')}
${indentString('scope: $scope')}
${indentString('credentials_placement: $credentialsPlacement')}
${indentString('credentials_id: $credentialsId')}
${indentString('token_placement: $tokenPlacement')}''';

        if (tokenPlacement == 'header') {
          bru += '\n${indentString('token_header_prefix: $tokenHeaderPrefix')}\n';
        } else {
          bru += '\n${indentString('token_query_key: $tokenQueryKey')}\n';
        }

        bru += '''
${indentString('auto_fetch_token: $autoFetchToken')}
${indentString('auto_refresh_token: $autoRefreshToken')}
}''';
        break;

      case 'authorization_code':
        bru += '''${indentString('grant_type: authorization_code')}
${indentString('callback_url: $callbackUrl')}
${indentString('authorization_url: $authorizationUrl')}
${indentString('access_token_url: $accessTokenUrl')}
${indentString('refresh_token_url: $refreshTokenUrl')}
${indentString('client_id: $clientId')}
${indentString('client_secret: $clientSecret')}
${indentString('scope: $scope')}
${indentString('state: $state')}
${indentString('pkce: $pkce')}
${indentString('credentials_placement: $credentialsPlacement')}
${indentString('credentials_id: $credentialsId')}
${indentString('token_placement: $tokenPlacement')}''';

        if (tokenPlacement == 'header') {
          bru += '\n${indentString('token_header_prefix: $tokenHeaderPrefix')}\n';
        } else {
          bru += '\n${indentString('token_query_key: $tokenQueryKey')}\n';
        }

        bru += '''
${indentString('auto_fetch_token: $autoFetchToken')}
${indentString('auto_refresh_token: $autoRefreshToken')}
}''';
        break;

      case 'client_credentials':
        bru += '''${indentString('grant_type: client_credentials')}
${indentString('access_token_url: $accessTokenUrl')}
${indentString('refresh_token_url: $refreshTokenUrl')}
${indentString('client_id: $clientId')}
${indentString('client_secret: $clientSecret')}
${indentString('scope: $scope')}
${indentString('credentials_placement: $credentialsPlacement')}
${indentString('credentials_id: $credentialsId')}
${indentString('token_placement: $tokenPlacement')}''';

        if (tokenPlacement == 'header') {
          bru += '\n${indentString('token_header_prefix: $tokenHeaderPrefix')}\n';
        } else {
          bru += '\n${indentString('token_query_key: $tokenQueryKey')}\n';
        }

        bru += '''
${indentString('auto_fetch_token: $autoFetchToken')}
${indentString('auto_refresh_token: $autoRefreshToken')}}''';
        break;
    }

    return bru;
  }

  @override
  bool isEmpty() {
    return accessTokenUrl.isEmpty &&
        authorizationUrl.isEmpty &&
        autoFetchToken &&
        autoRefreshToken &&
        callbackUrl.isEmpty &&
        clientId.isEmpty &&
        clientSecret.isEmpty &&
        credentialsId.isEmpty &&
        credentialsPlacement.isEmpty &&
        grantType.isEmpty &&
        pkce &&
        refreshTokenUrl.isEmpty &&
        scope.isEmpty &&
        state.isEmpty &&
        tokenHeaderPrefix.isEmpty &&
        tokenPlacement.isEmpty &&
        tokenQueryKey.isEmpty;
  }
}

class WsseAuth extends Auth {
  @override
  final String type = 'wsse';
  String username;
  String password;

  WsseAuth({required this.username, required this.password});

  @override
  bool equals(Auth other) {
    if (other is! WsseAuth) return false;
    return username == other.username && password == other.password;
  }

  @override
  String toBru() {
    return '''auth:wsse {
${indentString('username: $username')}
${indentString('password: $password')}
}''';
  }

  @override
  Auth deepCopy() {
    return WsseAuth(username: username, password: password);
  }

  @override
  bool isEmpty() {
    return username.isEmpty && password.isEmpty;
  }
}
