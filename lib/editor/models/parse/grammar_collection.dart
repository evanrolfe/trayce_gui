import 'package:petitparser/petitparser.dart';

import 'grammar_request.dart';

class BruCollectionGrammar extends GrammarDefinition<Map<String, Map<String, dynamic>>> with BasicCharacterParsers {
  @override
  Parser<Map<String, Map<String, dynamic>>> start() => ref0(bruFile).end();

  // Main grammar structure
  Parser<Map<String, Map<String, dynamic>>> bruFile() => (ref0(meta)
              .or(ref0(query))
              .or(ref0(headers))
              .or(ref0(auth))
              .or(ref0(auths))
              .or(ref0(vars))
              .or(ref0(script))
              .or(ref0(tests))
              .or(ref0(docs)))
          .seq(ref0(stnl).star())
          .star()
          .map((value) {
        final result = <String, Map<String, dynamic>>{};
        for (final item in value) {
          final block = item[0] as Map<String, Map<String, dynamic>>;
          result.addAll(block);
        }
        return result;
      });

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
  Parser<dynamic> value() => ref0(valuechar).star().flatten();

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

  // Headers and query parsers
  Parser<Map<String, Map<String, dynamic>>> headers() => string('headers')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'headers': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> query() => string('query')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'query': value[2] as Map<String, dynamic>});

  // Add auth parser for "auth" dictionary
  Parser<Map<String, Map<String, dynamic>>> auth() => string('auth')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'auth': value[2] as Map<String, dynamic>});

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

  // Vars block as in PEG
  Parser<Map<String, Map<String, dynamic>>> vars() =>
      ref0(varsreq).or(ref0(varsres)).cast<Map<String, Map<String, dynamic>>>();

  Parser<Map<String, Map<String, dynamic>>> varsreq() => string('vars:pre-request')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'vars:pre-request': value[2] as Map<String, dynamic>});

  Parser<Map<String, Map<String, dynamic>>> varsres() => string('vars:post-response')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'vars:post-response': value[2] as Map<String, dynamic>});

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
