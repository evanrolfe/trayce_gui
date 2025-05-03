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

class BruEnvironmentGrammar extends GrammarDefinition<Map<String, dynamic>> with BasicCharacterParsers {
  @override
  Parser<Map<String, dynamic>> start() => ref0(bruFile).seq(ref0(stnl).star()).end().map((value) => value[0]);

  // PEG: BruEnvFile = (vars | secretvars)*
  Parser<Map<String, dynamic>> bruFile() =>
      (ref0(vars).or(ref0(secretvars))).seq(ref0(stnl).star()).star().map((value) {
        final result = <String, dynamic>{};
        for (final item in value) {
          final block = item[0] as Map<String, dynamic>;
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

  // Array Blocks
  Parser<List<String>> array() => ref0(st)
          .star()
          .seq(char('['))
          .seq(ref0(stnl).star())
          .seq(ref0(valuelist).optional())
          .seq(ref0(stnl).star())
          .seq(char(']'))
          .map((value) {
        final values = value[3] as List<String>? ?? [];
        return values;
      });

  Parser<List<String>> valuelist() => ref0(stnl)
          .star()
          .seq(ref0(arrayvalue))
          .seq((ref0(stnl).star().seq(char(',')).seq(ref0(stnl).star()).seq(ref0(arrayvalue))).star())
          .map((value) {
        final values = [value[1] as String];
        values.addAll((value[2] as List).map((e) => e[3] as String));
        return values;
      });
  Parser<String> arrayvalue() => ref0(arrayvaluechar).star().flatten();
  Parser<String> arrayvaluechar() =>
      ref0(nl).or(ref0(st)).or(char('[')).or(char(']')).or(char(',')).not().seq(any()).flatten();

  // secretvars and vars
  Parser<Map<String, dynamic>> secretvars() =>
      string('vars:secret').seq(ref0(st).plus()).seq(ref0(array)).map((value) => {
            'secrets': {'values': value[2] as List<String>}
          });

  Parser<Map<String, dynamic>> vars() => string('vars')
      .seq(ref0(st).plus())
      .seq(ref0(dictionary))
      .map((value) => {'vars': value[2] as Map<String, dynamic>});
}
