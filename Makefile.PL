use inc::Module::Install;

name     'MIME-Base64-ChunkedEncoder';
abstract 'A light wrapper around MIME::Base64 that allows en/decoding of Base64 data in chunks with output to a filehandle or string.';
version  '1.0';
license  'gpl';
author   'Mark Gregson <mark.gregson@qut.edu.au>';

perl_version  '5.008';
test_requires 'Test::More' => '0.62';

WriteAll;

