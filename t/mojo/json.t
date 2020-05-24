use Mojo::Base -strict;

BEGIN { $ENV{MOJO_NO_JSON_XS} = 1 }

package JSONTest;
use Mojo::Base -base;

has 'something' => sub { {} };

sub TO_JSON { shift->something }

package JSONTest2;
use Mojo::Base -base;
use overload '&' => sub {die}, '""' => sub {'works!'};

package main;

use Test::More;
use Mojo::ByteStream qw(b);
use Mojo::JSON qw(decode_json encode_json false from_json j to_json true);
use Mojo::Util qw(encode);
use Scalar::Util qw(dualvar);

subtest 'Decode array' => sub {
  my $array = decode_json '[]';
  is_deeply $array, [], 'decode []';
  $array = decode_json '[ [ ]]';
  is_deeply $array, [[]], 'decode [ [ ]]';
};

subtest 'Decode number' => sub {
  my $array = decode_json '[0]';
  is_deeply $array, [0], 'decode [0]';
  $array = decode_json '[1]';
  is_deeply $array, [1], 'decode [1]';
  $array = decode_json '[ "-122.026020" ]';
  is_deeply $array, ['-122.026020'], 'decode [ -122.026020 ]';
  $array = decode_json '[ -122.026020 ]';
  is_deeply $array, ['-122.02602'], 'decode [ -122.026020 ]';
  $array = decode_json '[0.0]';
  cmp_ok $array->[0], '==', 0, 'value is 0';
  $array = decode_json '[0e0]';
  cmp_ok $array->[0], '==', 0, 'value is 0';
  $array = decode_json '[1,-2]';
  is_deeply $array, [1, -2], 'decode [1,-2]';
  $array = decode_json '["10e12" , [2 ]]';
  is_deeply $array, ['10e12', [2]], 'decode ["10e12" , [2 ]]';
  $array = decode_json '[10e12 , [2 ]]';
  is_deeply $array, [10000000000000, [2]], 'decode [10e12 , [2 ]]';
  $array = decode_json '[37.7668 , [ 20 ]] ';
  is_deeply $array, [37.7668, [20]], 'decode [37.7668 , [ 20 ]] ';
  $array = decode_json '[1e3]';
  cmp_ok $array->[0], '==', 1e3, 'value is 1e3';
  my $value = decode_json '0';
  cmp_ok $value, '==', 0, 'decode 0';
  $value = decode_json '23.3';
  cmp_ok $value, '==', 23.3, 'decode 23.3';
};

subtest 'Decode name' => sub {
  my $array = decode_json '[true]';
  is_deeply $array, [Mojo::JSON->true], 'decode [true]';
  $array = decode_json '[null]';
  is_deeply $array, [undef], 'decode [null]';
  $array = decode_json '[true, false]';
  is_deeply $array, [true, false], 'decode [true, false]';
  my $value = decode_json 'true';
  is $value, Mojo::JSON->true, 'decode true';
  $value = decode_json 'false';
  is $value, Mojo::JSON->false, 'decode false';
  $value = decode_json 'null';
  is $value, undef, 'decode null';
};

subtest 'Decode string' => sub {
  my $array = decode_json '[" "]';
  is_deeply $array, [' '], 'decode [" "]';
  $array = decode_json '["hello world!"]';
  is_deeply $array, ['hello world!'], 'decode ["hello world!"]';
  $array = decode_json '["hello\nworld!"]';
  is_deeply $array, ["hello\nworld!"], 'decode ["hello\nworld!"]';
  $array = decode_json '["hello\t\"world!"]';
  is_deeply $array, ["hello\t\"world!"], 'decode ["hello\t\"world!"]';
  $array = decode_json '["hello\u0152world\u0152!"]';
  is_deeply $array, ["hello\x{0152}world\x{0152}!"],
    'decode ["hello\u0152world\u0152!"]';
  $array = decode_json '["0."]';
  is_deeply $array, ['0.'], 'decode ["0."]';
  $array = decode_json '[" 0"]';
  is_deeply $array, [' 0'], 'decode [" 0"]';
  $array = decode_json '["1"]';
  is_deeply $array, ['1'], 'decode ["1"]';
  $array = decode_json '["\u0007\b\/\f\r"]';
  is_deeply $array, ["\a\b/\f\r"], 'decode ["\u0007\b\/\f\r"]';
  my $value = decode_json '""';
  is $value, '', 'decode ""';
  $value = decode_json '"hell\no"';
  is $value, "hell\no", 'decode "hell\no"';
};

