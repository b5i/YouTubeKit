(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
    
/*
     --------------------------------------------------------------------------------
     Meriyah | ISC
     URL: https://github.com/meriyah/meriyah
     --------------------------------------------------------------------------------
     ISC License

     Copyright (c) 2019 and later, KFlash and others.

     Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

     THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

 */
const meriyah = require('meriyah');
    
/*
    --------------------------------------------------------------------------------
    Astring | MIT
    URL: https://github.com/davidbonnet/astring/
    --------------------------------------------------------------------------------
    Copyright (c) 2015, David Bonnet <david@bonnet.cc>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
 */
const astring = require('astring');

// YT-DLP JS solver https://github.com/yt-dlp/yt-dlp/blob/5faffa999fd33b373d47773e8ee639d072accec2/yt_dlp/extractor/youtube/jsc/_builtin/vendor/yt.solver.core.js
var jsc = (function (meriyah, astring) {
  'use strict';
  function matchesStructure(obj, structure) {
    if (Array.isArray(structure)) {
      if (!Array.isArray(obj)) return false;
      return structure.length === obj.length && structure.every((value, index) => matchesStructure(obj[index], value));
    }
    if (typeof structure === 'object') {
      if (!obj) return !structure;
      if ('or' in structure) return structure.or.some((node) => matchesStructure(obj, node));
      if ('anykey' in structure && Array.isArray(structure.anykey)) {
        const haystack = Array.isArray(obj) ? obj : Object.values(obj);
        return structure.anykey.every((value) => haystack.some((el) => matchesStructure(el, value)));
      }
      for (const [key, value] of Object.entries(structure)) {
        if (!matchesStructure(obj[key], value)) return false;
      }
      return true;
    }
    return structure === obj;
  }
  function isOneOf(value, ...of) { return of.includes(value); }
  function generateArrowFunction(data) { return meriyah.parse(data).body[0].expression; }
  function _optionalChain$1(ops) {
    let lastAccessLHS = undefined, value = ops[0], i = 1;
    while (i < ops.length) {
      const op = ops[i], fn = ops[i + 1]; i += 2;
      if ((op === 'optionalAccess' || op === 'optionalCall') && value == null) return undefined;
      if (op === 'access' || op === 'optionalAccess') { lastAccessLHS = value; value = fn(value); }
      else if (op === 'call' || op === 'optionalCall') { value = fn((...args) => value.call(lastAccessLHS, ...args)); lastAccessLHS = undefined; }
    }
    return value;
  }
  const identifier = { or: [{ type: 'ExpressionStatement', expression: { type: 'AssignmentExpression', operator: '=', left: { or: [{ type: 'Identifier' }, { type: 'MemberExpression' }] }, right: { type: 'FunctionExpression', async: false } } }, { type: 'FunctionDeclaration', async: false, id: { type: 'Identifier' } }, { type: 'VariableDeclaration', declarations: { anykey: [{ type: 'VariableDeclarator', init: { type: 'FunctionExpression', async: false } }] } }] };
  const asdasd = { type: 'ExpressionStatement', expression: { type: 'CallExpression', callee: { type: 'MemberExpression', object: { type: 'Identifier' }, property: {}, optional: false }, arguments: [{ type: 'Literal', value: 'alr' }, { type: 'Literal', value: 'yes' }], optional: false } };
  function extract(node) {
    if (!matchesStructure(node, identifier)) return null;
    const options = [];
    if (node.type === 'FunctionDeclaration') {
      if (node.id && _optionalChain$1([node, 'access', (_) => _.body, 'optionalAccess', (_2) => _2.body])) options.push({ name: node.id, statements: _optionalChain$1([node, 'access', (_3) => _3.body, 'optionalAccess', (_4) => _4.body]) });
    } else if (node.type === 'ExpressionStatement') {
      if (node.expression.type !== 'AssignmentExpression') return null;
      const name = node.expression.left, body = _optionalChain$1([node.expression.right, 'optionalAccess', (_5) => _5.body, 'optionalAccess', (_6) => _6.body]);
      if (name && body) options.push({ name, statements: body });
    } else if (node.type === 'VariableDeclaration') {
      for (const declaration of node.declarations) {
        const name = declaration.id, body = _optionalChain$1([declaration.init, 'optionalAccess', (_7) => _7.body, 'optionalAccess', (_8) => _8.body]);
        if (name && body) options.push({ name, statements: body });
      }
    }
    for (const { name, statements } of options) {
      if (matchesStructure(statements, { anykey: [asdasd] })) return createSolver(name);
    }
    return null;
  }
  function createSolver(expression) {
    return generateArrowFunction(`\n({sig, n}) => {\n  const url = (${astring.generate(expression)})("https://youtube.com/watch?v=yt-dlp-wins", "s", sig ? encodeURIComponent(sig) : undefined);\n  url.set("n", n);\n  const proto = Object.getPrototypeOf(url);\n  const keys = Object.keys(proto).concat(Object.getOwnPropertyNames(proto));\n  for (const key of keys) {\n    if (!["constructor", "set", "get", "clone"].includes(key)) {\n      url[key]();\n      break;\n    }\n  }\n  const s = url.get("s");\n  return {\n    sig: s ? decodeURIComponent(s) : null,\n    n: url.get("n") ?? null,\n  };\n}\n`);
  }
  const setupNodes = meriyah.parse(`\nif (typeof globalThis.XMLHttpRequest === "undefined") {\n    globalThis.XMLHttpRequest = { prototype: {} };\n}\nif (typeof URL === "undefined") {\n    globalThis.location = {\n        hash: "",\n        host: "www.youtube.com",\n        hostname: "www.youtube.com",\n        href: "https://www.youtube.com/watch?v=yt-dlp-wins",\n        origin: "https://www.youtube.com",\n        password: "",\n        pathname: "/watch",\n        port: "",\n        protocol: "https:",\n        search: "?v=yt-dlp-wins",\n        username: "",\n    };\n} else {\n    globalThis.location = new URL("https://www.youtube.com/watch?v=yt-dlp-wins");\n}\nif (typeof globalThis.document === "undefined") {\n    globalThis.document = Object.create(null);\n}\nif (typeof globalThis.navigator === "undefined") {\n    globalThis.navigator = Object.create(null);\n}\nif (typeof globalThis.self === "undefined") {\n    globalThis.self = globalThis;\n}\nif (typeof globalThis.window === "undefined") {\n    globalThis.window = globalThis;\n}\n`).body;
  function _optionalChain(ops) {
    let lastAccessLHS = undefined, value = ops[0], i = 1;
    while (i < ops.length) {
      const op = ops[i], fn = ops[i + 1]; i += 2;
      if ((op === 'optionalAccess' || op === 'optionalCall') && value == null) return undefined;
      if (op === 'access' || op === 'optionalAccess') { lastAccessLHS = value; value = fn(value); }
      else if (op === 'call' || op === 'optionalCall') { value = fn((...args) => value.call(lastAccessLHS, ...args)); lastAccessLHS = undefined; }
    }
    return value;
  }
  function preprocessPlayer(data) {
    const program = meriyah.parse(data);
    const plainStatements = modifyPlayer(program);
    const solutions = getSolutions(plainStatements);
    for (const [name, options] of Object.entries(solutions)) {
      plainStatements.push({ type: 'ExpressionStatement', expression: { type: 'AssignmentExpression', operator: '=', left: { type: 'MemberExpression', computed: false, object: { type: 'Identifier', name: '_result' }, property: { type: 'Identifier', name }, optional: false }, right: multiTry(options) } });
    }
    program.body.splice(0, 0, ...setupNodes);
    return astring.generate(program);
  }
  function modifyPlayer(program) {
    const body = program.body;
    const block = (() => {
      switch (body.length) {
        case 1: {
          const func = body[0];
          if (_optionalChain([func, 'optionalAccess', (_) => _.type]) === 'ExpressionStatement' && func.expression.type === 'CallExpression' && func.expression.callee.type === 'MemberExpression' && func.expression.callee.object.type === 'FunctionExpression') return func.expression.callee.object.body;
          break;
        }
        case 2: {
          const func = body[1];
          if (_optionalChain([func, 'optionalAccess', (_2) => _2.type]) === 'ExpressionStatement' && func.expression.type === 'CallExpression' && func.expression.callee.type === 'FunctionExpression') {
            const block = func.expression.callee.body;
            block.body.splice(0, 1);
            return block;
          }
          break;
        }
      }
      throw 'unexpected structure';
    })();
    block.body = block.body.filter((node) => {
      if (node.type === 'ExpressionStatement') {
        if (node.expression.type === 'AssignmentExpression') return true;
        return node.expression.type === 'Literal';
      }
      return true;
    });
    return block.body;
  }
  function getSolutions(statements) {
    const found = { n: [], sig: [] };
    for (const statement of statements) {
      const result = extract(statement);
      if (result) {
        found.n.push(makeSolver(result, { type: 'Identifier', name: 'n' }));
        found.sig.push(makeSolver(result, { type: 'Identifier', name: 'sig' }));
      }
    }
    return found;
  }
  function makeSolver(result, ident) {
    return { type: 'ArrowFunctionExpression', params: [ident], body: { type: 'MemberExpression', object: { type: 'CallExpression', callee: result, arguments: [{ type: 'ObjectExpression', properties: [{ type: 'Property', key: ident, value: ident, kind: 'init', computed: false, method: false, shorthand: true }] }], optional: false }, computed: false, property: ident, optional: false }, async: false, expression: true, generator: false };
  }
  function getFromPrepared(code) {
    const resultObj = { n: null, sig: null };
    Function('_result', code)(resultObj);
    return resultObj;
  }
  function multiTry(generators) {
    return generateArrowFunction(`\n(_input) => {\n  const _results = new Set();\n  const errors = [];\n  for (const _generator of ${astring.generate({ type: 'ArrayExpression', elements: generators })}) {\n    try {\n      _results.add(_generator(_input));\n    } catch (e) {\n      errors.push(e);\n    }\n  }\n  if (!_results.size) {\n    throw \`no solutions: \${errors.join(", ")}\`;\n  }\n  if (_results.size !== 1) {\n    throw \`invalid solutions: \${[..._results].map(x => JSON.stringify(x)).join(", ")}\`;\n  }\n  return _results.values().next().value;\n}\n`);
  }
  function main(input) {
    const preprocessedPlayer = input.type === 'player' ? preprocessPlayer(input.player) : input.preprocessed_player;
    const solvers = getFromPrepared(preprocessedPlayer);
    const responses = input.requests.map((input) => {
      if (!isOneOf(input.type, 'n', 'sig')) return { type: 'error', error: `Unknown request type: ${input.type}` };
      const solver = solvers[input.type];
      if (!solver) return { type: 'error', error: `Failed to extract ${input.type} function` };
      try {
        return { type: 'result', data: Object.fromEntries(input.challenges.map((challenge) => [challenge, solver(challenge)])) };
      } catch (error) {
        return { type: 'error', error: error instanceof Error ? `${error.message}\n${error.stack}` : `${error}` };
      }
    });
    const output = { type: 'result', responses };
    if (input.type === 'player' && input.output_preprocessed) output.preprocessed_player = preprocessedPlayer;
    return output;
  }
  return main;
})(meriyah, astring);

// Exported function for Swift bridge
globalThis.jscSolveN = function(playerJs, nParam) {
  try {
    var result = jsc({
      type: 'player',
      player: playerJs,
      requests: [{ type: 'n', challenges: [nParam] }]
    });
    if (result.type === 'result' && result.responses[0].type === 'result') {
      return result.responses[0].data[nParam];
    }
    return null;
  } catch(e) {
    return null;
  }
};

// Also expose a "preprocess" step so Swift can cache the preprocessed player and avoid re-parsing base.js on every n call
globalThis.jscPreprocessPlayer = function(playerJs) {
  try {
    var result = jsc({
      type: 'player',
      player: playerJs,
      requests: [],
      output_preprocessed: true
    });
    return result.preprocessed_player || null;
  } catch(e) {
    return null;
  }
};

globalThis.jscSolveNFromPreprocessed = function(preprocessedPlayer, nParam) {
  try {
    var result = jsc({
      type: 'preprocessed',
      preprocessed_player: preprocessedPlayer,
      requests: [{ type: 'n', challenges: [nParam] }]
    });
    if (result.type === 'result' && result.responses[0].type === 'result') {
      return result.responses[0].data[nParam];
    }
    return null;
  } catch(e) {
    return null;
  }
};

},{"astring":2,"meriyah":3}],2:[function(require,module,exports){
"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.generate = generate;
exports.baseGenerator = exports.GENERATOR = exports.EXPRESSIONS_PRECEDENCE = exports.NEEDS_PARENTHESES = void 0;

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

var stringify = JSON.stringify;

if (!String.prototype.repeat) {
  throw new Error('String.prototype.repeat is undefined, see https://github.com/davidbonnet/astring#installation');
}

if (!String.prototype.endsWith) {
  throw new Error('String.prototype.endsWith is undefined, see https://github.com/davidbonnet/astring#installation');
}

var OPERATOR_PRECEDENCE = {
  '||': 2,
  '??': 3,
  '&&': 4,
  '|': 5,
  '^': 6,
  '&': 7,
  '==': 8,
  '!=': 8,
  '===': 8,
  '!==': 8,
  '<': 9,
  '>': 9,
  '<=': 9,
  '>=': 9,
  "in": 9,
  "instanceof": 9,
  '<<': 10,
  '>>': 10,
  '>>>': 10,
  '+': 11,
  '-': 11,
  '*': 12,
  '%': 12,
  '/': 12,
  '**': 13
};
var NEEDS_PARENTHESES = 17;
exports.NEEDS_PARENTHESES = NEEDS_PARENTHESES;
var EXPRESSIONS_PRECEDENCE = {
  ArrayExpression: 20,
  TaggedTemplateExpression: 20,
  ThisExpression: 20,
  Identifier: 20,
  PrivateIdentifier: 20,
  Literal: 18,
  TemplateLiteral: 20,
  Super: 20,
  SequenceExpression: 20,
  MemberExpression: 19,
  ChainExpression: 19,
  CallExpression: 19,
  NewExpression: 19,
  ArrowFunctionExpression: NEEDS_PARENTHESES,
  ClassExpression: NEEDS_PARENTHESES,
  FunctionExpression: NEEDS_PARENTHESES,
  ObjectExpression: NEEDS_PARENTHESES,
  UpdateExpression: 16,
  UnaryExpression: 15,
  AwaitExpression: 15,
  BinaryExpression: 14,
  LogicalExpression: 13,
  ConditionalExpression: 4,
  AssignmentExpression: 3,
  YieldExpression: 2,
  RestElement: 1
};
exports.EXPRESSIONS_PRECEDENCE = EXPRESSIONS_PRECEDENCE;

function formatSequence(state, nodes) {
  var generator = state.generator;
  state.write('(');

  if (nodes != null && nodes.length > 0) {
    generator[nodes[0].type](nodes[0], state);
    var length = nodes.length;

    for (var i = 1; i < length; i++) {
      var param = nodes[i];
      state.write(', ');
      generator[param.type](param, state);
    }
  }

  state.write(')');
}

function expressionNeedsParenthesis(state, node, parentNode, isRightHand) {
  var nodePrecedence = state.expressionsPrecedence[node.type];

  if (nodePrecedence === NEEDS_PARENTHESES) {
    return true;
  }

  var parentNodePrecedence = state.expressionsPrecedence[parentNode.type];

  if (nodePrecedence !== parentNodePrecedence) {
    return !isRightHand && nodePrecedence === 15 && parentNodePrecedence === 14 && parentNode.operator === '**' || nodePrecedence < parentNodePrecedence;
  }

  if (nodePrecedence !== 13 && nodePrecedence !== 14) {
    return false;
  }

  if (node.operator === '**' && parentNode.operator === '**') {
    return !isRightHand;
  }

  if (nodePrecedence === 13 && parentNodePrecedence === 13 && (node.operator === '??' || parentNode.operator === '??')) {
    return true;
  }

  if (isRightHand) {
    return OPERATOR_PRECEDENCE[node.operator] <= OPERATOR_PRECEDENCE[parentNode.operator];
  }

  return OPERATOR_PRECEDENCE[node.operator] < OPERATOR_PRECEDENCE[parentNode.operator];
}

function formatExpression(state, node, parentNode, isRightHand) {
  var generator = state.generator;

  if (expressionNeedsParenthesis(state, node, parentNode, isRightHand)) {
    state.write('(');
    generator[node.type](node, state);
    state.write(')');
  } else {
    generator[node.type](node, state);
  }
}

function reindent(state, text, indent, lineEnd) {
  var lines = text.split('\n');
  var end = lines.length - 1;
  state.write(lines[0].trim());

  if (end > 0) {
    state.write(lineEnd);

    for (var i = 1; i < end; i++) {
      state.write(indent + lines[i].trim() + lineEnd);
    }

    state.write(indent + lines[end].trim());
  }
}

function formatComments(state, comments, indent, lineEnd) {
  var length = comments.length;

  for (var i = 0; i < length; i++) {
    var comment = comments[i];
    state.write(indent);

    if (comment.type[0] === 'L') {
      state.write('// ' + comment.value.trim() + '\n', comment);
    } else {
      state.write('/*');
      reindent(state, comment.value, indent, lineEnd);
      state.write('*/' + lineEnd);
    }
  }
}

function hasCallExpression(node) {
  var currentNode = node;

  while (currentNode != null) {
    var _currentNode = currentNode,
        type = _currentNode.type;

    if (type[0] === 'C' && type[1] === 'a') {
      return true;
    } else if (type[0] === 'M' && type[1] === 'e' && type[2] === 'm') {
      currentNode = currentNode.object;
    } else {
      return false;
    }
  }
}

function formatVariableDeclaration(state, node) {
  var generator = state.generator;
  var declarations = node.declarations;
  state.write(node.kind + ' ');
  var length = declarations.length;

  if (length > 0) {
    generator.VariableDeclarator(declarations[0], state);

    for (var i = 1; i < length; i++) {
      state.write(', ');
      generator.VariableDeclarator(declarations[i], state);
    }
  }
}

var ForInStatement, FunctionDeclaration, RestElement, BinaryExpression, ArrayExpression, BlockStatement;
var GENERATOR = {
  Program: function Program(node, state) {
    var indent = state.indent.repeat(state.indentLevel);
    var lineEnd = state.lineEnd,
        writeComments = state.writeComments;

    if (writeComments && node.comments != null) {
      formatComments(state, node.comments, indent, lineEnd);
    }

    var statements = node.body;
    var length = statements.length;

    for (var i = 0; i < length; i++) {
      var statement = statements[i];

      if (writeComments && statement.comments != null) {
        formatComments(state, statement.comments, indent, lineEnd);
      }

      state.write(indent);
      this[statement.type](statement, state);
      state.write(lineEnd);
    }

    if (writeComments && node.trailingComments != null) {
      formatComments(state, node.trailingComments, indent, lineEnd);
    }
  },
  BlockStatement: BlockStatement = function BlockStatement(node, state) {
    var indent = state.indent.repeat(state.indentLevel++);
    var lineEnd = state.lineEnd,
        writeComments = state.writeComments;
    var statementIndent = indent + state.indent;
    state.write('{');
    var statements = node.body;

    if (statements != null && statements.length > 0) {
      state.write(lineEnd);

      if (writeComments && node.comments != null) {
        formatComments(state, node.comments, statementIndent, lineEnd);
      }

      var length = statements.length;

      for (var i = 0; i < length; i++) {
        var statement = statements[i];

        if (writeComments && statement.comments != null) {
          formatComments(state, statement.comments, statementIndent, lineEnd);
        }

        state.write(statementIndent);
        this[statement.type](statement, state);
        state.write(lineEnd);
      }

      state.write(indent);
    } else {
      if (writeComments && node.comments != null) {
        state.write(lineEnd);
        formatComments(state, node.comments, statementIndent, lineEnd);
        state.write(indent);
      }
    }

    if (writeComments && node.trailingComments != null) {
      formatComments(state, node.trailingComments, statementIndent, lineEnd);
    }

    state.write('}');
    state.indentLevel--;
  },
  ClassBody: BlockStatement,
  StaticBlock: function StaticBlock(node, state) {
    state.write('static ');
    this.BlockStatement(node, state);
  },
  EmptyStatement: function EmptyStatement(node, state) {
    state.write(';');
  },
  ExpressionStatement: function ExpressionStatement(node, state) {
    var precedence = state.expressionsPrecedence[node.expression.type];

    if (precedence === NEEDS_PARENTHESES || precedence === 3 && node.expression.left.type[0] === 'O') {
      state.write('(');
      this[node.expression.type](node.expression, state);
      state.write(')');
    } else {
      this[node.expression.type](node.expression, state);
    }

    state.write(';');
  },
  IfStatement: function IfStatement(node, state) {
    state.write('if (');
    this[node.test.type](node.test, state);
    state.write(') ');
    this[node.consequent.type](node.consequent, state);

    if (node.alternate != null) {
      state.write(' else ');
      this[node.alternate.type](node.alternate, state);
    }
  },
  LabeledStatement: function LabeledStatement(node, state) {
    this[node.label.type](node.label, state);
    state.write(': ');
    this[node.body.type](node.body, state);
  },
  BreakStatement: function BreakStatement(node, state) {
    state.write('break');

    if (node.label != null) {
      state.write(' ');
      this[node.label.type](node.label, state);
    }

    state.write(';');
  },
  ContinueStatement: function ContinueStatement(node, state) {
    state.write('continue');

    if (node.label != null) {
      state.write(' ');
      this[node.label.type](node.label, state);
    }

    state.write(';');
  },
  WithStatement: function WithStatement(node, state) {
    state.write('with (');
    this[node.object.type](node.object, state);
    state.write(') ');
    this[node.body.type](node.body, state);
  },
  SwitchStatement: function SwitchStatement(node, state) {
    var indent = state.indent.repeat(state.indentLevel++);
    var lineEnd = state.lineEnd,
        writeComments = state.writeComments;
    state.indentLevel++;
    var caseIndent = indent + state.indent;
    var statementIndent = caseIndent + state.indent;
    state.write('switch (');
    this[node.discriminant.type](node.discriminant, state);
    state.write(') {' + lineEnd);
    var occurences = node.cases;
    var occurencesCount = occurences.length;

    for (var i = 0; i < occurencesCount; i++) {
      var occurence = occurences[i];

      if (writeComments && occurence.comments != null) {
        formatComments(state, occurence.comments, caseIndent, lineEnd);
      }

      if (occurence.test) {
        state.write(caseIndent + 'case ');
        this[occurence.test.type](occurence.test, state);
        state.write(':' + lineEnd);
      } else {
        state.write(caseIndent + 'default:' + lineEnd);
      }

      var consequent = occurence.consequent;
      var consequentCount = consequent.length;

      for (var _i = 0; _i < consequentCount; _i++) {
        var statement = consequent[_i];

        if (writeComments && statement.comments != null) {
          formatComments(state, statement.comments, statementIndent, lineEnd);
        }

        state.write(statementIndent);
        this[statement.type](statement, state);
        state.write(lineEnd);
      }
    }

    state.indentLevel -= 2;
    state.write(indent + '}');
  },
  ReturnStatement: function ReturnStatement(node, state) {
    state.write('return');

    if (node.argument) {
      state.write(' ');
      this[node.argument.type](node.argument, state);
    }

    state.write(';');
  },
  ThrowStatement: function ThrowStatement(node, state) {
    state.write('throw ');
    this[node.argument.type](node.argument, state);
    state.write(';');
  },
  TryStatement: function TryStatement(node, state) {
    state.write('try ');
    this[node.block.type](node.block, state);

    if (node.handler) {
      var handler = node.handler;

      if (handler.param == null) {
        state.write(' catch ');
      } else {
        state.write(' catch (');
        this[handler.param.type](handler.param, state);
        state.write(') ');
      }

      this[handler.body.type](handler.body, state);
    }

    if (node.finalizer) {
      state.write(' finally ');
      this[node.finalizer.type](node.finalizer, state);
    }
  },
  WhileStatement: function WhileStatement(node, state) {
    state.write('while (');
    this[node.test.type](node.test, state);
    state.write(') ');
    this[node.body.type](node.body, state);
  },
  DoWhileStatement: function DoWhileStatement(node, state) {
    state.write('do ');
    this[node.body.type](node.body, state);
    state.write(' while (');
    this[node.test.type](node.test, state);
    state.write(');');
  },
  ForStatement: function ForStatement(node, state) {
    state.write('for (');

    if (node.init != null) {
      var init = node.init;

      if (init.type[0] === 'V') {
        formatVariableDeclaration(state, init);
      } else {
        this[init.type](init, state);
      }
    }

    state.write('; ');

    if (node.test) {
      this[node.test.type](node.test, state);
    }

    state.write('; ');

    if (node.update) {
      this[node.update.type](node.update, state);
    }

    state.write(') ');
    this[node.body.type](node.body, state);
  },
  ForInStatement: ForInStatement = function ForInStatement(node, state) {
    state.write("for ".concat(node["await"] ? 'await ' : '', "("));
    var left = node.left;

    if (left.type[0] === 'V') {
      formatVariableDeclaration(state, left);
    } else {
      this[left.type](left, state);
    }

    state.write(node.type[3] === 'I' ? ' in ' : ' of ');
    this[node.right.type](node.right, state);
    state.write(') ');
    this[node.body.type](node.body, state);
  },
  ForOfStatement: ForInStatement,
  DebuggerStatement: function DebuggerStatement(node, state) {
    state.write('debugger;', node);
  },
  FunctionDeclaration: FunctionDeclaration = function FunctionDeclaration(node, state) {
    state.write((node.async ? 'async ' : '') + (node.generator ? 'function* ' : 'function ') + (node.id ? node.id.name : ''), node);
    formatSequence(state, node.params);
    state.write(' ');
    this[node.body.type](node.body, state);
  },
  FunctionExpression: FunctionDeclaration,
  VariableDeclaration: function VariableDeclaration(node, state) {
    formatVariableDeclaration(state, node);
    state.write(';');
  },
  VariableDeclarator: function VariableDeclarator(node, state) {
    this[node.id.type](node.id, state);

    if (node.init != null) {
      state.write(' = ');
      this[node.init.type](node.init, state);
    }
  },
  ClassDeclaration: function ClassDeclaration(node, state) {
    state.write('class ' + (node.id ? "".concat(node.id.name, " ") : ''), node);

    if (node.superClass) {
      state.write('extends ');
      var superClass = node.superClass;
      var type = superClass.type;
      var precedence = state.expressionsPrecedence[type];

      if ((type[0] !== 'C' || type[1] !== 'l' || type[5] !== 'E') && (precedence === NEEDS_PARENTHESES || precedence < state.expressionsPrecedence.ClassExpression)) {
        state.write('(');
        this[node.superClass.type](superClass, state);
        state.write(')');
      } else {
        this[superClass.type](superClass, state);
      }

      state.write(' ');
    }

    this.ClassBody(node.body, state);
  },
  ImportDeclaration: function ImportDeclaration(node, state) {
    state.write('import ');
    var specifiers = node.specifiers,
        attributes = node.attributes;
    var length = specifiers.length;
    var i = 0;

    if (length > 0) {
      for (; i < length;) {
        if (i > 0) {
          state.write(', ');
        }

        var specifier = specifiers[i];
        var type = specifier.type[6];

        if (type === 'D') {
          state.write(specifier.local.name, specifier);
          i++;
        } else if (type === 'N') {
          state.write('* as ' + specifier.local.name, specifier);
          i++;
        } else {
          break;
        }
      }

      if (i < length) {
        state.write('{');

        for (;;) {
          var _specifier = specifiers[i];
          var name = _specifier.imported.name;
          state.write(name, _specifier);

          if (name !== _specifier.local.name) {
            state.write(' as ' + _specifier.local.name);
          }

          if (++i < length) {
            state.write(', ');
          } else {
            break;
          }
        }

        state.write('}');
      }

      state.write(' from ');
    }

    this.Literal(node.source, state);

    if (attributes && attributes.length > 0) {
      state.write(' with { ');

      for (var _i2 = 0; _i2 < attributes.length; _i2++) {
        this.ImportAttribute(attributes[_i2], state);
        if (_i2 < attributes.length - 1) state.write(', ');
      }

      state.write(' }');
    }

    state.write(';');
  },
  ImportAttribute: function ImportAttribute(node, state) {
    this.Identifier(node.key, state);
    state.write(': ');
    this.Literal(node.value, state);
  },
  ImportExpression: function ImportExpression(node, state) {
    state.write('import(');
    this[node.source.type](node.source, state);
    state.write(')');
  },
  ExportDefaultDeclaration: function ExportDefaultDeclaration(node, state) {
    state.write('export default ');
    this[node.declaration.type](node.declaration, state);

    if (state.expressionsPrecedence[node.declaration.type] != null && node.declaration.type[0] !== 'F') {
      state.write(';');
    }
  },
  ExportNamedDeclaration: function ExportNamedDeclaration(node, state) {
    state.write('export ');

    if (node.declaration) {
      this[node.declaration.type](node.declaration, state);
    } else {
      state.write('{');
      var specifiers = node.specifiers,
          length = specifiers.length;

      if (length > 0) {
        for (var i = 0;;) {
          var specifier = specifiers[i];
          var name = specifier.local.name;
          state.write(name, specifier);

          if (name !== specifier.exported.name) {
            state.write(' as ' + specifier.exported.name);
          }

          if (++i < length) {
            state.write(', ');
          } else {
            break;
          }
        }
      }

      state.write('}');

      if (node.source) {
        state.write(' from ');
        this.Literal(node.source, state);
      }

      if (node.attributes && node.attributes.length > 0) {
        state.write(' with { ');

        for (var _i3 = 0; _i3 < node.attributes.length; _i3++) {
          this.ImportAttribute(node.attributes[_i3], state);
          if (_i3 < node.attributes.length - 1) state.write(', ');
        }

        state.write(' }');
      }

      state.write(';');
    }
  },
  ExportAllDeclaration: function ExportAllDeclaration(node, state) {
    if (node.exported != null) {
      state.write('export * as ' + node.exported.name + ' from ');
    } else {
      state.write('export * from ');
    }

    this.Literal(node.source, state);

    if (node.attributes && node.attributes.length > 0) {
      state.write(' with { ');

      for (var i = 0; i < node.attributes.length; i++) {
        this.ImportAttribute(node.attributes[i], state);
        if (i < node.attributes.length - 1) state.write(', ');
      }

      state.write(' }');
    }

    state.write(';');
  },
  MethodDefinition: function MethodDefinition(node, state) {
    if (node["static"]) {
      state.write('static ');
    }

    var kind = node.kind[0];

    if (kind === 'g' || kind === 's') {
      state.write(node.kind + ' ');
    }

    if (node.value.async) {
      state.write('async ');
    }

    if (node.value.generator) {
      state.write('*');
    }

    if (node.computed) {
      state.write('[');
      this[node.key.type](node.key, state);
      state.write(']');
    } else {
      this[node.key.type](node.key, state);
    }

    formatSequence(state, node.value.params);
    state.write(' ');
    this[node.value.body.type](node.value.body, state);
  },
  ClassExpression: function ClassExpression(node, state) {
    this.ClassDeclaration(node, state);
  },
  ArrowFunctionExpression: function ArrowFunctionExpression(node, state) {
    state.write(node.async ? 'async ' : '', node);
    var params = node.params;

    if (params != null) {
      if (params.length === 1 && params[0].type[0] === 'I') {
        state.write(params[0].name, params[0]);
      } else {
        formatSequence(state, node.params);
      }
    }

    state.write(' => ');

    if (node.body.type[0] === 'O') {
      state.write('(');
      this.ObjectExpression(node.body, state);
      state.write(')');
    } else {
      this[node.body.type](node.body, state);
    }
  },
  ThisExpression: function ThisExpression(node, state) {
    state.write('this', node);
  },
  Super: function Super(node, state) {
    state.write('super', node);
  },
  RestElement: RestElement = function RestElement(node, state) {
    state.write('...');
    this[node.argument.type](node.argument, state);
  },
  SpreadElement: RestElement,
  YieldExpression: function YieldExpression(node, state) {
    state.write(node.delegate ? 'yield*' : 'yield');

    if (node.argument) {
      state.write(' ');
      this[node.argument.type](node.argument, state);
    }
  },
  AwaitExpression: function AwaitExpression(node, state) {
    state.write('await ', node);
    formatExpression(state, node.argument, node);
  },
  TemplateLiteral: function TemplateLiteral(node, state) {
    var quasis = node.quasis,
        expressions = node.expressions;
    state.write('`');
    var length = expressions.length;

    for (var i = 0; i < length; i++) {
      var expression = expressions[i];
      var _quasi = quasis[i];
      state.write(_quasi.value.raw, _quasi);
      state.write('${');
      this[expression.type](expression, state);
      state.write('}');
    }

    var quasi = quasis[quasis.length - 1];
    state.write(quasi.value.raw, quasi);
    state.write('`');
  },
  TemplateElement: function TemplateElement(node, state) {
    state.write(node.value.raw, node);
  },
  TaggedTemplateExpression: function TaggedTemplateExpression(node, state) {
    formatExpression(state, node.tag, node);
    this[node.quasi.type](node.quasi, state);
  },
  ArrayExpression: ArrayExpression = function ArrayExpression(node, state) {
    state.write('[');

    if (node.elements.length > 0) {
      var elements = node.elements,
          length = elements.length;

      for (var i = 0;;) {
        var element = elements[i];

        if (element != null) {
          this[element.type](element, state);
        }

        if (++i < length) {
          state.write(', ');
        } else {
          if (element == null) {
            state.write(', ');
          }

          break;
        }
      }
    }

    state.write(']');
  },
  ArrayPattern: ArrayExpression,
  ObjectExpression: function ObjectExpression(node, state) {
    var indent = state.indent.repeat(state.indentLevel++);
    var lineEnd = state.lineEnd,
        writeComments = state.writeComments;
    var propertyIndent = indent + state.indent;
    state.write('{');

    if (node.properties.length > 0) {
      state.write(lineEnd);

      if (writeComments && node.comments != null) {
        formatComments(state, node.comments, propertyIndent, lineEnd);
      }

      var comma = ',' + lineEnd;
      var properties = node.properties,
          length = properties.length;

      for (var i = 0;;) {
        var property = properties[i];

        if (writeComments && property.comments != null) {
          formatComments(state, property.comments, propertyIndent, lineEnd);
        }

        state.write(propertyIndent);
        this[property.type](property, state);

        if (++i < length) {
          state.write(comma);
        } else {
          break;
        }
      }

      state.write(lineEnd);

      if (writeComments && node.trailingComments != null) {
        formatComments(state, node.trailingComments, propertyIndent, lineEnd);
      }

      state.write(indent + '}');
    } else if (writeComments) {
      if (node.comments != null) {
        state.write(lineEnd);
        formatComments(state, node.comments, propertyIndent, lineEnd);

        if (node.trailingComments != null) {
          formatComments(state, node.trailingComments, propertyIndent, lineEnd);
        }

        state.write(indent + '}');
      } else if (node.trailingComments != null) {
        state.write(lineEnd);
        formatComments(state, node.trailingComments, propertyIndent, lineEnd);
        state.write(indent + '}');
      } else {
        state.write('}');
      }
    } else {
      state.write('}');
    }

    state.indentLevel--;
  },
  Property: function Property(node, state) {
    if (node.method || node.kind[0] !== 'i') {
      this.MethodDefinition(node, state);
    } else {
      if (!node.shorthand) {
        if (node.computed) {
          state.write('[');
          this[node.key.type](node.key, state);
          state.write(']');
        } else {
          this[node.key.type](node.key, state);
        }

        state.write(': ');
      }

      this[node.value.type](node.value, state);
    }
  },
  PropertyDefinition: function PropertyDefinition(node, state) {
    if (node["static"]) {
      state.write('static ');
    }

    if (node.computed) {
      state.write('[');
    }

    this[node.key.type](node.key, state);

    if (node.computed) {
      state.write(']');
    }

    if (node.value == null) {
      if (node.key.type[0] !== 'F') {
        state.write(';');
      }

      return;
    }

    state.write(' = ');
    this[node.value.type](node.value, state);
    state.write(';');
  },
  ObjectPattern: function ObjectPattern(node, state) {
    state.write('{');

    if (node.properties.length > 0) {
      var properties = node.properties,
          length = properties.length;

      for (var i = 0;;) {
        this[properties[i].type](properties[i], state);

        if (++i < length) {
          state.write(', ');
        } else {
          break;
        }
      }
    }

    state.write('}');
  },
  SequenceExpression: function SequenceExpression(node, state) {
    formatSequence(state, node.expressions);
  },
  UnaryExpression: function UnaryExpression(node, state) {
    if (node.prefix) {
      var operator = node.operator,
          argument = node.argument,
          type = node.argument.type;
      state.write(operator);
      var needsParentheses = expressionNeedsParenthesis(state, argument, node);

      if (!needsParentheses && (operator.length > 1 || type[0] === 'U' && (type[1] === 'n' || type[1] === 'p') && argument.prefix && argument.operator[0] === operator && (operator === '+' || operator === '-'))) {
        state.write(' ');
      }

      if (needsParentheses) {
        state.write(operator.length > 1 ? ' (' : '(');
        this[type](argument, state);
        state.write(')');
      } else {
        this[type](argument, state);
      }
    } else {
      this[node.argument.type](node.argument, state);
      state.write(node.operator);
    }
  },
  UpdateExpression: function UpdateExpression(node, state) {
    if (node.prefix) {
      state.write(node.operator);
      this[node.argument.type](node.argument, state);
    } else {
      this[node.argument.type](node.argument, state);
      state.write(node.operator);
    }
  },
  AssignmentExpression: function AssignmentExpression(node, state) {
    this[node.left.type](node.left, state);
    state.write(' ' + node.operator + ' ');
    this[node.right.type](node.right, state);
  },
  AssignmentPattern: function AssignmentPattern(node, state) {
    this[node.left.type](node.left, state);
    state.write(' = ');
    this[node.right.type](node.right, state);
  },
  BinaryExpression: BinaryExpression = function BinaryExpression(node, state) {
    var isIn = node.operator === 'in';

    if (isIn) {
      state.write('(');
    }

    formatExpression(state, node.left, node, false);
    state.write(' ' + node.operator + ' ');
    formatExpression(state, node.right, node, true);

    if (isIn) {
      state.write(')');
    }
  },
  LogicalExpression: BinaryExpression,
  ConditionalExpression: function ConditionalExpression(node, state) {
    var test = node.test;
    var precedence = state.expressionsPrecedence[test.type];

    if (precedence === NEEDS_PARENTHESES || precedence <= state.expressionsPrecedence.ConditionalExpression) {
      state.write('(');
      this[test.type](test, state);
      state.write(')');
    } else {
      this[test.type](test, state);
    }

    state.write(' ? ');
    this[node.consequent.type](node.consequent, state);
    state.write(' : ');
    this[node.alternate.type](node.alternate, state);
  },
  NewExpression: function NewExpression(node, state) {
    state.write('new ');
    var precedence = state.expressionsPrecedence[node.callee.type];

    if (precedence === NEEDS_PARENTHESES || precedence < state.expressionsPrecedence.CallExpression || hasCallExpression(node.callee)) {
      state.write('(');
      this[node.callee.type](node.callee, state);
      state.write(')');
    } else {
      this[node.callee.type](node.callee, state);
    }

    formatSequence(state, node['arguments']);
  },
  CallExpression: function CallExpression(node, state) {
    var precedence = state.expressionsPrecedence[node.callee.type];

    if (precedence === NEEDS_PARENTHESES || precedence < state.expressionsPrecedence.CallExpression) {
      state.write('(');
      this[node.callee.type](node.callee, state);
      state.write(')');
    } else {
      this[node.callee.type](node.callee, state);
    }

    if (node.optional) {
      state.write('?.');
    }

    formatSequence(state, node['arguments']);
  },
  ChainExpression: function ChainExpression(node, state) {
    this[node.expression.type](node.expression, state);
  },
  MemberExpression: function MemberExpression(node, state) {
    var precedence = state.expressionsPrecedence[node.object.type];

    if (precedence === NEEDS_PARENTHESES || precedence < state.expressionsPrecedence.MemberExpression) {
      state.write('(');
      this[node.object.type](node.object, state);
      state.write(')');
    } else {
      this[node.object.type](node.object, state);
    }

    if (node.computed) {
      if (node.optional) {
        state.write('?.');
      }

      state.write('[');
      this[node.property.type](node.property, state);
      state.write(']');
    } else {
      if (node.optional) {
        state.write('?.');
      } else {
        state.write('.');
      }

      this[node.property.type](node.property, state);
    }
  },
  MetaProperty: function MetaProperty(node, state) {
    state.write(node.meta.name + '.' + node.property.name, node);
  },
  Identifier: function Identifier(node, state) {
    state.write(node.name, node);
  },
  PrivateIdentifier: function PrivateIdentifier(node, state) {
    state.write("#".concat(node.name), node);
  },
  Literal: function Literal(node, state) {
    if (node.raw != null) {
      state.write(node.raw, node);
    } else if (node.regex != null) {
      this.RegExpLiteral(node, state);
    } else if (node.bigint != null) {
      state.write(node.bigint + 'n', node);
    } else {
      state.write(stringify(node.value), node);
    }
  },
  RegExpLiteral: function RegExpLiteral(node, state) {
    var regex = node.regex;
    state.write("/".concat(regex.pattern, "/").concat(regex.flags), node);
  }
};
exports.GENERATOR = GENERATOR;
var EMPTY_OBJECT = {};
var baseGenerator = GENERATOR;
exports.baseGenerator = baseGenerator;

var State = function () {
  function State(options) {
    _classCallCheck(this, State);

    var setup = options == null ? EMPTY_OBJECT : options;
    this.output = '';

    if (setup.output != null) {
      this.output = setup.output;
      this.write = this.writeToStream;
    } else {
      this.output = '';
    }

    this.generator = setup.generator != null ? setup.generator : GENERATOR;
    this.expressionsPrecedence = setup.expressionsPrecedence != null ? setup.expressionsPrecedence : EXPRESSIONS_PRECEDENCE;
    this.indent = setup.indent != null ? setup.indent : '  ';
    this.lineEnd = setup.lineEnd != null ? setup.lineEnd : '\n';
    this.indentLevel = setup.startingIndentLevel != null ? setup.startingIndentLevel : 0;
    this.writeComments = setup.comments ? setup.comments : false;

    if (setup.sourceMap != null) {
      this.write = setup.output == null ? this.writeAndMap : this.writeToStreamAndMap;
      this.sourceMap = setup.sourceMap;
      this.line = 1;
      this.column = 0;
      this.lineEndSize = this.lineEnd.split('\n').length - 1;
      this.mapping = {
        original: null,
        generated: this,
        name: undefined,
        source: setup.sourceMap.file || setup.sourceMap._file
      };
    }
  }

  _createClass(State, [{
    key: "write",
    value: function write(code) {
      this.output += code;
    }
  }, {
    key: "writeToStream",
    value: function writeToStream(code) {
      this.output.write(code);
    }
  }, {
    key: "writeAndMap",
    value: function writeAndMap(code, node) {
      this.output += code;
      this.map(code, node);
    }
  }, {
    key: "writeToStreamAndMap",
    value: function writeToStreamAndMap(code, node) {
      this.output.write(code);
      this.map(code, node);
    }
  }, {
    key: "map",
    value: function map(code, node) {
      if (node != null) {
        var type = node.type;

        if (type[0] === 'L' && type[2] === 'n') {
          this.column = 0;
          this.line++;
          return;
        }

        if (node.loc != null) {
          var mapping = this.mapping;
          mapping.original = node.loc.start;
          mapping.name = node.name;
          this.sourceMap.addMapping(mapping);
        }

        if (type[0] === 'T' && type[8] === 'E' || type[0] === 'L' && type[1] === 'i' && typeof node.value === 'string') {
          var _length = code.length;
          var column = this.column,
              line = this.line;

          for (var i = 0; i < _length; i++) {
            if (code[i] === '\n') {
              column = 0;
              line++;
            } else {
              column++;
            }
          }

          this.column = column;
          this.line = line;
          return;
        }
      }

      var length = code.length;
      var lineEnd = this.lineEnd;

      if (length > 0) {
        if (this.lineEndSize > 0 && (lineEnd.length === 1 ? code[length - 1] === lineEnd : code.endsWith(lineEnd))) {
          this.line += this.lineEndSize;
          this.column = 0;
        } else {
          this.column += length;
        }
      }
    }
  }, {
    key: "toString",
    value: function toString() {
      return this.output;
    }
  }]);

  return State;
}();

function generate(node, options) {
  var state = new State(options);
  state.generator[node.type](node, state);
  return state.output;
}


},{}],3:[function(require,module,exports){
!function(e,t){"object"==typeof exports&&"undefined"!=typeof module?t(exports):"function"==typeof define&&define.amd?define(["exports"],t):t((e="undefined"!=typeof globalThis?globalThis:e||self).meriyah={})}(this,function(e){"use strict";const t=((e,t)=>{const r=new Uint32Array(69632);let n=0,o=0;for(;n<2597;){const a=e[n++];if(a<0)o-=a;else{let i=e[n++];2&a&&(i=t[i]),1&a?r.fill(i,o,o+=e[n++]):r[o++]=i}}return r})([-1,2,26,2,27,2,5,-1,0,77595648,3,44,2,3,0,14,2,61,2,62,3,0,3,0,3168796671,0,4294956992,2,1,2,0,2,41,3,0,4,0,4294966523,3,0,4,2,16,2,63,2,0,0,4294836735,0,3221225471,0,4294901942,2,64,0,134152192,3,0,2,0,4294951935,3,0,2,0,2683305983,0,2684354047,2,17,2,0,0,4294961151,3,0,2,2,19,2,0,0,608174079,2,0,2,58,2,7,2,6,0,4286643967,3,0,2,2,1,3,0,3,0,4294901711,2,40,0,4089839103,0,2961209759,0,1342439375,0,4294543342,0,3547201023,0,1577204103,0,4194240,0,4294688750,2,2,0,80831,0,4261478351,0,4294549486,2,2,0,2967484831,0,196559,0,3594373100,0,3288319768,0,8469959,0,65472,2,3,0,4093640191,0,929054175,0,65487,0,4294828015,0,4092591615,0,1885355487,0,982991,2,3,2,0,0,2163244511,0,4227923919,0,4236247022,2,69,0,4284449919,0,851904,2,4,2,12,0,67076095,-1,2,70,0,1073741743,0,4093607775,-1,0,50331649,0,3265266687,2,33,0,4294844415,0,4278190047,2,20,2,137,-1,3,0,2,2,23,2,0,2,9,2,0,2,15,2,22,3,0,10,2,72,2,0,2,73,2,74,2,75,2,0,2,76,2,0,2,11,0,261632,2,25,3,0,2,2,13,2,4,3,0,18,2,77,2,5,3,0,2,2,78,0,2151677951,2,29,2,10,0,909311,3,0,2,0,814743551,2,48,0,67090432,3,0,2,2,42,2,0,2,6,2,0,2,30,2,8,0,268374015,2,108,2,51,2,0,2,79,0,134153215,-1,2,7,2,0,2,8,0,2684354559,0,67044351,0,3221160064,2,9,2,18,3,0,2,2,53,0,1046528,3,0,3,2,10,2,0,2,127,0,4294960127,2,9,2,6,2,11,0,4294377472,2,12,3,0,16,2,13,2,0,2,80,2,9,2,0,2,81,2,82,2,83,0,12288,2,54,0,1048577,2,84,2,14,-1,2,14,0,131042,2,85,2,86,2,87,2,0,2,34,-83,3,0,7,0,1046559,2,0,2,15,2,0,0,2147516671,2,21,3,88,2,2,0,-16,2,89,0,524222462,2,4,2,0,0,4269801471,2,4,3,0,2,2,28,2,16,3,0,2,2,49,2,0,-1,2,17,-16,3,0,206,-2,3,0,692,2,71,-1,2,17,2,9,3,0,8,2,91,2,18,2,0,0,3220242431,3,0,3,2,19,2,92,2,93,3,0,2,2,94,2,0,2,20,2,95,2,0,0,4351,2,0,2,10,3,0,2,0,67043391,0,3909091327,2,0,2,24,2,10,2,20,3,0,2,0,67076097,2,8,2,0,2,21,0,67059711,0,4236247039,3,0,2,0,939524103,0,8191999,2,99,2,100,2,22,2,23,3,0,3,0,67057663,3,0,349,2,101,2,102,2,7,-264,3,0,11,2,24,3,0,2,2,32,-1,0,3774349439,2,103,2,104,3,0,2,2,19,2,105,3,0,10,2,9,2,17,2,0,2,46,2,0,2,31,2,106,2,25,0,1638399,0,57344,2,107,3,0,3,2,20,2,26,2,27,2,5,2,28,2,0,2,8,2,109,-1,2,110,2,111,2,112,-1,3,0,3,2,12,-2,2,0,2,29,-3,0,536870912,-4,2,20,2,0,2,36,0,1,2,0,2,65,2,6,2,12,2,9,2,0,2,113,-1,3,0,4,2,9,2,23,2,114,2,7,2,0,2,115,2,0,2,116,2,117,2,118,2,0,2,10,3,0,9,2,21,2,30,2,31,2,119,2,120,-2,2,121,2,122,2,30,2,21,2,8,-2,2,123,2,30,3,32,2,-1,2,0,2,39,-2,0,4277137519,0,2269118463,-1,3,20,2,-1,2,33,2,38,2,0,3,30,2,2,35,2,19,-3,3,0,2,2,34,-1,2,0,2,35,2,0,2,35,2,0,2,47,2,0,0,4294950463,2,37,-7,2,0,0,203775,2,125,0,4227858432,2,20,2,43,2,36,2,17,2,37,2,17,2,124,2,21,3,0,2,2,38,0,2151677888,2,0,2,12,0,4294901764,2,145,2,0,2,56,2,55,0,5242879,3,0,2,0,402644511,-1,2,128,2,39,0,3,-1,2,129,2,130,2,0,0,67045375,2,40,0,4226678271,0,3766565279,0,2039759,2,132,2,41,0,1046437,0,6,3,0,2,0,3288270847,0,3,3,0,2,0,67043519,-5,2,0,0,4282384383,0,1056964609,-1,3,0,2,0,67043345,-1,2,0,2,42,2,23,2,50,2,11,2,59,2,38,-5,2,0,2,12,-3,3,0,2,0,2147484671,2,133,0,4190109695,2,52,-2,2,134,0,4244635647,0,27,2,0,2,8,2,43,2,0,2,66,2,17,2,0,2,42,-3,2,31,-2,2,0,2,45,2,57,2,44,2,45,2,135,2,46,0,8388351,-2,2,136,0,3028287487,2,47,2,138,0,33259519,2,23,2,7,2,48,-7,2,21,0,4294836223,0,3355443199,0,134152199,-2,2,67,-2,3,0,28,2,32,-3,3,0,3,2,49,3,0,6,2,50,-81,2,17,3,0,2,2,36,3,0,33,2,25,2,30,3,0,124,2,12,3,0,18,2,38,-213,2,0,2,32,-54,3,0,17,2,42,2,8,2,23,2,0,2,8,2,23,2,51,2,0,2,21,2,52,2,139,2,25,-13,2,0,2,53,-6,3,0,2,-1,2,140,2,10,-1,3,0,2,0,4294936575,2,0,0,4294934783,-2,0,8323099,3,0,230,2,30,2,54,2,8,-3,3,0,3,2,35,-271,2,141,3,0,9,2,142,2,143,2,55,3,0,11,2,7,-72,3,0,3,2,144,0,1677656575,-130,2,26,-16,2,0,2,24,2,38,-16,0,4161266656,0,4071,0,15360,-4,0,28,-13,3,0,2,2,56,2,0,2,146,2,147,2,60,2,0,2,148,2,149,2,150,3,0,10,2,151,2,152,2,22,3,56,2,3,153,2,3,57,2,0,4294954999,2,0,-16,2,0,2,90,2,0,0,2105343,0,4160749584,0,65534,-34,2,8,2,155,-6,0,4194303871,0,4294903771,2,0,2,58,2,98,-3,2,0,0,1073684479,0,17407,-9,2,17,2,49,2,0,2,32,-14,2,17,2,32,-6,2,17,2,12,-6,2,8,0,3225419775,-7,2,156,3,0,6,0,8323103,-1,3,0,2,2,59,-37,2,60,2,157,2,158,2,159,2,160,2,161,-105,2,26,-32,3,0,1335,-1,3,0,136,2,9,3,0,180,2,24,3,0,233,2,162,3,0,18,2,9,-77,3,0,16,2,9,-47,3,0,154,2,6,3,0,264,2,32,-22116,3,0,7,2,25,-6130,3,5,2,-1,0,69207040,3,44,2,3,0,14,2,61,2,62,-3,0,3168731136,0,4294956864,2,1,2,0,2,41,3,0,4,0,4294966275,3,0,4,2,16,2,63,2,0,2,34,-1,2,17,2,64,-1,2,0,0,2047,0,4294885376,3,0,2,0,3145727,0,2617294944,0,4294770688,2,25,2,65,3,0,2,0,131135,2,96,0,70256639,0,71303167,0,272,2,42,2,6,0,65279,2,0,2,48,-1,2,97,2,66,0,4278255616,0,4294836227,0,4294549473,0,600178175,0,2952806400,0,268632067,0,4294543328,0,57540095,0,1577058304,0,1835008,0,4294688736,2,68,2,67,0,33554435,2,131,2,68,0,2952790016,0,131075,0,3594373096,0,67094296,2,67,-1,0,4294828e3,0,603979263,0,922746880,0,3,0,4294828001,0,602930687,0,1879048192,0,393219,0,4294828016,0,671088639,0,2154840064,0,4227858435,0,4236247008,2,69,2,38,-1,2,4,0,917503,2,38,-1,2,70,0,537788335,0,4026531935,-1,0,1,-1,2,33,2,71,0,7936,-3,2,0,0,2147485695,0,1010761728,0,4292984930,0,16387,2,0,2,15,2,22,3,0,10,2,72,2,0,2,73,2,74,2,75,2,0,2,76,2,0,2,12,-1,2,25,3,0,2,2,13,2,4,3,0,18,2,77,2,5,3,0,2,2,78,0,2147745791,3,19,2,0,122879,2,0,2,10,0,276824064,-2,3,0,2,2,42,2,0,0,4294903295,2,0,2,30,2,8,-1,2,17,2,51,2,0,2,79,2,48,-1,2,21,2,0,2,29,-2,0,128,-2,2,28,2,10,0,8160,-1,2,126,0,4227907585,2,0,2,37,2,0,2,50,0,4227915776,2,9,2,6,2,11,-1,0,74440192,3,0,6,-2,3,0,8,2,13,2,0,2,80,2,9,2,0,2,81,2,82,2,83,-3,2,84,2,14,-3,2,85,2,86,2,87,2,0,2,34,-83,3,0,7,0,817183,2,0,2,15,2,0,0,33023,2,21,3,88,2,-17,2,89,0,524157950,2,4,2,0,2,90,2,4,2,0,2,22,2,28,2,16,3,0,2,2,49,2,0,-1,2,17,-16,3,0,206,-2,3,0,692,2,71,-1,2,17,2,9,3,0,8,2,91,0,3072,2,0,0,2147516415,2,9,3,0,2,2,25,2,92,2,93,3,0,2,2,94,2,0,2,20,2,95,0,4294965179,0,7,2,0,2,10,2,93,2,10,-1,0,1761345536,2,96,0,4294901823,2,38,2,20,2,97,2,35,2,98,0,2080440287,2,0,2,34,2,154,0,3296722943,2,0,0,1046675455,0,939524101,0,1837055,2,99,2,100,2,22,2,23,3,0,3,0,7,3,0,349,2,101,2,102,2,7,-264,3,0,11,2,24,3,0,2,2,32,-1,0,2700607615,2,103,2,104,3,0,2,2,19,2,105,3,0,10,2,9,2,17,2,0,2,46,2,0,2,31,2,106,-3,2,107,3,0,3,2,20,-1,3,5,2,2,108,2,0,2,8,2,109,-1,2,110,2,111,2,112,-1,3,0,3,2,12,-2,2,0,2,29,-8,2,20,2,0,2,36,-1,2,0,2,65,2,6,2,30,2,9,2,0,2,113,-1,3,0,4,2,9,2,17,2,114,2,7,2,0,2,115,2,0,2,116,2,117,2,118,2,0,2,10,3,0,9,2,21,2,30,2,31,2,119,2,120,-2,2,121,2,122,2,30,2,21,2,8,-2,2,123,2,30,3,32,2,-1,2,0,2,39,-2,0,4277075969,2,30,-1,3,20,2,-1,2,33,2,124,2,0,3,30,2,2,35,2,19,-3,3,0,2,2,34,-1,2,0,2,35,2,0,2,35,2,0,2,50,2,96,0,4294934591,2,37,-7,2,0,0,197631,2,125,-1,2,20,2,43,2,37,2,17,0,3,2,17,2,124,2,21,2,126,2,127,-1,0,2490368,2,126,2,25,2,17,2,34,2,126,2,38,0,4294901904,0,4718591,2,126,2,35,0,335544350,-1,2,128,0,2147487743,0,1,-1,2,129,2,130,2,8,-1,2,131,2,68,0,3758161920,0,3,2,132,0,12582911,0,655360,-1,2,0,2,29,0,2147485568,0,3,2,0,2,25,0,176,-5,2,0,2,49,0,251658240,-1,2,0,2,25,0,16,-1,2,0,0,16779263,-2,2,12,-1,2,38,-5,2,0,2,18,-3,3,0,2,2,54,2,133,0,2147549183,0,2,-2,2,134,2,36,0,10,0,4294965249,0,67633151,0,4026597376,2,0,0,536871935,2,17,2,0,2,42,-6,2,0,0,1,2,57,2,49,0,1,2,135,2,25,-3,2,136,2,36,2,137,2,138,0,16778239,2,17,2,7,-8,2,35,0,4294836212,2,10,-3,2,67,-2,3,0,28,2,32,-3,3,0,3,2,49,3,0,6,2,50,-81,2,17,3,0,2,2,36,3,0,33,2,25,0,126,3,0,124,2,12,3,0,18,2,38,-213,2,9,-55,3,0,17,2,42,2,8,2,17,2,0,2,8,2,17,2,58,2,0,2,25,2,50,2,139,2,25,-13,2,0,2,71,-6,3,0,2,-1,2,140,2,10,-1,3,0,2,0,67583,-1,2,105,-2,0,8126475,3,0,230,2,30,2,54,2,8,-3,3,0,3,2,35,-271,2,141,3,0,9,2,142,2,143,2,55,3,0,11,2,7,-72,3,0,3,2,144,2,145,-187,3,0,2,2,56,2,0,2,146,2,147,2,60,2,0,2,148,2,149,2,150,3,0,10,2,151,2,152,2,22,3,56,2,3,153,2,3,57,2,2,154,-57,2,8,2,155,-7,2,17,2,0,2,58,-4,2,0,0,1065361407,0,16384,-9,2,17,2,58,2,0,2,18,-14,2,17,2,18,-6,2,17,0,81919,-6,2,8,0,3223273399,-7,2,156,3,0,6,2,124,-1,3,0,2,0,2063,-37,2,60,2,157,2,158,2,159,2,160,2,161,-138,3,0,1335,-1,3,0,136,2,9,3,0,180,2,24,3,0,233,2,162,3,0,18,2,9,-77,3,0,16,2,9,-47,3,0,154,2,6,3,0,264,2,32,-28252],[4294967295,4294967291,4092460543,4294828031,4294967294,134217726,4294903807,268435455,2147483647,1073741823,1048575,3892314111,134217727,1061158911,536805376,4294910143,4294901759,4294901760,4095,262143,536870911,8388607,4160749567,4294902783,4294918143,65535,67043328,2281701374,4294967264,2097151,4194303,255,67108863,4294967039,511,524287,131071,63,127,3238002687,4294549487,4290772991,33554431,4294901888,4286578687,67043329,4294770687,67043583,1023,32767,15,2047999,67043343,67051519,2147483648,4294902e3,4292870143,4294966783,16383,67047423,4294967279,262083,20511,41943039,493567,4294959104,603979775,65536,602799615,805044223,4294965206,8191,1031749119,4294917631,2134769663,4286578493,4282253311,4294942719,33540095,4294905855,2868854591,1608515583,265232348,534519807,2147614720,1060109444,4093640016,17376,2139062143,224,4169138175,4294909951,4286578688,4294967292,4294965759,4294836224,4294966272,4294967280,32768,8289918,4294934399,4294901775,4294965375,1602223615,4294967259,4294443008,268369920,4292804608,4294967232,486341884,4294963199,3087007615,1073692671,4128527,4279238655,4294902015,4160684047,4290246655,469499899,4294967231,134086655,4294966591,2445279231,3670015,31,252,4294967288,16777215,4294705151,3221208447,4294902271,4294549472,4294921215,4285526655,4294966527,4294705152,4294966143,64,4294966719,3774873592,4194303999,1877934080,262151,2555904,536807423,67043839,3758096383,3959414372,3755993023,2080374783,4294835295,4294967103,4160749565,4294934527,4087,2016,2147446655,184024726,2862017156,1593309078,268434431,268434414,4294901761]),r=e=>!!(1&t[(e>>>5)+34816]>>>e),n=[0,0,0,0,0,0,0,0,0,0,1032,0,0,2056,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8192,0,3,0,0,8192,0,0,0,256,0,33024,0,0,242,242,114,114,114,114,114,114,594,594,0,0,16384,0,0,0,0,67,67,67,67,67,67,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,1,0,0,4099,0,71,71,71,71,71,71,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,16384,0,0,0,0],o=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0],a=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0];function i(e){return e<=127?o[e]>0:r(e)}function s(e){return e<=127?a[e]>0:(e=>!!(1&t[(e>>>5)+0]>>>e))(e)||8204===e||8205===e}function c(e){return e.column++,e.currentChar=e.source.charCodeAt(++e.index)}function l(e){const t=e.currentChar;if(55296!=(64512&t))return 0;const r=e.source.charCodeAt(e.index+1);return 56320!=(64512&r)?0:65536+((1023&t)<<10)+(1023&r)}function u(e,t){e.currentChar=e.source.charCodeAt(++e.index),e.flags|=1,4&t||(e.column=0,e.line++)}function p(e){e.flags|=1,e.currentChar=e.source.charCodeAt(++e.index),e.column=0,e.line++}function d(e){return 160===e||65279===e||133===e||5760===e||e>=8192&&e<=8203||8239===e||8287===e||12288===e||8201===e||65519===e}function g(e){return e<65?e-48:e-65+10&15}function f(e){switch(e){case 134283266:return"NumericLiteral";case 134283267:return"StringLiteral";case 86021:case 86022:return"BooleanLiteral";case 86023:return"NullLiteral";case 65540:return"RegularExpression";case 67174408:case 67174409:case 131:return"TemplateLiteral";default:return 143360&~e?4096&~e?"Punctuator":"Keyword":"Identifier"}}const k=["SingleLine","MultiLine","HTMLOpen","HTMLClose","HashbangComment"];function h(e,t,r,n,o,a){return 2&n&&e.report(0),m(e,t,r,o,a)}function m(e,t,r,o,a){const{index:i}=e;for(e.tokenIndex=e.index,e.tokenLine=e.line,e.tokenColumn=e.column;e.index<e.end;){if(8&n[e.currentChar]){const r=13===e.currentChar;p(e),r&&e.index<e.end&&10===e.currentChar&&(e.currentChar=t.charCodeAt(++e.index));break}if((8232^e.currentChar)<=1){p(e);break}c(e),e.tokenIndex=e.index,e.tokenLine=e.line,e.tokenColumn=e.column}if(e.options.onComment){const r={start:{line:a.line,column:a.column},end:{line:e.tokenLine,column:e.tokenColumn}};e.options.onComment(k[255&o],t.slice(i,e.tokenIndex),a.index,e.tokenIndex,r)}return 1|r}function b(e,t,r){const{index:o}=e;for(;e.index<e.end;)if(e.currentChar<43){let a=!1;for(;42===e.currentChar;)if(a||(r&=-5,a=!0),47===c(e)){if(c(e),e.options.onComment){const r={start:{line:e.tokenLine,column:e.tokenColumn},end:{line:e.line,column:e.column}};e.options.onComment(k[1],t.slice(o,e.index-2),o-2,e.index,r)}return e.tokenIndex=e.index,e.tokenLine=e.line,e.tokenColumn=e.column,r}if(a)continue;8&n[e.currentChar]?13===e.currentChar?(r|=5,p(e)):(u(e,r),r=-5&r|1):c(e)}else(8232^e.currentChar)<=1?(r=-5&r|1,p(e)):(r&=-5,c(e));e.report(18)}const T={0:"Unexpected token",30:"Unexpected token: '%0'",1:"Octal escape sequences are not allowed in strict mode",2:"Octal escape sequences are not allowed in template strings",3:"\\8 and \\9 are not allowed in template strings",4:"Private identifier #%0 is not defined",5:"Illegal Unicode escape sequence",6:"Invalid code point %0",7:"Invalid hexadecimal escape sequence",9:"Octal literals are not allowed in strict mode",8:"Decimal integer literals with a leading zero are forbidden in strict mode",10:"Expected number in radix %0",151:"Invalid left-hand side assignment to a destructible right-hand side",11:"Non-number found after exponent indicator",12:"Invalid BigIntLiteral",13:"No identifiers allowed directly after numeric literal",14:"Escapes \\8 or \\9 are not syntactically valid escapes",15:"Escapes \\8 or \\9 are not allowed in strict mode",16:"Unterminated string literal",17:"Unterminated template literal",18:"Multiline comment was not closed properly",19:"The identifier contained dynamic unicode escape that was not closed",20:"Illegal character '%0'",21:"Missing hexadecimal digits",22:"Invalid implicit octal",23:"Invalid line break in string literal",24:"Only unicode escapes are legal in identifier names",25:"Expected '%0'",26:"Invalid left-hand side in assignment",27:"Invalid left-hand side in async arrow",28:'Calls to super must be in the "constructor" method of a class expression or class declaration that has a superclass',29:"Member access on super must be in a method",31:"Await expression not allowed in formal parameter",32:"Yield expression not allowed in formal parameter",95:"Unexpected token: 'escaped keyword'",33:"Unary expressions as the left operand of an exponentiation expression must be disambiguated with parentheses",123:"Async functions can only be declared at the top level or inside a block",34:"Unterminated regular expression",35:"Unexpected regular expression flag",36:"Duplicate regular expression flag '%0'",37:"%0 functions must have exactly %1 argument%2",38:"Setter function argument must not be a rest parameter",39:"%0 declaration must have a name in this context",40:"Function name may not contain any reserved words or be eval or arguments in strict mode",41:"The rest operator is missing an argument",42:"A getter cannot be a generator",43:"A setter cannot be a generator",44:"A computed property name must be followed by a colon or paren",134:"Object literal keys that are strings or numbers must be a method or have a colon",46:"Found `* async x(){}` but this should be `async * x(){}`",45:"Getters and setters can not be generators",47:"'%0' can not be generator method",48:"No line break is allowed after '=>'",49:"The left-hand side of the arrow can only be destructed through assignment",50:"The binding declaration is not destructible",51:"Async arrow can not be followed by new expression",52:"Classes may not have a static property named 'prototype'",53:"Class constructor may not be a %0",54:"Duplicate constructor method in class",55:"Invalid increment/decrement operand",56:"Invalid use of `new` keyword on an increment/decrement expression",57:"`=>` is an invalid assignment target",58:"Rest element may not have a trailing comma",59:"Missing initializer in %0 declaration",60:"'for-%0' loop head declarations can not have an initializer",61:"Invalid left-hand side in for-%0 loop: Must have a single binding",62:"Invalid shorthand property initializer",63:"Property name __proto__ appears more than once in object literal",64:"Let is disallowed as a lexically bound name",65:"Invalid use of '%0' inside new expression",66:"Illegal 'use strict' directive in function with non-simple parameter list",67:'Identifier "let" disallowed as left-hand side expression in strict mode',68:"Illegal continue statement",69:"Illegal break statement",70:"Cannot have `let[...]` as a var name in strict mode",71:"Invalid destructuring assignment target",72:"Rest parameter may not have a default initializer",73:"The rest argument must the be last parameter",74:"Invalid rest argument",76:"In strict mode code, functions can only be declared at top level or inside a block",77:"In non-strict mode code, functions can only be declared at top level, inside a block, or as the body of an if statement",78:"Without web compatibility enabled functions can not be declared at top level, inside a block, or as the body of an if statement",79:"Class declaration can't appear in single-statement context",80:"Invalid left-hand side in for-%0",81:"Invalid assignment in for-%0",82:"for await (... of ...) is only valid in async functions and async generators",83:"The first token after the template expression should be a continuation of the template",85:"`let` declaration not allowed here and `let` cannot be a regular var name in strict mode",84:"`let \n [` is a restricted production at the start of a statement",86:"Catch clause requires exactly one parameter, not more (and no trailing comma)",87:"Catch clause parameter does not support default values",88:"Missing catch or finally after try",89:"More than one default clause in switch statement",90:"Illegal newline after throw",91:"Strict mode code may not include a with statement",92:"Illegal return statement",93:"The left hand side of the for-header binding declaration is not destructible",94:"new.target only allowed within functions or static blocks",96:"'#' not followed by identifier",102:"Invalid keyword",101:"Can not use 'let' as a class name",100:"'A lexical declaration can't define a 'let' binding",99:"Can not use `let` as variable name in strict mode",97:"'%0' may not be used as an identifier in this context",98:"Await is only valid in async functions",103:"The %0 keyword can only be used with the module goal",104:"Unicode codepoint must not be greater than 0x10FFFF",105:"%0 source must be string",106:"Only a identifier or string can be used to indicate alias",107:"Only '*' or '{...}' can be imported after default",108:"Trailing decorator may be followed by method",109:"Decorators can't be used with a constructor",110:"Can not use `await` as identifier in module or async func",111:"Can not use `await` as identifier in module",112:"HTML comments are only allowed with web compatibility (Annex B)",113:"The identifier 'let' must not be in expression position in strict mode",114:"Cannot assign to `eval` and `arguments` in strict mode",115:"The left-hand side of a for-of loop may not start with 'let'",116:"Block body arrows can not be immediately invoked without a group",117:"Block body arrows can not be immediately accessed without a group",118:"Unexpected strict mode reserved word",119:"Unexpected eval or arguments in strict mode",120:"Decorators must not be followed by a semicolon",121:"Calling delete on expression not allowed in strict mode",122:"Pattern can not have a tail",124:"Can not have a `yield` expression on the left side of a ternary",125:"An arrow function can not have a postfix update operator",126:"Invalid object literal key character after generator star",127:"Private fields can not be deleted",129:"Classes may not have a field called constructor",128:"Classes may not have a private element named constructor",130:"A class field initializer or static block may not contain arguments",131:"Generators can only be declared at the top level or inside a block",132:"Async methods are a restricted production and cannot have a newline following it",133:"Unexpected character after object literal property name",135:"Invalid key token",136:"Label '%0' has already been declared",137:"continue statement must be nested within an iteration statement",138:"Undefined label '%0'",139:"Trailing comma is disallowed inside import(...) arguments",140:"Invalid binding in JSON import",141:"import() requires exactly one argument",142:"Cannot use new with import(...)",143:"... is not allowed in import()",144:"Expected '=>'",145:"Duplicate binding '%0'",146:"Duplicate private identifier #%0",147:"Cannot export a duplicate name '%0'",150:"Duplicate %0 for-binding",148:"Exported binding '%0' needs to refer to a top-level declared variable",149:"Unexpected private field",153:"Numeric separators are not allowed at the end of numeric literals",152:"Only one underscore is allowed as numeric separator",154:"JSX value should be either an expression or a quoted JSX text",155:"Expected corresponding JSX closing tag for %0",156:"Adjacent JSX elements must be wrapped in an enclosing tag",157:"JSX attributes must only be assigned a non-empty 'expression'",158:"'%0' has already been declared",159:"'%0' shadowed a catch clause binding",160:"Dot property must be an identifier",161:"Encountered invalid input after spread/rest argument",162:"Catch without try",163:"Finally without try",164:"Expected corresponding closing tag for JSX fragment",165:"Coalescing and logical operators used together in the same expression must be disambiguated with parentheses",166:"Invalid tagged template on optional chain",167:"Invalid optional chain from super property",168:"Invalid optional chain from new expression",169:'Cannot use "import.meta" outside a module',170:"Leading decorators must be attached to a class declaration",171:"An export name cannot include a lone surrogate",172:"A string literal cannot be used as an exported binding without `from`",173:"Private fields can't be accessed on super",174:"The only valid meta property for import is 'import.meta'",175:"'import.meta' must not contain escaped characters",176:'cannot use "await" as identifier inside an async function',177:'cannot use "await" in static blocks'};class y extends SyntaxError{start;end;range;loc;description;constructor(e,t,r,...n){const o=T[r].replace(/%(\d+)/g,(e,t)=>n[t]);super("["+e.line+":"+e.column+"-"+t.line+":"+t.column+"]: "+o),this.start=e.index,this.end=t.index,this.range=[e.index,t.index],this.loc={start:{line:e.line,column:e.column},end:{line:t.line,column:t.column}},this.description=o}}function x(e,t){return Object.hasOwn(e,t)?e[t]:void 0}const w=["end of source","identifier","number","string","regular expression","false","true","null","template continuation","template tail","=>","(","{",".","...","}",")",";",",","[","]",":","?","'",'"',"++","--","=","<<=",">>=",">>>=","**=","+=","-=","*=","/=","%=","^=","|=","&=","||=","&&=","??=","typeof","delete","void","!","~","+","-","in","instanceof","*","%","/","**","&&","||","===","!==","==","!=","<=",">=","<",">","<<",">>",">>>","&","|","^","var","let","const","break","case","catch","class","continue","debugger","default","do","else","export","extends","finally","for","function","if","import","new","return","super","switch","this","throw","try","while","with","implements","interface","package","private","protected","public","static","yield","as","async","await","constructor","get","set","accessor","from","of","enum","eval","arguments","escaped keyword","escaped future reserved keyword","reserved if strict","#","BigIntLiteral","??","?.","WhiteSpace","Illegal","LineTerminator","PrivateField","Template","@","target","meta","LineFeed","Escaped","JSXText"],S={this:86111,function:86104,if:20569,return:20572,var:86088,else:20563,for:20567,new:86107,in:8673330,typeof:16863275,while:20578,case:20556,break:20555,try:20577,catch:20557,delete:16863276,throw:86112,switch:86110,continue:20559,default:20561,instanceof:8411187,do:20562,void:16863277,finally:20566,async:209005,await:209006,class:86094,const:86090,constructor:12399,debugger:20560,export:20564,extends:20565,false:86021,from:209011,get:209008,implements:36964,import:86106,interface:36965,let:241737,null:86023,of:471156,package:36966,private:36967,protected:36968,public:36969,set:209009,static:36970,super:86109,true:86022,with:20579,yield:241771,enum:86133,eval:537079926,as:77932,arguments:537079927,target:209029,meta:209030,accessor:12402};function v(e,t,r){for(;a[c(e)];);return e.tokenValue=e.source.slice(e.tokenIndex,e.index),92!==e.currentChar&&e.currentChar<=126?x(S,e.tokenValue)??208897:q(e,t,0,r)}function C(e,t){const r=N(e);return i(r)||e.report(5),e.tokenValue=String.fromCodePoint(r),q(e,t,1,4&n[r])}function q(e,t,r,o){let a=e.index;for(;e.index<e.end;)if(92===e.currentChar){e.tokenValue+=e.source.slice(a,e.index),r=1;const t=N(e);s(t)||e.report(5),o=o&&4&n[t],e.tokenValue+=String.fromCodePoint(t),a=e.index}else{const t=l(e);if(t>0)s(t)||e.report(20,String.fromCodePoint(t)),e.currentChar=t,e.index++,e.column++;else if(!s(e.currentChar))break;c(e)}e.index<=e.end&&(e.tokenValue+=e.source.slice(a,e.index));const{length:i}=e.tokenValue;if(o&&i>=2&&i<=11){const n=x(S,e.tokenValue);return void 0===n?208897|(r?-2147483648:0):r?209006===n?2050&t?-2147483528:-2147483648|n:1&t?36970===n?-2147483527:36864&~n?20480&~n?-2147274630:262144&t&&!(8&t)?-2147483648|n:-2147483528:-2147483527:!(262144&t)||8&t||20480&~n?241771===n?262144&t?-2147274630:1024&t?-2147483528:-2147483648|n:209005===n?-2147274630:36864&~n?-2147483528:12288|n|-2147483648:-2147483648|n:n}return 208897|(r?-2147483648:0)}function E(e){let t=c(e);if(92===t)return 130;const r=l(e);return r&&(t=r),i(t)||e.report(96),130}function N(e){return 117!==e.source.charCodeAt(e.index+1)&&e.report(5),e.currentChar=e.source.charCodeAt(e.index+=2),e.column+=2,function(e){let t=0;const r=e.currentChar;if(123===r){const r=e.index-2;for(;64&n[c(e)];)if(t=t<<4|g(e.currentChar),t>1114111)throw new y({index:r,line:e.line,column:e.column},e.currentLocation,104);if(125!==e.currentChar)throw new y({index:r,line:e.line,column:e.column},e.currentLocation,7);return c(e),t}64&n[r]||e.report(7);const o=e.source.charCodeAt(e.index+1);64&n[o]||e.report(7);const a=e.source.charCodeAt(e.index+2);64&n[a]||e.report(7);const i=e.source.charCodeAt(e.index+3);64&n[i]||e.report(7);return t=g(r)<<12|g(o)<<8|g(a)<<4|g(i),e.currentChar=e.source.charCodeAt(e.index+=4),e.column+=4,t}(e)}function L(e,t,r){let o=e.currentChar,a=0,s=9,l=64&r?0:1,u=0,p=0;if(64&r)a="."+A(e,o),o=e.currentChar,110===o&&e.report(12);else{if(48===o)if(o=c(e),120==(32|o)){for(r=136,o=c(e);4160&n[o];)95!==o?(p=1,a=16*a+g(o),u++,o=c(e)):(p||e.report(152),p=0,o=c(e));0!==u&&p||e.report(0===u?21:153)}else if(111==(32|o)){for(r=132,o=c(e);4128&n[o];)95!==o?(p=1,a=8*a+(o-48),u++,o=c(e)):(p||e.report(152),p=0,o=c(e));0!==u&&p||e.report(0===u?0:153)}else if(98==(32|o)){for(r=130,o=c(e);4224&n[o];)95!==o?(p=1,a=2*a+(o-48),u++,o=c(e)):(p||e.report(152),p=0,o=c(e));0!==u&&p||e.report(0===u?0:153)}else if(32&n[o])for(1&t&&e.report(1),r=1;16&n[o];){if(512&n[o]){r=32,l=0;break}a=8*a+(o-48),o=c(e)}else 512&n[o]?(1&t&&e.report(1),e.flags|=64,r=32):95===o&&e.report(0);if(48&r){if(l){for(;s>=0&&4112&n[o];)if(95!==o)p=0,a=10*a+(o-48),o=c(e),--s;else{if(o=c(e),95===o||32&r)throw new y(e.currentLocation,{index:e.index+1,line:e.line,column:e.column},152);p=1}if(p)throw new y(e.currentLocation,{index:e.index+1,line:e.line,column:e.column},153);if(s>=0&&!i(o)&&46!==o)return e.tokenValue=a,e.options.raw&&(e.tokenRaw=e.source.slice(e.tokenIndex,e.index)),134283266}a+=A(e,o),o=e.currentChar,46===o&&(95===c(e)&&e.report(0),r=64,a+="."+A(e,e.currentChar),o=e.currentChar)}}const d=e.index;let f=0;if(110===o&&128&r)f=1,o=c(e);else if(101==(32|o)){o=c(e),256&n[o]&&(o=c(e));const{index:t}=e;16&n[o]||e.report(11),a+=e.source.substring(d,t)+A(e,o),o=e.currentChar}return(e.index<e.end&&16&n[o]||i(o))&&e.report(13),f?(e.tokenRaw=e.source.slice(e.tokenIndex,e.index),e.tokenValue=BigInt(e.tokenRaw.slice(0,-1).replaceAll("_","")),134283388):(e.tokenValue=15&r?a:32&r?parseFloat(e.source.substring(e.tokenIndex,e.index)):+a,e.options.raw&&(e.tokenRaw=e.source.slice(e.tokenIndex,e.index)),134283266)}function A(e,t){let r=0,o=e.index,a="";for(;4112&n[t];){if(95===t){const{index:n}=e;if(95===(t=c(e)))throw new y(e.currentLocation,{index:e.index+1,line:e.line,column:e.column},152);r=1,a+=e.source.substring(o,n),o=e.index;continue}r=0,t=c(e)}if(r)throw new y(e.currentLocation,{index:e.index+1,line:e.line,column:e.column},153);return a+e.source.substring(o,e.index)}var I,V;function D(e){const t=e.index;let r=I.Empty;e:for(;;){const t=e.currentChar;if(c(e),r&I.Escape)r&=~I.Escape;else switch(t){case 47:if(r)break;break e;case 92:r|=I.Escape;break;case 91:r|=I.Class;break;case 93:r&=I.Escape}if(13!==t&&10!==t&&8232!==t&&8233!==t||e.report(34),e.index>=e.source.length)return e.report(34)}const n=e.index-1;let o=V.Empty,a=e.currentChar;const{index:i}=e;for(;s(a);){switch(a){case 103:o&V.Global&&e.report(36,"g"),o|=V.Global;break;case 105:o&V.IgnoreCase&&e.report(36,"i"),o|=V.IgnoreCase;break;case 109:o&V.Multiline&&e.report(36,"m"),o|=V.Multiline;break;case 117:o&V.Unicode&&e.report(36,"u"),o&V.UnicodeSets&&e.report(36,"vu"),o|=V.Unicode;break;case 118:o&V.Unicode&&e.report(36,"uv"),o&V.UnicodeSets&&e.report(36,"v"),o|=V.UnicodeSets;break;case 121:o&V.Sticky&&e.report(36,"y"),o|=V.Sticky;break;case 115:o&V.DotAll&&e.report(36,"s"),o|=V.DotAll;break;case 100:o&V.Indices&&e.report(36,"d"),o|=V.Indices;break;default:e.report(35)}a=c(e)}const l=e.source.slice(i,e.index),u=e.source.slice(t,n);return e.tokenRegExp={pattern:u,flags:l},e.options.raw&&(e.tokenRaw=e.source.slice(e.tokenIndex,e.index)),e.tokenValue=function(e,t,r){try{return new RegExp(t,r)}catch{if(!e.options.validateRegex)return null;e.report(34)}}(e,u,l),65540}function R(e,t,r){const{index:o}=e;let a="",i=c(e),s=e.index;for(;!(8&n[i]);){if(i===r)return a+=e.source.slice(s,e.index),c(e),e.options.raw&&(e.tokenRaw=e.source.slice(o,e.index)),e.tokenValue=a,134283267;if(8&~i||92!==i)8232!==i&&8233!==i||(e.column=-1,e.line++);else{if(a+=e.source.slice(s,e.index),i=c(e),i<127||8232===i||8233===i){const r=B(e,t,i);r>=0?a+=String.fromCodePoint(r):U(e,r,0)}else a+=String.fromCodePoint(i);s=e.index+1}e.index>=e.end&&e.report(16),i=c(e)}e.report(16)}function B(e,t,r,o=0){switch(r){case 98:return 8;case 102:return 12;case 114:return 13;case 110:return 10;case 116:return 9;case 118:return 11;case 13:if(e.index<e.end){const t=e.source.charCodeAt(e.index+1);10===t&&(e.index=e.index+1,e.currentChar=t)}case 10:case 8232:case 8233:return e.column=-1,e.line++,-1;case 48:case 49:case 50:case 51:{let a=r-48,i=e.index+1,s=e.column+1;if(i<e.end){const r=e.source.charCodeAt(i);if(32&n[r]){if(1&t||o)return-2;if(e.currentChar=r,a=a<<3|r-48,i++,s++,i<e.end){const t=e.source.charCodeAt(i);32&n[t]&&(e.currentChar=t,a=a<<3|t-48,i++,s++)}e.flags|=64}else if(0!==a||512&n[r]){if(1&t||o)return-2;e.flags|=64}e.index=i-1,e.column=s-1}return a}case 52:case 53:case 54:case 55:{if(o||1&t)return-2;let a=r-48;const i=e.index+1,s=e.column+1;if(i<e.end){const t=e.source.charCodeAt(i);32&n[t]&&(a=a<<3|t-48,e.currentChar=t,e.index=i,e.column=s)}return e.flags|=64,a}case 120:{const t=c(e);if(!(64&n[t]))return-4;const r=g(t),o=c(e);if(!(64&n[o]))return-4;return r<<4|g(o)}case 117:{const t=c(e);if(123===e.currentChar){let t=0;for(;64&n[c(e)];)if(t=t<<4|g(e.currentChar),t>1114111)return-5;return e.currentChar<1||125!==e.currentChar?-4:t}{if(!(64&n[t]))return-4;const r=e.source.charCodeAt(e.index+1);if(!(64&n[r]))return-4;const o=e.source.charCodeAt(e.index+2);if(!(64&n[o]))return-4;const a=e.source.charCodeAt(e.index+3);return 64&n[a]?(e.index+=3,e.column+=3,e.currentChar=e.source.charCodeAt(e.index),g(t)<<12|g(r)<<8|g(o)<<4|g(a)):-4}}case 56:case 57:if(o||!e.options.webcompat||1&t)return-3;e.flags|=4096;default:return r}}function U(e,t,r){switch(t){case-1:return;case-2:e.report(r?2:1);case-3:e.report(r?3:14);case-4:e.report(7);case-5:e.report(104)}}function P(e,t){const{index:r}=e;let n=67174409,o="",a=c(e);for(;96!==a;){if(36===a&&123===e.source.charCodeAt(e.index+1)){c(e),n=67174408;break}if(92===a)if(a=c(e),a>126)o+=String.fromCodePoint(a);else{const{index:r,line:i,column:s}=e,c=B(e,1|t,a,1);if(c>=0)o+=String.fromCodePoint(c);else{if(-1!==c&&64&t){e.index=r,e.line=i,e.column=s,o=null,a=O(e,a),a<0&&(n=67174408);break}U(e,c,1)}}else e.index<e.end&&(13===a&&10===e.source.charCodeAt(e.index)&&(o+=String.fromCodePoint(a),e.currentChar=e.source.charCodeAt(++e.index)),((83&a)<3&&10===a||(8232^a)<=1)&&(e.column=-1,e.line++),o+=String.fromCodePoint(a));e.index>=e.end&&e.report(17),a=c(e)}return c(e),e.tokenValue=o,e.tokenRaw=e.source.slice(r+1,e.index-(67174409===n?1:2)),n}function O(e,t){for(;96!==t;){switch(t){case 36:{const r=e.index+1;if(r<e.end&&123===e.source.charCodeAt(r))return e.index=r,e.column++,-t;break}case 10:case 8232:case 8233:e.column=-1,e.line++}e.index>=e.end&&e.report(17),t=c(e)}return t}function G(e,t){return e.index>=e.end&&e.report(0),e.index--,e.column--,P(e,t)}!function(e){e[e.Empty=0]="Empty",e[e.Escape=1]="Escape",e[e.Class=2]="Class"}(I||(I={})),function(e){e[e.Empty=0]="Empty",e[e.IgnoreCase=1]="IgnoreCase",e[e.Global=2]="Global",e[e.Multiline=4]="Multiline",e[e.Unicode=16]="Unicode",e[e.Sticky=8]="Sticky",e[e.DotAll=32]="DotAll",e[e.Indices=64]="Indices",e[e.UnicodeSets=128]="UnicodeSets"}(V||(V={}));const j=[128,128,128,128,128,128,128,128,128,127,135,127,127,129,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,127,16842798,134283267,130,208897,8391477,8390213,134283267,67174411,16,8391476,25233968,18,25233969,67108877,8457014,134283266,134283266,134283266,134283266,134283266,134283266,134283266,134283266,134283266,134283266,21,1074790417,8456256,1077936155,8390721,22,132,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,208897,69271571,136,20,8389959,208897,131,4096,4096,4096,4096,4096,4096,4096,208897,4096,208897,208897,4096,208897,4096,208897,4096,208897,4096,4096,4096,208897,4096,4096,208897,4096,4096,2162700,8389702,1074790415,16842799,128];function F(e,t){e.flags=1^(1|e.flags),e.startIndex=e.index,e.startColumn=e.column,e.startLine=e.line,e.setToken(M(e,t,0))}function M(e,t,n){const o=0===e.index,{source:a}=e;for(;e.index<e.end;){e.tokenIndex=e.index,e.tokenColumn=e.column,e.tokenLine=e.line;let i=e.currentChar;if(i<=126){const r=j[i];switch(r){case 67174411:case 16:case 2162700:case 1074790415:case 69271571:case 20:case 21:case 1074790417:case 18:case 16842799:case 132:case 128:return c(e),r;case 208897:return v(e,t,0);case 4096:return v(e,t,1);case 134283266:return L(e,t,144);case 134283267:return R(e,t,i);case 131:return P(e,t);case 136:return C(e,t);case 130:return E(e);case 127:c(e);break;case 129:n|=5,p(e);break;case 135:u(e,n),n=-5&n|1;break;case 8456256:{const r=c(e);if(e.index<e.end){if(60===r)return e.index<e.end&&61===c(e)?(c(e),4194332):8390978;if(61===r)return c(e),8390718;if(33===r){const r=e.index+1;if(r+1<e.end&&45===a.charCodeAt(r)&&45==a.charCodeAt(r+1)){e.column+=3,e.currentChar=a.charCodeAt(e.index+=3),n=h(e,a,n,t,2,e.tokenStart);continue}return 8456256}}return 8456256}case 1077936155:{c(e);const t=e.currentChar;return 61===t?61===c(e)?(c(e),8390458):8390460:62===t?(c(e),10):1077936155}case 16842798:return 61!==c(e)?16842798:61!==c(e)?8390461:(c(e),8390459);case 8391477:return 61!==c(e)?8391477:(c(e),4194340);case 8391476:{if(c(e),e.index>=e.end)return 8391476;const t=e.currentChar;return 61===t?(c(e),4194338):42!==t?8391476:61!==c(e)?8391735:(c(e),4194335)}case 8389959:return 61!==c(e)?8389959:(c(e),4194341);case 25233968:{c(e);const t=e.currentChar;return 43===t?(c(e),33619993):61===t?(c(e),4194336):25233968}case 25233969:{c(e);const r=e.currentChar;if(45===r){if(c(e),(1&n||o)&&62===e.currentChar){e.options.webcompat||e.report(112),c(e),n=h(e,a,n,t,3,e.tokenStart);continue}return 33619994}return 61===r?(c(e),4194337):25233969}case 8457014:if(c(e),e.index<e.end){const r=e.currentChar;if(47===r){c(e),n=m(e,a,n,0,e.tokenStart);continue}if(42===r){c(e),n=b(e,a,n);continue}if(32&t)return D(e);if(61===r)return c(e),4259875}return 8457014;case 67108877:{const r=c(e);if(r>=48&&r<=57)return L(e,t,80);if(46===r){const t=e.index+1;if(t<e.end&&46===a.charCodeAt(t))return e.column+=2,e.currentChar=a.charCodeAt(e.index+=2),14}return 67108877}case 8389702:{c(e);const t=e.currentChar;return 124===t?(c(e),61===e.currentChar?(c(e),4718632):8913465):61===t?(c(e),4194342):8389702}case 8390721:{c(e);const t=e.currentChar;if(61===t)return c(e),8390719;if(62!==t)return 8390721;if(c(e),e.index<e.end){const t=e.currentChar;if(62===t)return 61===c(e)?(c(e),4194334):8390980;if(61===t)return c(e),4194333}return 8390979}case 8390213:{c(e);const t=e.currentChar;return 38===t?(c(e),61===e.currentChar?(c(e),4718633):8913720):61===t?(c(e),4194343):8390213}case 22:{let t=c(e);if(63===t)return c(e),61===e.currentChar?(c(e),4718634):276824445;if(46===t){const r=e.index+1;if(r<e.end&&(t=a.charCodeAt(r),!(t>=48&&t<=57)))return c(e),67108990}return 22}}}else{if((8232^i)<=1){n=-5&n|1,p(e);continue}const o=l(e);if(o>0&&(i=o),r(i))return e.tokenValue="",q(e,t,0,0);if(d(i)){c(e);continue}e.report(20,String.fromCodePoint(i))}}return 1048576}function H(e,t){!(1&e.flags)&&1048576&~e.getToken()&&e.report(30,w[255&e.getToken()]),X(e,t,1074790417)||e.options.onInsertedSemicolon?.(e.startIndex)}function J(e,t,r,n){return t-r<13&&"use strict"===n&&(!(1048576&~e.getToken())||1&e.flags)?1:0}function z(e,t,r){return e.getToken()!==r?0:(F(e,t),1)}function X(e,t,r){return e.getToken()===r&&(F(e,t),!0)}function _(e,t,r){e.getToken()!==r&&e.report(25,w[255&r]),F(e,t)}function $(e,t){switch(t.type){case"ArrayExpression":{t.type="ArrayPattern";const{elements:r}=t;for(let t=0,n=r.length;t<n;++t){const n=r[t];n&&$(e,n)}return}case"ObjectExpression":{t.type="ObjectPattern";const{properties:r}=t;for(let t=0,n=r.length;t<n;++t)$(e,r[t]);return}case"AssignmentExpression":return t.type="AssignmentPattern","="!==t.operator&&e.report(71),delete t.operator,void $(e,t.left);case"Property":return void $(e,t.value);case"SpreadElement":t.type="RestElement",$(e,t.argument)}}function Y(e,t,r,n,o){1&t&&(36864&~n||e.report(118),o||537079808&~n||e.report(119)),20480&~n&&-2147483528!==n||e.report(102),24&r&&73==(255&n)&&e.report(100),2050&t&&209006===n&&e.report(110),1025&t&&241771===n&&e.report(97,"yield")}function W(e,t,r){1&t&&(36864&~r||e.report(118),537079808&~r||e.report(119),-2147483527===r&&e.report(95),-2147483528===r&&e.report(95)),20480&~r||e.report(102),2050&t&&209006===r&&e.report(110),1025&t&&241771===r&&e.report(97,"yield")}function Z(e,t,r){return 209006===r&&(2050&t&&e.report(110),e.destructible|=128),241771===r&&1024&t&&e.report(97,"yield"),!(20480&~r&&36864&~r&&-2147483527!=r)}function K(e,t,r,n){for(;t;){if(t["$"+r])return n&&e.report(137),1;n&&t.loop&&(n=0),t=t.$}return 0}function Q(e){switch(e.type){case"JSXIdentifier":return e.name;case"JSXNamespacedName":return e.namespace+":"+e.name;case"JSXMemberExpression":return Q(e.object)+"."+Q(e.property)}}function ee(e,t){return 1025&e?!(2&e&&209006===t)&&(!(1024&e&&241771===t)&&!(12288&~t)):!(12288&~t&&36864&~t)}function te(e,t,r){537079808&~r||(1&t&&e.report(119),e.flags|=512),ee(t,r)||e.report(0)}const re={AElig:"Æ",AMP:"&",Aacute:"Á",Abreve:"Ă",Acirc:"Â",Acy:"А",Afr:"𝔄",Agrave:"À",Alpha:"Α",Amacr:"Ā",And:"⩓",Aogon:"Ą",Aopf:"𝔸",ApplyFunction:"⁡",Aring:"Å",Ascr:"𝒜",Assign:"≔",Atilde:"Ã",Auml:"Ä",Backslash:"∖",Barv:"⫧",Barwed:"⌆",Bcy:"Б",Because:"∵",Bernoullis:"ℬ",Beta:"Β",Bfr:"𝔅",Bopf:"𝔹",Breve:"˘",Bscr:"ℬ",Bumpeq:"≎",CHcy:"Ч",COPY:"©",Cacute:"Ć",Cap:"⋒",CapitalDifferentialD:"ⅅ",Cayleys:"ℭ",Ccaron:"Č",Ccedil:"Ç",Ccirc:"Ĉ",Cconint:"∰",Cdot:"Ċ",Cedilla:"¸",CenterDot:"·",Cfr:"ℭ",Chi:"Χ",CircleDot:"⊙",CircleMinus:"⊖",CirclePlus:"⊕",CircleTimes:"⊗",ClockwiseContourIntegral:"∲",CloseCurlyDoubleQuote:"”",CloseCurlyQuote:"’",Colon:"∷",Colone:"⩴",Congruent:"≡",Conint:"∯",ContourIntegral:"∮",Copf:"ℂ",Coproduct:"∐",CounterClockwiseContourIntegral:"∳",Cross:"⨯",Cscr:"𝒞",Cup:"⋓",CupCap:"≍",DD:"ⅅ",DDotrahd:"⤑",DJcy:"Ђ",DScy:"Ѕ",DZcy:"Џ",Dagger:"‡",Darr:"↡",Dashv:"⫤",Dcaron:"Ď",Dcy:"Д",Del:"∇",Delta:"Δ",Dfr:"𝔇",DiacriticalAcute:"´",DiacriticalDot:"˙",DiacriticalDoubleAcute:"˝",DiacriticalGrave:"`",DiacriticalTilde:"˜",Diamond:"⋄",DifferentialD:"ⅆ",Dopf:"𝔻",Dot:"¨",DotDot:"⃜",DotEqual:"≐",DoubleContourIntegral:"∯",DoubleDot:"¨",DoubleDownArrow:"⇓",DoubleLeftArrow:"⇐",DoubleLeftRightArrow:"⇔",DoubleLeftTee:"⫤",DoubleLongLeftArrow:"⟸",DoubleLongLeftRightArrow:"⟺",DoubleLongRightArrow:"⟹",DoubleRightArrow:"⇒",DoubleRightTee:"⊨",DoubleUpArrow:"⇑",DoubleUpDownArrow:"⇕",DoubleVerticalBar:"∥",DownArrow:"↓",DownArrowBar:"⤓",DownArrowUpArrow:"⇵",DownBreve:"̑",DownLeftRightVector:"⥐",DownLeftTeeVector:"⥞",DownLeftVector:"↽",DownLeftVectorBar:"⥖",DownRightTeeVector:"⥟",DownRightVector:"⇁",DownRightVectorBar:"⥗",DownTee:"⊤",DownTeeArrow:"↧",Downarrow:"⇓",Dscr:"𝒟",Dstrok:"Đ",ENG:"Ŋ",ETH:"Ð",Eacute:"É",Ecaron:"Ě",Ecirc:"Ê",Ecy:"Э",Edot:"Ė",Efr:"𝔈",Egrave:"È",Element:"∈",Emacr:"Ē",EmptySmallSquare:"◻",EmptyVerySmallSquare:"▫",Eogon:"Ę",Eopf:"𝔼",Epsilon:"Ε",Equal:"⩵",EqualTilde:"≂",Equilibrium:"⇌",Escr:"ℰ",Esim:"⩳",Eta:"Η",Euml:"Ë",Exists:"∃",ExponentialE:"ⅇ",Fcy:"Ф",Ffr:"𝔉",FilledSmallSquare:"◼",FilledVerySmallSquare:"▪",Fopf:"𝔽",ForAll:"∀",Fouriertrf:"ℱ",Fscr:"ℱ",GJcy:"Ѓ",GT:">",Gamma:"Γ",Gammad:"Ϝ",Gbreve:"Ğ",Gcedil:"Ģ",Gcirc:"Ĝ",Gcy:"Г",Gdot:"Ġ",Gfr:"𝔊",Gg:"⋙",Gopf:"𝔾",GreaterEqual:"≥",GreaterEqualLess:"⋛",GreaterFullEqual:"≧",GreaterGreater:"⪢",GreaterLess:"≷",GreaterSlantEqual:"⩾",GreaterTilde:"≳",Gscr:"𝒢",Gt:"≫",HARDcy:"Ъ",Hacek:"ˇ",Hat:"^",Hcirc:"Ĥ",Hfr:"ℌ",HilbertSpace:"ℋ",Hopf:"ℍ",HorizontalLine:"─",Hscr:"ℋ",Hstrok:"Ħ",HumpDownHump:"≎",HumpEqual:"≏",IEcy:"Е",IJlig:"Ĳ",IOcy:"Ё",Iacute:"Í",Icirc:"Î",Icy:"И",Idot:"İ",Ifr:"ℑ",Igrave:"Ì",Im:"ℑ",Imacr:"Ī",ImaginaryI:"ⅈ",Implies:"⇒",Int:"∬",Integral:"∫",Intersection:"⋂",InvisibleComma:"⁣",InvisibleTimes:"⁢",Iogon:"Į",Iopf:"𝕀",Iota:"Ι",Iscr:"ℐ",Itilde:"Ĩ",Iukcy:"І",Iuml:"Ï",Jcirc:"Ĵ",Jcy:"Й",Jfr:"𝔍",Jopf:"𝕁",Jscr:"𝒥",Jsercy:"Ј",Jukcy:"Є",KHcy:"Х",KJcy:"Ќ",Kappa:"Κ",Kcedil:"Ķ",Kcy:"К",Kfr:"𝔎",Kopf:"𝕂",Kscr:"𝒦",LJcy:"Љ",LT:"<",Lacute:"Ĺ",Lambda:"Λ",Lang:"⟪",Laplacetrf:"ℒ",Larr:"↞",Lcaron:"Ľ",Lcedil:"Ļ",Lcy:"Л",LeftAngleBracket:"⟨",LeftArrow:"←",LeftArrowBar:"⇤",LeftArrowRightArrow:"⇆",LeftCeiling:"⌈",LeftDoubleBracket:"⟦",LeftDownTeeVector:"⥡",LeftDownVector:"⇃",LeftDownVectorBar:"⥙",LeftFloor:"⌊",LeftRightArrow:"↔",LeftRightVector:"⥎",LeftTee:"⊣",LeftTeeArrow:"↤",LeftTeeVector:"⥚",LeftTriangle:"⊲",LeftTriangleBar:"⧏",LeftTriangleEqual:"⊴",LeftUpDownVector:"⥑",LeftUpTeeVector:"⥠",LeftUpVector:"↿",LeftUpVectorBar:"⥘",LeftVector:"↼",LeftVectorBar:"⥒",Leftarrow:"⇐",Leftrightarrow:"⇔",LessEqualGreater:"⋚",LessFullEqual:"≦",LessGreater:"≶",LessLess:"⪡",LessSlantEqual:"⩽",LessTilde:"≲",Lfr:"𝔏",Ll:"⋘",Lleftarrow:"⇚",Lmidot:"Ŀ",LongLeftArrow:"⟵",LongLeftRightArrow:"⟷",LongRightArrow:"⟶",Longleftarrow:"⟸",Longleftrightarrow:"⟺",Longrightarrow:"⟹",Lopf:"𝕃",LowerLeftArrow:"↙",LowerRightArrow:"↘",Lscr:"ℒ",Lsh:"↰",Lstrok:"Ł",Lt:"≪",Map:"⤅",Mcy:"М",MediumSpace:" ",Mellintrf:"ℳ",Mfr:"𝔐",MinusPlus:"∓",Mopf:"𝕄",Mscr:"ℳ",Mu:"Μ",NJcy:"Њ",Nacute:"Ń",Ncaron:"Ň",Ncedil:"Ņ",Ncy:"Н",NegativeMediumSpace:"​",NegativeThickSpace:"​",NegativeThinSpace:"​",NegativeVeryThinSpace:"​",NestedGreaterGreater:"≫",NestedLessLess:"≪",NewLine:"\n",Nfr:"𝔑",NoBreak:"⁠",NonBreakingSpace:" ",Nopf:"ℕ",Not:"⫬",NotCongruent:"≢",NotCupCap:"≭",NotDoubleVerticalBar:"∦",NotElement:"∉",NotEqual:"≠",NotEqualTilde:"≂̸",NotExists:"∄",NotGreater:"≯",NotGreaterEqual:"≱",NotGreaterFullEqual:"≧̸",NotGreaterGreater:"≫̸",NotGreaterLess:"≹",NotGreaterSlantEqual:"⩾̸",NotGreaterTilde:"≵",NotHumpDownHump:"≎̸",NotHumpEqual:"≏̸",NotLeftTriangle:"⋪",NotLeftTriangleBar:"⧏̸",NotLeftTriangleEqual:"⋬",NotLess:"≮",NotLessEqual:"≰",NotLessGreater:"≸",NotLessLess:"≪̸",NotLessSlantEqual:"⩽̸",NotLessTilde:"≴",NotNestedGreaterGreater:"⪢̸",NotNestedLessLess:"⪡̸",NotPrecedes:"⊀",NotPrecedesEqual:"⪯̸",NotPrecedesSlantEqual:"⋠",NotReverseElement:"∌",NotRightTriangle:"⋫",NotRightTriangleBar:"⧐̸",NotRightTriangleEqual:"⋭",NotSquareSubset:"⊏̸",NotSquareSubsetEqual:"⋢",NotSquareSuperset:"⊐̸",NotSquareSupersetEqual:"⋣",NotSubset:"⊂⃒",NotSubsetEqual:"⊈",NotSucceeds:"⊁",NotSucceedsEqual:"⪰̸",NotSucceedsSlantEqual:"⋡",NotSucceedsTilde:"≿̸",NotSuperset:"⊃⃒",NotSupersetEqual:"⊉",NotTilde:"≁",NotTildeEqual:"≄",NotTildeFullEqual:"≇",NotTildeTilde:"≉",NotVerticalBar:"∤",Nscr:"𝒩",Ntilde:"Ñ",Nu:"Ν",OElig:"Œ",Oacute:"Ó",Ocirc:"Ô",Ocy:"О",Odblac:"Ő",Ofr:"𝔒",Ograve:"Ò",Omacr:"Ō",Omega:"Ω",Omicron:"Ο",Oopf:"𝕆",OpenCurlyDoubleQuote:"“",OpenCurlyQuote:"‘",Or:"⩔",Oscr:"𝒪",Oslash:"Ø",Otilde:"Õ",Otimes:"⨷",Ouml:"Ö",OverBar:"‾",OverBrace:"⏞",OverBracket:"⎴",OverParenthesis:"⏜",PartialD:"∂",Pcy:"П",Pfr:"𝔓",Phi:"Φ",Pi:"Π",PlusMinus:"±",Poincareplane:"ℌ",Popf:"ℙ",Pr:"⪻",Precedes:"≺",PrecedesEqual:"⪯",PrecedesSlantEqual:"≼",PrecedesTilde:"≾",Prime:"″",Product:"∏",Proportion:"∷",Proportional:"∝",Pscr:"𝒫",Psi:"Ψ",QUOT:'"',Qfr:"𝔔",Qopf:"ℚ",Qscr:"𝒬",RBarr:"⤐",REG:"®",Racute:"Ŕ",Rang:"⟫",Rarr:"↠",Rarrtl:"⤖",Rcaron:"Ř",Rcedil:"Ŗ",Rcy:"Р",Re:"ℜ",ReverseElement:"∋",ReverseEquilibrium:"⇋",ReverseUpEquilibrium:"⥯",Rfr:"ℜ",Rho:"Ρ",RightAngleBracket:"⟩",RightArrow:"→",RightArrowBar:"⇥",RightArrowLeftArrow:"⇄",RightCeiling:"⌉",RightDoubleBracket:"⟧",RightDownTeeVector:"⥝",RightDownVector:"⇂",RightDownVectorBar:"⥕",RightFloor:"⌋",RightTee:"⊢",RightTeeArrow:"↦",RightTeeVector:"⥛",RightTriangle:"⊳",RightTriangleBar:"⧐",RightTriangleEqual:"⊵",RightUpDownVector:"⥏",RightUpTeeVector:"⥜",RightUpVector:"↾",RightUpVectorBar:"⥔",RightVector:"⇀",RightVectorBar:"⥓",Rightarrow:"⇒",Ropf:"ℝ",RoundImplies:"⥰",Rrightarrow:"⇛",Rscr:"ℛ",Rsh:"↱",RuleDelayed:"⧴",SHCHcy:"Щ",SHcy:"Ш",SOFTcy:"Ь",Sacute:"Ś",Sc:"⪼",Scaron:"Š",Scedil:"Ş",Scirc:"Ŝ",Scy:"С",Sfr:"𝔖",ShortDownArrow:"↓",ShortLeftArrow:"←",ShortRightArrow:"→",ShortUpArrow:"↑",Sigma:"Σ",SmallCircle:"∘",Sopf:"𝕊",Sqrt:"√",Square:"□",SquareIntersection:"⊓",SquareSubset:"⊏",SquareSubsetEqual:"⊑",SquareSuperset:"⊐",SquareSupersetEqual:"⊒",SquareUnion:"⊔",Sscr:"𝒮",Star:"⋆",Sub:"⋐",Subset:"⋐",SubsetEqual:"⊆",Succeeds:"≻",SucceedsEqual:"⪰",SucceedsSlantEqual:"≽",SucceedsTilde:"≿",SuchThat:"∋",Sum:"∑",Sup:"⋑",Superset:"⊃",SupersetEqual:"⊇",Supset:"⋑",THORN:"Þ",TRADE:"™",TSHcy:"Ћ",TScy:"Ц",Tab:"\t",Tau:"Τ",Tcaron:"Ť",Tcedil:"Ţ",Tcy:"Т",Tfr:"𝔗",Therefore:"∴",Theta:"Θ",ThickSpace:"  ",ThinSpace:" ",Tilde:"∼",TildeEqual:"≃",TildeFullEqual:"≅",TildeTilde:"≈",Topf:"𝕋",TripleDot:"⃛",Tscr:"𝒯",Tstrok:"Ŧ",Uacute:"Ú",Uarr:"↟",Uarrocir:"⥉",Ubrcy:"Ў",Ubreve:"Ŭ",Ucirc:"Û",Ucy:"У",Udblac:"Ű",Ufr:"𝔘",Ugrave:"Ù",Umacr:"Ū",UnderBar:"_",UnderBrace:"⏟",UnderBracket:"⎵",UnderParenthesis:"⏝",Union:"⋃",UnionPlus:"⊎",Uogon:"Ų",Uopf:"𝕌",UpArrow:"↑",UpArrowBar:"⤒",UpArrowDownArrow:"⇅",UpDownArrow:"↕",UpEquilibrium:"⥮",UpTee:"⊥",UpTeeArrow:"↥",Uparrow:"⇑",Updownarrow:"⇕",UpperLeftArrow:"↖",UpperRightArrow:"↗",Upsi:"ϒ",Upsilon:"Υ",Uring:"Ů",Uscr:"𝒰",Utilde:"Ũ",Uuml:"Ü",VDash:"⊫",Vbar:"⫫",Vcy:"В",Vdash:"⊩",Vdashl:"⫦",Vee:"⋁",Verbar:"‖",Vert:"‖",VerticalBar:"∣",VerticalLine:"|",VerticalSeparator:"❘",VerticalTilde:"≀",VeryThinSpace:" ",Vfr:"𝔙",Vopf:"𝕍",Vscr:"𝒱",Vvdash:"⊪",Wcirc:"Ŵ",Wedge:"⋀",Wfr:"𝔚",Wopf:"𝕎",Wscr:"𝒲",Xfr:"𝔛",Xi:"Ξ",Xopf:"𝕏",Xscr:"𝒳",YAcy:"Я",YIcy:"Ї",YUcy:"Ю",Yacute:"Ý",Ycirc:"Ŷ",Ycy:"Ы",Yfr:"𝔜",Yopf:"𝕐",Yscr:"𝒴",Yuml:"Ÿ",ZHcy:"Ж",Zacute:"Ź",Zcaron:"Ž",Zcy:"З",Zdot:"Ż",ZeroWidthSpace:"​",Zeta:"Ζ",Zfr:"ℨ",Zopf:"ℤ",Zscr:"𝒵",aacute:"á",abreve:"ă",ac:"∾",acE:"∾̳",acd:"∿",acirc:"â",acute:"´",acy:"а",aelig:"æ",af:"⁡",afr:"𝔞",agrave:"à",alefsym:"ℵ",aleph:"ℵ",alpha:"α",amacr:"ā",amalg:"⨿",amp:"&",and:"∧",andand:"⩕",andd:"⩜",andslope:"⩘",andv:"⩚",ang:"∠",ange:"⦤",angle:"∠",angmsd:"∡",angmsdaa:"⦨",angmsdab:"⦩",angmsdac:"⦪",angmsdad:"⦫",angmsdae:"⦬",angmsdaf:"⦭",angmsdag:"⦮",angmsdah:"⦯",angrt:"∟",angrtvb:"⊾",angrtvbd:"⦝",angsph:"∢",angst:"Å",angzarr:"⍼",aogon:"ą",aopf:"𝕒",ap:"≈",apE:"⩰",apacir:"⩯",ape:"≊",apid:"≋",apos:"'",approx:"≈",approxeq:"≊",aring:"å",ascr:"𝒶",ast:"*",asymp:"≈",asympeq:"≍",atilde:"ã",auml:"ä",awconint:"∳",awint:"⨑",bNot:"⫭",backcong:"≌",backepsilon:"϶",backprime:"‵",backsim:"∽",backsimeq:"⋍",barvee:"⊽",barwed:"⌅",barwedge:"⌅",bbrk:"⎵",bbrktbrk:"⎶",bcong:"≌",bcy:"б",bdquo:"„",becaus:"∵",because:"∵",bemptyv:"⦰",bepsi:"϶",bernou:"ℬ",beta:"β",beth:"ℶ",between:"≬",bfr:"𝔟",bigcap:"⋂",bigcirc:"◯",bigcup:"⋃",bigodot:"⨀",bigoplus:"⨁",bigotimes:"⨂",bigsqcup:"⨆",bigstar:"★",bigtriangledown:"▽",bigtriangleup:"△",biguplus:"⨄",bigvee:"⋁",bigwedge:"⋀",bkarow:"⤍",blacklozenge:"⧫",blacksquare:"▪",blacktriangle:"▴",blacktriangledown:"▾",blacktriangleleft:"◂",blacktriangleright:"▸",blank:"␣",blk12:"▒",blk14:"░",blk34:"▓",block:"█",bne:"=⃥",bnequiv:"≡⃥",bnot:"⌐",bopf:"𝕓",bot:"⊥",bottom:"⊥",bowtie:"⋈",boxDL:"╗",boxDR:"╔",boxDl:"╖",boxDr:"╓",boxH:"═",boxHD:"╦",boxHU:"╩",boxHd:"╤",boxHu:"╧",boxUL:"╝",boxUR:"╚",boxUl:"╜",boxUr:"╙",boxV:"║",boxVH:"╬",boxVL:"╣",boxVR:"╠",boxVh:"╫",boxVl:"╢",boxVr:"╟",boxbox:"⧉",boxdL:"╕",boxdR:"╒",boxdl:"┐",boxdr:"┌",boxh:"─",boxhD:"╥",boxhU:"╨",boxhd:"┬",boxhu:"┴",boxminus:"⊟",boxplus:"⊞",boxtimes:"⊠",boxuL:"╛",boxuR:"╘",boxul:"┘",boxur:"└",boxv:"│",boxvH:"╪",boxvL:"╡",boxvR:"╞",boxvh:"┼",boxvl:"┤",boxvr:"├",bprime:"‵",breve:"˘",brvbar:"¦",bscr:"𝒷",bsemi:"⁏",bsim:"∽",bsime:"⋍",bsol:"\\",bsolb:"⧅",bsolhsub:"⟈",bull:"•",bullet:"•",bump:"≎",bumpE:"⪮",bumpe:"≏",bumpeq:"≏",cacute:"ć",cap:"∩",capand:"⩄",capbrcup:"⩉",capcap:"⩋",capcup:"⩇",capdot:"⩀",caps:"∩︀",caret:"⁁",caron:"ˇ",ccaps:"⩍",ccaron:"č",ccedil:"ç",ccirc:"ĉ",ccups:"⩌",ccupssm:"⩐",cdot:"ċ",cedil:"¸",cemptyv:"⦲",cent:"¢",centerdot:"·",cfr:"𝔠",chcy:"ч",check:"✓",checkmark:"✓",chi:"χ",cir:"○",cirE:"⧃",circ:"ˆ",circeq:"≗",circlearrowleft:"↺",circlearrowright:"↻",circledR:"®",circledS:"Ⓢ",circledast:"⊛",circledcirc:"⊚",circleddash:"⊝",cire:"≗",cirfnint:"⨐",cirmid:"⫯",cirscir:"⧂",clubs:"♣",clubsuit:"♣",colon:":",colone:"≔",coloneq:"≔",comma:",",commat:"@",comp:"∁",compfn:"∘",complement:"∁",complexes:"ℂ",cong:"≅",congdot:"⩭",conint:"∮",copf:"𝕔",coprod:"∐",copy:"©",copysr:"℗",crarr:"↵",cross:"✗",cscr:"𝒸",csub:"⫏",csube:"⫑",csup:"⫐",csupe:"⫒",ctdot:"⋯",cudarrl:"⤸",cudarrr:"⤵",cuepr:"⋞",cuesc:"⋟",cularr:"↶",cularrp:"⤽",cup:"∪",cupbrcap:"⩈",cupcap:"⩆",cupcup:"⩊",cupdot:"⊍",cupor:"⩅",cups:"∪︀",curarr:"↷",curarrm:"⤼",curlyeqprec:"⋞",curlyeqsucc:"⋟",curlyvee:"⋎",curlywedge:"⋏",curren:"¤",curvearrowleft:"↶",curvearrowright:"↷",cuvee:"⋎",cuwed:"⋏",cwconint:"∲",cwint:"∱",cylcty:"⌭",dArr:"⇓",dHar:"⥥",dagger:"†",daleth:"ℸ",darr:"↓",dash:"‐",dashv:"⊣",dbkarow:"⤏",dblac:"˝",dcaron:"ď",dcy:"д",dd:"ⅆ",ddagger:"‡",ddarr:"⇊",ddotseq:"⩷",deg:"°",delta:"δ",demptyv:"⦱",dfisht:"⥿",dfr:"𝔡",dharl:"⇃",dharr:"⇂",diam:"⋄",diamond:"⋄",diamondsuit:"♦",diams:"♦",die:"¨",digamma:"ϝ",disin:"⋲",div:"÷",divide:"÷",divideontimes:"⋇",divonx:"⋇",djcy:"ђ",dlcorn:"⌞",dlcrop:"⌍",dollar:"$",dopf:"𝕕",dot:"˙",doteq:"≐",doteqdot:"≑",dotminus:"∸",dotplus:"∔",dotsquare:"⊡",doublebarwedge:"⌆",downarrow:"↓",downdownarrows:"⇊",downharpoonleft:"⇃",downharpoonright:"⇂",drbkarow:"⤐",drcorn:"⌟",drcrop:"⌌",dscr:"𝒹",dscy:"ѕ",dsol:"⧶",dstrok:"đ",dtdot:"⋱",dtri:"▿",dtrif:"▾",duarr:"⇵",duhar:"⥯",dwangle:"⦦",dzcy:"џ",dzigrarr:"⟿",eDDot:"⩷",eDot:"≑",eacute:"é",easter:"⩮",ecaron:"ě",ecir:"≖",ecirc:"ê",ecolon:"≕",ecy:"э",edot:"ė",ee:"ⅇ",efDot:"≒",efr:"𝔢",eg:"⪚",egrave:"è",egs:"⪖",egsdot:"⪘",el:"⪙",elinters:"⏧",ell:"ℓ",els:"⪕",elsdot:"⪗",emacr:"ē",empty:"∅",emptyset:"∅",emptyv:"∅",emsp13:" ",emsp14:" ",emsp:" ",eng:"ŋ",ensp:" ",eogon:"ę",eopf:"𝕖",epar:"⋕",eparsl:"⧣",eplus:"⩱",epsi:"ε",epsilon:"ε",epsiv:"ϵ",eqcirc:"≖",eqcolon:"≕",eqsim:"≂",eqslantgtr:"⪖",eqslantless:"⪕",equals:"=",equest:"≟",equiv:"≡",equivDD:"⩸",eqvparsl:"⧥",erDot:"≓",erarr:"⥱",escr:"ℯ",esdot:"≐",esim:"≂",eta:"η",eth:"ð",euml:"ë",euro:"€",excl:"!",exist:"∃",expectation:"ℰ",exponentiale:"ⅇ",fallingdotseq:"≒",fcy:"ф",female:"♀",ffilig:"ﬃ",fflig:"ﬀ",ffllig:"ﬄ",ffr:"𝔣",filig:"ﬁ",fjlig:"fj",flat:"♭",fllig:"ﬂ",fltns:"▱",fnof:"ƒ",fopf:"𝕗",forall:"∀",fork:"⋔",forkv:"⫙",fpartint:"⨍",frac12:"½",frac13:"⅓",frac14:"¼",frac15:"⅕",frac16:"⅙",frac18:"⅛",frac23:"⅔",frac25:"⅖",frac34:"¾",frac35:"⅗",frac38:"⅜",frac45:"⅘",frac56:"⅚",frac58:"⅝",frac78:"⅞",frasl:"⁄",frown:"⌢",fscr:"𝒻",gE:"≧",gEl:"⪌",gacute:"ǵ",gamma:"γ",gammad:"ϝ",gap:"⪆",gbreve:"ğ",gcirc:"ĝ",gcy:"г",gdot:"ġ",ge:"≥",gel:"⋛",geq:"≥",geqq:"≧",geqslant:"⩾",ges:"⩾",gescc:"⪩",gesdot:"⪀",gesdoto:"⪂",gesdotol:"⪄",gesl:"⋛︀",gesles:"⪔",gfr:"𝔤",gg:"≫",ggg:"⋙",gimel:"ℷ",gjcy:"ѓ",gl:"≷",glE:"⪒",gla:"⪥",glj:"⪤",gnE:"≩",gnap:"⪊",gnapprox:"⪊",gne:"⪈",gneq:"⪈",gneqq:"≩",gnsim:"⋧",gopf:"𝕘",grave:"`",gscr:"ℊ",gsim:"≳",gsime:"⪎",gsiml:"⪐",gt:">",gtcc:"⪧",gtcir:"⩺",gtdot:"⋗",gtlPar:"⦕",gtquest:"⩼",gtrapprox:"⪆",gtrarr:"⥸",gtrdot:"⋗",gtreqless:"⋛",gtreqqless:"⪌",gtrless:"≷",gtrsim:"≳",gvertneqq:"≩︀",gvnE:"≩︀",hArr:"⇔",hairsp:" ",half:"½",hamilt:"ℋ",hardcy:"ъ",harr:"↔",harrcir:"⥈",harrw:"↭",hbar:"ℏ",hcirc:"ĥ",hearts:"♥",heartsuit:"♥",hellip:"…",hercon:"⊹",hfr:"𝔥",hksearow:"⤥",hkswarow:"⤦",hoarr:"⇿",homtht:"∻",hookleftarrow:"↩",hookrightarrow:"↪",hopf:"𝕙",horbar:"―",hscr:"𝒽",hslash:"ℏ",hstrok:"ħ",hybull:"⁃",hyphen:"‐",iacute:"í",ic:"⁣",icirc:"î",icy:"и",iecy:"е",iexcl:"¡",iff:"⇔",ifr:"𝔦",igrave:"ì",ii:"ⅈ",iiiint:"⨌",iiint:"∭",iinfin:"⧜",iiota:"℩",ijlig:"ĳ",imacr:"ī",image:"ℑ",imagline:"ℐ",imagpart:"ℑ",imath:"ı",imof:"⊷",imped:"Ƶ",in:"∈",incare:"℅",infin:"∞",infintie:"⧝",inodot:"ı",int:"∫",intcal:"⊺",integers:"ℤ",intercal:"⊺",intlarhk:"⨗",intprod:"⨼",iocy:"ё",iogon:"į",iopf:"𝕚",iota:"ι",iprod:"⨼",iquest:"¿",iscr:"𝒾",isin:"∈",isinE:"⋹",isindot:"⋵",isins:"⋴",isinsv:"⋳",isinv:"∈",it:"⁢",itilde:"ĩ",iukcy:"і",iuml:"ï",jcirc:"ĵ",jcy:"й",jfr:"𝔧",jmath:"ȷ",jopf:"𝕛",jscr:"𝒿",jsercy:"ј",jukcy:"є",kappa:"κ",kappav:"ϰ",kcedil:"ķ",kcy:"к",kfr:"𝔨",kgreen:"ĸ",khcy:"х",kjcy:"ќ",kopf:"𝕜",kscr:"𝓀",lAarr:"⇚",lArr:"⇐",lAtail:"⤛",lBarr:"⤎",lE:"≦",lEg:"⪋",lHar:"⥢",lacute:"ĺ",laemptyv:"⦴",lagran:"ℒ",lambda:"λ",lang:"⟨",langd:"⦑",langle:"⟨",lap:"⪅",laquo:"«",larr:"←",larrb:"⇤",larrbfs:"⤟",larrfs:"⤝",larrhk:"↩",larrlp:"↫",larrpl:"⤹",larrsim:"⥳",larrtl:"↢",lat:"⪫",latail:"⤙",late:"⪭",lates:"⪭︀",lbarr:"⤌",lbbrk:"❲",lbrace:"{",lbrack:"[",lbrke:"⦋",lbrksld:"⦏",lbrkslu:"⦍",lcaron:"ľ",lcedil:"ļ",lceil:"⌈",lcub:"{",lcy:"л",ldca:"⤶",ldquo:"“",ldquor:"„",ldrdhar:"⥧",ldrushar:"⥋",ldsh:"↲",le:"≤",leftarrow:"←",leftarrowtail:"↢",leftharpoondown:"↽",leftharpoonup:"↼",leftleftarrows:"⇇",leftrightarrow:"↔",leftrightarrows:"⇆",leftrightharpoons:"⇋",leftrightsquigarrow:"↭",leftthreetimes:"⋋",leg:"⋚",leq:"≤",leqq:"≦",leqslant:"⩽",les:"⩽",lescc:"⪨",lesdot:"⩿",lesdoto:"⪁",lesdotor:"⪃",lesg:"⋚︀",lesges:"⪓",lessapprox:"⪅",lessdot:"⋖",lesseqgtr:"⋚",lesseqqgtr:"⪋",lessgtr:"≶",lesssim:"≲",lfisht:"⥼",lfloor:"⌊",lfr:"𝔩",lg:"≶",lgE:"⪑",lhard:"↽",lharu:"↼",lharul:"⥪",lhblk:"▄",ljcy:"љ",ll:"≪",llarr:"⇇",llcorner:"⌞",llhard:"⥫",lltri:"◺",lmidot:"ŀ",lmoust:"⎰",lmoustache:"⎰",lnE:"≨",lnap:"⪉",lnapprox:"⪉",lne:"⪇",lneq:"⪇",lneqq:"≨",lnsim:"⋦",loang:"⟬",loarr:"⇽",lobrk:"⟦",longleftarrow:"⟵",longleftrightarrow:"⟷",longmapsto:"⟼",longrightarrow:"⟶",looparrowleft:"↫",looparrowright:"↬",lopar:"⦅",lopf:"𝕝",loplus:"⨭",lotimes:"⨴",lowast:"∗",lowbar:"_",loz:"◊",lozenge:"◊",lozf:"⧫",lpar:"(",lparlt:"⦓",lrarr:"⇆",lrcorner:"⌟",lrhar:"⇋",lrhard:"⥭",lrm:"‎",lrtri:"⊿",lsaquo:"‹",lscr:"𝓁",lsh:"↰",lsim:"≲",lsime:"⪍",lsimg:"⪏",lsqb:"[",lsquo:"‘",lsquor:"‚",lstrok:"ł",lt:"<",ltcc:"⪦",ltcir:"⩹",ltdot:"⋖",lthree:"⋋",ltimes:"⋉",ltlarr:"⥶",ltquest:"⩻",ltrPar:"⦖",ltri:"◃",ltrie:"⊴",ltrif:"◂",lurdshar:"⥊",luruhar:"⥦",lvertneqq:"≨︀",lvnE:"≨︀",mDDot:"∺",macr:"¯",male:"♂",malt:"✠",maltese:"✠",map:"↦",mapsto:"↦",mapstodown:"↧",mapstoleft:"↤",mapstoup:"↥",marker:"▮",mcomma:"⨩",mcy:"м",mdash:"—",measuredangle:"∡",mfr:"𝔪",mho:"℧",micro:"µ",mid:"∣",midast:"*",midcir:"⫰",middot:"·",minus:"−",minusb:"⊟",minusd:"∸",minusdu:"⨪",mlcp:"⫛",mldr:"…",mnplus:"∓",models:"⊧",mopf:"𝕞",mp:"∓",mscr:"𝓂",mstpos:"∾",mu:"μ",multimap:"⊸",mumap:"⊸",nGg:"⋙̸",nGt:"≫⃒",nGtv:"≫̸",nLeftarrow:"⇍",nLeftrightarrow:"⇎",nLl:"⋘̸",nLt:"≪⃒",nLtv:"≪̸",nRightarrow:"⇏",nVDash:"⊯",nVdash:"⊮",nabla:"∇",nacute:"ń",nang:"∠⃒",nap:"≉",napE:"⩰̸",napid:"≋̸",napos:"ŉ",napprox:"≉",natur:"♮",natural:"♮",naturals:"ℕ",nbsp:" ",nbump:"≎̸",nbumpe:"≏̸",ncap:"⩃",ncaron:"ň",ncedil:"ņ",ncong:"≇",ncongdot:"⩭̸",ncup:"⩂",ncy:"н",ndash:"–",ne:"≠",neArr:"⇗",nearhk:"⤤",nearr:"↗",nearrow:"↗",nedot:"≐̸",nequiv:"≢",nesear:"⤨",nesim:"≂̸",nexist:"∄",nexists:"∄",nfr:"𝔫",ngE:"≧̸",nge:"≱",ngeq:"≱",ngeqq:"≧̸",ngeqslant:"⩾̸",nges:"⩾̸",ngsim:"≵",ngt:"≯",ngtr:"≯",nhArr:"⇎",nharr:"↮",nhpar:"⫲",ni:"∋",nis:"⋼",nisd:"⋺",niv:"∋",njcy:"њ",nlArr:"⇍",nlE:"≦̸",nlarr:"↚",nldr:"‥",nle:"≰",nleftarrow:"↚",nleftrightarrow:"↮",nleq:"≰",nleqq:"≦̸",nleqslant:"⩽̸",nles:"⩽̸",nless:"≮",nlsim:"≴",nlt:"≮",nltri:"⋪",nltrie:"⋬",nmid:"∤",nopf:"𝕟",not:"¬",notin:"∉",notinE:"⋹̸",notindot:"⋵̸",notinva:"∉",notinvb:"⋷",notinvc:"⋶",notni:"∌",notniva:"∌",notnivb:"⋾",notnivc:"⋽",npar:"∦",nparallel:"∦",nparsl:"⫽⃥",npart:"∂̸",npolint:"⨔",npr:"⊀",nprcue:"⋠",npre:"⪯̸",nprec:"⊀",npreceq:"⪯̸",nrArr:"⇏",nrarr:"↛",nrarrc:"⤳̸",nrarrw:"↝̸",nrightarrow:"↛",nrtri:"⋫",nrtrie:"⋭",nsc:"⊁",nsccue:"⋡",nsce:"⪰̸",nscr:"𝓃",nshortmid:"∤",nshortparallel:"∦",nsim:"≁",nsime:"≄",nsimeq:"≄",nsmid:"∤",nspar:"∦",nsqsube:"⋢",nsqsupe:"⋣",nsub:"⊄",nsubE:"⫅̸",nsube:"⊈",nsubset:"⊂⃒",nsubseteq:"⊈",nsubseteqq:"⫅̸",nsucc:"⊁",nsucceq:"⪰̸",nsup:"⊅",nsupE:"⫆̸",nsupe:"⊉",nsupset:"⊃⃒",nsupseteq:"⊉",nsupseteqq:"⫆̸",ntgl:"≹",ntilde:"ñ",ntlg:"≸",ntriangleleft:"⋪",ntrianglelefteq:"⋬",ntriangleright:"⋫",ntrianglerighteq:"⋭",nu:"ν",num:"#",numero:"№",numsp:" ",nvDash:"⊭",nvHarr:"⤄",nvap:"≍⃒",nvdash:"⊬",nvge:"≥⃒",nvgt:">⃒",nvinfin:"⧞",nvlArr:"⤂",nvle:"≤⃒",nvlt:"<⃒",nvltrie:"⊴⃒",nvrArr:"⤃",nvrtrie:"⊵⃒",nvsim:"∼⃒",nwArr:"⇖",nwarhk:"⤣",nwarr:"↖",nwarrow:"↖",nwnear:"⤧",oS:"Ⓢ",oacute:"ó",oast:"⊛",ocir:"⊚",ocirc:"ô",ocy:"о",odash:"⊝",odblac:"ő",odiv:"⨸",odot:"⊙",odsold:"⦼",oelig:"œ",ofcir:"⦿",ofr:"𝔬",ogon:"˛",ograve:"ò",ogt:"⧁",ohbar:"⦵",ohm:"Ω",oint:"∮",olarr:"↺",olcir:"⦾",olcross:"⦻",oline:"‾",olt:"⧀",omacr:"ō",omega:"ω",omicron:"ο",omid:"⦶",ominus:"⊖",oopf:"𝕠",opar:"⦷",operp:"⦹",oplus:"⊕",or:"∨",orarr:"↻",ord:"⩝",order:"ℴ",orderof:"ℴ",ordf:"ª",ordm:"º",origof:"⊶",oror:"⩖",orslope:"⩗",orv:"⩛",oscr:"ℴ",oslash:"ø",osol:"⊘",otilde:"õ",otimes:"⊗",otimesas:"⨶",ouml:"ö",ovbar:"⌽",par:"∥",para:"¶",parallel:"∥",parsim:"⫳",parsl:"⫽",part:"∂",pcy:"п",percnt:"%",period:".",permil:"‰",perp:"⊥",pertenk:"‱",pfr:"𝔭",phi:"φ",phiv:"ϕ",phmmat:"ℳ",phone:"☎",pi:"π",pitchfork:"⋔",piv:"ϖ",planck:"ℏ",planckh:"ℎ",plankv:"ℏ",plus:"+",plusacir:"⨣",plusb:"⊞",pluscir:"⨢",plusdo:"∔",plusdu:"⨥",pluse:"⩲",plusmn:"±",plussim:"⨦",plustwo:"⨧",pm:"±",pointint:"⨕",popf:"𝕡",pound:"£",pr:"≺",prE:"⪳",prap:"⪷",prcue:"≼",pre:"⪯",prec:"≺",precapprox:"⪷",preccurlyeq:"≼",preceq:"⪯",precnapprox:"⪹",precneqq:"⪵",precnsim:"⋨",precsim:"≾",prime:"′",primes:"ℙ",prnE:"⪵",prnap:"⪹",prnsim:"⋨",prod:"∏",profalar:"⌮",profline:"⌒",profsurf:"⌓",prop:"∝",propto:"∝",prsim:"≾",prurel:"⊰",pscr:"𝓅",psi:"ψ",puncsp:" ",qfr:"𝔮",qint:"⨌",qopf:"𝕢",qprime:"⁗",qscr:"𝓆",quaternions:"ℍ",quatint:"⨖",quest:"?",questeq:"≟",quot:'"',rAarr:"⇛",rArr:"⇒",rAtail:"⤜",rBarr:"⤏",rHar:"⥤",race:"∽̱",racute:"ŕ",radic:"√",raemptyv:"⦳",rang:"⟩",rangd:"⦒",range:"⦥",rangle:"⟩",raquo:"»",rarr:"→",rarrap:"⥵",rarrb:"⇥",rarrbfs:"⤠",rarrc:"⤳",rarrfs:"⤞",rarrhk:"↪",rarrlp:"↬",rarrpl:"⥅",rarrsim:"⥴",rarrtl:"↣",rarrw:"↝",ratail:"⤚",ratio:"∶",rationals:"ℚ",rbarr:"⤍",rbbrk:"❳",rbrace:"}",rbrack:"]",rbrke:"⦌",rbrksld:"⦎",rbrkslu:"⦐",rcaron:"ř",rcedil:"ŗ",rceil:"⌉",rcub:"}",rcy:"р",rdca:"⤷",rdldhar:"⥩",rdquo:"”",rdquor:"”",rdsh:"↳",real:"ℜ",realine:"ℛ",realpart:"ℜ",reals:"ℝ",rect:"▭",reg:"®",rfisht:"⥽",rfloor:"⌋",rfr:"𝔯",rhard:"⇁",rharu:"⇀",rharul:"⥬",rho:"ρ",rhov:"ϱ",rightarrow:"→",rightarrowtail:"↣",rightharpoondown:"⇁",rightharpoonup:"⇀",rightleftarrows:"⇄",rightleftharpoons:"⇌",rightrightarrows:"⇉",rightsquigarrow:"↝",rightthreetimes:"⋌",ring:"˚",risingdotseq:"≓",rlarr:"⇄",rlhar:"⇌",rlm:"‏",rmoust:"⎱",rmoustache:"⎱",rnmid:"⫮",roang:"⟭",roarr:"⇾",robrk:"⟧",ropar:"⦆",ropf:"𝕣",roplus:"⨮",rotimes:"⨵",rpar:")",rpargt:"⦔",rppolint:"⨒",rrarr:"⇉",rsaquo:"›",rscr:"𝓇",rsh:"↱",rsqb:"]",rsquo:"’",rsquor:"’",rthree:"⋌",rtimes:"⋊",rtri:"▹",rtrie:"⊵",rtrif:"▸",rtriltri:"⧎",ruluhar:"⥨",rx:"℞",sacute:"ś",sbquo:"‚",sc:"≻",scE:"⪴",scap:"⪸",scaron:"š",sccue:"≽",sce:"⪰",scedil:"ş",scirc:"ŝ",scnE:"⪶",scnap:"⪺",scnsim:"⋩",scpolint:"⨓",scsim:"≿",scy:"с",sdot:"⋅",sdotb:"⊡",sdote:"⩦",seArr:"⇘",searhk:"⤥",searr:"↘",searrow:"↘",sect:"§",semi:";",seswar:"⤩",setminus:"∖",setmn:"∖",sext:"✶",sfr:"𝔰",sfrown:"⌢",sharp:"♯",shchcy:"щ",shcy:"ш",shortmid:"∣",shortparallel:"∥",shy:"­",sigma:"σ",sigmaf:"ς",sigmav:"ς",sim:"∼",simdot:"⩪",sime:"≃",simeq:"≃",simg:"⪞",simgE:"⪠",siml:"⪝",simlE:"⪟",simne:"≆",simplus:"⨤",simrarr:"⥲",slarr:"←",smallsetminus:"∖",smashp:"⨳",smeparsl:"⧤",smid:"∣",smile:"⌣",smt:"⪪",smte:"⪬",smtes:"⪬︀",softcy:"ь",sol:"/",solb:"⧄",solbar:"⌿",sopf:"𝕤",spades:"♠",spadesuit:"♠",spar:"∥",sqcap:"⊓",sqcaps:"⊓︀",sqcup:"⊔",sqcups:"⊔︀",sqsub:"⊏",sqsube:"⊑",sqsubset:"⊏",sqsubseteq:"⊑",sqsup:"⊐",sqsupe:"⊒",sqsupset:"⊐",sqsupseteq:"⊒",squ:"□",square:"□",squarf:"▪",squf:"▪",srarr:"→",sscr:"𝓈",ssetmn:"∖",ssmile:"⌣",sstarf:"⋆",star:"☆",starf:"★",straightepsilon:"ϵ",straightphi:"ϕ",strns:"¯",sub:"⊂",subE:"⫅",subdot:"⪽",sube:"⊆",subedot:"⫃",submult:"⫁",subnE:"⫋",subne:"⊊",subplus:"⪿",subrarr:"⥹",subset:"⊂",subseteq:"⊆",subseteqq:"⫅",subsetneq:"⊊",subsetneqq:"⫋",subsim:"⫇",subsub:"⫕",subsup:"⫓",succ:"≻",succapprox:"⪸",succcurlyeq:"≽",succeq:"⪰",succnapprox:"⪺",succneqq:"⪶",succnsim:"⋩",succsim:"≿",sum:"∑",sung:"♪",sup1:"¹",sup2:"²",sup3:"³",sup:"⊃",supE:"⫆",supdot:"⪾",supdsub:"⫘",supe:"⊇",supedot:"⫄",suphsol:"⟉",suphsub:"⫗",suplarr:"⥻",supmult:"⫂",supnE:"⫌",supne:"⊋",supplus:"⫀",supset:"⊃",supseteq:"⊇",supseteqq:"⫆",supsetneq:"⊋",supsetneqq:"⫌",supsim:"⫈",supsub:"⫔",supsup:"⫖",swArr:"⇙",swarhk:"⤦",swarr:"↙",swarrow:"↙",swnwar:"⤪",szlig:"ß",target:"⌖",tau:"τ",tbrk:"⎴",tcaron:"ť",tcedil:"ţ",tcy:"т",tdot:"⃛",telrec:"⌕",tfr:"𝔱",there4:"∴",therefore:"∴",theta:"θ",thetasym:"ϑ",thetav:"ϑ",thickapprox:"≈",thicksim:"∼",thinsp:" ",thkap:"≈",thksim:"∼",thorn:"þ",tilde:"˜",times:"×",timesb:"⊠",timesbar:"⨱",timesd:"⨰",tint:"∭",toea:"⤨",top:"⊤",topbot:"⌶",topcir:"⫱",topf:"𝕥",topfork:"⫚",tosa:"⤩",tprime:"‴",trade:"™",triangle:"▵",triangledown:"▿",triangleleft:"◃",trianglelefteq:"⊴",triangleq:"≜",triangleright:"▹",trianglerighteq:"⊵",tridot:"◬",trie:"≜",triminus:"⨺",triplus:"⨹",trisb:"⧍",tritime:"⨻",trpezium:"⏢",tscr:"𝓉",tscy:"ц",tshcy:"ћ",tstrok:"ŧ",twixt:"≬",twoheadleftarrow:"↞",twoheadrightarrow:"↠",uArr:"⇑",uHar:"⥣",uacute:"ú",uarr:"↑",ubrcy:"ў",ubreve:"ŭ",ucirc:"û",ucy:"у",udarr:"⇅",udblac:"ű",udhar:"⥮",ufisht:"⥾",ufr:"𝔲",ugrave:"ù",uharl:"↿",uharr:"↾",uhblk:"▀",ulcorn:"⌜",ulcorner:"⌜",ulcrop:"⌏",ultri:"◸",umacr:"ū",uml:"¨",uogon:"ų",uopf:"𝕦",uparrow:"↑",updownarrow:"↕",upharpoonleft:"↿",upharpoonright:"↾",uplus:"⊎",upsi:"υ",upsih:"ϒ",upsilon:"υ",upuparrows:"⇈",urcorn:"⌝",urcorner:"⌝",urcrop:"⌎",uring:"ů",urtri:"◹",uscr:"𝓊",utdot:"⋰",utilde:"ũ",utri:"▵",utrif:"▴",uuarr:"⇈",uuml:"ü",uwangle:"⦧",vArr:"⇕",vBar:"⫨",vBarv:"⫩",vDash:"⊨",vangrt:"⦜",varepsilon:"ϵ",varkappa:"ϰ",varnothing:"∅",varphi:"ϕ",varpi:"ϖ",varpropto:"∝",varr:"↕",varrho:"ϱ",varsigma:"ς",varsubsetneq:"⊊︀",varsubsetneqq:"⫋︀",varsupsetneq:"⊋︀",varsupsetneqq:"⫌︀",vartheta:"ϑ",vartriangleleft:"⊲",vartriangleright:"⊳",vcy:"в",vdash:"⊢",vee:"∨",veebar:"⊻",veeeq:"≚",vellip:"⋮",verbar:"|",vert:"|",vfr:"𝔳",vltri:"⊲",vnsub:"⊂⃒",vnsup:"⊃⃒",vopf:"𝕧",vprop:"∝",vrtri:"⊳",vscr:"𝓋",vsubnE:"⫋︀",vsubne:"⊊︀",vsupnE:"⫌︀",vsupne:"⊋︀",vzigzag:"⦚",wcirc:"ŵ",wedbar:"⩟",wedge:"∧",wedgeq:"≙",weierp:"℘",wfr:"𝔴",wopf:"𝕨",wp:"℘",wr:"≀",wreath:"≀",wscr:"𝓌",xcap:"⋂",xcirc:"◯",xcup:"⋃",xdtri:"▽",xfr:"𝔵",xhArr:"⟺",xharr:"⟷",xi:"ξ",xlArr:"⟸",xlarr:"⟵",xmap:"⟼",xnis:"⋻",xodot:"⨀",xopf:"𝕩",xoplus:"⨁",xotime:"⨂",xrArr:"⟹",xrarr:"⟶",xscr:"𝓍",xsqcup:"⨆",xuplus:"⨄",xutri:"△",xvee:"⋁",xwedge:"⋀",yacute:"ý",yacy:"я",ycirc:"ŷ",ycy:"ы",yen:"¥",yfr:"𝔶",yicy:"ї",yopf:"𝕪",yscr:"𝓎",yucy:"ю",yuml:"ÿ",zacute:"ź",zcaron:"ž",zcy:"з",zdot:"ż",zeetrf:"ℨ",zeta:"ζ",zfr:"𝔷",zhcy:"ж",zigrarr:"⇝",zopf:"𝕫",zscr:"𝓏",zwj:"‍",zwnj:"‌"},ne={0:65533,128:8364,130:8218,131:402,132:8222,133:8230,134:8224,135:8225,136:710,137:8240,138:352,139:8249,140:338,142:381,145:8216,146:8217,147:8220,148:8221,149:8226,150:8211,151:8212,152:732,153:8482,154:353,155:8250,156:339,158:382,159:376};function oe(e){return e.replace(/&(?:[a-zA-Z]+|#[xX][\da-fA-F]+|#\d+);/g,e=>{if("#"===e.charAt(1)){const t=e.charAt(2);return function(e){if(e>=55296&&e<=57343||e>1114111)return"�";return String.fromCodePoint(x(ne,e)??e)}("X"===t||"x"===t?parseInt(e.slice(3),16):parseInt(e.slice(2),10))}return x(re,e.slice(1,-1))??e})}function ae(e,t){return e.startIndex=e.tokenIndex=e.index,e.startColumn=e.tokenColumn=e.column,e.startLine=e.tokenLine=e.line,e.setToken(8192&n[e.currentChar]?function(e){const t=e.currentChar;let r=c(e);const n=e.index;for(;r!==t;)e.index>=e.end&&e.report(16),r=c(e);r!==t&&e.report(16);e.tokenValue=e.source.slice(n,e.index),c(e),e.options.raw&&(e.tokenRaw=e.source.slice(e.tokenIndex,e.index));return 134283267}(e):M(e,t,0)),e.getToken()}function ie(e){if(e.startIndex=e.tokenIndex=e.index,e.startColumn=e.tokenColumn=e.column,e.startLine=e.tokenLine=e.line,e.index>=e.end)return void e.setToken(1048576);if(60===e.currentChar)return c(e),void e.setToken(8456256);if(123===e.currentChar)return c(e),void e.setToken(2162700);let t=0;for(;e.index<e.end;){const r=n[e.source.charCodeAt(e.index)];if(1024&r?(t|=5,p(e)):2048&r?(u(e,t),t=-5&t|1):c(e),16384&n[e.currentChar])break}e.tokenIndex===e.index&&e.report(0);const r=e.source.slice(e.tokenIndex,e.index);e.options.raw&&(e.tokenRaw=r),e.tokenValue=oe(r),e.setToken(137)}function se(e){if(!(143360&~e.getToken())){const{index:t}=e;let r=e.currentChar;for(;32770&n[r];)r=c(e);e.tokenValue+=e.source.slice(t,e.index),e.setToken(208897,!0)}return e.getToken()}class ce{parser;parent;refs=Object.create(null);privateIdentifiers=new Map;constructor(e,t){this.parser=e,this.parent=t}addPrivateIdentifier(e,t){const{privateIdentifiers:r}=this;let n=800&t;768&n||(n|=768);const o=r.get(e);this.hasPrivateIdentifier(e)&&((32&o)!=(32&n)||o&n&768)&&this.parser.report(146,e),r.set(e,this.hasPrivateIdentifier(e)?o|n:n)}addPrivateIdentifierRef(e){this.refs[e]??=[],this.refs[e].push(this.parser.tokenStart)}isPrivateIdentifierDefined(e){return this.hasPrivateIdentifier(e)||Boolean(this.parent?.isPrivateIdentifierDefined(e))}validatePrivateIdentifierRefs(){for(const e in this.refs)if(!this.isPrivateIdentifierDefined(e)){const{index:t,line:r,column:n}=this.refs[e][0];throw new y({index:t,line:r,column:n},{index:t+e.length,line:r,column:n+e.length},4,e)}}hasPrivateIdentifier(e){return this.privateIdentifiers.has(e)}}class le{parser;type;parent;scopeError;variableBindings=new Map;constructor(e,t=2,r){this.parser=e,this.type=t,this.parent=r}createChildScope(e){return new le(this.parser,e,this)}addVarOrBlock(e,t,r,n){4&r?this.addVarName(e,t,r):this.addBlockName(e,t,r,n),64&n&&this.parser.declareUnboundVariable(t)}addVarName(e,t,r){const{parser:n}=this;let o=this;for(;o&&!(128&o.type);){const{variableBindings:a}=o,i=a.get(t);i&&248&i&&(!n.options.webcompat||1&e||!(128&r&&68&i||128&i&&68&r))&&n.report(145,t),o===this&&i&&1&i&&1&r&&o.recordScopeError(145,t),i&&(256&i||512&i&&!n.options.webcompat)&&n.report(145,t),o.variableBindings.set(t,r),o=o.parent}}hasVariable(e){return this.variableBindings.has(e)}addBlockName(e,t,r,n){const{parser:o}=this,a=this.variableBindings.get(t);!a||2&a||(1&r?this.recordScopeError(145,t):o.options.webcompat&&!(1&e)&&2&n&&64===a&&64===r||o.report(145,t)),64&this.type&&this.parent?.hasVariable(t)&&!(2&this.parent.variableBindings.get(t))&&o.report(145,t),512&this.type&&a&&!(2&a)&&1&r&&this.recordScopeError(145,t),32&this.type&&768&this.parent.variableBindings.get(t)&&o.report(159,t),this.variableBindings.set(t,r)}recordScopeError(e,...t){this.scopeError={type:e,params:t,start:this.parser.tokenStart,end:this.parser.currentLocation}}reportScopeError(){const{scopeError:e}=this;if(e)throw new y(e.start,e.end,e.type,...e.params)}}function ue(e,t,r){const n=e.createScope().createChildScope(512);return n.addBlockName(t,r,1,0),n}class pe{source;lastOnToken=null;options;token=1048576;flags=0;index=0;line=1;column=0;startIndex=0;end=0;tokenIndex=0;startColumn=0;tokenColumn=0;tokenLine=1;startLine=1;tokenValue="";tokenRaw="";tokenRegExp=void 0;currentChar=0;exportedNames=new Set;exportedBindings=new Set;assignable=0;destructible=0;leadingDecorators={decorators:[]};constructor(e,t={}){var r,n;this.source=e,this.end=e.length,this.currentChar=e.charCodeAt(0),this.options=function(e){const t={validateRegex:!0,...e};return t.module&&!t.sourceType&&(t.sourceType="module"),!t.globalReturn||t.sourceType&&"script"!==t.sourceType||(t.sourceType="commonjs"),t}(t),Array.isArray(this.options.onComment)&&(this.options.onComment=(r=this.options.onComment,n=this.options,function(e,t,o,a,i){const s={type:e,value:t};n.ranges&&(s.start=o,s.end=a,s.range=[o,a]),n.loc&&(s.loc=i),r.push(s)})),Array.isArray(this.options.onToken)&&(this.options.onToken=function(e,t){return function(r,n,o,a){const i={token:r};t.ranges&&(i.start=n,i.end=o,i.range=[n,o]),t.loc&&(i.loc=a),e.push(i)}}(this.options.onToken,this.options))}getToken(){return this.token}setToken(e,t=!1){this.token=e;const{onToken:r}=this.options;if(r)if(1048576!==e){const n={start:{line:this.tokenLine,column:this.tokenColumn},end:{line:this.line,column:this.column}};!t&&this.lastOnToken&&r(...this.lastOnToken),this.lastOnToken=[f(e),this.tokenIndex,this.index,n]}else this.lastOnToken&&(r(...this.lastOnToken),this.lastOnToken=null);return e}get tokenStart(){return{index:this.tokenIndex,line:this.tokenLine,column:this.tokenColumn}}get currentLocation(){return{index:this.index,line:this.line,column:this.column}}finishNode(e,t,r){if(this.options.ranges){e.start=t.index;const n=r?r.index:this.startIndex;e.end=n,e.range=[t.index,n]}return this.options.loc&&(e.loc={start:{line:t.line,column:t.column},end:r?{line:r.line,column:r.column}:{line:this.startLine,column:this.startColumn}},this.options.source&&(e.loc.source=this.options.source)),e}addBindingToExports(e){this.exportedBindings.add(e)}declareUnboundVariable(e){const{exportedNames:t}=this;t.has(e)&&this.report(147,e),t.add(e)}report(e,...t){throw new y(this.tokenStart,this.currentLocation,e,...t)}createScopeIfLexical(e,t){if(this.options.lexical)return this.createScope(e,t)}createScope(e,t){return new le(this,e,t)}createPrivateScopeIfLexical(e){if(this.options.lexical)return new ce(this,e)}cloneIdentifier(e){return this.cloneLocationInformation({...e},e)}cloneStringLiteral(e){return this.cloneLocationInformation({...e},e)}cloneLocationInformation(e,t){return this.options.ranges&&(e.range=[...t.range]),this.options.loc&&(e.loc={...t.loc,start:{...t.loc.start},end:{...t.loc.end}}),e}}function de(e,t={},r=0){const n=new pe(e,t);"module"===n.options.sourceType&&(r|=3),"commonjs"===n.options.sourceType&&(r|=69632),n.options.impliedStrict&&(r|=1),function(e){const{source:t}=e;35===e.currentChar&&33===t.charCodeAt(e.index+1)&&(c(e),c(e),m(e,t,0,4,e.tokenStart))}(n);const o=n.createScopeIfLexical();let a=[],i="script";if(2&r){if(i="module",a=function(e,t,r){F(e,32|t);const n=[];for(;134283267===e.getToken();){const{tokenStart:r}=e,o=e.getToken();n.push(ye(e,t,nt(e,t),o,r))}for(;1048576!==e.getToken();)n.push(ge(e,t,r));return n}(n,8|r,o),o)for(const e of n.exportedBindings)o.hasVariable(e)||n.report(148,e)}else a=function(e,t,r){F(e,262176|t);const n=[];for(;134283267===e.getToken();){const{index:r,tokenValue:o,tokenStart:a,tokenIndex:i}=e,s=e.getToken(),c=nt(e,t);if(J(e,r,i,o)){if(t|=1,64&e.flags)throw new y(e.tokenStart,e.currentLocation,9);if(4096&e.flags)throw new y(e.tokenStart,e.currentLocation,15)}n.push(ye(e,t,c,s,a))}for(;1048576!==e.getToken();)n.push(fe(e,t,r,void 0,4,{}));return n}(n,8|r,o);return n.finishNode({type:"Program",sourceType:i,body:a},{index:0,line:1,column:0},n.currentLocation)}function ge(e,t,r){let n;switch(132===e.getToken()&&Object.assign(e.leadingDecorators,{start:e.tokenStart,decorators:xt(e,t,void 0)}),e.getToken()){case 20564:n=function(e,t,r){const n=e.leadingDecorators.decorators.length?e.leadingDecorators.start:e.tokenStart;F(e,32|t);const o=[];let a=null,i=null,s=[];if(X(e,32|t,20561)){switch(e.getToken()){case 86104:a=ot(e,t,r,void 0,4,1,1,0,e.tokenStart);break;case 132:case 86094:a=yt(e,t,r,void 0,1);break;case 209005:{const{tokenStart:n}=e;a=rt(e,t);const{flags:o}=e;1&o||(86104===e.getToken()?a=ot(e,t,r,void 0,4,1,1,1,n):67174411===e.getToken()?(a=Tt(e,t,void 0,a,1,1,0,o,n),a=Fe(e,t,void 0,a,0,0,n),a=Be(e,t,void 0,0,0,n,a)):143360&e.getToken()&&(r&&(r=ue(e,t,e.tokenValue)),a=rt(e,t),a=kt(e,t,r,void 0,[a],1,n)));break}default:a=Ve(e,t,void 0,1,0,e.tokenStart),H(e,32|t)}return r&&e.declareUnboundVariable("default"),e.finishNode({type:"ExportDefaultDeclaration",declaration:a},n)}switch(e.getToken()){case 8391476:{F(e,t);let o=null;X(e,t,77932)&&(r&&e.declareUnboundVariable(e.tokenValue),o=Ye(e,t)),_(e,t,209011),134283267!==e.getToken()&&e.report(105,"Export"),i=nt(e,t);const a={type:"ExportAllDeclaration",source:i,exported:o,attributes:Xe(e,t)};return H(e,32|t),e.finishNode(a,n)}case 2162700:{F(e,t);const n=[],a=[];let c=0;for(;143360&e.getToken()||134283267===e.getToken();){const{tokenStart:i,tokenValue:s}=e,l=Ye(e,t);let u;"Literal"===l.type&&(c=1),77932===e.getToken()?(F(e,t),143360&e.getToken()||134283267===e.getToken()||e.report(106),r&&(n.push(e.tokenValue),a.push(s)),u=Ye(e,t)):(r&&(n.push(e.tokenValue),a.push(e.tokenValue)),u="Literal"===l.type?e.cloneStringLiteral(l):e.cloneIdentifier(l)),o.push(e.finishNode({type:"ExportSpecifier",local:l,exported:u},i)),1074790415!==e.getToken()&&_(e,t,18)}_(e,t,1074790415),X(e,t,209011)?(134283267!==e.getToken()&&e.report(105,"Export"),i=nt(e,t),s=Xe(e,t),r&&n.forEach(t=>e.declareUnboundVariable(t))):(c&&e.report(172),r&&(n.forEach(t=>e.declareUnboundVariable(t)),a.forEach(t=>e.addBindingToExports(t)))),H(e,32|t);break}case 132:case 86094:a=yt(e,t,r,void 0,2);break;case 86104:a=ot(e,t,r,void 0,4,1,2,0,e.tokenStart);break;case 241737:a=Se(e,t,r,void 0,8,64);break;case 86090:a=Se(e,t,r,void 0,16,64);break;case 86088:a=ve(e,t,r,void 0,64);break;case 209005:{const{tokenStart:n}=e;if(F(e,t),!(1&e.flags)&&86104===e.getToken()){a=ot(e,t,r,void 0,4,1,2,1,n);break}}default:e.report(30,w[255&e.getToken()])}const c={type:"ExportNamedDeclaration",declaration:a,specifiers:o,source:i,attributes:s};return e.finishNode(c,n)}(e,t,r);break;case 86106:n=function(e,t,r){const n=e.tokenStart;F(e,t);let o=null;const{tokenStart:a}=e;let i=[];if(134283267===e.getToken())o=nt(e,t);else{if(143360&e.getToken()){const n=Ee(e,t,r);if(i=[e.finishNode({type:"ImportDefaultSpecifier",local:n},a)],X(e,t,18))switch(e.getToken()){case 8391476:i.push(Ne(e,t,r));break;case 2162700:Le(e,t,r,i);break;default:e.report(107)}}else switch(e.getToken()){case 8391476:i=[Ne(e,t,r)];break;case 2162700:Le(e,t,r,i);break;case 67174411:return Ie(e,t,void 0,n);case 67108877:return Ae(e,t,n);default:e.report(30,w[255&e.getToken()])}o=function(e,t){_(e,t,209011),134283267!==e.getToken()&&e.report(105,"Import");return nt(e,t)}(e,t)}const s=Xe(e,t),c={type:"ImportDeclaration",specifiers:i,source:o,attributes:s};return H(e,32|t),e.finishNode(c,n)}(e,t,r);break;default:n=fe(e,t,r,void 0,4,{})}return e.leadingDecorators?.decorators.length&&e.report(170),n}function fe(e,t,r,n,o,a){const i=e.tokenStart;switch(e.getToken()){case 86104:return ot(e,t,r,n,o,1,0,0,i);case 132:case 86094:return yt(e,t,r,n,0);case 86090:return Se(e,t,r,n,16,0);case 241737:return function(e,t,r,n,o){const{tokenValue:a,tokenStart:i}=e,s=e.getToken();let c=rt(e,t);if(2240512&e.getToken()){const o=Ce(e,t,r,n,8,0);return H(e,32|t),e.finishNode({type:"VariableDeclaration",kind:"let",declarations:o},i)}e.assignable=1,1&t&&e.report(85);if(21===e.getToken())return be(e,t,r,n,o,{},a,c,s,0,i);if(10===e.getToken()){let r;e.options.lexical&&(r=ue(e,t,a)),e.flags=128^(128|e.flags),c=kt(e,t,r,n,[c],0,i)}else c=Fe(e,t,n,c,0,0,i),c=Be(e,t,n,0,0,i,c);18===e.getToken()&&(c=De(e,t,n,0,i,c));return me(e,t,c,i)}(e,t,r,n,o);case 20564:e.report(103,"export");case 86106:switch(F(e,t),e.getToken()){case 67174411:return Ie(e,t,n,i);case 67108877:return Ae(e,t,i);default:e.report(103,"import")}case 209005:return Te(e,t,r,n,o,a,1);default:return ke(e,t,r,n,o,a,1)}}function ke(e,t,r,n,o,a,i){switch(e.getToken()){case 86088:return ve(e,t,r,n,0);case 20572:return function(e,t,r){4096&t||e.report(92);const n=e.tokenStart;F(e,32|t);const o=1&e.flags||1048576&e.getToken()?null:Re(e,t,r,0,1,e.tokenStart);return H(e,32|t),e.finishNode({type:"ReturnStatement",argument:o},n)}(e,t,n);case 20569:return function(e,t,r,n,o){const a=e.tokenStart;F(e,t),_(e,32|t,67174411),e.assignable=1;const i=Re(e,t,n,0,1,e.tokenStart);_(e,32|t,16);const s=xe(e,t,r,n,o);let c=null;20563===e.getToken()&&(F(e,32|t),c=xe(e,t,r,n,o));return e.finishNode({type:"IfStatement",test:i,consequent:s,alternate:c},a)}(e,t,r,n,a);case 20567:return function(e,t,r,n,o){const a=e.tokenStart;F(e,t);const i=((2048&t)>0||(2&t)>0&&(8&t)>0)&&X(e,t,209006);_(e,32|t,67174411),r=r?.createChildScope(1);let s,c=null,l=null,u=0,p=null,d=86088===e.getToken()||241737===e.getToken()||86090===e.getToken();const{tokenStart:g}=e,f=e.getToken();if(d)241737===f?(p=rt(e,t),2240512&e.getToken()?(8673330===e.getToken()?1&t&&e.report(67):p=e.finishNode({type:"VariableDeclaration",kind:"let",declarations:Ce(e,131072|t,r,n,8,32)},g),e.assignable=1):1&t?e.report(67):(d=!1,e.assignable=1,p=Fe(e,t,n,p,0,0,g),471156===e.getToken()&&e.report(115))):(F(e,t),p=e.finishNode(86088===f?{type:"VariableDeclaration",kind:"var",declarations:Ce(e,131072|t,r,n,4,32)}:{type:"VariableDeclaration",kind:"const",declarations:Ce(e,131072|t,r,n,16,32)},g),e.assignable=1);else if(1074790417===f)i&&e.report(82);else if(2097152&~f)p=je(e,131072|t,n,1,0,1);else{const r=e.tokenStart;p=2162700===f?ut(e,t,void 0,n,1,0,0,2,32):it(e,t,void 0,n,1,0,0,2,32),u=e.destructible,64&u&&e.report(63),e.assignable=16&u?2:1,p=Fe(e,131072|t,n,p,0,0,r)}if(!(262144&~e.getToken())){if(471156===e.getToken()){2&e.assignable&&e.report(80,i?"await":"of"),$(e,p),F(e,32|t),s=Ve(e,t,n,1,0,e.tokenStart),_(e,32|t,16);const c=we(e,t,r,n,o);return e.finishNode({type:"ForOfStatement",left:p,right:s,body:c,await:i},a)}2&e.assignable&&e.report(80,"in"),$(e,p),F(e,32|t),i&&e.report(82),s=Re(e,t,n,0,1,e.tokenStart),_(e,32|t,16);const c=we(e,t,r,n,o);return e.finishNode({type:"ForInStatement",body:c,left:p,right:s},a)}i&&e.report(82);d||(8&u&&1077936155!==e.getToken()&&e.report(80,"loop"),p=Be(e,131072|t,n,0,0,g,p));18===e.getToken()&&(p=De(e,t,n,0,g,p));_(e,32|t,1074790417),1074790417!==e.getToken()&&(c=Re(e,t,n,0,1,e.tokenStart));_(e,32|t,1074790417),16!==e.getToken()&&(l=Re(e,t,n,0,1,e.tokenStart));_(e,32|t,16);const k=we(e,t,r,n,o);return e.finishNode({type:"ForStatement",init:p,test:c,update:l,body:k},a)}(e,t,r,n,a);case 20562:return function(e,t,r,n,o){const a=e.tokenStart;F(e,32|t);const i=we(e,t,r,n,o);_(e,t,20578),_(e,32|t,67174411);const s=Re(e,t,n,0,1,e.tokenStart);return _(e,32|t,16),X(e,32|t,1074790417),e.finishNode({type:"DoWhileStatement",body:i,test:s},a)}(e,t,r,n,a);case 20578:return function(e,t,r,n,o){const a=e.tokenStart;F(e,t),_(e,32|t,67174411);const i=Re(e,t,n,0,1,e.tokenStart);_(e,32|t,16);const s=we(e,t,r,n,o);return e.finishNode({type:"WhileStatement",test:i,body:s},a)}(e,t,r,n,a);case 86110:return function(e,t,r,n,o){const a=e.tokenStart;F(e,t),_(e,32|t,67174411);const i=Re(e,t,n,0,1,e.tokenStart);_(e,t,16),_(e,t,2162700);const s=[];let c=0;r=r?.createChildScope(8);for(;1074790415!==e.getToken();){const{tokenStart:a}=e;let i=null;const l=[];for(X(e,32|t,20556)?i=Re(e,t,n,0,1,e.tokenStart):(_(e,32|t,20561),c&&e.report(89),c=1),_(e,32|t,21);20556!==e.getToken()&&1074790415!==e.getToken()&&20561!==e.getToken();)l.push(fe(e,4|t,r,n,2,{$:o}));s.push(e.finishNode({type:"SwitchCase",test:i,consequent:l},a))}return _(e,32|t,1074790415),e.finishNode({type:"SwitchStatement",discriminant:i,cases:s},a)}(e,t,r,n,a);case 1074790417:return function(e,t){const r=e.tokenStart;return F(e,32|t),e.finishNode({type:"EmptyStatement"},r)}(e,t);case 2162700:return he(e,t,r?.createChildScope(),n,a,e.tokenStart);case 86112:return function(e,t,r){const n=e.tokenStart;F(e,32|t),1&e.flags&&e.report(90);const o=Re(e,t,r,0,1,e.tokenStart);return H(e,32|t),e.finishNode({type:"ThrowStatement",argument:o},n)}(e,t,n);case 20555:return function(e,t,r){const n=e.tokenStart;F(e,32|t);let o=null;if(!(1&e.flags)&&143360&e.getToken()){const{tokenValue:n}=e;o=rt(e,32|t),K(e,r,n,0)||e.report(138,n)}else 132&t||e.report(69);return H(e,32|t),e.finishNode({type:"BreakStatement",label:o},n)}(e,t,a);case 20559:return function(e,t,r){128&t||e.report(68);const n=e.tokenStart;F(e,t);let o=null;if(!(1&e.flags)&&143360&e.getToken()){const{tokenValue:n}=e;o=rt(e,32|t),K(e,r,n,1)||e.report(138,n)}return H(e,32|t),e.finishNode({type:"ContinueStatement",label:o},n)}(e,t,a);case 20577:return function(e,t,r,n,o){const a=e.tokenStart;F(e,32|t);const i=r?.createChildScope(16),s=he(e,t,i,n,{$:o}),{tokenStart:c}=e,l=X(e,32|t,20557)?function(e,t,r,n,o,a){let i=null,s=r;X(e,t,67174411)&&(r=r?.createChildScope(4),i=Et(e,t,r,n,2097152&~e.getToken()?512:256,0),18===e.getToken()?e.report(86):1077936155===e.getToken()&&e.report(87),_(e,32|t,16));s=r?.createChildScope(32);const c=he(e,t,s,n,{$:o});return e.finishNode({type:"CatchClause",param:i,body:c},a)}(e,t,r,n,o,c):null;let u=null;if(20566===e.getToken()){F(e,32|t);const a=r?.createChildScope(4);u=he(e,t,a,n,{$:o})}l||u||e.report(88);return e.finishNode({type:"TryStatement",block:s,handler:l,finalizer:u},a)}(e,t,r,n,a);case 20579:return function(e,t,r,n,o){const a=e.tokenStart;F(e,t),1&t&&e.report(91);_(e,32|t,67174411);const i=Re(e,t,n,0,1,e.tokenStart);_(e,32|t,16);const s=ke(e,t,r,n,2,o,0);return e.finishNode({type:"WithStatement",object:i,body:s},a)}(e,t,r,n,a);case 20560:return function(e,t){const r=e.tokenStart;return F(e,32|t),H(e,32|t),e.finishNode({type:"DebuggerStatement"},r)}(e,t);case 209005:return Te(e,t,r,n,o,a,0);case 20557:e.report(162);case 20566:e.report(163);case 86104:e.report(1&t?76:e.options.webcompat?77:78);case 86094:e.report(79);default:return function(e,t,r,n,o,a,i){const{tokenValue:s,tokenStart:c}=e,l=e.getToken();let u;if(241737===l)u=rt(e,t),1&t&&e.report(85),69271571===e.getToken()&&e.report(84);else u=He(e,t,n,2,0,1,0,1,e.tokenStart);if(143360&l&&21===e.getToken())return be(e,t,r,n,o,a,s,u,l,i,c);u=Fe(e,t,n,u,0,0,c),u=Be(e,t,n,0,0,c,u),18===e.getToken()&&(u=De(e,t,n,0,c,u));return me(e,t,u,c)}(e,t,r,n,o,a,i)}}function he(e,t,r,n,o,a=e.tokenStart,i="BlockStatement"){const s=[];for(_(e,32|t,2162700);1074790415!==e.getToken();)s.push(fe(e,t,r,n,2,{$:o}));return _(e,32|t,1074790415),e.finishNode({type:i,body:s},a)}function me(e,t,r,n){return H(e,32|t),e.finishNode({type:"ExpressionStatement",expression:r},n)}function be(e,t,r,n,o,a,i,s,c,l,u){Y(e,t,0,c,1),function(e,t,r){let n=t;for(;n;)n["$"+r]&&e.report(136,r),n=n.$;t["$"+r]=1}(e,a,i),F(e,32|t);const p=!l||1&t||!e.options.webcompat||86104!==e.getToken()?ke(e,t,r,n,o,a,l):ot(e,t,r?.createChildScope(),n,o,0,0,0,e.tokenStart);return e.finishNode({type:"LabeledStatement",label:s,body:p},u)}function Te(e,t,r,n,o,a,i){const{tokenValue:s,tokenStart:c}=e,l=e.getToken();let u=rt(e,t);if(21===e.getToken())return be(e,t,r,n,o,a,s,u,l,1,c);const p=1&e.flags;if(!p){if(86104===e.getToken())return i||e.report(123),ot(e,t,r,n,o,1,0,1,c);if(ee(t,e.getToken()))return u=bt(e,t,n,1,c),18===e.getToken()&&(u=De(e,t,n,0,c,u)),me(e,t,u,c)}return 67174411===e.getToken()?u=Tt(e,t,n,u,1,1,0,p,c):(10===e.getToken()&&(te(e,t,l),36864&~l||(e.flags|=256),u=gt(e,2048|t,n,e.tokenValue,u,0,1,0,c)),e.assignable=1),u=Fe(e,t,n,u,0,0,c),u=Be(e,t,n,0,0,c,u),e.assignable=1,18===e.getToken()&&(u=De(e,t,n,0,c,u)),me(e,t,u,c)}function ye(e,t,r,n,o){const a=e.startIndex;1074790417!==n&&(e.assignable=2,r=Fe(e,t,void 0,r,0,0,o),1074790417!==e.getToken()&&(r=Be(e,t,void 0,0,0,o,r),18===e.getToken()&&(r=De(e,t,void 0,0,o,r))),H(e,32|t));const i={type:"ExpressionStatement",expression:r};return"Literal"===r.type&&"string"==typeof r.value&&(i.directive=e.source.slice(o.index+1,a-1)),e.finishNode(i,o)}function xe(e,t,r,n,o){const{tokenStart:a}=e;return 1&t||!e.options.webcompat||86104!==e.getToken()?ke(e,t,r,n,0,{$:o},0):ot(e,t,r?.createChildScope(),n,0,0,0,0,a)}function we(e,t,r,n,o){return ke(e,131072^(131072|t)|128,r,n,0,{loop:1,$:o},0)}function Se(e,t,r,n,o,a){const i=e.tokenStart;F(e,t);const s=Ce(e,t,r,n,o,a);return H(e,32|t),e.finishNode({type:"VariableDeclaration",kind:8&o?"let":"const",declarations:s},i)}function ve(e,t,r,n,o){const a=e.tokenStart;F(e,t);const i=Ce(e,t,r,n,4,o);return H(e,32|t),e.finishNode({type:"VariableDeclaration",kind:"var",declarations:i},a)}function Ce(e,t,r,n,o,a){let i=1;const s=[qe(e,t,r,n,o,a)];for(;X(e,t,18);)i++,s.push(qe(e,t,r,n,o,a));return i>1&&32&a&&262144&e.getToken()&&e.report(61,w[255&e.getToken()]),s}function qe(e,t,r,n,o,a){const{tokenStart:i}=e,s=e.getToken();let c=null;const l=Et(e,t,r,n,o,a);if(1077936155===e.getToken()){if(F(e,32|t),c=Ve(e,t,n,1,0,e.tokenStart),(32&a||!(2097152&s))&&(471156===e.getToken()||8673330===e.getToken()&&(2097152&s||!(4&o)||1&t)))throw new y(i,e.currentLocation,60,471156===e.getToken()?"of":"in")}else(16&o||(2097152&s)>0)&&262144&~e.getToken()&&e.report(59,16&o?"const":"destructuring");return e.finishNode({type:"VariableDeclarator",id:l,init:c},i)}function Ee(e,t,r){return ee(t,e.getToken())||e.report(118),537079808&~e.getToken()||e.report(119),r?.addBlockName(t,e.tokenValue,8,0),rt(e,t)}function Ne(e,t,r){const{tokenStart:n}=e;if(F(e,t),_(e,t,77932),!(134217728&~e.getToken()))throw new y(n,e.currentLocation,30,w[255&e.getToken()]);return e.finishNode({type:"ImportNamespaceSpecifier",local:Ee(e,t,r)},n)}function Le(e,t,r,n){for(F(e,t);143360&e.getToken()||134283267===e.getToken();){let{tokenValue:o,tokenStart:a}=e;const i=e.getToken(),s=Ye(e,t);let c;X(e,t,77932)?(134217728&~e.getToken()&&18!==e.getToken()?Y(e,t,16,e.getToken(),0):e.report(106),o=e.tokenValue,c=rt(e,t)):"Identifier"===s.type?(Y(e,t,16,i,0),c=e.cloneIdentifier(s)):e.report(25,w[108]),r?.addBlockName(t,o,8,0),n.push(e.finishNode({type:"ImportSpecifier",local:c,imported:s},a)),1074790415!==e.getToken()&&_(e,t,18)}return _(e,t,1074790415),n}function Ae(e,t,r){let n=Je(e,t,e.finishNode({type:"Identifier",name:"import"},r),r);return n=Fe(e,t,void 0,n,0,0,r),n=Be(e,t,void 0,0,0,r,n),18===e.getToken()&&(n=De(e,t,void 0,0,r,n)),me(e,t,n,r)}function Ie(e,t,r,n){let o=ze(e,t,r,0,n);return o=Fe(e,t,r,o,0,0,n),18===e.getToken()&&(o=De(e,t,r,0,n,o)),me(e,t,o,n)}function Ve(e,t,r,n,o,a){let i=He(e,t,r,2,0,n,o,1,a);return i=Fe(e,t,r,i,o,0,a),Be(e,t,r,o,0,a,i)}function De(e,t,r,n,o,a){const i=[a];for(;X(e,32|t,18);)i.push(Ve(e,t,r,1,n,e.tokenStart));return e.finishNode({type:"SequenceExpression",expressions:i},o)}function Re(e,t,r,n,o,a){const i=Ve(e,t,r,o,n,a);return 18===e.getToken()?De(e,t,r,n,a,i):i}function Be(e,t,r,n,o,a,i){const s=e.getToken();if(!(4194304&~s)){2&e.assignable&&e.report(26),!(524288&~s)&&4&e.assignable&&e.report(26),(!o&&1077936155===s&&"ArrayExpression"===i.type||"ObjectExpression"===i.type)&&$(e,i),F(e,32|t);const c=Ve(e,t,r,1,n,e.tokenStart);return e.assignable=2,e.finishNode(o?{type:"AssignmentPattern",left:i,right:c}:{type:"AssignmentExpression",left:i,operator:w[255&s],right:c},a)}return 8388608&~s||(i=Oe(e,t,r,n,a,4,s,i)),X(e,32|t,22)&&(i=Pe(e,t,r,i,a)),i}function Ue(e,t,r,n,o,a,i){const s=e.getToken();F(e,32|t);const c=Ve(e,t,r,1,n,e.tokenStart);return i=e.finishNode(o?{type:"AssignmentPattern",left:i,right:c}:{type:"AssignmentExpression",left:i,operator:w[255&s],right:c},a),e.assignable=2,i}function Pe(e,t,r,n,o){const a=Ve(e,131072^(131072|t),r,1,0,e.tokenStart);_(e,32|t,21),e.assignable=1;const i=Ve(e,t,r,1,0,e.tokenStart);return e.assignable=2,e.finishNode({type:"ConditionalExpression",test:n,consequent:a,alternate:i},o)}function Oe(e,t,r,n,o,a,i,s){const c=8673330&-((131072&t)>0);let l,u;for(e.assignable=2;8388608&e.getToken()&&(l=e.getToken(),u=3840&l,(524288&l&&268435456&i||524288&i&&268435456&l)&&e.report(165),!(u+((8391735===l)<<8)-((c===l)<<12)<=a));)F(e,32|t),s=e.finishNode({type:524288&l||268435456&l?"LogicalExpression":"BinaryExpression",left:s,right:Oe(e,t,r,n,e.tokenStart,u,l,je(e,t,r,0,n,1)),operator:w[255&l]},o);return 1077936155===e.getToken()&&e.report(26),s}function Ge(e,t,r,n,o,a,i){const{tokenStart:s}=e;_(e,32|t,2162700);const c=[];if(1074790415!==e.getToken()){for(;134283267===e.getToken();){const{index:r,tokenStart:n,tokenIndex:o,tokenValue:a}=e,s=e.getToken(),l=nt(e,t);if(J(e,r,o,a)){if(t|=1,128&e.flags)throw new y(n,e.currentLocation,66);if(64&e.flags)throw new y(n,e.currentLocation,9);if(4096&e.flags)throw new y(n,e.currentLocation,15);i?.reportScopeError()}c.push(ye(e,t,l,s,n))}1&t&&(a&&(537079808&~a||e.report(119),36864&~a||e.report(40)),512&e.flags&&e.report(119),256&e.flags&&e.report(118))}for(e.flags=4928^(4928|e.flags),e.destructible=256^(256|e.destructible);1074790415!==e.getToken();)c.push(fe(e,t,r,n,4,{}));return _(e,24&o?32|t:t,1074790415),e.flags&=-4289,1077936155===e.getToken()&&e.report(26),e.finishNode({type:"BlockStatement",body:c},s)}function je(e,t,r,n,o,a){const i=e.tokenStart;return Fe(e,t,r,He(e,t,r,2,0,n,o,a,i),o,0,i)}function Fe(e,t,r,n,o,a,i){if(33619968&~e.getToken()||1&e.flags){if(!(67108864&~e.getToken())){switch(t=131072^(131072|t),e.getToken()){case 67108877:{F(e,8^(262152|t)),16&t&&130===e.getToken()&&"super"===e.tokenValue&&e.report(173),e.assignable=1;const o=Me(e,64|t,r);n=e.finishNode({type:"MemberExpression",object:n,computed:!1,property:o,optional:!1},i);break}case 69271571:{let a=!1;2048&~e.flags||(a=!0,e.flags=2048^(2048|e.flags)),F(e,32|t);const{tokenStart:s}=e,c=Re(e,t,r,o,1,s);_(e,t,20),e.assignable=1,n=e.finishNode({type:"MemberExpression",object:n,computed:!0,property:c,optional:!1},i),a&&(e.flags|=2048);break}case 67174411:{if(!(1024&~e.flags))return e.flags=1024^(1024|e.flags),n;let a=!1;2048&~e.flags||(a=!0,e.flags=2048^(2048|e.flags));const s=tt(e,t,r,o);1&t||!e.options.webcompat?e.assignable=2:e.assignable=4,n=e.finishNode({type:"CallExpression",callee:n,arguments:s,optional:!1},i),a&&(e.flags|=2048);break}case 67108990:F(e,8^(262152|t)),e.flags|=2048,e.assignable=2,n=function(e,t,r,n,o){let a,i=!1;69271571!==e.getToken()&&67174411!==e.getToken()||2048&~e.flags||(i=!0,e.flags=2048^(2048|e.flags));if(69271571===e.getToken()){F(e,32|t);const{tokenStart:i}=e,s=Re(e,t,r,0,1,i);_(e,t,20),e.assignable=2,a=e.finishNode({type:"MemberExpression",object:n,computed:!0,optional:!0,property:s},o)}else if(67174411===e.getToken()){const i=tt(e,t,r,0);1&t||!e.options.webcompat?e.assignable=2:e.assignable=4,a=e.finishNode({type:"CallExpression",callee:n,arguments:i,optional:!0},o)}else{const i=Me(e,t,r);e.assignable=2,a=e.finishNode({type:"MemberExpression",object:n,computed:!1,optional:!0,property:i},o)}i&&(e.flags|=2048);return a}(e,t,r,n,i);break;default:2048&~e.flags||e.report(166),e.assignable=2,n=e.finishNode({type:"TaggedTemplateExpression",tag:n,quasi:67174408===e.getToken()?Ke(e,64|t,r):Ze(e,t)},i)}n=Fe(e,t,r,n,0,1,i)}}else n=function(e,t,r,n){2&e.assignable&&e.report(55);const o=e.getToken();return F(e,t),e.assignable=2,e.finishNode({type:"UpdateExpression",argument:r,operator:w[255&o],prefix:!1},n)}(e,t,n,i);return 0!==a||2048&~e.flags||(e.flags=2048^(2048|e.flags),n=e.finishNode({type:"ChainExpression",expression:n},i)),n}function Me(e,t,r){return 143360&e.getToken()||-2147483528===e.getToken()||-2147483527===e.getToken()||130===e.getToken()||e.report(160),130===e.getToken()?Ct(e,t,r,0):rt(e,t)}function He(e,t,r,n,o,a,i,s,c){if(!(143360&~e.getToken())){switch(e.getToken()){case 209006:return function(e,t,r,n,o,a){o&&(e.destructible|=128),524288&t&&e.report(177);const i=dt(e,t,r);if("ArrowFunctionExpression"===i.type||!(65536&e.getToken())){if(2048&t)throw new y(a,{index:e.startIndex,line:e.startLine,column:e.startColumn},176);if(2&t)throw new y(a,{index:e.startIndex,line:e.startLine,column:e.startColumn},110);if(8192&t&&2048&t)throw new y(a,{index:e.startIndex,line:e.startLine,column:e.startColumn},110);return i}if(8192&t)throw new y(a,{index:e.startIndex,line:e.startLine,column:e.startColumn},31);if(2048&t||2&t&&8&t){if(n)throw new y(a,{index:e.startIndex,line:e.startLine,column:e.startColumn},0);const o=je(e,t,r,0,0,1);return 8391735===e.getToken()&&e.report(33),e.assignable=2,e.finishNode({type:"AwaitExpression",argument:o},a)}if(2&t)throw new y(a,{index:e.startIndex,line:e.startLine,column:e.startColumn},98);return i}(e,t,r,o,i,c);case 241771:return function(e,t,r,n,o,a){if(n&&(e.destructible|=256),1024&t){F(e,32|t),8192&t&&e.report(32),o||e.report(26),22===e.getToken()&&e.report(124);let n=null,i=!1;return 1&e.flags?8391476===e.getToken()&&e.report(30,w[255&e.getToken()]):(i=X(e,32|t,8391476),(77824&e.getToken()||i)&&(n=Ve(e,t,r,1,0,e.tokenStart))),e.assignable=2,e.finishNode({type:"YieldExpression",argument:n,delegate:i},a)}return 1&t&&e.report(97,"yield"),dt(e,t,r)}(e,t,r,i,a,c);case 209005:return function(e,t,r,n,o,a,i,s){const c=e.getToken(),l=rt(e,t),{flags:u}=e;if(!(1&u)){if(86104===e.getToken())return at(e,t,r,1,n,s);if(ee(t,e.getToken()))return o||e.report(0),36864&~e.getToken()||(e.flags|=256),bt(e,t,r,a,s)}return i||67174411!==e.getToken()?10===e.getToken()?(te(e,t,c),i&&e.report(51),36864&~c||(e.flags|=256),gt(e,t,r,e.tokenValue,l,i,a,0,s)):(e.assignable=1,l):Tt(e,t,r,l,a,1,0,u,s)}(e,t,r,i,s,a,o,c)}const{tokenValue:l}=e,u=e.getToken(),p=rt(e,64|t);return 10===e.getToken()?(s||e.report(0),te(e,t,u),36864&~u||(e.flags|=256),gt(e,t,r,l,p,o,a,0,c)):(!(16&t)||32768&t||8192&t||"arguments"!==e.tokenValue||e.report(130),73==(255&u)&&(1&t&&e.report(113),24&n&&e.report(100)),e.assignable=1&t&&!(537079808&~u)?2:1,p)}if(!(134217728&~e.getToken()))return nt(e,t);switch(e.getToken()){case 33619993:case 33619994:return function(e,t,r,n,o,a){n&&e.report(56),o||e.report(0);const i=e.getToken();F(e,32|t);const s=je(e,t,r,0,0,1);return 2&e.assignable&&e.report(55),e.assignable=2,e.finishNode({type:"UpdateExpression",argument:s,operator:w[255&i],prefix:!0},a)}(e,t,r,o,s,c);case 16863276:case 16842798:case 16842799:case 25233968:case 25233969:case 16863275:case 16863277:return function(e,t,r,n,o){n||e.report(0);const{tokenStart:a}=e,i=e.getToken();F(e,32|t);const s=je(e,t,r,0,o,1);var c;return 8391735===e.getToken()&&e.report(33),1&t&&16863276===i&&("Identifier"===s.type?e.report(121):(c=s).property&&"PrivateIdentifier"===c.property.type&&e.report(127)),e.assignable=2,e.finishNode({type:"UnaryExpression",operator:w[255&i],argument:s,prefix:!0},a)}(e,t,r,s,i);case 86104:return at(e,t,r,0,i,c);case 2162700:return function(e,t,r,n,o){const a=ut(e,t,void 0,r,n,o,0,2,0);64&e.destructible&&e.report(63);8&e.destructible&&e.report(62);return a}(e,t,r,a?0:1,i);case 69271571:return function(e,t,r,n,o){const a=it(e,t,void 0,r,n,o,0,2,0);64&e.destructible&&e.report(63);8&e.destructible&&e.report(62);return a}(e,t,r,a?0:1,i);case 67174411:return function(e,t,r,n,o,a,i){e.flags=128^(128|e.flags);const s=e.tokenStart;F(e,262176|t);const c=e.createScopeIfLexical()?.createChildScope(512);if(t=131072^(131072|t),X(e,t,16))return ft(e,t,c,r,[],n,0,i);let l,u=0;e.destructible&=-385;let p=[],d=0,g=0,f=0;const k=e.tokenStart;e.assignable=1;for(;16!==e.getToken();){const{tokenStart:n}=e,i=e.getToken();if(143360&i)c?.addBlockName(t,e.tokenValue,1,0),537079808&~i?36864&~i||(f=1):g=1,l=He(e,t,r,o,0,1,1,1,n),16===e.getToken()||18===e.getToken()?2&e.assignable&&(u|=16,g=1):(1077936155===e.getToken()?g=1:u|=16,l=Fe(e,t,r,l,1,0,n),16!==e.getToken()&&18!==e.getToken()&&(l=Be(e,t,r,1,0,n,l)));else{if(2097152&~i){if(14===i){l=ct(e,t,c,r,16,o,a,0,1,0),16&e.destructible&&e.report(74),g=1,!d||16!==e.getToken()&&18!==e.getToken()||p.push(l),u|=8;break}if(u|=16,l=Ve(e,t,r,1,1,n),!d||16!==e.getToken()&&18!==e.getToken()||p.push(l),18===e.getToken()&&(d||(d=1,p=[l])),d){for(;X(e,32|t,18);)p.push(Ve(e,t,r,1,1,e.tokenStart));e.assignable=2,l=e.finishNode({type:"SequenceExpression",expressions:p},k)}return _(e,t,16),e.destructible=u,e.options.preserveParens?e.finishNode({type:"ParenthesizedExpression",expression:l},s):l}l=2162700===i?ut(e,262144|t,c,r,0,1,0,o,a):it(e,262144|t,c,r,0,1,0,o,a),u|=e.destructible,g=1,e.assignable=2,16!==e.getToken()&&18!==e.getToken()&&(8&u&&e.report(122),l=Fe(e,t,r,l,0,0,n),u|=16,16!==e.getToken()&&18!==e.getToken()&&(l=Be(e,t,r,0,0,n,l)))}if(!d||16!==e.getToken()&&18!==e.getToken()||p.push(l),!X(e,32|t,18))break;if(d||(d=1,p=[l]),16===e.getToken()){u|=8;break}}d&&(e.assignable=2,l=e.finishNode({type:"SequenceExpression",expressions:p},k));_(e,t,16),16&u&&8&u&&e.report(151);if(u|=256&e.destructible?256:128&e.destructible?128:0,10===e.getToken())return 48&u&&e.report(49),2050&t&&128&u&&e.report(31),1025&t&&256&u&&e.report(32),g&&(e.flags|=128),f&&(e.flags|=256),ft(e,t,c,r,d?p:[l],n,0,i);64&u&&e.report(63);8&u&&e.report(144);return e.destructible=256^(256|e.destructible)|u,e.options.preserveParens?e.finishNode({type:"ParenthesizedExpression",expression:l},s):l}(e,64|t,r,a,1,0,c);case 86021:case 86022:case 86023:return function(e,t){const r=e.tokenStart,n=w[255&e.getToken()],o=86023===e.getToken()?null:"true"===n,a={type:"Literal",value:o};e.options.raw&&(a.raw=n);return F(e,t),e.assignable=2,e.finishNode(a,r)}(e,t);case 86111:return function(e,t){const{tokenStart:r}=e;return F(e,t),e.assignable=2,e.finishNode({type:"ThisExpression"},r)}(e,t);case 65540:return function(e,t){const{tokenRaw:r,tokenRegExp:n,tokenValue:o,tokenStart:a}=e;F(e,t),e.assignable=2;const i={type:"Literal",value:o,regex:n};e.options.raw&&(i.raw=r);return e.finishNode(i,a)}(e,t);case 132:case 86094:return function(e,t,r,n,o){let a=null,i=null;const s=xt(e,t,r);t=16384^(16385|t),F(e,t),4096&e.getToken()&&20565!==e.getToken()&&(Z(e,t,e.getToken())&&e.report(118),537079808&~e.getToken()||e.report(119),a=rt(e,t));let c=t;X(e,32|t,20565)?(i=je(e,t,r,0,n,0),c|=512):c=512^(512|c);const l=St(e,c,t,void 0,r,2,0,n);return e.assignable=2,e.finishNode({type:"ClassExpression",id:a,superClass:i,body:l,...e.options.next?{decorators:s}:null},o)}(e,t,r,i,c);case 86109:return function(e,t){const{tokenStart:r}=e;switch(F(e,t),e.getToken()){case 67108990:e.report(167);case 67174411:512&t||e.report(28),e.assignable=2;break;case 69271571:case 67108877:256&t||e.report(29),e.assignable=1;break;default:e.report(30,"super")}return e.finishNode({type:"Super"},r)}(e,t);case 67174409:return Ze(e,t);case 67174408:return Ke(e,t,r);case 86107:return function(e,t,r,n){const{tokenStart:o}=e,a=rt(e,32|t),{tokenStart:i}=e;if(X(e,t,67108877)){if(65536&t&&209029===e.getToken())return e.assignable=2,function(e,t,r,n){const o=rt(e,t);return e.finishNode({type:"MetaProperty",meta:r,property:o},n)}(e,t,a,o);e.report(94)}e.assignable=2,16842752&~e.getToken()||e.report(65,w[255&e.getToken()]);const s=He(e,t,r,2,1,0,n,1,i);t=131072^(131072|t),67108990===e.getToken()&&e.report(168);const c=mt(e,t,r,s,n,i);return e.assignable=2,e.finishNode({type:"NewExpression",callee:c,arguments:67174411===e.getToken()?tt(e,t,r,n):[]},o)}(e,t,r,i);case 134283388:return We(e,t);case 130:return Ct(e,t,r,0);case 86106:return function(e,t,r,n,o,a){let i=rt(e,t);if(67108877===e.getToken())return Je(e,t,i,a);n&&e.report(142);return i=ze(e,t,r,o,a),e.assignable=2,Fe(e,t,r,i,o,0,a)}(e,t,r,o,i,c);case 8456256:if(e.options.jsx)return Lt(e,t,r,0,e.tokenStart);default:if(ee(t,e.getToken()))return dt(e,t,r);e.report(30,w[255&e.getToken()])}}function Je(e,t,r,n){2&t||e.report(169),F(e,t);const o=e.getToken();return 209030!==o&&"meta"!==e.tokenValue?e.report(174):-2147483648&o&&e.report(175),e.assignable=2,e.finishNode({type:"MetaProperty",meta:r,property:rt(e,t)},n)}function ze(e,t,r,n,o){_(e,32|t,67174411),14===e.getToken()&&e.report(143);const a=Ve(e,t,r,1,n,e.tokenStart);let i=null;if(18===e.getToken()){if(_(e,t,18),16!==e.getToken()){i=Ve(e,131072^(131072|t),r,1,n,e.tokenStart)}X(e,t,18)}const s={type:"ImportExpression",source:a,options:i};return _(e,t,16),e.finishNode(s,o)}function Xe(e,t){if(!X(e,t,20579))return[];_(e,t,2162700);const r=[],n=new Set;for(;1074790415!==e.getToken();){const o=e.tokenStart,a=$e(e,t);_(e,t,21);const i=_e(e,t),s="Literal"===a.type?a.value:a.name;n.has(s)&&e.report(145,`${s}`),n.add(s),r.push(e.finishNode({type:"ImportAttribute",key:a,value:i},o)),1074790415!==e.getToken()&&_(e,t,18)}return _(e,t,1074790415),r}function _e(e,t){if(134283267===e.getToken())return nt(e,t);e.report(30,w[255&e.getToken()])}function $e(e,t){return 134283267===e.getToken()?nt(e,t):143360&e.getToken()?rt(e,t):void e.report(30,w[255&e.getToken()])}function Ye(e,t){if(134283267===e.getToken()){return e.tokenValue.isWellFormed()||e.report(171),nt(e,t)}if(143360&e.getToken())return rt(e,t);e.report(30,w[255&e.getToken()])}function We(e,t){const{tokenRaw:r,tokenValue:n,tokenStart:o}=e;F(e,t),e.assignable=2;const a={type:"Literal",value:n,bigint:String(n)};return e.options.raw&&(a.raw=r),e.finishNode(a,o)}function Ze(e,t){e.assignable=2;const{tokenValue:r,tokenRaw:n,tokenStart:o}=e;_(e,t,67174409);const a=[Qe(e,r,n,o,!0)];return e.finishNode({type:"TemplateLiteral",expressions:[],quasis:a},o)}function Ke(e,t,r){t=131072^(131072|t);const{tokenValue:n,tokenRaw:o,tokenStart:a}=e;_(e,-65&t|32,67174408);const i=[Qe(e,n,o,a,!1)],s=[Re(e,-65&t,r,0,1,e.tokenStart)];for(1074790415!==e.getToken()&&e.report(83);67174409!==e.setToken(G(e,t),!0);){const{tokenValue:n,tokenRaw:o,tokenStart:a}=e;_(e,-65&t|32,67174408),i.push(Qe(e,n,o,a,!1)),s.push(Re(e,t,r,0,1,e.tokenStart)),1074790415!==e.getToken()&&e.report(83)}{const{tokenValue:r,tokenRaw:n,tokenStart:o}=e;_(e,t,67174409),i.push(Qe(e,r,n,o,!0))}return e.finishNode({type:"TemplateLiteral",expressions:s,quasis:i},a)}function Qe(e,t,r,n,o){const a=e.finishNode({type:"TemplateElement",value:{cooked:t,raw:r},tail:o},n),i=o?1:2;return e.options.ranges&&(a.start+=1,a.range[0]+=1,a.end-=i,a.range[1]-=i),e.options.loc&&(a.loc.start.column+=1,a.loc.end.column-=i),a}function et(e,t,r){const n=e.tokenStart;_(e,32|(t=131072^(131072|t)),14);const o=Ve(e,t,r,1,0,e.tokenStart);return e.assignable=1,e.finishNode({type:"SpreadElement",argument:o},n)}function tt(e,t,r,n){F(e,32|t);const o=[];if(16===e.getToken())return F(e,64|t),o;for(;16!==e.getToken()&&(14===e.getToken()?o.push(et(e,t,r)):o.push(Ve(e,t,r,1,n,e.tokenStart)),18===e.getToken())&&(F(e,32|t),16!==e.getToken()););return _(e,64|t,16),o}function rt(e,t){const{tokenValue:r,tokenStart:n}=e,o="await"===r&&!(-2147483648&e.getToken());return F(e,t|(o?32:0)),e.finishNode({type:"Identifier",name:r},n)}function nt(e,t){const{tokenValue:r,tokenRaw:n,tokenStart:o}=e;if(134283388===e.getToken())return We(e,t);const a={type:"Literal",value:r};return e.options.raw&&(a.raw=n),F(e,t),e.assignable=2,e.finishNode(a,o)}function ot(e,t,r,n,o,a,i,s,c){F(e,32|t);const l=a?z(e,t,8391476):0;let u,p=null,d=r?e.createScope():void 0;if(67174411===e.getToken())1&i||e.report(39,"Function");else{const n=!(4&o)||8&t&&2&t?64|(s?1024:0)|(l?1024:0):4;W(e,t,e.getToken()),r&&(4&n?r.addVarName(t,e.tokenValue,n):r.addBlockName(t,e.tokenValue,n,o),d=d?.createChildScope(128),i&&2&i&&e.declareUnboundVariable(e.tokenValue)),u=e.getToken(),143360&e.getToken()?p=rt(e,t):e.report(30,w[255&e.getToken()])}{const e=28416;t=(t|e)^e|65536|(s?2048:0)|(l?1024:0)|(l?0:262144)}d=d?.createChildScope(256);const g=ht(e,-524289&t|8192,d,n,0,1),f=524428,k=Ge(e,36864|(t|f)^f,d?.createChildScope(64),n,8,u,d);return e.finishNode({type:"FunctionDeclaration",id:p,params:g,body:k,async:1===s,generator:1===l},c)}function at(e,t,r,n,o,a){F(e,32|t);const i=z(e,t,8391476),s=(n?2048:0)|(i?1024:0);let c,l=null,u=e.createScopeIfLexical();const p=552704;143360&e.getToken()&&(W(e,(t|p)^p|s,e.getToken()),u=u?.createChildScope(128),c=e.getToken(),l=rt(e,t)),t=(t|p)^p|65536|s|(i?0:262144),u=u?.createChildScope(256);const d=ht(e,-524289&t|8192,u,r,o,1),g=Ge(e,36864|-131229&t,u?.createChildScope(64),r,0,c,u);return e.assignable=2,e.finishNode({type:"FunctionExpression",id:l,params:d,body:g,async:1===n,generator:1===i},a)}function it(e,t,r,n,o,a,i,s,c){const{tokenStart:l}=e;F(e,32|t);const u=[];let p=0;for(t=131072^(131072|t);20!==e.getToken();)if(X(e,32|t,18))u.push(null);else{let o;const{tokenStart:l,tokenValue:d}=e,g=e.getToken();if(143360&g)if(o=He(e,t,n,s,0,1,a,1,l),1077936155===e.getToken()){2&e.assignable&&e.report(26),F(e,32|t),r?.addVarOrBlock(t,d,s,c);const u=Ve(e,t,n,1,a,e.tokenStart);o=e.finishNode(i?{type:"AssignmentPattern",left:o,right:u}:{type:"AssignmentExpression",operator:"=",left:o,right:u},l),p|=256&e.destructible?256:128&e.destructible?128:0}else 18===e.getToken()||20===e.getToken()?(2&e.assignable?p|=16:r?.addVarOrBlock(t,d,s,c),p|=256&e.destructible?256:128&e.destructible?128:0):(p|=1&s?32:2&s?0:16,o=Fe(e,t,n,o,a,0,l),18!==e.getToken()&&20!==e.getToken()?(1077936155!==e.getToken()&&(p|=16),o=Be(e,t,n,a,i,l,o)):1077936155!==e.getToken()&&(p|=1&e.assignable?32:16));else 2097152&g?(o=2162700===e.getToken()?ut(e,t,r,n,0,a,i,s,c):it(e,t,r,n,0,a,i,s,c),p|=e.destructible,e.assignable=16&e.destructible?2:1,18===e.getToken()||20===e.getToken()?2&e.assignable&&(p|=16):8&e.destructible?e.report(71):(o=Fe(e,t,n,o,a,0,l),p=2&e.assignable?16:0,18!==e.getToken()&&20!==e.getToken()?o=Be(e,t,n,a,i,l,o):1077936155!==e.getToken()&&(p|=1&e.assignable?32:16))):14===g?(o=ct(e,t,r,n,20,s,c,0,a,i),p|=e.destructible,18!==e.getToken()&&20!==e.getToken()&&e.report(30,w[255&e.getToken()])):(o=je(e,t,n,1,0,1),18!==e.getToken()&&20!==e.getToken()?(o=Be(e,t,n,a,i,l,o),3&s||67174411!==g||(p|=16)):2&e.assignable?p|=16:67174411===g&&(p|=1&e.assignable&&3&s?32:16));if(u.push(o),!X(e,32|t,18))break;if(20===e.getToken())break}_(e,t,20);const d=e.finishNode({type:i?"ArrayPattern":"ArrayExpression",elements:u},l);return!o&&4194304&e.getToken()?st(e,t,n,p,a,i,l,d):(e.destructible=p,d)}function st(e,t,r,n,o,a,i,s){1077936155!==e.getToken()&&e.report(26),F(e,32|t),16&n&&e.report(26),a||$(e,s);const{tokenStart:c}=e,l=Ve(e,t,r,1,o,c);return e.destructible=72^(72|n)|(128&e.destructible?128:0)|(256&e.destructible?256:0),e.finishNode(a?{type:"AssignmentPattern",left:s,right:l}:{type:"AssignmentExpression",left:s,operator:"=",right:l},i)}function ct(e,t,r,n,o,a,i,s,c,l){const{tokenStart:u}=e;F(e,32|t);let p=null,d=0;const{tokenValue:g,tokenStart:f}=e;let k=e.getToken();if(143360&k)e.assignable=1,p=He(e,t,n,a,0,1,c,1,f),k=e.getToken(),p=Fe(e,t,n,p,c,0,f),18!==e.getToken()&&e.getToken()!==o&&(2&e.assignable&&1077936155===e.getToken()&&e.report(71),d|=16,p=Be(e,t,n,c,l,f,p)),2&e.assignable?d|=16:k===o||18===k?r?.addVarOrBlock(t,g,a,i):d|=32,d|=128&e.destructible?128:0;else if(k===o)e.report(41);else{if(!(2097152&k)){d|=32,p=je(e,t,n,1,c,1);const{tokenStart:r}=e,a=e.getToken();return 1077936155===a?(2&e.assignable&&e.report(26),p=Be(e,t,n,c,l,r,p),d|=16):(18===a?d|=16:a!==o&&(p=Be(e,t,n,c,l,r,p)),d|=1&e.assignable?32:16),e.destructible=d,e.getToken()!==o&&18!==e.getToken()&&e.report(161),e.finishNode({type:l?"RestElement":"SpreadElement",argument:p},u)}p=2162700===e.getToken()?ut(e,t,r,n,1,c,l,a,i):it(e,t,r,n,1,c,l,a,i),k=e.getToken(),1077936155!==k&&k!==o&&18!==k?(8&e.destructible&&e.report(71),p=Fe(e,t,n,p,c,0,f),d|=1&e.assignable?0:16,4194304&~e.getToken()?(8388608&~e.getToken()||(p=Oe(e,t,n,1,f,4,k,p)),X(e,32|t,22)&&(p=Pe(e,t,n,p,f)),d|=1&e.assignable?32:16):(1077936155!==e.getToken()&&(d|=16),p=Be(e,t,n,c,l,f,p))):d|=1074790415===o&&1077936155!==k?16:e.destructible}if(e.getToken()!==o)if(1&a&&(d|=s?16:32),X(e,32|t,1077936155)){16&d&&e.report(26),$(e,p);const r=Ve(e,t,n,1,c,e.tokenStart);p=e.finishNode(l?{type:"AssignmentPattern",left:p,right:r}:{type:"AssignmentExpression",left:p,operator:"=",right:r},f),d=16}else d|=16;return e.destructible=d,e.finishNode({type:l?"RestElement":"SpreadElement",argument:p},u)}function lt(e,t,r,n,o,a){const i=11264|(64&n?0:16896);t=98560|((t|i)^i|(8&n?1024:0)|(16&n?2048:0)|(64&n?16384:0));let s=e.createScopeIfLexical(256);const c=function(e,t,r,n,o,a,i){_(e,t,67174411);const s=[];if(e.flags=128^(128|e.flags),16===e.getToken())return 512&o&&e.report(37,"Setter","one",""),F(e,t),s;256&o&&e.report(37,"Getter","no","s");512&o&&14===e.getToken()&&e.report(38);t=131072^(131072|t);let c=0,l=0;for(;18!==e.getToken();){let u=null;const{tokenStart:p}=e;if(143360&e.getToken()?(1&t||(36864&~e.getToken()||(e.flags|=256),537079808&~e.getToken()||(e.flags|=512)),u=Nt(e,t,r,1|o,0)):(2162700===e.getToken()?u=ut(e,t,r,n,1,i,1,a,0):69271571===e.getToken()?u=it(e,t,r,n,1,i,1,a,0):14===e.getToken()&&(u=ct(e,t,r,n,16,a,0,0,i,1)),l=1,48&e.destructible&&e.report(50)),1077936155===e.getToken()){F(e,32|t),l=1;const r=Ve(e,t,n,1,0,e.tokenStart);u=e.finishNode({type:"AssignmentPattern",left:u,right:r},p)}if(c++,s.push(u),!X(e,t,18))break;if(16===e.getToken())break}512&o&&1!==c&&e.report(37,"Setter","one","");r?.reportScopeError(),l&&(e.flags|=128);return _(e,t,16),s}(e,-524289&t|8192,s,r,n,1,o);s=s?.createChildScope(64);const l=Ge(e,36864|-655373&t,s,r,0,void 0,s?.parent);return e.finishNode({type:"FunctionExpression",params:c,body:l,async:(16&n)>0,generator:(8&n)>0,id:null},a)}function ut(e,t,r,n,o,a,i,s,c){const{tokenStart:l}=e;F(e,t);const u=[];let p=0,d=0;for(t=131072^(131072|t);1074790415!==e.getToken();){const{tokenValue:o,tokenStart:l}=e,g=e.getToken();if(14===g)u.push(ct(e,t,r,n,1074790415,s,c,0,a,i));else{let f,k=0,h=null;if(143360&e.getToken()||-2147483528===e.getToken()||-2147483527===e.getToken())if(-2147483527===e.getToken()&&(p|=16),h=rt(e,t),18===e.getToken()||1074790415===e.getToken()||1077936155===e.getToken())if(k|=4,1&t&&!(537079808&~g)?p|=16:Y(e,t,s,g,0),r?.addVarOrBlock(t,o,s,c),X(e,32|t,1077936155)){p|=8;const r=Ve(e,t,n,1,a,e.tokenStart);p|=256&e.destructible?256:128&e.destructible?128:0,f=e.finishNode({type:"AssignmentPattern",left:e.cloneIdentifier(h),right:r},l)}else p|=(209006===g?128:0)|(-2147483528===g?16:0),f=e.cloneIdentifier(h);else if(X(e,32|t,21)){const{tokenStart:l}=e;if("__proto__"===o&&d++,143360&e.getToken()){const o=e.getToken(),u=e.tokenValue;f=He(e,t,n,s,0,1,a,1,l);const d=e.getToken();f=Fe(e,t,n,f,a,0,l),18===e.getToken()||1074790415===e.getToken()?1077936155===d||1074790415===d||18===d?(p|=128&e.destructible?128:0,2&e.assignable?p|=16:143360&~o||r?.addVarOrBlock(t,u,s,c)):p|=1&e.assignable?32:16:4194304&~e.getToken()?(p|=16,8388608&~e.getToken()||(f=Oe(e,t,n,1,l,4,d,f)),X(e,32|t,22)&&(f=Pe(e,t,n,f,l))):(2&e.assignable?p|=16:1077936155!==d?p|=32:r?.addVarOrBlock(t,u,s,c),f=Be(e,t,n,a,i,l,f))}else 2097152&~e.getToken()?(f=je(e,t,n,1,a,1),p|=1&e.assignable?32:16,18===e.getToken()||1074790415===e.getToken()?2&e.assignable&&(p|=16):(f=Fe(e,t,n,f,a,0,l),p=2&e.assignable?16:0,18!==e.getToken()&&1074790415!==g&&(1077936155!==e.getToken()&&(p|=16),f=Be(e,t,n,a,i,l,f)))):(f=69271571===e.getToken()?it(e,t,r,n,0,a,i,s,c):ut(e,t,r,n,0,a,i,s,c),p=e.destructible,e.assignable=16&p?2:1,18===e.getToken()||1074790415===e.getToken()?2&e.assignable&&(p|=16):8&e.destructible?e.report(71):(f=Fe(e,t,n,f,a,0,l),p=2&e.assignable?16:0,4194304&~e.getToken()?(8388608&~e.getToken()||(f=Oe(e,t,n,1,l,4,g,f)),X(e,32|t,22)&&(f=Pe(e,t,n,f,l)),p|=1&e.assignable?32:16):f=Ue(e,t,n,a,i,l,f)))}else 69271571===e.getToken()?(p|=16,209005===g&&(k|=16),k|=2|(209008===g?256:209009===g?512:1),h=pt(e,t,n,a),p|=e.assignable,f=lt(e,t,n,k,a,e.tokenStart)):143360&e.getToken()?(p|=16,-2147483528===g&&e.report(95),209005===g?(1&e.flags&&e.report(132),k|=17):209008===g?k|=256:209009===g?k|=512:e.report(0),h=rt(e,t),f=lt(e,t,n,k,a,e.tokenStart)):67174411===e.getToken()?(p|=16,k|=1,f=lt(e,t,n,k,a,e.tokenStart)):8391476===e.getToken()?(p|=16,209008===g?e.report(42):209009===g?e.report(43):209005!==g&&e.report(30,w[52]),F(e,t),k|=9|(209005===g?16:0),143360&e.getToken()?h=rt(e,t):134217728&~e.getToken()?69271571===e.getToken()?(k|=2,h=pt(e,t,n,a),p|=e.assignable):e.report(30,w[255&e.getToken()]):h=nt(e,t),f=lt(e,t,n,k,a,e.tokenStart)):134217728&~e.getToken()?e.report(133):(209005===g&&(k|=16),k|=209008===g?256:209009===g?512:1,p|=16,h=nt(e,t),f=lt(e,t,n,k,a,e.tokenStart));else if(134217728&~e.getToken())if(69271571===e.getToken())if(h=pt(e,t,n,a),p|=256&e.destructible?256:0,k|=2,21===e.getToken()){F(e,32|t);const{tokenStart:o,tokenValue:l}=e,u=e.getToken();if(143360&e.getToken()){f=He(e,t,n,s,0,1,a,1,o);const d=e.getToken();f=Fe(e,t,n,f,a,0,o),4194304&~e.getToken()?18===e.getToken()||1074790415===e.getToken()?1077936155===d||1074790415===d||18===d?2&e.assignable?p|=16:143360&~u||r?.addVarOrBlock(t,l,s,c):p|=1&e.assignable?32:16:(p|=16,f=Be(e,t,n,a,i,o,f)):(p|=1&e.assignable?1077936155===d?0:32:16,f=Ue(e,t,n,a,i,o,f))}else 2097152&~e.getToken()?(f=je(e,t,n,1,0,1),p|=1&e.assignable?32:16,18===e.getToken()||1074790415===e.getToken()?2&e.assignable&&(p|=16):(f=Fe(e,t,n,f,a,0,o),p=1&e.assignable?0:16,18!==e.getToken()&&1074790415!==e.getToken()&&(1077936155!==e.getToken()&&(p|=16),f=Be(e,t,n,a,i,o,f)))):(f=69271571===e.getToken()?it(e,t,r,n,0,a,i,s,c):ut(e,t,r,n,0,a,i,s,c),p=e.destructible,e.assignable=16&p?2:1,18===e.getToken()||1074790415===e.getToken()?2&e.assignable&&(p|=16):8&p?e.report(62):(f=Fe(e,t,n,f,a,0,o),p=2&e.assignable?16|p:0,4194304&~e.getToken()?(8388608&~e.getToken()||(f=Oe(e,t,n,1,o,4,g,f)),X(e,32|t,22)&&(f=Pe(e,t,n,f,o)),p|=1&e.assignable?32:16):(1077936155!==e.getToken()&&(p|=16),f=Ue(e,t,n,a,i,o,f))))}else 67174411===e.getToken()?(k|=1,f=lt(e,t,n,k,a,e.tokenStart),p=16):e.report(44);else if(8391476===g)if(_(e,32|t,8391476),k|=8,143360&e.getToken()){const r=e.getToken();if(h=rt(e,t),k|=1,67174411!==e.getToken())throw new y(e.tokenStart,e.currentLocation,209005===r?46:209008===r||209009===e.getToken()?45:47,w[255&r]);p|=16,f=lt(e,t,n,k,a,e.tokenStart)}else 134217728&~e.getToken()?69271571===e.getToken()?(p|=16,k|=3,h=pt(e,t,n,a),f=lt(e,t,n,k,a,e.tokenStart)):e.report(126):(p|=16,h=nt(e,t),k|=1,f=lt(e,t,n,k,a,e.tokenStart));else e.report(30,w[255&g]);else if(h=nt(e,t),21===e.getToken()){_(e,32|t,21);const{tokenStart:l}=e;if("__proto__"===o&&d++,143360&e.getToken()){f=He(e,t,n,s,0,1,a,1,l);const{tokenValue:o}=e,u=e.getToken();f=Fe(e,t,n,f,a,0,l),18===e.getToken()||1074790415===e.getToken()?1077936155===u||1074790415===u||18===u?2&e.assignable?p|=16:r?.addVarOrBlock(t,o,s,c):p|=1&e.assignable?32:16:1077936155===e.getToken()?(2&e.assignable&&(p|=16),f=Be(e,t,n,a,i,l,f)):(p|=16,f=Be(e,t,n,a,i,l,f))}else 2097152&~e.getToken()?(f=je(e,t,n,1,0,1),p|=1&e.assignable?32:16,18===e.getToken()||1074790415===e.getToken()?2&e.assignable&&(p|=16):(f=Fe(e,t,n,f,a,0,l),p=1&e.assignable?0:16,18!==e.getToken()&&1074790415!==e.getToken()&&(1077936155!==e.getToken()&&(p|=16),f=Be(e,t,n,a,i,l,f)))):(f=69271571===e.getToken()?it(e,t,r,n,0,a,i,s,c):ut(e,t,r,n,0,a,i,s,c),p=e.destructible,e.assignable=16&p?2:1,18===e.getToken()||1074790415===e.getToken()?2&e.assignable&&(p|=16):8&~e.destructible&&(f=Fe(e,t,n,f,a,0,l),p=2&e.assignable?16:0,4194304&~e.getToken()?(8388608&~e.getToken()||(f=Oe(e,t,n,1,l,4,g,f)),X(e,32|t,22)&&(f=Pe(e,t,n,f,l)),p|=1&e.assignable?32:16):f=Ue(e,t,n,a,i,l,f)))}else 67174411===e.getToken()?(k|=1,f=lt(e,t,n,k,a,e.tokenStart),p=16):e.report(134);p|=128&e.destructible?128:0,e.destructible=p,u.push(e.finishNode({type:"Property",key:h,value:f,kind:768&k?512&k?"set":"get":"init",computed:(2&k)>0,method:(1&k)>0,shorthand:(4&k)>0},l))}if(p|=e.destructible,18!==e.getToken())break;F(e,t)}_(e,t,1074790415),d>1&&(p|=64);const g=e.finishNode({type:i?"ObjectPattern":"ObjectExpression",properties:u},l);return!o&&4194304&e.getToken()?st(e,t,n,p,a,i,l,g):(e.destructible=p,g)}function pt(e,t,r,n){F(e,32|t);const o=Ve(e,131072^(131072|t),r,1,n,e.tokenStart);return _(e,t,20),o}function dt(e,t,r){const{tokenStart:n}=e,{tokenValue:o}=e;let a=0,i=0;537079808&~e.getToken()?36864&~e.getToken()||(i=1):a=1;const s=rt(e,t);if(e.assignable=1,10===e.getToken()){const c=e.options.lexical?ue(e,t,o):void 0;return a&&(e.flags|=128),i&&(e.flags|=256),kt(e,t,c,r,[s],0,n)}return s}function gt(e,t,r,n,o,a,i,s,c){i||e.report(57),a&&e.report(51),e.flags&=-129;return kt(e,t,e.options.lexical?ue(e,t,n):void 0,r,[o],s,c)}function ft(e,t,r,n,o,a,i,s){a||e.report(57);for(let t=0;t<o.length;++t)$(e,o[t]);return kt(e,t,r,n,o,i,s)}function kt(e,t,r,n,o,a,i){1&e.flags&&e.report(48),_(e,32|t,10);const s=535552;t=(t|s)^s|(a?2048:0);const c=2162700!==e.getToken();let l;if(r?.reportScopeError(),c)e.flags=4928^(4928|e.flags),l=Ve(e,t,n,1,0,e.tokenStart);else{r=r?.createChildScope(64);const o=131084;switch(l=Ge(e,(t|o)^o|4096,r,n,16,void 0,void 0),e.getToken()){case 69271571:1&e.flags||e.report(116);break;case 67108877:case 67174409:case 22:e.report(117);case 67174411:1&e.flags||e.report(116),e.flags|=1024}8388608&~e.getToken()||1&e.flags||e.report(30,w[255&e.getToken()]),33619968&~e.getToken()||e.report(125)}return e.assignable=2,e.finishNode({type:"ArrowFunctionExpression",params:o,body:l,async:1===a,expression:c,generator:!1},i)}function ht(e,t,r,n,o,a){_(e,t,67174411),e.flags=128^(128|e.flags);const i=[];if(X(e,t,16))return i;t=131072^(131072|t);let s=0;for(;18!==e.getToken();){let c;const{tokenStart:l}=e,u=e.getToken();if(143360&u?(1&t||(36864&~u||(e.flags|=256),537079808&~u||(e.flags|=512)),c=Nt(e,t,r,1|a,0)):(2162700===u?c=ut(e,t,r,n,1,o,1,a,0):69271571===u?c=it(e,t,r,n,1,o,1,a,0):14===u?c=ct(e,t,r,n,16,a,0,0,o,1):e.report(30,w[255&u]),s=1,48&e.destructible&&e.report(50)),1077936155===e.getToken()){F(e,32|t),s=1;const r=Ve(e,t,n,1,o,e.tokenStart);c=e.finishNode({type:"AssignmentPattern",left:c,right:r},l)}if(i.push(c),!X(e,t,18))break;if(16===e.getToken())break}return s&&(e.flags|=128),(s||1&t)&&r?.reportScopeError(),_(e,t,16),i}function mt(e,t,r,n,o,a){const i=e.getToken();if(67108864&i){if(67108877===i){F(e,262144|t),e.assignable=1;const o=Me(e,t,r);return mt(e,t,r,e.finishNode({type:"MemberExpression",object:n,computed:!1,property:o,optional:!1},a),0,a)}if(69271571===i){F(e,32|t);const{tokenStart:i}=e,s=Re(e,t,r,o,1,i);return _(e,t,20),e.assignable=1,mt(e,t,r,e.finishNode({type:"MemberExpression",object:n,computed:!0,property:s,optional:!1},a),0,a)}if(67174408===i||67174409===i)return e.assignable=2,mt(e,t,r,e.finishNode({type:"TaggedTemplateExpression",tag:n,quasi:67174408===e.getToken()?Ke(e,64|t,r):Ze(e,64|t)},a),0,a)}return n}function bt(e,t,r,n,o){return 209006===e.getToken()&&e.report(31),1025&t&&241771===e.getToken()&&e.report(32),te(e,t,e.getToken()),36864&~e.getToken()||(e.flags|=256),gt(e,-524289&t|2048,r,e.tokenValue,rt(e,t),0,n,1,o)}function Tt(e,t,r,n,o,a,i,s,c){F(e,32|t);const l=e.createScopeIfLexical()?.createChildScope(512);if(X(e,t=131072^(131072|t),16))return 10===e.getToken()?(1&s&&e.report(48),ft(e,t,l,r,[],o,1,c)):(1&t||!e.options.webcompat?e.assignable=2:e.assignable=4,e.finishNode({type:"CallExpression",callee:n,arguments:[],optional:!1},c));let u=0,p=null,d=0;e.destructible=384^(384|e.destructible);const g=[];for(;16!==e.getToken();){const{tokenStart:o}=e,s=e.getToken();if(143360&s)l?.addBlockName(t,e.tokenValue,a,0),537079808&~s?36864&~s||(e.flags|=256):e.flags|=512,p=He(e,t,r,a,0,1,1,1,o),16===e.getToken()||18===e.getToken()?2&e.assignable&&(u|=16,d=1):(1077936155===e.getToken()?d=1:u|=16,p=Fe(e,t,r,p,1,0,o),16!==e.getToken()&&18!==e.getToken()&&(p=Be(e,t,r,1,0,o,p)));else if(2097152&s)p=2162700===s?ut(e,t,l,r,0,1,0,a,i):it(e,t,l,r,0,1,0,a,i),u|=e.destructible,d=1,16!==e.getToken()&&18!==e.getToken()&&(8&u&&e.report(122),p=Fe(e,t,r,p,0,0,o),u|=16,8388608&~e.getToken()||(p=Oe(e,t,r,1,c,4,s,p)),X(e,32|t,22)&&(p=Pe(e,t,r,p,c)));else{if(14!==s){for(p=Ve(e,t,r,1,0,o),u=0,g.push(p);X(e,32|t,18);)g.push(Ve(e,t,r,1,0,o));return u|=e.assignable,_(e,t,16),e.destructible=16|u,1&t||!e.options.webcompat?e.assignable=2:e.assignable=4,e.finishNode({type:"CallExpression",callee:n,arguments:g,optional:!1},c)}p=ct(e,t,l,r,16,a,i,1,1,0),u|=(16===e.getToken()?0:16)|e.destructible,d=1}if(g.push(p),!X(e,32|t,18))break}return _(e,t,16),u|=256&e.destructible?256:128&e.destructible?128:0,10===e.getToken()?(48&u&&e.report(27),(1&e.flags||1&s)&&e.report(48),128&u&&e.report(31),1025&t&&256&u&&e.report(32),d&&(e.flags|=128),ft(e,2048|t,l,r,g,o,1,c)):(64&u&&e.report(63),8&u&&e.report(62),1&t||!e.options.webcompat?e.assignable=2:e.assignable=4,e.finishNode({type:"CallExpression",callee:n,arguments:g,optional:!1},c))}function yt(e,t,r,n,o){let a,i;e.leadingDecorators.decorators.length?(132===e.getToken()&&e.report(30,"@"),a=e.leadingDecorators.start,i=[...e.leadingDecorators.decorators],e.leadingDecorators.decorators.length=0):(a=e.tokenStart,i=xt(e,t,n)),F(e,t=16384^(16385|t));let s=null,c=null;const{tokenValue:l}=e;4096&e.getToken()&&20565!==e.getToken()?(Z(e,t,e.getToken())&&e.report(118),537079808&~e.getToken()||e.report(119),r&&(r.addBlockName(t,l,32,0),o&&2&o&&e.declareUnboundVariable(l)),s=rt(e,t)):1&o||e.report(39,"Class");let u=t;X(e,32|t,20565)?(c=je(e,t,n,0,0,0),u|=512):u=512^(512|u);const p=St(e,u,t,r,n,2,8,0);return e.finishNode({type:"ClassDeclaration",id:s,superClass:c,body:p,...e.options.next?{decorators:i}:null},a)}function xt(e,t,r){const n=[];if(e.options.next)for(;132===e.getToken();)n.push(wt(e,t,r));return n}function wt(e,t,r){const n=e.tokenStart;F(e,32|t);const o=e.tokenStart;let a=He(e,t,r,2,0,1,0,1,n);return a=Fe(e,t,r,a,0,0,o),e.finishNode({type:"Decorator",expression:a},n)}function St(e,t,r,n,o,a,i,s){const{tokenStart:c}=e,l=e.createPrivateScopeIfLexical(o);_(e,32|t,2162700);const u=655360;t=(t|u)^u;const p=32&e.flags;e.flags=32^(32|e.flags);const d=[];for(;1074790415!==e.getToken();){const o=e.tokenStart,i=xt(e,t,l);i.length>0&&"constructor"===e.tokenValue&&e.report(109),1074790415===e.getToken()&&e.report(108),X(e,t,1074790417)?i.length>0&&e.report(120):d.push(vt(e,t,n,l,r,a,i,0,s,i.length>0?o:e.tokenStart))}return _(e,8&i?32|t:t,1074790415),l?.validatePrivateIdentifierRefs(),e.flags=-33&e.flags|p,e.finishNode({type:"ClassBody",body:d},c)}function vt(e,t,r,n,o,a,i,s,c,l){let u=s?32:0,p=null;const d=e.getToken();if(176128&d||-2147483528===d)switch(p=rt(e,t),d){case 36970:if(!s&&67174411!==e.getToken()&&1048576&~e.getToken()&&1077936155!==e.getToken())return vt(e,t,r,n,o,a,i,1,c,l);break;case 209005:if(67174411!==e.getToken()&&!(1&e.flags)){if(!(1073741824&~e.getToken()))return qt(e,t,n,p,u,i,l);u|=16|(z(e,t,8391476)?8:0)}break;case 209008:if(67174411!==e.getToken()){if(!(1073741824&~e.getToken()))return qt(e,t,n,p,u,i,l);u|=256}break;case 209009:if(67174411!==e.getToken()){if(!(1073741824&~e.getToken()))return qt(e,t,n,p,u,i,l);u|=512}break;case 12402:if(67174411!==e.getToken()&&!(1&e.flags)){if(!(1073741824&~e.getToken()))return qt(e,t,n,p,u,i,l);e.options.next&&(u|=1024)}}else if(69271571===d)u|=2,p=pt(e,o,n,c);else if(134217728&~d)if(8391476===d)u|=8,F(e,t);else if(130===e.getToken())u|=8192,p=Ct(e,16|t,n,768);else if(1073741824&~e.getToken()){if(s&&2162700===d)return function(e,t,r,n,o){return r=r?.createChildScope(),he(e,t=592128|5764^(5764|t),r,n,{},o,"StaticBlock")}(e,16|t,r,n,l);-2147483527===d?(p=rt(e,t),67174411!==e.getToken()&&e.report(30,w[255&e.getToken()])):e.report(30,w[255&e.getToken()])}else u|=128;else p=nt(e,t);if(1816&u&&(143360&e.getToken()||-2147483528===e.getToken()||-2147483527===e.getToken()?p=rt(e,t):134217728&~e.getToken()?69271571===e.getToken()?(u|=2,p=pt(e,t,n,0)):130===e.getToken()?(u|=8192,p=Ct(e,t,n,u)):e.report(135):p=nt(e,t)),2&u||("constructor"===e.tokenValue?(1073741824&~e.getToken()?32&u||67174411!==e.getToken()||(920&u?e.report(53,"accessor"):512&t||(32&e.flags?e.report(54):e.flags|=32)):e.report(129),u|=64):!(8192&u)&&32&u&&"prototype"===e.tokenValue&&e.report(52)),1024&u||67174411!==e.getToken()&&!(768&u))return qt(e,t,n,p,u,i,l);const g=lt(e,16|t,n,u,c,e.tokenStart);return e.finishNode({type:"MethodDefinition",kind:!(32&u)&&64&u?"constructor":256&u?"get":512&u?"set":"method",static:(32&u)>0,computed:(2&u)>0,key:p,value:g,...e.options.next?{decorators:i}:null},l)}function Ct(e,t,r,n){const{tokenStart:o}=e;F(e,t);const{tokenValue:a}=e;return"constructor"===a&&e.report(128),e.options.lexical&&(r||e.report(4,a),n?r.addPrivateIdentifier(a,n):r.addPrivateIdentifierRef(a)),F(e,t),e.finishNode({type:"PrivateIdentifier",name:a},o)}function qt(e,t,r,n,o,a,i){let s=null;if(8&o&&e.report(0),1077936155===e.getToken()){F(e,32|t);const{tokenStart:n}=e;537079927===e.getToken()&&e.report(119);const a=11264|(64&o?0:16896);s=He(e,16|(t=65792|((t|a)^a|(8&o?1024:0)|(16&o?2048:0)|(64&o?16384:0))),r,2,0,1,0,1,n),!(1073741824&~e.getToken())&&4194304&~e.getToken()||(s=Fe(e,16|t,r,s,0,0,n),s=Be(e,16|t,r,0,0,n,s))}return H(e,t),e.finishNode({type:1024&o?"AccessorProperty":"PropertyDefinition",key:n,value:s,static:(32&o)>0,computed:(2&o)>0,...e.options.next?{decorators:a}:null},i)}function Et(e,t,r,n,o,a){if(143360&e.getToken()||!(1&t)&&-2147483527===e.getToken())return Nt(e,t,r,o,a);2097152&~e.getToken()&&e.report(30,w[255&e.getToken()]);const i=69271571===e.getToken()?it(e,t,r,n,1,0,1,o,a):ut(e,t,r,n,1,0,1,o,a);return 16&e.destructible&&e.report(50),32&e.destructible&&e.report(50),i}function Nt(e,t,r,n,o){const a=e.getToken();1&t&&(537079808&~a?36864&~a&&-2147483527!==a||e.report(118):e.report(119)),20480&~a||e.report(102),241771===a&&(1024&t&&e.report(32),2&t&&e.report(111)),73==(255&a)&&24&n&&e.report(100),209006===a&&(2048&t&&e.report(176),2&t&&e.report(110));const{tokenValue:i,tokenStart:s}=e;return F(e,t),r?.addVarOrBlock(t,i,n,o),e.finishNode({type:"Identifier",name:i},s)}function Lt(e,t,r,n,o){if(n||_(e,t,8456256),8390721===e.getToken()){const a=function(e,t){return ie(e),e.finishNode({type:"JSXOpeningFragment"},t)}(e,o),[i,s]=function(e,t,r,n){const o=[];for(;;){const a=It(e,t,r,n);if("JSXClosingFragment"===a.type)return[o,a];o.push(a)}}(e,t,r,n);return e.finishNode({type:"JSXFragment",openingFragment:a,children:i,closingFragment:s},o)}8457014===e.getToken()&&e.report(30,w[255&e.getToken()]);let a=null,i=[];const s=function(e,t,r,n,o){143360&~e.getToken()&&4096&~e.getToken()&&e.report(0);const a=Dt(e,t),i=function(e,t,r){const n=[];for(;8457014!==e.getToken()&&8390721!==e.getToken()&&1048576!==e.getToken();)n.push(Bt(e,t,r));return n}(e,t,r),s=8457014===e.getToken();s&&_(e,t,8457014);8390721!==e.getToken()&&e.report(25,w[65]);n||!s?ie(e):F(e,t);return e.finishNode({type:"JSXOpeningElement",name:a,attributes:i,selfClosing:s},o)}(e,t,r,n,o);if(!s.selfClosing){[i,a]=function(e,t,r,n){const o=[];for(;;){const a=At(e,t,r,n);if("JSXClosingElement"===a.type)return[o,a];o.push(a)}}(e,t,r,n);const o=Q(a.name);Q(s.name)!==o&&e.report(155,o)}return e.finishNode({type:"JSXElement",children:i,openingElement:s,closingElement:a},o)}function At(e,t,r,n){if(137===e.getToken())return Vt(e,t);if(2162700===e.getToken())return Pt(e,t,r,1,0);if(8456256===e.getToken()){const{tokenStart:o}=e;return F(e,t),8457014===e.getToken()?function(e,t,r,n){_(e,t,8457014);const o=Dt(e,t);return 8390721!==e.getToken()&&e.report(25,w[65]),r?ie(e):F(e,t),e.finishNode({type:"JSXClosingElement",name:o},n)}(e,t,n,o):Lt(e,t,r,1,o)}e.report(0)}function It(e,t,r,n){if(137===e.getToken())return Vt(e,t);if(2162700===e.getToken())return Pt(e,t,r,1,0);if(8456256===e.getToken()){const{tokenStart:o}=e;return F(e,t),8457014===e.getToken()?function(e,t,r,n){return _(e,t,8457014),8390721!==e.getToken()&&e.report(25,w[65]),r?ie(e):F(e,t),e.finishNode({type:"JSXClosingFragment"},n)}(e,t,n,o):Lt(e,t,r,1,o)}e.report(0)}function Vt(e,t){const r=e.tokenStart;F(e,t);const n={type:"JSXText",value:e.tokenValue};return e.options.raw&&(n.raw=e.tokenRaw),e.finishNode(n,r)}function Dt(e,t){const{tokenStart:r}=e;se(e);let n=Ot(e,t);if(21===e.getToken())return Ut(e,t,n,r);for(;X(e,t,67108877);)se(e),n=Rt(e,t,n,r);return n}function Rt(e,t,r,n){const o=Ot(e,t);return e.finishNode({type:"JSXMemberExpression",object:r,property:o},n)}function Bt(e,t,r){const{tokenStart:n}=e;if(2162700===e.getToken())return function(e,t,r){const n=e.tokenStart;F(e,t),_(e,t,14);const o=Ve(e,t,r,1,0,e.tokenStart);return _(e,t,1074790415),e.finishNode({type:"JSXSpreadAttribute",argument:o},n)}(e,t,r);se(e);let o=null,a=Ot(e,t);if(21===e.getToken()&&(a=Ut(e,t,a,n)),1077936155===e.getToken()){switch(ae(e,t)){case 134283267:o=nt(e,t);break;case 8456256:o=Lt(e,t,r,0,e.tokenStart);break;case 2162700:o=Pt(e,t,r,0,1);break;default:e.report(154)}}return e.finishNode({type:"JSXAttribute",value:o,name:a},n)}function Ut(e,t,r,n){_(e,t,21);const o=Ot(e,t);return e.finishNode({type:"JSXNamespacedName",namespace:r,name:o},n)}function Pt(e,t,r,n,o){const{tokenStart:a}=e;F(e,32|t);const{tokenStart:i}=e;if(14===e.getToken())return function(e,t,r,n){_(e,t,14);const o=Ve(e,t,r,1,0,e.tokenStart);return _(e,t,1074790415),e.finishNode({type:"JSXSpreadChild",expression:o},n)}(e,t,r,a);let s=null;return 1074790415===e.getToken()?(o&&e.report(157),s=function(e,t){return e.finishNode({type:"JSXEmptyExpression"},t,e.tokenStart)}(e,{index:e.startIndex,line:e.startLine,column:e.startColumn})):s=Ve(e,t,r,1,0,i),1074790415!==e.getToken()&&e.report(25,w[15]),n?ie(e):F(e,t),e.finishNode({type:"JSXExpressionContainer",expression:s},a)}function Ot(e,t){const r=e.tokenStart;143360&e.getToken()||e.report(30,w[255&e.getToken()]);const{tokenValue:n}=e;return F(e,t),e.finishNode({type:"JSXIdentifier",name:n},r)}e.isParseError=e=>e instanceof y,e.parse=function(e,t){return de(e,t)},e.parseModule=function(e,t){return de(e,{...t,sourceType:"module"})},e.parseScript=function(e,t){return de(e,{...t,sourceType:"script"})},e.version="7.1.0"});

},{}]},{},[1]);
