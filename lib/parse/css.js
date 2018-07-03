// Generated by CoffeeScript 2.3.0
var after, error, skipRE, tokenizer;

tokenizer = require('postcss/lib/tokenize');

skipRE = /^(;|comment|space)$/;

exports.imports = function(css) {
  var curr, deps, next, offset, prev, ref, start, toks;
  toks = tokenizer({css, error});
  offset = 0;
  prev = null;
  curr = null;
  next = function() {
    if (prev = curr) {
      offset += prev[1].length;
    }
    return curr = toks.nextToken();
  };
  deps = [];
  while (next()) {
    if (skipRE.test(curr[0])) {
      continue;
    }
    if (curr[0] !== 'at-word') {
      break;
    }
    if (curr[1] !== '@import') {
      break;
    }
    start = offset;
    next(); // skip ' '
    ref = next()[1].slice(1, -1);
    next(); // skip ';'
    next(); // skip '\n'
    deps.push({
      ref: ref,
      module: null,
      start: start,
      end: offset + 1
    });
  }
  return deps;
};


// Helpers

after = function(type, next) {
  var tok;
  while (tok = next()) {
    if (tok[0] === type) {
      return next();
    }
  }
};

error = function(msg, line, column) {
  var e;
  e = new Error(msg);
  e.line = line;
  e.column = column;
  throw e;
};