subtest 'Decode object' => sub {
  my $hash = decode_json '{}';
  is_deeply $hash, {}, 'decode {}';
  $hash = decode_json '{"foo": "bar"}';
  is_deeply $hash, {foo => 'bar'}, 'decode {"foo": "bar"}';
  $hash = decode_json '{"foo": [23, "bar"]}';
  is_deeply $hash, {foo => [qw(23 bar)]}, 'decode {"foo": [23, "bar"]}';
};

subtest 'Decode full spec example' => sub {
  my $hash = decode_json <<EOF;
{
   "Image": {
       "Width":  800,
       "Height": 600,
       "Title":  "View from 15th Floor",
       "Thumbnail": {
           "Url":    "http://www.example.com/image/481989943",
           "Height": 125,
           "Width":  "100"
       },
       "IDs": [116, 943, 234, 38793]
    }
}
EOF
  is $hash->{Image}{Width},  800,                    'right value';
  is $hash->{Image}{Height}, 600,                    'right value';
  is $hash->{Image}{Title},  'View from 15th Floor', 'right value';
  is $hash->{Image}{Thumbnail}{Url}, 'http://www.example.com/image/481989943',
    'right value';
  is $hash->{Image}{Thumbnail}{Height}, 125, 'right value';
  is $hash->{Image}{Thumbnail}{Width},  100, 'right value';
  is $hash->{Image}{IDs}[0], 116,   'right value';
  is $hash->{Image}{IDs}[1], 943,   'right value';
  is $hash->{Image}{IDs}[2], 234,   'right value';
  is $hash->{Image}{IDs}[3], 38793, 'right value';
};

subtest 'Encode array' => sub {
  my $bytes = encode_json [];
  is $bytes, '[]', 'encode []';
  $bytes = encode_json [[]];
  is $bytes, '[[]]', 'encode [[]]';
  $bytes = encode_json [[], []];
  is $bytes, '[[],[]]', 'encode [[], []]';
  $bytes = encode_json [[], [[]], []];
  is $bytes, '[[],[[]],[]]', 'encode [[], [[]], []]';
};

subtest 'Encode string' => sub {
  my $bytes = encode_json ['foo'];
  is $bytes, '["foo"]', 'encode [\'foo\']';
  $bytes = encode_json ["hello\nworld!"];
  is $bytes, '["hello\nworld!"]', 'encode ["hello\nworld!"]';
  $bytes = encode_json ["hello\t\"world!"];
  is $bytes, '["hello\t\"world!"]', 'encode ["hello\t\"world!"]';
  $bytes = encode_json ["hello\x{0003}\x{0152}world\x{0152}!"];
  is b($bytes)->decode('UTF-8'), "[\"hello\\u0003\x{0152}world\x{0152}!\"]",
    'encode ["hello\x{0003}\x{0152}world\x{0152}!"]';
  $bytes = encode_json ["123abc"];
  is $bytes, '["123abc"]', 'encode ["123abc"]';
  $bytes = encode_json ["\x00\x1f \a\b/\f\r"];
  is $bytes, '["\\u0000\\u001F \\u0007\\b\/\f\r"]',
    'encode ["\x00\x1f \a\b/\f\r"]';
  $bytes = encode_json '';
  is $bytes, '""', 'encode ""';
  $bytes = encode_json "hell\no";
  is $bytes, '"hell\no"', 'encode "hell\no"';
};

