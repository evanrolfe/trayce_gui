import 'package:petitparser/petitparser.dart';

mixin BasicCharacterParsers {
  Parser<String> nl() => char('\r').optional().seq(char('\n')).flatten();
  Parser<String> st() => char(' ').or(char('\t')).flatten();
  Parser<String> stnl() => ref0(st).or(ref0(nl)).cast<String>();
  Parser<String> tagend() => ref0(nl).seq(char('}')).flatten();
  Parser<String> optionalnl() => ref0(tagend).not().seq(ref0(nl)).flatten();
  Parser<String> keychar() => ref0(tagend).or(ref0(st)).or(ref0(nl)).or(char(':')).not().seq(any()).flatten();
  Parser<String> valuechar() => ref0(nl).or(ref0(tagend)).not().seq(any()).flatten();
}

class BruRequestGrammar extends GrammarDefinition<Map<String, Map<String, dynamic>>> with BasicCharacterParsers {
  @override
  Parser<Map<String, Map<String, dynamic>>> start() => ref0(bruFile).end();

  // Main grammar structure
  Parser<Map<String, Map<String, dynamic>>> bruFile() => (ref0(meta)
              .or(ref0(http))
              .or(ref0(query))
              .or(ref0(params))
              .or(ref0(headers))
              .or(ref0(auths))
              .or(ref0(bodies))
              .or(ref0(varsandassert))
              .or(ref0(script))
              .or(ref0(tests))
              .or(ref0(docs)))
          .seq(ref0(stnl).star())
          .star()
          .map((value) {
        // value is a List of List: [[block, stnl*], ...]
        final result = <String, Map<String, dynamic>>{};
        for (final item in value) {
          final block = item[0] as Map<String, Map<String, dynamic>>;
          result.addAll(block);
        }
        return result;
      });

  // Multiline text block surrounded by '''
  Parser<String> multilinetextblockdelimiter() => string("'''");
  Parser<String> multilinetextblock() => ref0(multilinetextblockdelimiter)
      .seq(ref0(multilinetextblockdelimiter).not().seq(any()).star())
      .seq(ref0(multilinetextblockdelimiter))
      .flatten();

  // Dictionary Blocks
  Parser<Map<String, dynamic>> dictionary() =>
      ref0(st).star().seq(char('{')).seq(ref0(pairlist).optional()).seq(ref0(tagend)).map((value) {
        final pairs = value[2] as List<MapEntry<String, dynamic>>? ?? [];
        return Map.fromEntries(pairs);
      });
  Parser<List<MapEntry<String, dynamic>>> pairlist() => ref0(optionalnl)
          .star()
          .seq(ref0(pair))
          .seq((ref0(tagend).not().seq(ref0(stnl).star()).seq(ref0(pair))).star())
          .map((value) {
        final pairs = [value[1] as MapEntry<String, dynamic>];
        pairs.addAll((value[2] as List).map((e) => e[2] as MapEntry<String, dynamic>));
        return pairs;
      });
  Parser<MapEntry<String, dynamic>> pair() => ref0(st)
      .star()
      .seq(ref0(key))
      .seq(ref0(st).star())
      .seq(char(':'))
      .seq(ref0(st).star())
      .seq(ref0(value))
      .seq(ref0(st).star())
      .map((value) => MapEntry(value[1] as String, value[5] as dynamic));
  Parser<String> key() => ref0(keychar).star().flatten();
  Parser<dynamic> value() => ref0(multilinetextblock).or(ref0(valuechar).star().flatten());

  // Assert dictionary blocks
  Parser<Map<String, dynamic>> assertdictionary() =>
      ref0(st).star().seq(char('{')).seq(ref0(assertpairlist).optional()).seq(ref0(tagend)).map((value) {
        final pairs = value[2] as List<MapEntry<String, dynamic>>? ?? [];
        return Map.fromEntries(pairs);
      });
  Parser<List<MapEntry<String, dynamic>>> assertpairlist() => ref0(optionalnl)
          .star()
          .seq(ref0(assertpair))
          .seq((ref0(tagend).not().seq(ref0(stnl).star()).seq(ref0(assertpair))).star())
          .map((value) {
        final pairs = [value[1] as MapEntry<String, dynamic>];
        pairs.addAll((value[2] as List).map((e) => e[2] as MapEntry<String, dynamic>));
        return pairs;
      });
  Parser<MapEntry<String, dynamic>> assertpair() => ref0(st)
      .star()
      .seq(ref0(assertkey))
      .seq(ref0(st).star())
      .seq(char(':'))
      .seq(ref0(st).star())
      .seq(ref0(value))
      .seq(ref0(st).star())
      .map((value) => MapEntry(value[1] as String, value[5] as dynamic));
  Parser<String> assertkey() => ref0(assertkeychar).star().flatten();
  Parser<String> assertkeychar() => ref0(tagend).or(ref0(nl)).or(char(':')).not().seq(any()).flatten();

