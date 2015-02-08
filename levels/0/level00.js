// Install dependencies with 'npm install'
// Run as 'node level00.js'

var express = require('express'), // Web framework
    mu = require('mu2'),          // Mustache.js templating
    bodyParser = require('body-parser'),
    crypto = require('crypto'),
    sqlite3 = require('sqlite3'); // SQLite (database) driver

// Look for templates in the current directory
mu.root = __dirname;

// Set up the DB
var db = new sqlite3.Database('level00.db');
db.serialize(function() {
db.run(
  'CREATE TABLE IF NOT EXISTS secrets (' +
    'key varchar(255),' +
    'secret varchar(255)' +
  ')'
);
  db.get(
      'SELECT * FROM secrets;'
      , function(err, answer) {
          if (!answer) {
              var buf = process.env.PASSWORD_LEVEL1;
              db.run(
                  'INSERT INTO secrets values("level1.password", "' + buf + '")');
          }
      })
  })


// Create the server
var app = express();
app.use(bodyParser());

function renderPage(res, variables) {
  var stream = mu.compileAndRender('level00.html', variables);
  res.header('Content-Type', 'text/html');
  stream.pipe(res);
}

app.get('/*', function(req, res) {
  var namespace = req.param('namespace');

  if (namespace) {
    var query = 'SELECT * FROM secrets WHERE key LIKE ? || ".%"';
    db.all(query, namespace, function(err, secrets) {
	     if (err) throw err;

	     renderPage(res, {namespace: namespace, secrets: secrets});
	   });
  } else {
    renderPage(res, {});
  }
});

app.post('/*', function(req, res) {
  var namespace = req.body['namespace'];
  var secret_name = req.body['secret_name'];
  var secret_value = req.body['secret_value'];

  var query = 'INSERT INTO secrets (key, secret) VALUES (? || "." || ?, ?)';
  db.run(query, namespace, secret_name, secret_value, function(err) {
     if (err) throw err;

	   res.header('Content-Type', 'text/html');
	   res.redirect(req.path + '?namespace=' + namespace);
	 });
});

if (process.argv.length > 2) {
  var socket = process.argv[2];
  console.log("Starting server on UNIX socket " + socket);
  app.listen(socket);
} else {
  console.log("Starting server at http://localhost:3000/");
  app.listen(3000);
}