subtest 'Encode object' => sub {
  my $bytes = encode_json {};
  is $bytes, '{}', 'encode {}';
  $bytes = encode_json {foo => {}};
  is $bytes, '{"foo":{}}', 'encode {foo => {}}';
  $bytes = encode_json {foo => 'bar'};
  is $bytes, '{"foo":"bar"}', 'encode {foo => \'bar\'}';
  $bytes = encode_json {foo => []};
  is $bytes, '{"foo":[]}', 'encode {foo => []}';
  $bytes = encode_json {foo => ['bar']};
  is $bytes, '{"foo":["bar"]}', 'encode {foo => [\'bar\']}';
  $bytes = encode_json {foo => 'bar', baz => 'yada'};
  is $bytes, '{"baz":"yada","foo":"bar"}',
    'encode {foo => \'bar\', baz => \'yada\'}';
};

subtest 'Encode name' => sub {
  my $bytes = encode_json [Mojo::JSON->true];
  is $bytes, '[true]', 'encode [Mojo::JSON->true]';
  $bytes = encode_json [undef];
  is $bytes, '[null]', 'encode [undef]';
  $bytes = encode_json [Mojo::JSON->true, Mojo::JSON->false];
  is $bytes, '[true,false]', 'encode [Mojo::JSON->true, Mojo::JSON->false]';
  $bytes = encode_json(Mojo::JSON->true);
  is $bytes, 'true', 'encode Mojo::JSON->true';
  $bytes = encode_json(Mojo::JSON->false);
  is $bytes, 'false', 'encode Mojo::JSON->false';
  $bytes = encode_json undef;
  is $bytes, 'null', 'encode undef';
};

subtest 'Encode number' => sub {
  my $bytes = encode_json [1];
  is $bytes, '[1]', 'encode [1]';
  $bytes = encode_json ["1"];
  is $bytes, '["1"]', 'encode ["1"]';
  $bytes = encode_json ['-122.026020'];
  is $bytes, '["-122.026020"]', 'encode [\'-122.026020\']';
  $bytes = encode_json [-122.026020];
  is $bytes, '[-122.02602]', 'encode [-122.026020]';
  $bytes = encode_json [1, -2];
  is $bytes, '[1,-2]', 'encode [1, -2]';
  $bytes = encode_json ['10e12', [2]];
  is $bytes, '["10e12",[2]]', 'encode [\'10e12\', [2]]';
  $bytes = encode_json [10e12, [2]];
  is $bytes, '[10000000000000,[2]]', 'encode [10e12, [2]]';
  $bytes = encode_json [37.7668, [20]];
  is $bytes, '[37.7668,[20]]', 'encode [37.7668, [20]]';
  $bytes = encode_json 0;
  is $bytes, '0', 'encode 0';
  $bytes = encode_json 23.3;
  is $bytes, '23.3', 'encode 23.3';
};

subtest 'Faihu roundtrip' => sub {
  my $bytes = j(["\x{10346}"]);
  is b($bytes)->decode('UTF-8'), "[\"\x{10346}\"]", 'encode ["\x{10346}"]';
  my $array = j($bytes);
  is_deeply $array, ["\x{10346}"], 'successful roundtrip';
};

subtest 'Decode faihu surrogate pair' => sub {
  my $array = decode_json '["\\ud800\\udf46"]';
  is_deeply $array, ["\x{10346}"], 'decode [\"\\ud800\\udf46\"]';
};

subtest 'Complicated roundtrips' => sub {
  my $bytes = '{"":""}';
  my $hash  = decode_json $bytes;
  is_deeply $hash, {'' => ''}, 'decode {"":""}';
  is encode_json($hash), $bytes, 're-encode';
  $bytes = '[null,false,true,"",0,1]';
  my $array = decode_json $bytes;
  is_deeply $array, [undef, Mojo::JSON->false, Mojo::JSON->true, '', 0, 1],
    'decode [null,false,true,"",0,1]';
  is encode_json($array), $bytes, 're-encode';
  $array = [undef, 0, 1, '', Mojo::JSON->true, Mojo::JSON->false];
  $bytes = encode_json($array);
  ok $bytes, 'defined value';
  is_deeply decode_json($bytes), $array, 'successful roundtrip';
};