  // Text Blocks
  Parser<String> textblock() =>
      ref0(textline).seq((ref0(tagend).not().seq(ref0(nl)).seq(ref0(textline))).star()).flatten();
  Parser<String> textline() => ref0(textchar).star().flatten();
  Parser<String> textchar() => ref0(nl).not().seq(any()).flatten();

  // Meta
  Parser<Map<String, Map<String, dynamic>>> meta() => string('meta')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'meta': value[2] as Map<String, dynamic>});

  // HTTP method parsers
  Parser<Map<String, Map<String, dynamic>>> http() => ref0(get)
      .or(ref0(post))
      .or(ref0(put))
      .or(ref0(delete))
      .or(ref0(patch))
      .or(ref0(options))
      .or(ref0(head))
      .or(ref0(connect))
      .or(ref0(trace))
      .cast<Map<String, Map<String, dynamic>>>();

  Parser<Map<String, Map<String, dynamic>>> get() => string('get')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'get': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> post() => string('post')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'post': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> put() => string('put')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'put': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> delete() => string('delete')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'delete': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> patch() => string('patch')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'patch': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> options() => string('options')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'options': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> head() => string('head')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'head': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> connect() => string('connect')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'connect': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> trace() => string('trace')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'trace': value[2] as Map<String, dynamic>});

  // Headers and query parsers
  Parser<Map<String, Map<String, dynamic>>> headers() => string('headers')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'headers': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> query() => string('query')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'query': value[2] as Map<String, dynamic>});

  // Params parsers
  Parser<Map<String, Map<String, dynamic>>> params() =>
      ref0(paramspath).or(ref0(paramsquery)).cast<Map<String, Map<String, dynamic>>>();

  Parser<Map<String, Map<String, dynamic>>> paramspath() => string('params:path')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'params:path': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> paramsquery() => string('params:query')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'params:query': value[2] as Map<String, dynamic>});

  // Vars and assert parsers
  Parser<Map<String, Map<String, dynamic>>> varsandassert() =>
      ref0(varsreq).or(ref0(varsres)).or(ref0(asert)).cast<Map<String, Map<String, dynamic>>>();

  Parser<Map<String, Map<String, dynamic>>> varsreq() => string('vars:pre-request')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'vars:pre-request': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> varsres() => string('vars:post-response')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'vars:post-response': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> asert() => string('assert')
      .seq(ref0(st).plus())
      .seq(ref0(assertdictionary))
      .map((value) => {'assert': value[2] as Map<String, dynamic>});

  // Auth parsers
  Parser<Map<String, Map<String, dynamic>>> auths() => (ref0(authawsv4)
          .or(ref0(authbearer))
          .or(ref0(authbasic))
          .or(ref0(authdigest))
          .or(ref0(authoauth1))
          .or(ref0(authoauth2))
          .or(ref0(authntlm))
          .or(ref0(authapikey))
          .or(ref0(authwsse))
      // Add more as needed: authntlm, authapikey, etc.
      )
      .cast<Map<String, Map<String, dynamic>>>();

  Parser<Map<String, Map<String, dynamic>>> authawsv4() => string('auth:awsv4')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth:awsv4': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> authbearer() => string('auth:bearer')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth:bearer': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> authbasic() => string('auth:basic')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth:basic': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> authdigest() => string('auth:digest')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth:digest': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> authoauth1() => string('auth:oauth1')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth:oauth1': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> authoauth2() => string('auth:oauth2')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth:oauth2': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> authntlm() => string('auth:ntlm')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth:ntlm': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> authapikey() => string('auth:apikey')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth:apikey': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> authwsse() => string('auth:wsse')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth:wsse': value[2] as Map<String, dynamic>});

  // Body parsers
  Parser<Map<String, Map<String, dynamic>>> bodies() => ref0(bodyjson)
      .or(ref0(bodytext))
      .or(ref0(bodyxml))
      .or(ref0(bodysparql))
      .or(ref0(bodygraphql))
      .or(ref0(bodygraphqlvars))
      .or(ref0(bodyforms))
      .or(ref0(body))
      .cast<Map<String, Map<String, dynamic>>>();

  Parser<Map<String, Map<String, dynamic>>> bodyforms() =>
      ref0(bodyformurlencoded).or(ref0(bodymultipart)).or(ref0(bodyfile)).cast<Map<String, Map<String, dynamic>>>();

  Parser<Map<String, Map<String, dynamic>>> body() => string('body')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'body': {'content': value[4] as String}
          });

  Parser<Map<String, Map<String, dynamic>>> bodyjson() => string('body:json')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'body:json': {'content': value[4] as String}
          });

  Parser<Map<String, Map<String, dynamic>>> bodytext() => string('body:text')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'body:text': {'content': value[4] as String}
          });

  Parser<Map<String, Map<String, dynamic>>> bodyxml() => string('body:xml')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'body:xml': {'content': value[4] as String}
          });

  Parser<Map<String, Map<String, dynamic>>> bodysparql() => string('body:sparql')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'body:sparql': {'content': value[4] as String}
          });

  Parser<Map<String, Map<String, dynamic>>> bodygraphql() => string('body:graphql')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'body:graphql': {'content': value[4] as String}
          });

  Parser<Map<String, Map<String, dynamic>>> bodygraphqlvars() => string('body:graphql:vars')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'body:graphql:vars': {'content': value[4] as String}
          });

  Parser<Map<String, Map<String, dynamic>>> bodyformurlencoded() => string('body:form-urlencoded')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'body:form-urlencoded': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> bodymultipart() => string('body:multipart-form')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'body:multipart-form': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> bodyfile() => string('body:file')
          .seq(ref0(st).plus())
          .seq(char('{'))
          .seq(ref0(filepairlist).optional())
          .seq(ref0(tagend))
          .map((value) {
        final pairs = value[3] as List<MapEntry<String, List<String>>>? ?? [];
        final result = <String, List<String>>{};

        // Group values by key
        for (final pair in pairs) {
          final key = pair.key;
          final value = pair.value;

          if (result.containsKey(key)) {
            result[key]!.addAll(value);
          } else {
            result[key] = value;
          }
        }

        return {'body:file': result};
      });

  Parser<List<MapEntry<String, List<String>>>> filepairlist() => ref0(optionalnl)
          .star()
          .seq(ref0(filepair))
          .seq((ref0(tagend).not().seq(ref0(stnl).star()).seq(ref0(filepair))).star())
          .map((value) {
        final pairs = [value[1] as MapEntry<String, List<String>>];
        pairs.addAll((value[2] as List).map((e) => e[2] as MapEntry<String, List<String>>));
        return pairs;
      });

  Parser<MapEntry<String, List<String>>> filepair() => ref0(st)
      .star()
      .seq(ref0(key))
      .seq(ref0(st).star())
      .seq(char(':'))
      .seq(ref0(st).star())
      .seq(ref0(value))
      .seq(ref0(st).star())
      .map((value) => MapEntry(value[1] as String, [value[5] as String]));

  // Script parsers
  Parser<Map<String, Map<String, dynamic>>> script() =>
      ref0(scriptreq).or(ref0(scriptres)).cast<Map<String, Map<String, dynamic>>>();

  Parser<Map<String, Map<String, dynamic>>> scriptreq() => string('script:pre-request')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'script:pre-request': {'content': value[4] as String}
          });

  Parser<Map<String, Map<String, dynamic>>> scriptres() => string('script:post-response')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'script:post-response': {'content': value[4] as String}
          });

  // Tests and docs parsers
  Parser<Map<String, Map<String, dynamic>>> tests() => string('tests')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'tests': {'content': value[4] as String}
          });

  Parser<Map<String, Map<String, dynamic>>> docs() => string('docs')
      .seq(ref0(st).star())
      .seq(char('{'))
      .seq(ref0(nl).star())
      .seq(ref0(textblock))
      .seq(ref0(tagend))
      .map((value) => {
            'docs': {'content': value[4] as String}
          });
}
