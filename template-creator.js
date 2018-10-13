


var input_file = require('fs').readFileSync(process.argv[2], 'utf-8');

input_file = input_file.split ('<content id="content">')[1].split('</content>')[0];

input_file = input_file.replace ('e3RpdGxlfQ==', '{title}');
input_file = input_file.replace ('e3N1YnRpdGxlfQ==', '{subtitle}');

var presentation = JSON.parse (input_file);

// Move preview of slide 1 to slide 0:
// Asume slide 1 is the redacted version of 0
presentation.slides[0].preview = presentation.slides[1].preview;
presentation.slides.splice(1, 1); // Remove redacted slide

presentation['preview-slide'] = 0;
presentation['current-slide'] = 0;

console.log (JSON.stringify(presentation));