subtest 'Real world roundtrip' => sub {
  my $bytes = encode_json({foo => 'c:\progra~1\mozill~1\firefox.exe'});
  is $bytes, '{"foo":"c:\\\\progra~1\\\\mozill~1\\\\firefox.exe"}',
    'encode {foo => \'c:\progra~1\mozill~1\firefox.exe\'}';
  my $hash = decode_json $bytes;
  is_deeply $hash, {foo => 'c:\progra~1\mozill~1\firefox.exe'},
    'successful roundtrip';
};

subtest 'Huge string' => sub {
  my $bytes = encode_json(['a' x 32768]);
  is_deeply decode_json($bytes), ['a' x 32768], 'successful roundtrip';
};

subtest 'Slash' => sub {
  my $bytes = encode_json ['123</script>'];
  is $bytes, '["123<\/script>"]', 'escaped slash';
  is_deeply decode_json($bytes), ['123</script>'], 'successful roundtrip';
};

subtest 'JSON without UTF-8 encoding' => sub {
  is_deeply from_json('["♥"]'), ['♥'], 'characters decoded';
  is to_json(['♥']), '["♥"]', 'characters encoded';
  is_deeply from_json(to_json(["\xe9"])), ["\xe9"], 'successful roundtrip';
};

subtest 'Blessed reference' => sub {
  my $bytes = encode_json [b('test')];
  is_deeply decode_json($bytes), ['test'], 'successful roundtrip';
};

subtest 'Blessed reference with TO_JSON method' => sub {
  my $bytes = encode_json(JSONTest->new);
  is_deeply decode_json($bytes), {}, 'successful roundtrip';
  $bytes = encode_json(JSONTest->new(
    something => {just => 'works'}, else => {not => 'working'}));
  is_deeply decode_json($bytes), {just => 'works'}, 'successful roundtrip';
};

subtest 'Unknown reference' => sub {
  is_deeply encode_json(sub { }), 'null', 'unknown reference';
};

subtest 'Boolean shortcut' => sub {
  is encode_json({true  => \1}), '{"true":true}',   'encode {true => \1}';
  is encode_json({false => \0}), '{"false":false}', 'encode {false => \0}';
};

subtest 'Booleans in different contexts' => sub {
  ok true, 'true';
  is true, 1, 'right string value';
  is true + 0, 1, 'right numeric value';
  ok !false, 'false';
  is false, 0, 'right string value';
  is false + 0, 0, 'right numeric value';
};

subtest 'Upgraded numbers' => sub {
  my $num = 3;
  my $str = "$num";
  is encode_json({test => [$num, $str]}), '{"test":[3,"3"]}',
    'upgraded number detected';
  $num = 3.21;
  $str = "$num";
  is encode_json({test => [$num, $str]}), '{"test":[3.21,"3.21"]}',
    'upgraded number detected';
  $str = '0 but true';
  $num = 1 + $str;
  is encode_json({test => [$num, $str]}), '{"test":[1,"0 but true"]}',
    'upgraded number detected';
};

subtest 'Upgraded string' => sub {
  my $str = "bar";
  my $num;
  { no warnings 'numeric'; $num = 23 + $str }
  is encode_json({test => [$num, $str]}), '{"test":[23,"bar"]}',
    'upgraded string detected';
};

subtest 'dualvar' => sub {
  my $dual = dualvar 23, 'twenty three';
  is encode_json([$dual]), '["twenty three"]', 'dualvar stringified';
};

subtest 'Other reference types' => sub {
  is encode_json([JSONTest2->new]), "[\"works!\"]", 'object stringified';
};

subtest 'Ensure numbers and strings are not upgraded' => sub {
  my $mixed = [3, 'three', '3', 0, "0"];
  is encode_json($mixed), '[3,"three","3",0,"0"]',
    'all have been detected correctly';
  is encode_json($mixed), '[3,"three","3",0,"0"]',
    'all have been detected correctly again';
};

