// Generated by CoffeeScript 2.3.0
var isObject, push, u;

isObject = require('is-object');

push = Function.apply.bind([].push);

u = exports;

u.evalFile = require('./evalFile');

u.findPackage = require('./findPackage');

u.lazyRequire = require('./lazyRequire');

u.mapSources = require('./mapSources');

u.sha256 = require('./sha256');

u.uhoh = require('./uhoh');

u.cloneArray = function(a) {
  var b, i, len;
  len = a.length;
  if (len > 50) {
    return a.concat();
  } else {
    i = len;
    b = new Array(len);
    while (i--) {
      b[i] = a[i];
    }
    return b;
  }
};

u.concat = function(a, b) {
  var an, bn, i, res;
  if (!(an = a.length)) {
    return b;
  }
  if (!(bn = b.length)) {
    return a;
  }
  res = new Array(i = an + bn);
  while (i-- !== an) {
    res[i] = b[i - an];
  }
  while (i !== -1) {
    res[i] = a[i--];
  }
  return res;
};

u.each = function(obj, fn, ctx) {
  var key, val;
  if (obj) {
    for (key in obj) {
      val = obj[key];
      fn.call(ctx, val, key);
    }
  }
};

u.merge = function(a, b) {
  var key, val;
  if (Array.isArray(b)) {
    push(a, b);
    return a;
  }
  for (key in b) {
    val = b[key];
    if (Array.isArray(val)) {
      if (Array.isArray(a[key])) {
        push(a[key], val);
        continue;
      }
    } else if (isObject(val)) {
      if (isObject(a[key])) {
        u.merge(a[key], val);
        continue;
      }
    }
    if (val !== void 0) {
      a[key] = val;
    }
  }
  return a;
};

// Arrays are only shallow cloned.
u.cloneObject = function(obj) {
  var key, res, val;
  res = {};
  for (key in obj) {
    val = obj[key];
    res[key] = Array.isArray(val) && u.cloneArray(val) || isObject(val) && u.cloneObject(val) || val;
  }
  return res;
};

// Arrays are only shallow cloned.
u.mergeDefaults = function(a, b) {
  var key, val;
  for (key in b) {
    val = b[key];
    if (a[key] === void 0) {
      a[key] = Array.isArray(val) && u.cloneArray(val) || isObject(val) && u.cloneObject(val) || val;
    } else if (isObject(val)) {
      u.mergeDefaults(a[key], val);
    }
  }
  return a;
};