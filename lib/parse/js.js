// Generated by CoffeeScript 2.3.0
var getRequireArg, isRequire, tokTypes, tokenizer;

({tokenizer, tokTypes} = require('acorn'));

// Only parses `require` calls,
// because `import` statements are transformed with sucrase.
exports.imports = function(input) {
  var deps, next, tok, toks;
  toks = tokenizer(input);
  next = toks.getToken.bind(toks);
  deps = [];
  while (tok = next()) {
    if (tok.type === tokTypes.eof) {
      break;
    }
    if (isRequire(tok) && (tok = getRequireArg(next))) {
      deps.push({
        ref: tok.value,
        module: null,
        start: tok.start,
        end: tok.end
      });
    }
  }
  return deps;
};

isRequire = function(tok) {
  return (tok.type === tokTypes.name) && (tok.value === 'require');
};

getRequireArg = function(next) {
  var tok;
  if (next().type === tokTypes.parenL) {
    if ((tok = next()).type === tokTypes.string) {
      if (next().type === tokTypes.parenR) {
        return tok;
      }
    }
  }
};