subtest '"inf" and "nan"' => sub {
  like encode_json({test => 9**9**9}), qr/^{"test":".*"}$/,
    'encode "inf" as string';
  like encode_json({test => -sin(9**9**9)}), qr/^{"test":".*"}$/,
    'encode "nan" as string';
};

subtest '"null"' => sub {
  is j('null'), undef, 'decode null';
};

subtest 'Errors' => sub {
  eval { decode_json 'test' };
  like $@, qr/Malformed JSON: Expected string, array, object/, 'right error';
  like $@, qr/object, number, boolean or null at line 0, offset 0/,
    'right error';
  eval { decode_json b('["\\ud800"]')->encode };
  like $@, qr/Malformed JSON: Missing low-surrogate at line 1, offset 8/,
    'right error';
  eval { decode_json b('["\\udf46"]')->encode };
  like $@, qr/Malformed JSON: Missing high-surrogate at line 1, offset 8/,
    'right error';
  eval { decode_json '[[]' };
  like $@, qr/Malformed JSON: Expected comma or right square bracket/,
    'right error';
  like $@, qr/bracket while parsing array at line 1, offset 3/, 'right error';
  eval { decode_json '{{}' };
  like $@,
    qr/Malformed JSON: Expected string while parsing object at line 1, offset 1/,
    'right error';
  eval { decode_json "[\"foo\x00]" };
  like $@, qr/Malformed JSON: Unexpected character or invalid escape/,
    'right error';
  like $@, qr/escape while parsing string at line 1, offset 5/, 'right error';
  eval { decode_json '{"foo":"bar"{' };
  like $@, qr/Malformed JSON: Expected comma or right curly bracket/,
    'right error';
  like $@, qr/bracket while parsing object at line 1, offset 12/, 'right error';
  eval { decode_json '{"foo""bar"}' };
  like $@,
    qr/Malformed JSON: Expected colon while parsing object at line 1, offset 6/,
    'right error';
  eval { decode_json '[[]...' };
  like $@, qr/Malformed JSON: Expected comma or right square bracket/,
    'right error';
  like $@, qr/bracket while parsing array at line 1, offset 3/, 'right error';
  eval { decode_json '{{}...' };
  like $@,
    qr/Malformed JSON: Expected string while parsing object at line 1, offset 1/,
    'right error';
  eval { decode_json '[nan]' };
  like $@, qr/Malformed JSON: Expected string, array, object, number/,
    'right error';
  like $@, qr/number, boolean or null at line 1, offset 1/, 'right error';
  eval { decode_json '["foo]' };
  like $@, qr/Malformed JSON: Unterminated string at line 1, offset 6/,
    'right error';
  eval { decode_json '{"foo":"bar"}lala' };
  like $@, qr/Malformed JSON: Unexpected data at line 1, offset 13/,
    'right error';
  eval { decode_json '' };
  like $@, qr/Missing or empty input at offset 0/, 'right error';
  eval { decode_json "[\"foo\",\n\"bar\"]lala" };
  like $@, qr/Malformed JSON: Unexpected data at line 2, offset 6/,
    'right error';
  eval { decode_json "[\"foo\",\n\"bar\",\n\"bazra\"]lalala" };
  like $@, qr/Malformed JSON: Unexpected data at line 3, offset 8/,
    'right error';
  eval { decode_json '["♥"]' };
  like $@, qr/Input is not UTF-8 encoded/, 'right error';
  eval { decode_json encode('Shift_JIS', 'やった') };
  like $@, qr/Input is not UTF-8 encoded/, 'right error';
  is j('{'), undef, 'syntax error';
  eval { decode_json "[\"foo\",\n\"bar\",\n\"bazra\"]lalala" };
  like $@, qr/JSON: Unexpected data at line 3, offset 8 at.*json\.t/,
    'right error';
  eval { from_json "[\"foo\",\n\"bar\",\n\"bazra\"]lalala" };
  like $@, qr/JSON: Unexpected data at line 3, offset 8 at.*json\.t/,
    'right error';
};

done_testing();
