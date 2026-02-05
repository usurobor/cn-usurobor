"use strict";
var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_exceptions.js
var require_caml_exceptions = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_exceptions.js"(exports2, module2) {
    "use strict";
    var $$Map = {};
    var idMap = {};
    function fresh(str) {
      const v = idMap[str];
      const id = v == null ? 1 : v + 1 | 0;
      idMap[str] = id;
      return id;
    }
    function create(str) {
      const id = fresh(str);
      return str + ("/" + id);
    }
    function caml_is_extension(e) {
      if (e == null) {
        return false;
      } else {
        return typeof e.MEL_EXN_ID === "string";
      }
    }
    function caml_exn_slot_name(x) {
      return x.MEL_EXN_ID;
    }
    var caml_exn_slot_id = (function(x) {
      if (x.MEL_EXN_ID != null) {
        var parts = x.MEL_EXN_ID.split("/");
        if (parts.length > 1) {
          return Number(parts[parts.length - 1]);
        } else {
          return -1;
        }
      } else {
        return -1;
      }
    });
    module2.exports = {
      $$Map,
      idMap,
      fresh,
      create,
      caml_is_extension,
      caml_exn_slot_name,
      caml_exn_slot_id
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_js_exceptions.js
var require_caml_js_exceptions = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_js_exceptions.js"(exports2, module2) {
    "use strict";
    var Caml_exceptions = require_caml_exceptions();
    var MelangeError = (function MelangeError2(message, payload) {
      var cause = payload != null ? payload : { MEL_EXN_ID: message };
      var _this = Error.call(this, message, { cause });
      if (_this.cause == null) {
        Object.defineProperty(_this, "cause", {
          configurable: true,
          enumerable: false,
          writable: true,
          value: cause
        });
      }
      Object.defineProperty(_this, "name", {
        configurable: true,
        enumerable: false,
        writable: true,
        value: "MelangeError"
      });
      Object.assign(_this, cause);
      return _this;
    });
    MelangeError.prototype = Error.prototype;
    function internalAnyToExn(any) {
      if (Caml_exceptions.caml_is_extension(any)) {
        return any;
      }
      const exn = new MelangeError("Js__Js_exn.Error/1");
      exn["_1"] = any;
      return exn;
    }
    var internalToOCamlException = internalAnyToExn;
    module2.exports = {
      MelangeError,
      internalAnyToExn,
      internalToOCamlException
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_array.js
var require_caml_array = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_array.js"(exports2, module2) {
    "use strict";
    var Caml_js_exceptions = require_caml_js_exceptions();
    function sub(x, offset, len2) {
      const result = new Array(len2);
      let j = 0;
      let i = offset;
      while (j < len2) {
        result[j] = x[i];
        j = j + 1 | 0;
        i = i + 1 | 0;
      }
      ;
      return result;
    }
    function len(_acc, _l) {
      while (true) {
        const l = _l;
        const acc = _acc;
        if (!l) {
          return acc;
        }
        _l = l.tl;
        _acc = l.hd.length + acc | 0;
        continue;
      }
      ;
    }
    function fill(arr, _i, _l) {
      while (true) {
        const l = _l;
        const i = _i;
        if (!l) {
          return;
        }
        const x = l.hd;
        const l$1 = x.length;
        let k = i;
        let j = 0;
        while (j < l$1) {
          arr[k] = x[j];
          k = k + 1 | 0;
          j = j + 1 | 0;
        }
        ;
        _l = l.tl;
        _i = k;
        continue;
      }
      ;
    }
    function concat(l) {
      const v = len(0, l);
      const result = new Array(v);
      fill(result, 0, l);
      return result;
    }
    function set(xs, index, newval) {
      if (index < 0 || index >= xs.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      xs[index] = newval;
    }
    function get(xs, index) {
      if (index < 0 || index >= xs.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      return xs[index];
    }
    function make(len2, init) {
      const b = new Array(len2);
      for (let i = 0; i < len2; ++i) {
        b[i] = init;
      }
      return b;
    }
    function make_float(len2) {
      const b = new Array(len2);
      for (let i = 0; i < len2; ++i) {
        b[i] = 0;
      }
      return b;
    }
    function blit(a1, i1, a2, i2, len2) {
      if (i2 <= i1) {
        for (let j = 0; j < len2; ++j) {
          a2[j + i2 | 0] = a1[j + i1 | 0];
        }
        return;
      }
      for (let j$1 = len2 - 1 | 0; j$1 >= 0; --j$1) {
        a2[j$1 + i2 | 0] = a1[j$1 + i1 | 0];
      }
    }
    function dup(prim) {
      return prim.slice(0);
    }
    module2.exports = {
      dup,
      sub,
      concat,
      make,
      make_float,
      blit,
      get,
      set
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/curry.js
var require_curry = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/curry.js"(exports2, module2) {
    "use strict";
    var Caml_array2 = require_caml_array();
    function app(_f, _args) {
      while (true) {
        const args = _args;
        const f = _f;
        const init_arity = f.length;
        const arity = init_arity === 0 ? 1 : init_arity;
        const len = args.length;
        const d = arity - len | 0;
        if (d === 0) {
          return f.apply(null, args);
        }
        if (d >= 0) {
          return function(x) {
            return app(f, args.concat([x]));
          };
        }
        _args = Caml_array2.sub(args, arity, -d | 0);
        _f = f.apply(null, Caml_array2.sub(args, 0, arity));
        continue;
      }
      ;
    }
    function _1(o, a0) {
      const arity = o.length;
      if (arity === 1) {
        return o(a0);
      } else {
        switch (arity) {
          case 1:
            return o(a0);
          case 2:
            return function(param) {
              return o(a0, param);
            };
          case 3:
            return function(param, param$1) {
              return o(a0, param, param$1);
            };
          case 4:
            return function(param, param$1, param$2) {
              return o(a0, param, param$1, param$2);
            };
          case 5:
            return function(param, param$1, param$2, param$3) {
              return o(a0, param, param$1, param$2, param$3);
            };
          case 6:
            return function(param, param$1, param$2, param$3, param$4) {
              return o(a0, param, param$1, param$2, param$3, param$4);
            };
          case 7:
            return function(param, param$1, param$2, param$3, param$4, param$5) {
              return o(a0, param, param$1, param$2, param$3, param$4, param$5);
            };
          default:
            return app(o, [a0]);
        }
      }
    }
    function __1(o) {
      const arity = o.length;
      if (arity === 1) {
        return o;
      } else {
        return function(a0) {
          return _1(o, a0);
        };
      }
    }
    function _2(o, a0, a1) {
      const arity = o.length;
      if (arity === 2) {
        return o(a0, a1);
      } else {
        switch (arity) {
          case 1:
            return app(o(a0), [a1]);
          case 2:
            return o(a0, a1);
          case 3:
            return function(param) {
              return o(a0, a1, param);
            };
          case 4:
            return function(param, param$1) {
              return o(a0, a1, param, param$1);
            };
          case 5:
            return function(param, param$1, param$2) {
              return o(a0, a1, param, param$1, param$2);
            };
          case 6:
            return function(param, param$1, param$2, param$3) {
              return o(a0, a1, param, param$1, param$2, param$3);
            };
          case 7:
            return function(param, param$1, param$2, param$3, param$4) {
              return o(a0, a1, param, param$1, param$2, param$3, param$4);
            };
          default:
            return app(o, [
              a0,
              a1
            ]);
        }
      }
    }
    function __2(o) {
      const arity = o.length;
      if (arity === 2) {
        return o;
      } else {
        return function(a0, a1) {
          return _2(o, a0, a1);
        };
      }
    }
    function _3(o, a0, a1, a2) {
      const arity = o.length;
      if (arity === 3) {
        return o(a0, a1, a2);
      } else {
        switch (arity) {
          case 1:
            return app(o(a0), [
              a1,
              a2
            ]);
          case 2:
            return app(o(a0, a1), [a2]);
          case 3:
            return o(a0, a1, a2);
          case 4:
            return function(param) {
              return o(a0, a1, a2, param);
            };
          case 5:
            return function(param, param$1) {
              return o(a0, a1, a2, param, param$1);
            };
          case 6:
            return function(param, param$1, param$2) {
              return o(a0, a1, a2, param, param$1, param$2);
            };
          case 7:
            return function(param, param$1, param$2, param$3) {
              return o(a0, a1, a2, param, param$1, param$2, param$3);
            };
          default:
            return app(o, [
              a0,
              a1,
              a2
            ]);
        }
      }
    }
    function __3(o) {
      const arity = o.length;
      if (arity === 3) {
        return o;
      } else {
        return function(a0, a1, a2) {
          return _3(o, a0, a1, a2);
        };
      }
    }
    function _4(o, a0, a1, a2, a3) {
      const arity = o.length;
      if (arity === 4) {
        return o(a0, a1, a2, a3);
      } else {
        switch (arity) {
          case 1:
            return app(o(a0), [
              a1,
              a2,
              a3
            ]);
          case 2:
            return app(o(a0, a1), [
              a2,
              a3
            ]);
          case 3:
            return app(o(a0, a1, a2), [a3]);
          case 4:
            return o(a0, a1, a2, a3);
          case 5:
            return function(param) {
              return o(a0, a1, a2, a3, param);
            };
          case 6:
            return function(param, param$1) {
              return o(a0, a1, a2, a3, param, param$1);
            };
          case 7:
            return function(param, param$1, param$2) {
              return o(a0, a1, a2, a3, param, param$1, param$2);
            };
          default:
            return app(o, [
              a0,
              a1,
              a2,
              a3
            ]);
        }
      }
    }
    function __4(o) {
      const arity = o.length;
      if (arity === 4) {
        return o;
      } else {
        return function(a0, a1, a2, a3) {
          return _4(o, a0, a1, a2, a3);
        };
      }
    }
    function _5(o, a0, a1, a2, a3, a4) {
      const arity = o.length;
      if (arity === 5) {
        return o(a0, a1, a2, a3, a4);
      } else {
        switch (arity) {
          case 1:
            return app(o(a0), [
              a1,
              a2,
              a3,
              a4
            ]);
          case 2:
            return app(o(a0, a1), [
              a2,
              a3,
              a4
            ]);
          case 3:
            return app(o(a0, a1, a2), [
              a3,
              a4
            ]);
          case 4:
            return app(o(a0, a1, a2, a3), [a4]);
          case 5:
            return o(a0, a1, a2, a3, a4);
          case 6:
            return function(param) {
              return o(a0, a1, a2, a3, a4, param);
            };
          case 7:
            return function(param, param$1) {
              return o(a0, a1, a2, a3, a4, param, param$1);
            };
          default:
            return app(o, [
              a0,
              a1,
              a2,
              a3,
              a4
            ]);
        }
      }
    }
    function __5(o) {
      const arity = o.length;
      if (arity === 5) {
        return o;
      } else {
        return function(a0, a1, a2, a3, a4) {
          return _5(o, a0, a1, a2, a3, a4);
        };
      }
    }
    function _6(o, a0, a1, a2, a3, a4, a5) {
      const arity = o.length;
      if (arity === 6) {
        return o(a0, a1, a2, a3, a4, a5);
      } else {
        switch (arity) {
          case 1:
            return app(o(a0), [
              a1,
              a2,
              a3,
              a4,
              a5
            ]);
          case 2:
            return app(o(a0, a1), [
              a2,
              a3,
              a4,
              a5
            ]);
          case 3:
            return app(o(a0, a1, a2), [
              a3,
              a4,
              a5
            ]);
          case 4:
            return app(o(a0, a1, a2, a3), [
              a4,
              a5
            ]);
          case 5:
            return app(o(a0, a1, a2, a3, a4), [a5]);
          case 6:
            return o(a0, a1, a2, a3, a4, a5);
          case 7:
            return function(param) {
              return o(a0, a1, a2, a3, a4, a5, param);
            };
          default:
            return app(o, [
              a0,
              a1,
              a2,
              a3,
              a4,
              a5
            ]);
        }
      }
    }
    function __6(o) {
      const arity = o.length;
      if (arity === 6) {
        return o;
      } else {
        return function(a0, a1, a2, a3, a4, a5) {
          return _6(o, a0, a1, a2, a3, a4, a5);
        };
      }
    }
    function _7(o, a0, a1, a2, a3, a4, a5, a6) {
      const arity = o.length;
      if (arity === 7) {
        return o(a0, a1, a2, a3, a4, a5, a6);
      } else {
        switch (arity) {
          case 1:
            return app(o(a0), [
              a1,
              a2,
              a3,
              a4,
              a5,
              a6
            ]);
          case 2:
            return app(o(a0, a1), [
              a2,
              a3,
              a4,
              a5,
              a6
            ]);
          case 3:
            return app(o(a0, a1, a2), [
              a3,
              a4,
              a5,
              a6
            ]);
          case 4:
            return app(o(a0, a1, a2, a3), [
              a4,
              a5,
              a6
            ]);
          case 5:
            return app(o(a0, a1, a2, a3, a4), [
              a5,
              a6
            ]);
          case 6:
            return app(o(a0, a1, a2, a3, a4, a5), [a6]);
          case 7:
            return o(a0, a1, a2, a3, a4, a5, a6);
          default:
            return app(o, [
              a0,
              a1,
              a2,
              a3,
              a4,
              a5,
              a6
            ]);
        }
      }
    }
    function __7(o) {
      const arity = o.length;
      if (arity === 7) {
        return o;
      } else {
        return function(a0, a1, a2, a3, a4, a5, a6) {
          return _7(o, a0, a1, a2, a3, a4, a5, a6);
        };
      }
    }
    function _8(o, a0, a1, a2, a3, a4, a5, a6, a7) {
      const arity = o.length;
      if (arity === 8) {
        return o(a0, a1, a2, a3, a4, a5, a6, a7);
      } else {
        switch (arity) {
          case 1:
            return app(o(a0), [
              a1,
              a2,
              a3,
              a4,
              a5,
              a6,
              a7
            ]);
          case 2:
            return app(o(a0, a1), [
              a2,
              a3,
              a4,
              a5,
              a6,
              a7
            ]);
          case 3:
            return app(o(a0, a1, a2), [
              a3,
              a4,
              a5,
              a6,
              a7
            ]);
          case 4:
            return app(o(a0, a1, a2, a3), [
              a4,
              a5,
              a6,
              a7
            ]);
          case 5:
            return app(o(a0, a1, a2, a3, a4), [
              a5,
              a6,
              a7
            ]);
          case 6:
            return app(o(a0, a1, a2, a3, a4, a5), [
              a6,
              a7
            ]);
          case 7:
            return app(o(a0, a1, a2, a3, a4, a5, a6), [a7]);
          default:
            return app(o, [
              a0,
              a1,
              a2,
              a3,
              a4,
              a5,
              a6,
              a7
            ]);
        }
      }
    }
    function __8(o) {
      const arity = o.length;
      if (arity === 8) {
        return o;
      } else {
        return function(a0, a1, a2, a3, a4, a5, a6, a7) {
          return _8(o, a0, a1, a2, a3, a4, a5, a6, a7);
        };
      }
    }
    module2.exports = {
      app,
      _1,
      __1,
      _2,
      __2,
      _3,
      __3,
      _4,
      __4,
      _5,
      __5,
      _6,
      __6,
      _7,
      __7,
      _8,
      __8
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml.js
var require_caml = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml.js"(exports2, module2) {
    "use strict";
    function caml_int_compare(x, y) {
      if (x < y) {
        return -1;
      } else if (x === y) {
        return 0;
      } else {
        return 1;
      }
    }
    function caml_bool_compare(x, y) {
      if (x) {
        if (y) {
          return 0;
        } else {
          return 1;
        }
      } else if (y) {
        return -1;
      } else {
        return 0;
      }
    }
    function caml_float_compare(x, y) {
      if (x === y) {
        return 0;
      } else if (x < y) {
        return -1;
      } else if (x > y || x === x) {
        return 1;
      } else if (y === y) {
        return -1;
      } else {
        return 0;
      }
    }
    function caml_string_compare(s1, s2) {
      if (s1 === s2) {
        return 0;
      } else if (s1 < s2) {
        return -1;
      } else {
        return 1;
      }
    }
    function caml_bool_min(x, y) {
      if (x) {
        return y;
      } else {
        return x;
      }
    }
    function caml_int_min(x, y) {
      if (x < y) {
        return x;
      } else {
        return y;
      }
    }
    function caml_float_min(x, y) {
      if (x < y) {
        return x;
      } else {
        return y;
      }
    }
    function caml_string_min(x, y) {
      if (x < y) {
        return x;
      } else {
        return y;
      }
    }
    function caml_int32_min(x, y) {
      if (x < y) {
        return x;
      } else {
        return y;
      }
    }
    function caml_bool_max(x, y) {
      if (x) {
        return x;
      } else {
        return y;
      }
    }
    function caml_int_max(x, y) {
      if (x > y) {
        return x;
      } else {
        return y;
      }
    }
    function caml_float_max(x, y) {
      if (x > y) {
        return x;
      } else {
        return y;
      }
    }
    function caml_string_max(x, y) {
      if (x > y) {
        return x;
      } else {
        return y;
      }
    }
    function caml_int32_max(x, y) {
      if (x > y) {
        return x;
      } else {
        return y;
      }
    }
    function i64_eq(x, y) {
      if (x[1] === y[1]) {
        return x[0] === y[0];
      } else {
        return false;
      }
    }
    function i64_ge(param, param$1) {
      const other_hi = param$1[0];
      const hi = param[0];
      if (hi > other_hi) {
        return true;
      } else if (hi < other_hi) {
        return false;
      } else {
        return param[1] >= param$1[1];
      }
    }
    function i64_neq(x, y) {
      return !i64_eq(x, y);
    }
    function i64_lt(x, y) {
      return !i64_ge(x, y);
    }
    function i64_gt(x, y) {
      if (x[0] > y[0]) {
        return true;
      } else if (x[0] < y[0]) {
        return false;
      } else {
        return x[1] > y[1];
      }
    }
    function i64_le(x, y) {
      return !i64_gt(x, y);
    }
    function i64_min(x, y) {
      if (i64_ge(x, y)) {
        return y;
      } else {
        return x;
      }
    }
    function i64_max(x, y) {
      if (i64_gt(x, y)) {
        return x;
      } else {
        return y;
      }
    }
    module2.exports = {
      caml_int_compare,
      caml_bool_compare,
      caml_float_compare,
      caml_string_compare,
      caml_bool_min,
      caml_int_min,
      caml_float_min,
      caml_string_min,
      caml_int32_min,
      caml_bool_max,
      caml_int_max,
      caml_float_max,
      caml_string_max,
      caml_int32_max,
      i64_eq,
      i64_neq,
      i64_lt,
      i64_gt,
      i64_le,
      i64_ge,
      i64_min,
      i64_max
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_obj.js
var require_caml_obj = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_obj.js"(exports2, module2) {
    "use strict";
    var Caml = require_caml();
    var Caml_js_exceptions = require_caml_js_exceptions();
    var for_in = (function(o, foo) {
      for (var x in o) {
        foo(x);
      }
    });
    var caml_obj_dup = (function(x) {
      if (Array.isArray(x)) {
        var len = x.length;
        var v = new Array(len);
        for (var i = 0; i < len; ++i) {
          v[i] = x[i];
        }
        if (x.TAG !== void 0) {
          v.TAG = x.TAG;
        }
        return v;
      }
      return Object.assign({}, x);
    });
    var update_dummy = (function(x, y) {
      var k;
      if (Array.isArray(y)) {
        for (k = 0; k < y.length; ++k) {
          x[k] = y[k];
        }
        if (y.TAG !== void 0) {
          x.TAG = y.TAG;
        }
      } else {
        for (var k in y) {
          x[k] = y[k];
        }
      }
    });
    function caml_compare(a, b) {
      if (a === b) {
        return 0;
      }
      const a_type = typeof a;
      const b_type = typeof b;
      switch (a_type) {
        case "bigint":
          if (b_type === "bigint") {
            return Caml.caml_float_compare(a, b);
          }
          break;
        case "boolean":
          if (b_type === "boolean") {
            return Caml.caml_int_compare(a, b);
          }
          break;
        case "function":
          if (b_type === "function") {
            throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
              MEL_EXN_ID: "Invalid_argument",
              _1: "compare: functional value"
            });
          }
          break;
        case "number":
          if (b_type === "number") {
            return Caml.caml_float_compare(a, b);
          }
          break;
        case "string":
          if (b_type === "string") {
            return Caml.caml_string_compare(a, b);
          } else {
            return 1;
          }
        case "undefined":
          return -1;
      }
      switch (b_type) {
        case "string":
          return -1;
        case "undefined":
          return 1;
        default:
          if (a_type === "boolean") {
            return 1;
          }
          if (b_type === "boolean") {
            return -1;
          }
          if (a_type === "function") {
            return 1;
          }
          if (b_type === "function") {
            return -1;
          }
          if (a_type === "number") {
            if (b === null || b.MEL_PRIVATE_NESTED_SOME_NONE !== void 0) {
              return 1;
            } else {
              return -1;
            }
          }
          if (b_type === "number") {
            if (a === null || a.MEL_PRIVATE_NESTED_SOME_NONE !== void 0) {
              return -1;
            } else {
              return 1;
            }
          }
          if (a === null) {
            if (b.MEL_PRIVATE_NESTED_SOME_NONE !== void 0) {
              return 1;
            } else {
              return -1;
            }
          }
          if (b === null) {
            if (a.MEL_PRIVATE_NESTED_SOME_NONE !== void 0) {
              return -1;
            } else {
              return 1;
            }
          }
          if (a.MEL_PRIVATE_NESTED_SOME_NONE !== void 0) {
            if (b.MEL_PRIVATE_NESTED_SOME_NONE !== void 0) {
              return aux_obj_compare(a, b);
            } else {
              return -1;
            }
          }
          const tag_a = a.TAG;
          const tag_b = b.TAG;
          if (tag_a === 248) {
            return Caml.caml_int_compare(a[1], b[1]);
          }
          if (tag_a === 251) {
            throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
              MEL_EXN_ID: "Invalid_argument",
              _1: "equal: abstract value"
            });
          }
          if (tag_a !== tag_b) {
            if (tag_a < tag_b) {
              return -1;
            } else {
              return 1;
            }
          }
          const len_a = a.length | 0;
          const len_b = b.length | 0;
          if (len_a === len_b) {
            if (Array.isArray(a)) {
              let _i = 0;
              while (true) {
                const i = _i;
                if (i === len_a) {
                  return 0;
                }
                const res = caml_compare(a[i], b[i]);
                if (res !== 0) {
                  return res;
                }
                _i = i + 1 | 0;
                continue;
              }
              ;
            } else if (a instanceof Date && b instanceof Date) {
              return a - b;
            } else {
              return aux_obj_compare(a, b);
            }
          } else if (len_a < len_b) {
            let _i$1 = 0;
            while (true) {
              const i$1 = _i$1;
              if (i$1 === len_a) {
                return -1;
              }
              const res$1 = caml_compare(a[i$1], b[i$1]);
              if (res$1 !== 0) {
                return res$1;
              }
              _i$1 = i$1 + 1 | 0;
              continue;
            }
            ;
          } else {
            let _i$2 = 0;
            while (true) {
              const i$2 = _i$2;
              if (i$2 === len_b) {
                return 1;
              }
              const res$2 = caml_compare(a[i$2], b[i$2]);
              if (res$2 !== 0) {
                return res$2;
              }
              _i$2 = i$2 + 1 | 0;
              continue;
            }
            ;
          }
      }
    }
    function aux_obj_compare(a, b) {
      const min_key_lhs = {
        contents: void 0
      };
      const min_key_rhs = {
        contents: void 0
      };
      const do_key = function(param, key) {
        const min_key = param[2];
        const b2 = param[1];
        if (!(!Object.prototype.hasOwnProperty.call(b2, key) || caml_compare(param[0][key], b2[key]) > 0)) {
          return;
        }
        const mk = min_key.contents;
        if (mk !== void 0 && key >= mk) {
          return;
        } else {
          min_key.contents = key;
          return;
        }
      };
      const partial_arg = [
        a,
        b,
        min_key_rhs
      ];
      const do_key_a = function(param) {
        return do_key(partial_arg, param);
      };
      const partial_arg$1 = [
        b,
        a,
        min_key_lhs
      ];
      const do_key_b = function(param) {
        return do_key(partial_arg$1, param);
      };
      for_in(a, do_key_a);
      for_in(b, do_key_b);
      const match = min_key_lhs.contents;
      const match$1 = min_key_rhs.contents;
      if (match !== void 0) {
        if (match$1 !== void 0) {
          return Caml.caml_string_compare(match, match$1);
        } else {
          return -1;
        }
      } else if (match$1 !== void 0) {
        return 1;
      } else {
        return 0;
      }
    }
    function caml_equal(a, b) {
      if (a === b) {
        return true;
      }
      const a_type = typeof a;
      if (a_type === "string" || a_type === "number" || a_type === "bigint" || a_type === "boolean" || a_type === "undefined" || a === null) {
        return false;
      }
      const b_type = typeof b;
      if (a_type === "function" || b_type === "function") {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "equal: functional value"
        });
      }
      if (b_type === "number" || b_type === "bigint" || b_type === "undefined" || b === null) {
        return false;
      }
      const tag_a = a.TAG;
      const tag_b = b.TAG;
      if (tag_a === 248) {
        return a[1] === b[1];
      }
      if (tag_a === 251) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "equal: abstract value"
        });
      }
      if (tag_a !== tag_b) {
        return false;
      }
      const len_a = a.length | 0;
      const len_b = b.length | 0;
      if (len_a === len_b) {
        if (Array.isArray(a)) {
          let _i = 0;
          while (true) {
            const i = _i;
            if (i === len_a) {
              return true;
            }
            if (!caml_equal(a[i], b[i])) {
              return false;
            }
            _i = i + 1 | 0;
            continue;
          }
          ;
        } else if (a instanceof Date && b instanceof Date) {
          return !(a > b || a < b);
        } else {
          const result = {
            contents: true
          };
          const do_key_a = function(key) {
            if (!Object.prototype.hasOwnProperty.call(b, key)) {
              result.contents = false;
              return;
            }
          };
          const do_key_b = function(key) {
            if (!Object.prototype.hasOwnProperty.call(a, key) || !caml_equal(b[key], a[key])) {
              result.contents = false;
              return;
            }
          };
          for_in(a, do_key_a);
          if (result.contents) {
            for_in(b, do_key_b);
          }
          return result.contents;
        }
      } else {
        return false;
      }
    }
    function caml_equal_null(x, y) {
      if (y !== null) {
        return caml_equal(x, y);
      } else {
        return x === y;
      }
    }
    function caml_equal_undefined(x, y) {
      if (y !== void 0) {
        return caml_equal(x, y);
      } else {
        return x === y;
      }
    }
    function caml_equal_nullable(x, y) {
      if (y == null) {
        return x === y;
      } else {
        return caml_equal(x, y);
      }
    }
    function caml_notequal(a, b) {
      if ((typeof a === "number" || typeof a === "bigint") && (typeof b === "number" || typeof b === "bigint")) {
        return a !== b;
      } else {
        return !caml_equal(a, b);
      }
    }
    function caml_greaterequal(a, b) {
      if ((typeof a === "number" || typeof a === "bigint") && (typeof b === "number" || typeof b === "bigint")) {
        return a >= b;
      } else {
        return caml_compare(a, b) >= 0;
      }
    }
    function caml_greaterthan(a, b) {
      if ((typeof a === "number" || typeof a === "bigint") && (typeof b === "number" || typeof b === "bigint")) {
        return a > b;
      } else {
        return caml_compare(a, b) > 0;
      }
    }
    function caml_lessequal(a, b) {
      if ((typeof a === "number" || typeof a === "bigint") && (typeof b === "number" || typeof b === "bigint")) {
        return a <= b;
      } else {
        return caml_compare(a, b) <= 0;
      }
    }
    function caml_lessthan(a, b) {
      if ((typeof a === "number" || typeof a === "bigint") && (typeof b === "number" || typeof b === "bigint")) {
        return a < b;
      } else {
        return caml_compare(a, b) < 0;
      }
    }
    function caml_min(x, y) {
      if (caml_compare(x, y) <= 0) {
        return x;
      } else {
        return y;
      }
    }
    function caml_max(x, y) {
      if (caml_compare(x, y) >= 0) {
        return x;
      } else {
        return y;
      }
    }
    module2.exports = {
      caml_obj_dup,
      update_dummy,
      caml_compare,
      caml_equal,
      caml_equal_null,
      caml_equal_undefined,
      caml_equal_nullable,
      caml_notequal,
      caml_greaterequal,
      caml_greaterthan,
      caml_lessthan,
      caml_lessequal,
      caml_min,
      caml_max
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_option.js
var require_caml_option = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_option.js"(exports2, module2) {
    "use strict";
    function isNested(x) {
      return x.MEL_PRIVATE_NESTED_SOME_NONE !== void 0;
    }
    function some(x) {
      if (x === void 0) {
        return {
          MEL_PRIVATE_NESTED_SOME_NONE: 0
        };
      } else if (x !== null && x.MEL_PRIVATE_NESTED_SOME_NONE !== void 0) {
        return {
          MEL_PRIVATE_NESTED_SOME_NONE: x.MEL_PRIVATE_NESTED_SOME_NONE + 1 | 0
        };
      } else {
        return x;
      }
    }
    function nullable_to_opt(x) {
      if (x == null) {
        return;
      } else {
        return some(x);
      }
    }
    function undefined_to_opt(x) {
      if (x === void 0) {
        return;
      } else {
        return some(x);
      }
    }
    function null_to_opt(x) {
      if (x === null) {
        return;
      } else {
        return some(x);
      }
    }
    function valFromOption(x) {
      if (!(x !== null && x.MEL_PRIVATE_NESTED_SOME_NONE !== void 0)) {
        return x;
      }
      const depth = x.MEL_PRIVATE_NESTED_SOME_NONE;
      if (depth === 0) {
        return;
      } else {
        return {
          MEL_PRIVATE_NESTED_SOME_NONE: depth - 1 | 0
        };
      }
    }
    function option_get(x) {
      if (x === void 0) {
        return;
      } else {
        return valFromOption(x);
      }
    }
    function option_unwrap(x) {
      if (x !== void 0) {
        return x.VAL;
      } else {
        return x;
      }
    }
    module2.exports = {
      nullable_to_opt,
      undefined_to_opt,
      null_to_opt,
      valFromOption,
      some,
      isNested,
      option_get,
      option_unwrap
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_int64.js
var require_caml_int64 = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_int64.js"(exports2, module2) {
    "use strict";
    var Caml = require_caml();
    var Caml_js_exceptions = require_caml_js_exceptions();
    function mk(lo, hi) {
      return [
        hi,
        lo >>> 0
      ];
    }
    var min_int = [
      -2147483648,
      0
    ];
    var max_int = [
      2147483647,
      4294967295
    ];
    var one = [
      0,
      1
    ];
    var zero = [
      0,
      0
    ];
    var neg_one = [
      -1,
      4294967295
    ];
    function neg_signed(x) {
      return (x & -2147483648) !== 0;
    }
    function non_neg_signed(x) {
      return (x & -2147483648) === 0;
    }
    function succ(param) {
      let x_lo = param[1];
      let x_hi = param[0];
      const lo = x_lo + 1 | 0;
      return [
        x_hi + (lo === 0 ? 1 : 0) | 0,
        lo >>> 0
      ];
    }
    function neg(param) {
      const other_lo = (param[1] ^ -1) + 1 | 0;
      return [
        (param[0] ^ -1) + (other_lo === 0 ? 1 : 0) | 0,
        other_lo >>> 0
      ];
    }
    function add_aux(param, y_lo, y_hi) {
      const x_lo = param[1];
      const lo = x_lo + y_lo | 0;
      const overflow = neg_signed(x_lo) && (neg_signed(y_lo) || non_neg_signed(lo)) || neg_signed(y_lo) && non_neg_signed(lo) ? 1 : 0;
      return [
        param[0] + y_hi + overflow | 0,
        lo >>> 0
      ];
    }
    function add(self2, param) {
      return add_aux(self2, param[1], param[0]);
    }
    function equal_null(x, y) {
      if (y !== null) {
        return Caml.i64_eq(x, y);
      } else {
        return false;
      }
    }
    function equal_undefined(x, y) {
      if (y !== void 0) {
        return Caml.i64_eq(x, y);
      } else {
        return false;
      }
    }
    function equal_nullable(x, y) {
      if (y == null) {
        return false;
      } else {
        return Caml.i64_eq(x, y);
      }
    }
    function sub_aux(x, lo, hi) {
      const y_lo = (lo ^ -1) + 1 >>> 0;
      const y_hi = (hi ^ -1) + (y_lo === 0 ? 1 : 0) | 0;
      return add_aux(x, y_lo, y_hi);
    }
    function sub(self2, param) {
      return sub_aux(self2, param[1], param[0]);
    }
    function lsl_(x, numBits) {
      if (numBits === 0) {
        return x;
      }
      const lo = x[1];
      if (numBits >= 32) {
        return [
          lo << (numBits - 32 | 0),
          0
        ];
      } else {
        return [
          lo >>> (32 - numBits | 0) | x[0] << numBits,
          lo << numBits >>> 0
        ];
      }
    }
    function lsr_(x, numBits) {
      if (numBits === 0) {
        return x;
      }
      const hi = x[0];
      const offset = numBits - 32 | 0;
      if (offset === 0) {
        return [
          0,
          hi >>> 0
        ];
      } else if (offset > 0) {
        return [
          0,
          hi >>> offset
        ];
      } else {
        return [
          hi >>> numBits,
          (hi << (-offset | 0) | x[1] >>> numBits) >>> 0
        ];
      }
    }
    function asr_(x, numBits) {
      if (numBits === 0) {
        return x;
      }
      const hi = x[0];
      if (numBits < 32) {
        return [
          hi >> numBits,
          (hi << (32 - numBits | 0) | x[1] >>> numBits) >>> 0
        ];
      } else {
        return [
          hi >= 0 ? 0 : -1,
          hi >> (numBits - 32 | 0) >>> 0
        ];
      }
    }
    function is_zero(param) {
      if (param[0] !== 0) {
        return false;
      } else {
        return param[1] === 0;
      }
    }
    function mul(_this, _other) {
      while (true) {
        const other = _other;
        const $$this = _this;
        let lo;
        const this_hi = $$this[0];
        let exit = 0;
        let exit$1 = 0;
        let exit$2 = 0;
        if (this_hi !== 0) {
          exit$2 = 4;
        } else {
          if ($$this[1] === 0) {
            return zero;
          }
          exit$2 = 4;
        }
        if (exit$2 === 4) {
          if (other[0] !== 0) {
            exit$1 = 3;
          } else {
            if (other[1] === 0) {
              return zero;
            }
            exit$1 = 3;
          }
        }
        if (exit$1 === 3) {
          if (this_hi !== -2147483648 || $$this[1] !== 0) {
            exit = 2;
          } else {
            lo = other[1];
          }
        }
        if (exit === 2) {
          const other_hi = other[0];
          const lo$1 = $$this[1];
          let exit$3 = 0;
          if (other_hi !== -2147483648 || other[1] !== 0) {
            exit$3 = 3;
          } else {
            lo = lo$1;
          }
          if (exit$3 === 3) {
            const other_lo = other[1];
            if (this_hi < 0) {
              if (other_hi >= 0) {
                return neg(mul(neg($$this), other));
              }
              _other = neg(other);
              _this = neg($$this);
              continue;
            }
            if (other_hi < 0) {
              return neg(mul($$this, neg(other)));
            }
            const a48 = this_hi >>> 16;
            const a32 = this_hi & 65535;
            const a16 = lo$1 >>> 16;
            const a00 = lo$1 & 65535;
            const b48 = other_hi >>> 16;
            const b32 = other_hi & 65535;
            const b16 = other_lo >>> 16;
            const b00 = other_lo & 65535;
            let c48 = 0;
            let c32 = 0;
            let c16 = 0;
            const c00 = a00 * b00;
            c16 = (c00 >>> 16) + a16 * b00;
            c32 = c16 >>> 16;
            c16 = (c16 & 65535) + a00 * b16;
            c32 = c32 + (c16 >>> 16) + a32 * b00;
            c48 = c32 >>> 16;
            c32 = (c32 & 65535) + a16 * b16;
            c48 = c48 + (c32 >>> 16);
            c32 = (c32 & 65535) + a00 * b32;
            c48 = c48 + (c32 >>> 16);
            c32 = c32 & 65535;
            c48 = c48 + (a48 * b00 + a32 * b16 + a16 * b32 + a00 * b48) & 65535;
            return [
              c32 | c48 << 16,
              (c00 & 65535 | (c16 & 65535) << 16) >>> 0
            ];
          }
        }
        if ((lo & 1) === 0) {
          return zero;
        } else {
          return min_int;
        }
      }
      ;
    }
    function xor(param, param$1) {
      return [
        param[0] ^ param$1[0],
        (param[1] ^ param$1[1]) >>> 0
      ];
    }
    function or_(param, param$1) {
      return [
        param[0] | param$1[0],
        (param[1] | param$1[1]) >>> 0
      ];
    }
    function and_(param, param$1) {
      return [
        param[0] & param$1[0],
        (param[1] & param$1[1]) >>> 0
      ];
    }
    function to_float(param) {
      return param[0] * 4294967296 + param[1];
    }
    function of_float(x) {
      if (isNaN(x) || !isFinite(x)) {
        return zero;
      }
      if (x <= -9223372036854776e3) {
        return min_int;
      }
      if (x + 1 >= 9223372036854776e3) {
        return max_int;
      }
      if (x < 0) {
        return neg(of_float(-x));
      }
      const hi = x / 4294967296 | 0;
      const lo = x % 4294967296 | 0;
      return [
        hi,
        lo >>> 0
      ];
    }
    function isSafeInteger(param) {
      const hi = param[0];
      const top11Bits = hi >> 21;
      if (top11Bits === 0) {
        return true;
      } else if (top11Bits === -1) {
        return !(param[1] === 0 && hi === -2097152);
      } else {
        return false;
      }
    }
    function to_string(self2) {
      if (isSafeInteger(self2)) {
        return String(to_float(self2));
      }
      if (self2[0] < 0) {
        if (Caml.i64_eq(self2, min_int)) {
          return "-9223372036854775808";
        } else {
          return "-" + to_string(neg(self2));
        }
      }
      const approx_div1 = of_float(Math.floor(to_float(self2) / 10));
      const lo = approx_div1[1];
      const hi = approx_div1[0];
      const match = sub_aux(sub_aux(self2, lo << 3, lo >>> 29 | hi << 3), lo << 1, lo >>> 31 | hi << 1);
      const rem_lo = match[1];
      const rem_hi = match[0];
      if (rem_lo === 0 && rem_hi === 0) {
        return to_string(approx_div1) + "0";
      }
      if (rem_hi < 0) {
        const rem_lo$1 = (rem_lo ^ -1) + 1 >>> 0;
        const delta = Math.ceil(rem_lo$1 / 10);
        const remainder = 10 * delta - rem_lo$1;
        return to_string(sub_aux(approx_div1, delta | 0, 0)) + String(remainder | 0);
      }
      const delta$1 = Math.floor(rem_lo / 10);
      const remainder$1 = rem_lo - 10 * delta$1;
      return to_string(add_aux(approx_div1, delta$1 | 0, 0)) + String(remainder$1 | 0);
    }
    function div(_self, _other) {
      while (true) {
        const other = _other;
        const self2 = _self;
        let exit = 0;
        if (other[0] !== 0 || other[1] !== 0) {
          exit = 1;
        } else {
          throw new Caml_js_exceptions.MelangeError("Division_by_zero", {
            MEL_EXN_ID: "Division_by_zero"
          });
        }
        if (exit === 1) {
          const self_hi = self2[0];
          let exit$1 = 0;
          if (self_hi !== -2147483648) {
            if (self_hi !== 0) {
              exit$1 = 2;
            } else {
              if (self2[1] === 0) {
                return zero;
              }
              exit$1 = 2;
            }
          } else if (self2[1] !== 0) {
            exit$1 = 2;
          } else {
            if (Caml.i64_eq(other, one) || Caml.i64_eq(other, neg_one)) {
              return self2;
            }
            if (Caml.i64_eq(other, min_int)) {
              return one;
            }
            const half_this = asr_(self2, 1);
            const approx = lsl_(div(half_this, other), 1);
            let exit$2 = 0;
            if (approx[0] !== 0) {
              exit$2 = 3;
            } else {
              if (approx[1] === 0) {
                if (other[0] < 0) {
                  return one;
                } else {
                  return neg(one);
                }
              }
              exit$2 = 3;
            }
            if (exit$2 === 3) {
              const rem = sub(self2, mul(other, approx));
              return add(approx, div(rem, other));
            }
          }
          if (exit$1 === 2) {
            const other_hi = other[0];
            let exit$3 = 0;
            if (other_hi !== -2147483648) {
              exit$3 = 3;
            } else {
              if (other[1] === 0) {
                return zero;
              }
              exit$3 = 3;
            }
            if (exit$3 === 3) {
              if (self_hi < 0) {
                if (other_hi >= 0) {
                  return neg(div(neg(self2), other));
                }
                _other = neg(other);
                _self = neg(self2);
                continue;
              }
              if (other_hi < 0) {
                return neg(div(self2, neg(other)));
              }
              let res = zero;
              let rem$1 = self2;
              while (Caml.i64_ge(rem$1, other)) {
                const b = Math.floor(to_float(rem$1) / to_float(other));
                let approx$1 = 1 > b ? 1 : b;
                const log2 = Math.ceil(Math.log(approx$1) / Math.LN2);
                const delta = log2 <= 48 ? 1 : Math.pow(2, log2 - 48);
                let approxRes = of_float(approx$1);
                let approxRem = mul(approxRes, other);
                while (approxRem[0] < 0 || Caml.i64_gt(approxRem, rem$1)) {
                  approx$1 = approx$1 - delta;
                  approxRes = of_float(approx$1);
                  approxRem = mul(approxRes, other);
                }
                ;
                if (is_zero(approxRes)) {
                  approxRes = one;
                }
                res = add(res, approxRes);
                rem$1 = sub(rem$1, approxRem);
              }
              ;
              return res;
            }
          }
        }
      }
      ;
    }
    function mod_(self2, other) {
      return sub(self2, mul(div(self2, other), other));
    }
    function div_mod(self2, other) {
      const quotient = div(self2, other);
      return [
        quotient,
        sub(self2, mul(quotient, other))
      ];
    }
    function compare(self2, other) {
      const y = other[0];
      const x = self2[0];
      const v = x < y ? -1 : x === y ? 0 : 1;
      if (v !== 0) {
        return v;
      }
      const y$1 = other[1];
      const x$1 = self2[1];
      if (x$1 < y$1) {
        return -1;
      } else if (x$1 === y$1) {
        return 0;
      } else {
        return 1;
      }
    }
    function of_int32(lo) {
      return [
        lo < 0 ? -1 : 0,
        lo >>> 0
      ];
    }
    function to_int32(x) {
      return x[1] | 0;
    }
    function to_hex(x) {
      const x_lo = x[1];
      const x_hi = x[0];
      const aux = function(v) {
        return (v >>> 0).toString(16);
      };
      if (x_hi === 0 && x_lo === 0) {
        return "0";
      }
      if (x_lo === 0) {
        return aux(x_hi) + "00000000";
      }
      if (x_hi === 0) {
        return aux(x_lo);
      }
      const lo = aux(x_lo);
      const pad = 8 - lo.length | 0;
      if (pad <= 0) {
        return aux(x_hi) + lo;
      } else {
        return aux(x_hi) + ("0".repeat(pad) + lo);
      }
    }
    function discard_sign(x) {
      return [
        2147483647 & x[0],
        x[1]
      ];
    }
    function float_of_bits(x) {
      return (function(lo, hi) {
        return new Float64Array(new Int32Array([lo, hi]).buffer)[0];
      })(x[1], x[0]);
    }
    function bits_of_float(x) {
      const match = (function(x2) {
        return new Int32Array(new Float64Array([x2]).buffer);
      })(x);
      return [
        match[1],
        match[0] >>> 0
      ];
    }
    module2.exports = {
      mk,
      succ,
      min_int,
      max_int,
      one,
      zero,
      neg_one,
      of_int32,
      to_int32,
      add,
      neg,
      sub,
      lsl_,
      lsr_,
      asr_,
      is_zero,
      mul,
      xor,
      or_,
      and_,
      equal_null,
      equal_undefined,
      equal_nullable,
      to_float,
      of_float,
      div,
      mod_,
      compare,
      float_of_bits,
      bits_of_float,
      div_mod,
      to_hex,
      discard_sign,
      to_string
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_bytes.js
var require_caml_bytes = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_bytes.js"(exports2, module2) {
    "use strict";
    var Caml_int64 = require_caml_int64();
    var Caml_js_exceptions = require_caml_js_exceptions();
    function set(s, i, ch) {
      if (i < 0 || i >= s.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      s[i] = ch;
    }
    function get(s, i) {
      if (i < 0 || i >= s.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      return s[i];
    }
    function caml_fill_bytes(s, i, l, c) {
      if (l <= 0) {
        return;
      }
      for (let k = i, k_finish = l + i | 0; k < k_finish; ++k) {
        s[k] = c;
      }
    }
    function caml_create_bytes(len) {
      if (len < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.create"
        });
      }
      const result = new Array(len);
      for (let i = 0; i < len; ++i) {
        result[i] = /* '\000' */
        0;
      }
      return result;
    }
    function caml_blit_bytes(s1, i1, s2, i2, len) {
      if (len <= 0) {
        return;
      }
      if (s1 === s2) {
        if (i1 < i2) {
          const range_a = (s1.length - i2 | 0) - 1 | 0;
          const range_b = len - 1 | 0;
          const range = range_a > range_b ? range_b : range_a;
          for (let j = range; j >= 0; --j) {
            s1[i2 + j | 0] = s1[i1 + j | 0];
          }
          return;
        }
        if (i1 <= i2) {
          return;
        }
        const range_a$1 = (s1.length - i1 | 0) - 1 | 0;
        const range_b$1 = len - 1 | 0;
        const range$1 = range_a$1 > range_b$1 ? range_b$1 : range_a$1;
        for (let k = 0; k <= range$1; ++k) {
          s1[i2 + k | 0] = s1[i1 + k | 0];
        }
        return;
      }
      const off1 = s1.length - i1 | 0;
      if (len <= off1) {
        for (let i = 0; i < len; ++i) {
          s2[i2 + i | 0] = s1[i1 + i | 0];
        }
        return;
      }
      for (let i$1 = 0; i$1 < off1; ++i$1) {
        s2[i2 + i$1 | 0] = s1[i1 + i$1 | 0];
      }
      for (let i$2 = off1; i$2 < len; ++i$2) {
        s2[i2 + i$2 | 0] = /* '\000' */
        0;
      }
    }
    function bytes_to_string(a) {
      let i = 0;
      let len = a.length;
      let s = "";
      let s_len = len;
      if (i === 0 && len <= 4096 && len === a.length) {
        return String.fromCharCode.apply(null, a);
      }
      let offset = 0;
      while (s_len > 0) {
        const next = s_len < 1024 ? s_len : 1024;
        const tmp_bytes = new Array(next);
        for (let k = 0; k < next; ++k) {
          tmp_bytes[k] = a[k + offset | 0];
        }
        s = s + String.fromCharCode.apply(null, tmp_bytes);
        s_len = s_len - next | 0;
        offset = offset + next | 0;
      }
      ;
      return s;
    }
    function caml_blit_string(s1, i1, s2, i2, len) {
      if (len <= 0) {
        return;
      }
      const off1 = s1.length - i1 | 0;
      if (len <= off1) {
        for (let i = 0; i < len; ++i) {
          s2[i2 + i | 0] = s1.charCodeAt(i1 + i | 0);
        }
        return;
      }
      for (let i$1 = 0; i$1 < off1; ++i$1) {
        s2[i2 + i$1 | 0] = s1.charCodeAt(i1 + i$1 | 0);
      }
      for (let i$2 = off1; i$2 < len; ++i$2) {
        s2[i2 + i$2 | 0] = /* '\000' */
        0;
      }
    }
    function bytes_of_string(s) {
      const len = s.length;
      const res = new Array(len);
      for (let i = 0; i < len; ++i) {
        res[i] = s.charCodeAt(i);
      }
      return res;
    }
    function caml_bytes_compare_aux(s1, s2, _off, len, def) {
      while (true) {
        const off = _off;
        if (off >= len) {
          return def;
        }
        const a = s1[off];
        const b = s2[off];
        if (a > b) {
          return 1;
        }
        if (a < b) {
          return -1;
        }
        _off = off + 1 | 0;
        continue;
      }
      ;
    }
    function caml_bytes_compare(s1, s2) {
      const len1 = s1.length;
      const len2 = s2.length;
      if (len1 === len2) {
        return caml_bytes_compare_aux(s1, s2, 0, len1, 0);
      } else if (len1 < len2) {
        return caml_bytes_compare_aux(s1, s2, 0, len1, -1);
      } else {
        return caml_bytes_compare_aux(s1, s2, 0, len2, 1);
      }
    }
    function caml_bytes_equal(s1, s2) {
      const len1 = s1.length;
      const len2 = s2.length;
      if (len1 === len2) {
        let _off = 0;
        while (true) {
          const off = _off;
          if (off === len1) {
            return true;
          }
          const a = s1[off];
          const b = s2[off];
          if (a !== b) {
            return false;
          }
          _off = off + 1 | 0;
          continue;
        }
        ;
      } else {
        return false;
      }
    }
    function caml_bytes_greaterthan(s1, s2) {
      return caml_bytes_compare(s1, s2) > 0;
    }
    function caml_bytes_greaterequal(s1, s2) {
      return caml_bytes_compare(s1, s2) >= 0;
    }
    function caml_bytes_lessthan(s1, s2) {
      return caml_bytes_compare(s1, s2) < 0;
    }
    function caml_bytes_lessequal(s1, s2) {
      return caml_bytes_compare(s1, s2) <= 0;
    }
    function bswap16(x) {
      return (x & 255) << 8 | (x & 65280) >>> 8;
    }
    function bswap32(x) {
      return (x & 255) << 24 | (x & 65280) << 8 | (x & 16711680) >>> 8 | (x & -16777216) >>> 24;
    }
    function bswap64(x) {
      return Caml_int64.or_(Caml_int64.or_(Caml_int64.or_(Caml_int64.or_(Caml_int64.or_(Caml_int64.or_(Caml_int64.or_(Caml_int64.lsl_(Caml_int64.and_(x, [
        0,
        255
      ]), 56), Caml_int64.lsl_(Caml_int64.and_(x, [
        0,
        65280
      ]), 40)), Caml_int64.lsl_(Caml_int64.and_(x, [
        0,
        16711680
      ]), 24)), Caml_int64.lsl_(Caml_int64.and_(x, [
        0,
        4278190080
      ]), 8)), Caml_int64.lsr_(Caml_int64.and_(x, [
        255,
        0
      ]), 8)), Caml_int64.lsr_(Caml_int64.and_(x, [
        65280,
        0
      ]), 24)), Caml_int64.lsr_(Caml_int64.and_(x, [
        16711680,
        0
      ]), 40)), Caml_int64.lsr_(Caml_int64.and_(x, [
        -16777216,
        0
      ]), 56));
    }
    function get16u(str, idx) {
      const b1 = str[idx];
      const b2 = str[idx + 1 | 0];
      return b2 << 8 | b1;
    }
    function get16(str, idx) {
      if (idx < 0 || (idx + 1 | 0) >= str.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      return get16u(str, idx);
    }
    function get32(str, idx) {
      if (idx < 0 || (idx + 3 | 0) >= str.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      const b1 = str[idx];
      const b2 = str[idx + 1 | 0];
      const b3 = str[idx + 2 | 0];
      const b4 = str[idx + 3 | 0];
      return b4 << 24 | b3 << 16 | b2 << 8 | b1;
    }
    function get64(str, idx) {
      if (idx < 0 || (idx + 7 | 0) >= str.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      const b1 = str[idx];
      const b2 = str[idx + 1 | 0];
      const b3 = str[idx + 2 | 0];
      const b4 = str[idx + 3 | 0];
      const b5 = str[idx + 4 | 0];
      const b6 = str[idx + 5 | 0];
      const b7 = str[idx + 6 | 0];
      const b8 = str[idx + 7 | 0];
      return Caml_int64.or_(Caml_int64.lsl_(Caml_int64.or_(Caml_int64.lsl_(Caml_int64.or_(Caml_int64.lsl_(Caml_int64.or_(Caml_int64.lsl_(Caml_int64.or_(Caml_int64.lsl_(Caml_int64.or_(Caml_int64.lsl_(Caml_int64.or_(Caml_int64.lsl_(Caml_int64.of_int32(b8), 56), Caml_int64.of_int32(b7)), 48), Caml_int64.of_int32(b6)), 40), Caml_int64.of_int32(b5)), 32), Caml_int64.of_int32(b4)), 24), Caml_int64.of_int32(b3)), 16), Caml_int64.of_int32(b2)), 8), Caml_int64.of_int32(b1));
    }
    function set16u(b, idx, newval) {
      const b2 = 255 & newval >>> 8;
      const b1 = 255 & newval;
      b[idx] = b1;
      b[idx + 1 | 0] = b2;
    }
    function set16(b, idx, newval) {
      if (idx < 0 || (idx + 1 | 0) >= b.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      set16u(b, idx, newval);
    }
    function set32u(str, idx, newval) {
      const b4 = 255 & newval >>> 24;
      const b3 = 255 & newval >>> 16;
      const b2 = 255 & newval >>> 8;
      const b1 = 255 & newval;
      str[idx] = b1;
      str[idx + 1 | 0] = b2;
      str[idx + 2 | 0] = b3;
      str[idx + 3 | 0] = b4;
    }
    function set32(str, idx, newval) {
      if (idx < 0 || (idx + 3 | 0) >= str.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      set32u(str, idx, newval);
    }
    function set64u(str, idx, newval) {
      const x = Caml_int64.lsr_(newval, 56);
      const b8 = 255 & (x[1] | 0);
      const x$1 = Caml_int64.lsr_(newval, 48);
      const b7 = 255 & (x$1[1] | 0);
      const x$2 = Caml_int64.lsr_(newval, 40);
      const b6 = 255 & (x$2[1] | 0);
      const x$3 = Caml_int64.lsr_(newval, 32);
      const b5 = 255 & (x$3[1] | 0);
      const x$4 = Caml_int64.lsr_(newval, 24);
      const b4 = 255 & (x$4[1] | 0);
      const x$5 = Caml_int64.lsr_(newval, 16);
      const b3 = 255 & (x$5[1] | 0);
      const x$6 = Caml_int64.lsr_(newval, 8);
      const b2 = 255 & (x$6[1] | 0);
      const b1 = 255 & (newval[1] | 0);
      str[idx] = b1;
      str[idx + 1 | 0] = b2;
      str[idx + 2 | 0] = b3;
      str[idx + 3 | 0] = b4;
      str[idx + 4 | 0] = b5;
      str[idx + 5 | 0] = b6;
      str[idx + 6 | 0] = b7;
      str[idx + 7 | 0] = b8;
    }
    function set64(str, idx, newval) {
      if (idx < 0 || (idx + 7 | 0) >= str.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      set64u(str, idx, newval);
    }
    module2.exports = {
      caml_create_bytes,
      caml_fill_bytes,
      get,
      set,
      bytes_to_string,
      caml_blit_bytes,
      caml_blit_string,
      bytes_of_string,
      caml_bytes_compare,
      caml_bytes_greaterthan,
      caml_bytes_greaterequal,
      caml_bytes_lessthan,
      caml_bytes_lessequal,
      caml_bytes_equal,
      bswap16,
      bswap32,
      bswap64,
      get16u,
      get16,
      get32,
      get64,
      set16u,
      set16,
      set32u,
      set32,
      set64u,
      set64
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_external_polyfill.js
var require_caml_external_polyfill = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_external_polyfill.js"(exports2, module2) {
    "use strict";
    var getGlobalThis = (function() {
      if (typeof globalThis !== "undefined") return globalThis;
      if (typeof self !== "undefined") return self;
      if (typeof window !== "undefined") return window;
      if (typeof global !== "undefined") return global;
      if (typeof this !== "undefined") return this;
      throw new Error("Unable to locate global `this`");
    });
    var resolve = (function(s) {
      var myGlobal = getGlobalThis();
      if (myGlobal[s] === void 0) {
        throw new Error(s + " not polyfilled by Melange yet\n");
      }
      return myGlobal[s];
    });
    var register = (function(s, fn) {
      var myGlobal = getGlobalThis();
      myGlobal[s] = fn;
      return 0;
    });
    module2.exports = {
      getGlobalThis,
      resolve,
      register
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_format.js
var require_caml_format = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_format.js"(exports2, module2) {
    "use strict";
    var Caml = require_caml();
    var Caml_int64 = require_caml_int64();
    var Caml_js_exceptions = require_caml_js_exceptions();
    function parse_digit(c) {
      if (c >= 65) {
        if (c >= 97) {
          if (c >= 123) {
            return -1;
          } else {
            return c - 87 | 0;
          }
        } else if (c >= 91) {
          return -1;
        } else {
          return c - 55 | 0;
        }
      } else if (c > 57 || c < 48) {
        return -1;
      } else {
        return c - /* '0' */
        48 | 0;
      }
    }
    function int_of_string_base(param) {
      switch (param) {
        case /* Oct */
        0:
          return 8;
        case /* Hex */
        1:
          return 16;
        case /* Dec */
        2:
          return 10;
        case /* Bin */
        3:
          return 2;
      }
    }
    function parse_sign_and_base(s) {
      let sign = 1;
      let base = (
        /* Dec */
        2
      );
      let i = 0;
      const match = s.charCodeAt(i);
      switch (match) {
        case 43:
          i = i + 1 | 0;
          break;
        case 45:
          sign = -1;
          i = i + 1 | 0;
          break;
      }
      if (s[i] === "0") {
        const match$1 = s.charCodeAt(i + 1 | 0);
        if (match$1 >= 89) {
          if (match$1 >= 111) {
            if (match$1 < 121) {
              switch (match$1) {
                case 111:
                  base = /* Oct */
                  0;
                  i = i + 2 | 0;
                  break;
                case 117:
                  i = i + 2 | 0;
                  break;
                case 112:
                case 113:
                case 114:
                case 115:
                case 116:
                case 118:
                case 119:
                  break;
                case 120:
                  base = /* Hex */
                  1;
                  i = i + 2 | 0;
                  break;
              }
            }
          } else if (match$1 === 98) {
            base = /* Bin */
            3;
            i = i + 2 | 0;
          }
        } else if (match$1 !== 66) {
          if (match$1 >= 79) {
            switch (match$1) {
              case 79:
                base = /* Oct */
                0;
                i = i + 2 | 0;
                break;
              case 85:
                i = i + 2 | 0;
                break;
              case 80:
              case 81:
              case 82:
              case 83:
              case 84:
              case 86:
              case 87:
                break;
              case 88:
                base = /* Hex */
                1;
                i = i + 2 | 0;
                break;
            }
          }
        } else {
          base = /* Bin */
          3;
          i = i + 2 | 0;
        }
      }
      return [
        i,
        sign,
        base
      ];
    }
    function caml_int_of_string(s) {
      const match = parse_sign_and_base(s);
      const i = match[0];
      const base = int_of_string_base(match[2]);
      const threshold = 4294967295;
      const len = s.length;
      const c = i < len ? s.charCodeAt(i) : (
        /* '\000' */
        0
      );
      const d = parse_digit(c);
      if (d < 0 || d >= base) {
        throw new Caml_js_exceptions.MelangeError("Failure", {
          MEL_EXN_ID: "Failure",
          _1: "int_of_string"
        });
      }
      const aux = function(_acc, _k) {
        while (true) {
          const k = _k;
          const acc = _acc;
          if (k === len) {
            return acc;
          }
          const a = s.charCodeAt(k);
          if (a === /* '_' */
          95) {
            _k = k + 1 | 0;
            continue;
          }
          const v = parse_digit(a);
          if (v < 0 || v >= base) {
            throw new Caml_js_exceptions.MelangeError("Failure", {
              MEL_EXN_ID: "Failure",
              _1: "int_of_string"
            });
          }
          const acc$1 = base * acc + v;
          if (acc$1 > threshold) {
            throw new Caml_js_exceptions.MelangeError("Failure", {
              MEL_EXN_ID: "Failure",
              _1: "int_of_string"
            });
          }
          _k = k + 1 | 0;
          _acc = acc$1;
          continue;
        }
        ;
      };
      const res = match[1] * aux(d, i + 1 | 0);
      const or_res = res | 0;
      if (base === 10 && res !== or_res) {
        throw new Caml_js_exceptions.MelangeError("Failure", {
          MEL_EXN_ID: "Failure",
          _1: "int_of_string"
        });
      }
      return or_res;
    }
    function caml_int64_of_string(s) {
      const match = parse_sign_and_base(s);
      const hbase = match[2];
      const i = match[0];
      const base = Caml_int64.of_int32(int_of_string_base(hbase));
      const sign = Caml_int64.of_int32(match[1]);
      let threshold;
      switch (hbase) {
        case /* Oct */
        0:
          threshold = [
            536870911,
            4294967295
          ];
          break;
        case /* Hex */
        1:
          threshold = [
            268435455,
            4294967295
          ];
          break;
        case /* Dec */
        2:
          threshold = [
            429496729,
            2576980377
          ];
          break;
        case /* Bin */
        3:
          threshold = Caml_int64.max_int;
          break;
      }
      const len = s.length;
      const c = i < len ? s.charCodeAt(i) : (
        /* '\000' */
        0
      );
      const d = Caml_int64.of_int32(parse_digit(c));
      if (Caml.i64_lt(d, Caml_int64.zero) || Caml.i64_ge(d, base)) {
        throw new Caml_js_exceptions.MelangeError("Failure", {
          MEL_EXN_ID: "Failure",
          _1: "int64_of_string"
        });
      }
      const aux = function(_acc, _k) {
        while (true) {
          const k = _k;
          const acc = _acc;
          if (k === len) {
            return acc;
          }
          const a = s.charCodeAt(k);
          if (a === /* '_' */
          95) {
            _k = k + 1 | 0;
            continue;
          }
          const v = Caml_int64.of_int32(parse_digit(a));
          if (Caml.i64_lt(v, Caml_int64.zero) || Caml.i64_ge(v, base) || Caml.i64_gt(acc, threshold)) {
            throw new Caml_js_exceptions.MelangeError("Failure", {
              MEL_EXN_ID: "Failure",
              _1: "int64_of_string"
            });
          }
          const acc$1 = Caml_int64.add(Caml_int64.mul(base, acc), v);
          _k = k + 1 | 0;
          _acc = acc$1;
          continue;
        }
        ;
      };
      const res = Caml_int64.mul(sign, aux(d, i + 1 | 0));
      const or_res = Caml_int64.or_(res, Caml_int64.zero);
      if (Caml.i64_eq(base, [
        0,
        10
      ]) && Caml.i64_neq(res, or_res)) {
        throw new Caml_js_exceptions.MelangeError("Failure", {
          MEL_EXN_ID: "Failure",
          _1: "int64_of_string"
        });
      }
      return or_res;
    }
    function int_of_base(param) {
      switch (param) {
        case /* Oct */
        0:
          return 8;
        case /* Hex */
        1:
          return 16;
        case /* Dec */
        2:
          return 10;
      }
    }
    function lowercase(c) {
      if (c >= /* 'A' */
      65 && c <= /* 'Z' */
      90 || c >= /* '\192' */
      192 && c <= /* '\214' */
      214 || c >= /* '\216' */
      216 && c <= /* '\222' */
      222) {
        return c + 32 | 0;
      } else {
        return c;
      }
    }
    function parse_format(fmt) {
      const len = fmt.length;
      if (len > 31) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "format_int: format too long"
        });
      }
      let f = {
        justify: "+",
        signstyle: "-",
        filter: " ",
        alternate: false,
        base: (
          /* Dec */
          2
        ),
        signedconv: false,
        width: 0,
        uppercase: false,
        sign: 1,
        prec: -1,
        conv: "f"
      };
      let _i = 0;
      while (true) {
        const i = _i;
        if (i >= len) {
          return f;
        }
        const c = fmt.charCodeAt(i);
        let exit = 0;
        if (c >= 69) {
          if (c >= 88) {
            if (c >= 121) {
              exit = 1;
            } else {
              switch (c) {
                case 88:
                  f.base = /* Hex */
                  1;
                  f.uppercase = true;
                  _i = i + 1 | 0;
                  continue;
                case 101:
                case 102:
                case 103:
                  exit = 5;
                  break;
                case 100:
                case 105:
                  exit = 4;
                  break;
                case 111:
                  f.base = /* Oct */
                  0;
                  _i = i + 1 | 0;
                  continue;
                case 117:
                  f.base = /* Dec */
                  2;
                  _i = i + 1 | 0;
                  continue;
                case 89:
                case 90:
                case 91:
                case 92:
                case 93:
                case 94:
                case 95:
                case 96:
                case 97:
                case 98:
                case 99:
                case 104:
                case 106:
                case 107:
                case 108:
                case 109:
                case 110:
                case 112:
                case 113:
                case 114:
                case 115:
                case 116:
                case 118:
                case 119:
                  exit = 1;
                  break;
                case 120:
                  f.base = /* Hex */
                  1;
                  _i = i + 1 | 0;
                  continue;
              }
            }
          } else if (c >= 72) {
            exit = 1;
          } else {
            f.signedconv = true;
            f.uppercase = true;
            f.conv = String.fromCharCode(lowercase(c));
            _i = i + 1 | 0;
            continue;
          }
        } else {
          switch (c) {
            case 35:
              f.alternate = true;
              _i = i + 1 | 0;
              continue;
            case 32:
            case 43:
              exit = 2;
              break;
            case 45:
              f.justify = "-";
              _i = i + 1 | 0;
              continue;
            case 46:
              f.prec = 0;
              let j = i + 1 | 0;
              while ((function() {
                const w = fmt.charCodeAt(j) - /* '0' */
                48 | 0;
                return w >= 0 && w <= 9;
              })()) {
                f.prec = (Math.imul(f.prec, 10) + fmt.charCodeAt(j) | 0) - /* '0' */
                48 | 0;
                j = j + 1 | 0;
              }
              ;
              _i = j;
              continue;
            case 48:
              f.filter = "0";
              _i = i + 1 | 0;
              continue;
            case 49:
            case 50:
            case 51:
            case 52:
            case 53:
            case 54:
            case 55:
            case 56:
            case 57:
              exit = 3;
              break;
            default:
              exit = 1;
          }
        }
        switch (exit) {
          case 1:
            _i = i + 1 | 0;
            continue;
          case 2:
            f.signstyle = String.fromCharCode(c);
            _i = i + 1 | 0;
            continue;
          case 3:
            f.width = 0;
            let j$1 = i;
            while ((function() {
              const w = fmt.charCodeAt(j$1) - /* '0' */
              48 | 0;
              return w >= 0 && w <= 9;
            })()) {
              f.width = (Math.imul(f.width, 10) + fmt.charCodeAt(j$1) | 0) - /* '0' */
              48 | 0;
              j$1 = j$1 + 1 | 0;
            }
            ;
            _i = j$1;
            continue;
          case 4:
            f.signedconv = true;
            f.base = /* Dec */
            2;
            _i = i + 1 | 0;
            continue;
          case 5:
            f.signedconv = true;
            f.conv = String.fromCharCode(c);
            _i = i + 1 | 0;
            continue;
        }
      }
      ;
    }
    function finish_formatting(config, rawbuffer) {
      const justify = config.justify;
      const signstyle = config.signstyle;
      const filter = config.filter;
      const alternate = config.alternate;
      const base = config.base;
      const signedconv = config.signedconv;
      const width = config.width;
      const uppercase = config.uppercase;
      const sign = config.sign;
      let len = rawbuffer.length;
      if (signedconv && (sign < 0 || signstyle !== "-")) {
        len = len + 1 | 0;
      }
      if (alternate) {
        if (base === /* Oct */
        0) {
          len = len + 1 | 0;
        } else if (base === /* Hex */
        1) {
          len = len + 2 | 0;
        }
      }
      let buffer = "";
      if (justify === "+" && filter === " ") {
        for (let _for = len; _for < width; ++_for) {
          buffer = buffer + filter;
        }
      }
      if (signedconv) {
        if (sign < 0) {
          buffer = buffer + "-";
        } else if (signstyle !== "-") {
          buffer = buffer + signstyle;
        }
      }
      if (alternate && base === /* Oct */
      0) {
        buffer = buffer + "0";
      }
      if (alternate && base === /* Hex */
      1) {
        buffer = buffer + "0x";
      }
      if (justify === "+" && filter === "0") {
        for (let _for$1 = len; _for$1 < width; ++_for$1) {
          buffer = buffer + filter;
        }
      }
      buffer = uppercase ? buffer + rawbuffer.toUpperCase() : buffer + rawbuffer;
      if (justify === "-") {
        for (let _for$2 = len; _for$2 < width; ++_for$2) {
          buffer = buffer + " ";
        }
      }
      return buffer;
    }
    function caml_format_int(fmt, i) {
      if (fmt === "%d") {
        return String(i);
      }
      const f = parse_format(fmt);
      const i$1 = i < 0 ? f.signedconv ? (f.sign = -1, -i >>> 0) : i >>> 0 : i;
      let s = i$1.toString(int_of_base(f.base));
      if (f.prec >= 0) {
        f.filter = " ";
        const n2 = f.prec - s.length | 0;
        if (n2 > 0) {
          s = "0".repeat(n2) + s;
        }
      }
      return finish_formatting(f, s);
    }
    function dec_of_pos_int64(x) {
      if (!Caml.i64_lt(x, Caml_int64.zero)) {
        return Caml_int64.to_string(x);
      }
      const wbase = [
        0,
        10
      ];
      const y = Caml_int64.discard_sign(x);
      const match = Caml_int64.div_mod(y, wbase);
      const match$1 = Caml_int64.div_mod(Caml_int64.add([
        0,
        8
      ], match[1]), wbase);
      const quotient = Caml_int64.add(Caml_int64.add([
        214748364,
        3435973836
      ], match[0]), match$1[0]);
      return Caml_int64.to_string(quotient) + "0123456789"[Caml_int64.to_int32(match$1[1])];
    }
    function oct_of_int64(x) {
      let s = "";
      const wbase = [
        0,
        8
      ];
      const cvtbl = "01234567";
      if (Caml.i64_lt(x, Caml_int64.zero)) {
        const y = Caml_int64.discard_sign(x);
        const match = Caml_int64.div_mod(y, wbase);
        let quotient = Caml_int64.add([
          268435456,
          0
        ], match[0]);
        let modulus = match[1];
        s = cvtbl[Caml_int64.to_int32(modulus)] + s;
        while (Caml.i64_neq(quotient, Caml_int64.zero)) {
          const match$1 = Caml_int64.div_mod(quotient, wbase);
          quotient = match$1[0];
          modulus = match$1[1];
          s = cvtbl[Caml_int64.to_int32(modulus)] + s;
        }
        ;
      } else {
        const match$2 = Caml_int64.div_mod(x, wbase);
        let quotient$1 = match$2[0];
        let modulus$1 = match$2[1];
        s = cvtbl[Caml_int64.to_int32(modulus$1)] + s;
        while (Caml.i64_neq(quotient$1, Caml_int64.zero)) {
          const match$3 = Caml_int64.div_mod(quotient$1, wbase);
          quotient$1 = match$3[0];
          modulus$1 = match$3[1];
          s = cvtbl[Caml_int64.to_int32(modulus$1)] + s;
        }
        ;
      }
      return s;
    }
    function caml_int64_format(fmt, x) {
      if (fmt === "%d") {
        return Caml_int64.to_string(x);
      }
      const f = parse_format(fmt);
      const x$1 = f.signedconv && Caml.i64_lt(x, Caml_int64.zero) ? (f.sign = -1, Caml_int64.neg(x)) : x;
      const match = f.base;
      let s;
      switch (match) {
        case /* Oct */
        0:
          s = oct_of_int64(x$1);
          break;
        case /* Hex */
        1:
          s = Caml_int64.to_hex(x$1);
          break;
        case /* Dec */
        2:
          s = dec_of_pos_int64(x$1);
          break;
      }
      let fill_s;
      if (f.prec >= 0) {
        f.filter = " ";
        const n2 = f.prec - s.length | 0;
        fill_s = n2 > 0 ? "0".repeat(n2) + s : s;
      } else {
        fill_s = s;
      }
      return finish_formatting(f, fill_s);
    }
    function caml_format_float(fmt, x) {
      const f = parse_format(fmt);
      const prec = f.prec < 0 ? 6 : f.prec;
      const x$1 = x < 0 ? (f.sign = -1, -x) : x;
      let s = "";
      if (isNaN(x$1)) {
        s = "nan";
        f.filter = " ";
      } else if (isFinite(x$1)) {
        const match = f.conv;
        switch (match) {
          case "e":
            s = x$1.toExponential(prec);
            const i = s.length;
            if (s[i - 3 | 0] === "e") {
              s = s.slice(0, i - 1 | 0) + ("0" + s.slice(i - 1 | 0));
            }
            break;
          case "f":
            s = x$1.toFixed(prec);
            break;
          case "g":
            const prec$1 = prec !== 0 ? prec : 1;
            s = x$1.toExponential(prec$1 - 1 | 0);
            const j = s.indexOf("e");
            const exp = Number(s.slice(j + 1 | 0)) | 0;
            if (exp < -4 || x$1 >= 1e21 || x$1.toFixed().length > prec$1) {
              let i$1 = j - 1 | 0;
              while (s[i$1] === "0") {
                i$1 = i$1 - 1 | 0;
              }
              ;
              if (s[i$1] === ".") {
                i$1 = i$1 - 1 | 0;
              }
              s = s.slice(0, i$1 + 1 | 0) + s.slice(j);
              const i$2 = s.length;
              if (s[i$2 - 3 | 0] === "e") {
                s = s.slice(0, i$2 - 1 | 0) + ("0" + s.slice(i$2 - 1 | 0));
              }
            } else {
              let p = prec$1;
              if (exp < 0) {
                p = p - (exp + 1 | 0) | 0;
                s = x$1.toFixed(p);
              } else {
                while ((function() {
                  s = x$1.toFixed(p);
                  return s.length > (prec$1 + 1 | 0);
                })()) {
                  p = p - 1 | 0;
                }
                ;
              }
              if (p !== 0) {
                let k = s.length - 1 | 0;
                while (s[k] === "0") {
                  k = k - 1 | 0;
                }
                ;
                if (s[k] === ".") {
                  k = k - 1 | 0;
                }
                s = s.slice(0, k + 1 | 0);
              }
            }
            break;
        }
      } else {
        s = "inf";
        f.filter = " ";
      }
      return finish_formatting(f, s);
    }
    var caml_hexstring_of_float = (function(x, prec, style) {
      if (!isFinite(x)) {
        if (isNaN(x)) return "nan";
        return x > 0 ? "infinity" : "-infinity";
      }
      var sign = x == 0 && 1 / x == -Infinity ? 1 : x >= 0 ? 0 : 1;
      if (sign) x = -x;
      var exp = 0;
      if (x == 0) {
      } else if (x < 1) {
        while (x < 1 && exp > -1022) {
          x *= 2;
          exp--;
        }
      } else {
        while (x >= 2) {
          x /= 2;
          exp++;
        }
      }
      var exp_sign = exp < 0 ? "" : "+";
      var sign_str = "";
      if (sign) sign_str = "-";
      else {
        switch (style) {
          case 43:
            sign_str = "+";
            break;
          case 32:
            sign_str = " ";
            break;
          default:
            break;
        }
      }
      if (prec >= 0 && prec < 13) {
        var cst = Math.pow(2, prec * 4);
        x = Math.round(x * cst) / cst;
      }
      var x_str = x.toString(16);
      if (prec >= 0) {
        var idx = x_str.indexOf(".");
        if (idx < 0) {
          x_str += "." + "0".repeat(prec);
        } else {
          var size = idx + 1 + prec;
          if (x_str.length < size)
            x_str += "0".repeat(size - x_str.length);
          else
            x_str = x_str.substr(0, size);
        }
      }
      return sign_str + "0x" + x_str + "p" + exp_sign + exp.toString(10);
    });
    var float_of_string = (function(s, exn) {
      var res = +s;
      if (s.length > 0 && res === res)
        return res;
      s = s.replace(/_/g, "");
      res = +s;
      if (s.length > 0 && res === res || /^[+-]?nan$/i.test(s)) {
        return res;
      }
      ;
      var m = /^ *([+-]?)0x([0-9a-f]+)\.?([0-9a-f]*)p([+-]?[0-9]+)/i.exec(s);
      if (m) {
        var m3 = m[3].replace(/0+$/, "");
        var mantissa = parseInt(m[1] + m[2] + m3, 16);
        var exponent = (m[4] | 0) - 4 * m3.length;
        res = mantissa * Math.pow(2, exponent);
        return res;
      }
      if (/^\+?inf(inity)?$/i.test(s))
        return Infinity;
      if (/^-inf(inity)?$/i.test(s))
        return -Infinity;
      throw exn;
    });
    function caml_float_of_string(s) {
      return float_of_string(s, new Caml_js_exceptions.MelangeError("Failure", {
        MEL_EXN_ID: "Failure",
        _1: "float_of_string"
      }));
    }
    var caml_nativeint_format = caml_format_int;
    var caml_int32_format = caml_format_int;
    var caml_int32_of_string = caml_int_of_string;
    var caml_nativeint_of_string = caml_int_of_string;
    module2.exports = {
      caml_format_float,
      caml_hexstring_of_float,
      caml_format_int,
      caml_nativeint_format,
      caml_int32_format,
      caml_float_of_string,
      caml_int64_format,
      caml_int_of_string,
      caml_int32_of_string,
      caml_int64_of_string,
      caml_nativeint_of_string
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_io.js
var require_caml_io = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_io.js"(exports2, module2) {
    "use strict";
    var stdout = {
      buffer: "",
      output: (function(param, s) {
        const v = s.length - 1 | 0;
        if (typeof process !== "undefined" && process.stdout && process.stdout.write) {
          return process.stdout.write(s);
        } else {
          if (s[v] === "\n") {
            console.log(s.slice(0, v));
          } else {
            console.log(s);
          }
          return;
        }
      })
    };
    var stderr = {
      buffer: "",
      output: (function(param, s) {
        const v = s.length - 1 | 0;
        if (s[v] === "\n") {
          console.log(s.slice(0, v));
        } else {
          console.log(s);
        }
      })
    };
    function caml_ml_flush(oc) {
      if (oc.buffer !== "") {
        oc.output(oc, oc.buffer);
        oc.buffer = "";
        return;
      }
    }
    function caml_ml_output(oc, str, offset, len) {
      const str$1 = offset === 0 && len === str.length ? str : str.slice(offset, len);
      if (typeof process !== "undefined" && process.stdout && process.stdout.write && oc === stdout) {
        return process.stdout.write(str$1);
      }
      const id = str$1.lastIndexOf("\n");
      if (id < 0) {
        oc.buffer = oc.buffer + str$1;
      } else {
        oc.buffer = oc.buffer + str$1.slice(0, id + 1 | 0);
        caml_ml_flush(oc);
        oc.buffer = oc.buffer + str$1.slice(id + 1 | 0);
      }
    }
    function caml_ml_output_char(oc, $$char) {
      caml_ml_output(oc, String.fromCharCode($$char), 0, 1);
    }
    function caml_ml_out_channels_list(param) {
      return {
        hd: stdout,
        tl: {
          hd: stderr,
          tl: (
            /* [] */
            0
          )
        }
      };
    }
    var stdin;
    module2.exports = {
      stdin,
      stdout,
      stderr,
      caml_ml_flush,
      caml_ml_output,
      caml_ml_output_char,
      caml_ml_out_channels_list
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_string.js
var require_caml_string = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_string.js"(exports2, module2) {
    "use strict";
    var Caml_js_exceptions = require_caml_js_exceptions();
    function get(s, i) {
      if (i >= s.length || i < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      return s.charCodeAt(i);
    }
    function make(n2, ch) {
      return String.fromCharCode(ch).repeat(n2);
    }
    module2.exports = {
      get,
      make
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_sys.js
var require_caml_sys = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_sys.js"(exports2, module2) {
    "use strict";
    var Caml_js_exceptions = require_caml_js_exceptions();
    function caml_sys_getenv(s) {
      if (typeof process === "undefined" || process.env === void 0) {
        throw new Caml_js_exceptions.MelangeError("Not_found", {
          MEL_EXN_ID: "Not_found"
        });
      }
      const x = process.env[s];
      if (x !== void 0) {
        return x;
      }
      throw new Caml_js_exceptions.MelangeError("Not_found", {
        MEL_EXN_ID: "Not_found"
      });
    }
    var os_type = (function(_) {
      if (typeof process !== "undefined" && process.platform === "win32") {
        return "Win32";
      } else {
        return "Unix";
      }
    });
    function caml_sys_time(param) {
      if (typeof process === "undefined" || process.uptime === void 0) {
        return -1;
      } else {
        return process.uptime();
      }
    }
    function caml_sys_system_command(_cmd) {
      return 127;
    }
    var caml_sys_getcwd = (function(param) {
      if (typeof process === "undefined" || process.cwd === void 0) {
        return "/";
      }
      return process.cwd();
    });
    function caml_sys_executable_name(param) {
      if (typeof process === "undefined") {
        return "";
      }
      const argv2 = process.argv;
      if (argv2 == null) {
        return "";
      } else {
        return argv2[0];
      }
    }
    function caml_sys_argv(param) {
      if (typeof process === "undefined") {
        return [""];
      }
      const argv2 = process.argv;
      if (argv2 == null) {
        return [""];
      } else {
        return argv2;
      }
    }
    function caml_sys_exit(exit_code) {
      if (typeof process !== "undefined") {
        return process.exit(exit_code);
      }
    }
    function caml_sys_is_directory(_s) {
      throw new Caml_js_exceptions.MelangeError("Failure", {
        MEL_EXN_ID: "Failure",
        _1: "caml_sys_is_directory not implemented"
      });
    }
    function caml_sys_file_exists(_s) {
      throw new Caml_js_exceptions.MelangeError("Failure", {
        MEL_EXN_ID: "Failure",
        _1: "caml_sys_file_exists not implemented"
      });
    }
    module2.exports = {
      caml_sys_getenv,
      caml_sys_time,
      os_type,
      caml_sys_system_command,
      caml_sys_getcwd,
      caml_sys_executable_name,
      caml_sys_argv,
      caml_sys_exit,
      caml_sys_is_directory,
      caml_sys_file_exists
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/camlinternalFormatBasics.js
var require_camlinternalFormatBasics = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/camlinternalFormatBasics.js"(exports2, module2) {
    "use strict";
    function erase_rel(rest) {
      if (
        /* tag */
        typeof rest === "number" || typeof rest === "string"
      ) {
        return (
          /* End_of_fmtty */
          0
        );
      }
      switch (rest.TAG) {
        case /* Char_ty */
        0:
          return {
            TAG: (
              /* Char_ty */
              0
            ),
            _0: erase_rel(rest._0)
          };
        case /* String_ty */
        1:
          return {
            TAG: (
              /* String_ty */
              1
            ),
            _0: erase_rel(rest._0)
          };
        case /* Int_ty */
        2:
          return {
            TAG: (
              /* Int_ty */
              2
            ),
            _0: erase_rel(rest._0)
          };
        case /* Int32_ty */
        3:
          return {
            TAG: (
              /* Int32_ty */
              3
            ),
            _0: erase_rel(rest._0)
          };
        case /* Nativeint_ty */
        4:
          return {
            TAG: (
              /* Nativeint_ty */
              4
            ),
            _0: erase_rel(rest._0)
          };
        case /* Int64_ty */
        5:
          return {
            TAG: (
              /* Int64_ty */
              5
            ),
            _0: erase_rel(rest._0)
          };
        case /* Float_ty */
        6:
          return {
            TAG: (
              /* Float_ty */
              6
            ),
            _0: erase_rel(rest._0)
          };
        case /* Bool_ty */
        7:
          return {
            TAG: (
              /* Bool_ty */
              7
            ),
            _0: erase_rel(rest._0)
          };
        case /* Format_arg_ty */
        8:
          return {
            TAG: (
              /* Format_arg_ty */
              8
            ),
            _0: rest._0,
            _1: erase_rel(rest._1)
          };
        case /* Format_subst_ty */
        9:
          const ty1 = rest._0;
          return {
            TAG: (
              /* Format_subst_ty */
              9
            ),
            _0: ty1,
            _1: ty1,
            _2: erase_rel(rest._2)
          };
        case /* Alpha_ty */
        10:
          return {
            TAG: (
              /* Alpha_ty */
              10
            ),
            _0: erase_rel(rest._0)
          };
        case /* Theta_ty */
        11:
          return {
            TAG: (
              /* Theta_ty */
              11
            ),
            _0: erase_rel(rest._0)
          };
        case /* Any_ty */
        12:
          return {
            TAG: (
              /* Any_ty */
              12
            ),
            _0: erase_rel(rest._0)
          };
        case /* Reader_ty */
        13:
          return {
            TAG: (
              /* Reader_ty */
              13
            ),
            _0: erase_rel(rest._0)
          };
        case /* Ignored_reader_ty */
        14:
          return {
            TAG: (
              /* Ignored_reader_ty */
              14
            ),
            _0: erase_rel(rest._0)
          };
      }
    }
    function concat_fmtty(fmtty1, fmtty2) {
      if (
        /* tag */
        typeof fmtty1 === "number" || typeof fmtty1 === "string"
      ) {
        return fmtty2;
      }
      switch (fmtty1.TAG) {
        case /* Char_ty */
        0:
          return {
            TAG: (
              /* Char_ty */
              0
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* String_ty */
        1:
          return {
            TAG: (
              /* String_ty */
              1
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Int_ty */
        2:
          return {
            TAG: (
              /* Int_ty */
              2
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Int32_ty */
        3:
          return {
            TAG: (
              /* Int32_ty */
              3
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Nativeint_ty */
        4:
          return {
            TAG: (
              /* Nativeint_ty */
              4
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Int64_ty */
        5:
          return {
            TAG: (
              /* Int64_ty */
              5
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Float_ty */
        6:
          return {
            TAG: (
              /* Float_ty */
              6
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Bool_ty */
        7:
          return {
            TAG: (
              /* Bool_ty */
              7
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Format_arg_ty */
        8:
          return {
            TAG: (
              /* Format_arg_ty */
              8
            ),
            _0: fmtty1._0,
            _1: concat_fmtty(fmtty1._1, fmtty2)
          };
        case /* Format_subst_ty */
        9:
          return {
            TAG: (
              /* Format_subst_ty */
              9
            ),
            _0: fmtty1._0,
            _1: fmtty1._1,
            _2: concat_fmtty(fmtty1._2, fmtty2)
          };
        case /* Alpha_ty */
        10:
          return {
            TAG: (
              /* Alpha_ty */
              10
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Theta_ty */
        11:
          return {
            TAG: (
              /* Theta_ty */
              11
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Any_ty */
        12:
          return {
            TAG: (
              /* Any_ty */
              12
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Reader_ty */
        13:
          return {
            TAG: (
              /* Reader_ty */
              13
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
        case /* Ignored_reader_ty */
        14:
          return {
            TAG: (
              /* Ignored_reader_ty */
              14
            ),
            _0: concat_fmtty(fmtty1._0, fmtty2)
          };
      }
    }
    function concat_fmt(fmt1, fmt2) {
      if (
        /* tag */
        typeof fmt1 === "number" || typeof fmt1 === "string"
      ) {
        return fmt2;
      }
      switch (fmt1.TAG) {
        case /* Char */
        0:
          return {
            TAG: (
              /* Char */
              0
            ),
            _0: concat_fmt(fmt1._0, fmt2)
          };
        case /* Caml_char */
        1:
          return {
            TAG: (
              /* Caml_char */
              1
            ),
            _0: concat_fmt(fmt1._0, fmt2)
          };
        case /* String */
        2:
          return {
            TAG: (
              /* String */
              2
            ),
            _0: fmt1._0,
            _1: concat_fmt(fmt1._1, fmt2)
          };
        case /* Caml_string */
        3:
          return {
            TAG: (
              /* Caml_string */
              3
            ),
            _0: fmt1._0,
            _1: concat_fmt(fmt1._1, fmt2)
          };
        case /* Int */
        4:
          return {
            TAG: (
              /* Int */
              4
            ),
            _0: fmt1._0,
            _1: fmt1._1,
            _2: fmt1._2,
            _3: concat_fmt(fmt1._3, fmt2)
          };
        case /* Int32 */
        5:
          return {
            TAG: (
              /* Int32 */
              5
            ),
            _0: fmt1._0,
            _1: fmt1._1,
            _2: fmt1._2,
            _3: concat_fmt(fmt1._3, fmt2)
          };
        case /* Nativeint */
        6:
          return {
            TAG: (
              /* Nativeint */
              6
            ),
            _0: fmt1._0,
            _1: fmt1._1,
            _2: fmt1._2,
            _3: concat_fmt(fmt1._3, fmt2)
          };
        case /* Int64 */
        7:
          return {
            TAG: (
              /* Int64 */
              7
            ),
            _0: fmt1._0,
            _1: fmt1._1,
            _2: fmt1._2,
            _3: concat_fmt(fmt1._3, fmt2)
          };
        case /* Float */
        8:
          return {
            TAG: (
              /* Float */
              8
            ),
            _0: fmt1._0,
            _1: fmt1._1,
            _2: fmt1._2,
            _3: concat_fmt(fmt1._3, fmt2)
          };
        case /* Bool */
        9:
          return {
            TAG: (
              /* Bool */
              9
            ),
            _0: fmt1._0,
            _1: concat_fmt(fmt1._1, fmt2)
          };
        case /* Flush */
        10:
          return {
            TAG: (
              /* Flush */
              10
            ),
            _0: concat_fmt(fmt1._0, fmt2)
          };
        case /* String_literal */
        11:
          return {
            TAG: (
              /* String_literal */
              11
            ),
            _0: fmt1._0,
            _1: concat_fmt(fmt1._1, fmt2)
          };
        case /* Char_literal */
        12:
          return {
            TAG: (
              /* Char_literal */
              12
            ),
            _0: fmt1._0,
            _1: concat_fmt(fmt1._1, fmt2)
          };
        case /* Format_arg */
        13:
          return {
            TAG: (
              /* Format_arg */
              13
            ),
            _0: fmt1._0,
            _1: fmt1._1,
            _2: concat_fmt(fmt1._2, fmt2)
          };
        case /* Format_subst */
        14:
          return {
            TAG: (
              /* Format_subst */
              14
            ),
            _0: fmt1._0,
            _1: fmt1._1,
            _2: concat_fmt(fmt1._2, fmt2)
          };
        case /* Alpha */
        15:
          return {
            TAG: (
              /* Alpha */
              15
            ),
            _0: concat_fmt(fmt1._0, fmt2)
          };
        case /* Theta */
        16:
          return {
            TAG: (
              /* Theta */
              16
            ),
            _0: concat_fmt(fmt1._0, fmt2)
          };
        case /* Formatting_lit */
        17:
          return {
            TAG: (
              /* Formatting_lit */
              17
            ),
            _0: fmt1._0,
            _1: concat_fmt(fmt1._1, fmt2)
          };
        case /* Formatting_gen */
        18:
          return {
            TAG: (
              /* Formatting_gen */
              18
            ),
            _0: fmt1._0,
            _1: concat_fmt(fmt1._1, fmt2)
          };
        case /* Reader */
        19:
          return {
            TAG: (
              /* Reader */
              19
            ),
            _0: concat_fmt(fmt1._0, fmt2)
          };
        case /* Scan_char_set */
        20:
          return {
            TAG: (
              /* Scan_char_set */
              20
            ),
            _0: fmt1._0,
            _1: fmt1._1,
            _2: concat_fmt(fmt1._2, fmt2)
          };
        case /* Scan_get_counter */
        21:
          return {
            TAG: (
              /* Scan_get_counter */
              21
            ),
            _0: fmt1._0,
            _1: concat_fmt(fmt1._1, fmt2)
          };
        case /* Scan_next_char */
        22:
          return {
            TAG: (
              /* Scan_next_char */
              22
            ),
            _0: concat_fmt(fmt1._0, fmt2)
          };
        case /* Ignored_param */
        23:
          return {
            TAG: (
              /* Ignored_param */
              23
            ),
            _0: fmt1._0,
            _1: concat_fmt(fmt1._1, fmt2)
          };
        case /* Custom */
        24:
          return {
            TAG: (
              /* Custom */
              24
            ),
            _0: fmt1._0,
            _1: fmt1._1,
            _2: concat_fmt(fmt1._2, fmt2)
          };
      }
    }
    module2.exports = {
      concat_fmtty,
      erase_rel,
      concat_fmt
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/stdlib.js
var require_stdlib = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/stdlib.js"(exports2, module2) {
    "use strict";
    var Caml_bytes = require_caml_bytes();
    var Caml_exceptions = require_caml_exceptions();
    var Caml_external_polyfill = require_caml_external_polyfill();
    var Caml_format = require_caml_format();
    var Caml_io = require_caml_io();
    var Caml_js_exceptions = require_caml_js_exceptions();
    var Caml_string = require_caml_string();
    var Caml_sys = require_caml_sys();
    var CamlinternalFormatBasics = require_camlinternalFormatBasics();
    var Curry2 = require_curry();
    function failwith(s) {
      throw new Caml_js_exceptions.MelangeError("Failure", {
        MEL_EXN_ID: "Failure",
        _1: s
      });
    }
    function invalid_arg(s) {
      throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
        MEL_EXN_ID: "Invalid_argument",
        _1: s
      });
    }
    var Exit = /* @__PURE__ */ Caml_exceptions.create("Stdlib.Exit");
    var Failure = "Failure";
    var Sys_error = "Sys_error";
    var End_of_file = "End_of_file";
    function abs(x) {
      if (x >= 0) {
        return x;
      } else {
        return -x | 0;
      }
    }
    function lnot(x) {
      return x ^ -1;
    }
    var min_int = -2147483648;
    function classify_float(x) {
      if (isFinite(x)) {
        if (Math.abs(x) >= 22250738585072014e-324) {
          return (
            /* FP_normal */
            0
          );
        } else if (x !== 0) {
          return (
            /* FP_subnormal */
            1
          );
        } else {
          return (
            /* FP_zero */
            2
          );
        }
      } else if (isNaN(x)) {
        return (
          /* FP_nan */
          4
        );
      } else {
        return (
          /* FP_infinite */
          3
        );
      }
    }
    function char_of_int(n2) {
      if (n2 < 0 || n2 > 255) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "char_of_int"
        });
      }
      return n2;
    }
    function string_of_bool(b) {
      if (b) {
        return "true";
      } else {
        return "false";
      }
    }
    function bool_of_string(param) {
      switch (param) {
        case "false":
          return false;
        case "true":
          return true;
        default:
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "bool_of_string"
          });
      }
    }
    function bool_of_string_opt(param) {
      switch (param) {
        case "false":
          return false;
        case "true":
          return true;
        default:
          return;
      }
    }
    function int_of_string_opt(s) {
      try {
        return Caml_format.caml_int_of_string(s);
      } catch (raw_exn) {
        const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
        if (exn.MEL_EXN_ID === Failure) {
          return;
        }
        throw exn;
      }
    }
    function valid_float_lexem(s) {
      const l = s.length;
      let _i = 0;
      while (true) {
        const i = _i;
        if (i >= l) {
          return s + ".";
        }
        const match = Caml_string.get(s, i);
        if (match >= 48) {
          if (match >= 58) {
            return s;
          }
          _i = i + 1 | 0;
          continue;
        }
        if (match !== 45) {
          return s;
        }
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function string_of_float(f) {
      return valid_float_lexem(Caml_format.caml_format_float("%.12g", f));
    }
    function float_of_string_opt(s) {
      try {
        return Caml_format.caml_float_of_string(s);
      } catch (raw_exn) {
        const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
        if (exn.MEL_EXN_ID === Failure) {
          return;
        }
        throw exn;
      }
    }
    function $at_dps(_dst, _offset, _l1, l2) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const l1 = _l1;
        if (!l1) {
          dst[offset] = l2;
          return;
        }
        const match = l1.tl;
        const h1 = l1.hd;
        if (!match) {
          dst[offset] = {
            hd: h1,
            tl: l2
          };
          return;
        }
        const match$1 = match.tl;
        const h2 = match.hd;
        if (!match$1) {
          dst[offset] = {
            hd: h1,
            tl: {
              hd: h2,
              tl: l2
            }
          };
          return;
        }
        const block = {
          hd: match$1.hd,
          tl: 24029
        };
        dst[offset] = {
          hd: h1,
          tl: {
            hd: h2,
            tl: block
          }
        };
        _l1 = match$1.tl;
        _offset = "tl";
        _dst = block;
        continue;
      }
      ;
    }
    function $at(l1, l2) {
      if (!l1) {
        return l2;
      }
      const match = l1.tl;
      const h1 = l1.hd;
      if (!match) {
        return {
          hd: h1,
          tl: l2
        };
      }
      const match$1 = match.tl;
      const h2 = match.hd;
      if (!match$1) {
        return {
          hd: h1,
          tl: {
            hd: h2,
            tl: l2
          }
        };
      }
      const block = {
        hd: match$1.hd,
        tl: 24029
      };
      return {
        hd: h1,
        tl: {
          hd: h2,
          tl: ($at_dps(block, "tl", match$1.tl, l2), block)
        }
      };
    }
    var stdin = Caml_io.stdin;
    var stdout = Caml_io.stdout;
    var stderr = Caml_io.stderr;
    function open_out_gen(mode, perm, name) {
      const c = Caml_external_polyfill.resolve("caml_ml_open_descriptor_out")(Caml_external_polyfill.resolve("caml_sys_open")(name, mode, perm));
      Caml_external_polyfill.resolve("caml_ml_set_channel_name")(c, name);
      return c;
    }
    function open_out(name) {
      return open_out_gen({
        hd: (
          /* Open_wronly */
          1
        ),
        tl: {
          hd: (
            /* Open_creat */
            3
          ),
          tl: {
            hd: (
              /* Open_trunc */
              4
            ),
            tl: {
              hd: (
                /* Open_text */
                7
              ),
              tl: (
                /* [] */
                0
              )
            }
          }
        }
      }, 438, name);
    }
    function open_out_bin(name) {
      return open_out_gen({
        hd: (
          /* Open_wronly */
          1
        ),
        tl: {
          hd: (
            /* Open_creat */
            3
          ),
          tl: {
            hd: (
              /* Open_trunc */
              4
            ),
            tl: {
              hd: (
                /* Open_binary */
                6
              ),
              tl: (
                /* [] */
                0
              )
            }
          }
        }
      }, 438, name);
    }
    function flush_all(param) {
      let _param = Caml_io.caml_ml_out_channels_list(void 0);
      while (true) {
        const param$1 = _param;
        if (!param$1) {
          return;
        }
        try {
          Caml_io.caml_ml_flush(param$1.hd);
        } catch (raw_exn) {
          const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
          if (exn.MEL_EXN_ID !== Sys_error) {
            throw exn;
          }
        }
        _param = param$1.tl;
        continue;
      }
      ;
    }
    function output_bytes(oc, s) {
      Caml_external_polyfill.resolve("caml_ml_output_bytes")(oc, s, 0, s.length);
    }
    function output_string(oc, s) {
      Caml_io.caml_ml_output(oc, s, 0, s.length);
    }
    function output(oc, s, ofs, len) {
      if (ofs < 0 || len < 0 || ofs > (s.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "output"
        });
      }
      Caml_external_polyfill.resolve("caml_ml_output_bytes")(oc, s, ofs, len);
    }
    function output_substring(oc, s, ofs, len) {
      if (ofs < 0 || len < 0 || ofs > (s.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "output_substring"
        });
      }
      Caml_io.caml_ml_output(oc, s, ofs, len);
    }
    function output_value(chan, v) {
      Caml_external_polyfill.resolve("caml_output_value")(
        chan,
        v,
        /* [] */
        0
      );
    }
    function close_out(oc) {
      Caml_io.caml_ml_flush(oc);
      Caml_external_polyfill.resolve("caml_ml_close_channel")(oc);
    }
    function close_out_noerr(oc) {
      try {
        Caml_io.caml_ml_flush(oc);
      } catch (exn) {
      }
      try {
        return Caml_external_polyfill.resolve("caml_ml_close_channel")(oc);
      } catch (exn$1) {
        return;
      }
    }
    function open_in_gen(mode, perm, name) {
      const c = Caml_external_polyfill.resolve("caml_ml_open_descriptor_in")(Caml_external_polyfill.resolve("caml_sys_open")(name, mode, perm));
      Caml_external_polyfill.resolve("caml_ml_set_channel_name")(c, name);
      return c;
    }
    function open_in(name) {
      return open_in_gen({
        hd: (
          /* Open_rdonly */
          0
        ),
        tl: {
          hd: (
            /* Open_text */
            7
          ),
          tl: (
            /* [] */
            0
          )
        }
      }, 0, name);
    }
    function open_in_bin(name) {
      return open_in_gen({
        hd: (
          /* Open_rdonly */
          0
        ),
        tl: {
          hd: (
            /* Open_binary */
            6
          ),
          tl: (
            /* [] */
            0
          )
        }
      }, 0, name);
    }
    function input(ic, s, ofs, len) {
      if (ofs < 0 || len < 0 || ofs > (s.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "input"
        });
      }
      return Caml_external_polyfill.resolve("caml_ml_input")(ic, s, ofs, len);
    }
    function unsafe_really_input(ic, s, _ofs, _len) {
      while (true) {
        const len = _len;
        const ofs = _ofs;
        if (len <= 0) {
          return;
        }
        const r = Caml_external_polyfill.resolve("caml_ml_input")(ic, s, ofs, len);
        if (r === 0) {
          throw new Caml_js_exceptions.MelangeError(End_of_file, {
            MEL_EXN_ID: End_of_file
          });
        }
        _len = len - r | 0;
        _ofs = ofs + r | 0;
        continue;
      }
      ;
    }
    function really_input(ic, s, ofs, len) {
      if (ofs < 0 || len < 0 || ofs > (s.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "really_input"
        });
      }
      unsafe_really_input(ic, s, ofs, len);
    }
    function really_input_string(ic, len) {
      const s = Caml_bytes.caml_create_bytes(len);
      really_input(ic, s, 0, len);
      return Caml_bytes.bytes_to_string(s);
    }
    function input_line(chan) {
      const build_result = function(buf, _pos, _param) {
        while (true) {
          const param = _param;
          const pos = _pos;
          if (!param) {
            return buf;
          }
          const hd = param.hd;
          const len = hd.length;
          Caml_bytes.caml_blit_bytes(hd, 0, buf, pos - len | 0, len);
          _param = param.tl;
          _pos = pos - len | 0;
          continue;
        }
        ;
      };
      const scan = function(_accu, _len) {
        while (true) {
          const len = _len;
          const accu = _accu;
          const n2 = Caml_external_polyfill.resolve("caml_ml_input_scan_line")(chan);
          if (n2 === 0) {
            if (accu) {
              return build_result(Caml_bytes.caml_create_bytes(len), len, accu);
            }
            throw new Caml_js_exceptions.MelangeError(End_of_file, {
              MEL_EXN_ID: End_of_file
            });
          }
          if (n2 > 0) {
            const res = Caml_bytes.caml_create_bytes(n2 - 1 | 0);
            Caml_external_polyfill.resolve("caml_ml_input")(chan, res, 0, n2 - 1 | 0);
            Caml_external_polyfill.resolve("caml_ml_input_char")(chan);
            if (!accu) {
              return res;
            }
            const len$1 = (len + n2 | 0) - 1 | 0;
            return build_result(Caml_bytes.caml_create_bytes(len$1), len$1, {
              hd: res,
              tl: accu
            });
          }
          const beg = Caml_bytes.caml_create_bytes(-n2 | 0);
          Caml_external_polyfill.resolve("caml_ml_input")(chan, beg, 0, -n2 | 0);
          _len = len - n2 | 0;
          _accu = {
            hd: beg,
            tl: accu
          };
          continue;
        }
        ;
      };
      return Caml_bytes.bytes_to_string(scan(
        /* [] */
        0,
        0
      ));
    }
    function close_in_noerr(ic) {
      try {
        return Caml_external_polyfill.resolve("caml_ml_close_channel")(ic);
      } catch (exn) {
        return;
      }
    }
    function print_char(c) {
      Caml_io.caml_ml_output_char(stdout, c);
    }
    function print_string(s) {
      output_string(stdout, s);
    }
    function print_bytes(s) {
      output_bytes(stdout, s);
    }
    function print_int(i) {
      output_string(stdout, String(i));
    }
    function print_float(f) {
      output_string(stdout, valid_float_lexem(Caml_format.caml_format_float("%.12g", f)));
    }
    function print_newline(param) {
      Caml_io.caml_ml_output_char(
        stdout,
        /* '\n' */
        10
      );
      Caml_io.caml_ml_flush(stdout);
    }
    function prerr_char(c) {
      Caml_io.caml_ml_output_char(stderr, c);
    }
    function prerr_string(s) {
      output_string(stderr, s);
    }
    function prerr_bytes(s) {
      output_bytes(stderr, s);
    }
    function prerr_int(i) {
      output_string(stderr, String(i));
    }
    function prerr_float(f) {
      output_string(stderr, valid_float_lexem(Caml_format.caml_format_float("%.12g", f)));
    }
    function prerr_newline(param) {
      Caml_io.caml_ml_output_char(
        stderr,
        /* '\n' */
        10
      );
      Caml_io.caml_ml_flush(stderr);
    }
    function read_line(param) {
      Caml_io.caml_ml_flush(stdout);
      return input_line(stdin);
    }
    function read_int(param) {
      return Caml_format.caml_int_of_string((Caml_io.caml_ml_flush(stdout), input_line(stdin)));
    }
    function read_int_opt(param) {
      return int_of_string_opt((Caml_io.caml_ml_flush(stdout), input_line(stdin)));
    }
    function read_float(param) {
      return Caml_format.caml_float_of_string((Caml_io.caml_ml_flush(stdout), input_line(stdin)));
    }
    function read_float_opt(param) {
      return float_of_string_opt((Caml_io.caml_ml_flush(stdout), input_line(stdin)));
    }
    function string_of_format(param) {
      return param._1;
    }
    function $caret$caret(param, param$1) {
      return {
        TAG: (
          /* Format */
          0
        ),
        _0: CamlinternalFormatBasics.concat_fmt(param._0, param$1._0),
        _1: param._1 + ("%," + param$1._1)
      };
    }
    var exit_function = {
      contents: flush_all
    };
    function at_exit(f) {
      const f_yet_to_run = {
        contents: true
      };
      const old_exit = exit_function.contents;
      const new_exit = function(param) {
        if (!f_yet_to_run.contents) {
          f_yet_to_run.contents = false;
          Curry2._1(f, void 0);
        }
        Curry2._1(old_exit, void 0);
      };
      exit_function.contents = new_exit;
    }
    var do_domain_local_at_exit = {
      contents: (function(param) {
      })
    };
    function do_at_exit(param) {
      Curry2._1(do_domain_local_at_exit.contents, void 0);
      Curry2._1(exit_function.contents, void 0);
    }
    function exit(retcode) {
      do_at_exit(void 0);
      return Caml_sys.caml_sys_exit(retcode);
    }
    var Match_failure = "Match_failure";
    var Assert_failure = "Assert_failure";
    var Invalid_argument = "Invalid_argument";
    var Not_found = "Not_found";
    var Out_of_memory = "Out_of_memory";
    var Stack_overflow = "Stack_overflow";
    var Division_by_zero = "Division_by_zero";
    var Sys_blocked_io = "Sys_blocked_io";
    var Undefined_recursive_module = "Undefined_recursive_module";
    var max_int = 2147483647;
    var infinity = Infinity;
    var neg_infinity = -Infinity;
    var max_float = 17976931348623157e292;
    var min_float = 22250738585072014e-324;
    var epsilon_float = 2220446049250313e-31;
    var flush = Caml_io.caml_ml_flush;
    var output_char = Caml_io.caml_ml_output_char;
    var output_byte = Caml_io.caml_ml_output_char;
    function output_binary_int(prim0, prim1) {
      return Caml_external_polyfill.resolve("caml_ml_output_int")(prim0, prim1);
    }
    function seek_out(prim0, prim1) {
      return Caml_external_polyfill.resolve("caml_ml_seek_out")(prim0, prim1);
    }
    function pos_out(prim) {
      return Caml_external_polyfill.resolve("caml_ml_pos_out")(prim);
    }
    function out_channel_length(prim) {
      return Caml_external_polyfill.resolve("caml_ml_channel_size")(prim);
    }
    function set_binary_mode_out(prim0, prim1) {
      return Caml_external_polyfill.resolve("caml_ml_set_binary_mode")(prim0, prim1);
    }
    function input_char(prim) {
      return Caml_external_polyfill.resolve("caml_ml_input_char")(prim);
    }
    function input_byte(prim) {
      return Caml_external_polyfill.resolve("caml_ml_input_char")(prim);
    }
    function input_binary_int(prim) {
      return Caml_external_polyfill.resolve("caml_ml_input_int")(prim);
    }
    function input_value(prim) {
      return Caml_external_polyfill.resolve("caml_input_value")(prim);
    }
    function seek_in(prim0, prim1) {
      return Caml_external_polyfill.resolve("caml_ml_seek_in")(prim0, prim1);
    }
    function pos_in(prim) {
      return Caml_external_polyfill.resolve("caml_ml_pos_in")(prim);
    }
    function in_channel_length(prim) {
      return Caml_external_polyfill.resolve("caml_ml_channel_size")(prim);
    }
    function close_in(prim) {
      return Caml_external_polyfill.resolve("caml_ml_close_channel")(prim);
    }
    function set_binary_mode_in(prim0, prim1) {
      return Caml_external_polyfill.resolve("caml_ml_set_binary_mode")(prim0, prim1);
    }
    function LargeFile_seek_out(prim0, prim1) {
      return Caml_external_polyfill.resolve("caml_ml_seek_out_64")(prim0, prim1);
    }
    function LargeFile_pos_out(prim) {
      return Caml_external_polyfill.resolve("caml_ml_pos_out_64")(prim);
    }
    function LargeFile_out_channel_length(prim) {
      return Caml_external_polyfill.resolve("caml_ml_channel_size_64")(prim);
    }
    function LargeFile_seek_in(prim0, prim1) {
      return Caml_external_polyfill.resolve("caml_ml_seek_in_64")(prim0, prim1);
    }
    function LargeFile_pos_in(prim) {
      return Caml_external_polyfill.resolve("caml_ml_pos_in_64")(prim);
    }
    function LargeFile_in_channel_length(prim) {
      return Caml_external_polyfill.resolve("caml_ml_channel_size_64")(prim);
    }
    var LargeFile = {
      seek_out: LargeFile_seek_out,
      pos_out: LargeFile_pos_out,
      out_channel_length: LargeFile_out_channel_length,
      seek_in: LargeFile_seek_in,
      pos_in: LargeFile_pos_in,
      in_channel_length: LargeFile_in_channel_length
    };
    module2.exports = {
      invalid_arg,
      failwith,
      Exit,
      Match_failure,
      Assert_failure,
      Invalid_argument,
      Failure,
      Not_found,
      Out_of_memory,
      Stack_overflow,
      Sys_error,
      End_of_file,
      Division_by_zero,
      Sys_blocked_io,
      Undefined_recursive_module,
      abs,
      max_int,
      min_int,
      lnot,
      infinity,
      neg_infinity,
      max_float,
      min_float,
      epsilon_float,
      classify_float,
      char_of_int,
      string_of_bool,
      bool_of_string_opt,
      bool_of_string,
      int_of_string_opt,
      string_of_float,
      float_of_string_opt,
      $at,
      stdin,
      stdout,
      stderr,
      print_char,
      print_string,
      print_bytes,
      print_int,
      print_float,
      print_newline,
      prerr_char,
      prerr_string,
      prerr_bytes,
      prerr_int,
      prerr_float,
      prerr_newline,
      read_line,
      read_int_opt,
      read_int,
      read_float_opt,
      read_float,
      open_out,
      open_out_bin,
      open_out_gen,
      flush,
      flush_all,
      output_char,
      output_string,
      output_bytes,
      output,
      output_substring,
      output_byte,
      output_binary_int,
      output_value,
      seek_out,
      pos_out,
      out_channel_length,
      close_out,
      close_out_noerr,
      set_binary_mode_out,
      open_in,
      open_in_bin,
      open_in_gen,
      input_char,
      input_line,
      input,
      really_input,
      really_input_string,
      input_byte,
      input_binary_int,
      input_value,
      seek_in,
      pos_in,
      in_channel_length,
      close_in,
      close_in_noerr,
      set_binary_mode_in,
      LargeFile,
      string_of_format,
      $caret$caret,
      exit,
      at_exit,
      valid_float_lexem,
      unsafe_really_input,
      do_at_exit,
      do_domain_local_at_exit
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/list.js
var require_list = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/list.js"(exports2, module2) {
    "use strict";
    var Caml_js_exceptions = require_caml_js_exceptions();
    var Caml_obj = require_caml_obj();
    var Caml_option = require_caml_option();
    var Curry2 = require_curry();
    var Stdlib = require_stdlib();
    function length(l) {
      let _len = 0;
      let _param = l;
      while (true) {
        const param = _param;
        const len = _len;
        if (!param) {
          return len;
        }
        _param = param.tl;
        _len = len + 1 | 0;
        continue;
      }
      ;
    }
    function cons(a, l) {
      return {
        hd: a,
        tl: l
      };
    }
    function hd(param) {
      if (param) {
        return param.hd;
      }
      throw new Caml_js_exceptions.MelangeError("Failure", {
        MEL_EXN_ID: "Failure",
        _1: "hd"
      });
    }
    function tl(param) {
      if (param) {
        return param.tl;
      }
      throw new Caml_js_exceptions.MelangeError("Failure", {
        MEL_EXN_ID: "Failure",
        _1: "tl"
      });
    }
    function nth(l, n2) {
      if (n2 < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.nth"
        });
      }
      let _l = l;
      let _n = n2;
      while (true) {
        const n$1 = _n;
        const l$1 = _l;
        if (l$1) {
          if (n$1 === 0) {
            return l$1.hd;
          }
          _n = n$1 - 1 | 0;
          _l = l$1.tl;
          continue;
        }
        throw new Caml_js_exceptions.MelangeError("Failure", {
          MEL_EXN_ID: "Failure",
          _1: "nth"
        });
      }
      ;
    }
    function nth_opt(l, n2) {
      if (n2 < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.nth"
        });
      }
      let _l = l;
      let _n = n2;
      while (true) {
        const n$1 = _n;
        const l$1 = _l;
        if (!l$1) {
          return;
        }
        if (n$1 === 0) {
          return Caml_option.some(l$1.hd);
        }
        _n = n$1 - 1 | 0;
        _l = l$1.tl;
        continue;
      }
      ;
    }
    function rev_append(_l1, _l2) {
      while (true) {
        const l2 = _l2;
        const l1 = _l1;
        if (!l1) {
          return l2;
        }
        _l2 = {
          hd: l1.hd,
          tl: l2
        };
        _l1 = l1.tl;
        continue;
      }
      ;
    }
    function rev(l) {
      return rev_append(
        l,
        /* [] */
        0
      );
    }
    function init_dps(_dst, _offset, _i, last, f) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const i = _i;
        if (i > last) {
          dst[offset] = /* [] */
          0;
          return;
        }
        if (i === last) {
          dst[offset] = {
            hd: Curry2._1(f, i),
            tl: (
              /* [] */
              0
            )
          };
          return;
        }
        const r1 = Curry2._1(f, i);
        const r2 = Curry2._1(f, i + 1 | 0);
        const block = {
          hd: r2,
          tl: 24029
        };
        dst[offset] = {
          hd: r1,
          tl: block
        };
        _i = i + 2 | 0;
        _offset = "tl";
        _dst = block;
        continue;
      }
      ;
    }
    function init(len, f) {
      if (len < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.init"
        });
      }
      let i = 0;
      let last = len - 1 | 0;
      if (i > last) {
        return (
          /* [] */
          0
        );
      }
      if (i === last) {
        return {
          hd: Curry2._1(f, i),
          tl: (
            /* [] */
            0
          )
        };
      }
      const r1 = Curry2._1(f, i);
      const r2 = Curry2._1(f, i + 1 | 0);
      const block = {
        hd: r2,
        tl: 24029
      };
      return {
        hd: r1,
        tl: (init_dps(block, "tl", i + 2 | 0, last, f), block)
      };
    }
    function flatten(param) {
      if (param) {
        return Stdlib.$at(param.hd, flatten(param.tl));
      } else {
        return (
          /* [] */
          0
        );
      }
    }
    function map_dps(_dst, _offset, f, _param) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const param = _param;
        if (!param) {
          dst[offset] = /* [] */
          0;
          return;
        }
        const match = param.tl;
        const a1 = param.hd;
        if (match) {
          const r1 = Curry2._1(f, a1);
          const r2 = Curry2._1(f, match.hd);
          const block = {
            hd: r2,
            tl: 24029
          };
          dst[offset] = {
            hd: r1,
            tl: block
          };
          _param = match.tl;
          _offset = "tl";
          _dst = block;
          continue;
        }
        const r1$1 = Curry2._1(f, a1);
        dst[offset] = {
          hd: r1$1,
          tl: (
            /* [] */
            0
          )
        };
        return;
      }
      ;
    }
    function map(f, param) {
      if (!param) {
        return (
          /* [] */
          0
        );
      }
      const match = param.tl;
      const a1 = param.hd;
      if (match) {
        const r1 = Curry2._1(f, a1);
        const r2 = Curry2._1(f, match.hd);
        const block = {
          hd: r2,
          tl: 24029
        };
        return {
          hd: r1,
          tl: (map_dps(block, "tl", f, match.tl), block)
        };
      }
      const r1$1 = Curry2._1(f, a1);
      return {
        hd: r1$1,
        tl: (
          /* [] */
          0
        )
      };
    }
    function mapi_dps(_dst, _offset, _i, f, _param) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const i = _i;
        const param = _param;
        if (!param) {
          dst[offset] = /* [] */
          0;
          return;
        }
        const match = param.tl;
        const a1 = param.hd;
        if (match) {
          const r1 = Curry2._2(f, i, a1);
          const r2 = Curry2._2(f, i + 1 | 0, match.hd);
          const block = {
            hd: r2,
            tl: 24029
          };
          dst[offset] = {
            hd: r1,
            tl: block
          };
          _param = match.tl;
          _i = i + 2 | 0;
          _offset = "tl";
          _dst = block;
          continue;
        }
        const r1$1 = Curry2._2(f, i, a1);
        dst[offset] = {
          hd: r1$1,
          tl: (
            /* [] */
            0
          )
        };
        return;
      }
      ;
    }
    function mapi(f, l) {
      let i = 0;
      if (!l) {
        return (
          /* [] */
          0
        );
      }
      const match = l.tl;
      const a1 = l.hd;
      if (match) {
        const r1 = Curry2._2(f, i, a1);
        const r2 = Curry2._2(f, i + 1 | 0, match.hd);
        const block = {
          hd: r2,
          tl: 24029
        };
        return {
          hd: r1,
          tl: (mapi_dps(block, "tl", i + 2 | 0, f, match.tl), block)
        };
      }
      const r1$1 = Curry2._2(f, i, a1);
      return {
        hd: r1$1,
        tl: (
          /* [] */
          0
        )
      };
    }
    function rev_map(f, l) {
      let _accu = (
        /* [] */
        0
      );
      let _param = l;
      while (true) {
        const param = _param;
        const accu = _accu;
        if (!param) {
          return accu;
        }
        _param = param.tl;
        _accu = {
          hd: Curry2._1(f, param.hd),
          tl: accu
        };
        continue;
      }
      ;
    }
    function iter(f, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return;
        }
        Curry2._1(f, param.hd);
        _param = param.tl;
        continue;
      }
      ;
    }
    function iteri(f, l) {
      let _i = 0;
      let _param = l;
      while (true) {
        const param = _param;
        const i = _i;
        if (!param) {
          return;
        }
        Curry2._2(f, i, param.hd);
        _param = param.tl;
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function fold_left(f, _accu, _l) {
      while (true) {
        const l = _l;
        const accu = _accu;
        if (!l) {
          return accu;
        }
        _l = l.tl;
        _accu = Curry2._2(f, accu, l.hd);
        continue;
      }
      ;
    }
    function fold_right(f, l, accu) {
      if (l) {
        return Curry2._2(f, l.hd, fold_right(f, l.tl, accu));
      } else {
        return accu;
      }
    }
    function map2_dps(_dst, _offset, f, _l1, _l2) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const l1 = _l1;
        const l2 = _l2;
        if (l1) {
          const match = l1.tl;
          const a1 = l1.hd;
          if (match) {
            if (l2) {
              const match$1 = l2.tl;
              if (match$1) {
                const r1 = Curry2._2(f, a1, l2.hd);
                const r2 = Curry2._2(f, match.hd, match$1.hd);
                const block = {
                  hd: r2,
                  tl: 24029
                };
                dst[offset] = {
                  hd: r1,
                  tl: block
                };
                _l2 = match$1.tl;
                _l1 = match.tl;
                _offset = "tl";
                _dst = block;
                continue;
              }
              throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
                MEL_EXN_ID: "Invalid_argument",
                _1: "List.map2"
              });
            }
            throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
              MEL_EXN_ID: "Invalid_argument",
              _1: "List.map2"
            });
          }
          if (l2) {
            if (l2.tl) {
              throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
                MEL_EXN_ID: "Invalid_argument",
                _1: "List.map2"
              });
            }
            const r1$1 = Curry2._2(f, a1, l2.hd);
            dst[offset] = {
              hd: r1$1,
              tl: (
                /* [] */
                0
              )
            };
            return;
          }
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.map2"
          });
        }
        if (l2) {
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.map2"
          });
        }
        dst[offset] = /* [] */
        0;
        return;
      }
      ;
    }
    function map2(f, l1, l2) {
      if (l1) {
        const match = l1.tl;
        const a1 = l1.hd;
        if (match) {
          if (l2) {
            const match$1 = l2.tl;
            if (match$1) {
              const r1 = Curry2._2(f, a1, l2.hd);
              const r2 = Curry2._2(f, match.hd, match$1.hd);
              const block = {
                hd: r2,
                tl: 24029
              };
              return {
                hd: r1,
                tl: (map2_dps(block, "tl", f, match.tl, match$1.tl), block)
              };
            }
            throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
              MEL_EXN_ID: "Invalid_argument",
              _1: "List.map2"
            });
          }
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.map2"
          });
        }
        if (l2) {
          if (l2.tl) {
            throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
              MEL_EXN_ID: "Invalid_argument",
              _1: "List.map2"
            });
          }
          const r1$1 = Curry2._2(f, a1, l2.hd);
          return {
            hd: r1$1,
            tl: (
              /* [] */
              0
            )
          };
        }
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.map2"
        });
      }
      if (!l2) {
        return (
          /* [] */
          0
        );
      }
      throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
        MEL_EXN_ID: "Invalid_argument",
        _1: "List.map2"
      });
    }
    function rev_map2(f, l1, l2) {
      let _accu = (
        /* [] */
        0
      );
      let _l1 = l1;
      let _l2 = l2;
      while (true) {
        const l2$1 = _l2;
        const l1$1 = _l1;
        const accu = _accu;
        if (l1$1) {
          if (l2$1) {
            _l2 = l2$1.tl;
            _l1 = l1$1.tl;
            _accu = {
              hd: Curry2._2(f, l1$1.hd, l2$1.hd),
              tl: accu
            };
            continue;
          }
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.rev_map2"
          });
        }
        if (l2$1) {
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.rev_map2"
          });
        }
        return accu;
      }
      ;
    }
    function iter2(f, _l1, _l2) {
      while (true) {
        const l2 = _l2;
        const l1 = _l1;
        if (l1) {
          if (l2) {
            Curry2._2(f, l1.hd, l2.hd);
            _l2 = l2.tl;
            _l1 = l1.tl;
            continue;
          }
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.iter2"
          });
        }
        if (!l2) {
          return;
        }
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.iter2"
        });
      }
      ;
    }
    function fold_left2(f, _accu, _l1, _l2) {
      while (true) {
        const l2 = _l2;
        const l1 = _l1;
        const accu = _accu;
        if (l1) {
          if (l2) {
            _l2 = l2.tl;
            _l1 = l1.tl;
            _accu = Curry2._3(f, accu, l1.hd, l2.hd);
            continue;
          }
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.fold_left2"
          });
        }
        if (l2) {
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.fold_left2"
          });
        }
        return accu;
      }
      ;
    }
    function fold_right2(f, l1, l2, accu) {
      if (l1) {
        if (l2) {
          return Curry2._3(f, l1.hd, l2.hd, fold_right2(f, l1.tl, l2.tl, accu));
        }
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.fold_right2"
        });
      }
      if (l2) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.fold_right2"
        });
      }
      return accu;
    }
    function for_all(p, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return true;
        }
        if (!Curry2._1(p, param.hd)) {
          return false;
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function exists(p, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return false;
        }
        if (Curry2._1(p, param.hd)) {
          return true;
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function for_all2(p, _l1, _l2) {
      while (true) {
        const l2 = _l2;
        const l1 = _l1;
        if (l1) {
          if (l2) {
            if (!Curry2._2(p, l1.hd, l2.hd)) {
              return false;
            }
            _l2 = l2.tl;
            _l1 = l1.tl;
            continue;
          }
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.for_all2"
          });
        }
        if (!l2) {
          return true;
        }
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.for_all2"
        });
      }
      ;
    }
    function exists2(p, _l1, _l2) {
      while (true) {
        const l2 = _l2;
        const l1 = _l1;
        if (l1) {
          if (l2) {
            if (Curry2._2(p, l1.hd, l2.hd)) {
              return true;
            }
            _l2 = l2.tl;
            _l1 = l1.tl;
            continue;
          }
          throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
            MEL_EXN_ID: "Invalid_argument",
            _1: "List.exists2"
          });
        }
        if (!l2) {
          return false;
        }
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.exists2"
        });
      }
      ;
    }
    function mem(x, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return false;
        }
        if (Caml_obj.caml_equal(param.hd, x)) {
          return true;
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function memq(x, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return false;
        }
        if (param.hd === x) {
          return true;
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function assoc(x, _param) {
      while (true) {
        const param = _param;
        if (param) {
          const match = param.hd;
          if (Caml_obj.caml_equal(match[0], x)) {
            return match[1];
          }
          _param = param.tl;
          continue;
        }
        throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
          MEL_EXN_ID: Stdlib.Not_found
        });
      }
      ;
    }
    function assoc_opt(x, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return;
        }
        const match = param.hd;
        if (Caml_obj.caml_equal(match[0], x)) {
          return Caml_option.some(match[1]);
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function assq(x, _param) {
      while (true) {
        const param = _param;
        if (param) {
          const match = param.hd;
          if (match[0] === x) {
            return match[1];
          }
          _param = param.tl;
          continue;
        }
        throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
          MEL_EXN_ID: Stdlib.Not_found
        });
      }
      ;
    }
    function assq_opt(x, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return;
        }
        const match = param.hd;
        if (match[0] === x) {
          return Caml_option.some(match[1]);
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function mem_assoc(x, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return false;
        }
        if (Caml_obj.caml_equal(param.hd[0], x)) {
          return true;
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function mem_assq(x, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return false;
        }
        if (param.hd[0] === x) {
          return true;
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function remove_assoc(x, param) {
      if (!param) {
        return (
          /* [] */
          0
        );
      }
      const l = param.tl;
      const pair = param.hd;
      if (Caml_obj.caml_equal(pair[0], x)) {
        return l;
      } else {
        return {
          hd: pair,
          tl: remove_assoc(x, l)
        };
      }
    }
    function remove_assq(x, param) {
      if (!param) {
        return (
          /* [] */
          0
        );
      }
      const l = param.tl;
      const pair = param.hd;
      if (pair[0] === x) {
        return l;
      } else {
        return {
          hd: pair,
          tl: remove_assq(x, l)
        };
      }
    }
    function find(p, _param) {
      while (true) {
        const param = _param;
        if (param) {
          const x = param.hd;
          if (Curry2._1(p, x)) {
            return x;
          }
          _param = param.tl;
          continue;
        }
        throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
          MEL_EXN_ID: Stdlib.Not_found
        });
      }
      ;
    }
    function find_opt(p, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return;
        }
        const x = param.hd;
        if (Curry2._1(p, x)) {
          return Caml_option.some(x);
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function find_index(p) {
      return function(param) {
        let _i = 0;
        let _param = param;
        while (true) {
          const param$1 = _param;
          const i = _i;
          if (!param$1) {
            return;
          }
          if (Curry2._1(p, param$1.hd)) {
            return i;
          }
          _param = param$1.tl;
          _i = i + 1 | 0;
          continue;
        }
        ;
      };
    }
    function find_map(f, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return;
        }
        const result = Curry2._1(f, param.hd);
        if (result !== void 0) {
          return result;
        }
        _param = param.tl;
        continue;
      }
      ;
    }
    function find_mapi(f) {
      return function(param) {
        let _i = 0;
        let _param = param;
        while (true) {
          const param$1 = _param;
          const i = _i;
          if (!param$1) {
            return;
          }
          const result = Curry2._2(f, i, param$1.hd);
          if (result !== void 0) {
            return result;
          }
          _param = param$1.tl;
          _i = i + 1 | 0;
          continue;
        }
        ;
      };
    }
    function find_all(p, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return (
            /* [] */
            0
          );
        }
        const l = param.tl;
        const x = param.hd;
        if (Curry2._1(p, x)) {
          const block = {
            hd: x,
            tl: 24029
          };
          find_all_dps(block, "tl", p, l);
          return block;
        }
        _param = l;
        continue;
      }
      ;
    }
    function find_all_dps(_dst, _offset, p, _param) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const param = _param;
        if (!param) {
          dst[offset] = /* [] */
          0;
          return;
        }
        const l = param.tl;
        const x = param.hd;
        if (Curry2._1(p, x)) {
          const block = {
            hd: x,
            tl: 24029
          };
          dst[offset] = block;
          _param = l;
          _offset = "tl";
          _dst = block;
          continue;
        }
        _param = l;
        continue;
      }
      ;
    }
    function filteri_dps(_dst, _offset, p, _i, _param) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const i = _i;
        const param = _param;
        if (!param) {
          dst[offset] = /* [] */
          0;
          return;
        }
        const l = param.tl;
        const x = param.hd;
        const i$p = i + 1 | 0;
        if (Curry2._2(p, i, x)) {
          const block = {
            hd: x,
            tl: 24029
          };
          dst[offset] = block;
          _param = l;
          _i = i$p;
          _offset = "tl";
          _dst = block;
          continue;
        }
        _param = l;
        _i = i$p;
        continue;
      }
      ;
    }
    function filteri(p, l) {
      let _i = 0;
      let _param = l;
      while (true) {
        const param = _param;
        const i = _i;
        if (!param) {
          return (
            /* [] */
            0
          );
        }
        const l$1 = param.tl;
        const x = param.hd;
        const i$p = i + 1 | 0;
        if (Curry2._2(p, i, x)) {
          const block = {
            hd: x,
            tl: 24029
          };
          filteri_dps(block, "tl", p, i$p, l$1);
          return block;
        }
        _param = l$1;
        _i = i$p;
        continue;
      }
      ;
    }
    function filter_map(f, _param) {
      while (true) {
        const param = _param;
        if (!param) {
          return (
            /* [] */
            0
          );
        }
        const l = param.tl;
        const v = Curry2._1(f, param.hd);
        if (v !== void 0) {
          const block = {
            hd: Caml_option.valFromOption(v),
            tl: 24029
          };
          filter_map_dps(block, "tl", f, l);
          return block;
        }
        _param = l;
        continue;
      }
      ;
    }
    function filter_map_dps(_dst, _offset, f, _param) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const param = _param;
        if (!param) {
          dst[offset] = /* [] */
          0;
          return;
        }
        const l = param.tl;
        const v = Curry2._1(f, param.hd);
        if (v !== void 0) {
          const block = {
            hd: Caml_option.valFromOption(v),
            tl: 24029
          };
          dst[offset] = block;
          _param = l;
          _offset = "tl";
          _dst = block;
          continue;
        }
        _param = l;
        continue;
      }
      ;
    }
    function concat_map(f, param) {
      if (param) {
        let ys = Curry2._1(f, param.hd);
        let xs = param.tl;
        if (!ys) {
          return concat_map(f, xs);
        }
        const block = {
          hd: ys.hd,
          tl: 24029
        };
        prepend_concat_map_dps(block, "tl", ys.tl, f, xs);
        return block;
      } else {
        return (
          /* [] */
          0
        );
      }
    }
    function prepend_concat_map_dps(_dst, _offset, _ys, f, xs) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const ys = _ys;
        if (!ys) {
          if (xs) {
            return prepend_concat_map_dps(dst, offset, Curry2._1(f, xs.hd), f, xs.tl);
          } else {
            dst[offset] = /* [] */
            0;
            return;
          }
        }
        const block = {
          hd: ys.hd,
          tl: 24029
        };
        dst[offset] = block;
        _ys = ys.tl;
        _offset = "tl";
        _dst = block;
        continue;
      }
      ;
    }
    function take(n2, l) {
      const aux_dps = function(_dst, _offset, _n, _l) {
        while (true) {
          const dst = _dst;
          const offset = _offset;
          const n3 = _n;
          const l2 = _l;
          if (n3 === 0) {
            dst[offset] = /* [] */
            0;
            return;
          }
          if (!l2) {
            dst[offset] = /* [] */
            0;
            return;
          }
          const block2 = {
            hd: l2.hd,
            tl: 24029
          };
          dst[offset] = block2;
          _l = l2.tl;
          _n = n3 - 1 | 0;
          _offset = "tl";
          _dst = block2;
          continue;
        }
        ;
      };
      if (n2 < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.take"
        });
      }
      if (n2 === 0) {
        return (
          /* [] */
          0
        );
      }
      if (!l) {
        return (
          /* [] */
          0
        );
      }
      const block = {
        hd: l.hd,
        tl: 24029
      };
      aux_dps(block, "tl", n2 - 1 | 0, l.tl);
      return block;
    }
    function drop(n2, l) {
      if (n2 < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.drop"
        });
      }
      let _i = 0;
      let _rest = l;
      while (true) {
        const rest = _rest;
        const i = _i;
        if (!rest) {
          return rest;
        }
        if (i >= n2) {
          return rest;
        }
        _rest = rest.tl;
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function take_while(p, l) {
      const aux_dps = function(_dst, _offset, __rest) {
        while (true) {
          const dst = _dst;
          const offset = _offset;
          const _rest = __rest;
          if (!_rest) {
            dst[offset] = /* [] */
            0;
            return;
          }
          const x2 = _rest.hd;
          if (!Curry2._1(p, x2)) {
            dst[offset] = /* [] */
            0;
            return;
          }
          const block2 = {
            hd: x2,
            tl: 24029
          };
          dst[offset] = block2;
          __rest = _rest.tl;
          _offset = "tl";
          _dst = block2;
          continue;
        }
        ;
      };
      if (!l) {
        return (
          /* [] */
          0
        );
      }
      const x = l.hd;
      if (!Curry2._1(p, x)) {
        return (
          /* [] */
          0
        );
      }
      const block = {
        hd: x,
        tl: 24029
      };
      aux_dps(block, "tl", l.tl);
      return block;
    }
    function drop_while(p, _rest) {
      while (true) {
        const rest = _rest;
        if (!rest) {
          return rest;
        }
        if (!Curry2._1(p, rest.hd)) {
          return rest;
        }
        _rest = rest.tl;
        continue;
      }
      ;
    }
    function fold_left_map(f, accu, l) {
      let _accu = accu;
      let _l_accu = (
        /* [] */
        0
      );
      let _param = l;
      while (true) {
        const param = _param;
        const l_accu = _l_accu;
        const accu$1 = _accu;
        if (!param) {
          return [
            accu$1,
            rev_append(
              l_accu,
              /* [] */
              0
            )
          ];
        }
        const match = Curry2._2(f, accu$1, param.hd);
        _param = param.tl;
        _l_accu = {
          hd: match[1],
          tl: l_accu
        };
        _accu = match[0];
        continue;
      }
      ;
    }
    function partition(p, l) {
      let _yes = (
        /* [] */
        0
      );
      let _no = (
        /* [] */
        0
      );
      let _param = l;
      while (true) {
        const param = _param;
        const no = _no;
        const yes = _yes;
        if (!param) {
          return [
            rev_append(
              yes,
              /* [] */
              0
            ),
            rev_append(
              no,
              /* [] */
              0
            )
          ];
        }
        const l$1 = param.tl;
        const x = param.hd;
        if (Curry2._1(p, x)) {
          _param = l$1;
          _yes = {
            hd: x,
            tl: yes
          };
          continue;
        }
        _param = l$1;
        _no = {
          hd: x,
          tl: no
        };
        continue;
      }
      ;
    }
    function partition_map(p, l) {
      let _left = (
        /* [] */
        0
      );
      let _right = (
        /* [] */
        0
      );
      let _param = l;
      while (true) {
        const param = _param;
        const right = _right;
        const left = _left;
        if (!param) {
          return [
            rev_append(
              left,
              /* [] */
              0
            ),
            rev_append(
              right,
              /* [] */
              0
            )
          ];
        }
        const l$1 = param.tl;
        const v = Curry2._1(p, param.hd);
        if (v.TAG === /* Left */
        0) {
          _param = l$1;
          _left = {
            hd: v._0,
            tl: left
          };
          continue;
        }
        _param = l$1;
        _right = {
          hd: v._0,
          tl: right
        };
        continue;
      }
      ;
    }
    function split(param) {
      if (!param) {
        return [
          /* [] */
          0,
          /* [] */
          0
        ];
      }
      const match = param.hd;
      const match$1 = split(param.tl);
      return [
        {
          hd: match[0],
          tl: match$1[0]
        },
        {
          hd: match[1],
          tl: match$1[1]
        }
      ];
    }
    function combine(l1, l2) {
      if (l1) {
        if (l2) {
          return {
            hd: [
              l1.hd,
              l2.hd
            ],
            tl: combine(l1.tl, l2.tl)
          };
        }
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "List.combine"
        });
      }
      if (!l2) {
        return (
          /* [] */
          0
        );
      }
      throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
        MEL_EXN_ID: "Invalid_argument",
        _1: "List.combine"
      });
    }
    function merge(cmp, l1, l2) {
      if (!l1) {
        return l2;
      }
      if (!l2) {
        return l1;
      }
      const h2 = l2.hd;
      const h1 = l1.hd;
      if (Curry2._2(cmp, h1, h2) <= 0) {
        return {
          hd: h1,
          tl: merge(cmp, l1.tl, l2)
        };
      } else {
        return {
          hd: h2,
          tl: merge(cmp, l1, l2.tl)
        };
      }
    }
    function stable_sort(cmp, l) {
      const rev_merge = function(_l1, _l2, _accu) {
        while (true) {
          const accu = _accu;
          const l2 = _l2;
          const l1 = _l1;
          if (!l1) {
            return rev_append(l2, accu);
          }
          if (!l2) {
            return rev_append(l1, accu);
          }
          const h2 = l2.hd;
          const h1 = l1.hd;
          if (Curry2._2(cmp, h1, h2) <= 0) {
            _accu = {
              hd: h1,
              tl: accu
            };
            _l1 = l1.tl;
            continue;
          }
          _accu = {
            hd: h2,
            tl: accu
          };
          _l2 = l2.tl;
          continue;
        }
        ;
      };
      const rev_merge_rev = function(_l1, _l2, _accu) {
        while (true) {
          const accu = _accu;
          const l2 = _l2;
          const l1 = _l1;
          if (!l1) {
            return rev_append(l2, accu);
          }
          if (!l2) {
            return rev_append(l1, accu);
          }
          const h2 = l2.hd;
          const h1 = l1.hd;
          if (Curry2._2(cmp, h1, h2) > 0) {
            _accu = {
              hd: h1,
              tl: accu
            };
            _l1 = l1.tl;
            continue;
          }
          _accu = {
            hd: h2,
            tl: accu
          };
          _l2 = l2.tl;
          continue;
        }
        ;
      };
      const sort2 = function(n2, l2) {
        if (n2 !== 2) {
          if (n2 === 3 && l2) {
            const match = l2.tl;
            if (match) {
              const match$1 = match.tl;
              if (match$1) {
                const x3 = match$1.hd;
                const x2 = match.hd;
                const x1 = l2.hd;
                const s = Curry2._2(cmp, x1, x2) <= 0 ? Curry2._2(cmp, x2, x3) <= 0 ? {
                  hd: x1,
                  tl: {
                    hd: x2,
                    tl: {
                      hd: x3,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : Curry2._2(cmp, x1, x3) <= 0 ? {
                  hd: x1,
                  tl: {
                    hd: x3,
                    tl: {
                      hd: x2,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : {
                  hd: x3,
                  tl: {
                    hd: x1,
                    tl: {
                      hd: x2,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : Curry2._2(cmp, x1, x3) <= 0 ? {
                  hd: x2,
                  tl: {
                    hd: x1,
                    tl: {
                      hd: x3,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : Curry2._2(cmp, x2, x3) <= 0 ? {
                  hd: x2,
                  tl: {
                    hd: x3,
                    tl: {
                      hd: x1,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : {
                  hd: x3,
                  tl: {
                    hd: x2,
                    tl: {
                      hd: x1,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                };
                return [
                  s,
                  match$1.tl
                ];
              }
            }
          }
        } else if (l2) {
          const match$2 = l2.tl;
          if (match$2) {
            const x2$1 = match$2.hd;
            const x1$1 = l2.hd;
            const s$1 = Curry2._2(cmp, x1$1, x2$1) <= 0 ? {
              hd: x1$1,
              tl: {
                hd: x2$1,
                tl: (
                  /* [] */
                  0
                )
              }
            } : {
              hd: x2$1,
              tl: {
                hd: x1$1,
                tl: (
                  /* [] */
                  0
                )
              }
            };
            return [
              s$1,
              match$2.tl
            ];
          }
        }
        const n1 = n2 >> 1;
        const n22 = n2 - n1 | 0;
        const match$3 = rev_sort(n1, l2);
        const match$4 = rev_sort(n22, match$3[1]);
        return [
          rev_merge_rev(
            match$3[0],
            match$4[0],
            /* [] */
            0
          ),
          match$4[1]
        ];
      };
      const rev_sort = function(n2, l2) {
        if (n2 !== 2) {
          if (n2 === 3 && l2) {
            const match = l2.tl;
            if (match) {
              const match$1 = match.tl;
              if (match$1) {
                const x3 = match$1.hd;
                const x2 = match.hd;
                const x1 = l2.hd;
                const s = Curry2._2(cmp, x1, x2) > 0 ? Curry2._2(cmp, x2, x3) > 0 ? {
                  hd: x1,
                  tl: {
                    hd: x2,
                    tl: {
                      hd: x3,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : Curry2._2(cmp, x1, x3) > 0 ? {
                  hd: x1,
                  tl: {
                    hd: x3,
                    tl: {
                      hd: x2,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : {
                  hd: x3,
                  tl: {
                    hd: x1,
                    tl: {
                      hd: x2,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : Curry2._2(cmp, x1, x3) > 0 ? {
                  hd: x2,
                  tl: {
                    hd: x1,
                    tl: {
                      hd: x3,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : Curry2._2(cmp, x2, x3) > 0 ? {
                  hd: x2,
                  tl: {
                    hd: x3,
                    tl: {
                      hd: x1,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                } : {
                  hd: x3,
                  tl: {
                    hd: x2,
                    tl: {
                      hd: x1,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  }
                };
                return [
                  s,
                  match$1.tl
                ];
              }
            }
          }
        } else if (l2) {
          const match$2 = l2.tl;
          if (match$2) {
            const x2$1 = match$2.hd;
            const x1$1 = l2.hd;
            const s$1 = Curry2._2(cmp, x1$1, x2$1) > 0 ? {
              hd: x1$1,
              tl: {
                hd: x2$1,
                tl: (
                  /* [] */
                  0
                )
              }
            } : {
              hd: x2$1,
              tl: {
                hd: x1$1,
                tl: (
                  /* [] */
                  0
                )
              }
            };
            return [
              s$1,
              match$2.tl
            ];
          }
        }
        const n1 = n2 >> 1;
        const n22 = n2 - n1 | 0;
        const match$3 = sort2(n1, l2);
        const match$4 = sort2(n22, match$3[1]);
        return [
          rev_merge(
            match$3[0],
            match$4[0],
            /* [] */
            0
          ),
          match$4[1]
        ];
      };
      const len = length(l);
      if (len < 2) {
        return l;
      } else {
        return sort2(len, l)[0];
      }
    }
    function sort_uniq(cmp, l) {
      const rev_merge = function(_l1, _l2, _accu) {
        while (true) {
          const accu = _accu;
          const l2 = _l2;
          const l1 = _l1;
          if (!l1) {
            return rev_append(l2, accu);
          }
          if (!l2) {
            return rev_append(l1, accu);
          }
          const t2 = l2.tl;
          const h2 = l2.hd;
          const t1 = l1.tl;
          const h1 = l1.hd;
          const c = Curry2._2(cmp, h1, h2);
          if (c === 0) {
            _accu = {
              hd: h1,
              tl: accu
            };
            _l2 = t2;
            _l1 = t1;
            continue;
          }
          if (c < 0) {
            _accu = {
              hd: h1,
              tl: accu
            };
            _l1 = t1;
            continue;
          }
          _accu = {
            hd: h2,
            tl: accu
          };
          _l2 = t2;
          continue;
        }
        ;
      };
      const rev_merge_rev = function(_l1, _l2, _accu) {
        while (true) {
          const accu = _accu;
          const l2 = _l2;
          const l1 = _l1;
          if (!l1) {
            return rev_append(l2, accu);
          }
          if (!l2) {
            return rev_append(l1, accu);
          }
          const t2 = l2.tl;
          const h2 = l2.hd;
          const t1 = l1.tl;
          const h1 = l1.hd;
          const c = Curry2._2(cmp, h1, h2);
          if (c === 0) {
            _accu = {
              hd: h1,
              tl: accu
            };
            _l2 = t2;
            _l1 = t1;
            continue;
          }
          if (c > 0) {
            _accu = {
              hd: h1,
              tl: accu
            };
            _l1 = t1;
            continue;
          }
          _accu = {
            hd: h2,
            tl: accu
          };
          _l2 = t2;
          continue;
        }
        ;
      };
      const sort2 = function(n2, l2) {
        if (n2 !== 2) {
          if (n2 === 3 && l2) {
            const match = l2.tl;
            if (match) {
              const match$1 = match.tl;
              if (match$1) {
                const x3 = match$1.hd;
                const x2 = match.hd;
                const x1 = l2.hd;
                const c = Curry2._2(cmp, x1, x2);
                let s;
                if (c === 0) {
                  const c$1 = Curry2._2(cmp, x2, x3);
                  s = c$1 === 0 ? {
                    hd: x2,
                    tl: (
                      /* [] */
                      0
                    )
                  } : c$1 < 0 ? {
                    hd: x2,
                    tl: {
                      hd: x3,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  } : {
                    hd: x3,
                    tl: {
                      hd: x2,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  };
                } else if (c < 0) {
                  const c$2 = Curry2._2(cmp, x2, x3);
                  if (c$2 === 0) {
                    s = {
                      hd: x1,
                      tl: {
                        hd: x2,
                        tl: (
                          /* [] */
                          0
                        )
                      }
                    };
                  } else if (c$2 < 0) {
                    s = {
                      hd: x1,
                      tl: {
                        hd: x2,
                        tl: {
                          hd: x3,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    };
                  } else {
                    const c$3 = Curry2._2(cmp, x1, x3);
                    s = c$3 === 0 ? {
                      hd: x1,
                      tl: {
                        hd: x2,
                        tl: (
                          /* [] */
                          0
                        )
                      }
                    } : c$3 < 0 ? {
                      hd: x1,
                      tl: {
                        hd: x3,
                        tl: {
                          hd: x2,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    } : {
                      hd: x3,
                      tl: {
                        hd: x1,
                        tl: {
                          hd: x2,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    };
                  }
                } else {
                  const c$4 = Curry2._2(cmp, x1, x3);
                  if (c$4 === 0) {
                    s = {
                      hd: x2,
                      tl: {
                        hd: x1,
                        tl: (
                          /* [] */
                          0
                        )
                      }
                    };
                  } else if (c$4 < 0) {
                    s = {
                      hd: x2,
                      tl: {
                        hd: x1,
                        tl: {
                          hd: x3,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    };
                  } else {
                    const c$5 = Curry2._2(cmp, x2, x3);
                    s = c$5 === 0 ? {
                      hd: x2,
                      tl: {
                        hd: x1,
                        tl: (
                          /* [] */
                          0
                        )
                      }
                    } : c$5 < 0 ? {
                      hd: x2,
                      tl: {
                        hd: x3,
                        tl: {
                          hd: x1,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    } : {
                      hd: x3,
                      tl: {
                        hd: x2,
                        tl: {
                          hd: x1,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    };
                  }
                }
                return [
                  s,
                  match$1.tl
                ];
              }
            }
          }
        } else if (l2) {
          const match$2 = l2.tl;
          if (match$2) {
            const x2$1 = match$2.hd;
            const x1$1 = l2.hd;
            const c$6 = Curry2._2(cmp, x1$1, x2$1);
            const s$1 = c$6 === 0 ? {
              hd: x1$1,
              tl: (
                /* [] */
                0
              )
            } : c$6 < 0 ? {
              hd: x1$1,
              tl: {
                hd: x2$1,
                tl: (
                  /* [] */
                  0
                )
              }
            } : {
              hd: x2$1,
              tl: {
                hd: x1$1,
                tl: (
                  /* [] */
                  0
                )
              }
            };
            return [
              s$1,
              match$2.tl
            ];
          }
        }
        const n1 = n2 >> 1;
        const n22 = n2 - n1 | 0;
        const match$3 = rev_sort(n1, l2);
        const match$4 = rev_sort(n22, match$3[1]);
        return [
          rev_merge_rev(
            match$3[0],
            match$4[0],
            /* [] */
            0
          ),
          match$4[1]
        ];
      };
      const rev_sort = function(n2, l2) {
        if (n2 !== 2) {
          if (n2 === 3 && l2) {
            const match = l2.tl;
            if (match) {
              const match$1 = match.tl;
              if (match$1) {
                const x3 = match$1.hd;
                const x2 = match.hd;
                const x1 = l2.hd;
                const c = Curry2._2(cmp, x1, x2);
                let s;
                if (c === 0) {
                  const c$1 = Curry2._2(cmp, x2, x3);
                  s = c$1 === 0 ? {
                    hd: x2,
                    tl: (
                      /* [] */
                      0
                    )
                  } : c$1 > 0 ? {
                    hd: x2,
                    tl: {
                      hd: x3,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  } : {
                    hd: x3,
                    tl: {
                      hd: x2,
                      tl: (
                        /* [] */
                        0
                      )
                    }
                  };
                } else if (c > 0) {
                  const c$2 = Curry2._2(cmp, x2, x3);
                  if (c$2 === 0) {
                    s = {
                      hd: x1,
                      tl: {
                        hd: x2,
                        tl: (
                          /* [] */
                          0
                        )
                      }
                    };
                  } else if (c$2 > 0) {
                    s = {
                      hd: x1,
                      tl: {
                        hd: x2,
                        tl: {
                          hd: x3,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    };
                  } else {
                    const c$3 = Curry2._2(cmp, x1, x3);
                    s = c$3 === 0 ? {
                      hd: x1,
                      tl: {
                        hd: x2,
                        tl: (
                          /* [] */
                          0
                        )
                      }
                    } : c$3 > 0 ? {
                      hd: x1,
                      tl: {
                        hd: x3,
                        tl: {
                          hd: x2,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    } : {
                      hd: x3,
                      tl: {
                        hd: x1,
                        tl: {
                          hd: x2,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    };
                  }
                } else {
                  const c$4 = Curry2._2(cmp, x1, x3);
                  if (c$4 === 0) {
                    s = {
                      hd: x2,
                      tl: {
                        hd: x1,
                        tl: (
                          /* [] */
                          0
                        )
                      }
                    };
                  } else if (c$4 > 0) {
                    s = {
                      hd: x2,
                      tl: {
                        hd: x1,
                        tl: {
                          hd: x3,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    };
                  } else {
                    const c$5 = Curry2._2(cmp, x2, x3);
                    s = c$5 === 0 ? {
                      hd: x2,
                      tl: {
                        hd: x1,
                        tl: (
                          /* [] */
                          0
                        )
                      }
                    } : c$5 > 0 ? {
                      hd: x2,
                      tl: {
                        hd: x3,
                        tl: {
                          hd: x1,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    } : {
                      hd: x3,
                      tl: {
                        hd: x2,
                        tl: {
                          hd: x1,
                          tl: (
                            /* [] */
                            0
                          )
                        }
                      }
                    };
                  }
                }
                return [
                  s,
                  match$1.tl
                ];
              }
            }
          }
        } else if (l2) {
          const match$2 = l2.tl;
          if (match$2) {
            const x2$1 = match$2.hd;
            const x1$1 = l2.hd;
            const c$6 = Curry2._2(cmp, x1$1, x2$1);
            const s$1 = c$6 === 0 ? {
              hd: x1$1,
              tl: (
                /* [] */
                0
              )
            } : c$6 > 0 ? {
              hd: x1$1,
              tl: {
                hd: x2$1,
                tl: (
                  /* [] */
                  0
                )
              }
            } : {
              hd: x2$1,
              tl: {
                hd: x1$1,
                tl: (
                  /* [] */
                  0
                )
              }
            };
            return [
              s$1,
              match$2.tl
            ];
          }
        }
        const n1 = n2 >> 1;
        const n22 = n2 - n1 | 0;
        const match$3 = sort2(n1, l2);
        const match$4 = sort2(n22, match$3[1]);
        return [
          rev_merge(
            match$3[0],
            match$4[0],
            /* [] */
            0
          ),
          match$4[1]
        ];
      };
      const len = length(l);
      if (len < 2) {
        return l;
      } else {
        return sort2(len, l)[0];
      }
    }
    function compare_lengths(_l1, _l2) {
      while (true) {
        const l2 = _l2;
        const l1 = _l1;
        if (!l1) {
          if (l2) {
            return -1;
          } else {
            return 0;
          }
        }
        if (!l2) {
          return 1;
        }
        _l2 = l2.tl;
        _l1 = l1.tl;
        continue;
      }
      ;
    }
    function compare_length_with(_l, _n) {
      while (true) {
        const n2 = _n;
        const l = _l;
        if (!l) {
          if (n2 === 0) {
            return 0;
          } else if (n2 > 0) {
            return -1;
          } else {
            return 1;
          }
        }
        if (n2 <= 0) {
          return 1;
        }
        _n = n2 - 1 | 0;
        _l = l.tl;
        continue;
      }
      ;
    }
    function is_empty(param) {
      if (param) {
        return false;
      } else {
        return true;
      }
    }
    function equal(eq, _l1, _l2) {
      while (true) {
        const l2 = _l2;
        const l1 = _l1;
        if (!l1) {
          if (l2) {
            return false;
          } else {
            return true;
          }
        }
        if (!l2) {
          return false;
        }
        if (!Curry2._2(eq, l1.hd, l2.hd)) {
          return false;
        }
        _l2 = l2.tl;
        _l1 = l1.tl;
        continue;
      }
      ;
    }
    function compare(cmp, _l1, _l2) {
      while (true) {
        const l2 = _l2;
        const l1 = _l1;
        if (!l1) {
          if (l2) {
            return -1;
          } else {
            return 0;
          }
        }
        if (!l2) {
          return 1;
        }
        const c = Curry2._2(cmp, l1.hd, l2.hd);
        if (c !== 0) {
          return c;
        }
        _l2 = l2.tl;
        _l1 = l1.tl;
        continue;
      }
      ;
    }
    function to_seq(l) {
      const aux = function(l2, param) {
        if (!l2) {
          return (
            /* Nil */
            0
          );
        }
        const tail = l2.tl;
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: l2.hd,
          _1: (function(param2) {
            return aux(tail, param2);
          })
        };
      };
      return function(param) {
        return aux(l, param);
      };
    }
    function of_seq_dps(_dst, _offset, _seq) {
      while (true) {
        const dst = _dst;
        const offset = _offset;
        const seq = _seq;
        const match = Curry2._1(seq, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          dst[offset] = /* [] */
          0;
          return;
        }
        const x1 = match._0;
        const match$1 = Curry2._1(match._1, void 0);
        if (
          /* tag */
          typeof match$1 === "number" || typeof match$1 === "string"
        ) {
          dst[offset] = {
            hd: x1,
            tl: (
              /* [] */
              0
            )
          };
          return;
        }
        const block = {
          hd: match$1._0,
          tl: 24029
        };
        dst[offset] = {
          hd: x1,
          tl: block
        };
        _seq = match$1._1;
        _offset = "tl";
        _dst = block;
        continue;
      }
      ;
    }
    function of_seq(seq) {
      const match = Curry2._1(seq, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* [] */
          0
        );
      }
      const x1 = match._0;
      const match$1 = Curry2._1(match._1, void 0);
      if (
        /* tag */
        typeof match$1 === "number" || typeof match$1 === "string"
      ) {
        return {
          hd: x1,
          tl: (
            /* [] */
            0
          )
        };
      }
      const block = {
        hd: match$1._0,
        tl: 24029
      };
      return {
        hd: x1,
        tl: (of_seq_dps(block, "tl", match$1._1), block)
      };
    }
    var append = Stdlib.$at;
    var concat = flatten;
    var filter = find_all;
    var sort = stable_sort;
    var fast_sort = stable_sort;
    module2.exports = {
      length,
      compare_lengths,
      compare_length_with,
      is_empty,
      cons,
      hd,
      tl,
      nth,
      nth_opt,
      rev,
      init,
      append,
      rev_append,
      concat,
      flatten,
      equal,
      compare,
      iter,
      iteri,
      map,
      mapi,
      rev_map,
      filter_map,
      concat_map,
      fold_left_map,
      fold_left,
      fold_right,
      iter2,
      map2,
      rev_map2,
      fold_left2,
      fold_right2,
      for_all,
      exists,
      for_all2,
      exists2,
      mem,
      memq,
      find,
      find_opt,
      find_index,
      find_map,
      find_mapi,
      filter,
      find_all,
      filteri,
      take,
      drop,
      take_while,
      drop_while,
      partition,
      partition_map,
      assoc,
      assoc_opt,
      assq,
      assq_opt,
      mem_assoc,
      mem_assq,
      remove_assoc,
      remove_assq,
      split,
      combine,
      sort,
      stable_sort,
      fast_sort,
      sort_uniq,
      merge,
      to_seq,
      of_seq
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/camlinternalLazy.js
var require_camlinternalLazy = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/camlinternalLazy.js"(exports2, module2) {
    "use strict";
    var Caml_exceptions = require_caml_exceptions();
    var Caml_js_exceptions = require_caml_js_exceptions();
    var Undefined = /* @__PURE__ */ Caml_exceptions.create("CamlinternalLazy.Undefined");
    function is_val(l) {
      return l.LAZY_DONE;
    }
    function forward_with_closure(blk, closure) {
      const result = closure();
      blk.VAL = result;
      blk.LAZY_DONE = true;
      return result;
    }
    function raise_undefined() {
      throw new Caml_js_exceptions.MelangeError(Undefined, {
        MEL_EXN_ID: Undefined
      });
    }
    function force_lazy_block(blk) {
      const closure = blk.VAL;
      blk.VAL = raise_undefined;
      try {
        return forward_with_closure(blk, closure);
      } catch (e) {
        blk.VAL = (function() {
          throw e;
        });
        throw e;
      }
    }
    function force_val_lazy_block(blk) {
      const closure = blk.VAL;
      blk.VAL = raise_undefined;
      return forward_with_closure(blk, closure);
    }
    function force(lzv) {
      if (lzv.LAZY_DONE) {
        return lzv.VAL;
      } else {
        return force_lazy_block(lzv);
      }
    }
    function force_val(lzv) {
      if (lzv.LAZY_DONE) {
        return lzv.VAL;
      } else {
        return force_val_lazy_block(lzv);
      }
    }
    module2.exports = {
      Undefined,
      force_lazy_block,
      force_val_lazy_block,
      force,
      force_val,
      is_val
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/camlinternalAtomic.js
var require_camlinternalAtomic = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/camlinternalAtomic.js"(exports2, module2) {
    "use strict";
    function make(v) {
      return {
        v
      };
    }
    function get(r) {
      return r.v;
    }
    function set(r, v) {
      r.v = v;
    }
    function exchange(r, v) {
      const cur = r.v;
      r.v = v;
      return cur;
    }
    function compare_and_set(r, seen, v) {
      const cur = r.v;
      if (cur === seen) {
        r.v = v;
        return true;
      } else {
        return false;
      }
    }
    function fetch_and_add(r, n2) {
      const cur = r.v;
      r.v = cur + n2 | 0;
      return cur;
    }
    function incr(r) {
      fetch_and_add(r, 1);
    }
    function decr(r) {
      fetch_and_add(r, -1);
    }
    module2.exports = {
      make,
      get,
      set,
      exchange,
      compare_and_set,
      fetch_and_add,
      incr,
      decr
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/atomic.js
var require_atomic = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/atomic.js"(exports2, module2) {
    "use strict";
    var CamlinternalAtomic = require_camlinternalAtomic();
    var make = CamlinternalAtomic.make;
    var get = CamlinternalAtomic.get;
    var set = CamlinternalAtomic.set;
    var exchange = CamlinternalAtomic.exchange;
    var compare_and_set = CamlinternalAtomic.compare_and_set;
    var fetch_and_add = CamlinternalAtomic.fetch_and_add;
    var incr = CamlinternalAtomic.incr;
    var decr = CamlinternalAtomic.decr;
    module2.exports = {
      make,
      get,
      set,
      exchange,
      compare_and_set,
      fetch_and_add,
      incr,
      decr
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/seq.js
var require_seq = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/seq.js"(exports2, module2) {
    "use strict";
    var Caml_exceptions = require_caml_exceptions();
    var Caml_js_exceptions = require_caml_js_exceptions();
    var Caml_option = require_caml_option();
    var CamlinternalLazy = require_camlinternalLazy();
    var Curry2 = require_curry();
    var Stdlib__Atomic = require_atomic();
    function empty(param) {
      return (
        /* Nil */
        0
      );
    }
    function $$return(x, param) {
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: x,
        _1: empty
      };
    }
    function cons(x, next, param) {
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: x,
        _1: next
      };
    }
    function append(seq1, seq2, param) {
      const match = Curry2._1(seq1, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return Curry2._1(seq2, void 0);
      }
      const next = match._1;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: match._0,
        _1: (function(param2) {
          return append(next, seq2, param2);
        })
      };
    }
    function map(f, seq, param) {
      const match = Curry2._1(seq, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const next = match._1;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: Curry2._1(f, match._0),
        _1: (function(param2) {
          return map(f, next, param2);
        })
      };
    }
    function filter_map(f, _seq, _param) {
      while (true) {
        const seq = _seq;
        const match = Curry2._1(seq, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return (
            /* Nil */
            0
          );
        }
        const next = match._1;
        const y = Curry2._1(f, match._0);
        if (y !== void 0) {
          return {
            TAG: (
              /* Cons */
              0
            ),
            _0: Caml_option.valFromOption(y),
            _1: (function(param) {
              return filter_map(f, next, param);
            })
          };
        }
        _param = void 0;
        _seq = next;
        continue;
      }
      ;
    }
    function filter(f, _seq, _param) {
      while (true) {
        const seq = _seq;
        const match = Curry2._1(seq, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return (
            /* Nil */
            0
          );
        }
        const next = match._1;
        const x = match._0;
        if (Curry2._1(f, x)) {
          return {
            TAG: (
              /* Cons */
              0
            ),
            _0: x,
            _1: (function(param) {
              return filter(f, next, param);
            })
          };
        }
        _param = void 0;
        _seq = next;
        continue;
      }
      ;
    }
    function concat(seq, param) {
      const match = Curry2._1(seq, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const next = match._1;
      return append(match._0, (function(param2) {
        return concat(next, param2);
      }), void 0);
    }
    function flat_map(f, seq, param) {
      const match = Curry2._1(seq, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const next = match._1;
      return append(Curry2._1(f, match._0), (function(param2) {
        return flat_map(f, next, param2);
      }), void 0);
    }
    function fold_left(f, _acc, _seq) {
      while (true) {
        const seq = _seq;
        const acc = _acc;
        const match = Curry2._1(seq, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return acc;
        }
        const acc$1 = Curry2._2(f, acc, match._0);
        _seq = match._1;
        _acc = acc$1;
        continue;
      }
      ;
    }
    function iter(f, _seq) {
      while (true) {
        const seq = _seq;
        const match = Curry2._1(seq, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return;
        }
        Curry2._1(f, match._0);
        _seq = match._1;
        continue;
      }
      ;
    }
    function unfold(f, u, param) {
      const match = Curry2._1(f, u);
      if (match === void 0) {
        return (
          /* Nil */
          0
        );
      }
      const u$p = match[1];
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: match[0],
        _1: (function(param2) {
          return unfold(f, u$p, param2);
        })
      };
    }
    function is_empty(xs) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return true;
      } else {
        return false;
      }
    }
    function uncons(xs) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return;
      } else {
        return [
          match._0,
          match._1
        ];
      }
    }
    function length(xs) {
      let _accu = 0;
      let _xs = xs;
      while (true) {
        const xs$1 = _xs;
        const accu = _accu;
        const match = Curry2._1(xs$1, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return accu;
        }
        _xs = match._1;
        _accu = accu + 1 | 0;
        continue;
      }
      ;
    }
    function iteri(f, xs) {
      let _i = 0;
      let _xs = xs;
      while (true) {
        const xs$1 = _xs;
        const i = _i;
        const match = Curry2._1(xs$1, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return;
        }
        Curry2._2(f, i, match._0);
        _xs = match._1;
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function fold_lefti(f, accu, xs) {
      let _accu = accu;
      let _i = 0;
      let _xs = xs;
      while (true) {
        const xs$1 = _xs;
        const i = _i;
        const accu$1 = _accu;
        const match = Curry2._1(xs$1, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return accu$1;
        }
        const accu$2 = Curry2._3(f, accu$1, i, match._0);
        _xs = match._1;
        _i = i + 1 | 0;
        _accu = accu$2;
        continue;
      }
      ;
    }
    function for_all(p, _xs) {
      while (true) {
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return true;
        }
        if (!Curry2._1(p, match._0)) {
          return false;
        }
        _xs = match._1;
        continue;
      }
      ;
    }
    function exists(p, _xs) {
      while (true) {
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return false;
        }
        if (Curry2._1(p, match._0)) {
          return true;
        }
        _xs = match._1;
        continue;
      }
      ;
    }
    function find(p, _xs) {
      while (true) {
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return;
        }
        const x = match._0;
        if (Curry2._1(p, x)) {
          return Caml_option.some(x);
        }
        _xs = match._1;
        continue;
      }
      ;
    }
    function find_index(p, xs) {
      let _i = 0;
      let _xs = xs;
      while (true) {
        const xs$1 = _xs;
        const i = _i;
        const match = Curry2._1(xs$1, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return;
        }
        if (Curry2._1(p, match._0)) {
          return i;
        }
        _xs = match._1;
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function find_map(f, _xs) {
      while (true) {
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return;
        }
        const result = Curry2._1(f, match._0);
        if (result !== void 0) {
          return result;
        }
        _xs = match._1;
        continue;
      }
      ;
    }
    function find_mapi(f, xs) {
      let _i = 0;
      let _xs = xs;
      while (true) {
        const xs$1 = _xs;
        const i = _i;
        const match = Curry2._1(xs$1, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return;
        }
        const result = Curry2._2(f, i, match._0);
        if (result !== void 0) {
          return result;
        }
        _xs = match._1;
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function iter2(f, _xs, _ys) {
      while (true) {
        const ys = _ys;
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return;
        }
        const match$1 = Curry2._1(ys, void 0);
        if (
          /* tag */
          typeof match$1 === "number" || typeof match$1 === "string"
        ) {
          return;
        }
        Curry2._2(f, match._0, match$1._0);
        _ys = match$1._1;
        _xs = match._1;
        continue;
      }
      ;
    }
    function fold_left2(f, _accu, _xs, _ys) {
      while (true) {
        const ys = _ys;
        const xs = _xs;
        const accu = _accu;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return accu;
        }
        const match$1 = Curry2._1(ys, void 0);
        if (
          /* tag */
          typeof match$1 === "number" || typeof match$1 === "string"
        ) {
          return accu;
        }
        const accu$1 = Curry2._3(f, accu, match._0, match$1._0);
        _ys = match$1._1;
        _xs = match._1;
        _accu = accu$1;
        continue;
      }
      ;
    }
    function for_all2(f, _xs, _ys) {
      while (true) {
        const ys = _ys;
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return true;
        }
        const match$1 = Curry2._1(ys, void 0);
        if (
          /* tag */
          typeof match$1 === "number" || typeof match$1 === "string"
        ) {
          return true;
        }
        if (!Curry2._2(f, match._0, match$1._0)) {
          return false;
        }
        _ys = match$1._1;
        _xs = match._1;
        continue;
      }
      ;
    }
    function exists2(f, _xs, _ys) {
      while (true) {
        const ys = _ys;
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return false;
        }
        const match$1 = Curry2._1(ys, void 0);
        if (
          /* tag */
          typeof match$1 === "number" || typeof match$1 === "string"
        ) {
          return false;
        }
        if (Curry2._2(f, match._0, match$1._0)) {
          return true;
        }
        _ys = match$1._1;
        _xs = match._1;
        continue;
      }
      ;
    }
    function equal(eq, _xs, _ys) {
      while (true) {
        const ys = _ys;
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        const match$1 = Curry2._1(ys, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          if (
            /* tag */
            typeof match$1 === "number" || typeof match$1 === "string"
          ) {
            return true;
          } else {
            return false;
          }
        }
        if (
          /* tag */
          typeof match$1 === "number" || typeof match$1 === "string"
        ) {
          return false;
        }
        if (!Curry2._2(eq, match._0, match$1._0)) {
          return false;
        }
        _ys = match$1._1;
        _xs = match._1;
        continue;
      }
      ;
    }
    function compare(cmp, _xs, _ys) {
      while (true) {
        const ys = _ys;
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        const match$1 = Curry2._1(ys, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          if (
            /* tag */
            typeof match$1 === "number" || typeof match$1 === "string"
          ) {
            return 0;
          } else {
            return -1;
          }
        }
        if (
          /* tag */
          typeof match$1 === "number" || typeof match$1 === "string"
        ) {
          return 1;
        }
        const c = Curry2._2(cmp, match._0, match$1._0);
        if (c !== 0) {
          return c;
        }
        _ys = match$1._1;
        _xs = match._1;
        continue;
      }
      ;
    }
    function init_aux(f, i, j, param) {
      if (i >= j) {
        return (
          /* Nil */
          0
        );
      }
      const partial_arg = i + 1 | 0;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: Curry2._1(f, i),
        _1: (function(param2) {
          return init_aux(f, partial_arg, j, param2);
        })
      };
    }
    function init(n2, f) {
      if (n2 < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Seq.init"
        });
      }
      return function(param) {
        return init_aux(f, 0, n2, param);
      };
    }
    function repeat(x, param) {
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: x,
        _1: (function(param2) {
          return repeat(x, param2);
        })
      };
    }
    function forever(f, param) {
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: Curry2._1(f, void 0),
        _1: (function(param2) {
          return forever(f, param2);
        })
      };
    }
    function cycle_nonempty(xs, param) {
      return append(xs, (function(param2) {
        return cycle_nonempty(xs, param2);
      }), void 0);
    }
    function cycle(xs, param) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const xs$p = match._1;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: match._0,
        _1: (function(param2) {
          return append(xs$p, (function(param3) {
            return cycle_nonempty(xs, param3);
          }), param2);
        })
      };
    }
    function iterate1(f, x, param) {
      const y = Curry2._1(f, x);
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: y,
        _1: (function(param2) {
          return iterate1(f, y, param2);
        })
      };
    }
    function iterate(f, x) {
      return function(param) {
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: x,
          _1: (function(param2) {
            return iterate1(f, x, param2);
          })
        };
      };
    }
    function mapi_aux(f, i, xs, param) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const xs$1 = match._1;
      const partial_arg = i + 1 | 0;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: Curry2._2(f, i, match._0),
        _1: (function(param2) {
          return mapi_aux(f, partial_arg, xs$1, param2);
        })
      };
    }
    function mapi(f, xs) {
      return function(param) {
        return mapi_aux(f, 0, xs, param);
      };
    }
    function tail_scan(f, s, xs, param) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const xs$1 = match._1;
      const s$1 = Curry2._2(f, s, match._0);
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: s$1,
        _1: (function(param2) {
          return tail_scan(f, s$1, xs$1, param2);
        })
      };
    }
    function scan(f, s, xs) {
      return function(param) {
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: s,
          _1: (function(param2) {
            return tail_scan(f, s, xs, param2);
          })
        };
      };
    }
    function take_aux(n2, xs) {
      if (n2 === 0) {
        return empty;
      } else {
        return function(param) {
          const match = Curry2._1(xs, void 0);
          if (
            /* tag */
            typeof match === "number" || typeof match === "string"
          ) {
            return (
              /* Nil */
              0
            );
          } else {
            return {
              TAG: (
                /* Cons */
                0
              ),
              _0: match._0,
              _1: take_aux(n2 - 1 | 0, match._1)
            };
          }
        };
      }
    }
    function take(n2, xs) {
      if (n2 < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Seq.take"
        });
      }
      return take_aux(n2, xs);
    }
    function drop(n2, xs) {
      if (n2 < 0) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Seq.drop"
        });
      }
      if (n2 === 0) {
        return xs;
      } else {
        return function(param) {
          let _n = n2;
          let _xs = xs;
          while (true) {
            const xs$1 = _xs;
            const n$1 = _n;
            const match = Curry2._1(xs$1, void 0);
            if (
              /* tag */
              typeof match === "number" || typeof match === "string"
            ) {
              return (
                /* Nil */
                0
              );
            }
            const xs$2 = match._1;
            const n$2 = n$1 - 1 | 0;
            if (n$2 === 0) {
              return Curry2._1(xs$2, void 0);
            }
            _xs = xs$2;
            _n = n$2;
            continue;
          }
          ;
        };
      }
    }
    function take_while(p, xs, param) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const xs$1 = match._1;
      const x = match._0;
      if (Curry2._1(p, x)) {
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: x,
          _1: (function(param2) {
            return take_while(p, xs$1, param2);
          })
        };
      } else {
        return (
          /* Nil */
          0
        );
      }
    }
    function drop_while(p, _xs, _param) {
      while (true) {
        const xs = _xs;
        const node = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof node === "number" || typeof node === "string"
        ) {
          return (
            /* Nil */
            0
          );
        }
        if (!Curry2._1(p, node._0)) {
          return node;
        }
        _param = void 0;
        _xs = node._1;
        continue;
      }
      ;
    }
    function group(eq, xs, param) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const xs$1 = match._1;
      const x = match._0;
      const partial_arg = Curry2._1(eq, x);
      const partial_arg$1 = function(param2) {
        return take_while(partial_arg, xs$1, param2);
      };
      const partial_arg$2 = Curry2._1(eq, x);
      const partial_arg$3 = function(param2) {
        return drop_while(partial_arg$2, xs$1, param2);
      };
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: (function(param2) {
          return {
            TAG: (
              /* Cons */
              0
            ),
            _0: x,
            _1: partial_arg$1
          };
        }),
        _1: (function(param2) {
          return group(eq, partial_arg$3, param2);
        })
      };
    }
    var Forced_twice = /* @__PURE__ */ Caml_exceptions.create("Stdlib.Seq.Forced_twice");
    function failure(param) {
      throw new Caml_js_exceptions.MelangeError(Forced_twice, {
        MEL_EXN_ID: Forced_twice
      });
    }
    function memoize(xs) {
      const partial_arg = {
        LAZY_DONE: false,
        VAL: (function() {
          const match = Curry2._1(xs, void 0);
          if (
            /* tag */
            typeof match === "number" || typeof match === "string"
          ) {
            return (
              /* Nil */
              0
            );
          } else {
            return {
              TAG: (
                /* Cons */
                0
              ),
              _0: match._0,
              _1: memoize(match._1)
            };
          }
        })
      };
      return function(param) {
        return CamlinternalLazy.force(partial_arg);
      };
    }
    function once(xs) {
      const f = function(param) {
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return (
            /* Nil */
            0
          );
        } else {
          return {
            TAG: (
              /* Cons */
              0
            ),
            _0: match._0,
            _1: once(match._1)
          };
        }
      };
      const action = Stdlib__Atomic.make(f);
      return function(param) {
        const f2 = Stdlib__Atomic.exchange(action, failure);
        return Curry2._1(f2, void 0);
      };
    }
    function zip(xs, ys, param) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const xs$1 = match._1;
      const match$1 = Curry2._1(ys, void 0);
      if (
        /* tag */
        typeof match$1 === "number" || typeof match$1 === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const ys$1 = match$1._1;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: [
          match._0,
          match$1._0
        ],
        _1: (function(param2) {
          return zip(xs$1, ys$1, param2);
        })
      };
    }
    function map2(f, xs, ys, param) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const xs$1 = match._1;
      const match$1 = Curry2._1(ys, void 0);
      if (
        /* tag */
        typeof match$1 === "number" || typeof match$1 === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const ys$1 = match$1._1;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: Curry2._2(f, match._0, match$1._0),
        _1: (function(param2) {
          return map2(f, xs$1, ys$1, param2);
        })
      };
    }
    function interleave(xs, ys, param) {
      const match = Curry2._1(xs, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return Curry2._1(ys, void 0);
      }
      const xs$1 = match._1;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: match._0,
        _1: (function(param2) {
          return interleave(ys, xs$1, param2);
        })
      };
    }
    function sorted_merge1(cmp, x, xs, y, ys) {
      if (Curry2._2(cmp, x, y) <= 0) {
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: x,
          _1: (function(param) {
            const match = Curry2._1(xs, void 0);
            if (
              /* tag */
              typeof match === "number" || typeof match === "string"
            ) {
              return {
                TAG: (
                  /* Cons */
                  0
                ),
                _0: y,
                _1: ys
              };
            } else {
              return sorted_merge1(cmp, match._0, match._1, y, ys);
            }
          })
        };
      } else {
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: y,
          _1: (function(param) {
            const match = Curry2._1(ys, void 0);
            if (
              /* tag */
              typeof match === "number" || typeof match === "string"
            ) {
              return {
                TAG: (
                  /* Cons */
                  0
                ),
                _0: x,
                _1: xs
              };
            } else {
              return sorted_merge1(cmp, x, xs, match._0, match._1);
            }
          })
        };
      }
    }
    function sorted_merge(cmp, xs, ys, param) {
      const match = Curry2._1(xs, void 0);
      const match$1 = Curry2._1(ys, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        if (
          /* tag */
          typeof match$1 === "number" || typeof match$1 === "string"
        ) {
          return (
            /* Nil */
            0
          );
        } else {
          return match$1;
        }
      } else if (
        /* tag */
        typeof match$1 === "number" || typeof match$1 === "string"
      ) {
        return match;
      } else {
        return sorted_merge1(cmp, match._0, match._1, match$1._0, match$1._1);
      }
    }
    function map_fst(xys, param) {
      const match = Curry2._1(xys, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const xys$1 = match._1;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: match._0[0],
        _1: (function(param2) {
          return map_fst(xys$1, param2);
        })
      };
    }
    function map_snd(xys, param) {
      const match = Curry2._1(xys, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return (
          /* Nil */
          0
        );
      }
      const xys$1 = match._1;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: match._0[1],
        _1: (function(param2) {
          return map_snd(xys$1, param2);
        })
      };
    }
    function unzip(xys) {
      return [
        (function(param) {
          return map_fst(xys, param);
        }),
        (function(param) {
          return map_snd(xys, param);
        })
      ];
    }
    function filter_map_find_left_map(f, _xs, _param) {
      while (true) {
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return (
            /* Nil */
            0
          );
        }
        const xs$1 = match._1;
        const y = Curry2._1(f, match._0);
        if (y.TAG === /* Left */
        0) {
          return {
            TAG: (
              /* Cons */
              0
            ),
            _0: y._0,
            _1: (function(param) {
              return filter_map_find_left_map(f, xs$1, param);
            })
          };
        }
        _param = void 0;
        _xs = xs$1;
        continue;
      }
      ;
    }
    function filter_map_find_right_map(f, _xs, _param) {
      while (true) {
        const xs = _xs;
        const match = Curry2._1(xs, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return (
            /* Nil */
            0
          );
        }
        const xs$1 = match._1;
        const z = Curry2._1(f, match._0);
        if (z.TAG !== /* Left */
        0) {
          return {
            TAG: (
              /* Cons */
              0
            ),
            _0: z._0,
            _1: (function(param) {
              return filter_map_find_right_map(f, xs$1, param);
            })
          };
        }
        _param = void 0;
        _xs = xs$1;
        continue;
      }
      ;
    }
    function partition_map(f, xs) {
      return [
        (function(param) {
          return filter_map_find_left_map(f, xs, param);
        }),
        (function(param) {
          return filter_map_find_right_map(f, xs, param);
        })
      ];
    }
    function partition(p, xs) {
      return [
        (function(param) {
          return filter(p, xs, param);
        }),
        (function(param) {
          return filter((function(x) {
            return !Curry2._1(p, x);
          }), xs, param);
        })
      ];
    }
    function transpose(xss, param) {
      const match = unzip(function(param2) {
        return filter_map(uncons, xss, param2);
      });
      const tails = match[1];
      const heads = match[0];
      if (!is_empty(heads)) {
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: heads,
          _1: (function(param2) {
            return transpose(tails, param2);
          })
        };
      }
      if (!is_empty(tails)) {
        throw new Caml_js_exceptions.MelangeError("Assert_failure", {
          MEL_EXN_ID: "Assert_failure",
          _1: [
            "seq.ml",
            616,
            4
          ]
        });
      }
      return (
        /* Nil */
        0
      );
    }
    function diagonals(remainders, xss, param) {
      const match = Curry2._1(xss, void 0);
      if (
        /* tag */
        typeof match === "number" || typeof match === "string"
      ) {
        return transpose(remainders, void 0);
      }
      const xss$1 = match._1;
      const match$1 = Curry2._1(match._0, void 0);
      if (
        /* tag */
        typeof match$1 === "number" || typeof match$1 === "string"
      ) {
        const match$2 = unzip(function(param2) {
          return filter_map(uncons, remainders, param2);
        });
        const tails = match$2[1];
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: match$2[0],
          _1: (function(param2) {
            return diagonals(tails, xss$1, param2);
          })
        };
      }
      const xs = match$1._1;
      const x = match$1._0;
      const match$3 = unzip(function(param2) {
        return filter_map(uncons, remainders, param2);
      });
      const tails$1 = match$3[1];
      const heads = match$3[0];
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: (function(param2) {
          return {
            TAG: (
              /* Cons */
              0
            ),
            _0: x,
            _1: heads
          };
        }),
        _1: (function(param2) {
          return diagonals((function(param3) {
            return {
              TAG: (
                /* Cons */
                0
              ),
              _0: xs,
              _1: tails$1
            };
          }), xss$1, param2);
        })
      };
    }
    function map_product(f, xs, ys) {
      return function(param) {
        return concat((function(param2) {
          return diagonals(empty, (function(param3) {
            return map((function(x) {
              return function(param4) {
                return map((function(y) {
                  return Curry2._2(f, x, y);
                }), ys, param4);
              };
            }), xs, param3);
          }), param2);
        }), param);
      };
    }
    function product(xs, ys) {
      return map_product((function(x, y) {
        return [
          x,
          y
        ];
      }), xs, ys);
    }
    function of_dispenser(it) {
      const c = function(param) {
        const x = Curry2._1(it, void 0);
        if (x !== void 0) {
          return {
            TAG: (
              /* Cons */
              0
            ),
            _0: Caml_option.valFromOption(x),
            _1: c
          };
        } else {
          return (
            /* Nil */
            0
          );
        }
      };
      return c;
    }
    function to_dispenser(xs) {
      const s = {
        contents: xs
      };
      return function(param) {
        const match = Curry2._1(s.contents, void 0);
        if (
          /* tag */
          typeof match === "number" || typeof match === "string"
        ) {
          return;
        }
        s.contents = match._1;
        return Caml_option.some(match._0);
      };
    }
    function ints(i, param) {
      const partial_arg = i + 1 | 0;
      return {
        TAG: (
          /* Cons */
          0
        ),
        _0: i,
        _1: (function(param2) {
          return ints(partial_arg, param2);
        })
      };
    }
    var concat_map = flat_map;
    var split = unzip;
    module2.exports = {
      is_empty,
      uncons,
      length,
      iter,
      fold_left,
      iteri,
      fold_lefti,
      for_all,
      exists,
      find,
      find_index,
      find_map,
      find_mapi,
      iter2,
      fold_left2,
      for_all2,
      exists2,
      equal,
      compare,
      empty,
      $$return,
      cons,
      init,
      unfold,
      repeat,
      forever,
      cycle,
      iterate,
      map,
      mapi,
      filter,
      filter_map,
      scan,
      take,
      drop,
      take_while,
      drop_while,
      group,
      memoize,
      Forced_twice,
      once,
      transpose,
      append,
      concat,
      flat_map,
      concat_map,
      zip,
      map2,
      interleave,
      sorted_merge,
      product,
      map_product,
      unzip,
      split,
      partition_map,
      partition,
      of_dispenser,
      to_dispenser,
      ints
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/option.js
var require_option = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/option.js"(exports2, module2) {
    "use strict";
    var Caml_js_exceptions = require_caml_js_exceptions();
    var Caml_option = require_caml_option();
    var Curry2 = require_curry();
    var Stdlib__Seq = require_seq();
    function some(v) {
      return Caml_option.some(v);
    }
    function value(o, $$default) {
      if (o !== void 0) {
        return Caml_option.valFromOption(o);
      } else {
        return $$default;
      }
    }
    function get(v) {
      if (v !== void 0) {
        return Caml_option.valFromOption(v);
      }
      throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
        MEL_EXN_ID: "Invalid_argument",
        _1: "option is None"
      });
    }
    function bind(o, f) {
      if (o !== void 0) {
        return Curry2._1(f, Caml_option.valFromOption(o));
      }
    }
    function join(o) {
      if (o !== void 0) {
        return Caml_option.valFromOption(o);
      }
    }
    function map(f, o) {
      if (o !== void 0) {
        return Caml_option.some(Curry2._1(f, Caml_option.valFromOption(o)));
      }
    }
    function fold(none2, some2, v) {
      if (v !== void 0) {
        return Curry2._1(some2, Caml_option.valFromOption(v));
      } else {
        return none2;
      }
    }
    function iter(f, v) {
      if (v !== void 0) {
        return Curry2._1(f, Caml_option.valFromOption(v));
      }
    }
    function is_none(param) {
      return param === void 0;
    }
    function is_some(param) {
      return param !== void 0;
    }
    function equal(eq, o0, o1) {
      if (o0 !== void 0) {
        if (o1 !== void 0) {
          return Curry2._2(eq, Caml_option.valFromOption(o0), Caml_option.valFromOption(o1));
        } else {
          return false;
        }
      } else {
        return o1 === void 0;
      }
    }
    function compare(cmp, o0, o1) {
      if (o0 !== void 0) {
        if (o1 !== void 0) {
          return Curry2._2(cmp, Caml_option.valFromOption(o0), Caml_option.valFromOption(o1));
        } else {
          return 1;
        }
      } else if (o1 !== void 0) {
        return -1;
      } else {
        return 0;
      }
    }
    function to_result(none2, v) {
      if (v !== void 0) {
        return {
          TAG: (
            /* Ok */
            0
          ),
          _0: Caml_option.valFromOption(v)
        };
      } else {
        return {
          TAG: (
            /* Error */
            1
          ),
          _0: none2
        };
      }
    }
    function to_list(v) {
      if (v !== void 0) {
        return {
          hd: Caml_option.valFromOption(v),
          tl: (
            /* [] */
            0
          )
        };
      } else {
        return (
          /* [] */
          0
        );
      }
    }
    function to_seq(v) {
      if (v === void 0) {
        return Stdlib__Seq.empty;
      }
      const partial_arg = Caml_option.valFromOption(v);
      return function(param) {
        return Stdlib__Seq.$$return(partial_arg, param);
      };
    }
    var none;
    module2.exports = {
      none,
      some,
      value,
      get,
      bind,
      join,
      map,
      fold,
      iter,
      is_none,
      is_some,
      equal,
      compare,
      to_result,
      to_list,
      to_seq
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_hash_primitive.js
var require_caml_hash_primitive = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_hash_primitive.js"(exports2, module2) {
    "use strict";
    function rotl32(x, n2) {
      return x << n2 | x >>> (32 - n2 | 0) | 0;
    }
    function caml_hash_mix_int(h, d) {
      let d$1 = d;
      d$1 = Math.imul(d$1, -862048943);
      d$1 = rotl32(d$1, 15);
      d$1 = Math.imul(d$1, 461845907);
      let h$1 = h ^ d$1;
      h$1 = rotl32(h$1, 13);
      return (h$1 + (h$1 << 2) | 0) - 430675100 | 0;
    }
    function caml_hash_final_mix(h) {
      let h$1 = h ^ h >>> 16;
      h$1 = Math.imul(h$1, -2048144789);
      h$1 = h$1 ^ h$1 >>> 13;
      h$1 = Math.imul(h$1, -1028477387);
      return h$1 ^ h$1 >>> 16;
    }
    function caml_hash_mix_string(h, s) {
      const len = s.length;
      const block = (len / 4 | 0) - 1 | 0;
      let hash = h;
      for (let i = 0; i <= block; ++i) {
        const j = i << 2;
        const w = s.charCodeAt(j) | s.charCodeAt(j + 1 | 0) << 8 | s.charCodeAt(j + 2 | 0) << 16 | s.charCodeAt(j + 3 | 0) << 24;
        hash = caml_hash_mix_int(hash, w);
      }
      const modulo = len & 3;
      if (modulo !== 0) {
        const w$1 = modulo === 3 ? s.charCodeAt(len - 1 | 0) << 16 | s.charCodeAt(len - 2 | 0) << 8 | s.charCodeAt(len - 3 | 0) : modulo === 2 ? s.charCodeAt(len - 1 | 0) << 8 | s.charCodeAt(len - 2 | 0) : s.charCodeAt(len - 1 | 0);
        hash = caml_hash_mix_int(hash, w$1);
      }
      hash = hash ^ len;
      return hash;
    }
    module2.exports = {
      caml_hash_mix_int,
      caml_hash_mix_string,
      caml_hash_final_mix
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange.js/caml_hash.js
var require_caml_hash = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange.js/caml_hash.js"(exports2, module2) {
    "use strict";
    var Caml_hash_primitive = require_caml_hash_primitive();
    function push_back(q, v) {
      const cell = {
        content: v,
        next: void 0
      };
      const last = q.last;
      if (last !== void 0) {
        q.length = q.length + 1 | 0;
        last.next = cell;
        q.last = cell;
      } else {
        q.length = 1;
        q.first = cell;
        q.last = cell;
      }
    }
    function unsafe_pop(q) {
      const cell = q.first;
      const next = cell.next;
      if (next === void 0) {
        q.length = 0;
        q.first = void 0;
        q.last = void 0;
      } else {
        q.length = q.length - 1 | 0;
        q.first = next;
      }
      return cell.content;
    }
    function caml_hash(count, _limit, seed, obj) {
      let hash = seed;
      if (typeof obj === "number") {
        const u = obj | 0;
        hash = Caml_hash_primitive.caml_hash_mix_int(hash, (u + u | 0) + 1 | 0);
        return Caml_hash_primitive.caml_hash_final_mix(hash);
      }
      if (typeof obj === "string") {
        hash = Caml_hash_primitive.caml_hash_mix_string(hash, obj);
        return Caml_hash_primitive.caml_hash_final_mix(hash);
      }
      const queue = {
        length: 0,
        first: void 0,
        last: void 0
      };
      let num = count;
      push_back(queue, obj);
      num = num - 1 | 0;
      while (queue.length !== 0 && num > 0) {
        const obj$1 = unsafe_pop(queue);
        if (typeof obj$1 === "number") {
          const u$1 = obj$1 | 0;
          hash = Caml_hash_primitive.caml_hash_mix_int(hash, (u$1 + u$1 | 0) + 1 | 0);
          num = num - 1 | 0;
        } else if (typeof obj$1 === "string") {
          hash = Caml_hash_primitive.caml_hash_mix_string(hash, obj$1);
          num = num - 1 | 0;
        } else if (typeof obj$1 === "boolean") {
          const u$2 = obj$1 ? 1 : 0;
          hash = Caml_hash_primitive.caml_hash_mix_int(hash, (u$2 + u$2 | 0) + 1 | 0);
          num = num - 1 | 0;
        } else if (typeof obj$1 !== "undefined" && typeof obj$1 !== "symbol" && typeof obj$1 !== "function") {
          const size = obj$1.length | 0;
          if (size !== 0) {
            const obj_tag = obj$1.TAG;
            const tag = size << 10 | obj_tag;
            if (obj_tag === 248) {
              hash = Caml_hash_primitive.caml_hash_mix_int(hash, obj$1[1]);
            } else {
              hash = Caml_hash_primitive.caml_hash_mix_int(hash, tag);
              const v = size - 1 | 0;
              const block = v < num ? v : num;
              for (let i = 0; i <= block; ++i) {
                push_back(queue, obj$1[i]);
              }
            }
          } else {
            const size$1 = (function(obj2, cb) {
              var size2 = 0;
              for (var k in obj2) {
                cb(obj2[k]);
                ++size2;
              }
              return size2;
            })(obj$1, (function(v) {
              push_back(queue, v);
            }));
            hash = Caml_hash_primitive.caml_hash_mix_int(hash, size$1 << 10 | 0);
          }
        }
      }
      ;
      return Caml_hash_primitive.caml_hash_final_mix(hash);
    }
    module2.exports = {
      caml_hash
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/char.js
var require_char = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/char.js"(exports2, module2) {
    "use strict";
    var Caml_bytes = require_caml_bytes();
    var Caml_hash = require_caml_hash();
    var Caml_js_exceptions = require_caml_js_exceptions();
    function chr(n2) {
      if (n2 < 0 || n2 > 255) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Char.chr"
        });
      }
      return n2;
    }
    function escaped(c) {
      let exit = 0;
      if (c >= 40) {
        if (c === 92) {
          return "\\\\";
        }
        exit = c >= 127 ? 1 : 2;
      } else if (c >= 32) {
        if (c >= 39) {
          return "\\'";
        }
        exit = 2;
      } else if (c >= 14) {
        exit = 1;
      } else {
        switch (c) {
          case 8:
            return "\\b";
          case 9:
            return "\\t";
          case 10:
            return "\\n";
          case 0:
          case 1:
          case 2:
          case 3:
          case 4:
          case 5:
          case 6:
          case 7:
          case 11:
          case 12:
            exit = 1;
            break;
          case 13:
            return "\\r";
        }
      }
      switch (exit) {
        case 1:
          const s = [
            0,
            0,
            0,
            0
          ];
          s[0] = /* '\\' */
          92;
          s[1] = 48 + (c / 100 | 0) | 0;
          s[2] = 48 + (c / 10 | 0) % 10 | 0;
          s[3] = 48 + c % 10 | 0;
          return Caml_bytes.bytes_to_string(s);
        case 2:
          const s$1 = [0];
          s$1[0] = c;
          return Caml_bytes.bytes_to_string(s$1);
      }
    }
    function lowercase_ascii(c) {
      if (c > 90 || c < 65) {
        return c;
      } else {
        return c + 32 | 0;
      }
    }
    function uppercase_ascii(c) {
      if (c > 122 || c < 97) {
        return c;
      } else {
        return c - 32 | 0;
      }
    }
    function compare(c1, c2) {
      return c1 - c2 | 0;
    }
    function equal(c1, c2) {
      return (c1 - c2 | 0) === 0;
    }
    function seeded_hash(seed, x) {
      return Caml_hash.caml_hash(10, 100, seed, x);
    }
    function hash(x) {
      return Caml_hash.caml_hash(10, 100, 0, x);
    }
    module2.exports = {
      chr,
      escaped,
      lowercase_ascii,
      uppercase_ascii,
      compare,
      equal,
      seeded_hash,
      hash
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/int.js
var require_int = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/int.js"(exports2, module2) {
    "use strict";
    var Caml = require_caml();
    var Caml_format = require_caml_format();
    var Caml_hash = require_caml_hash();
    function abs(x) {
      if (x >= 0) {
        return x;
      } else {
        return -x | 0;
      }
    }
    var min_int = -2147483648;
    function lognot(x) {
      return x ^ -1;
    }
    function equal(prim0, prim1) {
      return prim0 === prim1;
    }
    var compare = Caml.caml_int_compare;
    function min(x, y) {
      if (x <= y) {
        return x;
      } else {
        return y;
      }
    }
    function max(x, y) {
      if (x >= y) {
        return x;
      } else {
        return y;
      }
    }
    function to_string(x) {
      return Caml_format.caml_format_int("%d", x);
    }
    function seeded_hash(seed, x) {
      return Caml_hash.caml_hash(10, 100, seed, x);
    }
    function hash(x) {
      return Caml_hash.caml_hash(10, 100, 0, x);
    }
    var zero = 0;
    var one = 1;
    var minus_one = -1;
    var max_int = 2147483647;
    module2.exports = {
      zero,
      one,
      minus_one,
      abs,
      max_int,
      min_int,
      lognot,
      equal,
      compare,
      min,
      max,
      to_string,
      seeded_hash,
      hash
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/sys.js
var require_sys = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/sys.js"(exports2, module2) {
    "use strict";
    var Caml_exceptions = require_caml_exceptions();
    var Caml_external_polyfill = require_caml_external_polyfill();
    var Caml_sys = require_caml_sys();
    var executable_name = Caml_sys.caml_sys_executable_name(void 0);
    var os_type = Caml_sys.os_type(void 0);
    var backend_type = {
      TAG: (
        /* Other */
        0
      ),
      _0: "Melange"
    };
    var big_endian = false;
    var unix = Caml_sys.os_type(void 0) === "Unix";
    var win32 = Caml_sys.os_type(void 0) === "Win32";
    function getenv_opt(s) {
      const x = typeof process === "undefined" ? void 0 : process;
      if (x !== void 0) {
        return x.env[s];
      }
    }
    var interactive = {
      contents: false
    };
    function set_signal(sig_num, sig_beh) {
    }
    var Break = /* @__PURE__ */ Caml_exceptions.create("Stdlib.Sys.Break");
    function catch_break(on) {
    }
    function Make(Immediate, Non_immediate) {
      const repr = (
        /* Non_immediate */
        1
      );
      return {
        repr
      };
    }
    var Immediate64 = {
      Make
    };
    var cygwin = false;
    var word_size = 32;
    var int_size = 32;
    var max_string_length = 2147483647;
    var max_array_length = 2147483647;
    var max_floatarray_length = 2147483647;
    var sigabrt = -1;
    var sigalrm = -2;
    var sigfpe = -3;
    var sighup = -4;
    var sigill = -5;
    var sigint = -6;
    var sigkill = -7;
    var sigpipe = -8;
    var sigquit = -9;
    var sigsegv = -10;
    var sigterm = -11;
    var sigusr1 = -12;
    var sigusr2 = -13;
    var sigchld = -14;
    var sigcont = -15;
    var sigstop = -16;
    var sigtstp = -17;
    var sigttin = -18;
    var sigttou = -19;
    var sigvtalrm = -20;
    var sigprof = -21;
    var sigbus = -22;
    var sigpoll = -23;
    var sigsys = -24;
    var sigtrap = -25;
    var sigurg = -26;
    var sigxcpu = -27;
    var sigxfsz = -28;
    var ocaml_version = "4.14.0+mel";
    var development_version = false;
    var ocaml_release = {
      major: 4,
      minor: 14,
      patchlevel: 0,
      extra: [
        /* Plus */
        0,
        "mel"
      ]
    };
    function enable_runtime_warnings(prim) {
      return Caml_external_polyfill.resolve("caml_ml_enable_runtime_warnings")(prim);
    }
    function runtime_warnings_enabled(prim) {
      return Caml_external_polyfill.resolve("caml_ml_runtime_warnings_enabled")(prim);
    }
    module2.exports = {
      executable_name,
      getenv_opt,
      interactive,
      os_type,
      backend_type,
      unix,
      win32,
      cygwin,
      word_size,
      int_size,
      big_endian,
      max_string_length,
      max_array_length,
      max_floatarray_length,
      set_signal,
      sigabrt,
      sigalrm,
      sigfpe,
      sighup,
      sigill,
      sigint,
      sigkill,
      sigpipe,
      sigquit,
      sigsegv,
      sigterm,
      sigusr1,
      sigusr2,
      sigchld,
      sigcont,
      sigstop,
      sigtstp,
      sigttin,
      sigttou,
      sigvtalrm,
      sigprof,
      sigbus,
      sigpoll,
      sigsys,
      sigtrap,
      sigurg,
      sigxcpu,
      sigxfsz,
      Break,
      catch_break,
      ocaml_version,
      development_version,
      ocaml_release,
      enable_runtime_warnings,
      runtime_warnings_enabled,
      Immediate64
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/bytes.js
var require_bytes = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/bytes.js"(exports2, module2) {
    "use strict";
    var Caml_bytes = require_caml_bytes();
    var Caml_js_exceptions = require_caml_js_exceptions();
    var Curry2 = require_curry();
    var Stdlib = require_stdlib();
    var Stdlib__Char = require_char();
    var Stdlib__Int = require_int();
    var Stdlib__Seq = require_seq();
    var Stdlib__Sys = require_sys();
    function make(n2, c) {
      const s = Caml_bytes.caml_create_bytes(n2);
      Caml_bytes.caml_fill_bytes(s, 0, n2, c);
      return s;
    }
    function init(n2, f) {
      const s = Caml_bytes.caml_create_bytes(n2);
      for (let i = 0; i < n2; ++i) {
        s[i] = Curry2._1(f, i);
      }
      return s;
    }
    var empty = [];
    function copy(s) {
      const len = s.length;
      const r = Caml_bytes.caml_create_bytes(len);
      Caml_bytes.caml_blit_bytes(s, 0, r, 0, len);
      return r;
    }
    function to_string(b) {
      return Caml_bytes.bytes_to_string(copy(b));
    }
    function of_string(s) {
      return copy(Caml_bytes.bytes_of_string(s));
    }
    function sub(s, ofs, len) {
      if (ofs < 0 || len < 0 || ofs > (s.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.sub / Bytes.sub"
        });
      }
      const r = Caml_bytes.caml_create_bytes(len);
      Caml_bytes.caml_blit_bytes(s, ofs, r, 0, len);
      return r;
    }
    function sub_string(b, ofs, len) {
      return Caml_bytes.bytes_to_string(sub(b, ofs, len));
    }
    function $plus$plus(a, b) {
      const c = a + b | 0;
      const match = a < 0;
      const match$1 = b < 0;
      const match$2 = c < 0;
      if (match) {
        if (!match$1) {
          return c;
        }
        if (match$2) {
          return c;
        }
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Bytes.extend"
        });
      }
      if (match$1) {
        return c;
      }
      if (match$2) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Bytes.extend"
        });
      }
      return c;
    }
    function extend(s, left, right) {
      const len = $plus$plus($plus$plus(s.length, left), right);
      const r = Caml_bytes.caml_create_bytes(len);
      const match = left < 0 ? [
        -left | 0,
        0
      ] : [
        0,
        left
      ];
      const dstoff = match[1];
      const srcoff = match[0];
      const cpylen = Stdlib__Int.min(s.length - srcoff | 0, len - dstoff | 0);
      if (cpylen > 0) {
        Caml_bytes.caml_blit_bytes(s, srcoff, r, dstoff, cpylen);
      }
      return r;
    }
    function fill(s, ofs, len, c) {
      if (ofs < 0 || len < 0 || ofs > (s.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.fill / Bytes.fill"
        });
      }
      Caml_bytes.caml_fill_bytes(s, ofs, len, c);
    }
    function blit(s1, ofs1, s2, ofs2, len) {
      if (len < 0 || ofs1 < 0 || ofs1 > (s1.length - len | 0) || ofs2 < 0 || ofs2 > (s2.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Bytes.blit"
        });
      }
      Caml_bytes.caml_blit_bytes(s1, ofs1, s2, ofs2, len);
    }
    function blit_string(s1, ofs1, s2, ofs2, len) {
      if (len < 0 || ofs1 < 0 || ofs1 > (s1.length - len | 0) || ofs2 < 0 || ofs2 > (s2.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.blit / Bytes.blit_string"
        });
      }
      Caml_bytes.caml_blit_string(s1, ofs1, s2, ofs2, len);
    }
    function iter(f, a) {
      for (let i = 0, i_finish = a.length; i < i_finish; ++i) {
        Curry2._1(f, a[i]);
      }
    }
    function iteri(f, a) {
      for (let i = 0, i_finish = a.length; i < i_finish; ++i) {
        Curry2._2(f, i, a[i]);
      }
    }
    function ensure_ge(x, y) {
      if (x >= y) {
        return x;
      }
      throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
        MEL_EXN_ID: "Invalid_argument",
        _1: "Bytes.concat"
      });
    }
    function sum_lengths(_acc, seplen, _param) {
      while (true) {
        const param = _param;
        const acc = _acc;
        if (!param) {
          return acc;
        }
        const hd = param.hd;
        if (!param.tl) {
          return hd.length + acc | 0;
        }
        _param = param.tl;
        _acc = ensure_ge((hd.length + seplen | 0) + acc | 0, acc);
        continue;
      }
      ;
    }
    function concat(sep, l) {
      if (!l) {
        return empty;
      }
      const seplen = sep.length;
      let dst = Caml_bytes.caml_create_bytes(sum_lengths(0, seplen, l));
      let _pos = 0;
      let _param = l;
      while (true) {
        const param = _param;
        const pos = _pos;
        if (!param) {
          return dst;
        }
        const hd = param.hd;
        if (param.tl) {
          Caml_bytes.caml_blit_bytes(hd, 0, dst, pos, hd.length);
          Caml_bytes.caml_blit_bytes(sep, 0, dst, pos + hd.length | 0, seplen);
          _param = param.tl;
          _pos = (pos + hd.length | 0) + seplen | 0;
          continue;
        }
        Caml_bytes.caml_blit_bytes(hd, 0, dst, pos, hd.length);
        return dst;
      }
      ;
    }
    function cat(s1, s2) {
      const l1 = s1.length;
      const l2 = s2.length;
      const r = Caml_bytes.caml_create_bytes(l1 + l2 | 0);
      Caml_bytes.caml_blit_bytes(s1, 0, r, 0, l1);
      Caml_bytes.caml_blit_bytes(s2, 0, r, l1, l2);
      return r;
    }
    function is_space(param) {
      if (param > 13 || param < 9) {
        return param === 32;
      } else {
        return param !== 11;
      }
    }
    function trim(s) {
      const len = s.length;
      let i = 0;
      while (i < len && is_space(s[i])) {
        i = i + 1 | 0;
      }
      ;
      let j = len - 1 | 0;
      while (j >= i && is_space(s[j])) {
        j = j - 1 | 0;
      }
      ;
      if (j >= i) {
        return sub(s, i, (j - i | 0) + 1 | 0);
      } else {
        return empty;
      }
    }
    function unsafe_escape(s) {
      let n2 = 0;
      for (let i = 0, i_finish = s.length; i < i_finish; ++i) {
        const match = s[i];
        n2 = n2 + (match >= 32 ? match > 92 || match < 34 ? match >= 127 ? 4 : 1 : match > 91 || match < 35 ? 2 : 1 : match >= 11 ? match !== 13 ? 4 : 2 : match >= 8 ? 2 : 4) | 0;
      }
      if (n2 === s.length) {
        return s;
      }
      const s$p = Caml_bytes.caml_create_bytes(n2);
      n2 = 0;
      for (let i$1 = 0, i_finish$1 = s.length; i$1 < i_finish$1; ++i$1) {
        const c = s[i$1];
        let exit = 0;
        if (c >= 35) {
          if (c !== 92) {
            if (c >= 127) {
              exit = 1;
            } else {
              s$p[n2] = c;
            }
          } else {
            exit = 2;
          }
        } else if (c >= 32) {
          if (c >= 34) {
            exit = 2;
          } else {
            s$p[n2] = c;
          }
        } else if (c >= 14) {
          exit = 1;
        } else {
          switch (c) {
            case 8:
              s$p[n2] = /* '\\' */
              92;
              n2 = n2 + 1 | 0;
              s$p[n2] = /* 'b' */
              98;
              break;
            case 9:
              s$p[n2] = /* '\\' */
              92;
              n2 = n2 + 1 | 0;
              s$p[n2] = /* 't' */
              116;
              break;
            case 10:
              s$p[n2] = /* '\\' */
              92;
              n2 = n2 + 1 | 0;
              s$p[n2] = /* 'n' */
              110;
              break;
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
            case 6:
            case 7:
            case 11:
            case 12:
              exit = 1;
              break;
            case 13:
              s$p[n2] = /* '\\' */
              92;
              n2 = n2 + 1 | 0;
              s$p[n2] = /* 'r' */
              114;
              break;
          }
        }
        switch (exit) {
          case 1:
            s$p[n2] = /* '\\' */
            92;
            n2 = n2 + 1 | 0;
            s$p[n2] = 48 + (c / 100 | 0) | 0;
            n2 = n2 + 1 | 0;
            s$p[n2] = 48 + (c / 10 | 0) % 10 | 0;
            n2 = n2 + 1 | 0;
            s$p[n2] = 48 + c % 10 | 0;
            break;
          case 2:
            s$p[n2] = /* '\\' */
            92;
            n2 = n2 + 1 | 0;
            s$p[n2] = c;
            break;
        }
        n2 = n2 + 1 | 0;
      }
      return s$p;
    }
    function escaped(b) {
      return unsafe_escape(copy(b));
    }
    function map(f, s) {
      const l = s.length;
      if (l === 0) {
        return s;
      }
      const r = Caml_bytes.caml_create_bytes(l);
      for (let i = 0; i < l; ++i) {
        r[i] = Curry2._1(f, s[i]);
      }
      return r;
    }
    function mapi(f, s) {
      const l = s.length;
      if (l === 0) {
        return s;
      }
      const r = Caml_bytes.caml_create_bytes(l);
      for (let i = 0; i < l; ++i) {
        r[i] = Curry2._2(f, i, s[i]);
      }
      return r;
    }
    function fold_left(f, x, a) {
      let r = x;
      for (let i = 0, i_finish = a.length; i < i_finish; ++i) {
        r = Curry2._2(f, r, a[i]);
      }
      return r;
    }
    function fold_right(f, a, x) {
      let r = x;
      for (let i = a.length - 1 | 0; i >= 0; --i) {
        r = Curry2._2(f, a[i], r);
      }
      return r;
    }
    function exists(p, s) {
      const n2 = s.length;
      let _i = 0;
      while (true) {
        const i = _i;
        if (i === n2) {
          return false;
        }
        if (Curry2._1(p, s[i])) {
          return true;
        }
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function for_all(p, s) {
      const n2 = s.length;
      let _i = 0;
      while (true) {
        const i = _i;
        if (i === n2) {
          return true;
        }
        if (!Curry2._1(p, s[i])) {
          return false;
        }
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function uppercase_ascii(s) {
      return map(Stdlib__Char.uppercase_ascii, s);
    }
    function lowercase_ascii(s) {
      return map(Stdlib__Char.lowercase_ascii, s);
    }
    function apply1(f, s) {
      if (s.length === 0) {
        return s;
      }
      const r = copy(s);
      r[0] = Curry2._1(f, s[0]);
      return r;
    }
    function capitalize_ascii(s) {
      return apply1(Stdlib__Char.uppercase_ascii, s);
    }
    function uncapitalize_ascii(s) {
      return apply1(Stdlib__Char.lowercase_ascii, s);
    }
    function starts_with(prefix, s) {
      const len_s = s.length;
      const len_pre = prefix.length;
      if (len_s >= len_pre) {
        let _i = 0;
        while (true) {
          const i = _i;
          if (i === len_pre) {
            return true;
          }
          if (s[i] !== prefix[i]) {
            return false;
          }
          _i = i + 1 | 0;
          continue;
        }
        ;
      } else {
        return false;
      }
    }
    function ends_with(suffix, s) {
      const len_s = s.length;
      const len_suf = suffix.length;
      const diff = len_s - len_suf | 0;
      if (diff >= 0) {
        let _i = 0;
        while (true) {
          const i = _i;
          if (i === len_suf) {
            return true;
          }
          if (s[diff + i | 0] !== suffix[i]) {
            return false;
          }
          _i = i + 1 | 0;
          continue;
        }
        ;
      } else {
        return false;
      }
    }
    function index_rec(s, lim, _i, c) {
      while (true) {
        const i = _i;
        if (i >= lim) {
          throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
            MEL_EXN_ID: Stdlib.Not_found
          });
        }
        if (s[i] === c) {
          return i;
        }
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function index(s, c) {
      return index_rec(s, s.length, 0, c);
    }
    function index_rec_opt(s, lim, _i, c) {
      while (true) {
        const i = _i;
        if (i >= lim) {
          return;
        }
        if (s[i] === c) {
          return i;
        }
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function index_opt(s, c) {
      return index_rec_opt(s, s.length, 0, c);
    }
    function index_from(s, i, c) {
      const l = s.length;
      if (i < 0 || i > l) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.index_from / Bytes.index_from"
        });
      }
      return index_rec(s, l, i, c);
    }
    function index_from_opt(s, i, c) {
      const l = s.length;
      if (i < 0 || i > l) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.index_from_opt / Bytes.index_from_opt"
        });
      }
      return index_rec_opt(s, l, i, c);
    }
    function rindex_rec(s, _i, c) {
      while (true) {
        const i = _i;
        if (i < 0) {
          throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
            MEL_EXN_ID: Stdlib.Not_found
          });
        }
        if (s[i] === c) {
          return i;
        }
        _i = i - 1 | 0;
        continue;
      }
      ;
    }
    function rindex(s, c) {
      return rindex_rec(s, s.length - 1 | 0, c);
    }
    function rindex_from(s, i, c) {
      if (i < -1 || i >= s.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.rindex_from / Bytes.rindex_from"
        });
      }
      return rindex_rec(s, i, c);
    }
    function rindex_rec_opt(s, _i, c) {
      while (true) {
        const i = _i;
        if (i < 0) {
          return;
        }
        if (s[i] === c) {
          return i;
        }
        _i = i - 1 | 0;
        continue;
      }
      ;
    }
    function rindex_opt(s, c) {
      return rindex_rec_opt(s, s.length - 1 | 0, c);
    }
    function rindex_from_opt(s, i, c) {
      if (i < -1 || i >= s.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.rindex_from_opt / Bytes.rindex_from_opt"
        });
      }
      return rindex_rec_opt(s, i, c);
    }
    function contains_from(s, i, c) {
      const l = s.length;
      if (i < 0 || i > l) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.contains_from / Bytes.contains_from"
        });
      }
      try {
        index_rec(s, l, i, c);
        return true;
      } catch (raw_exn) {
        const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
        if (exn.MEL_EXN_ID === Stdlib.Not_found) {
          return false;
        }
        throw exn;
      }
    }
    function contains(s, c) {
      return contains_from(s, 0, c);
    }
    function rcontains_from(s, i, c) {
      if (i < 0 || i >= s.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.rcontains_from / Bytes.rcontains_from"
        });
      }
      try {
        rindex_rec(s, i, c);
        return true;
      } catch (raw_exn) {
        const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
        if (exn.MEL_EXN_ID === Stdlib.Not_found) {
          return false;
        }
        throw exn;
      }
    }
    var compare = Caml_bytes.caml_bytes_compare;
    function split_on_char(sep, s) {
      let r = (
        /* [] */
        0
      );
      let j = s.length;
      for (let i = s.length - 1 | 0; i >= 0; --i) {
        if (s[i] === sep) {
          r = {
            hd: sub(s, i + 1 | 0, (j - i | 0) - 1 | 0),
            tl: r
          };
          j = i;
        }
      }
      return {
        hd: sub(s, 0, j),
        tl: r
      };
    }
    function to_seq(s) {
      const aux = function(i, param) {
        if (i === s.length) {
          return (
            /* Nil */
            0
          );
        }
        const x = Caml_bytes.get(s, i);
        const partial_arg = i + 1 | 0;
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: x,
          _1: (function(param2) {
            return aux(partial_arg, param2);
          })
        };
      };
      return function(param) {
        return aux(0, param);
      };
    }
    function to_seqi(s) {
      const aux = function(i, param) {
        if (i === s.length) {
          return (
            /* Nil */
            0
          );
        }
        const x = Caml_bytes.get(s, i);
        const partial_arg = i + 1 | 0;
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: [
            i,
            x
          ],
          _1: (function(param2) {
            return aux(partial_arg, param2);
          })
        };
      };
      return function(param) {
        return aux(0, param);
      };
    }
    function of_seq(i) {
      const n2 = {
        contents: 0
      };
      const buf = {
        contents: make(
          256,
          /* '\000' */
          0
        )
      };
      const resize = function(param) {
        const new_len = Stdlib__Int.min(buf.contents.length << 1, Stdlib__Sys.max_string_length);
        if (buf.contents.length === new_len) {
          throw new Caml_js_exceptions.MelangeError("Failure", {
            MEL_EXN_ID: "Failure",
            _1: "Bytes.of_seq: cannot grow bytes"
          });
        }
        const new_buf = make(
          new_len,
          /* '\000' */
          0
        );
        blit(buf.contents, 0, new_buf, 0, n2.contents);
        buf.contents = new_buf;
      };
      Stdlib__Seq.iter((function(c) {
        if (n2.contents === buf.contents.length) {
          resize(void 0);
        }
        Caml_bytes.set(buf.contents, n2.contents, c);
        n2.contents = n2.contents + 1 | 0;
      }), i);
      return sub(buf.contents, 0, n2.contents);
    }
    function unsafe_get_uint16_le(b, i) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.bswap16(Caml_bytes.get16u(b, i));
      } else {
        return Caml_bytes.get16u(b, i);
      }
    }
    function unsafe_get_uint16_be(b, i) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.get16u(b, i);
      } else {
        return Caml_bytes.bswap16(Caml_bytes.get16u(b, i));
      }
    }
    function get_int8(b, i) {
      return Caml_bytes.get(b, i) << (Stdlib__Sys.int_size - 8 | 0) >> (Stdlib__Sys.int_size - 8 | 0);
    }
    function get_uint16_le(b, i) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.bswap16(Caml_bytes.get16(b, i));
      } else {
        return Caml_bytes.get16(b, i);
      }
    }
    function get_uint16_be(b, i) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.get16(b, i);
      } else {
        return Caml_bytes.bswap16(Caml_bytes.get16(b, i));
      }
    }
    function get_int16_ne(b, i) {
      return Caml_bytes.get16(b, i) << (Stdlib__Sys.int_size - 16 | 0) >> (Stdlib__Sys.int_size - 16 | 0);
    }
    function get_int16_le(b, i) {
      return get_uint16_le(b, i) << (Stdlib__Sys.int_size - 16 | 0) >> (Stdlib__Sys.int_size - 16 | 0);
    }
    function get_int16_be(b, i) {
      return get_uint16_be(b, i) << (Stdlib__Sys.int_size - 16 | 0) >> (Stdlib__Sys.int_size - 16 | 0);
    }
    function get_int32_le(b, i) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.bswap32(Caml_bytes.get32(b, i));
      } else {
        return Caml_bytes.get32(b, i);
      }
    }
    function get_int32_be(b, i) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.get32(b, i);
      } else {
        return Caml_bytes.bswap32(Caml_bytes.get32(b, i));
      }
    }
    function get_int64_le(b, i) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.bswap64(Caml_bytes.get64(b, i));
      } else {
        return Caml_bytes.get64(b, i);
      }
    }
    function get_int64_be(b, i) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.get64(b, i);
      } else {
        return Caml_bytes.bswap64(Caml_bytes.get64(b, i));
      }
    }
    function unsafe_set_uint16_le(b, i, x) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.set16u(b, i, Caml_bytes.bswap16(x));
      } else {
        return Caml_bytes.set16u(b, i, x);
      }
    }
    function unsafe_set_uint16_be(b, i, x) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.set16u(b, i, x);
      } else {
        return Caml_bytes.set16u(b, i, Caml_bytes.bswap16(x));
      }
    }
    function set_int16_le(b, i, x) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.set16(b, i, Caml_bytes.bswap16(x));
      } else {
        return Caml_bytes.set16(b, i, x);
      }
    }
    function set_int16_be(b, i, x) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.set16(b, i, x);
      } else {
        return Caml_bytes.set16(b, i, Caml_bytes.bswap16(x));
      }
    }
    function set_int32_le(b, i, x) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.set32(b, i, Caml_bytes.bswap32(x));
      } else {
        return Caml_bytes.set32(b, i, x);
      }
    }
    function set_int32_be(b, i, x) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.set32(b, i, x);
      } else {
        return Caml_bytes.set32(b, i, Caml_bytes.bswap32(x));
      }
    }
    function set_int64_le(b, i, x) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.set64(b, i, Caml_bytes.bswap64(x));
      } else {
        return Caml_bytes.set64(b, i, x);
      }
    }
    function set_int64_be(b, i, x) {
      if (Stdlib__Sys.big_endian) {
        return Caml_bytes.set64(b, i, x);
      } else {
        return Caml_bytes.set64(b, i, Caml_bytes.bswap64(x));
      }
    }
    var set_uint8 = Caml_bytes.set;
    var set_uint16_ne = Caml_bytes.set16;
    function get_utf_8_uchar(b, i) {
      const b0 = Caml_bytes.get(b, i);
      const max = b.length - 1 | 0;
      let exit = 0;
      if (b0 >= 224) {
        if (b0 >= 237) {
          if (b0 >= 245) {
            return 16842749;
          }
          switch (b0) {
            case 237:
              const i$1 = i + 1 | 0;
              if (i$1 > max) {
                return 16842749;
              }
              const b1 = b[i$1];
              if (b1 >>> 5 !== 4) {
                return 16842749;
              }
              const i$2 = i$1 + 1 | 0;
              if (i$2 > max) {
                return 33619965;
              }
              const b2 = b[i$2];
              if (b2 >>> 6 !== 2) {
                return 33619965;
              }
              const u = (b0 & 15) << 12 | (b1 & 63) << 6 | b2 & 63;
              return 184549376 | u;
            case 238:
            case 239:
              exit = 1;
              break;
            case 240:
              const i$3 = i + 1 | 0;
              if (i$3 > max) {
                return 16842749;
              }
              const b1$1 = b[i$3];
              if (b1$1 < 144 || 191 < b1$1) {
                return 16842749;
              }
              const i$4 = i$3 + 1 | 0;
              if (i$4 > max) {
                return 33619965;
              }
              const b2$1 = b[i$4];
              if (b2$1 >>> 6 !== 2) {
                return 33619965;
              }
              const i$5 = i$4 + 1 | 0;
              if (i$5 > max) {
                return 50397181;
              }
              const b3 = b[i$5];
              if (b3 >>> 6 !== 2) {
                return 50397181;
              }
              const u$1 = (b0 & 7) << 18 | (b1$1 & 63) << 12 | (b2$1 & 63) << 6 | b3 & 63;
              return 201326592 | u$1;
            case 241:
            case 242:
            case 243:
              exit = 2;
              break;
            case 244:
              const i$6 = i + 1 | 0;
              if (i$6 > max) {
                return 16842749;
              }
              const b1$2 = b[i$6];
              if (b1$2 >>> 4 !== 8) {
                return 16842749;
              }
              const i$7 = i$6 + 1 | 0;
              if (i$7 > max) {
                return 33619965;
              }
              const b2$2 = b[i$7];
              if (b2$2 >>> 6 !== 2) {
                return 33619965;
              }
              const i$8 = i$7 + 1 | 0;
              if (i$8 > max) {
                return 50397181;
              }
              const b3$1 = b[i$8];
              if (b3$1 >>> 6 !== 2) {
                return 50397181;
              }
              const u$2 = (b0 & 7) << 18 | (b1$2 & 63) << 12 | (b2$2 & 63) << 6 | b3$1 & 63;
              return 201326592 | u$2;
          }
        } else if (b0 >= 225) {
          exit = 1;
        } else {
          const i$9 = i + 1 | 0;
          if (i$9 > max) {
            return 16842749;
          }
          const b1$3 = b[i$9];
          if (b1$3 >>> 5 !== 5) {
            return 16842749;
          }
          const i$10 = i$9 + 1 | 0;
          if (i$10 > max) {
            return 33619965;
          }
          const b2$3 = b[i$10];
          if (b2$3 >>> 6 !== 2) {
            return 33619965;
          }
          const u$3 = (b0 & 15) << 12 | (b1$3 & 63) << 6 | b2$3 & 63;
          return 184549376 | u$3;
        }
      } else {
        if (b0 < 128) {
          return 150994944 | b0;
        }
        if (b0 < 194) {
          return 16842749;
        }
        const i$11 = i + 1 | 0;
        if (i$11 > max) {
          return 16842749;
        }
        const b1$4 = b[i$11];
        if (b1$4 >>> 6 !== 2) {
          return 16842749;
        }
        const u$4 = (b0 & 31) << 6 | b1$4 & 63;
        return 167772160 | u$4;
      }
      switch (exit) {
        case 1:
          const i$12 = i + 1 | 0;
          if (i$12 > max) {
            return 16842749;
          }
          const b1$5 = b[i$12];
          if (b1$5 >>> 6 !== 2) {
            return 16842749;
          }
          const i$13 = i$12 + 1 | 0;
          if (i$13 > max) {
            return 33619965;
          }
          const b2$4 = b[i$13];
          if (b2$4 >>> 6 !== 2) {
            return 33619965;
          }
          const u$5 = (b0 & 15) << 12 | (b1$5 & 63) << 6 | b2$4 & 63;
          return 184549376 | u$5;
        case 2:
          const i$14 = i + 1 | 0;
          if (i$14 > max) {
            return 16842749;
          }
          const b1$6 = b[i$14];
          if (b1$6 >>> 6 !== 2) {
            return 16842749;
          }
          const i$15 = i$14 + 1 | 0;
          if (i$15 > max) {
            return 33619965;
          }
          const b2$5 = b[i$15];
          if (b2$5 >>> 6 !== 2) {
            return 33619965;
          }
          const i$16 = i$15 + 1 | 0;
          if (i$16 > max) {
            return 50397181;
          }
          const b3$2 = b[i$16];
          if (b3$2 >>> 6 !== 2) {
            return 50397181;
          }
          const u$6 = (b0 & 7) << 18 | (b1$6 & 63) << 12 | (b2$5 & 63) << 6 | b3$2 & 63;
          return 201326592 | u$6;
      }
    }
    function set_utf_8_uchar(b, i, u) {
      const max = b.length - 1 | 0;
      const u$1 = u;
      if (u$1 < 0) {
        throw new Caml_js_exceptions.MelangeError("Assert_failure", {
          MEL_EXN_ID: "Assert_failure",
          _1: [
            "bytes.ml",
            654,
            20
          ]
        });
      }
      if (u$1 <= 127) {
        Caml_bytes.set(b, i, u$1);
        return 1;
      }
      if (u$1 <= 2047) {
        const last = i + 1 | 0;
        if (last > max) {
          return 0;
        } else {
          Caml_bytes.set(b, i, 192 | u$1 >>> 6);
          b[last] = 128 | u$1 & 63;
          return 2;
        }
      }
      if (u$1 <= 65535) {
        const last$1 = i + 2 | 0;
        if (last$1 > max) {
          return 0;
        } else {
          Caml_bytes.set(b, i, 224 | u$1 >>> 12);
          b[i + 1 | 0] = 128 | u$1 >>> 6 & 63;
          b[last$1] = 128 | u$1 & 63;
          return 3;
        }
      }
      if (u$1 <= 1114111) {
        const last$2 = i + 3 | 0;
        if (last$2 > max) {
          return 0;
        } else {
          Caml_bytes.set(b, i, 240 | u$1 >>> 18);
          b[i + 1 | 0] = 128 | u$1 >>> 12 & 63;
          b[i + 2 | 0] = 128 | u$1 >>> 6 & 63;
          b[last$2] = 128 | u$1 & 63;
          return 4;
        }
      }
      throw new Caml_js_exceptions.MelangeError("Assert_failure", {
        MEL_EXN_ID: "Assert_failure",
        _1: [
          "bytes.ml",
          679,
          9
        ]
      });
    }
    function is_valid_utf_8(b) {
      let max = b.length - 1 | 0;
      let _i = 0;
      while (true) {
        const i = _i;
        if (i > max) {
          return true;
        }
        const match = b[i];
        let exit = 0;
        if (match >= 224) {
          if (match >= 237) {
            if (match >= 245) {
              return false;
            }
            switch (match) {
              case 237:
                const last = i + 2 | 0;
                if (last > max || b[i + 1 | 0] >>> 5 !== 4 || b[last] >>> 6 !== 2) {
                  return false;
                }
                _i = last + 1 | 0;
                continue;
              case 238:
              case 239:
                exit = 1;
                break;
              case 240:
                const last$1 = i + 3 | 0;
                let tmp = true;
                if (last$1 <= max) {
                  const b$1 = b[i + 1 | 0];
                  tmp = b$1 < 144 || 191 < b$1 || b[i + 2 | 0] >>> 6 !== 2 || b[last$1] >>> 6 !== 2;
                }
                if (tmp) {
                  return false;
                }
                _i = last$1 + 1 | 0;
                continue;
              case 241:
              case 242:
              case 243:
                exit = 2;
                break;
              case 244:
                const last$2 = i + 3 | 0;
                if (last$2 > max || b[i + 1 | 0] >>> 4 !== 8 || b[i + 2 | 0] >>> 6 !== 2 || b[last$2] >>> 6 !== 2) {
                  return false;
                }
                _i = last$2 + 1 | 0;
                continue;
            }
          } else if (match >= 225) {
            exit = 1;
          } else {
            const last$3 = i + 2 | 0;
            if (last$3 > max || b[i + 1 | 0] >>> 5 !== 5 || b[last$3] >>> 6 !== 2) {
              return false;
            }
            _i = last$3 + 1 | 0;
            continue;
          }
        } else {
          if (match >= 128) {
            if (match < 194) {
              return false;
            }
            const last$4 = i + 1 | 0;
            if (last$4 > max || b[last$4] >>> 6 !== 2) {
              return false;
            }
            _i = last$4 + 1 | 0;
            continue;
          }
          _i = i + 1 | 0;
          continue;
        }
        switch (exit) {
          case 1:
            const last$5 = i + 2 | 0;
            if (last$5 > max || b[i + 1 | 0] >>> 6 !== 2 || b[last$5] >>> 6 !== 2) {
              return false;
            }
            _i = last$5 + 1 | 0;
            continue;
          case 2:
            const last$6 = i + 3 | 0;
            if (last$6 > max || b[i + 1 | 0] >>> 6 !== 2 || b[i + 2 | 0] >>> 6 !== 2 || b[last$6] >>> 6 !== 2) {
              return false;
            }
            _i = last$6 + 1 | 0;
            continue;
        }
      }
      ;
    }
    function get_utf_16be_uchar(b, i) {
      const max = b.length - 1 | 0;
      if (i < 0 || i > max) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      if (i === max) {
        return 16842749;
      }
      const u = unsafe_get_uint16_be(b, i);
      if (u < 55296 || u > 57343) {
        return 167772160 | u;
      }
      if (u > 56319) {
        return 33619965;
      }
      const last = i + 3 | 0;
      if (last > max) {
        return ((max - i | 0) + 1 | 0) << 24 | 65533;
      }
      const u$1 = unsafe_get_uint16_be(b, i + 2 | 0);
      if (u$1 < 56320 || u$1 > 57343) {
        return 33619965;
      }
      const u$2 = ((u & 1023) << 10 | u$1 & 1023) + 65536 | 0;
      return 201326592 | u$2;
    }
    function set_utf_16be_uchar(b, i, u) {
      const max = b.length - 1 | 0;
      if (i < 0 || i > max) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      const u$1 = u;
      if (u$1 < 0) {
        throw new Caml_js_exceptions.MelangeError("Assert_failure", {
          MEL_EXN_ID: "Assert_failure",
          _1: [
            "bytes.ml",
            766,
            20
          ]
        });
      }
      if (u$1 <= 65535) {
        const last = i + 1 | 0;
        if (last > max) {
          return 0;
        } else {
          unsafe_set_uint16_be(b, i, u$1);
          return 2;
        }
      }
      if (u$1 <= 1114111) {
        const last$1 = i + 3 | 0;
        if (last$1 > max) {
          return 0;
        }
        const u$p = u$1 - 65536 | 0;
        const hi = 55296 | u$p >>> 10;
        const lo = 56320 | u$p & 1023;
        unsafe_set_uint16_be(b, i, hi);
        unsafe_set_uint16_be(b, i + 2 | 0, lo);
        return 4;
      }
      throw new Caml_js_exceptions.MelangeError("Assert_failure", {
        MEL_EXN_ID: "Assert_failure",
        _1: [
          "bytes.ml",
          777,
          9
        ]
      });
    }
    function is_valid_utf_16be(b) {
      let max = b.length - 1 | 0;
      let _i = 0;
      while (true) {
        const i = _i;
        if (i > max) {
          return true;
        }
        if (i === max) {
          return false;
        }
        const u = unsafe_get_uint16_be(b, i);
        if (u < 55296 || u > 57343) {
          _i = i + 2 | 0;
          continue;
        }
        if (u > 56319) {
          return false;
        }
        const last = i + 3 | 0;
        if (last > max) {
          return false;
        }
        const u$1 = unsafe_get_uint16_be(b, i + 2 | 0);
        if (u$1 < 56320 || u$1 > 57343) {
          return false;
        }
        _i = i + 4 | 0;
        continue;
      }
      ;
    }
    function get_utf_16le_uchar(b, i) {
      const max = b.length - 1 | 0;
      if (i < 0 || i > max) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      if (i === max) {
        return 16842749;
      }
      const u = unsafe_get_uint16_le(b, i);
      if (u < 55296 || u > 57343) {
        return 167772160 | u;
      }
      if (u > 56319) {
        return 33619965;
      }
      const last = i + 3 | 0;
      if (last > max) {
        return ((max - i | 0) + 1 | 0) << 24 | 65533;
      }
      const u$1 = unsafe_get_uint16_le(b, i + 2 | 0);
      if (u$1 < 56320 || u$1 > 57343) {
        return 33619965;
      }
      const u$2 = ((u & 1023) << 10 | u$1 & 1023) + 65536 | 0;
      return 201326592 | u$2;
    }
    function set_utf_16le_uchar(b, i, u) {
      const max = b.length - 1 | 0;
      if (i < 0 || i > max) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "index out of bounds"
        });
      }
      const u$1 = u;
      if (u$1 < 0) {
        throw new Caml_js_exceptions.MelangeError("Assert_failure", {
          MEL_EXN_ID: "Assert_failure",
          _1: [
            "bytes.ml",
            820,
            20
          ]
        });
      }
      if (u$1 <= 65535) {
        const last = i + 1 | 0;
        if (last > max) {
          return 0;
        } else {
          unsafe_set_uint16_le(b, i, u$1);
          return 2;
        }
      }
      if (u$1 <= 1114111) {
        const last$1 = i + 3 | 0;
        if (last$1 > max) {
          return 0;
        }
        const u$p = u$1 - 65536 | 0;
        const hi = 55296 | u$p >>> 10;
        const lo = 56320 | u$p & 1023;
        unsafe_set_uint16_le(b, i, hi);
        unsafe_set_uint16_le(b, i + 2 | 0, lo);
        return 4;
      }
      throw new Caml_js_exceptions.MelangeError("Assert_failure", {
        MEL_EXN_ID: "Assert_failure",
        _1: [
          "bytes.ml",
          831,
          9
        ]
      });
    }
    function is_valid_utf_16le(b) {
      let max = b.length - 1 | 0;
      let _i = 0;
      while (true) {
        const i = _i;
        if (i > max) {
          return true;
        }
        if (i === max) {
          return false;
        }
        const u = unsafe_get_uint16_le(b, i);
        if (u < 55296 || u > 57343) {
          _i = i + 2 | 0;
          continue;
        }
        if (u > 56319) {
          return false;
        }
        const last = i + 3 | 0;
        if (last > max) {
          return false;
        }
        const u$1 = unsafe_get_uint16_le(b, i + 2 | 0);
        if (u$1 < 56320 || u$1 > 57343) {
          return false;
        }
        _i = i + 4 | 0;
        continue;
      }
      ;
    }
    var equal = Caml_bytes.caml_bytes_equal;
    var unsafe_to_string = Caml_bytes.bytes_to_string;
    var unsafe_of_string = Caml_bytes.bytes_of_string;
    var get_uint8 = Caml_bytes.get;
    var get_uint16_ne = Caml_bytes.get16;
    var get_int32_ne = Caml_bytes.get32;
    var get_int64_ne = Caml_bytes.get64;
    var set_int8 = Caml_bytes.set;
    var set_uint16_be = set_int16_be;
    var set_uint16_le = set_int16_le;
    var set_int16_ne = Caml_bytes.set16;
    var set_int32_ne = Caml_bytes.set32;
    var set_int64_ne = Caml_bytes.set64;
    module2.exports = {
      make,
      init,
      empty,
      copy,
      of_string,
      to_string,
      sub,
      sub_string,
      extend,
      fill,
      blit,
      blit_string,
      concat,
      cat,
      iter,
      iteri,
      map,
      mapi,
      fold_left,
      fold_right,
      for_all,
      exists,
      trim,
      escaped,
      index,
      index_opt,
      rindex,
      rindex_opt,
      index_from,
      index_from_opt,
      rindex_from,
      rindex_from_opt,
      contains,
      contains_from,
      rcontains_from,
      uppercase_ascii,
      lowercase_ascii,
      capitalize_ascii,
      uncapitalize_ascii,
      compare,
      equal,
      starts_with,
      ends_with,
      unsafe_to_string,
      unsafe_of_string,
      split_on_char,
      to_seq,
      to_seqi,
      of_seq,
      get_utf_8_uchar,
      set_utf_8_uchar,
      is_valid_utf_8,
      get_utf_16be_uchar,
      set_utf_16be_uchar,
      is_valid_utf_16be,
      get_utf_16le_uchar,
      set_utf_16le_uchar,
      is_valid_utf_16le,
      get_uint8,
      get_int8,
      get_uint16_ne,
      get_uint16_be,
      get_uint16_le,
      get_int16_ne,
      get_int16_be,
      get_int16_le,
      get_int32_ne,
      get_int32_be,
      get_int32_le,
      get_int64_ne,
      get_int64_be,
      get_int64_le,
      set_uint8,
      set_int8,
      set_uint16_ne,
      set_uint16_be,
      set_uint16_le,
      set_int16_ne,
      set_int16_be,
      set_int16_le,
      set_int32_ne,
      set_int32_be,
      set_int32_le,
      set_int64_ne,
      set_int64_be,
      set_int64_le,
      unsafe_escape
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/string.js
var require_string = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/string.js"(exports2, module2) {
    "use strict";
    var Caml = require_caml();
    var Caml_bytes = require_caml_bytes();
    var Caml_external_polyfill = require_caml_external_polyfill();
    var Caml_js_exceptions = require_caml_js_exceptions();
    var Caml_string = require_caml_string();
    var Curry2 = require_curry();
    var Stdlib = require_stdlib();
    var Stdlib__Bytes = require_bytes();
    function make(n2, c) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.make(n2, c));
    }
    function init(n2, f) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.init(n2, f));
    }
    function sub(s, ofs, len) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.sub(Caml_bytes.bytes_of_string(s), ofs, len));
    }
    function ensure_ge(x, y) {
      if (x >= y) {
        return x;
      }
      throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
        MEL_EXN_ID: "Invalid_argument",
        _1: "String.concat"
      });
    }
    function sum_lengths(_acc, seplen, _param) {
      while (true) {
        const param = _param;
        const acc = _acc;
        if (!param) {
          return acc;
        }
        const hd = param.hd;
        if (!param.tl) {
          return hd.length + acc | 0;
        }
        _param = param.tl;
        _acc = ensure_ge((hd.length + seplen | 0) + acc | 0, acc);
        continue;
      }
      ;
    }
    function unsafe_blits(dst, _pos, sep, seplen, _param) {
      while (true) {
        const param = _param;
        const pos = _pos;
        if (!param) {
          return dst;
        }
        const hd = param.hd;
        if (param.tl) {
          Caml_bytes.caml_blit_string(hd, 0, dst, pos, hd.length);
          Caml_bytes.caml_blit_string(sep, 0, dst, pos + hd.length | 0, seplen);
          _param = param.tl;
          _pos = (pos + hd.length | 0) + seplen | 0;
          continue;
        }
        Caml_bytes.caml_blit_string(hd, 0, dst, pos, hd.length);
        return dst;
      }
      ;
    }
    function concat(sep, l) {
      if (!l) {
        return "";
      }
      const seplen = sep.length;
      return Caml_bytes.bytes_to_string(unsafe_blits(Caml_bytes.caml_create_bytes(sum_lengths(0, seplen, l)), 0, sep, seplen, l));
    }
    function cat(prim0, prim1) {
      return prim0 + prim1;
    }
    function iter(f, s) {
      for (let i = 0, i_finish = s.length; i < i_finish; ++i) {
        Curry2._1(f, s.charCodeAt(i));
      }
    }
    function iteri(f, s) {
      for (let i = 0, i_finish = s.length; i < i_finish; ++i) {
        Curry2._2(f, i, s.charCodeAt(i));
      }
    }
    function map(f, s) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.map(f, Caml_bytes.bytes_of_string(s)));
    }
    function mapi(f, s) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.mapi(f, Caml_bytes.bytes_of_string(s)));
    }
    function fold_right(f, x, a) {
      return Stdlib__Bytes.fold_right(f, Caml_bytes.bytes_of_string(x), a);
    }
    function fold_left(f, a, x) {
      return Stdlib__Bytes.fold_left(f, a, Caml_bytes.bytes_of_string(x));
    }
    function exists(f, s) {
      return Stdlib__Bytes.exists(f, Caml_bytes.bytes_of_string(s));
    }
    function for_all(f, s) {
      return Stdlib__Bytes.for_all(f, Caml_bytes.bytes_of_string(s));
    }
    function is_space(param) {
      if (param > 13 || param < 9) {
        return param === 32;
      } else {
        return param !== 11;
      }
    }
    function trim(s) {
      if (s === "" || !(is_space(s.charCodeAt(0)) || is_space(s.charCodeAt(s.length - 1 | 0)))) {
        return s;
      } else {
        return Caml_bytes.bytes_to_string(Stdlib__Bytes.trim(Caml_bytes.bytes_of_string(s)));
      }
    }
    function escaped(s) {
      const b = Caml_bytes.bytes_of_string(s);
      const b$p = Stdlib__Bytes.unsafe_escape(b);
      if (b === b$p) {
        return s;
      } else {
        return Caml_bytes.bytes_to_string(b$p);
      }
    }
    function index_rec(s, lim, _i, c) {
      while (true) {
        const i = _i;
        if (i >= lim) {
          throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
            MEL_EXN_ID: Stdlib.Not_found
          });
        }
        if (s.charCodeAt(i) === c) {
          return i;
        }
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function index(s, c) {
      return index_rec(s, s.length, 0, c);
    }
    function index_rec_opt(s, lim, _i, c) {
      while (true) {
        const i = _i;
        if (i >= lim) {
          return;
        }
        if (s.charCodeAt(i) === c) {
          return i;
        }
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function index_opt(s, c) {
      return index_rec_opt(s, s.length, 0, c);
    }
    function index_from(s, i, c) {
      const l = s.length;
      if (i < 0 || i > l) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.index_from / Bytes.index_from"
        });
      }
      return index_rec(s, l, i, c);
    }
    function index_from_opt(s, i, c) {
      const l = s.length;
      if (i < 0 || i > l) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.index_from_opt / Bytes.index_from_opt"
        });
      }
      return index_rec_opt(s, l, i, c);
    }
    function rindex_rec(s, _i, c) {
      while (true) {
        const i = _i;
        if (i < 0) {
          throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
            MEL_EXN_ID: Stdlib.Not_found
          });
        }
        if (s.charCodeAt(i) === c) {
          return i;
        }
        _i = i - 1 | 0;
        continue;
      }
      ;
    }
    function rindex(s, c) {
      return rindex_rec(s, s.length - 1 | 0, c);
    }
    function rindex_from(s, i, c) {
      if (i < -1 || i >= s.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.rindex_from / Bytes.rindex_from"
        });
      }
      return rindex_rec(s, i, c);
    }
    function rindex_rec_opt(s, _i, c) {
      while (true) {
        const i = _i;
        if (i < 0) {
          return;
        }
        if (s.charCodeAt(i) === c) {
          return i;
        }
        _i = i - 1 | 0;
        continue;
      }
      ;
    }
    function rindex_opt(s, c) {
      return rindex_rec_opt(s, s.length - 1 | 0, c);
    }
    function rindex_from_opt(s, i, c) {
      if (i < -1 || i >= s.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.rindex_from_opt / Bytes.rindex_from_opt"
        });
      }
      return rindex_rec_opt(s, i, c);
    }
    function contains_from(s, i, c) {
      const l = s.length;
      if (i < 0 || i > l) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.contains_from / Bytes.contains_from"
        });
      }
      try {
        index_rec(s, l, i, c);
        return true;
      } catch (raw_exn) {
        const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
        if (exn.MEL_EXN_ID === Stdlib.Not_found) {
          return false;
        }
        throw exn;
      }
    }
    function contains(s, c) {
      return contains_from(s, 0, c);
    }
    function rcontains_from(s, i, c) {
      if (i < 0 || i >= s.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "String.rcontains_from / Bytes.rcontains_from"
        });
      }
      try {
        rindex_rec(s, i, c);
        return true;
      } catch (raw_exn) {
        const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
        if (exn.MEL_EXN_ID === Stdlib.Not_found) {
          return false;
        }
        throw exn;
      }
    }
    function uppercase_ascii(s) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.uppercase_ascii(Caml_bytes.bytes_of_string(s)));
    }
    function lowercase_ascii(s) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.lowercase_ascii(Caml_bytes.bytes_of_string(s)));
    }
    function capitalize_ascii(s) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.capitalize_ascii(Caml_bytes.bytes_of_string(s)));
    }
    function uncapitalize_ascii(s) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.uncapitalize_ascii(Caml_bytes.bytes_of_string(s)));
    }
    function starts_with(prefix, s) {
      const len_s = s.length;
      const len_pre = prefix.length;
      if (len_s >= len_pre) {
        let _i = 0;
        while (true) {
          const i = _i;
          if (i === len_pre) {
            return true;
          }
          if (s.charCodeAt(i) !== prefix.charCodeAt(i)) {
            return false;
          }
          _i = i + 1 | 0;
          continue;
        }
        ;
      } else {
        return false;
      }
    }
    function ends_with(suffix, s) {
      const len_s = s.length;
      const len_suf = suffix.length;
      const diff = len_s - len_suf | 0;
      if (diff >= 0) {
        let _i = 0;
        while (true) {
          const i = _i;
          if (i === len_suf) {
            return true;
          }
          if (s.charCodeAt(diff + i | 0) !== suffix.charCodeAt(i)) {
            return false;
          }
          _i = i + 1 | 0;
          continue;
        }
        ;
      } else {
        return false;
      }
    }
    function hash(x) {
      return Caml_external_polyfill.resolve("caml_string_hash")(0, x);
    }
    function split_on_char(sep, s) {
      let r = (
        /* [] */
        0
      );
      let j = s.length;
      for (let i = s.length - 1 | 0; i >= 0; --i) {
        if (s.charCodeAt(i) === sep) {
          r = {
            hd: sub(s, i + 1 | 0, (j - i | 0) - 1 | 0),
            tl: r
          };
          j = i;
        }
      }
      return {
        hd: sub(s, 0, j),
        tl: r
      };
    }
    var compare = Caml.caml_string_compare;
    function to_seq(s) {
      return Stdlib__Bytes.to_seq(Caml_bytes.bytes_of_string(s));
    }
    function to_seqi(s) {
      return Stdlib__Bytes.to_seqi(Caml_bytes.bytes_of_string(s));
    }
    function of_seq(g) {
      return Caml_bytes.bytes_to_string(Stdlib__Bytes.of_seq(g));
    }
    function get_utf_8_uchar(s, i) {
      return Stdlib__Bytes.get_utf_8_uchar(Caml_bytes.bytes_of_string(s), i);
    }
    function is_valid_utf_8(s) {
      return Stdlib__Bytes.is_valid_utf_8(Caml_bytes.bytes_of_string(s));
    }
    function get_utf_16be_uchar(s, i) {
      return Stdlib__Bytes.get_utf_16be_uchar(Caml_bytes.bytes_of_string(s), i);
    }
    function is_valid_utf_16be(s) {
      return Stdlib__Bytes.is_valid_utf_16be(Caml_bytes.bytes_of_string(s));
    }
    function get_utf_16le_uchar(s, i) {
      return Stdlib__Bytes.get_utf_16le_uchar(Caml_bytes.bytes_of_string(s), i);
    }
    function is_valid_utf_16le(s) {
      return Stdlib__Bytes.is_valid_utf_16le(Caml_bytes.bytes_of_string(s));
    }
    function get_int8(s, i) {
      return Stdlib__Bytes.get_int8(Caml_bytes.bytes_of_string(s), i);
    }
    function get_uint16_le(s, i) {
      return Stdlib__Bytes.get_uint16_le(Caml_bytes.bytes_of_string(s), i);
    }
    function get_uint16_be(s, i) {
      return Stdlib__Bytes.get_uint16_be(Caml_bytes.bytes_of_string(s), i);
    }
    function get_int16_ne(s, i) {
      return Stdlib__Bytes.get_int16_ne(Caml_bytes.bytes_of_string(s), i);
    }
    function get_int16_le(s, i) {
      return Stdlib__Bytes.get_int16_le(Caml_bytes.bytes_of_string(s), i);
    }
    function get_int16_be(s, i) {
      return Stdlib__Bytes.get_int16_be(Caml_bytes.bytes_of_string(s), i);
    }
    function get_int32_le(s, i) {
      return Stdlib__Bytes.get_int32_le(Caml_bytes.bytes_of_string(s), i);
    }
    function get_int32_be(s, i) {
      return Stdlib__Bytes.get_int32_be(Caml_bytes.bytes_of_string(s), i);
    }
    function get_int64_le(s, i) {
      return Stdlib__Bytes.get_int64_le(Caml_bytes.bytes_of_string(s), i);
    }
    function get_int64_be(s, i) {
      return Stdlib__Bytes.get_int64_be(Caml_bytes.bytes_of_string(s), i);
    }
    var empty = "";
    var of_bytes = Stdlib__Bytes.to_string;
    var to_bytes = Stdlib__Bytes.of_string;
    var blit = Stdlib__Bytes.blit_string;
    function equal(prim0, prim1) {
      return prim0 === prim1;
    }
    var get_uint8 = Caml_string.get;
    var get_uint16_ne = Caml_bytes.get16;
    var get_int32_ne = Caml_bytes.get32;
    function seeded_hash(prim0, prim1) {
      return Caml_external_polyfill.resolve("caml_string_hash")(prim0, prim1);
    }
    var get_int64_ne = Caml_bytes.get64;
    module2.exports = {
      make,
      init,
      empty,
      of_bytes,
      to_bytes,
      blit,
      concat,
      cat,
      equal,
      compare,
      starts_with,
      ends_with,
      contains_from,
      rcontains_from,
      contains,
      sub,
      split_on_char,
      map,
      mapi,
      fold_left,
      fold_right,
      for_all,
      exists,
      trim,
      escaped,
      uppercase_ascii,
      lowercase_ascii,
      capitalize_ascii,
      uncapitalize_ascii,
      iter,
      iteri,
      index_from,
      index_from_opt,
      rindex_from,
      rindex_from_opt,
      index,
      index_opt,
      rindex,
      rindex_opt,
      to_seq,
      to_seqi,
      of_seq,
      get_utf_8_uchar,
      is_valid_utf_8,
      get_utf_16be_uchar,
      is_valid_utf_16be,
      get_utf_16le_uchar,
      is_valid_utf_16le,
      get_uint8,
      get_int8,
      get_uint16_ne,
      get_uint16_be,
      get_uint16_le,
      get_int16_ne,
      get_int16_be,
      get_int16_le,
      get_int32_ne,
      hash,
      seeded_hash,
      get_int32_be,
      get_int32_le,
      get_int64_ne,
      get_int64_be,
      get_int64_le
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/buffer.js
var require_buffer = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/buffer.js"(exports2, module2) {
    "use strict";
    var Caml_bytes = require_caml_bytes();
    var Caml_js_exceptions = require_caml_js_exceptions();
    var Caml_string = require_caml_string();
    var Curry2 = require_curry();
    var Stdlib = require_stdlib();
    var Stdlib__Bytes = require_bytes();
    var Stdlib__Seq = require_seq();
    var Stdlib__String2 = require_string();
    var Stdlib__Sys = require_sys();
    function create(n2) {
      const n$1 = n2 < 1 ? 1 : n2;
      const n$2 = n$1 > Stdlib__Sys.max_string_length ? Stdlib__Sys.max_string_length : n$1;
      const s = Caml_bytes.caml_create_bytes(n$2);
      return {
        inner: {
          buffer: s,
          length: n$2
        },
        position: 0,
        initial_buffer: s
      };
    }
    function contents(b) {
      return Stdlib__Bytes.sub_string(b.inner.buffer, 0, b.position);
    }
    function to_bytes(b) {
      return Stdlib__Bytes.sub(b.inner.buffer, 0, b.position);
    }
    function sub(b, ofs, len) {
      if (ofs < 0 || len < 0 || ofs > (b.position - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Buffer.sub"
        });
      }
      return Stdlib__Bytes.sub_string(b.inner.buffer, ofs, len);
    }
    function blit(src, srcoff, dst, dstoff, len) {
      if (len < 0 || srcoff < 0 || srcoff > (src.position - len | 0) || dstoff < 0 || dstoff > (dst.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Buffer.blit"
        });
      }
      Stdlib__Bytes.blit(src.inner.buffer, srcoff, dst, dstoff, len);
    }
    function nth(b, ofs) {
      const position = b.position;
      const match = b.inner;
      if (ofs < 0 || ofs >= position || position > match.length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Buffer.nth"
        });
      }
      return match.buffer[ofs];
    }
    function length(b) {
      return b.position;
    }
    function clear(b) {
      b.position = 0;
    }
    function reset(b) {
      b.position = 0;
      const inner_buffer = b.initial_buffer;
      const inner_length = b.initial_buffer.length;
      const inner = {
        buffer: inner_buffer,
        length: inner_length
      };
      b.inner = inner;
    }
    function resize(b, more) {
      const old_pos = b.position;
      const old_len = b.inner.length;
      let new_len = old_len;
      while ((old_pos + more | 0) > new_len) {
        new_len = new_len << 1;
      }
      ;
      if (new_len > Stdlib__Sys.max_string_length) {
        if ((old_pos + more | 0) <= Stdlib__Sys.max_string_length) {
          new_len = Stdlib__Sys.max_string_length;
        } else {
          throw new Caml_js_exceptions.MelangeError("Failure", {
            MEL_EXN_ID: "Failure",
            _1: "Buffer.add: cannot grow buffer"
          });
        }
      }
      const new_buffer = Caml_bytes.caml_create_bytes(new_len);
      Stdlib__Bytes.blit(b.inner.buffer, 0, new_buffer, 0, b.position);
      b.inner = {
        buffer: new_buffer,
        length: new_len
      };
    }
    function add_char(b, c) {
      const pos = b.position;
      const match = b.inner;
      if (pos >= match.length) {
        resize(b, 1);
        Caml_bytes.set(b.inner.buffer, b.position, c);
      } else {
        match.buffer[pos] = c;
      }
      b.position = pos + 1 | 0;
    }
    function add_utf_8_uchar(b, u) {
      while (true) {
        const pos = b.position;
        if (pos >= b.inner.length) {
          resize(b, 4);
        }
        const n2 = Stdlib__Bytes.set_utf_8_uchar(b.inner.buffer, pos, u);
        if (n2 !== 0) {
          b.position = pos + n2 | 0;
          return;
        }
        resize(b, 4);
        continue;
      }
      ;
    }
    function add_utf_16be_uchar(b, u) {
      while (true) {
        const pos = b.position;
        if (pos >= b.inner.length) {
          resize(b, 4);
        }
        const n2 = Stdlib__Bytes.set_utf_16be_uchar(b.inner.buffer, pos, u);
        if (n2 !== 0) {
          b.position = pos + n2 | 0;
          return;
        }
        resize(b, 4);
        continue;
      }
      ;
    }
    function add_utf_16le_uchar(b, u) {
      while (true) {
        const pos = b.position;
        if (pos >= b.inner.length) {
          resize(b, 4);
        }
        const n2 = Stdlib__Bytes.set_utf_16le_uchar(b.inner.buffer, pos, u);
        if (n2 !== 0) {
          b.position = pos + n2 | 0;
          return;
        }
        resize(b, 4);
        continue;
      }
      ;
    }
    function add_substring(b, s, offset, len) {
      if (offset < 0 || len < 0 || offset > (s.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Buffer.add_substring"
        });
      }
      const position = b.position;
      const match = b.inner;
      const new_position = position + len | 0;
      if (new_position > match.length) {
        resize(b, len);
        Stdlib__Bytes.blit_string(s, offset, b.inner.buffer, b.position, len);
      } else {
        Caml_bytes.caml_blit_string(s, offset, match.buffer, position, len);
      }
      b.position = new_position;
    }
    function add_subbytes(b, bytes, offset, len) {
      if (offset < 0 || len < 0 || offset > (bytes.length - len | 0)) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Buffer.add_subbytes"
        });
      }
      const position = b.position;
      const match = b.inner;
      const new_position = position + len | 0;
      if (new_position > match.length) {
        resize(b, len);
        Stdlib__Bytes.blit(bytes, offset, b.inner.buffer, b.position, len);
      } else {
        Caml_bytes.caml_blit_bytes(bytes, offset, match.buffer, position, len);
      }
      b.position = new_position;
    }
    function add_string(b, s) {
      add_substring(b, s, 0, s.length);
    }
    function add_bytes(b, bytes) {
      add_subbytes(b, bytes, 0, bytes.length);
    }
    function add_buffer(b, bs) {
      add_subbytes(b, bs.inner.buffer, 0, bs.position);
    }
    function really_input_up_to(ic, buf, ofs, len) {
      let _already_read = 0;
      let _ofs = ofs;
      let _to_read = len;
      while (true) {
        const to_read = _to_read;
        const ofs$1 = _ofs;
        const already_read = _already_read;
        if (to_read === 0) {
          return already_read;
        }
        const r = Stdlib.input(ic, buf, ofs$1, to_read);
        if (r === 0) {
          return already_read;
        }
        const already_read$1 = already_read + r | 0;
        const ofs$2 = ofs$1 + r | 0;
        const to_read$1 = to_read - r | 0;
        _to_read = to_read$1;
        _ofs = ofs$2;
        _already_read = already_read$1;
        continue;
      }
      ;
    }
    function unsafe_add_channel_up_to(b, ic, len) {
      if ((b.position + len | 0) > b.inner.length) {
        resize(b, len);
      }
      const n2 = really_input_up_to(ic, b.inner.buffer, b.position, len);
      b.position = b.position + n2 | 0;
      return n2;
    }
    function add_channel(b, ic, len) {
      if (len < 0 || len > Stdlib__Sys.max_string_length) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Buffer.add_channel"
        });
      }
      const n2 = unsafe_add_channel_up_to(b, ic, len);
      if (n2 < len) {
        throw new Caml_js_exceptions.MelangeError(Stdlib.End_of_file, {
          MEL_EXN_ID: Stdlib.End_of_file
        });
      }
    }
    function output_buffer(oc, b) {
      Stdlib.output(oc, b.inner.buffer, 0, b.position);
    }
    function closing(param) {
      if (param === 40) {
        return (
          /* ')' */
          41
        );
      }
      if (param === 123) {
        return (
          /* '}' */
          125
        );
      }
      throw new Caml_js_exceptions.MelangeError("Assert_failure", {
        MEL_EXN_ID: "Assert_failure",
        _1: [
          "buffer.ml",
          222,
          9
        ]
      });
    }
    function advance_to_closing(opening, closing2, k, s, start) {
      let _k = k;
      let _i = start;
      let lim = s.length;
      while (true) {
        const i = _i;
        const k$1 = _k;
        if (i >= lim) {
          throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
            MEL_EXN_ID: Stdlib.Not_found
          });
        }
        if (Caml_string.get(s, i) === opening) {
          _i = i + 1 | 0;
          _k = k$1 + 1 | 0;
          continue;
        }
        if (Caml_string.get(s, i) === closing2) {
          if (k$1 === 0) {
            return i;
          }
          _i = i + 1 | 0;
          _k = k$1 - 1 | 0;
          continue;
        }
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function advance_to_non_alpha(s, start) {
      let _i = start;
      let lim = s.length;
      while (true) {
        const i = _i;
        if (i >= lim) {
          return lim;
        }
        const match = Caml_string.get(s, i);
        if (match >= 91) {
          if (match >= 97) {
            if (match >= 123) {
              return i;
            }
          } else if (match !== 95) {
            return i;
          }
        } else if (match >= 58) {
          if (match < 65) {
            return i;
          }
        } else if (match < 48) {
          return i;
        }
        _i = i + 1 | 0;
        continue;
      }
      ;
    }
    function find_ident(s, start, lim) {
      if (start >= lim) {
        throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
          MEL_EXN_ID: Stdlib.Not_found
        });
      }
      const c = Caml_string.get(s, start);
      if (c !== 40 && c !== 123) {
        const stop = advance_to_non_alpha(s, start);
        if (stop === start) {
          throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
            MEL_EXN_ID: Stdlib.Not_found
          });
        }
        return [
          Stdlib__String2.sub(s, start, stop - start | 0),
          stop
        ];
      }
      const new_start = start + 1 | 0;
      const stop$1 = advance_to_closing(c, closing(c), 0, s, new_start);
      return [
        Stdlib__String2.sub(s, new_start, (stop$1 - start | 0) - 1 | 0),
        stop$1 + 1 | 0
      ];
    }
    function add_substitute(b, f, s) {
      const lim = s.length;
      let _previous = (
        /* ' ' */
        32
      );
      let _i = 0;
      while (true) {
        const i = _i;
        const previous = _previous;
        if (i >= lim) {
          if (previous === /* '\\' */
          92) {
            return add_char(b, previous);
          } else {
            return;
          }
        }
        const current = Caml_string.get(s, i);
        if (current !== 36) {
          if (previous === /* '\\' */
          92) {
            add_char(b, previous);
          }
          if (current !== /* '\\' */
          92) {
            add_char(b, current);
          }
          _i = i + 1 | 0;
          _previous = current;
          continue;
        }
        if (previous === /* '\\' */
        92) {
          add_char(b, current);
          _i = i + 1 | 0;
          _previous = /* ' ' */
          32;
          continue;
        }
        const j = i + 1 | 0;
        let val;
        try {
          val = find_ident(s, j, lim);
        } catch (raw_exn) {
          const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
          if (exn.MEL_EXN_ID === Stdlib.Not_found) {
            add_char(
              b,
              /* '$' */
              36
            );
            _i = j;
            _previous = /* ' ' */
            32;
            continue;
          }
          throw exn;
        }
        add_string(b, Curry2._1(f, val[0]));
        _i = val[1];
        _previous = /* ' ' */
        32;
        continue;
      }
      ;
    }
    function truncate(b, len) {
      if (len < 0 || len > b.position) {
        throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
          MEL_EXN_ID: "Invalid_argument",
          _1: "Buffer.truncate"
        });
      }
      b.position = len;
    }
    function to_seq(b) {
      const aux = function(i, param) {
        if (i >= b.position) {
          return (
            /* Nil */
            0
          );
        }
        const x = Caml_bytes.get(b.inner.buffer, i);
        const partial_arg = i + 1 | 0;
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: x,
          _1: (function(param2) {
            return aux(partial_arg, param2);
          })
        };
      };
      return function(param) {
        return aux(0, param);
      };
    }
    function to_seqi(b) {
      const aux = function(i, param) {
        if (i >= b.position) {
          return (
            /* Nil */
            0
          );
        }
        const x = Caml_bytes.get(b.inner.buffer, i);
        const partial_arg = i + 1 | 0;
        return {
          TAG: (
            /* Cons */
            0
          ),
          _0: [
            i,
            x
          ],
          _1: (function(param2) {
            return aux(partial_arg, param2);
          })
        };
      };
      return function(param) {
        return aux(0, param);
      };
    }
    function add_seq(b, seq) {
      Stdlib__Seq.iter((function(param) {
        return add_char(b, param);
      }), seq);
    }
    function of_seq(i) {
      const b = create(32);
      Stdlib__Seq.iter((function(param) {
        return add_char(b, param);
      }), i);
      return b;
    }
    function add_int8(b, x) {
      const position = b.position;
      const match = b.inner;
      const new_position = position + 1 | 0;
      if (new_position > match.length) {
        resize(b, 1);
        Caml_bytes.set(b.inner.buffer, b.position, x);
      } else {
        match.buffer[position] = x;
      }
      b.position = new_position;
    }
    function add_int16_ne(b, x) {
      const position = b.position;
      const match = b.inner;
      const new_position = position + 2 | 0;
      if (new_position > match.length) {
        resize(b, 2);
        Caml_bytes.set16(b.inner.buffer, b.position, x);
      } else {
        Caml_bytes.set16u(match.buffer, position, x);
      }
      b.position = new_position;
    }
    function add_int32_ne(b, x) {
      const position = b.position;
      const match = b.inner;
      const new_position = position + 4 | 0;
      if (new_position > match.length) {
        resize(b, 4);
        Caml_bytes.set32(b.inner.buffer, b.position, x);
      } else {
        Caml_bytes.set32u(match.buffer, position, x);
      }
      b.position = new_position;
    }
    function add_int64_ne(b, x) {
      const position = b.position;
      const match = b.inner;
      const new_position = position + 8 | 0;
      if (new_position > match.length) {
        resize(b, 8);
        Caml_bytes.set64(b.inner.buffer, b.position, x);
      } else {
        Caml_bytes.set64u(match.buffer, position, x);
      }
      b.position = new_position;
    }
    function add_int16_le(b, x) {
      add_int16_ne(b, Stdlib__Sys.big_endian ? Caml_bytes.bswap16(x) : x);
    }
    function add_int16_be(b, x) {
      add_int16_ne(b, Stdlib__Sys.big_endian ? x : Caml_bytes.bswap16(x));
    }
    function add_int32_le(b, x) {
      add_int32_ne(b, Stdlib__Sys.big_endian ? Caml_bytes.bswap32(x) : x);
    }
    function add_int32_be(b, x) {
      add_int32_ne(b, Stdlib__Sys.big_endian ? x : Caml_bytes.bswap32(x));
    }
    function add_int64_le(b, x) {
      add_int64_ne(b, Stdlib__Sys.big_endian ? Caml_bytes.bswap64(x) : x);
    }
    function add_int64_be(b, x) {
      add_int64_ne(b, Stdlib__Sys.big_endian ? x : Caml_bytes.bswap64(x));
    }
    var add_uint8 = add_int8;
    var add_uint16_ne = add_int16_ne;
    var add_uint16_be = add_int16_be;
    var add_uint16_le = add_int16_le;
    module2.exports = {
      create,
      contents,
      to_bytes,
      sub,
      blit,
      nth,
      length,
      clear,
      reset,
      output_buffer,
      truncate,
      add_char,
      add_utf_8_uchar,
      add_utf_16le_uchar,
      add_utf_16be_uchar,
      add_string,
      add_bytes,
      add_substring,
      add_subbytes,
      add_substitute,
      add_buffer,
      add_channel,
      to_seq,
      to_seqi,
      add_seq,
      of_seq,
      add_uint8,
      add_int8,
      add_uint16_ne,
      add_uint16_be,
      add_uint16_le,
      add_int16_ne,
      add_int16_be,
      add_int16_le,
      add_int32_ne,
      add_int32_be,
      add_int32_le,
      add_int64_ne,
      add_int64_be,
      add_int64_le
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/camlinternalFormat.js
var require_camlinternalFormat = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/camlinternalFormat.js"(exports2, module2) {
    "use strict";
    var Caml_bytes = require_caml_bytes();
    var Caml_exceptions = require_caml_exceptions();
    var Caml_format = require_caml_format();
    var Caml_io = require_caml_io();
    var Caml_js_exceptions = require_caml_js_exceptions();
    var Caml_obj = require_caml_obj();
    var Caml_string = require_caml_string();
    var CamlinternalFormatBasics = require_camlinternalFormatBasics();
    var Curry2 = require_curry();
    var Stdlib = require_stdlib();
    var Stdlib__Buffer = require_buffer();
    var Stdlib__Bytes = require_bytes();
    var Stdlib__Char = require_char();
    var Stdlib__Int = require_int();
    var Stdlib__String2 = require_string();
    function create_char_set(param) {
      return Stdlib__Bytes.make(
        32,
        /* '\000' */
        0
      );
    }
    function add_in_char_set(char_set, c) {
      const str_ind = c >>> 3;
      const mask = 1 << (c & 7);
      Caml_bytes.set(char_set, str_ind, Stdlib.char_of_int(Caml_bytes.get(char_set, str_ind) | mask));
    }
    var freeze_char_set = Stdlib__Bytes.to_string;
    function rev_char_set(char_set) {
      const char_set$p = Stdlib__Bytes.make(
        32,
        /* '\000' */
        0
      );
      for (let i = 0; i <= 31; ++i) {
        Caml_bytes.set(char_set$p, i, Stdlib.char_of_int(Caml_string.get(char_set, i) ^ 255));
      }
      return Caml_bytes.bytes_to_string(char_set$p);
    }
    function is_in_char_set(char_set, c) {
      const str_ind = c >>> 3;
      const mask = 1 << (c & 7);
      return (Caml_string.get(char_set, str_ind) & mask) !== 0;
    }
    function pad_of_pad_opt(pad_opt) {
      if (pad_opt !== void 0) {
        return {
          TAG: (
            /* Lit_padding */
            0
          ),
          _0: (
            /* Right */
            1
          ),
          _1: pad_opt
        };
      } else {
        return (
          /* No_padding */
          0
        );
      }
    }
    function prec_of_prec_opt(prec_opt) {
      if (prec_opt !== void 0) {
        return {
          TAG: (
            /* Lit_precision */
            0
          ),
          _0: prec_opt
        };
      } else {
        return (
          /* No_precision */
          0
        );
      }
    }
    function param_format_of_ignored_format(ign, fmt) {
      if (
        /* tag */
        typeof ign === "number" || typeof ign === "string"
      ) {
        switch (ign) {
          case /* Ignored_char */
          0:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Char */
                  0
                ),
                _0: fmt
              }
            };
          case /* Ignored_caml_char */
          1:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Caml_char */
                  1
                ),
                _0: fmt
              }
            };
          case /* Ignored_reader */
          2:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Reader */
                  19
                ),
                _0: fmt
              }
            };
          case /* Ignored_scan_next_char */
          3:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Scan_next_char */
                  22
                ),
                _0: fmt
              }
            };
        }
      } else {
        switch (ign.TAG) {
          case /* Ignored_string */
          0:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* String */
                  2
                ),
                _0: pad_of_pad_opt(ign._0),
                _1: fmt
              }
            };
          case /* Ignored_caml_string */
          1:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Caml_string */
                  3
                ),
                _0: pad_of_pad_opt(ign._0),
                _1: fmt
              }
            };
          case /* Ignored_int */
          2:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Int */
                  4
                ),
                _0: ign._0,
                _1: pad_of_pad_opt(ign._1),
                _2: (
                  /* No_precision */
                  0
                ),
                _3: fmt
              }
            };
          case /* Ignored_int32 */
          3:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Int32 */
                  5
                ),
                _0: ign._0,
                _1: pad_of_pad_opt(ign._1),
                _2: (
                  /* No_precision */
                  0
                ),
                _3: fmt
              }
            };
          case /* Ignored_nativeint */
          4:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Nativeint */
                  6
                ),
                _0: ign._0,
                _1: pad_of_pad_opt(ign._1),
                _2: (
                  /* No_precision */
                  0
                ),
                _3: fmt
              }
            };
          case /* Ignored_int64 */
          5:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Int64 */
                  7
                ),
                _0: ign._0,
                _1: pad_of_pad_opt(ign._1),
                _2: (
                  /* No_precision */
                  0
                ),
                _3: fmt
              }
            };
          case /* Ignored_float */
          6:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Float */
                  8
                ),
                _0: [
                  /* Float_flag_ */
                  0,
                  /* Float_f */
                  0
                ],
                _1: pad_of_pad_opt(ign._0),
                _2: prec_of_prec_opt(ign._1),
                _3: fmt
              }
            };
          case /* Ignored_bool */
          7:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Bool */
                  9
                ),
                _0: pad_of_pad_opt(ign._0),
                _1: fmt
              }
            };
          case /* Ignored_format_arg */
          8:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Format_arg */
                  13
                ),
                _0: ign._0,
                _1: ign._1,
                _2: fmt
              }
            };
          case /* Ignored_format_subst */
          9:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Format_subst */
                  14
                ),
                _0: ign._0,
                _1: ign._1,
                _2: fmt
              }
            };
          case /* Ignored_scan_char_set */
          10:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Scan_char_set */
                  20
                ),
                _0: ign._0,
                _1: ign._1,
                _2: fmt
              }
            };
          case /* Ignored_scan_get_counter */
          11:
            return {
              TAG: (
                /* Param_format_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Scan_get_counter */
                  21
                ),
                _0: ign._0,
                _1: fmt
              }
            };
        }
      }
    }
    function default_float_precision(fconv) {
      const match = fconv[1];
      if (match === /* Float_F */
      5) {
        return 12;
      } else {
        return -6;
      }
    }
    function buffer_check_size(buf, overhead) {
      const len = buf.bytes.length;
      const min_len = buf.ind + overhead | 0;
      if (min_len <= len) {
        return;
      }
      const new_len = Stdlib__Int.max(len << 1, min_len);
      const new_str = Caml_bytes.caml_create_bytes(new_len);
      Stdlib__Bytes.blit(buf.bytes, 0, new_str, 0, len);
      buf.bytes = new_str;
    }
    function buffer_add_char(buf, c) {
      buffer_check_size(buf, 1);
      Caml_bytes.set(buf.bytes, buf.ind, c);
      buf.ind = buf.ind + 1 | 0;
    }
    function buffer_add_string(buf, s) {
      const str_len = s.length;
      buffer_check_size(buf, str_len);
      Stdlib__String2.blit(s, 0, buf.bytes, buf.ind, str_len);
      buf.ind = buf.ind + str_len | 0;
    }
    function buffer_contents(buf) {
      return Stdlib__Bytes.sub_string(buf.bytes, 0, buf.ind);
    }
    function char_of_iconv(iconv) {
      switch (iconv) {
        case /* Int_x */
        6:
        case /* Int_Cx */
        7:
          return (
            /* 'x' */
            120
          );
        case /* Int_X */
        8:
        case /* Int_CX */
        9:
          return (
            /* 'X' */
            88
          );
        case /* Int_o */
        10:
        case /* Int_Co */
        11:
          return (
            /* 'o' */
            111
          );
        case /* Int_i */
        3:
        case /* Int_pi */
        4:
        case /* Int_si */
        5:
        case /* Int_Ci */
        14:
          return (
            /* 'i' */
            105
          );
        case /* Int_u */
        12:
        case /* Int_Cu */
        15:
          return (
            /* 'u' */
            117
          );
        default:
          return (
            /* 'd' */
            100
          );
      }
    }
    function char_of_fconv(cFOpt, fconv) {
      const cF = cFOpt !== void 0 ? cFOpt : (
        /* 'F' */
        70
      );
      const match = fconv[1];
      switch (match) {
        case /* Float_f */
        0:
          return (
            /* 'f' */
            102
          );
        case /* Float_e */
        1:
          return (
            /* 'e' */
            101
          );
        case /* Float_E */
        2:
          return (
            /* 'E' */
            69
          );
        case /* Float_g */
        3:
          return (
            /* 'g' */
            103
          );
        case /* Float_G */
        4:
          return (
            /* 'G' */
            71
          );
        case /* Float_F */
        5:
          return cF;
        case /* Float_h */
        6:
          return (
            /* 'h' */
            104
          );
        case /* Float_H */
        7:
          return (
            /* 'H' */
            72
          );
        case /* Float_CF */
        8:
          return (
            /* 'F' */
            70
          );
      }
    }
    function char_of_counter(counter) {
      switch (counter) {
        case /* Line_counter */
        0:
          return (
            /* 'l' */
            108
          );
        case /* Char_counter */
        1:
          return (
            /* 'n' */
            110
          );
        case /* Token_counter */
        2:
          return (
            /* 'N' */
            78
          );
      }
    }
    function bprint_char_set(buf, char_set) {
      const print_char = function(buf2, i) {
        const c = Stdlib.char_of_int(i);
        if (c !== 37) {
          if (c !== 64) {
            return buffer_add_char(buf2, c);
          } else {
            buffer_add_char(
              buf2,
              /* '%' */
              37
            );
            return buffer_add_char(
              buf2,
              /* '@' */
              64
            );
          }
        } else {
          buffer_add_char(
            buf2,
            /* '%' */
            37
          );
          return buffer_add_char(
            buf2,
            /* '%' */
            37
          );
        }
      };
      const print_out = function(set, _i) {
        while (true) {
          const i = _i;
          if (i >= 256) {
            return;
          }
          if (is_in_char_set(set, Stdlib.char_of_int(i))) {
            const match = Stdlib.char_of_int(i);
            if (match > 93 || match < 45) {
              if (match >= 255) {
                return print_char(buf, 255);
              } else {
                return print_second(set, i + 1 | 0);
              }
            } else if (match > 92 || match < 46) {
              return print_out(set, i + 1 | 0);
            } else {
              return print_second(set, i + 1 | 0);
            }
          }
          _i = i + 1 | 0;
          continue;
        }
        ;
      };
      const print_second = function(set, i) {
        if (is_in_char_set(set, Stdlib.char_of_int(i))) {
          const match = Stdlib.char_of_int(i);
          if (match > 93 || match < 45) {
            if (match >= 255) {
              print_char(buf, 254);
              return print_char(buf, 255);
            }
          } else if ((match > 92 || match < 46) && !is_in_char_set(set, Stdlib.char_of_int(i + 1 | 0))) {
            print_char(buf, i - 1 | 0);
            return print_out(set, i + 1 | 0);
          }
          if (is_in_char_set(set, Stdlib.char_of_int(i + 1 | 0))) {
            let i$1 = i - 1 | 0;
            let _j = i + 2 | 0;
            while (true) {
              const j = _j;
              if (j === 256 || !is_in_char_set(set, Stdlib.char_of_int(j))) {
                print_char(buf, i$1);
                print_char(
                  buf,
                  /* '-' */
                  45
                );
                print_char(buf, j - 1 | 0);
                if (j < 256) {
                  return print_out(set, j + 1 | 0);
                } else {
                  return;
                }
              }
              _j = j + 1 | 0;
              continue;
            }
            ;
          } else {
            print_char(buf, i - 1 | 0);
            print_char(buf, i);
            return print_out(set, i + 2 | 0);
          }
        }
        print_char(buf, i - 1 | 0);
        print_out(set, i + 1 | 0);
      };
      const print_start = function(set) {
        const is_alone = function(c) {
          const before = Stdlib__Char.chr(c - 1 | 0);
          const after = Stdlib__Char.chr(c + 1 | 0);
          if (is_in_char_set(set, c)) {
            return !(is_in_char_set(set, before) && is_in_char_set(set, after));
          } else {
            return false;
          }
        };
        if (is_alone(
          /* ']' */
          93
        )) {
          buffer_add_char(
            buf,
            /* ']' */
            93
          );
        }
        print_out(set, 1);
        if (is_alone(
          /* '-' */
          45
        )) {
          return buffer_add_char(
            buf,
            /* '-' */
            45
          );
        }
      };
      buffer_add_char(
        buf,
        /* '[' */
        91
      );
      print_start(is_in_char_set(
        char_set,
        /* '\000' */
        0
      ) ? (buffer_add_char(
        buf,
        /* '^' */
        94
      ), rev_char_set(char_set)) : char_set);
      buffer_add_char(
        buf,
        /* ']' */
        93
      );
    }
    function bprint_padty(buf, padty) {
      switch (padty) {
        case /* Left */
        0:
          return buffer_add_char(
            buf,
            /* '-' */
            45
          );
        case /* Right */
        1:
          return;
        case /* Zeros */
        2:
          return buffer_add_char(
            buf,
            /* '0' */
            48
          );
      }
    }
    function bprint_ignored_flag(buf, ign_flag) {
      if (ign_flag) {
        return buffer_add_char(
          buf,
          /* '_' */
          95
        );
      }
    }
    function bprint_pad_opt(buf, pad_opt) {
      if (pad_opt !== void 0) {
        return buffer_add_string(buf, Caml_format.caml_format_int("%d", pad_opt));
      }
    }
    function bprint_padding(buf, pad) {
      if (
        /* tag */
        typeof pad === "number" || typeof pad === "string"
      ) {
        return;
      }
      if (pad.TAG === /* Lit_padding */
      0) {
        bprint_padty(buf, pad._0);
        return buffer_add_string(buf, Caml_format.caml_format_int("%d", pad._1));
      }
      bprint_padty(buf, pad._0);
      buffer_add_char(
        buf,
        /* '*' */
        42
      );
    }
    function bprint_precision(buf, prec) {
      if (
        /* tag */
        typeof prec === "number" || typeof prec === "string"
      ) {
        if (prec === /* No_precision */
        0) {
          return;
        } else {
          return buffer_add_string(buf, ".*");
        }
      }
      buffer_add_char(
        buf,
        /* '.' */
        46
      );
      buffer_add_string(buf, Caml_format.caml_format_int("%d", prec._0));
    }
    function bprint_iconv_flag(buf, iconv) {
      switch (iconv) {
        case /* Int_pd */
        1:
        case /* Int_pi */
        4:
          return buffer_add_char(
            buf,
            /* '+' */
            43
          );
        case /* Int_sd */
        2:
        case /* Int_si */
        5:
          return buffer_add_char(
            buf,
            /* ' ' */
            32
          );
        case /* Int_d */
        0:
        case /* Int_i */
        3:
        case /* Int_x */
        6:
        case /* Int_X */
        8:
        case /* Int_o */
        10:
        case /* Int_u */
        12:
          return;
        default:
          return buffer_add_char(
            buf,
            /* '#' */
            35
          );
      }
    }
    function bprint_int_fmt(buf, ign_flag, iconv, pad, prec) {
      buffer_add_char(
        buf,
        /* '%' */
        37
      );
      bprint_ignored_flag(buf, ign_flag);
      bprint_iconv_flag(buf, iconv);
      bprint_padding(buf, pad);
      bprint_precision(buf, prec);
      buffer_add_char(buf, char_of_iconv(iconv));
    }
    function bprint_altint_fmt(buf, ign_flag, iconv, pad, prec, c) {
      buffer_add_char(
        buf,
        /* '%' */
        37
      );
      bprint_ignored_flag(buf, ign_flag);
      bprint_iconv_flag(buf, iconv);
      bprint_padding(buf, pad);
      bprint_precision(buf, prec);
      buffer_add_char(buf, c);
      buffer_add_char(buf, char_of_iconv(iconv));
    }
    function bprint_fconv_flag(buf, fconv) {
      const match = fconv[0];
      switch (match) {
        case /* Float_flag_ */
        0:
          break;
        case /* Float_flag_p */
        1:
          buffer_add_char(
            buf,
            /* '+' */
            43
          );
          break;
        case /* Float_flag_s */
        2:
          buffer_add_char(
            buf,
            /* ' ' */
            32
          );
          break;
      }
      const match$1 = fconv[1];
      if (match$1 === /* Float_CF */
      8) {
        return buffer_add_char(
          buf,
          /* '#' */
          35
        );
      }
    }
    function bprint_float_fmt(buf, ign_flag, fconv, pad, prec) {
      buffer_add_char(
        buf,
        /* '%' */
        37
      );
      bprint_ignored_flag(buf, ign_flag);
      bprint_fconv_flag(buf, fconv);
      bprint_padding(buf, pad);
      bprint_precision(buf, prec);
      buffer_add_char(buf, char_of_fconv(void 0, fconv));
    }
    function string_of_formatting_lit(formatting_lit) {
      if (
        /* tag */
        typeof formatting_lit === "number" || typeof formatting_lit === "string"
      ) {
        switch (formatting_lit) {
          case /* Close_box */
          0:
            return "@]";
          case /* Close_tag */
          1:
            return "@}";
          case /* FFlush */
          2:
            return "@?";
          case /* Force_newline */
          3:
            return "@\n";
          case /* Flush_newline */
          4:
            return "@.";
          case /* Escaped_at */
          5:
            return "@@";
          case /* Escaped_percent */
          6:
            return "@%";
        }
      } else {
        switch (formatting_lit.TAG) {
          case /* Break */
          0:
          case /* Magic_size */
          1:
            return formatting_lit._0;
          case /* Scan_indic */
          2:
            return "@" + Caml_bytes.bytes_to_string(Stdlib__Bytes.make(1, formatting_lit._0));
        }
      }
    }
    function bprint_char_literal(buf, chr) {
      if (chr !== 37) {
        return buffer_add_char(buf, chr);
      } else {
        return buffer_add_string(buf, "%%");
      }
    }
    function bprint_string_literal(buf, str) {
      for (let i = 0, i_finish = str.length; i < i_finish; ++i) {
        bprint_char_literal(buf, Caml_string.get(str, i));
      }
    }
    function bprint_fmtty(buf, _fmtty) {
      while (true) {
        const fmtty = _fmtty;
        if (
          /* tag */
          typeof fmtty === "number" || typeof fmtty === "string"
        ) {
          return;
        }
        switch (fmtty.TAG) {
          case /* Char_ty */
          0:
            buffer_add_string(buf, "%c");
            _fmtty = fmtty._0;
            continue;
          case /* String_ty */
          1:
            buffer_add_string(buf, "%s");
            _fmtty = fmtty._0;
            continue;
          case /* Int_ty */
          2:
            buffer_add_string(buf, "%i");
            _fmtty = fmtty._0;
            continue;
          case /* Int32_ty */
          3:
            buffer_add_string(buf, "%li");
            _fmtty = fmtty._0;
            continue;
          case /* Nativeint_ty */
          4:
            buffer_add_string(buf, "%ni");
            _fmtty = fmtty._0;
            continue;
          case /* Int64_ty */
          5:
            buffer_add_string(buf, "%Li");
            _fmtty = fmtty._0;
            continue;
          case /* Float_ty */
          6:
            buffer_add_string(buf, "%f");
            _fmtty = fmtty._0;
            continue;
          case /* Bool_ty */
          7:
            buffer_add_string(buf, "%B");
            _fmtty = fmtty._0;
            continue;
          case /* Format_arg_ty */
          8:
            buffer_add_string(buf, "%{");
            bprint_fmtty(buf, fmtty._0);
            buffer_add_string(buf, "%}");
            _fmtty = fmtty._1;
            continue;
          case /* Format_subst_ty */
          9:
            buffer_add_string(buf, "%(");
            bprint_fmtty(buf, fmtty._0);
            buffer_add_string(buf, "%)");
            _fmtty = fmtty._2;
            continue;
          case /* Alpha_ty */
          10:
            buffer_add_string(buf, "%a");
            _fmtty = fmtty._0;
            continue;
          case /* Theta_ty */
          11:
            buffer_add_string(buf, "%t");
            _fmtty = fmtty._0;
            continue;
          case /* Any_ty */
          12:
            buffer_add_string(buf, "%?");
            _fmtty = fmtty._0;
            continue;
          case /* Reader_ty */
          13:
            buffer_add_string(buf, "%r");
            _fmtty = fmtty._0;
            continue;
          case /* Ignored_reader_ty */
          14:
            buffer_add_string(buf, "%_r");
            _fmtty = fmtty._0;
            continue;
        }
      }
      ;
    }
    function bprint_fmt(buf, fmt) {
      let _fmt = fmt;
      let _ign_flag = false;
      while (true) {
        const ign_flag = _ign_flag;
        const fmt$1 = _fmt;
        if (
          /* tag */
          typeof fmt$1 === "number" || typeof fmt$1 === "string"
        ) {
          return;
        }
        switch (fmt$1.TAG) {
          case /* Char */
          0:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            buffer_add_char(
              buf,
              /* 'c' */
              99
            );
            _ign_flag = false;
            _fmt = fmt$1._0;
            continue;
          case /* Caml_char */
          1:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            buffer_add_char(
              buf,
              /* 'C' */
              67
            );
            _ign_flag = false;
            _fmt = fmt$1._0;
            continue;
          case /* String */
          2:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            bprint_padding(buf, fmt$1._0);
            buffer_add_char(
              buf,
              /* 's' */
              115
            );
            _ign_flag = false;
            _fmt = fmt$1._1;
            continue;
          case /* Caml_string */
          3:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            bprint_padding(buf, fmt$1._0);
            buffer_add_char(
              buf,
              /* 'S' */
              83
            );
            _ign_flag = false;
            _fmt = fmt$1._1;
            continue;
          case /* Int */
          4:
            bprint_int_fmt(buf, ign_flag, fmt$1._0, fmt$1._1, fmt$1._2);
            _ign_flag = false;
            _fmt = fmt$1._3;
            continue;
          case /* Int32 */
          5:
            bprint_altint_fmt(
              buf,
              ign_flag,
              fmt$1._0,
              fmt$1._1,
              fmt$1._2,
              /* 'l' */
              108
            );
            _ign_flag = false;
            _fmt = fmt$1._3;
            continue;
          case /* Nativeint */
          6:
            bprint_altint_fmt(
              buf,
              ign_flag,
              fmt$1._0,
              fmt$1._1,
              fmt$1._2,
              /* 'n' */
              110
            );
            _ign_flag = false;
            _fmt = fmt$1._3;
            continue;
          case /* Int64 */
          7:
            bprint_altint_fmt(
              buf,
              ign_flag,
              fmt$1._0,
              fmt$1._1,
              fmt$1._2,
              /* 'L' */
              76
            );
            _ign_flag = false;
            _fmt = fmt$1._3;
            continue;
          case /* Float */
          8:
            bprint_float_fmt(buf, ign_flag, fmt$1._0, fmt$1._1, fmt$1._2);
            _ign_flag = false;
            _fmt = fmt$1._3;
            continue;
          case /* Bool */
          9:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            bprint_padding(buf, fmt$1._0);
            buffer_add_char(
              buf,
              /* 'B' */
              66
            );
            _ign_flag = false;
            _fmt = fmt$1._1;
            continue;
          case /* Flush */
          10:
            buffer_add_string(buf, "%!");
            _fmt = fmt$1._0;
            continue;
          case /* String_literal */
          11:
            bprint_string_literal(buf, fmt$1._0);
            _fmt = fmt$1._1;
            continue;
          case /* Char_literal */
          12:
            bprint_char_literal(buf, fmt$1._0);
            _fmt = fmt$1._1;
            continue;
          case /* Format_arg */
          13:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            bprint_pad_opt(buf, fmt$1._0);
            buffer_add_char(
              buf,
              /* '{' */
              123
            );
            bprint_fmtty(buf, fmt$1._1);
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            buffer_add_char(
              buf,
              /* '}' */
              125
            );
            _ign_flag = false;
            _fmt = fmt$1._2;
            continue;
          case /* Format_subst */
          14:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            bprint_pad_opt(buf, fmt$1._0);
            buffer_add_char(
              buf,
              /* '(' */
              40
            );
            bprint_fmtty(buf, fmt$1._1);
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            buffer_add_char(
              buf,
              /* ')' */
              41
            );
            _ign_flag = false;
            _fmt = fmt$1._2;
            continue;
          case /* Alpha */
          15:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            buffer_add_char(
              buf,
              /* 'a' */
              97
            );
            _ign_flag = false;
            _fmt = fmt$1._0;
            continue;
          case /* Theta */
          16:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            buffer_add_char(
              buf,
              /* 't' */
              116
            );
            _ign_flag = false;
            _fmt = fmt$1._0;
            continue;
          case /* Formatting_lit */
          17:
            bprint_string_literal(buf, string_of_formatting_lit(fmt$1._0));
            _fmt = fmt$1._1;
            continue;
          case /* Formatting_gen */
          18:
            const fmting_gen = fmt$1._0;
            if (fmting_gen.TAG === /* Open_tag */
            0) {
              buffer_add_string(buf, "@{");
              buffer_add_string(buf, fmting_gen._0._1);
            } else {
              buffer_add_string(buf, "@[");
              buffer_add_string(buf, fmting_gen._0._1);
            }
            _fmt = fmt$1._1;
            continue;
          case /* Reader */
          19:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            buffer_add_char(
              buf,
              /* 'r' */
              114
            );
            _ign_flag = false;
            _fmt = fmt$1._0;
            continue;
          case /* Scan_char_set */
          20:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            bprint_pad_opt(buf, fmt$1._0);
            bprint_char_set(buf, fmt$1._1);
            _ign_flag = false;
            _fmt = fmt$1._2;
            continue;
          case /* Scan_get_counter */
          21:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            buffer_add_char(buf, char_of_counter(fmt$1._0));
            _ign_flag = false;
            _fmt = fmt$1._1;
            continue;
          case /* Scan_next_char */
          22:
            buffer_add_char(
              buf,
              /* '%' */
              37
            );
            bprint_ignored_flag(buf, ign_flag);
            bprint_string_literal(buf, "0c");
            _ign_flag = false;
            _fmt = fmt$1._0;
            continue;
          case /* Ignored_param */
          23:
            const fmt$p = param_format_of_ignored_format(fmt$1._0, fmt$1._1);
            _ign_flag = true;
            _fmt = fmt$p._0;
            continue;
          case /* Custom */
          24:
            for (let _i = 1, _i_finish = int_of_custom_arity(fmt$1._0); _i <= _i_finish; ++_i) {
              buffer_add_char(
                buf,
                /* '%' */
                37
              );
              bprint_ignored_flag(buf, ign_flag);
              buffer_add_char(
                buf,
                /* '?' */
                63
              );
            }
            _ign_flag = false;
            _fmt = fmt$1._2;
            continue;
        }
      }
      ;
    }
    function string_of_fmt(fmt) {
      const buf = {
        ind: 0,
        bytes: Caml_bytes.caml_create_bytes(16)
      };
      bprint_fmt(buf, fmt);
      return buffer_contents(buf);
    }
    function symm(rest) {
      if (
        /* tag */
        typeof rest === "number" || typeof rest === "string"
      ) {
        return (
          /* End_of_fmtty */
          0
        );
      }
      switch (rest.TAG) {
        case /* Char_ty */
        0:
          return {
            TAG: (
              /* Char_ty */
              0
            ),
            _0: symm(rest._0)
          };
        case /* String_ty */
        1:
          return {
            TAG: (
              /* String_ty */
              1
            ),
            _0: symm(rest._0)
          };
        case /* Int_ty */
        2:
          return {
            TAG: (
              /* Int_ty */
              2
            ),
            _0: symm(rest._0)
          };
        case /* Int32_ty */
        3:
          return {
            TAG: (
              /* Int32_ty */
              3
            ),
            _0: symm(rest._0)
          };
        case /* Nativeint_ty */
        4:
          return {
            TAG: (
              /* Nativeint_ty */
              4
            ),
            _0: symm(rest._0)
          };
        case /* Int64_ty */
        5:
          return {
            TAG: (
              /* Int64_ty */
              5
            ),
            _0: symm(rest._0)
          };
        case /* Float_ty */
        6:
          return {
            TAG: (
              /* Float_ty */
              6
            ),
            _0: symm(rest._0)
          };
        case /* Bool_ty */
        7:
          return {
            TAG: (
              /* Bool_ty */
              7
            ),
            _0: symm(rest._0)
          };
        case /* Format_arg_ty */
        8:
          return {
            TAG: (
              /* Format_arg_ty */
              8
            ),
            _0: rest._0,
            _1: symm(rest._1)
          };
        case /* Format_subst_ty */
        9:
          return {
            TAG: (
              /* Format_subst_ty */
              9
            ),
            _0: rest._1,
            _1: rest._0,
            _2: symm(rest._2)
          };
        case /* Alpha_ty */
        10:
          return {
            TAG: (
              /* Alpha_ty */
              10
            ),
            _0: symm(rest._0)
          };
        case /* Theta_ty */
        11:
          return {
            TAG: (
              /* Theta_ty */
              11
            ),
            _0: symm(rest._0)
          };
        case /* Any_ty */
        12:
          return {
            TAG: (
              /* Any_ty */
              12
            ),
            _0: symm(rest._0)
          };
        case /* Reader_ty */
        13:
          return {
            TAG: (
              /* Reader_ty */
              13
            ),
            _0: symm(rest._0)
          };
        case /* Ignored_reader_ty */
        14:
          return {
            TAG: (
              /* Ignored_reader_ty */
              14
            ),
            _0: symm(rest._0)
          };
      }
    }
    function fmtty_rel_det(rest) {
      if (
        /* tag */
        typeof rest === "number" || typeof rest === "string"
      ) {
        return [
          (function(param) {
            return (
              /* Refl */
              0
            );
          }),
          (function(param) {
            return (
              /* Refl */
              0
            );
          }),
          (function(param) {
            return (
              /* Refl */
              0
            );
          }),
          (function(param) {
            return (
              /* Refl */
              0
            );
          })
        ];
      }
      switch (rest.TAG) {
        case /* Char_ty */
        0:
          const match = fmtty_rel_det(rest._0);
          const af = match[1];
          const fa = match[0];
          return [
            (function(param) {
              Curry2._1(
                fa,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match[2],
            match[3]
          ];
        case /* String_ty */
        1:
          const match$1 = fmtty_rel_det(rest._0);
          const af$1 = match$1[1];
          const fa$1 = match$1[0];
          return [
            (function(param) {
              Curry2._1(
                fa$1,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$1,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$1[2],
            match$1[3]
          ];
        case /* Int_ty */
        2:
          const match$2 = fmtty_rel_det(rest._0);
          const af$2 = match$2[1];
          const fa$2 = match$2[0];
          return [
            (function(param) {
              Curry2._1(
                fa$2,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$2,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$2[2],
            match$2[3]
          ];
        case /* Int32_ty */
        3:
          const match$3 = fmtty_rel_det(rest._0);
          const af$3 = match$3[1];
          const fa$3 = match$3[0];
          return [
            (function(param) {
              Curry2._1(
                fa$3,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$3,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$3[2],
            match$3[3]
          ];
        case /* Nativeint_ty */
        4:
          const match$4 = fmtty_rel_det(rest._0);
          const af$4 = match$4[1];
          const fa$4 = match$4[0];
          return [
            (function(param) {
              Curry2._1(
                fa$4,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$4,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$4[2],
            match$4[3]
          ];
        case /* Int64_ty */
        5:
          const match$5 = fmtty_rel_det(rest._0);
          const af$5 = match$5[1];
          const fa$5 = match$5[0];
          return [
            (function(param) {
              Curry2._1(
                fa$5,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$5,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$5[2],
            match$5[3]
          ];
        case /* Float_ty */
        6:
          const match$6 = fmtty_rel_det(rest._0);
          const af$6 = match$6[1];
          const fa$6 = match$6[0];
          return [
            (function(param) {
              Curry2._1(
                fa$6,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$6,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$6[2],
            match$6[3]
          ];
        case /* Bool_ty */
        7:
          const match$7 = fmtty_rel_det(rest._0);
          const af$7 = match$7[1];
          const fa$7 = match$7[0];
          return [
            (function(param) {
              Curry2._1(
                fa$7,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$7,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$7[2],
            match$7[3]
          ];
        case /* Format_arg_ty */
        8:
          const match$8 = fmtty_rel_det(rest._1);
          const af$8 = match$8[1];
          const fa$8 = match$8[0];
          return [
            (function(param) {
              Curry2._1(
                fa$8,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$8,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$8[2],
            match$8[3]
          ];
        case /* Format_subst_ty */
        9:
          const match$9 = fmtty_rel_det(rest._2);
          const de = match$9[3];
          const ed = match$9[2];
          const af$9 = match$9[1];
          const fa$9 = match$9[0];
          const ty = trans(symm(rest._0), rest._1);
          const match$10 = fmtty_rel_det(ty);
          const jd = match$10[3];
          const dj = match$10[2];
          const ga = match$10[1];
          const ag = match$10[0];
          return [
            (function(param) {
              Curry2._1(
                fa$9,
                /* Refl */
                0
              );
              Curry2._1(
                ag,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                ga,
                /* Refl */
                0
              );
              Curry2._1(
                af$9,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                ed,
                /* Refl */
                0
              );
              Curry2._1(
                dj,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                jd,
                /* Refl */
                0
              );
              Curry2._1(
                de,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            })
          ];
        case /* Alpha_ty */
        10:
          const match$11 = fmtty_rel_det(rest._0);
          const af$10 = match$11[1];
          const fa$10 = match$11[0];
          return [
            (function(param) {
              Curry2._1(
                fa$10,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$10,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$11[2],
            match$11[3]
          ];
        case /* Theta_ty */
        11:
          const match$12 = fmtty_rel_det(rest._0);
          const af$11 = match$12[1];
          const fa$11 = match$12[0];
          return [
            (function(param) {
              Curry2._1(
                fa$11,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$11,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$12[2],
            match$12[3]
          ];
        case /* Any_ty */
        12:
          const match$13 = fmtty_rel_det(rest._0);
          const af$12 = match$13[1];
          const fa$12 = match$13[0];
          return [
            (function(param) {
              Curry2._1(
                fa$12,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$12,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            match$13[2],
            match$13[3]
          ];
        case /* Reader_ty */
        13:
          const match$14 = fmtty_rel_det(rest._0);
          const de$1 = match$14[3];
          const ed$1 = match$14[2];
          const af$13 = match$14[1];
          const fa$13 = match$14[0];
          return [
            (function(param) {
              Curry2._1(
                fa$13,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$13,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                ed$1,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                de$1,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            })
          ];
        case /* Ignored_reader_ty */
        14:
          const match$15 = fmtty_rel_det(rest._0);
          const de$2 = match$15[3];
          const ed$2 = match$15[2];
          const af$14 = match$15[1];
          const fa$14 = match$15[0];
          return [
            (function(param) {
              Curry2._1(
                fa$14,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                af$14,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                ed$2,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            }),
            (function(param) {
              Curry2._1(
                de$2,
                /* Refl */
                0
              );
              return (
                /* Refl */
                0
              );
            })
          ];
      }
    }
    function trans(ty1, ty2) {
      let exit = 0;
      if (
        /* tag */
        typeof ty1 === "number" || typeof ty1 === "string"
      ) {
        if (
          /* tag */
          typeof ty2 === "number" || typeof ty2 === "string"
        ) {
          return (
            /* End_of_fmtty */
            0
          );
        }
        switch (ty2.TAG) {
          case /* Format_arg_ty */
          8:
            exit = 6;
            break;
          case /* Format_subst_ty */
          9:
            exit = 7;
            break;
          case /* Alpha_ty */
          10:
            exit = 1;
            break;
          case /* Theta_ty */
          11:
            exit = 2;
            break;
          case /* Any_ty */
          12:
            exit = 3;
            break;
          case /* Reader_ty */
          13:
            exit = 4;
            break;
          case /* Ignored_reader_ty */
          14:
            exit = 5;
            break;
          default:
            throw new Caml_js_exceptions.MelangeError("Assert_failure", {
              MEL_EXN_ID: "Assert_failure",
              _1: [
                "camlinternalFormat.cppo.ml",
                850,
                23
              ]
            });
        }
      } else {
        switch (ty1.TAG) {
          case /* Char_ty */
          0:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              exit = 8;
            } else {
              switch (ty2.TAG) {
                case /* Char_ty */
                0:
                  return {
                    TAG: (
                      /* Char_ty */
                      0
                    ),
                    _0: trans(ty1._0, ty2._0)
                  };
                case /* Format_arg_ty */
                8:
                  exit = 6;
                  break;
                case /* Format_subst_ty */
                9:
                  exit = 7;
                  break;
                case /* Alpha_ty */
                10:
                  exit = 1;
                  break;
                case /* Theta_ty */
                11:
                  exit = 2;
                  break;
                case /* Any_ty */
                12:
                  exit = 3;
                  break;
                case /* Reader_ty */
                13:
                  exit = 4;
                  break;
                case /* Ignored_reader_ty */
                14:
                  exit = 5;
                  break;
              }
            }
            break;
          case /* String_ty */
          1:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              exit = 8;
            } else {
              switch (ty2.TAG) {
                case /* String_ty */
                1:
                  return {
                    TAG: (
                      /* String_ty */
                      1
                    ),
                    _0: trans(ty1._0, ty2._0)
                  };
                case /* Format_arg_ty */
                8:
                  exit = 6;
                  break;
                case /* Format_subst_ty */
                9:
                  exit = 7;
                  break;
                case /* Alpha_ty */
                10:
                  exit = 1;
                  break;
                case /* Theta_ty */
                11:
                  exit = 2;
                  break;
                case /* Any_ty */
                12:
                  exit = 3;
                  break;
                case /* Reader_ty */
                13:
                  exit = 4;
                  break;
                case /* Ignored_reader_ty */
                14:
                  exit = 5;
                  break;
              }
            }
            break;
          case /* Int_ty */
          2:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              exit = 8;
            } else {
              switch (ty2.TAG) {
                case /* Int_ty */
                2:
                  return {
                    TAG: (
                      /* Int_ty */
                      2
                    ),
                    _0: trans(ty1._0, ty2._0)
                  };
                case /* Format_arg_ty */
                8:
                  exit = 6;
                  break;
                case /* Format_subst_ty */
                9:
                  exit = 7;
                  break;
                case /* Alpha_ty */
                10:
                  exit = 1;
                  break;
                case /* Theta_ty */
                11:
                  exit = 2;
                  break;
                case /* Any_ty */
                12:
                  exit = 3;
                  break;
                case /* Reader_ty */
                13:
                  exit = 4;
                  break;
                case /* Ignored_reader_ty */
                14:
                  exit = 5;
                  break;
              }
            }
            break;
          case /* Int32_ty */
          3:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              exit = 8;
            } else {
              switch (ty2.TAG) {
                case /* Int32_ty */
                3:
                  return {
                    TAG: (
                      /* Int32_ty */
                      3
                    ),
                    _0: trans(ty1._0, ty2._0)
                  };
                case /* Format_arg_ty */
                8:
                  exit = 6;
                  break;
                case /* Format_subst_ty */
                9:
                  exit = 7;
                  break;
                case /* Alpha_ty */
                10:
                  exit = 1;
                  break;
                case /* Theta_ty */
                11:
                  exit = 2;
                  break;
                case /* Any_ty */
                12:
                  exit = 3;
                  break;
                case /* Reader_ty */
                13:
                  exit = 4;
                  break;
                case /* Ignored_reader_ty */
                14:
                  exit = 5;
                  break;
              }
            }
            break;
          case /* Nativeint_ty */
          4:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              exit = 8;
            } else {
              switch (ty2.TAG) {
                case /* Nativeint_ty */
                4:
                  return {
                    TAG: (
                      /* Nativeint_ty */
                      4
                    ),
                    _0: trans(ty1._0, ty2._0)
                  };
                case /* Format_arg_ty */
                8:
                  exit = 6;
                  break;
                case /* Format_subst_ty */
                9:
                  exit = 7;
                  break;
                case /* Alpha_ty */
                10:
                  exit = 1;
                  break;
                case /* Theta_ty */
                11:
                  exit = 2;
                  break;
                case /* Any_ty */
                12:
                  exit = 3;
                  break;
                case /* Reader_ty */
                13:
                  exit = 4;
                  break;
                case /* Ignored_reader_ty */
                14:
                  exit = 5;
                  break;
              }
            }
            break;
          case /* Int64_ty */
          5:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              exit = 8;
            } else {
              switch (ty2.TAG) {
                case /* Int64_ty */
                5:
                  return {
                    TAG: (
                      /* Int64_ty */
                      5
                    ),
                    _0: trans(ty1._0, ty2._0)
                  };
                case /* Format_arg_ty */
                8:
                  exit = 6;
                  break;
                case /* Format_subst_ty */
                9:
                  exit = 7;
                  break;
                case /* Alpha_ty */
                10:
                  exit = 1;
                  break;
                case /* Theta_ty */
                11:
                  exit = 2;
                  break;
                case /* Any_ty */
                12:
                  exit = 3;
                  break;
                case /* Reader_ty */
                13:
                  exit = 4;
                  break;
                case /* Ignored_reader_ty */
                14:
                  exit = 5;
                  break;
              }
            }
            break;
          case /* Float_ty */
          6:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              exit = 8;
            } else {
              switch (ty2.TAG) {
                case /* Float_ty */
                6:
                  return {
                    TAG: (
                      /* Float_ty */
                      6
                    ),
                    _0: trans(ty1._0, ty2._0)
                  };
                case /* Format_arg_ty */
                8:
                  exit = 6;
                  break;
                case /* Format_subst_ty */
                9:
                  exit = 7;
                  break;
                case /* Alpha_ty */
                10:
                  exit = 1;
                  break;
                case /* Theta_ty */
                11:
                  exit = 2;
                  break;
                case /* Any_ty */
                12:
                  exit = 3;
                  break;
                case /* Reader_ty */
                13:
                  exit = 4;
                  break;
                case /* Ignored_reader_ty */
                14:
                  exit = 5;
                  break;
              }
            }
            break;
          case /* Bool_ty */
          7:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              exit = 8;
            } else {
              switch (ty2.TAG) {
                case /* Bool_ty */
                7:
                  return {
                    TAG: (
                      /* Bool_ty */
                      7
                    ),
                    _0: trans(ty1._0, ty2._0)
                  };
                case /* Format_arg_ty */
                8:
                  exit = 6;
                  break;
                case /* Format_subst_ty */
                9:
                  exit = 7;
                  break;
                case /* Alpha_ty */
                10:
                  exit = 1;
                  break;
                case /* Theta_ty */
                11:
                  exit = 2;
                  break;
                case /* Any_ty */
                12:
                  exit = 3;
                  break;
                case /* Reader_ty */
                13:
                  exit = 4;
                  break;
                case /* Ignored_reader_ty */
                14:
                  exit = 5;
                  break;
              }
            }
            break;
          case /* Format_arg_ty */
          8:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                MEL_EXN_ID: "Assert_failure",
                _1: [
                  "camlinternalFormat.cppo.ml",
                  836,
                  26
                ]
              });
            }
            switch (ty2.TAG) {
              case /* Format_arg_ty */
              8:
                return {
                  TAG: (
                    /* Format_arg_ty */
                    8
                  ),
                  _0: trans(ty1._0, ty2._0),
                  _1: trans(ty1._1, ty2._1)
                };
              case /* Alpha_ty */
              10:
                exit = 1;
                break;
              case /* Theta_ty */
              11:
                exit = 2;
                break;
              case /* Any_ty */
              12:
                exit = 3;
                break;
              case /* Reader_ty */
              13:
                exit = 4;
                break;
              case /* Ignored_reader_ty */
              14:
                exit = 5;
                break;
              default:
                throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                  MEL_EXN_ID: "Assert_failure",
                  _1: [
                    "camlinternalFormat.cppo.ml",
                    836,
                    26
                  ]
                });
            }
            break;
          case /* Format_subst_ty */
          9:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                MEL_EXN_ID: "Assert_failure",
                _1: [
                  "camlinternalFormat.cppo.ml",
                  846,
                  28
                ]
              });
            }
            switch (ty2.TAG) {
              case /* Format_arg_ty */
              8:
                exit = 6;
                break;
              case /* Format_subst_ty */
              9:
                const ty = trans(symm(ty1._1), ty2._0);
                const match = fmtty_rel_det(ty);
                Curry2._1(
                  match[1],
                  /* Refl */
                  0
                );
                Curry2._1(
                  match[3],
                  /* Refl */
                  0
                );
                return {
                  TAG: (
                    /* Format_subst_ty */
                    9
                  ),
                  _0: ty1._0,
                  _1: ty2._1,
                  _2: trans(ty1._2, ty2._2)
                };
              case /* Alpha_ty */
              10:
                exit = 1;
                break;
              case /* Theta_ty */
              11:
                exit = 2;
                break;
              case /* Any_ty */
              12:
                exit = 3;
                break;
              case /* Reader_ty */
              13:
                exit = 4;
                break;
              case /* Ignored_reader_ty */
              14:
                exit = 5;
                break;
              default:
                throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                  MEL_EXN_ID: "Assert_failure",
                  _1: [
                    "camlinternalFormat.cppo.ml",
                    846,
                    28
                  ]
                });
            }
            break;
          case /* Alpha_ty */
          10:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                MEL_EXN_ID: "Assert_failure",
                _1: [
                  "camlinternalFormat.cppo.ml",
                  814,
                  21
                ]
              });
            }
            if (ty2.TAG === /* Alpha_ty */
            10) {
              return {
                TAG: (
                  /* Alpha_ty */
                  10
                ),
                _0: trans(ty1._0, ty2._0)
              };
            }
            throw new Caml_js_exceptions.MelangeError("Assert_failure", {
              MEL_EXN_ID: "Assert_failure",
              _1: [
                "camlinternalFormat.cppo.ml",
                814,
                21
              ]
            });
          case /* Theta_ty */
          11:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                MEL_EXN_ID: "Assert_failure",
                _1: [
                  "camlinternalFormat.cppo.ml",
                  818,
                  21
                ]
              });
            }
            switch (ty2.TAG) {
              case /* Alpha_ty */
              10:
                exit = 1;
                break;
              case /* Theta_ty */
              11:
                return {
                  TAG: (
                    /* Theta_ty */
                    11
                  ),
                  _0: trans(ty1._0, ty2._0)
                };
              default:
                throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                  MEL_EXN_ID: "Assert_failure",
                  _1: [
                    "camlinternalFormat.cppo.ml",
                    818,
                    21
                  ]
                });
            }
            break;
          case /* Any_ty */
          12:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                MEL_EXN_ID: "Assert_failure",
                _1: [
                  "camlinternalFormat.cppo.ml",
                  822,
                  19
                ]
              });
            }
            switch (ty2.TAG) {
              case /* Alpha_ty */
              10:
                exit = 1;
                break;
              case /* Theta_ty */
              11:
                exit = 2;
                break;
              case /* Any_ty */
              12:
                return {
                  TAG: (
                    /* Any_ty */
                    12
                  ),
                  _0: trans(ty1._0, ty2._0)
                };
              default:
                throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                  MEL_EXN_ID: "Assert_failure",
                  _1: [
                    "camlinternalFormat.cppo.ml",
                    822,
                    19
                  ]
                });
            }
            break;
          case /* Reader_ty */
          13:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                MEL_EXN_ID: "Assert_failure",
                _1: [
                  "camlinternalFormat.cppo.ml",
                  826,
                  22
                ]
              });
            }
            switch (ty2.TAG) {
              case /* Alpha_ty */
              10:
                exit = 1;
                break;
              case /* Theta_ty */
              11:
                exit = 2;
                break;
              case /* Any_ty */
              12:
                exit = 3;
                break;
              case /* Reader_ty */
              13:
                return {
                  TAG: (
                    /* Reader_ty */
                    13
                  ),
                  _0: trans(ty1._0, ty2._0)
                };
              default:
                throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                  MEL_EXN_ID: "Assert_failure",
                  _1: [
                    "camlinternalFormat.cppo.ml",
                    826,
                    22
                  ]
                });
            }
            break;
          case /* Ignored_reader_ty */
          14:
            if (
              /* tag */
              typeof ty2 === "number" || typeof ty2 === "string"
            ) {
              throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                MEL_EXN_ID: "Assert_failure",
                _1: [
                  "camlinternalFormat.cppo.ml",
                  831,
                  30
                ]
              });
            }
            switch (ty2.TAG) {
              case /* Alpha_ty */
              10:
                exit = 1;
                break;
              case /* Theta_ty */
              11:
                exit = 2;
                break;
              case /* Any_ty */
              12:
                exit = 3;
                break;
              case /* Reader_ty */
              13:
                exit = 4;
                break;
              case /* Ignored_reader_ty */
              14:
                return {
                  TAG: (
                    /* Ignored_reader_ty */
                    14
                  ),
                  _0: trans(ty1._0, ty2._0)
                };
              default:
                throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                  MEL_EXN_ID: "Assert_failure",
                  _1: [
                    "camlinternalFormat.cppo.ml",
                    831,
                    30
                  ]
                });
            }
            break;
        }
      }
      switch (exit) {
        case 1:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              815,
              21
            ]
          });
        case 2:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              819,
              21
            ]
          });
        case 3:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              823,
              19
            ]
          });
        case 4:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              827,
              22
            ]
          });
        case 5:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              832,
              30
            ]
          });
        case 6:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              837,
              26
            ]
          });
        case 7:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              847,
              28
            ]
          });
        case 8:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              851,
              23
            ]
          });
      }
    }
    function fmtty_of_formatting_gen(formatting_gen) {
      return fmtty_of_fmt(formatting_gen._0._0);
    }
    function fmtty_of_fmt(_fmtty) {
      while (true) {
        const fmtty = _fmtty;
        if (
          /* tag */
          typeof fmtty === "number" || typeof fmtty === "string"
        ) {
          return (
            /* End_of_fmtty */
            0
          );
        }
        switch (fmtty.TAG) {
          case /* String */
          2:
          case /* Caml_string */
          3:
            break;
          case /* Int */
          4:
            const ty_rest = fmtty_of_fmt(fmtty._3);
            const prec_ty = fmtty_of_precision_fmtty(fmtty._2, {
              TAG: (
                /* Int_ty */
                2
              ),
              _0: ty_rest
            });
            return fmtty_of_padding_fmtty(fmtty._1, prec_ty);
          case /* Int32 */
          5:
            const ty_rest$1 = fmtty_of_fmt(fmtty._3);
            const prec_ty$1 = fmtty_of_precision_fmtty(fmtty._2, {
              TAG: (
                /* Int32_ty */
                3
              ),
              _0: ty_rest$1
            });
            return fmtty_of_padding_fmtty(fmtty._1, prec_ty$1);
          case /* Nativeint */
          6:
            const ty_rest$2 = fmtty_of_fmt(fmtty._3);
            const prec_ty$2 = fmtty_of_precision_fmtty(fmtty._2, {
              TAG: (
                /* Nativeint_ty */
                4
              ),
              _0: ty_rest$2
            });
            return fmtty_of_padding_fmtty(fmtty._1, prec_ty$2);
          case /* Int64 */
          7:
            const ty_rest$3 = fmtty_of_fmt(fmtty._3);
            const prec_ty$3 = fmtty_of_precision_fmtty(fmtty._2, {
              TAG: (
                /* Int64_ty */
                5
              ),
              _0: ty_rest$3
            });
            return fmtty_of_padding_fmtty(fmtty._1, prec_ty$3);
          case /* Float */
          8:
            const ty_rest$4 = fmtty_of_fmt(fmtty._3);
            const prec_ty$4 = fmtty_of_precision_fmtty(fmtty._2, {
              TAG: (
                /* Float_ty */
                6
              ),
              _0: ty_rest$4
            });
            return fmtty_of_padding_fmtty(fmtty._1, prec_ty$4);
          case /* Bool */
          9:
            return fmtty_of_padding_fmtty(fmtty._0, {
              TAG: (
                /* Bool_ty */
                7
              ),
              _0: fmtty_of_fmt(fmtty._1)
            });
          case /* Flush */
          10:
            _fmtty = fmtty._0;
            continue;
          case /* Format_arg */
          13:
            return {
              TAG: (
                /* Format_arg_ty */
                8
              ),
              _0: fmtty._1,
              _1: fmtty_of_fmt(fmtty._2)
            };
          case /* Format_subst */
          14:
            const ty = fmtty._1;
            return {
              TAG: (
                /* Format_subst_ty */
                9
              ),
              _0: ty,
              _1: ty,
              _2: fmtty_of_fmt(fmtty._2)
            };
          case /* Alpha */
          15:
            return {
              TAG: (
                /* Alpha_ty */
                10
              ),
              _0: fmtty_of_fmt(fmtty._0)
            };
          case /* Theta */
          16:
            return {
              TAG: (
                /* Theta_ty */
                11
              ),
              _0: fmtty_of_fmt(fmtty._0)
            };
          case /* Formatting_gen */
          18:
            return CamlinternalFormatBasics.concat_fmtty(fmtty_of_formatting_gen(fmtty._0), fmtty_of_fmt(fmtty._1));
          case /* Reader */
          19:
            return {
              TAG: (
                /* Reader_ty */
                13
              ),
              _0: fmtty_of_fmt(fmtty._0)
            };
          case /* Scan_char_set */
          20:
            return {
              TAG: (
                /* String_ty */
                1
              ),
              _0: fmtty_of_fmt(fmtty._2)
            };
          case /* Scan_get_counter */
          21:
            return {
              TAG: (
                /* Int_ty */
                2
              ),
              _0: fmtty_of_fmt(fmtty._1)
            };
          case /* Char */
          0:
          case /* Caml_char */
          1:
          case /* Scan_next_char */
          22:
            return {
              TAG: (
                /* Char_ty */
                0
              ),
              _0: fmtty_of_fmt(fmtty._0)
            };
          case /* Ignored_param */
          23:
            let ign = fmtty._0;
            let fmt = fmtty._1;
            if (
              /* tag */
              typeof ign === "number" || typeof ign === "string"
            ) {
              if (ign === /* Ignored_reader */
              2) {
                return {
                  TAG: (
                    /* Ignored_reader_ty */
                    14
                  ),
                  _0: fmtty_of_fmt(fmt)
                };
              } else {
                return fmtty_of_fmt(fmt);
              }
            } else if (ign.TAG === /* Ignored_format_subst */
            9) {
              return CamlinternalFormatBasics.concat_fmtty(ign._1, fmtty_of_fmt(fmt));
            } else {
              return fmtty_of_fmt(fmt);
            }
          case /* Custom */
          24:
            return fmtty_of_custom(fmtty._0, fmtty_of_fmt(fmtty._2));
          default:
            _fmtty = fmtty._1;
            continue;
        }
        return fmtty_of_padding_fmtty(fmtty._0, {
          TAG: (
            /* String_ty */
            1
          ),
          _0: fmtty_of_fmt(fmtty._1)
        });
      }
      ;
    }
    function fmtty_of_custom(arity, fmtty) {
      if (
        /* tag */
        typeof arity === "number" || typeof arity === "string"
      ) {
        return fmtty;
      } else {
        return {
          TAG: (
            /* Any_ty */
            12
          ),
          _0: fmtty_of_custom(arity._0, fmtty)
        };
      }
    }
    function fmtty_of_padding_fmtty(pad, fmtty) {
      if (
        /* tag */
        typeof pad === "number" || typeof pad === "string" || pad.TAG === /* Lit_padding */
        0
      ) {
        return fmtty;
      } else {
        return {
          TAG: (
            /* Int_ty */
            2
          ),
          _0: fmtty
        };
      }
    }
    function fmtty_of_precision_fmtty(prec, fmtty) {
      if (
        /* tag */
        (typeof prec === "number" || typeof prec === "string") && prec !== /* No_precision */
        0
      ) {
        return {
          TAG: (
            /* Int_ty */
            2
          ),
          _0: fmtty
        };
      } else {
        return fmtty;
      }
    }
    var Type_mismatch = /* @__PURE__ */ Caml_exceptions.create("CamlinternalFormat.Type_mismatch");
    function type_padding(pad, fmtty) {
      if (
        /* tag */
        typeof pad === "number" || typeof pad === "string"
      ) {
        return {
          TAG: (
            /* Padding_fmtty_EBB */
            0
          ),
          _0: (
            /* No_padding */
            0
          ),
          _1: fmtty
        };
      }
      if (pad.TAG === /* Lit_padding */
      0) {
        return {
          TAG: (
            /* Padding_fmtty_EBB */
            0
          ),
          _0: {
            TAG: (
              /* Lit_padding */
              0
            ),
            _0: pad._0,
            _1: pad._1
          },
          _1: fmtty
        };
      }
      if (
        /* tag */
        typeof fmtty === "number" || typeof fmtty === "string"
      ) {
        throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
          MEL_EXN_ID: Type_mismatch
        });
      }
      if (fmtty.TAG === /* Int_ty */
      2) {
        return {
          TAG: (
            /* Padding_fmtty_EBB */
            0
          ),
          _0: {
            TAG: (
              /* Arg_padding */
              1
            ),
            _0: pad._0
          },
          _1: fmtty._0
        };
      }
      throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
        MEL_EXN_ID: Type_mismatch
      });
    }
    function type_padprec(pad, prec, fmtty) {
      const match = type_padding(pad, fmtty);
      if (!/* tag */
      (typeof prec === "number" || typeof prec === "string")) {
        return {
          TAG: (
            /* Padprec_fmtty_EBB */
            0
          ),
          _0: match._0,
          _1: {
            TAG: (
              /* Lit_precision */
              0
            ),
            _0: prec._0
          },
          _2: match._1
        };
      }
      if (prec === /* No_precision */
      0) {
        return {
          TAG: (
            /* Padprec_fmtty_EBB */
            0
          ),
          _0: match._0,
          _1: (
            /* No_precision */
            0
          ),
          _2: match._1
        };
      }
      const rest = match._1;
      if (
        /* tag */
        typeof rest === "number" || typeof rest === "string"
      ) {
        throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
          MEL_EXN_ID: Type_mismatch
        });
      }
      if (rest.TAG === /* Int_ty */
      2) {
        return {
          TAG: (
            /* Padprec_fmtty_EBB */
            0
          ),
          _0: match._0,
          _1: (
            /* Arg_precision */
            1
          ),
          _2: rest._0
        };
      }
      throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
        MEL_EXN_ID: Type_mismatch
      });
    }
    function type_format_gen(fmt, fmtty) {
      if (
        /* tag */
        typeof fmt === "number" || typeof fmt === "string"
      ) {
        return {
          TAG: (
            /* Fmt_fmtty_EBB */
            0
          ),
          _0: (
            /* End_of_format */
            0
          ),
          _1: fmtty
        };
      }
      switch (fmt.TAG) {
        case /* Char */
        0:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Char_ty */
          0) {
            const match = type_format_gen(fmt._0, fmtty._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Char */
                  0
                ),
                _0: match._0
              },
              _1: match._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Caml_char */
        1:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Char_ty */
          0) {
            const match$1 = type_format_gen(fmt._0, fmtty._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Caml_char */
                  1
                ),
                _0: match$1._0
              },
              _1: match$1._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* String */
        2:
          const match$2 = type_padding(fmt._0, fmtty);
          const fmtty_rest = match$2._1;
          if (
            /* tag */
            typeof fmtty_rest === "number" || typeof fmtty_rest === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty_rest.TAG === /* String_ty */
          1) {
            const match$3 = type_format_gen(fmt._1, fmtty_rest._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* String */
                  2
                ),
                _0: match$2._0,
                _1: match$3._0
              },
              _1: match$3._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Caml_string */
        3:
          const match$4 = type_padding(fmt._0, fmtty);
          const fmtty_rest$1 = match$4._1;
          if (
            /* tag */
            typeof fmtty_rest$1 === "number" || typeof fmtty_rest$1 === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty_rest$1.TAG === /* String_ty */
          1) {
            const match$5 = type_format_gen(fmt._1, fmtty_rest$1._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Caml_string */
                  3
                ),
                _0: match$4._0,
                _1: match$5._0
              },
              _1: match$5._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Int */
        4:
          const match$6 = type_padprec(fmt._1, fmt._2, fmtty);
          const fmtty_rest$2 = match$6._2;
          if (
            /* tag */
            typeof fmtty_rest$2 === "number" || typeof fmtty_rest$2 === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty_rest$2.TAG === /* Int_ty */
          2) {
            const match$7 = type_format_gen(fmt._3, fmtty_rest$2._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Int */
                  4
                ),
                _0: fmt._0,
                _1: match$6._0,
                _2: match$6._1,
                _3: match$7._0
              },
              _1: match$7._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Int32 */
        5:
          const match$8 = type_padprec(fmt._1, fmt._2, fmtty);
          const fmtty_rest$3 = match$8._2;
          if (
            /* tag */
            typeof fmtty_rest$3 === "number" || typeof fmtty_rest$3 === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty_rest$3.TAG === /* Int32_ty */
          3) {
            const match$9 = type_format_gen(fmt._3, fmtty_rest$3._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Int32 */
                  5
                ),
                _0: fmt._0,
                _1: match$8._0,
                _2: match$8._1,
                _3: match$9._0
              },
              _1: match$9._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Nativeint */
        6:
          const match$10 = type_padprec(fmt._1, fmt._2, fmtty);
          const fmtty_rest$4 = match$10._2;
          if (
            /* tag */
            typeof fmtty_rest$4 === "number" || typeof fmtty_rest$4 === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty_rest$4.TAG === /* Nativeint_ty */
          4) {
            const match$11 = type_format_gen(fmt._3, fmtty_rest$4._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Nativeint */
                  6
                ),
                _0: fmt._0,
                _1: match$10._0,
                _2: match$10._1,
                _3: match$11._0
              },
              _1: match$11._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Int64 */
        7:
          const match$12 = type_padprec(fmt._1, fmt._2, fmtty);
          const fmtty_rest$5 = match$12._2;
          if (
            /* tag */
            typeof fmtty_rest$5 === "number" || typeof fmtty_rest$5 === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty_rest$5.TAG === /* Int64_ty */
          5) {
            const match$13 = type_format_gen(fmt._3, fmtty_rest$5._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Int64 */
                  7
                ),
                _0: fmt._0,
                _1: match$12._0,
                _2: match$12._1,
                _3: match$13._0
              },
              _1: match$13._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Float */
        8:
          const match$14 = type_padprec(fmt._1, fmt._2, fmtty);
          const fmtty_rest$6 = match$14._2;
          if (
            /* tag */
            typeof fmtty_rest$6 === "number" || typeof fmtty_rest$6 === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty_rest$6.TAG === /* Float_ty */
          6) {
            const match$15 = type_format_gen(fmt._3, fmtty_rest$6._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Float */
                  8
                ),
                _0: fmt._0,
                _1: match$14._0,
                _2: match$14._1,
                _3: match$15._0
              },
              _1: match$15._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Bool */
        9:
          const match$16 = type_padding(fmt._0, fmtty);
          const fmtty_rest$7 = match$16._1;
          if (
            /* tag */
            typeof fmtty_rest$7 === "number" || typeof fmtty_rest$7 === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty_rest$7.TAG === /* Bool_ty */
          7) {
            const match$17 = type_format_gen(fmt._1, fmtty_rest$7._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Bool */
                  9
                ),
                _0: match$16._0,
                _1: match$17._0
              },
              _1: match$17._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Flush */
        10:
          const match$18 = type_format_gen(fmt._0, fmtty);
          return {
            TAG: (
              /* Fmt_fmtty_EBB */
              0
            ),
            _0: {
              TAG: (
                /* Flush */
                10
              ),
              _0: match$18._0
            },
            _1: match$18._1
          };
        case /* String_literal */
        11:
          const match$19 = type_format_gen(fmt._1, fmtty);
          return {
            TAG: (
              /* Fmt_fmtty_EBB */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: fmt._0,
              _1: match$19._0
            },
            _1: match$19._1
          };
        case /* Char_literal */
        12:
          const match$20 = type_format_gen(fmt._1, fmtty);
          return {
            TAG: (
              /* Fmt_fmtty_EBB */
              0
            ),
            _0: {
              TAG: (
                /* Char_literal */
                12
              ),
              _0: fmt._0,
              _1: match$20._0
            },
            _1: match$20._1
          };
        case /* Format_arg */
        13:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Format_arg_ty */
          8) {
            const sub_fmtty$p = fmtty._0;
            if (Caml_obj.caml_notequal({
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: fmt._1
            }, {
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: sub_fmtty$p
            })) {
              throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
                MEL_EXN_ID: Type_mismatch
              });
            }
            const match$21 = type_format_gen(fmt._2, fmtty._1);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Format_arg */
                  13
                ),
                _0: fmt._0,
                _1: sub_fmtty$p,
                _2: match$21._0
              },
              _1: match$21._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Format_subst */
        14:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Format_subst_ty */
          9) {
            const sub_fmtty1 = fmtty._0;
            if (Caml_obj.caml_notequal({
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: CamlinternalFormatBasics.erase_rel(fmt._1)
            }, {
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: CamlinternalFormatBasics.erase_rel(sub_fmtty1)
            })) {
              throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
                MEL_EXN_ID: Type_mismatch
              });
            }
            const match$22 = type_format_gen(fmt._2, CamlinternalFormatBasics.erase_rel(fmtty._2));
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Format_subst */
                  14
                ),
                _0: fmt._0,
                _1: sub_fmtty1,
                _2: match$22._0
              },
              _1: match$22._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Alpha */
        15:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Alpha_ty */
          10) {
            const match$23 = type_format_gen(fmt._0, fmtty._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Alpha */
                  15
                ),
                _0: match$23._0
              },
              _1: match$23._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Theta */
        16:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Theta_ty */
          11) {
            const match$24 = type_format_gen(fmt._0, fmtty._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Theta */
                  16
                ),
                _0: match$24._0
              },
              _1: match$24._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Formatting_lit */
        17:
          const match$25 = type_format_gen(fmt._1, fmtty);
          return {
            TAG: (
              /* Fmt_fmtty_EBB */
              0
            ),
            _0: {
              TAG: (
                /* Formatting_lit */
                17
              ),
              _0: fmt._0,
              _1: match$25._0
            },
            _1: match$25._1
          };
        case /* Formatting_gen */
        18:
          let formatting_gen = fmt._0;
          let fmt0 = fmt._1;
          if (formatting_gen.TAG === /* Open_tag */
          0) {
            const match$26 = formatting_gen._0;
            const match$27 = type_format_gen(match$26._0, fmtty);
            const match$28 = type_format_gen(fmt0, match$27._1);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Formatting_gen */
                  18
                ),
                _0: {
                  TAG: (
                    /* Open_tag */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Format */
                      0
                    ),
                    _0: match$27._0,
                    _1: match$26._1
                  }
                },
                _1: match$28._0
              },
              _1: match$28._1
            };
          }
          const match$29 = formatting_gen._0;
          const match$30 = type_format_gen(match$29._0, fmtty);
          const match$31 = type_format_gen(fmt0, match$30._1);
          return {
            TAG: (
              /* Fmt_fmtty_EBB */
              0
            ),
            _0: {
              TAG: (
                /* Formatting_gen */
                18
              ),
              _0: {
                TAG: (
                  /* Open_box */
                  1
                ),
                _0: {
                  TAG: (
                    /* Format */
                    0
                  ),
                  _0: match$30._0,
                  _1: match$29._1
                }
              },
              _1: match$31._0
            },
            _1: match$31._1
          };
        case /* Reader */
        19:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Reader_ty */
          13) {
            const match$32 = type_format_gen(fmt._0, fmtty._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Reader */
                  19
                ),
                _0: match$32._0
              },
              _1: match$32._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Scan_char_set */
        20:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* String_ty */
          1) {
            const match$33 = type_format_gen(fmt._2, fmtty._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Scan_char_set */
                  20
                ),
                _0: fmt._0,
                _1: fmt._1,
                _2: match$33._0
              },
              _1: match$33._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Scan_get_counter */
        21:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Int_ty */
          2) {
            const match$34 = type_format_gen(fmt._1, fmtty._0);
            return {
              TAG: (
                /* Fmt_fmtty_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Scan_get_counter */
                  21
                ),
                _0: fmt._0,
                _1: match$34._0
              },
              _1: match$34._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Ignored_param */
        23:
          let ign = fmt._0;
          let fmt$1 = fmt._1;
          if (
            /* tag */
            typeof ign === "number" || typeof ign === "string"
          ) {
            if (ign !== /* Ignored_reader */
            2) {
              return type_ignored_param_one(ign, fmt$1, fmtty);
            }
            if (
              /* tag */
              typeof fmtty === "number" || typeof fmtty === "string"
            ) {
              throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
                MEL_EXN_ID: Type_mismatch
              });
            }
            if (fmtty.TAG === /* Ignored_reader_ty */
            14) {
              const match$35 = type_format_gen(fmt$1, fmtty._0);
              return {
                TAG: (
                  /* Fmt_fmtty_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Ignored_param */
                    23
                  ),
                  _0: (
                    /* Ignored_reader */
                    2
                  ),
                  _1: match$35._0
                },
                _1: match$35._1
              };
            }
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          } else {
            switch (ign.TAG) {
              case /* Ignored_format_arg */
              8:
                return type_ignored_param_one({
                  TAG: (
                    /* Ignored_format_arg */
                    8
                  ),
                  _0: ign._0,
                  _1: ign._1
                }, fmt$1, fmtty);
              case /* Ignored_format_subst */
              9:
                const match$36 = type_ignored_format_substitution(ign._1, fmt$1, fmtty);
                const match$37 = match$36._1;
                return {
                  TAG: (
                    /* Fmt_fmtty_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Ignored_param */
                      23
                    ),
                    _0: {
                      TAG: (
                        /* Ignored_format_subst */
                        9
                      ),
                      _0: ign._0,
                      _1: match$36._0
                    },
                    _1: match$37._0
                  },
                  _1: match$37._1
                };
              default:
                return type_ignored_param_one(ign, fmt$1, fmtty);
            }
          }
        case /* Scan_next_char */
        22:
        case /* Custom */
        24:
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
      }
    }
    function type_ignored_format_substitution(sub_fmtty, fmt, fmtty) {
      if (
        /* tag */
        typeof sub_fmtty === "number" || typeof sub_fmtty === "string"
      ) {
        return {
          TAG: (
            /* Fmtty_fmt_EBB */
            0
          ),
          _0: (
            /* End_of_fmtty */
            0
          ),
          _1: type_format_gen(fmt, fmtty)
        };
      }
      switch (sub_fmtty.TAG) {
        case /* Char_ty */
        0:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Char_ty */
          0) {
            const match = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Char_ty */
                  0
                ),
                _0: match._0
              },
              _1: match._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* String_ty */
        1:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* String_ty */
          1) {
            const match$1 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* String_ty */
                  1
                ),
                _0: match$1._0
              },
              _1: match$1._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Int_ty */
        2:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Int_ty */
          2) {
            const match$2 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Int_ty */
                  2
                ),
                _0: match$2._0
              },
              _1: match$2._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Int32_ty */
        3:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Int32_ty */
          3) {
            const match$3 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Int32_ty */
                  3
                ),
                _0: match$3._0
              },
              _1: match$3._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Nativeint_ty */
        4:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Nativeint_ty */
          4) {
            const match$4 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Nativeint_ty */
                  4
                ),
                _0: match$4._0
              },
              _1: match$4._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Int64_ty */
        5:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Int64_ty */
          5) {
            const match$5 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Int64_ty */
                  5
                ),
                _0: match$5._0
              },
              _1: match$5._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Float_ty */
        6:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Float_ty */
          6) {
            const match$6 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Float_ty */
                  6
                ),
                _0: match$6._0
              },
              _1: match$6._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Bool_ty */
        7:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Bool_ty */
          7) {
            const match$7 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Bool_ty */
                  7
                ),
                _0: match$7._0
              },
              _1: match$7._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Format_arg_ty */
        8:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Format_arg_ty */
          8) {
            const sub2_fmtty$p = fmtty._0;
            if (Caml_obj.caml_notequal({
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: sub_fmtty._0
            }, {
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: sub2_fmtty$p
            })) {
              throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
                MEL_EXN_ID: Type_mismatch
              });
            }
            const match$8 = type_ignored_format_substitution(sub_fmtty._1, fmt, fmtty._1);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Format_arg_ty */
                  8
                ),
                _0: sub2_fmtty$p,
                _1: match$8._0
              },
              _1: match$8._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Format_subst_ty */
        9:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Format_subst_ty */
          9) {
            const sub2_fmtty$p$1 = fmtty._1;
            const sub1_fmtty$p = fmtty._0;
            if (Caml_obj.caml_notequal({
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: CamlinternalFormatBasics.erase_rel(sub_fmtty._0)
            }, {
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: CamlinternalFormatBasics.erase_rel(sub1_fmtty$p)
            })) {
              throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
                MEL_EXN_ID: Type_mismatch
              });
            }
            if (Caml_obj.caml_notequal({
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: CamlinternalFormatBasics.erase_rel(sub_fmtty._1)
            }, {
              TAG: (
                /* Fmtty_EBB */
                0
              ),
              _0: CamlinternalFormatBasics.erase_rel(sub2_fmtty$p$1)
            })) {
              throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
                MEL_EXN_ID: Type_mismatch
              });
            }
            const sub_fmtty$p = trans(symm(sub1_fmtty$p), sub2_fmtty$p$1);
            const match$9 = fmtty_rel_det(sub_fmtty$p);
            Curry2._1(
              match$9[1],
              /* Refl */
              0
            );
            Curry2._1(
              match$9[3],
              /* Refl */
              0
            );
            const match$10 = type_ignored_format_substitution(CamlinternalFormatBasics.erase_rel(sub_fmtty._2), fmt, fmtty._2);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Format_subst_ty */
                  9
                ),
                _0: sub1_fmtty$p,
                _1: sub2_fmtty$p$1,
                _2: symm(match$10._0)
              },
              _1: match$10._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Alpha_ty */
        10:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Alpha_ty */
          10) {
            const match$11 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Alpha_ty */
                  10
                ),
                _0: match$11._0
              },
              _1: match$11._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Theta_ty */
        11:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Theta_ty */
          11) {
            const match$12 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Theta_ty */
                  11
                ),
                _0: match$12._0
              },
              _1: match$12._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Any_ty */
        12:
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Reader_ty */
        13:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Reader_ty */
          13) {
            const match$13 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Reader_ty */
                  13
                ),
                _0: match$13._0
              },
              _1: match$13._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
        case /* Ignored_reader_ty */
        14:
          if (
            /* tag */
            typeof fmtty === "number" || typeof fmtty === "string"
          ) {
            throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
              MEL_EXN_ID: Type_mismatch
            });
          }
          if (fmtty.TAG === /* Ignored_reader_ty */
          14) {
            const match$14 = type_ignored_format_substitution(sub_fmtty._0, fmt, fmtty._0);
            return {
              TAG: (
                /* Fmtty_fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Ignored_reader_ty */
                  14
                ),
                _0: match$14._0
              },
              _1: match$14._1
            };
          }
          throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
            MEL_EXN_ID: Type_mismatch
          });
      }
    }
    function type_ignored_param_one(ign, fmt, fmtty) {
      const match = type_format_gen(fmt, fmtty);
      return {
        TAG: (
          /* Fmt_fmtty_EBB */
          0
        ),
        _0: {
          TAG: (
            /* Ignored_param */
            23
          ),
          _0: ign,
          _1: match._0
        },
        _1: match._1
      };
    }
    function type_format(fmt, fmtty) {
      const match = type_format_gen(fmt, fmtty);
      let tmp = match._1;
      if (
        /* tag */
        typeof tmp === "number" || typeof tmp === "string"
      ) {
        return match._0;
      }
      throw new Caml_js_exceptions.MelangeError(Type_mismatch, {
        MEL_EXN_ID: Type_mismatch
      });
    }
    function recast(fmt, fmtty) {
      return type_format(fmt, CamlinternalFormatBasics.erase_rel(symm(fmtty)));
    }
    function fix_padding(padty, width, str) {
      const len = str.length;
      const width$1 = Stdlib.abs(width);
      const padty$1 = width < 0 ? (
        /* Left */
        0
      ) : padty;
      if (width$1 <= len) {
        return str;
      }
      const res = Stdlib__Bytes.make(width$1, padty$1 === /* Zeros */
      2 ? (
        /* '0' */
        48
      ) : (
        /* ' ' */
        32
      ));
      switch (padty$1) {
        case /* Left */
        0:
          Stdlib__String2.blit(str, 0, res, 0, len);
          break;
        case /* Right */
        1:
          Stdlib__String2.blit(str, 0, res, width$1 - len | 0, len);
          break;
        case /* Zeros */
        2:
          if (len > 0 && (Caml_string.get(str, 0) === /* '+' */
          43 || Caml_string.get(str, 0) === /* '-' */
          45 || Caml_string.get(str, 0) === /* ' ' */
          32)) {
            Caml_bytes.set(res, 0, Caml_string.get(str, 0));
            Stdlib__String2.blit(str, 1, res, (width$1 - len | 0) + 1 | 0, len - 1 | 0);
          } else if (len > 1 && Caml_string.get(str, 0) === /* '0' */
          48 && (Caml_string.get(str, 1) === /* 'x' */
          120 || Caml_string.get(str, 1) === /* 'X' */
          88)) {
            Caml_bytes.set(res, 1, Caml_string.get(str, 1));
            Stdlib__String2.blit(str, 2, res, (width$1 - len | 0) + 2 | 0, len - 2 | 0);
          } else {
            Stdlib__String2.blit(str, 0, res, width$1 - len | 0, len);
          }
          break;
      }
      return Caml_bytes.bytes_to_string(res);
    }
    function fix_int_precision(prec, str) {
      const prec$1 = Stdlib.abs(prec);
      const len = str.length;
      const c = Caml_string.get(str, 0);
      let exit = 0;
      if (c >= 58) {
        if (c >= 71) {
          if (c > 102 || c < 97) {
            return str;
          }
          exit = 2;
        } else {
          if (c < 65) {
            return str;
          }
          exit = 2;
        }
      } else if (c !== 32) {
        if (c < 43) {
          return str;
        }
        switch (c) {
          case 43:
          case 45:
            exit = 1;
            break;
          case 44:
          case 46:
          case 47:
            return str;
          case 48:
            if ((prec$1 + 2 | 0) > len && len > 1 && (Caml_string.get(str, 1) === /* 'x' */
            120 || Caml_string.get(str, 1) === /* 'X' */
            88)) {
              const res = Stdlib__Bytes.make(
                prec$1 + 2 | 0,
                /* '0' */
                48
              );
              Caml_bytes.set(res, 1, Caml_string.get(str, 1));
              Stdlib__String2.blit(str, 2, res, (prec$1 - len | 0) + 4 | 0, len - 2 | 0);
              return Caml_bytes.bytes_to_string(res);
            }
            exit = 2;
            break;
          case 49:
          case 50:
          case 51:
          case 52:
          case 53:
          case 54:
          case 55:
          case 56:
          case 57:
            exit = 2;
            break;
        }
      } else {
        exit = 1;
      }
      switch (exit) {
        case 1:
          if ((prec$1 + 1 | 0) <= len) {
            return str;
          }
          const res$1 = Stdlib__Bytes.make(
            prec$1 + 1 | 0,
            /* '0' */
            48
          );
          Caml_bytes.set(res$1, 0, c);
          Stdlib__String2.blit(str, 1, res$1, (prec$1 - len | 0) + 2 | 0, len - 1 | 0);
          return Caml_bytes.bytes_to_string(res$1);
        case 2:
          if (prec$1 <= len) {
            return str;
          }
          const res$2 = Stdlib__Bytes.make(
            prec$1,
            /* '0' */
            48
          );
          Stdlib__String2.blit(str, 0, res$2, prec$1 - len | 0, len);
          return Caml_bytes.bytes_to_string(res$2);
      }
    }
    function string_to_caml_string(str) {
      const str$1 = Stdlib__String2.escaped(str);
      const l = str$1.length;
      const res = Stdlib__Bytes.make(
        l + 2 | 0,
        /* '"' */
        34
      );
      Caml_bytes.caml_blit_string(str$1, 0, res, 1, l);
      return Caml_bytes.bytes_to_string(res);
    }
    function format_of_iconv(param) {
      switch (param) {
        case /* Int_pd */
        1:
          return "%+d";
        case /* Int_sd */
        2:
          return "% d";
        case /* Int_pi */
        4:
          return "%+i";
        case /* Int_si */
        5:
          return "% i";
        case /* Int_x */
        6:
          return "%x";
        case /* Int_Cx */
        7:
          return "%#x";
        case /* Int_X */
        8:
          return "%X";
        case /* Int_CX */
        9:
          return "%#X";
        case /* Int_o */
        10:
          return "%o";
        case /* Int_Co */
        11:
          return "%#o";
        case /* Int_d */
        0:
        case /* Int_Cd */
        13:
          return "%d";
        case /* Int_i */
        3:
        case /* Int_Ci */
        14:
          return "%i";
        case /* Int_u */
        12:
        case /* Int_Cu */
        15:
          return "%u";
      }
    }
    function format_of_iconvL(param) {
      switch (param) {
        case /* Int_pd */
        1:
          return "%+Ld";
        case /* Int_sd */
        2:
          return "% Ld";
        case /* Int_pi */
        4:
          return "%+Li";
        case /* Int_si */
        5:
          return "% Li";
        case /* Int_x */
        6:
          return "%Lx";
        case /* Int_Cx */
        7:
          return "%#Lx";
        case /* Int_X */
        8:
          return "%LX";
        case /* Int_CX */
        9:
          return "%#LX";
        case /* Int_o */
        10:
          return "%Lo";
        case /* Int_Co */
        11:
          return "%#Lo";
        case /* Int_d */
        0:
        case /* Int_Cd */
        13:
          return "%Ld";
        case /* Int_i */
        3:
        case /* Int_Ci */
        14:
          return "%Li";
        case /* Int_u */
        12:
        case /* Int_Cu */
        15:
          return "%Lu";
      }
    }
    function format_of_iconvl(param) {
      switch (param) {
        case /* Int_pd */
        1:
          return "%+ld";
        case /* Int_sd */
        2:
          return "% ld";
        case /* Int_pi */
        4:
          return "%+li";
        case /* Int_si */
        5:
          return "% li";
        case /* Int_x */
        6:
          return "%lx";
        case /* Int_Cx */
        7:
          return "%#lx";
        case /* Int_X */
        8:
          return "%lX";
        case /* Int_CX */
        9:
          return "%#lX";
        case /* Int_o */
        10:
          return "%lo";
        case /* Int_Co */
        11:
          return "%#lo";
        case /* Int_d */
        0:
        case /* Int_Cd */
        13:
          return "%ld";
        case /* Int_i */
        3:
        case /* Int_Ci */
        14:
          return "%li";
        case /* Int_u */
        12:
        case /* Int_Cu */
        15:
          return "%lu";
      }
    }
    function format_of_iconvn(param) {
      switch (param) {
        case /* Int_pd */
        1:
          return "%+nd";
        case /* Int_sd */
        2:
          return "% nd";
        case /* Int_pi */
        4:
          return "%+ni";
        case /* Int_si */
        5:
          return "% ni";
        case /* Int_x */
        6:
          return "%nx";
        case /* Int_Cx */
        7:
          return "%#nx";
        case /* Int_X */
        8:
          return "%nX";
        case /* Int_CX */
        9:
          return "%#nX";
        case /* Int_o */
        10:
          return "%no";
        case /* Int_Co */
        11:
          return "%#no";
        case /* Int_d */
        0:
        case /* Int_Cd */
        13:
          return "%nd";
        case /* Int_i */
        3:
        case /* Int_Ci */
        14:
          return "%ni";
        case /* Int_u */
        12:
        case /* Int_Cu */
        15:
          return "%nu";
      }
    }
    function format_of_fconv(fconv, prec) {
      const prec$1 = Stdlib.abs(prec);
      const symb = char_of_fconv(
        /* 'g' */
        103,
        fconv
      );
      const buf = {
        ind: 0,
        bytes: Caml_bytes.caml_create_bytes(16)
      };
      buffer_add_char(
        buf,
        /* '%' */
        37
      );
      bprint_fconv_flag(buf, fconv);
      buffer_add_char(
        buf,
        /* '.' */
        46
      );
      buffer_add_string(buf, Caml_format.caml_format_int("%d", prec$1));
      buffer_add_char(buf, symb);
      return buffer_contents(buf);
    }
    function transform_int_alt(iconv, s) {
      switch (iconv) {
        case /* Int_Cd */
        13:
        case /* Int_Ci */
        14:
        case /* Int_Cu */
        15:
          break;
        default:
          return s;
      }
      let n2 = 0;
      for (let i = 0, i_finish = s.length; i < i_finish; ++i) {
        const match = s.charCodeAt(i);
        if (!(match > 57 || match < 48)) {
          n2 = n2 + 1 | 0;
        }
      }
      const digits = n2;
      const buf = Caml_bytes.caml_create_bytes(s.length + ((digits - 1 | 0) / 3 | 0) | 0);
      const pos = {
        contents: 0
      };
      const put = function(c) {
        Caml_bytes.set(buf, pos.contents, c);
        pos.contents = pos.contents + 1 | 0;
      };
      let left = (digits - 1 | 0) % 3 + 1 | 0;
      for (let i$1 = 0, i_finish$1 = s.length; i$1 < i_finish$1; ++i$1) {
        const c = s.charCodeAt(i$1);
        if (c > 57 || c < 48) {
          put(c);
        } else {
          if (left === 0) {
            put(
              /* '_' */
              95
            );
            left = 3;
          }
          left = left - 1 | 0;
          put(c);
        }
      }
      return Caml_bytes.bytes_to_string(buf);
    }
    function convert_int(iconv, n2) {
      return transform_int_alt(iconv, Caml_format.caml_format_int(format_of_iconv(iconv), n2));
    }
    function convert_int32(iconv, n2) {
      return transform_int_alt(iconv, Caml_format.caml_int32_format(format_of_iconvl(iconv), n2));
    }
    function convert_nativeint(iconv, n2) {
      return transform_int_alt(iconv, Caml_format.caml_nativeint_format(format_of_iconvn(iconv), n2));
    }
    function convert_int64(iconv, n2) {
      return transform_int_alt(iconv, Caml_format.caml_int64_format(format_of_iconvL(iconv), n2));
    }
    function convert_float(fconv, prec, x) {
      const hex = function(param) {
        const match2 = fconv[0];
        let sign;
        switch (match2) {
          case /* Float_flag_ */
          0:
            sign = /* '-' */
            45;
            break;
          case /* Float_flag_p */
          1:
            sign = /* '+' */
            43;
            break;
          case /* Float_flag_s */
          2:
            sign = /* ' ' */
            32;
            break;
        }
        return Caml_format.caml_hexstring_of_float(x, prec, sign);
      };
      const add_dot_if_needed = function(str) {
        const len = str.length;
        const is_valid = function(_i) {
          while (true) {
            const i = _i;
            if (i === len) {
              return false;
            }
            const match2 = Caml_string.get(str, i);
            if (match2 > 69 || match2 < 46) {
              if (match2 === 101) {
                return true;
              }
              _i = i + 1 | 0;
              continue;
            }
            if (match2 > 68 || match2 < 47) {
              return true;
            }
            _i = i + 1 | 0;
            continue;
          }
          ;
        };
        if (is_valid(0)) {
          return str;
        } else {
          return str + ".";
        }
      };
      const caml_special_val = function(str) {
        const match2 = Stdlib.classify_float(x);
        switch (match2) {
          case /* FP_infinite */
          3:
            if (x < 0) {
              return "neg_infinity";
            } else {
              return "infinity";
            }
          case /* FP_nan */
          4:
            return "nan";
          default:
            return str;
        }
      };
      const match = fconv[1];
      switch (match) {
        case /* Float_F */
        5:
          const str = Caml_format.caml_format_float(format_of_fconv(fconv, prec), x);
          return caml_special_val(add_dot_if_needed(str));
        case /* Float_h */
        6:
          return hex(void 0);
        case /* Float_H */
        7:
          const s = hex(void 0);
          return Caml_bytes.bytes_to_string(Stdlib__Bytes.uppercase_ascii(Caml_bytes.bytes_of_string(s)));
        case /* Float_CF */
        8:
          return caml_special_val(hex(void 0));
        default:
          return Caml_format.caml_format_float(format_of_fconv(fconv, prec), x);
      }
    }
    function format_caml_char(c) {
      const str = Stdlib__Char.escaped(c);
      const l = str.length;
      const res = Stdlib__Bytes.make(
        l + 2 | 0,
        /* '\'' */
        39
      );
      Caml_bytes.caml_blit_string(str, 0, res, 1, l);
      return Caml_bytes.bytes_to_string(res);
    }
    function string_of_fmtty(fmtty) {
      const buf = {
        ind: 0,
        bytes: Caml_bytes.caml_create_bytes(16)
      };
      bprint_fmtty(buf, fmtty);
      return buffer_contents(buf);
    }
    function make_printf(_k, _acc, _fmt) {
      while (true) {
        const fmt = _fmt;
        const acc = _acc;
        const k = _k;
        if (
          /* tag */
          typeof fmt === "number" || typeof fmt === "string"
        ) {
          return Curry2._1(k, acc);
        }
        switch (fmt.TAG) {
          case /* Char */
          0:
            const rest = fmt._0;
            return function(c) {
              const new_acc2 = {
                TAG: (
                  /* Acc_data_char */
                  5
                ),
                _0: acc,
                _1: c
              };
              return make_printf(k, new_acc2, rest);
            };
          case /* Caml_char */
          1:
            const rest$1 = fmt._0;
            return function(c) {
              const new_acc_1 = format_caml_char(c);
              const new_acc2 = {
                TAG: (
                  /* Acc_data_string */
                  4
                ),
                _0: acc,
                _1: new_acc_1
              };
              return make_printf(k, new_acc2, rest$1);
            };
          case /* String */
          2:
            return make_padding(k, acc, fmt._1, fmt._0, (function(str) {
              return str;
            }));
          case /* Caml_string */
          3:
            return make_padding(k, acc, fmt._1, fmt._0, string_to_caml_string);
          case /* Int */
          4:
            return make_int_padding_precision(k, acc, fmt._3, fmt._1, fmt._2, convert_int, fmt._0);
          case /* Int32 */
          5:
            return make_int_padding_precision(k, acc, fmt._3, fmt._1, fmt._2, convert_int32, fmt._0);
          case /* Nativeint */
          6:
            return make_int_padding_precision(k, acc, fmt._3, fmt._1, fmt._2, convert_nativeint, fmt._0);
          case /* Int64 */
          7:
            return make_int_padding_precision(k, acc, fmt._3, fmt._1, fmt._2, convert_int64, fmt._0);
          case /* Float */
          8:
            let fmt$1 = fmt._3;
            let pad = fmt._1;
            let prec = fmt._2;
            let fconv = fmt._0;
            if (
              /* tag */
              typeof pad === "number" || typeof pad === "string"
            ) {
              if (
                /* tag */
                typeof prec === "number" || typeof prec === "string"
              ) {
                if (prec === /* No_precision */
                0) {
                  return function(x) {
                    const str = convert_float(fconv, default_float_precision(fconv), x);
                    return make_printf(k, {
                      TAG: (
                        /* Acc_data_string */
                        4
                      ),
                      _0: acc,
                      _1: str
                    }, fmt$1);
                  };
                } else {
                  return function(p2, x) {
                    const str = convert_float(fconv, p2, x);
                    return make_printf(k, {
                      TAG: (
                        /* Acc_data_string */
                        4
                      ),
                      _0: acc,
                      _1: str
                    }, fmt$1);
                  };
                }
              }
              const p = prec._0;
              return function(x) {
                const str = convert_float(fconv, p, x);
                return make_printf(k, {
                  TAG: (
                    /* Acc_data_string */
                    4
                  ),
                  _0: acc,
                  _1: str
                }, fmt$1);
              };
            }
            if (pad.TAG === /* Lit_padding */
            0) {
              const w = pad._1;
              const padty = pad._0;
              if (
                /* tag */
                typeof prec === "number" || typeof prec === "string"
              ) {
                if (prec === /* No_precision */
                0) {
                  return function(x) {
                    const str = convert_float(fconv, default_float_precision(fconv), x);
                    const str$p = fix_padding(padty, w, str);
                    return make_printf(k, {
                      TAG: (
                        /* Acc_data_string */
                        4
                      ),
                      _0: acc,
                      _1: str$p
                    }, fmt$1);
                  };
                } else {
                  return function(p, x) {
                    const str = fix_padding(padty, w, convert_float(fconv, p, x));
                    return make_printf(k, {
                      TAG: (
                        /* Acc_data_string */
                        4
                      ),
                      _0: acc,
                      _1: str
                    }, fmt$1);
                  };
                }
              }
              const p$1 = prec._0;
              return function(x) {
                const str = fix_padding(padty, w, convert_float(fconv, p$1, x));
                return make_printf(k, {
                  TAG: (
                    /* Acc_data_string */
                    4
                  ),
                  _0: acc,
                  _1: str
                }, fmt$1);
              };
            }
            const padty$1 = pad._0;
            if (
              /* tag */
              typeof prec === "number" || typeof prec === "string"
            ) {
              if (prec === /* No_precision */
              0) {
                return function(w, x) {
                  const str = convert_float(fconv, default_float_precision(fconv), x);
                  const str$p = fix_padding(padty$1, w, str);
                  return make_printf(k, {
                    TAG: (
                      /* Acc_data_string */
                      4
                    ),
                    _0: acc,
                    _1: str$p
                  }, fmt$1);
                };
              } else {
                return function(w, p, x) {
                  const str = fix_padding(padty$1, w, convert_float(fconv, p, x));
                  return make_printf(k, {
                    TAG: (
                      /* Acc_data_string */
                      4
                    ),
                    _0: acc,
                    _1: str
                  }, fmt$1);
                };
              }
            }
            const p$2 = prec._0;
            return function(w, x) {
              const str = fix_padding(padty$1, w, convert_float(fconv, p$2, x));
              return make_printf(k, {
                TAG: (
                  /* Acc_data_string */
                  4
                ),
                _0: acc,
                _1: str
              }, fmt$1);
            };
          case /* Bool */
          9:
            return make_padding(k, acc, fmt._1, fmt._0, Stdlib.string_of_bool);
          case /* Flush */
          10:
            _fmt = fmt._0;
            _acc = {
              TAG: (
                /* Acc_flush */
                7
              ),
              _0: acc
            };
            continue;
          case /* String_literal */
          11:
            _fmt = fmt._1;
            _acc = {
              TAG: (
                /* Acc_string_literal */
                2
              ),
              _0: acc,
              _1: fmt._0
            };
            continue;
          case /* Char_literal */
          12:
            _fmt = fmt._1;
            _acc = {
              TAG: (
                /* Acc_char_literal */
                3
              ),
              _0: acc,
              _1: fmt._0
            };
            continue;
          case /* Format_arg */
          13:
            const rest$2 = fmt._2;
            const ty = string_of_fmtty(fmt._1);
            return function(str) {
              return make_printf(k, {
                TAG: (
                  /* Acc_data_string */
                  4
                ),
                _0: acc,
                _1: ty
              }, rest$2);
            };
          case /* Format_subst */
          14:
            const rest$3 = fmt._2;
            const fmtty = fmt._1;
            return function(param) {
              return make_printf(k, acc, CamlinternalFormatBasics.concat_fmt(recast(param._0, fmtty), rest$3));
            };
          case /* Alpha */
          15:
            const rest$4 = fmt._0;
            return function(f, x) {
              return make_printf(k, {
                TAG: (
                  /* Acc_delay */
                  6
                ),
                _0: acc,
                _1: (function(o) {
                  return Curry2._2(f, o, x);
                })
              }, rest$4);
            };
          case /* Theta */
          16:
            const rest$5 = fmt._0;
            return function(f) {
              return make_printf(k, {
                TAG: (
                  /* Acc_delay */
                  6
                ),
                _0: acc,
                _1: f
              }, rest$5);
            };
          case /* Formatting_lit */
          17:
            _fmt = fmt._1;
            _acc = {
              TAG: (
                /* Acc_formatting_lit */
                0
              ),
              _0: acc,
              _1: fmt._0
            };
            continue;
          case /* Formatting_gen */
          18:
            const match = fmt._0;
            if (match.TAG === /* Open_tag */
            0) {
              const rest$6 = fmt._1;
              const k$p = function(kacc) {
                return make_printf(k, {
                  TAG: (
                    /* Acc_formatting_gen */
                    1
                  ),
                  _0: acc,
                  _1: {
                    TAG: (
                      /* Acc_open_tag */
                      0
                    ),
                    _0: kacc
                  }
                }, rest$6);
              };
              _fmt = match._0._0;
              _acc = /* End_of_acc */
              0;
              _k = k$p;
              continue;
            }
            const rest$7 = fmt._1;
            const k$p$1 = function(kacc) {
              return make_printf(k, {
                TAG: (
                  /* Acc_formatting_gen */
                  1
                ),
                _0: acc,
                _1: {
                  TAG: (
                    /* Acc_open_box */
                    1
                  ),
                  _0: kacc
                }
              }, rest$7);
            };
            _fmt = match._0._0;
            _acc = /* End_of_acc */
            0;
            _k = k$p$1;
            continue;
          case /* Reader */
          19:
            throw new Caml_js_exceptions.MelangeError("Assert_failure", {
              MEL_EXN_ID: "Assert_failure",
              _1: [
                "camlinternalFormat.cppo.ml",
                1558,
                4
              ]
            });
          case /* Scan_char_set */
          20:
            const rest$8 = fmt._2;
            const new_acc = {
              TAG: (
                /* Acc_invalid_arg */
                8
              ),
              _0: acc,
              _1: "Printf: bad conversion %["
            };
            return function(param) {
              return make_printf(k, new_acc, rest$8);
            };
          case /* Scan_get_counter */
          21:
            const rest$9 = fmt._1;
            return function(n2) {
              const new_acc_1 = Caml_format.caml_format_int("%u", n2);
              const new_acc2 = {
                TAG: (
                  /* Acc_data_string */
                  4
                ),
                _0: acc,
                _1: new_acc_1
              };
              return make_printf(k, new_acc2, rest$9);
            };
          case /* Scan_next_char */
          22:
            const rest$10 = fmt._0;
            return function(c) {
              const new_acc2 = {
                TAG: (
                  /* Acc_data_char */
                  5
                ),
                _0: acc,
                _1: c
              };
              return make_printf(k, new_acc2, rest$10);
            };
          case /* Ignored_param */
          23:
            return make_ignored_param(k, acc, fmt._0, fmt._1);
          case /* Custom */
          24:
            return make_custom(k, acc, fmt._2, fmt._0, Curry2._1(fmt._1, void 0));
        }
      }
      ;
    }
    function make_ignored_param(k, acc, ign, fmt) {
      if (!/* tag */
      (typeof ign === "number" || typeof ign === "string")) {
        if (ign.TAG === /* Ignored_format_subst */
        9) {
          return make_from_fmtty(k, acc, ign._1, fmt);
        } else {
          return make_invalid_arg(k, acc, fmt);
        }
      }
      if (ign !== /* Ignored_reader */
      2) {
        return make_invalid_arg(k, acc, fmt);
      }
      throw new Caml_js_exceptions.MelangeError("Assert_failure", {
        MEL_EXN_ID: "Assert_failure",
        _1: [
          "camlinternalFormat.cppo.ml",
          1626,
          39
        ]
      });
    }
    function make_from_fmtty(k, acc, fmtty, fmt) {
      if (
        /* tag */
        typeof fmtty === "number" || typeof fmtty === "string"
      ) {
        return make_invalid_arg(k, acc, fmt);
      }
      switch (fmtty.TAG) {
        case /* Char_ty */
        0:
          const rest = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest, fmt);
          };
        case /* String_ty */
        1:
          const rest$1 = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest$1, fmt);
          };
        case /* Int_ty */
        2:
          const rest$2 = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest$2, fmt);
          };
        case /* Int32_ty */
        3:
          const rest$3 = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest$3, fmt);
          };
        case /* Nativeint_ty */
        4:
          const rest$4 = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest$4, fmt);
          };
        case /* Int64_ty */
        5:
          const rest$5 = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest$5, fmt);
          };
        case /* Float_ty */
        6:
          const rest$6 = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest$6, fmt);
          };
        case /* Bool_ty */
        7:
          const rest$7 = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest$7, fmt);
          };
        case /* Format_arg_ty */
        8:
          const rest$8 = fmtty._1;
          return function(param) {
            return make_from_fmtty(k, acc, rest$8, fmt);
          };
        case /* Format_subst_ty */
        9:
          const rest$9 = fmtty._2;
          const ty = trans(symm(fmtty._0), fmtty._1);
          return function(param) {
            return make_from_fmtty(k, acc, CamlinternalFormatBasics.concat_fmtty(ty, rest$9), fmt);
          };
        case /* Alpha_ty */
        10:
          const rest$10 = fmtty._0;
          return function(param, param$1) {
            return make_from_fmtty(k, acc, rest$10, fmt);
          };
        case /* Theta_ty */
        11:
          const rest$11 = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest$11, fmt);
          };
        case /* Any_ty */
        12:
          const rest$12 = fmtty._0;
          return function(param) {
            return make_from_fmtty(k, acc, rest$12, fmt);
          };
        case /* Reader_ty */
        13:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              1649,
              31
            ]
          });
        case /* Ignored_reader_ty */
        14:
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              1650,
              31
            ]
          });
      }
    }
    function make_invalid_arg(k, acc, fmt) {
      return make_printf(k, {
        TAG: (
          /* Acc_invalid_arg */
          8
        ),
        _0: acc,
        _1: "Printf: bad conversion %_"
      }, fmt);
    }
    function make_padding(k, acc, fmt, pad, trans2) {
      if (
        /* tag */
        typeof pad === "number" || typeof pad === "string"
      ) {
        return function(x) {
          const new_acc_1 = Curry2._1(trans2, x);
          const new_acc = {
            TAG: (
              /* Acc_data_string */
              4
            ),
            _0: acc,
            _1: new_acc_1
          };
          return make_printf(k, new_acc, fmt);
        };
      }
      if (pad.TAG === /* Lit_padding */
      0) {
        const width = pad._1;
        const padty = pad._0;
        return function(x) {
          const new_acc_1 = fix_padding(padty, width, Curry2._1(trans2, x));
          const new_acc = {
            TAG: (
              /* Acc_data_string */
              4
            ),
            _0: acc,
            _1: new_acc_1
          };
          return make_printf(k, new_acc, fmt);
        };
      }
      const padty$1 = pad._0;
      return function(w, x) {
        const new_acc_1 = fix_padding(padty$1, w, Curry2._1(trans2, x));
        const new_acc = {
          TAG: (
            /* Acc_data_string */
            4
          ),
          _0: acc,
          _1: new_acc_1
        };
        return make_printf(k, new_acc, fmt);
      };
    }
    function make_int_padding_precision(k, acc, fmt, pad, prec, trans2, iconv) {
      if (
        /* tag */
        typeof pad === "number" || typeof pad === "string"
      ) {
        if (
          /* tag */
          typeof prec === "number" || typeof prec === "string"
        ) {
          if (prec === /* No_precision */
          0) {
            return function(x) {
              const str = Curry2._2(trans2, iconv, x);
              return make_printf(k, {
                TAG: (
                  /* Acc_data_string */
                  4
                ),
                _0: acc,
                _1: str
              }, fmt);
            };
          } else {
            return function(p2, x) {
              const str = fix_int_precision(p2, Curry2._2(trans2, iconv, x));
              return make_printf(k, {
                TAG: (
                  /* Acc_data_string */
                  4
                ),
                _0: acc,
                _1: str
              }, fmt);
            };
          }
        }
        const p = prec._0;
        return function(x) {
          const str = fix_int_precision(p, Curry2._2(trans2, iconv, x));
          return make_printf(k, {
            TAG: (
              /* Acc_data_string */
              4
            ),
            _0: acc,
            _1: str
          }, fmt);
        };
      }
      if (pad.TAG === /* Lit_padding */
      0) {
        const w = pad._1;
        const padty = pad._0;
        if (
          /* tag */
          typeof prec === "number" || typeof prec === "string"
        ) {
          if (prec === /* No_precision */
          0) {
            return function(x) {
              const str = fix_padding(padty, w, Curry2._2(trans2, iconv, x));
              return make_printf(k, {
                TAG: (
                  /* Acc_data_string */
                  4
                ),
                _0: acc,
                _1: str
              }, fmt);
            };
          } else {
            return function(p, x) {
              const str = fix_padding(padty, w, fix_int_precision(p, Curry2._2(trans2, iconv, x)));
              return make_printf(k, {
                TAG: (
                  /* Acc_data_string */
                  4
                ),
                _0: acc,
                _1: str
              }, fmt);
            };
          }
        }
        const p$1 = prec._0;
        return function(x) {
          const str = fix_padding(padty, w, fix_int_precision(p$1, Curry2._2(trans2, iconv, x)));
          return make_printf(k, {
            TAG: (
              /* Acc_data_string */
              4
            ),
            _0: acc,
            _1: str
          }, fmt);
        };
      }
      const padty$1 = pad._0;
      if (
        /* tag */
        typeof prec === "number" || typeof prec === "string"
      ) {
        if (prec === /* No_precision */
        0) {
          return function(w, x) {
            const str = fix_padding(padty$1, w, Curry2._2(trans2, iconv, x));
            return make_printf(k, {
              TAG: (
                /* Acc_data_string */
                4
              ),
              _0: acc,
              _1: str
            }, fmt);
          };
        } else {
          return function(w, p, x) {
            const str = fix_padding(padty$1, w, fix_int_precision(p, Curry2._2(trans2, iconv, x)));
            return make_printf(k, {
              TAG: (
                /* Acc_data_string */
                4
              ),
              _0: acc,
              _1: str
            }, fmt);
          };
        }
      }
      const p$2 = prec._0;
      return function(w, x) {
        const str = fix_padding(padty$1, w, fix_int_precision(p$2, Curry2._2(trans2, iconv, x)));
        return make_printf(k, {
          TAG: (
            /* Acc_data_string */
            4
          ),
          _0: acc,
          _1: str
        }, fmt);
      };
    }
    function make_custom(k, acc, rest, arity, f) {
      if (
        /* tag */
        typeof arity === "number" || typeof arity === "string"
      ) {
        return make_printf(k, {
          TAG: (
            /* Acc_data_string */
            4
          ),
          _0: acc,
          _1: f
        }, rest);
      }
      const arity$1 = arity._0;
      return function(x) {
        return make_custom(k, acc, rest, arity$1, Curry2._1(f, x));
      };
    }
    function make_iprintf(_k, o, _fmt) {
      while (true) {
        const fmt = _fmt;
        const k = _k;
        let exit = 0;
        if (
          /* tag */
          typeof fmt === "number" || typeof fmt === "string"
        ) {
          return Curry2._1(k, o);
        }
        switch (fmt.TAG) {
          case /* String */
          2:
            let exit$1 = 0;
            let tmp = fmt._0;
            if (
              /* tag */
              typeof tmp === "number" || typeof tmp === "string" || tmp.TAG === /* Lit_padding */
              0
            ) {
              exit$1 = 4;
            } else {
              const partial_arg = make_iprintf(k, o, fmt._1);
              const partial_arg$1 = function(param) {
                return partial_arg;
              };
              return function(param) {
                return partial_arg$1;
              };
            }
            if (exit$1 === 4) {
              const partial_arg$2 = make_iprintf(k, o, fmt._1);
              return function(param) {
                return partial_arg$2;
              };
            }
            break;
          case /* Caml_string */
          3:
            let exit$2 = 0;
            let tmp$1 = fmt._0;
            if (
              /* tag */
              typeof tmp$1 === "number" || typeof tmp$1 === "string" || tmp$1.TAG === /* Lit_padding */
              0
            ) {
              exit$2 = 4;
            } else {
              const partial_arg$3 = make_iprintf(k, o, fmt._1);
              const partial_arg$4 = function(param) {
                return partial_arg$3;
              };
              return function(param) {
                return partial_arg$4;
              };
            }
            if (exit$2 === 4) {
              const partial_arg$5 = make_iprintf(k, o, fmt._1);
              return function(param) {
                return partial_arg$5;
              };
            }
            break;
          case /* Bool */
          9:
            let exit$3 = 0;
            let tmp$2 = fmt._0;
            if (
              /* tag */
              typeof tmp$2 === "number" || typeof tmp$2 === "string" || tmp$2.TAG === /* Lit_padding */
              0
            ) {
              exit$3 = 4;
            } else {
              const partial_arg$6 = make_iprintf(k, o, fmt._1);
              const partial_arg$7 = function(param) {
                return partial_arg$6;
              };
              return function(param) {
                return partial_arg$7;
              };
            }
            if (exit$3 === 4) {
              const partial_arg$8 = make_iprintf(k, o, fmt._1);
              return function(param) {
                return partial_arg$8;
              };
            }
            break;
          case /* Flush */
          10:
            _fmt = fmt._0;
            continue;
          case /* Format_subst */
          14:
            const rest = fmt._2;
            const fmtty = fmt._1;
            return function(param) {
              return make_iprintf(k, o, CamlinternalFormatBasics.concat_fmt(recast(param._0, fmtty), rest));
            };
          case /* Alpha */
          15:
            const partial_arg$9 = make_iprintf(k, o, fmt._0);
            const partial_arg$10 = function(param) {
              return partial_arg$9;
            };
            return function(param) {
              return partial_arg$10;
            };
          case /* String_literal */
          11:
          case /* Char_literal */
          12:
          case /* Formatting_lit */
          17:
            exit = 2;
            break;
          case /* Formatting_gen */
          18:
            const match = fmt._0;
            if (match.TAG === /* Open_tag */
            0) {
              const rest$1 = fmt._1;
              _fmt = match._0._0;
              _k = (function(koc) {
                return make_iprintf(k, koc, rest$1);
              });
              continue;
            }
            const rest$2 = fmt._1;
            _fmt = match._0._0;
            _k = (function(koc) {
              return make_iprintf(k, koc, rest$2);
            });
            continue;
          case /* Reader */
          19:
            throw new Caml_js_exceptions.MelangeError("Assert_failure", {
              MEL_EXN_ID: "Assert_failure",
              _1: [
                "camlinternalFormat.cppo.ml",
                1830,
                8
              ]
            });
          case /* Format_arg */
          13:
          case /* Scan_char_set */
          20:
            exit = 3;
            break;
          case /* Scan_get_counter */
          21:
            const partial_arg$11 = make_iprintf(k, o, fmt._1);
            return function(param) {
              return partial_arg$11;
            };
          case /* Char */
          0:
          case /* Caml_char */
          1:
          case /* Theta */
          16:
          case /* Scan_next_char */
          22:
            exit = 1;
            break;
          case /* Ignored_param */
          23:
            return make_ignored_param(
              (function(param) {
                return Curry2._1(k, o);
              }),
              /* End_of_acc */
              0,
              fmt._0,
              fmt._1
            );
          case /* Custom */
          24:
            return fn_of_custom_arity(k, o, fmt._2, fmt._0);
          default:
            let fmt$1 = fmt._3;
            let pad = fmt._1;
            let prec = fmt._2;
            if (
              /* tag */
              typeof pad === "number" || typeof pad === "string"
            ) {
              if (
                /* tag */
                typeof prec === "number" || typeof prec === "string"
              ) {
                if (prec === /* No_precision */
                0) {
                  const partial_arg$12 = make_iprintf(k, o, fmt$1);
                  return function(param) {
                    return partial_arg$12;
                  };
                }
                const partial_arg$13 = make_iprintf(k, o, fmt$1);
                const partial_arg$14 = function(param) {
                  return partial_arg$13;
                };
                return function(param) {
                  return partial_arg$14;
                };
              } else {
                const partial_arg$15 = make_iprintf(k, o, fmt$1);
                return function(param) {
                  return partial_arg$15;
                };
              }
            } else if (pad.TAG === /* Lit_padding */
            0) {
              if (
                /* tag */
                typeof prec === "number" || typeof prec === "string"
              ) {
                if (prec === /* No_precision */
                0) {
                  const partial_arg$16 = make_iprintf(k, o, fmt$1);
                  return function(param) {
                    return partial_arg$16;
                  };
                }
                const partial_arg$17 = make_iprintf(k, o, fmt$1);
                const partial_arg$18 = function(param) {
                  return partial_arg$17;
                };
                return function(param) {
                  return partial_arg$18;
                };
              } else {
                const partial_arg$19 = make_iprintf(k, o, fmt$1);
                return function(param) {
                  return partial_arg$19;
                };
              }
            } else if (
              /* tag */
              typeof prec === "number" || typeof prec === "string"
            ) {
              if (prec === /* No_precision */
              0) {
                const partial_arg$20 = make_iprintf(k, o, fmt$1);
                const partial_arg$21 = function(param) {
                  return partial_arg$20;
                };
                return function(param) {
                  return partial_arg$21;
                };
              }
              const partial_arg$22 = make_iprintf(k, o, fmt$1);
              const partial_arg$23 = function(param) {
                return partial_arg$22;
              };
              const partial_arg$24 = function(param) {
                return partial_arg$23;
              };
              return function(param) {
                return partial_arg$24;
              };
            } else {
              const partial_arg$25 = make_iprintf(k, o, fmt$1);
              const partial_arg$26 = function(param) {
                return partial_arg$25;
              };
              return function(param) {
                return partial_arg$26;
              };
            }
        }
        switch (exit) {
          case 1:
            const partial_arg$27 = make_iprintf(k, o, fmt._0);
            return function(param) {
              return partial_arg$27;
            };
          case 2:
            _fmt = fmt._1;
            continue;
          case 3:
            const partial_arg$28 = make_iprintf(k, o, fmt._2);
            return function(param) {
              return partial_arg$28;
            };
        }
      }
      ;
    }
    function fn_of_custom_arity(k, o, fmt, arity) {
      if (
        /* tag */
        typeof arity === "number" || typeof arity === "string"
      ) {
        return make_iprintf(k, o, fmt);
      }
      const partial_arg = fn_of_custom_arity(k, o, fmt, arity._0);
      return function(param) {
        return partial_arg;
      };
    }
    function output_acc(o, _acc) {
      while (true) {
        const acc = _acc;
        let exit = 0;
        if (
          /* tag */
          typeof acc === "number" || typeof acc === "string"
        ) {
          return;
        }
        switch (acc.TAG) {
          case /* Acc_formatting_lit */
          0:
            const s = string_of_formatting_lit(acc._1);
            output_acc(o, acc._0);
            return Stdlib.output_string(o, s);
          case /* Acc_formatting_gen */
          1:
            const acc$p = acc._1;
            const p = acc._0;
            if (acc$p.TAG === /* Acc_open_tag */
            0) {
              output_acc(o, p);
              Stdlib.output_string(o, "@{");
              _acc = acc$p._0;
              continue;
            }
            output_acc(o, p);
            Stdlib.output_string(o, "@[");
            _acc = acc$p._0;
            continue;
          case /* Acc_string_literal */
          2:
          case /* Acc_data_string */
          4:
            exit = 1;
            break;
          case /* Acc_char_literal */
          3:
          case /* Acc_data_char */
          5:
            exit = 2;
            break;
          case /* Acc_delay */
          6:
            output_acc(o, acc._0);
            return Curry2._1(acc._1, o);
          case /* Acc_flush */
          7:
            output_acc(o, acc._0);
            return Caml_io.caml_ml_flush(o);
          case /* Acc_invalid_arg */
          8:
            output_acc(o, acc._0);
            throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
              MEL_EXN_ID: "Invalid_argument",
              _1: acc._1
            });
        }
        switch (exit) {
          case 1:
            output_acc(o, acc._0);
            return Stdlib.output_string(o, acc._1);
          case 2:
            output_acc(o, acc._0);
            return Caml_io.caml_ml_output_char(o, acc._1);
        }
      }
      ;
    }
    function bufput_acc(b, _acc) {
      while (true) {
        const acc = _acc;
        let exit = 0;
        if (
          /* tag */
          typeof acc === "number" || typeof acc === "string"
        ) {
          return;
        }
        switch (acc.TAG) {
          case /* Acc_formatting_lit */
          0:
            const s = string_of_formatting_lit(acc._1);
            bufput_acc(b, acc._0);
            return Stdlib__Buffer.add_string(b, s);
          case /* Acc_formatting_gen */
          1:
            const acc$p = acc._1;
            const p = acc._0;
            if (acc$p.TAG === /* Acc_open_tag */
            0) {
              bufput_acc(b, p);
              Stdlib__Buffer.add_string(b, "@{");
              _acc = acc$p._0;
              continue;
            }
            bufput_acc(b, p);
            Stdlib__Buffer.add_string(b, "@[");
            _acc = acc$p._0;
            continue;
          case /* Acc_string_literal */
          2:
          case /* Acc_data_string */
          4:
            exit = 1;
            break;
          case /* Acc_char_literal */
          3:
          case /* Acc_data_char */
          5:
            exit = 2;
            break;
          case /* Acc_delay */
          6:
            bufput_acc(b, acc._0);
            return Curry2._1(acc._1, b);
          case /* Acc_flush */
          7:
            _acc = acc._0;
            continue;
          case /* Acc_invalid_arg */
          8:
            bufput_acc(b, acc._0);
            throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
              MEL_EXN_ID: "Invalid_argument",
              _1: acc._1
            });
        }
        switch (exit) {
          case 1:
            bufput_acc(b, acc._0);
            return Stdlib__Buffer.add_string(b, acc._1);
          case 2:
            bufput_acc(b, acc._0);
            return Stdlib__Buffer.add_char(b, acc._1);
        }
      }
      ;
    }
    function strput_acc(b, _acc) {
      while (true) {
        const acc = _acc;
        let exit = 0;
        if (
          /* tag */
          typeof acc === "number" || typeof acc === "string"
        ) {
          return;
        }
        switch (acc.TAG) {
          case /* Acc_formatting_lit */
          0:
            const s = string_of_formatting_lit(acc._1);
            strput_acc(b, acc._0);
            return Stdlib__Buffer.add_string(b, s);
          case /* Acc_formatting_gen */
          1:
            const acc$p = acc._1;
            const p = acc._0;
            if (acc$p.TAG === /* Acc_open_tag */
            0) {
              strput_acc(b, p);
              Stdlib__Buffer.add_string(b, "@{");
              _acc = acc$p._0;
              continue;
            }
            strput_acc(b, p);
            Stdlib__Buffer.add_string(b, "@[");
            _acc = acc$p._0;
            continue;
          case /* Acc_string_literal */
          2:
          case /* Acc_data_string */
          4:
            exit = 1;
            break;
          case /* Acc_char_literal */
          3:
          case /* Acc_data_char */
          5:
            exit = 2;
            break;
          case /* Acc_delay */
          6:
            strput_acc(b, acc._0);
            return Stdlib__Buffer.add_string(b, Curry2._1(acc._1, void 0));
          case /* Acc_flush */
          7:
            _acc = acc._0;
            continue;
          case /* Acc_invalid_arg */
          8:
            strput_acc(b, acc._0);
            throw new Caml_js_exceptions.MelangeError("Invalid_argument", {
              MEL_EXN_ID: "Invalid_argument",
              _1: acc._1
            });
        }
        switch (exit) {
          case 1:
            strput_acc(b, acc._0);
            return Stdlib__Buffer.add_string(b, acc._1);
          case 2:
            strput_acc(b, acc._0);
            return Stdlib__Buffer.add_char(b, acc._1);
        }
      }
      ;
    }
    function failwith_message(param) {
      const buf = Stdlib__Buffer.create(256);
      const k = function(acc) {
        strput_acc(buf, acc);
        const s = Stdlib__Buffer.contents(buf);
        throw new Caml_js_exceptions.MelangeError("Failure", {
          MEL_EXN_ID: "Failure",
          _1: s
        });
      };
      return make_printf(
        k,
        /* End_of_acc */
        0,
        param._0
      );
    }
    function open_box_of_string(str) {
      if (str === "") {
        return [
          0,
          /* Pp_box */
          4
        ];
      }
      const len = str.length;
      const invalid_box = function(param) {
        return Curry2._1(failwith_message({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "invalid box description ",
            _1: {
              TAG: (
                /* Caml_string */
                3
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: (
                /* End_of_format */
                0
              )
            }
          },
          _1: "invalid box description %S"
        }), str);
      };
      const parse_spaces = function(_i) {
        while (true) {
          const i = _i;
          if (i === len) {
            return i;
          }
          const match = Caml_string.get(str, i);
          if (match !== 9) {
            if (match !== 32) {
              return i;
            }
            _i = i + 1 | 0;
            continue;
          }
          _i = i + 1 | 0;
          continue;
        }
        ;
      };
      const parse_lword = function(i, _j) {
        while (true) {
          const j = _j;
          if (j === len) {
            return j;
          }
          const match = Caml_string.get(str, j);
          if (match > 122 || match < 97) {
            return j;
          }
          _j = j + 1 | 0;
          continue;
        }
        ;
      };
      const parse_int = function(i, _j) {
        while (true) {
          const j = _j;
          if (j === len) {
            return j;
          }
          const match = Caml_string.get(str, j);
          if (match >= 48) {
            if (match >= 58) {
              return j;
            }
            _j = j + 1 | 0;
            continue;
          }
          if (match !== 45) {
            return j;
          }
          _j = j + 1 | 0;
          continue;
        }
        ;
      };
      const wstart = parse_spaces(0);
      const wend = parse_lword(wstart, wstart);
      const box_name = Stdlib__String2.sub(str, wstart, wend - wstart | 0);
      const nstart = parse_spaces(wend);
      const nend = parse_int(nstart, nstart);
      let indent;
      if (nstart === nend) {
        indent = 0;
      } else {
        try {
          indent = Caml_format.caml_int_of_string(Stdlib__String2.sub(str, nstart, nend - nstart | 0));
        } catch (raw_exn) {
          const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
          if (exn.MEL_EXN_ID === Stdlib.Failure) {
            indent = invalid_box(void 0);
          } else {
            throw exn;
          }
        }
      }
      const exp_end = parse_spaces(nend);
      if (exp_end !== len) {
        invalid_box(void 0);
      }
      let box_type;
      switch (box_name) {
        case "":
        case "b":
          box_type = /* Pp_box */
          4;
          break;
        case "h":
          box_type = /* Pp_hbox */
          0;
          break;
        case "hov":
          box_type = /* Pp_hovbox */
          3;
          break;
        case "hv":
          box_type = /* Pp_hvbox */
          2;
          break;
        case "v":
          box_type = /* Pp_vbox */
          1;
          break;
        default:
          box_type = invalid_box(void 0);
      }
      return [
        indent,
        box_type
      ];
    }
    function make_padding_fmt_ebb(pad, fmt) {
      if (
        /* tag */
        typeof pad === "number" || typeof pad === "string"
      ) {
        return {
          TAG: (
            /* Padding_fmt_EBB */
            0
          ),
          _0: (
            /* No_padding */
            0
          ),
          _1: fmt
        };
      } else if (pad.TAG === /* Lit_padding */
      0) {
        return {
          TAG: (
            /* Padding_fmt_EBB */
            0
          ),
          _0: {
            TAG: (
              /* Lit_padding */
              0
            ),
            _0: pad._0,
            _1: pad._1
          },
          _1: fmt
        };
      } else {
        return {
          TAG: (
            /* Padding_fmt_EBB */
            0
          ),
          _0: {
            TAG: (
              /* Arg_padding */
              1
            ),
            _0: pad._0
          },
          _1: fmt
        };
      }
    }
    function make_precision_fmt_ebb(prec, fmt) {
      if (
        /* tag */
        typeof prec === "number" || typeof prec === "string"
      ) {
        if (prec === /* No_precision */
        0) {
          return {
            TAG: (
              /* Precision_fmt_EBB */
              0
            ),
            _0: (
              /* No_precision */
              0
            ),
            _1: fmt
          };
        } else {
          return {
            TAG: (
              /* Precision_fmt_EBB */
              0
            ),
            _0: (
              /* Arg_precision */
              1
            ),
            _1: fmt
          };
        }
      } else {
        return {
          TAG: (
            /* Precision_fmt_EBB */
            0
          ),
          _0: {
            TAG: (
              /* Lit_precision */
              0
            ),
            _0: prec._0
          },
          _1: fmt
        };
      }
    }
    function make_padprec_fmt_ebb(pad, prec, fmt) {
      const match = make_precision_fmt_ebb(prec, fmt);
      const fmt$p = match._1;
      const prec$1 = match._0;
      if (
        /* tag */
        typeof pad === "number" || typeof pad === "string"
      ) {
        return {
          TAG: (
            /* Padprec_fmt_EBB */
            0
          ),
          _0: (
            /* No_padding */
            0
          ),
          _1: prec$1,
          _2: fmt$p
        };
      } else if (pad.TAG === /* Lit_padding */
      0) {
        return {
          TAG: (
            /* Padprec_fmt_EBB */
            0
          ),
          _0: {
            TAG: (
              /* Lit_padding */
              0
            ),
            _0: pad._0,
            _1: pad._1
          },
          _1: prec$1,
          _2: fmt$p
        };
      } else {
        return {
          TAG: (
            /* Padprec_fmt_EBB */
            0
          ),
          _0: {
            TAG: (
              /* Arg_padding */
              1
            ),
            _0: pad._0
          },
          _1: prec$1,
          _2: fmt$p
        };
      }
    }
    function fmt_ebb_of_string(legacy_behavior, str) {
      const legacy_behavior$1 = legacy_behavior !== void 0 ? legacy_behavior : true;
      const invalid_format_message = function(str_ind, msg) {
        return Curry2._3(failwith_message({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "invalid format ",
            _1: {
              TAG: (
                /* Caml_string */
                3
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: ": at character number ",
                _1: {
                  TAG: (
                    /* Int */
                    4
                  ),
                  _0: (
                    /* Int_d */
                    0
                  ),
                  _1: (
                    /* No_padding */
                    0
                  ),
                  _2: (
                    /* No_precision */
                    0
                  ),
                  _3: {
                    TAG: (
                      /* String_literal */
                      11
                    ),
                    _0: ", ",
                    _1: {
                      TAG: (
                        /* String */
                        2
                      ),
                      _0: (
                        /* No_padding */
                        0
                      ),
                      _1: (
                        /* End_of_format */
                        0
                      )
                    }
                  }
                }
              }
            }
          },
          _1: "invalid format %S: at character number %d, %s"
        }), str, str_ind, msg);
      };
      const invalid_format_without = function(str_ind, c, s) {
        return Curry2._4(failwith_message({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "invalid format ",
            _1: {
              TAG: (
                /* Caml_string */
                3
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: ": at character number ",
                _1: {
                  TAG: (
                    /* Int */
                    4
                  ),
                  _0: (
                    /* Int_d */
                    0
                  ),
                  _1: (
                    /* No_padding */
                    0
                  ),
                  _2: (
                    /* No_precision */
                    0
                  ),
                  _3: {
                    TAG: (
                      /* String_literal */
                      11
                    ),
                    _0: ", '",
                    _1: {
                      TAG: (
                        /* Char */
                        0
                      ),
                      _0: {
                        TAG: (
                          /* String_literal */
                          11
                        ),
                        _0: "' without ",
                        _1: {
                          TAG: (
                            /* String */
                            2
                          ),
                          _0: (
                            /* No_padding */
                            0
                          ),
                          _1: (
                            /* End_of_format */
                            0
                          )
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          _1: "invalid format %S: at character number %d, '%c' without %s"
        }), str, str_ind, c, s);
      };
      const expected_character = function(str_ind, expected, read) {
        return Curry2._4(failwith_message({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "invalid format ",
            _1: {
              TAG: (
                /* Caml_string */
                3
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: ": at character number ",
                _1: {
                  TAG: (
                    /* Int */
                    4
                  ),
                  _0: (
                    /* Int_d */
                    0
                  ),
                  _1: (
                    /* No_padding */
                    0
                  ),
                  _2: (
                    /* No_precision */
                    0
                  ),
                  _3: {
                    TAG: (
                      /* String_literal */
                      11
                    ),
                    _0: ", ",
                    _1: {
                      TAG: (
                        /* String */
                        2
                      ),
                      _0: (
                        /* No_padding */
                        0
                      ),
                      _1: {
                        TAG: (
                          /* String_literal */
                          11
                        ),
                        _0: " expected, read ",
                        _1: {
                          TAG: (
                            /* Caml_char */
                            1
                          ),
                          _0: (
                            /* End_of_format */
                            0
                          )
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          _1: "invalid format %S: at character number %d, %s expected, read %C"
        }), str, str_ind, expected, read);
      };
      const parse_tag = function(is_open_tag, str_ind, end_ind) {
        try {
          if (str_ind === end_ind) {
            throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
              MEL_EXN_ID: Stdlib.Not_found
            });
          }
          const match = Caml_string.get(str, str_ind);
          if (match !== 60) {
            throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
              MEL_EXN_ID: Stdlib.Not_found
            });
          }
          const ind = Stdlib__String2.index_from(
            str,
            str_ind + 1 | 0,
            /* '>' */
            62
          );
          if (ind >= end_ind) {
            throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
              MEL_EXN_ID: Stdlib.Not_found
            });
          }
          const sub_str = Stdlib__String2.sub(str, str_ind, (ind - str_ind | 0) + 1 | 0);
          const beg_ind = ind + 1 | 0;
          const fmt_rest = parse_literal(beg_ind, beg_ind, end_ind);
          const sub_fmt = parse_literal(str_ind, str_ind, ind + 1 | 0);
          const sub_format_0 = sub_fmt._0;
          const sub_format = {
            TAG: (
              /* Format */
              0
            ),
            _0: sub_format_0,
            _1: sub_str
          };
          const formatting = is_open_tag ? {
            TAG: (
              /* Open_tag */
              0
            ),
            _0: sub_format
          } : {
            TAG: (
              /* Open_box */
              1
            ),
            _0: sub_format
          };
          return {
            TAG: (
              /* Fmt_EBB */
              0
            ),
            _0: {
              TAG: (
                /* Formatting_gen */
                18
              ),
              _0: formatting,
              _1: fmt_rest._0
            }
          };
        } catch (raw_exn) {
          const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
          if (exn.MEL_EXN_ID === Stdlib.Not_found) {
            const fmt_rest$1 = parse_literal(str_ind, str_ind, end_ind);
            const sub_format$1 = {
              TAG: (
                /* Format */
                0
              ),
              _0: (
                /* End_of_format */
                0
              ),
              _1: ""
            };
            const formatting$1 = is_open_tag ? {
              TAG: (
                /* Open_tag */
                0
              ),
              _0: sub_format$1
            } : {
              TAG: (
                /* Open_box */
                1
              ),
              _0: sub_format$1
            };
            return {
              TAG: (
                /* Fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Formatting_gen */
                  18
                ),
                _0: formatting$1,
                _1: fmt_rest$1._0
              }
            };
          }
          throw exn;
        }
      };
      const parse_literal = function(lit_start, _str_ind, end_ind) {
        while (true) {
          const str_ind = _str_ind;
          if (str_ind === end_ind) {
            return add_literal(
              lit_start,
              str_ind,
              /* End_of_format */
              0
            );
          }
          const match = Caml_string.get(str, str_ind);
          if (match !== 37) {
            if (match !== 64) {
              _str_ind = str_ind + 1 | 0;
              continue;
            }
            const fmt_rest = parse_after_at(str_ind + 1 | 0, end_ind);
            return add_literal(lit_start, str_ind, fmt_rest._0);
          }
          const fmt_rest$1 = parse_format(str_ind, end_ind);
          return add_literal(lit_start, str_ind, fmt_rest$1._0);
        }
        ;
      };
      const incompatible_flag = function(pct_ind, str_ind, symb, option) {
        const subfmt = Stdlib__String2.sub(str, pct_ind, str_ind - pct_ind | 0);
        return Curry2._5(failwith_message({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "invalid format ",
            _1: {
              TAG: (
                /* Caml_string */
                3
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: ": at character number ",
                _1: {
                  TAG: (
                    /* Int */
                    4
                  ),
                  _0: (
                    /* Int_d */
                    0
                  ),
                  _1: (
                    /* No_padding */
                    0
                  ),
                  _2: (
                    /* No_precision */
                    0
                  ),
                  _3: {
                    TAG: (
                      /* String_literal */
                      11
                    ),
                    _0: ", ",
                    _1: {
                      TAG: (
                        /* String */
                        2
                      ),
                      _0: (
                        /* No_padding */
                        0
                      ),
                      _1: {
                        TAG: (
                          /* String_literal */
                          11
                        ),
                        _0: " is incompatible with '",
                        _1: {
                          TAG: (
                            /* Char */
                            0
                          ),
                          _0: {
                            TAG: (
                              /* String_literal */
                              11
                            ),
                            _0: "' in sub-format ",
                            _1: {
                              TAG: (
                                /* Caml_string */
                                3
                              ),
                              _0: (
                                /* No_padding */
                                0
                              ),
                              _1: (
                                /* End_of_format */
                                0
                              )
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          _1: "invalid format %S: at character number %d, %s is incompatible with '%c' in sub-format %S"
        }), str, pct_ind, option, symb, subfmt);
      };
      const compute_int_conv = function(pct_ind, str_ind, _plus, _hash, _space, symb) {
        while (true) {
          const space = _space;
          const hash = _hash;
          const plus = _plus;
          let exit = 0;
          if (plus) {
            if (hash) {
              exit = 2;
            } else if (!space) {
              if (symb === 100) {
                return (
                  /* Int_pd */
                  1
                );
              }
              if (symb === 105) {
                return (
                  /* Int_pi */
                  4
                );
              }
            }
          } else if (hash) {
            if (space) {
              exit = 2;
            } else {
              switch (symb) {
                case 88:
                  return (
                    /* Int_CX */
                    9
                  );
                case 100:
                  return (
                    /* Int_Cd */
                    13
                  );
                case 105:
                  return (
                    /* Int_Ci */
                    14
                  );
                case 111:
                  return (
                    /* Int_Co */
                    11
                  );
                case 117:
                  return (
                    /* Int_Cu */
                    15
                  );
                case 120:
                  return (
                    /* Int_Cx */
                    7
                  );
                default:
                  exit = 2;
              }
            }
          } else if (space) {
            if (symb === 100) {
              return (
                /* Int_sd */
                2
              );
            }
            if (symb === 105) {
              return (
                /* Int_si */
                5
              );
            }
          } else {
            switch (symb) {
              case 88:
                return (
                  /* Int_X */
                  8
                );
              case 100:
                return (
                  /* Int_d */
                  0
                );
              case 105:
                return (
                  /* Int_i */
                  3
                );
              case 111:
                return (
                  /* Int_o */
                  10
                );
              case 117:
                return (
                  /* Int_u */
                  12
                );
              case 120:
                return (
                  /* Int_x */
                  6
                );
            }
          }
          if (exit === 2) {
            let exit$1 = 0;
            switch (symb) {
              case 88:
                if (legacy_behavior$1) {
                  return (
                    /* Int_CX */
                    9
                  );
                }
                break;
              case 111:
                if (legacy_behavior$1) {
                  return (
                    /* Int_Co */
                    11
                  );
                }
                break;
              case 100:
              case 105:
              case 117:
                exit$1 = 3;
                break;
              case 120:
                if (legacy_behavior$1) {
                  return (
                    /* Int_Cx */
                    7
                  );
                }
                break;
            }
            if (exit$1 === 3) {
              if (!legacy_behavior$1) {
                return incompatible_flag(pct_ind, str_ind, symb, "'#'");
              }
              _hash = false;
              continue;
            }
          }
          if (plus) {
            if (space) {
              if (!legacy_behavior$1) {
                return incompatible_flag(
                  pct_ind,
                  str_ind,
                  /* ' ' */
                  32,
                  "'+'"
                );
              }
              _space = false;
              continue;
            }
            if (!legacy_behavior$1) {
              return incompatible_flag(pct_ind, str_ind, symb, "'+'");
            }
            _plus = false;
            continue;
          }
          if (space) {
            if (!legacy_behavior$1) {
              return incompatible_flag(pct_ind, str_ind, symb, "' '");
            }
            _space = false;
            continue;
          }
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              2938,
              28
            ]
          });
        }
        ;
      };
      const counter_of_char = function(symb) {
        if (symb >= 108) {
          if (symb < 111) {
            switch (symb) {
              case 108:
                return (
                  /* Line_counter */
                  0
                );
              case 109:
                break;
              case 110:
                return (
                  /* Char_counter */
                  1
                );
            }
          }
        } else if (symb === 76) {
          return (
            /* Token_counter */
            2
          );
        }
        throw new Caml_js_exceptions.MelangeError("Assert_failure", {
          MEL_EXN_ID: "Assert_failure",
          _1: [
            "camlinternalFormat.cppo.ml",
            2902,
            34
          ]
        });
      };
      const search_subformat_end = function(_str_ind, end_ind, c) {
        while (true) {
          const str_ind = _str_ind;
          if (str_ind === end_ind) {
            Curry2._3(failwith_message({
              TAG: (
                /* Format */
                0
              ),
              _0: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: "invalid format ",
                _1: {
                  TAG: (
                    /* Caml_string */
                    3
                  ),
                  _0: (
                    /* No_padding */
                    0
                  ),
                  _1: {
                    TAG: (
                      /* String_literal */
                      11
                    ),
                    _0: ': unclosed sub-format, expected "',
                    _1: {
                      TAG: (
                        /* Char_literal */
                        12
                      ),
                      _0: (
                        /* '%' */
                        37
                      ),
                      _1: {
                        TAG: (
                          /* Char */
                          0
                        ),
                        _0: {
                          TAG: (
                            /* String_literal */
                            11
                          ),
                          _0: '" at character number ',
                          _1: {
                            TAG: (
                              /* Int */
                              4
                            ),
                            _0: (
                              /* Int_d */
                              0
                            ),
                            _1: (
                              /* No_padding */
                              0
                            ),
                            _2: (
                              /* No_precision */
                              0
                            ),
                            _3: (
                              /* End_of_format */
                              0
                            )
                          }
                        }
                      }
                    }
                  }
                }
              },
              _1: 'invalid format %S: unclosed sub-format, expected "%%%c" at character number %d'
            }), str, c, end_ind);
          }
          const match = Caml_string.get(str, str_ind);
          if (match !== 37) {
            _str_ind = str_ind + 1 | 0;
            continue;
          }
          if ((str_ind + 1 | 0) === end_ind) {
            invalid_format_message(end_ind, "unexpected end of format");
          }
          if (Caml_string.get(str, str_ind + 1 | 0) === c) {
            return str_ind;
          }
          const match$1 = Caml_string.get(str, str_ind + 1 | 0);
          if (match$1 >= 95) {
            if (match$1 >= 123) {
              if (match$1 < 126) {
                switch (match$1) {
                  case 123:
                    const sub_end = search_subformat_end(
                      str_ind + 2 | 0,
                      end_ind,
                      /* '}' */
                      125
                    );
                    _str_ind = sub_end + 2 | 0;
                    continue;
                  case 124:
                    break;
                  case 125:
                    return expected_character(
                      str_ind + 1 | 0,
                      "character ')'",
                      /* '}' */
                      125
                    );
                }
              }
            } else if (match$1 < 96) {
              if ((str_ind + 2 | 0) === end_ind) {
                invalid_format_message(end_ind, "unexpected end of format");
              }
              const match$2 = Caml_string.get(str, str_ind + 2 | 0);
              if (match$2 !== 40) {
                if (match$2 !== 123) {
                  _str_ind = str_ind + 3 | 0;
                  continue;
                }
                const sub_end$1 = search_subformat_end(
                  str_ind + 3 | 0,
                  end_ind,
                  /* '}' */
                  125
                );
                _str_ind = sub_end$1 + 2 | 0;
                continue;
              }
              const sub_end$2 = search_subformat_end(
                str_ind + 3 | 0,
                end_ind,
                /* ')' */
                41
              );
              _str_ind = sub_end$2 + 2 | 0;
              continue;
            }
          } else if (match$1 !== 40) {
            if (match$1 === 41) {
              return expected_character(
                str_ind + 1 | 0,
                "character '}'",
                /* ')' */
                41
              );
            }
          } else {
            const sub_end$3 = search_subformat_end(
              str_ind + 2 | 0,
              end_ind,
              /* ')' */
              41
            );
            _str_ind = sub_end$3 + 2 | 0;
            continue;
          }
          _str_ind = str_ind + 2 | 0;
          continue;
        }
        ;
      };
      const compute_float_conv = function(pct_ind, str_ind, plus, hash, space, symb) {
        const flag = plus ? space && !legacy_behavior$1 ? incompatible_flag(
          pct_ind,
          str_ind,
          /* ' ' */
          32,
          "'+'"
        ) : (
          /* Float_flag_p */
          1
        ) : space ? (
          /* Float_flag_s */
          2
        ) : (
          /* Float_flag_ */
          0
        );
        let kind;
        let exit = 0;
        if (symb >= 73) {
          switch (symb) {
            case 101:
              kind = /* Float_e */
              1;
              break;
            case 102:
              kind = /* Float_f */
              0;
              break;
            case 103:
              kind = /* Float_g */
              3;
              break;
            case 104:
              kind = /* Float_h */
              6;
              break;
            default:
              exit = 1;
          }
        } else if (symb >= 69) {
          switch (symb) {
            case 69:
              kind = /* Float_E */
              2;
              break;
            case 70:
              exit = 1;
              break;
            case 71:
              kind = /* Float_G */
              4;
              break;
            case 72:
              kind = /* Float_H */
              7;
              break;
          }
        } else {
          exit = 1;
        }
        if (exit === 1) {
          if (hash) {
            if (symb !== 70) {
              throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                MEL_EXN_ID: "Assert_failure",
                _1: [
                  "camlinternalFormat.cppo.ml",
                  2960,
                  11
                ]
              });
            }
            kind = /* Float_CF */
            8;
          } else {
            if (symb !== 70) {
              throw new Caml_js_exceptions.MelangeError("Assert_failure", {
                MEL_EXN_ID: "Assert_failure",
                _1: [
                  "camlinternalFormat.cppo.ml",
                  2960,
                  11
                ]
              });
            }
            kind = /* Float_F */
            5;
          }
        }
        return [
          flag,
          kind
        ];
      };
      const parse_char_set = function(str_ind, end_ind) {
        if (str_ind === end_ind) {
          invalid_format_message(end_ind, "unexpected end of format");
        }
        const char_set = Stdlib__Bytes.make(
          32,
          /* '\000' */
          0
        );
        const add_range = function(c, c$p) {
          for (let i = c; i <= c$p; ++i) {
            add_in_char_set(char_set, Stdlib.char_of_int(i));
          }
        };
        const fail_single_percent = function(str_ind2) {
          return Curry2._2(failwith_message({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "invalid format ",
              _1: {
                TAG: (
                  /* Caml_string */
                  3
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: {
                  TAG: (
                    /* String_literal */
                    11
                  ),
                  _0: ": '",
                  _1: {
                    TAG: (
                      /* Char_literal */
                      12
                    ),
                    _0: (
                      /* '%' */
                      37
                    ),
                    _1: {
                      TAG: (
                        /* String_literal */
                        11
                      ),
                      _0: "' alone is not accepted in character sets, use ",
                      _1: {
                        TAG: (
                          /* Char_literal */
                          12
                        ),
                        _0: (
                          /* '%' */
                          37
                        ),
                        _1: {
                          TAG: (
                            /* Char_literal */
                            12
                          ),
                          _0: (
                            /* '%' */
                            37
                          ),
                          _1: {
                            TAG: (
                              /* String_literal */
                              11
                            ),
                            _0: " instead at position ",
                            _1: {
                              TAG: (
                                /* Int */
                                4
                              ),
                              _0: (
                                /* Int_d */
                                0
                              ),
                              _1: (
                                /* No_padding */
                                0
                              ),
                              _2: (
                                /* No_precision */
                                0
                              ),
                              _3: {
                                TAG: (
                                  /* Char_literal */
                                  12
                                ),
                                _0: (
                                  /* '.' */
                                  46
                                ),
                                _1: (
                                  /* End_of_format */
                                  0
                                )
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            _1: "invalid format %S: '%%' alone is not accepted in character sets, use %%%% instead at position %d."
          }), str, str_ind2);
        };
        const parse_char_set_content = function(_str_ind, end_ind2) {
          while (true) {
            const str_ind2 = _str_ind;
            if (str_ind2 === end_ind2) {
              invalid_format_message(end_ind2, "unexpected end of format");
            }
            const c = Caml_string.get(str, str_ind2);
            if (c !== 45) {
              if (c !== 93) {
                return parse_char_set_after_char(str_ind2 + 1 | 0, end_ind2, c);
              } else {
                return str_ind2 + 1 | 0;
              }
            }
            add_in_char_set(
              char_set,
              /* '-' */
              45
            );
            _str_ind = str_ind2 + 1 | 0;
            continue;
          }
          ;
        };
        const parse_char_set_after_char = function(_str_ind, end_ind2, _c) {
          while (true) {
            const c = _c;
            const str_ind2 = _str_ind;
            if (str_ind2 === end_ind2) {
              invalid_format_message(end_ind2, "unexpected end of format");
            }
            const c$p = Caml_string.get(str, str_ind2);
            let exit = 0;
            if (c$p >= 46) {
              if (c$p !== 64) {
                if (c$p === 93) {
                  add_in_char_set(char_set, c);
                  return str_ind2 + 1 | 0;
                }
              } else {
                exit = 2;
              }
            } else if (c$p !== 37) {
              if (c$p >= 45) {
                let str_ind$1 = str_ind2 + 1 | 0;
                if (str_ind$1 === end_ind2) {
                  invalid_format_message(end_ind2, "unexpected end of format");
                }
                const c$p$1 = Caml_string.get(str, str_ind$1);
                if (c$p$1 !== 37) {
                  if (c$p$1 !== 93) {
                    add_range(c, c$p$1);
                    return parse_char_set_content(str_ind$1 + 1 | 0, end_ind2);
                  } else {
                    add_in_char_set(char_set, c);
                    add_in_char_set(
                      char_set,
                      /* '-' */
                      45
                    );
                    return str_ind$1 + 1 | 0;
                  }
                }
                if ((str_ind$1 + 1 | 0) === end_ind2) {
                  invalid_format_message(end_ind2, "unexpected end of format");
                }
                const c$p$2 = Caml_string.get(str, str_ind$1 + 1 | 0);
                if (c$p$2 !== 37 && c$p$2 !== 64) {
                  return fail_single_percent(str_ind$1);
                }
                add_range(c, c$p$2);
                return parse_char_set_content(str_ind$1 + 2 | 0, end_ind2);
              }
            } else {
              exit = 2;
            }
            if (exit === 2 && c === /* '%' */
            37) {
              add_in_char_set(char_set, c$p);
              return parse_char_set_content(str_ind2 + 1 | 0, end_ind2);
            }
            if (c === /* '%' */
            37) {
              fail_single_percent(str_ind2);
            }
            add_in_char_set(char_set, c);
            _c = c$p;
            _str_ind = str_ind2 + 1 | 0;
            continue;
          }
          ;
        };
        const parse_char_set_start = function(str_ind2, end_ind2) {
          if (str_ind2 === end_ind2) {
            invalid_format_message(end_ind2, "unexpected end of format");
          }
          const c = Caml_string.get(str, str_ind2);
          return parse_char_set_after_char(str_ind2 + 1 | 0, end_ind2, c);
        };
        if (str_ind === end_ind) {
          invalid_format_message(end_ind, "unexpected end of format");
        }
        const match = Caml_string.get(str, str_ind);
        const match$1 = match !== 94 ? [
          str_ind,
          false
        ] : [
          str_ind + 1 | 0,
          true
        ];
        const next_ind = parse_char_set_start(match$1[0], end_ind);
        const char_set$1 = Stdlib__Bytes.to_string(char_set);
        return [
          next_ind,
          match$1[1] ? rev_char_set(char_set$1) : char_set$1
        ];
      };
      const is_int_base = function(symb) {
        switch (symb) {
          case 88:
          case 100:
          case 105:
          case 111:
          case 117:
          case 120:
            return true;
          default:
            return false;
        }
      };
      const parse_spaces = function(_str_ind, end_ind) {
        while (true) {
          const str_ind = _str_ind;
          if (str_ind === end_ind) {
            invalid_format_message(end_ind, "unexpected end of format");
          }
          if (Caml_string.get(str, str_ind) !== /* ' ' */
          32) {
            return str_ind;
          }
          _str_ind = str_ind + 1 | 0;
          continue;
        }
        ;
      };
      const parse_integer = function(str_ind, end_ind) {
        if (str_ind === end_ind) {
          invalid_format_message(end_ind, "unexpected end of format");
        }
        const match = Caml_string.get(str, str_ind);
        if (match >= 48) {
          if (match >= 58) {
            throw new Caml_js_exceptions.MelangeError("Assert_failure", {
              MEL_EXN_ID: "Assert_failure",
              _1: [
                "camlinternalFormat.cppo.ml",
                2840,
                11
              ]
            });
          }
          return parse_positive(str_ind, end_ind, 0);
        }
        if (match !== 45) {
          throw new Caml_js_exceptions.MelangeError("Assert_failure", {
            MEL_EXN_ID: "Assert_failure",
            _1: [
              "camlinternalFormat.cppo.ml",
              2840,
              11
            ]
          });
        }
        if ((str_ind + 1 | 0) === end_ind) {
          invalid_format_message(end_ind, "unexpected end of format");
        }
        const c = Caml_string.get(str, str_ind + 1 | 0);
        if (c > 57 || c < 48) {
          return expected_character(str_ind + 1 | 0, "digit", c);
        }
        const match$1 = parse_positive(str_ind + 1 | 0, end_ind, 0);
        return [
          match$1[0],
          -match$1[1] | 0
        ];
      };
      const parse_conversion = function(pct_ind, str_ind, end_ind, plus, hash, space, ign, pad, prec, padprec, symb) {
        let plus_used = false;
        let hash_used = false;
        let space_used = false;
        const ign_used = {
          contents: false
        };
        const pad_used = {
          contents: false
        };
        const prec_used = {
          contents: false
        };
        const get_int_pad = function(param) {
          pad_used.contents = true;
          prec_used.contents = true;
          if (
            /* tag */
            (typeof prec === "number" || typeof prec === "string") && prec === /* No_precision */
            0
          ) {
            return pad;
          }
          if (
            /* tag */
            typeof pad === "number" || typeof pad === "string"
          ) {
            return (
              /* No_padding */
              0
            );
          }
          if (pad.TAG === /* Lit_padding */
          0) {
            switch (pad._0) {
              case /* Left */
              0:
              case /* Right */
              1:
                return pad;
              case /* Zeros */
              2:
                if (legacy_behavior$1) {
                  return {
                    TAG: (
                      /* Lit_padding */
                      0
                    ),
                    _0: (
                      /* Right */
                      1
                    ),
                    _1: pad._1
                  };
                } else {
                  return incompatible_flag(
                    pct_ind,
                    str_ind,
                    /* '0' */
                    48,
                    "precision"
                  );
                }
            }
          } else {
            switch (pad._0) {
              case /* Left */
              0:
              case /* Right */
              1:
                return pad;
              case /* Zeros */
              2:
                if (legacy_behavior$1) {
                  return {
                    TAG: (
                      /* Arg_padding */
                      1
                    ),
                    _0: (
                      /* Right */
                      1
                    )
                  };
                } else {
                  return incompatible_flag(
                    pct_ind,
                    str_ind,
                    /* '0' */
                    48,
                    "precision"
                  );
                }
            }
          }
        };
        const check_no_0 = function(symb2, pad2) {
          if (
            /* tag */
            typeof pad2 === "number" || typeof pad2 === "string"
          ) {
            return pad2;
          }
          if (pad2.TAG === /* Lit_padding */
          0) {
            switch (pad2._0) {
              case /* Left */
              0:
              case /* Right */
              1:
                return pad2;
              case /* Zeros */
              2:
                if (legacy_behavior$1) {
                  return {
                    TAG: (
                      /* Lit_padding */
                      0
                    ),
                    _0: (
                      /* Right */
                      1
                    ),
                    _1: pad2._1
                  };
                } else {
                  return incompatible_flag(pct_ind, str_ind, symb2, "0");
                }
            }
          } else {
            switch (pad2._0) {
              case /* Left */
              0:
              case /* Right */
              1:
                return pad2;
              case /* Zeros */
              2:
                if (legacy_behavior$1) {
                  return {
                    TAG: (
                      /* Arg_padding */
                      1
                    ),
                    _0: (
                      /* Right */
                      1
                    )
                  };
                } else {
                  return incompatible_flag(pct_ind, str_ind, symb2, "0");
                }
            }
          }
        };
        const opt_of_pad = function(c, pad2) {
          if (
            /* tag */
            typeof pad2 === "number" || typeof pad2 === "string"
          ) {
            return;
          }
          if (pad2.TAG !== /* Lit_padding */
          0) {
            return incompatible_flag(pct_ind, str_ind, c, "'*'");
          }
          switch (pad2._0) {
            case /* Left */
            0:
              if (legacy_behavior$1) {
                return pad2._1;
              } else {
                return incompatible_flag(pct_ind, str_ind, c, "'-'");
              }
            case /* Right */
            1:
              return pad2._1;
            case /* Zeros */
            2:
              if (legacy_behavior$1) {
                return pad2._1;
              } else {
                return incompatible_flag(pct_ind, str_ind, c, "'0'");
              }
          }
        };
        const get_prec_opt = function(param) {
          prec_used.contents = true;
          if (
            /* tag */
            typeof prec === "number" || typeof prec === "string"
          ) {
            if (prec === /* No_precision */
            0) {
              return;
            } else {
              return incompatible_flag(
                pct_ind,
                str_ind,
                /* '_' */
                95,
                "'*'"
              );
            }
          } else {
            return prec._0;
          }
        };
        let fmt_result;
        let exit = 0;
        let exit$1 = 0;
        let exit$2 = 0;
        if (symb >= 124) {
          exit$1 = 6;
        } else {
          switch (symb) {
            case 33:
              const fmt_rest = parse_literal(str_ind, str_ind, end_ind);
              fmt_result = {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Flush */
                    10
                  ),
                  _0: fmt_rest._0
                }
              };
              break;
            case 40:
              const sub_end = search_subformat_end(
                str_ind,
                end_ind,
                /* ')' */
                41
              );
              const beg_ind = sub_end + 2 | 0;
              const fmt_rest$1 = parse_literal(beg_ind, beg_ind, end_ind);
              const fmt_rest$2 = fmt_rest$1._0;
              const sub_fmt = parse_literal(str_ind, str_ind, sub_end);
              const sub_fmtty = fmtty_of_fmt(sub_fmt._0);
              if (ign_used.contents = true, ign) {
                const ignored_0 = opt_of_pad(
                  /* '_' */
                  95,
                  (pad_used.contents = true, pad)
                );
                const ignored = {
                  TAG: (
                    /* Ignored_format_subst */
                    9
                  ),
                  _0: ignored_0,
                  _1: sub_fmtty
                };
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Ignored_param */
                      23
                    ),
                    _0: ignored,
                    _1: fmt_rest$2
                  }
                };
              } else {
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Format_subst */
                      14
                    ),
                    _0: opt_of_pad(
                      /* '(' */
                      40,
                      (pad_used.contents = true, pad)
                    ),
                    _1: sub_fmtty,
                    _2: fmt_rest$2
                  }
                };
              }
              break;
            case 44:
              fmt_result = parse_literal(str_ind, str_ind, end_ind);
              break;
            case 37:
            case 64:
              exit$1 = 4;
              break;
            case 67:
              const fmt_rest$3 = parse_literal(str_ind, str_ind, end_ind);
              const fmt_rest$4 = fmt_rest$3._0;
              fmt_result = (ign_used.contents = true, ign) ? {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Ignored_param */
                    23
                  ),
                  _0: (
                    /* Ignored_caml_char */
                    1
                  ),
                  _1: fmt_rest$4
                }
              } : {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Caml_char */
                    1
                  ),
                  _0: fmt_rest$4
                }
              };
              break;
            case 78:
              const fmt_rest$5 = parse_literal(str_ind, str_ind, end_ind);
              const fmt_rest$6 = fmt_rest$5._0;
              if (ign_used.contents = true, ign) {
                const ignored$1 = {
                  TAG: (
                    /* Ignored_scan_get_counter */
                    11
                  ),
                  _0: (
                    /* Token_counter */
                    2
                  )
                };
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Ignored_param */
                      23
                    ),
                    _0: ignored$1,
                    _1: fmt_rest$6
                  }
                };
              } else {
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Scan_get_counter */
                      21
                    ),
                    _0: (
                      /* Token_counter */
                      2
                    ),
                    _1: fmt_rest$6
                  }
                };
              }
              break;
            case 83:
              const pad$1 = check_no_0(symb, (pad_used.contents = true, padprec));
              const fmt_rest$7 = parse_literal(str_ind, str_ind, end_ind);
              const fmt_rest$8 = fmt_rest$7._0;
              if (ign_used.contents = true, ign) {
                const ignored$2 = {
                  TAG: (
                    /* Ignored_caml_string */
                    1
                  ),
                  _0: opt_of_pad(
                    /* '_' */
                    95,
                    (pad_used.contents = true, padprec)
                  )
                };
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Ignored_param */
                      23
                    ),
                    _0: ignored$2,
                    _1: fmt_rest$8
                  }
                };
              } else {
                const match = make_padding_fmt_ebb(pad$1, fmt_rest$8);
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Caml_string */
                      3
                    ),
                    _0: match._0,
                    _1: match._1
                  }
                };
              }
              break;
            case 91:
              const match$1 = parse_char_set(str_ind, end_ind);
              const char_set = match$1[1];
              const next_ind = match$1[0];
              const fmt_rest$9 = parse_literal(next_ind, next_ind, end_ind);
              const fmt_rest$10 = fmt_rest$9._0;
              if (ign_used.contents = true, ign) {
                const ignored_0$1 = opt_of_pad(
                  /* '_' */
                  95,
                  (pad_used.contents = true, pad)
                );
                const ignored$3 = {
                  TAG: (
                    /* Ignored_scan_char_set */
                    10
                  ),
                  _0: ignored_0$1,
                  _1: char_set
                };
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Ignored_param */
                      23
                    ),
                    _0: ignored$3,
                    _1: fmt_rest$10
                  }
                };
              } else {
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Scan_char_set */
                      20
                    ),
                    _0: opt_of_pad(
                      /* '[' */
                      91,
                      (pad_used.contents = true, pad)
                    ),
                    _1: char_set,
                    _2: fmt_rest$10
                  }
                };
              }
              break;
            case 32:
            case 35:
            case 43:
            case 45:
            case 95:
              exit$1 = 5;
              break;
            case 97:
              const fmt_rest$11 = parse_literal(str_ind, str_ind, end_ind);
              fmt_result = {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Alpha */
                    15
                  ),
                  _0: fmt_rest$11._0
                }
              };
              break;
            case 66:
            case 98:
              exit$1 = 3;
              break;
            case 99:
              const char_format = function(fmt_rest2) {
                if (ign_used.contents = true, ign) {
                  return {
                    TAG: (
                      /* Fmt_EBB */
                      0
                    ),
                    _0: {
                      TAG: (
                        /* Ignored_param */
                        23
                      ),
                      _0: (
                        /* Ignored_char */
                        0
                      ),
                      _1: fmt_rest2
                    }
                  };
                } else {
                  return {
                    TAG: (
                      /* Fmt_EBB */
                      0
                    ),
                    _0: {
                      TAG: (
                        /* Char */
                        0
                      ),
                      _0: fmt_rest2
                    }
                  };
                }
              };
              const scan_format = function(fmt_rest2) {
                if (ign_used.contents = true, ign) {
                  return {
                    TAG: (
                      /* Fmt_EBB */
                      0
                    ),
                    _0: {
                      TAG: (
                        /* Ignored_param */
                        23
                      ),
                      _0: (
                        /* Ignored_scan_next_char */
                        3
                      ),
                      _1: fmt_rest2
                    }
                  };
                } else {
                  return {
                    TAG: (
                      /* Fmt_EBB */
                      0
                    ),
                    _0: {
                      TAG: (
                        /* Scan_next_char */
                        22
                      ),
                      _0: fmt_rest2
                    }
                  };
                }
              };
              const fmt_rest$12 = parse_literal(str_ind, str_ind, end_ind);
              const fmt_rest$13 = fmt_rest$12._0;
              const _n = opt_of_pad(
                /* 'c' */
                99,
                (pad_used.contents = true, pad)
              );
              fmt_result = _n !== void 0 ? _n !== 0 ? legacy_behavior$1 ? char_format(fmt_rest$13) : invalid_format_message(str_ind, "non-zero widths are unsupported for %c conversions") : scan_format(fmt_rest$13) : char_format(fmt_rest$13);
              break;
            case 69:
            case 70:
            case 71:
            case 72:
            case 101:
            case 102:
            case 103:
            case 104:
              exit$1 = 2;
              break;
            case 76:
            case 108:
            case 110:
              exit$2 = 8;
              break;
            case 114:
              const fmt_rest$14 = parse_literal(str_ind, str_ind, end_ind);
              const fmt_rest$15 = fmt_rest$14._0;
              fmt_result = (ign_used.contents = true, ign) ? {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Ignored_param */
                    23
                  ),
                  _0: (
                    /* Ignored_reader */
                    2
                  ),
                  _1: fmt_rest$15
                }
              } : {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Reader */
                    19
                  ),
                  _0: fmt_rest$15
                }
              };
              break;
            case 115:
              const pad$2 = check_no_0(symb, (pad_used.contents = true, padprec));
              const fmt_rest$16 = parse_literal(str_ind, str_ind, end_ind);
              const fmt_rest$17 = fmt_rest$16._0;
              if (ign_used.contents = true, ign) {
                const ignored$4 = {
                  TAG: (
                    /* Ignored_string */
                    0
                  ),
                  _0: opt_of_pad(
                    /* '_' */
                    95,
                    (pad_used.contents = true, padprec)
                  )
                };
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Ignored_param */
                      23
                    ),
                    _0: ignored$4,
                    _1: fmt_rest$17
                  }
                };
              } else {
                const match$2 = make_padding_fmt_ebb(pad$2, fmt_rest$17);
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* String */
                      2
                    ),
                    _0: match$2._0,
                    _1: match$2._1
                  }
                };
              }
              break;
            case 116:
              const fmt_rest$18 = parse_literal(str_ind, str_ind, end_ind);
              fmt_result = {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Theta */
                    16
                  ),
                  _0: fmt_rest$18._0
                }
              };
              break;
            case 88:
            case 100:
            case 105:
            case 111:
            case 117:
            case 120:
              exit$2 = 7;
              break;
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
            case 6:
            case 7:
            case 8:
            case 9:
            case 10:
            case 11:
            case 12:
            case 13:
            case 14:
            case 15:
            case 16:
            case 17:
            case 18:
            case 19:
            case 20:
            case 21:
            case 22:
            case 23:
            case 24:
            case 25:
            case 26:
            case 27:
            case 28:
            case 29:
            case 30:
            case 31:
            case 34:
            case 36:
            case 38:
            case 39:
            case 41:
            case 42:
            case 46:
            case 47:
            case 48:
            case 49:
            case 50:
            case 51:
            case 52:
            case 53:
            case 54:
            case 55:
            case 56:
            case 57:
            case 58:
            case 59:
            case 60:
            case 61:
            case 62:
            case 63:
            case 65:
            case 68:
            case 73:
            case 74:
            case 75:
            case 77:
            case 79:
            case 80:
            case 81:
            case 82:
            case 84:
            case 85:
            case 86:
            case 87:
            case 89:
            case 90:
            case 92:
            case 93:
            case 94:
            case 96:
            case 106:
            case 107:
            case 109:
            case 112:
            case 113:
            case 118:
            case 119:
            case 121:
            case 122:
              exit$1 = 6;
              break;
            case 123:
              const sub_end$1 = search_subformat_end(
                str_ind,
                end_ind,
                /* '}' */
                125
              );
              const sub_fmt$1 = parse_literal(str_ind, str_ind, sub_end$1);
              const beg_ind$1 = sub_end$1 + 2 | 0;
              const fmt_rest$19 = parse_literal(beg_ind$1, beg_ind$1, end_ind);
              const fmt_rest$20 = fmt_rest$19._0;
              const sub_fmtty$1 = fmtty_of_fmt(sub_fmt$1._0);
              if (ign_used.contents = true, ign) {
                const ignored_0$2 = opt_of_pad(
                  /* '_' */
                  95,
                  (pad_used.contents = true, pad)
                );
                const ignored$5 = {
                  TAG: (
                    /* Ignored_format_arg */
                    8
                  ),
                  _0: ignored_0$2,
                  _1: sub_fmtty$1
                };
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Ignored_param */
                      23
                    ),
                    _0: ignored$5,
                    _1: fmt_rest$20
                  }
                };
              } else {
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Format_arg */
                      13
                    ),
                    _0: opt_of_pad(
                      /* '{' */
                      123,
                      (pad_used.contents = true, pad)
                    ),
                    _1: sub_fmtty$1,
                    _2: fmt_rest$20
                  }
                };
              }
              break;
          }
        }
        switch (exit$2) {
          case 7:
            plus_used = true;
            hash_used = true;
            space_used = true;
            const iconv = compute_int_conv(pct_ind, str_ind, plus, hash, space, symb);
            const fmt_rest$21 = parse_literal(str_ind, str_ind, end_ind);
            const fmt_rest$22 = fmt_rest$21._0;
            if (ign_used.contents = true, ign) {
              const ignored_1 = opt_of_pad(
                /* '_' */
                95,
                (pad_used.contents = true, pad)
              );
              const ignored$6 = {
                TAG: (
                  /* Ignored_int */
                  2
                ),
                _0: iconv,
                _1: ignored_1
              };
              fmt_result = {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Ignored_param */
                    23
                  ),
                  _0: ignored$6,
                  _1: fmt_rest$22
                }
              };
            } else {
              const match$3 = make_padprec_fmt_ebb(get_int_pad(void 0), (prec_used.contents = true, prec), fmt_rest$22);
              fmt_result = {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Int */
                    4
                  ),
                  _0: iconv,
                  _1: match$3._0,
                  _2: match$3._1,
                  _3: match$3._2
                }
              };
            }
            break;
          case 8:
            if (str_ind === end_ind || !is_int_base(Caml_string.get(str, str_ind))) {
              const fmt_rest$23 = parse_literal(str_ind, str_ind, end_ind);
              const fmt_rest$24 = fmt_rest$23._0;
              const counter = counter_of_char(symb);
              if (ign_used.contents = true, ign) {
                const ignored$7 = {
                  TAG: (
                    /* Ignored_scan_get_counter */
                    11
                  ),
                  _0: counter
                };
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Ignored_param */
                      23
                    ),
                    _0: ignored$7,
                    _1: fmt_rest$24
                  }
                };
              } else {
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Scan_get_counter */
                      21
                    ),
                    _0: counter,
                    _1: fmt_rest$24
                  }
                };
              }
            } else {
              exit$1 = 6;
            }
            break;
        }
        switch (exit$1) {
          case 2:
            plus_used = true;
            hash_used = true;
            space_used = true;
            const fconv = compute_float_conv(pct_ind, str_ind, plus, hash, space, symb);
            const fmt_rest$25 = parse_literal(str_ind, str_ind, end_ind);
            const fmt_rest$26 = fmt_rest$25._0;
            if (ign_used.contents = true, ign) {
              const ignored_0$3 = opt_of_pad(
                /* '_' */
                95,
                (pad_used.contents = true, pad)
              );
              const ignored_1$1 = get_prec_opt(void 0);
              const ignored$8 = {
                TAG: (
                  /* Ignored_float */
                  6
                ),
                _0: ignored_0$3,
                _1: ignored_1$1
              };
              fmt_result = {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Ignored_param */
                    23
                  ),
                  _0: ignored$8,
                  _1: fmt_rest$26
                }
              };
            } else {
              const match$4 = make_padprec_fmt_ebb((pad_used.contents = true, pad), (prec_used.contents = true, prec), fmt_rest$26);
              fmt_result = {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Float */
                    8
                  ),
                  _0: fconv,
                  _1: match$4._0,
                  _2: match$4._1,
                  _3: match$4._2
                }
              };
            }
            break;
          case 3:
            const pad$3 = check_no_0(symb, (pad_used.contents = true, padprec));
            const fmt_rest$27 = parse_literal(str_ind, str_ind, end_ind);
            const fmt_rest$28 = fmt_rest$27._0;
            if (ign_used.contents = true, ign) {
              const ignored$9 = {
                TAG: (
                  /* Ignored_bool */
                  7
                ),
                _0: opt_of_pad(
                  /* '_' */
                  95,
                  (pad_used.contents = true, padprec)
                )
              };
              fmt_result = {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Ignored_param */
                    23
                  ),
                  _0: ignored$9,
                  _1: fmt_rest$28
                }
              };
            } else {
              const match$5 = make_padding_fmt_ebb(pad$3, fmt_rest$28);
              fmt_result = {
                TAG: (
                  /* Fmt_EBB */
                  0
                ),
                _0: {
                  TAG: (
                    /* Bool */
                    9
                  ),
                  _0: match$5._0,
                  _1: match$5._1
                }
              };
            }
            break;
          case 4:
            const fmt_rest$29 = parse_literal(str_ind, str_ind, end_ind);
            fmt_result = {
              TAG: (
                /* Fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Char_literal */
                  12
                ),
                _0: symb,
                _1: fmt_rest$29._0
              }
            };
            break;
          case 5:
            fmt_result = Curry2._3(failwith_message({
              TAG: (
                /* Format */
                0
              ),
              _0: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: "invalid format ",
                _1: {
                  TAG: (
                    /* Caml_string */
                    3
                  ),
                  _0: (
                    /* No_padding */
                    0
                  ),
                  _1: {
                    TAG: (
                      /* String_literal */
                      11
                    ),
                    _0: ": at character number ",
                    _1: {
                      TAG: (
                        /* Int */
                        4
                      ),
                      _0: (
                        /* Int_d */
                        0
                      ),
                      _1: (
                        /* No_padding */
                        0
                      ),
                      _2: (
                        /* No_precision */
                        0
                      ),
                      _3: {
                        TAG: (
                          /* String_literal */
                          11
                        ),
                        _0: ", flag ",
                        _1: {
                          TAG: (
                            /* Caml_char */
                            1
                          ),
                          _0: {
                            TAG: (
                              /* String_literal */
                              11
                            ),
                            _0: " is only allowed after the '",
                            _1: {
                              TAG: (
                                /* Char_literal */
                                12
                              ),
                              _0: (
                                /* '%' */
                                37
                              ),
                              _1: {
                                TAG: (
                                  /* String_literal */
                                  11
                                ),
                                _0: "', before padding and precision",
                                _1: (
                                  /* End_of_format */
                                  0
                                )
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              },
              _1: "invalid format %S: at character number %d, flag %C is only allowed after the '%%', before padding and precision"
            }), str, pct_ind, symb);
            break;
          case 6:
            if (symb >= 108) {
              if (symb >= 111) {
                exit = 1;
              } else {
                switch (symb) {
                  case 108:
                    plus_used = true;
                    hash_used = true;
                    space_used = true;
                    const iconv$1 = compute_int_conv(pct_ind, str_ind + 1 | 0, plus, hash, space, Caml_string.get(str, str_ind));
                    const beg_ind$2 = str_ind + 1 | 0;
                    const fmt_rest$30 = parse_literal(beg_ind$2, beg_ind$2, end_ind);
                    const fmt_rest$31 = fmt_rest$30._0;
                    if (ign_used.contents = true, ign) {
                      const ignored_1$2 = opt_of_pad(
                        /* '_' */
                        95,
                        (pad_used.contents = true, pad)
                      );
                      const ignored$10 = {
                        TAG: (
                          /* Ignored_int32 */
                          3
                        ),
                        _0: iconv$1,
                        _1: ignored_1$2
                      };
                      fmt_result = {
                        TAG: (
                          /* Fmt_EBB */
                          0
                        ),
                        _0: {
                          TAG: (
                            /* Ignored_param */
                            23
                          ),
                          _0: ignored$10,
                          _1: fmt_rest$31
                        }
                      };
                    } else {
                      const match$6 = make_padprec_fmt_ebb(get_int_pad(void 0), (prec_used.contents = true, prec), fmt_rest$31);
                      fmt_result = {
                        TAG: (
                          /* Fmt_EBB */
                          0
                        ),
                        _0: {
                          TAG: (
                            /* Int32 */
                            5
                          ),
                          _0: iconv$1,
                          _1: match$6._0,
                          _2: match$6._1,
                          _3: match$6._2
                        }
                      };
                    }
                    break;
                  case 109:
                    exit = 1;
                    break;
                  case 110:
                    plus_used = true;
                    hash_used = true;
                    space_used = true;
                    const iconv$2 = compute_int_conv(pct_ind, str_ind + 1 | 0, plus, hash, space, Caml_string.get(str, str_ind));
                    const beg_ind$3 = str_ind + 1 | 0;
                    const fmt_rest$32 = parse_literal(beg_ind$3, beg_ind$3, end_ind);
                    const fmt_rest$33 = fmt_rest$32._0;
                    if (ign_used.contents = true, ign) {
                      const ignored_1$3 = opt_of_pad(
                        /* '_' */
                        95,
                        (pad_used.contents = true, pad)
                      );
                      const ignored$11 = {
                        TAG: (
                          /* Ignored_nativeint */
                          4
                        ),
                        _0: iconv$2,
                        _1: ignored_1$3
                      };
                      fmt_result = {
                        TAG: (
                          /* Fmt_EBB */
                          0
                        ),
                        _0: {
                          TAG: (
                            /* Ignored_param */
                            23
                          ),
                          _0: ignored$11,
                          _1: fmt_rest$33
                        }
                      };
                    } else {
                      const match$7 = make_padprec_fmt_ebb(get_int_pad(void 0), (prec_used.contents = true, prec), fmt_rest$33);
                      fmt_result = {
                        TAG: (
                          /* Fmt_EBB */
                          0
                        ),
                        _0: {
                          TAG: (
                            /* Nativeint */
                            6
                          ),
                          _0: iconv$2,
                          _1: match$7._0,
                          _2: match$7._1,
                          _3: match$7._2
                        }
                      };
                    }
                    break;
                }
              }
            } else if (symb !== 76) {
              exit = 1;
            } else {
              plus_used = true;
              hash_used = true;
              space_used = true;
              const iconv$3 = compute_int_conv(pct_ind, str_ind + 1 | 0, plus, hash, space, Caml_string.get(str, str_ind));
              const beg_ind$4 = str_ind + 1 | 0;
              const fmt_rest$34 = parse_literal(beg_ind$4, beg_ind$4, end_ind);
              const fmt_rest$35 = fmt_rest$34._0;
              if (ign_used.contents = true, ign) {
                const ignored_1$4 = opt_of_pad(
                  /* '_' */
                  95,
                  (pad_used.contents = true, pad)
                );
                const ignored$12 = {
                  TAG: (
                    /* Ignored_int64 */
                    5
                  ),
                  _0: iconv$3,
                  _1: ignored_1$4
                };
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Ignored_param */
                      23
                    ),
                    _0: ignored$12,
                    _1: fmt_rest$35
                  }
                };
              } else {
                const match$8 = make_padprec_fmt_ebb(get_int_pad(void 0), (prec_used.contents = true, prec), fmt_rest$35);
                fmt_result = {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Int64 */
                      7
                    ),
                    _0: iconv$3,
                    _1: match$8._0,
                    _2: match$8._1,
                    _3: match$8._2
                  }
                };
              }
            }
            break;
        }
        if (exit === 1) {
          fmt_result = Curry2._3(failwith_message({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "invalid format ",
              _1: {
                TAG: (
                  /* Caml_string */
                  3
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: {
                  TAG: (
                    /* String_literal */
                    11
                  ),
                  _0: ": at character number ",
                  _1: {
                    TAG: (
                      /* Int */
                      4
                    ),
                    _0: (
                      /* Int_d */
                      0
                    ),
                    _1: (
                      /* No_padding */
                      0
                    ),
                    _2: (
                      /* No_precision */
                      0
                    ),
                    _3: {
                      TAG: (
                        /* String_literal */
                        11
                      ),
                      _0: ', invalid conversion "',
                      _1: {
                        TAG: (
                          /* Char_literal */
                          12
                        ),
                        _0: (
                          /* '%' */
                          37
                        ),
                        _1: {
                          TAG: (
                            /* Char */
                            0
                          ),
                          _0: {
                            TAG: (
                              /* Char_literal */
                              12
                            ),
                            _0: (
                              /* '"' */
                              34
                            ),
                            _1: (
                              /* End_of_format */
                              0
                            )
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            _1: 'invalid format %S: at character number %d, invalid conversion "%%%c"'
          }), str, str_ind - 1 | 0, symb);
        }
        if (!legacy_behavior$1) {
          if (!plus_used && plus) {
            incompatible_flag(pct_ind, str_ind, symb, "'+'");
          }
          if (!hash_used && hash) {
            incompatible_flag(pct_ind, str_ind, symb, "'#'");
          }
          if (!space_used && space) {
            incompatible_flag(pct_ind, str_ind, symb, "' '");
          }
          if (!pad_used.contents && Caml_obj.caml_notequal({
            TAG: (
              /* Padding_EBB */
              0
            ),
            _0: pad
          }, {
            TAG: (
              /* Padding_EBB */
              0
            ),
            _0: (
              /* No_padding */
              0
            )
          })) {
            incompatible_flag(pct_ind, str_ind, symb, "`padding'");
          }
          if (!prec_used.contents && Caml_obj.caml_notequal({
            TAG: (
              /* Precision_EBB */
              0
            ),
            _0: prec
          }, {
            TAG: (
              /* Precision_EBB */
              0
            ),
            _0: (
              /* No_precision */
              0
            )
          })) {
            incompatible_flag(pct_ind, str_ind, ign ? (
              /* '_' */
              95
            ) : symb, "`precision'");
          }
          if (ign && plus) {
            incompatible_flag(
              pct_ind,
              str_ind,
              /* '_' */
              95,
              "'+'"
            );
          }
        }
        if (!ign_used.contents && ign) {
          let exit$3 = 0;
          if (symb >= 38) {
            if (symb !== 44) {
              if (symb !== 64 || !legacy_behavior$1) {
                exit$3 = 1;
              }
            } else if (!legacy_behavior$1) {
              exit$3 = 1;
            }
          } else if (symb !== 33) {
            if (!(symb >= 37 && legacy_behavior$1)) {
              exit$3 = 1;
            }
          } else if (!legacy_behavior$1) {
            exit$3 = 1;
          }
          if (exit$3 === 1) {
            incompatible_flag(pct_ind, str_ind, symb, "'_'");
          }
        }
        return fmt_result;
      };
      const parse_positive = function(_str_ind, end_ind, _acc) {
        while (true) {
          const acc = _acc;
          const str_ind = _str_ind;
          if (str_ind === end_ind) {
            invalid_format_message(end_ind, "unexpected end of format");
          }
          const c = Caml_string.get(str, str_ind);
          if (c > 57 || c < 48) {
            return [
              str_ind,
              acc
            ];
          }
          const new_acc = Math.imul(acc, 10) + (c - /* '0' */
          48 | 0) | 0;
          _acc = new_acc;
          _str_ind = str_ind + 1 | 0;
          continue;
        }
        ;
      };
      const parse_after_precision = function(pct_ind, str_ind, end_ind, minus, plus, hash, space, ign, pad, prec) {
        if (str_ind === end_ind) {
          invalid_format_message(end_ind, "unexpected end of format");
        }
        const parse_conv = function(padprec) {
          return parse_conversion(pct_ind, str_ind + 1 | 0, end_ind, plus, hash, space, ign, pad, prec, padprec, Caml_string.get(str, str_ind));
        };
        if (!/* tag */
        (typeof pad === "number" || typeof pad === "string")) {
          return parse_conv(pad);
        }
        if (
          /* tag */
          (typeof prec === "number" || typeof prec === "string") && prec === /* No_precision */
          0
        ) {
          return parse_conv(
            /* No_padding */
            0
          );
        }
        if (minus) {
          if (
            /* tag */
            typeof prec === "number" || typeof prec === "string"
          ) {
            return parse_conv({
              TAG: (
                /* Arg_padding */
                1
              ),
              _0: (
                /* Left */
                0
              )
            });
          } else {
            return parse_conv({
              TAG: (
                /* Lit_padding */
                0
              ),
              _0: (
                /* Left */
                0
              ),
              _1: prec._0
            });
          }
        } else if (
          /* tag */
          typeof prec === "number" || typeof prec === "string"
        ) {
          return parse_conv({
            TAG: (
              /* Arg_padding */
              1
            ),
            _0: (
              /* Right */
              1
            )
          });
        } else {
          return parse_conv({
            TAG: (
              /* Lit_padding */
              0
            ),
            _0: (
              /* Right */
              1
            ),
            _1: prec._0
          });
        }
      };
      const parse_after_padding = function(pct_ind, str_ind, end_ind, minus, plus, hash, space, ign, pad) {
        if (str_ind === end_ind) {
          invalid_format_message(end_ind, "unexpected end of format");
        }
        const symb = Caml_string.get(str, str_ind);
        if (symb !== 46) {
          return parse_conversion(
            pct_ind,
            str_ind + 1 | 0,
            end_ind,
            plus,
            hash,
            space,
            ign,
            pad,
            /* No_precision */
            0,
            pad,
            symb
          );
        } else {
          let str_ind$1 = str_ind + 1 | 0;
          if (str_ind$1 === end_ind) {
            invalid_format_message(end_ind, "unexpected end of format");
          }
          const parse_literal2 = function(minus2, str_ind2) {
            const match = parse_positive(str_ind2, end_ind, 0);
            return parse_after_precision(pct_ind, match[0], end_ind, minus2, plus, hash, space, ign, pad, {
              TAG: (
                /* Lit_precision */
                0
              ),
              _0: match[1]
            });
          };
          const symb$1 = Caml_string.get(str, str_ind$1);
          let exit = 0;
          if (symb$1 >= 48) {
            if (symb$1 < 58) {
              return parse_literal2(minus, str_ind$1);
            }
          } else if (symb$1 >= 42) {
            switch (symb$1) {
              case 42:
                return parse_after_precision(
                  pct_ind,
                  str_ind$1 + 1 | 0,
                  end_ind,
                  minus,
                  plus,
                  hash,
                  space,
                  ign,
                  pad,
                  /* Arg_precision */
                  1
                );
              case 43:
              case 45:
                exit = 2;
                break;
              case 44:
              case 46:
              case 47:
                break;
            }
          }
          if (exit === 2 && legacy_behavior$1) {
            return parse_literal2(minus || symb$1 === /* '-' */
            45, str_ind$1 + 1 | 0);
          }
          if (legacy_behavior$1) {
            return parse_after_precision(pct_ind, str_ind$1, end_ind, minus, plus, hash, space, ign, pad, {
              TAG: (
                /* Lit_precision */
                0
              ),
              _0: 0
            });
          } else {
            return invalid_format_without(
              str_ind$1 - 1 | 0,
              /* '.' */
              46,
              "precision"
            );
          }
        }
      };
      const add_literal = function(lit_start, str_ind, fmt) {
        const size = str_ind - lit_start | 0;
        if (size !== 0) {
          if (size !== 1) {
            return {
              TAG: (
                /* Fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: Stdlib__String2.sub(str, lit_start, size),
                _1: fmt
              }
            };
          } else {
            return {
              TAG: (
                /* Fmt_EBB */
                0
              ),
              _0: {
                TAG: (
                  /* Char_literal */
                  12
                ),
                _0: Caml_string.get(str, lit_start),
                _1: fmt
              }
            };
          }
        } else {
          return {
            TAG: (
              /* Fmt_EBB */
              0
            ),
            _0: fmt
          };
        }
      };
      const parse_format = function(pct_ind, end_ind) {
        let str_ind = pct_ind + 1 | 0;
        if (str_ind === end_ind) {
          invalid_format_message(end_ind, "unexpected end of format");
        }
        const match = Caml_string.get(str, str_ind);
        if (match !== 95) {
          return parse_flags(pct_ind, str_ind, end_ind, false);
        } else {
          return parse_flags(pct_ind, str_ind + 1 | 0, end_ind, true);
        }
      };
      const parse_after_at = function(str_ind, end_ind) {
        if (str_ind === end_ind) {
          return {
            TAG: (
              /* Fmt_EBB */
              0
            ),
            _0: {
              TAG: (
                /* Char_literal */
                12
              ),
              _0: (
                /* '@' */
                64
              ),
              _1: (
                /* End_of_format */
                0
              )
            }
          };
        }
        const c = Caml_string.get(str, str_ind);
        if (c >= 65) {
          if (c >= 94) {
            switch (c) {
              case 123:
                return parse_tag(true, str_ind + 1 | 0, end_ind);
              case 125:
                const beg_ind = str_ind + 1 | 0;
                const fmt_rest = parse_literal(beg_ind, beg_ind, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Formatting_lit */
                      17
                    ),
                    _0: (
                      /* Close_tag */
                      1
                    ),
                    _1: fmt_rest._0
                  }
                };
            }
          } else if (c >= 91) {
            switch (c) {
              case 91:
                return parse_tag(false, str_ind + 1 | 0, end_ind);
              case 92:
                break;
              case 93:
                const beg_ind$1 = str_ind + 1 | 0;
                const fmt_rest$1 = parse_literal(beg_ind$1, beg_ind$1, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Formatting_lit */
                      17
                    ),
                    _0: (
                      /* Close_box */
                      0
                    ),
                    _1: fmt_rest$1._0
                  }
                };
            }
          }
        } else if (c !== 10) {
          if (c >= 32) {
            switch (c) {
              case 32:
                const beg_ind$2 = str_ind + 1 | 0;
                const fmt_rest$2 = parse_literal(beg_ind$2, beg_ind$2, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Formatting_lit */
                      17
                    ),
                    _0: {
                      TAG: (
                        /* Break */
                        0
                      ),
                      _0: "@ ",
                      _1: 1,
                      _2: 0
                    },
                    _1: fmt_rest$2._0
                  }
                };
              case 37:
                if ((str_ind + 1 | 0) < end_ind && Caml_string.get(str, str_ind + 1 | 0) === /* '%' */
                37) {
                  const beg_ind$3 = str_ind + 2 | 0;
                  const fmt_rest$3 = parse_literal(beg_ind$3, beg_ind$3, end_ind);
                  return {
                    TAG: (
                      /* Fmt_EBB */
                      0
                    ),
                    _0: {
                      TAG: (
                        /* Formatting_lit */
                        17
                      ),
                      _0: (
                        /* Escaped_percent */
                        6
                      ),
                      _1: fmt_rest$3._0
                    }
                  };
                }
                const fmt_rest$4 = parse_literal(str_ind, str_ind, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Char_literal */
                      12
                    ),
                    _0: (
                      /* '@' */
                      64
                    ),
                    _1: fmt_rest$4._0
                  }
                };
              case 44:
                const beg_ind$4 = str_ind + 1 | 0;
                const fmt_rest$5 = parse_literal(beg_ind$4, beg_ind$4, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Formatting_lit */
                      17
                    ),
                    _0: {
                      TAG: (
                        /* Break */
                        0
                      ),
                      _0: "@,",
                      _1: 0,
                      _2: 0
                    },
                    _1: fmt_rest$5._0
                  }
                };
              case 46:
                const beg_ind$5 = str_ind + 1 | 0;
                const fmt_rest$6 = parse_literal(beg_ind$5, beg_ind$5, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Formatting_lit */
                      17
                    ),
                    _0: (
                      /* Flush_newline */
                      4
                    ),
                    _1: fmt_rest$6._0
                  }
                };
              case 59:
                let str_ind$1 = str_ind + 1 | 0;
                let match;
                try {
                  if (str_ind$1 === end_ind || Caml_string.get(str, str_ind$1) !== /* '<' */
                  60) {
                    throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
                      MEL_EXN_ID: Stdlib.Not_found
                    });
                  }
                  const str_ind_1 = parse_spaces(str_ind$1 + 1 | 0, end_ind);
                  const match$1 = Caml_string.get(str, str_ind_1);
                  let exit = 0;
                  if (match$1 >= 48) {
                    if (match$1 >= 58) {
                      throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
                        MEL_EXN_ID: Stdlib.Not_found
                      });
                    }
                    exit = 1;
                  } else {
                    if (match$1 !== 45) {
                      throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
                        MEL_EXN_ID: Stdlib.Not_found
                      });
                    }
                    exit = 1;
                  }
                  if (exit === 1) {
                    const match$2 = parse_integer(str_ind_1, end_ind);
                    const width = match$2[1];
                    const str_ind_3 = parse_spaces(match$2[0], end_ind);
                    const match$3 = Caml_string.get(str, str_ind_3);
                    if (match$3 > 57 || match$3 < 45) {
                      if (match$3 !== 62) {
                        throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
                          MEL_EXN_ID: Stdlib.Not_found
                        });
                      }
                      const s = Stdlib__String2.sub(str, str_ind$1 - 2 | 0, (str_ind_3 - str_ind$1 | 0) + 3 | 0);
                      match = [
                        str_ind_3 + 1 | 0,
                        {
                          TAG: (
                            /* Break */
                            0
                          ),
                          _0: s,
                          _1: width,
                          _2: 0
                        }
                      ];
                    } else {
                      if (match$3 === 47 || match$3 === 46) {
                        throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
                          MEL_EXN_ID: Stdlib.Not_found
                        });
                      }
                      const match$4 = parse_integer(str_ind_3, end_ind);
                      const str_ind_5 = parse_spaces(match$4[0], end_ind);
                      if (Caml_string.get(str, str_ind_5) !== /* '>' */
                      62) {
                        throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
                          MEL_EXN_ID: Stdlib.Not_found
                        });
                      }
                      const s$1 = Stdlib__String2.sub(str, str_ind$1 - 2 | 0, (str_ind_5 - str_ind$1 | 0) + 3 | 0);
                      match = [
                        str_ind_5 + 1 | 0,
                        {
                          TAG: (
                            /* Break */
                            0
                          ),
                          _0: s$1,
                          _1: width,
                          _2: match$4[1]
                        }
                      ];
                    }
                  }
                } catch (raw_exn) {
                  const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
                  if (exn.MEL_EXN_ID === Stdlib.Not_found || exn.MEL_EXN_ID === Stdlib.Failure) {
                    match = [
                      str_ind$1,
                      {
                        TAG: (
                          /* Break */
                          0
                        ),
                        _0: "@;",
                        _1: 1,
                        _2: 0
                      }
                    ];
                  } else {
                    throw exn;
                  }
                }
                const next_ind = match[0];
                const fmt_rest$7 = parse_literal(next_ind, next_ind, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Formatting_lit */
                      17
                    ),
                    _0: match[1],
                    _1: fmt_rest$7._0
                  }
                };
              case 60:
                let str_ind$2 = str_ind + 1 | 0;
                let match$5;
                try {
                  const str_ind_1$1 = parse_spaces(str_ind$2, end_ind);
                  const match$6 = Caml_string.get(str, str_ind_1$1);
                  let exit$1 = 0;
                  if (match$6 >= 48) {
                    if (match$6 >= 58) {
                      match$5 = void 0;
                    } else {
                      exit$1 = 1;
                    }
                  } else if (match$6 !== 45) {
                    match$5 = void 0;
                  } else {
                    exit$1 = 1;
                  }
                  if (exit$1 === 1) {
                    const match$7 = parse_integer(str_ind_1$1, end_ind);
                    const str_ind_3$1 = parse_spaces(match$7[0], end_ind);
                    if (Caml_string.get(str, str_ind_3$1) !== /* '>' */
                    62) {
                      throw new Caml_js_exceptions.MelangeError(Stdlib.Not_found, {
                        MEL_EXN_ID: Stdlib.Not_found
                      });
                    }
                    const s$2 = Stdlib__String2.sub(str, str_ind$2 - 2 | 0, (str_ind_3$1 - str_ind$2 | 0) + 3 | 0);
                    match$5 = [
                      str_ind_3$1 + 1 | 0,
                      {
                        TAG: (
                          /* Magic_size */
                          1
                        ),
                        _0: s$2,
                        _1: match$7[1]
                      }
                    ];
                  }
                } catch (raw_exn$1) {
                  const exn$1 = Caml_js_exceptions.internalToOCamlException(raw_exn$1);
                  if (exn$1.MEL_EXN_ID === Stdlib.Not_found || exn$1.MEL_EXN_ID === Stdlib.Failure) {
                    match$5 = void 0;
                  } else {
                    throw exn$1;
                  }
                }
                if (match$5 !== void 0) {
                  const next_ind$1 = match$5[0];
                  const fmt_rest$8 = parse_literal(next_ind$1, next_ind$1, end_ind);
                  return {
                    TAG: (
                      /* Fmt_EBB */
                      0
                    ),
                    _0: {
                      TAG: (
                        /* Formatting_lit */
                        17
                      ),
                      _0: match$5[1],
                      _1: fmt_rest$8._0
                    }
                  };
                }
                const fmt_rest$9 = parse_literal(str_ind$2, str_ind$2, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Formatting_lit */
                      17
                    ),
                    _0: {
                      TAG: (
                        /* Scan_indic */
                        2
                      ),
                      _0: (
                        /* '<' */
                        60
                      )
                    },
                    _1: fmt_rest$9._0
                  }
                };
              case 33:
              case 34:
              case 35:
              case 36:
              case 38:
              case 39:
              case 40:
              case 41:
              case 42:
              case 43:
              case 45:
              case 47:
              case 48:
              case 49:
              case 50:
              case 51:
              case 52:
              case 53:
              case 54:
              case 55:
              case 56:
              case 57:
              case 58:
              case 61:
              case 62:
                break;
              case 63:
                const beg_ind$6 = str_ind + 1 | 0;
                const fmt_rest$10 = parse_literal(beg_ind$6, beg_ind$6, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Formatting_lit */
                      17
                    ),
                    _0: (
                      /* FFlush */
                      2
                    ),
                    _1: fmt_rest$10._0
                  }
                };
              case 64:
                const beg_ind$7 = str_ind + 1 | 0;
                const fmt_rest$11 = parse_literal(beg_ind$7, beg_ind$7, end_ind);
                return {
                  TAG: (
                    /* Fmt_EBB */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* Formatting_lit */
                      17
                    ),
                    _0: (
                      /* Escaped_at */
                      5
                    ),
                    _1: fmt_rest$11._0
                  }
                };
            }
          }
        } else {
          const beg_ind$8 = str_ind + 1 | 0;
          const fmt_rest$12 = parse_literal(beg_ind$8, beg_ind$8, end_ind);
          return {
            TAG: (
              /* Fmt_EBB */
              0
            ),
            _0: {
              TAG: (
                /* Formatting_lit */
                17
              ),
              _0: (
                /* Force_newline */
                3
              ),
              _1: fmt_rest$12._0
            }
          };
        }
        const beg_ind$9 = str_ind + 1 | 0;
        const fmt_rest$13 = parse_literal(beg_ind$9, beg_ind$9, end_ind);
        return {
          TAG: (
            /* Fmt_EBB */
            0
          ),
          _0: {
            TAG: (
              /* Formatting_lit */
              17
            ),
            _0: {
              TAG: (
                /* Scan_indic */
                2
              ),
              _0: c
            },
            _1: fmt_rest$13._0
          }
        };
      };
      const parse_flags = function(pct_ind, str_ind, end_ind, ign) {
        const zero = {
          contents: false
        };
        const minus = {
          contents: false
        };
        const plus = {
          contents: false
        };
        const space = {
          contents: false
        };
        const hash = {
          contents: false
        };
        const set_flag = function(str_ind2, flag) {
          if (flag.contents && !legacy_behavior$1) {
            Curry2._3(failwith_message({
              TAG: (
                /* Format */
                0
              ),
              _0: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: "invalid format ",
                _1: {
                  TAG: (
                    /* Caml_string */
                    3
                  ),
                  _0: (
                    /* No_padding */
                    0
                  ),
                  _1: {
                    TAG: (
                      /* String_literal */
                      11
                    ),
                    _0: ": at character number ",
                    _1: {
                      TAG: (
                        /* Int */
                        4
                      ),
                      _0: (
                        /* Int_d */
                        0
                      ),
                      _1: (
                        /* No_padding */
                        0
                      ),
                      _2: (
                        /* No_precision */
                        0
                      ),
                      _3: {
                        TAG: (
                          /* String_literal */
                          11
                        ),
                        _0: ", duplicate flag ",
                        _1: {
                          TAG: (
                            /* Caml_char */
                            1
                          ),
                          _0: (
                            /* End_of_format */
                            0
                          )
                        }
                      }
                    }
                  }
                }
              },
              _1: "invalid format %S: at character number %d, duplicate flag %C"
            }), str, str_ind2, Caml_string.get(str, str_ind2));
          }
          flag.contents = true;
        };
        let _str_ind = str_ind;
        while (true) {
          const str_ind$1 = _str_ind;
          if (str_ind$1 === end_ind) {
            invalid_format_message(end_ind, "unexpected end of format");
          }
          const match = Caml_string.get(str, str_ind$1);
          switch (match) {
            case 32:
              set_flag(str_ind$1, space);
              _str_ind = str_ind$1 + 1 | 0;
              continue;
            case 35:
              set_flag(str_ind$1, hash);
              _str_ind = str_ind$1 + 1 | 0;
              continue;
            case 43:
              set_flag(str_ind$1, plus);
              _str_ind = str_ind$1 + 1 | 0;
              continue;
            case 45:
              set_flag(str_ind$1, minus);
              _str_ind = str_ind$1 + 1 | 0;
              continue;
            case 48:
              set_flag(str_ind$1, zero);
              _str_ind = str_ind$1 + 1 | 0;
              continue;
          }
          let zero$1 = zero.contents;
          let minus$1 = minus.contents;
          let plus$1 = plus.contents;
          let hash$1 = hash.contents;
          let space$1 = space.contents;
          if (str_ind$1 === end_ind) {
            invalid_format_message(end_ind, "unexpected end of format");
          }
          const padty = zero$1 ? minus$1 ? legacy_behavior$1 ? (
            /* Left */
            0
          ) : incompatible_flag(
            pct_ind,
            str_ind$1,
            /* '-' */
            45,
            "0"
          ) : (
            /* Zeros */
            2
          ) : minus$1 ? (
            /* Left */
            0
          ) : (
            /* Right */
            1
          );
          const match$1 = Caml_string.get(str, str_ind$1);
          if (match$1 >= 48) {
            if (match$1 < 58) {
              const match$2 = parse_positive(str_ind$1, end_ind, 0);
              return parse_after_padding(pct_ind, match$2[0], end_ind, minus$1, plus$1, hash$1, space$1, ign, {
                TAG: (
                  /* Lit_padding */
                  0
                ),
                _0: padty,
                _1: match$2[1]
              });
            }
          } else if (match$1 === 42) {
            return parse_after_padding(pct_ind, str_ind$1 + 1 | 0, end_ind, minus$1, plus$1, hash$1, space$1, ign, {
              TAG: (
                /* Arg_padding */
                1
              ),
              _0: padty
            });
          }
          switch (padty) {
            case /* Left */
            0:
              if (!legacy_behavior$1) {
                invalid_format_without(
                  str_ind$1 - 1 | 0,
                  /* '-' */
                  45,
                  "padding"
                );
              }
              return parse_after_padding(
                pct_ind,
                str_ind$1,
                end_ind,
                minus$1,
                plus$1,
                hash$1,
                space$1,
                ign,
                /* No_padding */
                0
              );
            case /* Right */
            1:
              return parse_after_padding(
                pct_ind,
                str_ind$1,
                end_ind,
                minus$1,
                plus$1,
                hash$1,
                space$1,
                ign,
                /* No_padding */
                0
              );
            case /* Zeros */
            2:
              return parse_after_padding(pct_ind, str_ind$1, end_ind, minus$1, plus$1, hash$1, space$1, ign, {
                TAG: (
                  /* Lit_padding */
                  0
                ),
                _0: (
                  /* Right */
                  1
                ),
                _1: 0
              });
          }
        }
        ;
      };
      return parse_literal(0, 0, str.length);
    }
    function format_of_string_fmtty(str, fmtty) {
      const fmt = fmt_ebb_of_string(void 0, str);
      try {
        return {
          TAG: (
            /* Format */
            0
          ),
          _0: type_format(fmt._0, fmtty),
          _1: str
        };
      } catch (raw_exn) {
        const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
        if (exn.MEL_EXN_ID === Type_mismatch) {
          return Curry2._2(failwith_message({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "bad input: format type mismatch between ",
              _1: {
                TAG: (
                  /* Caml_string */
                  3
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: {
                  TAG: (
                    /* String_literal */
                    11
                  ),
                  _0: " and ",
                  _1: {
                    TAG: (
                      /* Caml_string */
                      3
                    ),
                    _0: (
                      /* No_padding */
                      0
                    ),
                    _1: (
                      /* End_of_format */
                      0
                    )
                  }
                }
              }
            },
            _1: "bad input: format type mismatch between %S and %S"
          }), str, string_of_fmtty(fmtty));
        }
        throw exn;
      }
    }
    function format_of_string_format(str, param) {
      const fmt = fmt_ebb_of_string(void 0, str);
      try {
        return {
          TAG: (
            /* Format */
            0
          ),
          _0: type_format(fmt._0, fmtty_of_fmt(param._0)),
          _1: str
        };
      } catch (raw_exn) {
        const exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
        if (exn.MEL_EXN_ID === Type_mismatch) {
          return Curry2._2(failwith_message({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "bad input: format type mismatch between ",
              _1: {
                TAG: (
                  /* Caml_string */
                  3
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: {
                  TAG: (
                    /* String_literal */
                    11
                  ),
                  _0: " and ",
                  _1: {
                    TAG: (
                      /* Caml_string */
                      3
                    ),
                    _0: (
                      /* No_padding */
                      0
                    ),
                    _1: (
                      /* End_of_format */
                      0
                    )
                  }
                }
              }
            },
            _1: "bad input: format type mismatch between %S and %S"
          }), str, param._1);
        }
        throw exn;
      }
    }
    module2.exports = {
      is_in_char_set,
      rev_char_set,
      create_char_set,
      add_in_char_set,
      freeze_char_set,
      param_format_of_ignored_format,
      make_printf,
      make_iprintf,
      output_acc,
      bufput_acc,
      strput_acc,
      type_format,
      fmt_ebb_of_string,
      format_of_string_fmtty,
      format_of_string_format,
      char_of_iconv,
      string_of_formatting_lit,
      string_of_fmtty,
      string_of_fmt,
      open_box_of_string,
      symm,
      trans,
      recast
    };
  }
});

// _build/default/tools/src/inbox/output/node_modules/melange/printf.js
var require_printf = __commonJS({
  "_build/default/tools/src/inbox/output/node_modules/melange/printf.js"(exports2, module2) {
    "use strict";
    var CamlinternalFormat = require_camlinternalFormat();
    var Curry2 = require_curry();
    var Stdlib = require_stdlib();
    var Stdlib__Buffer = require_buffer();
    function kfprintf(k, o, param) {
      return CamlinternalFormat.make_printf(
        (function(acc) {
          CamlinternalFormat.output_acc(o, acc);
          return Curry2._1(k, o);
        }),
        /* End_of_acc */
        0,
        param._0
      );
    }
    function kbprintf(k, b, param) {
      return CamlinternalFormat.make_printf(
        (function(acc) {
          CamlinternalFormat.bufput_acc(b, acc);
          return Curry2._1(k, b);
        }),
        /* End_of_acc */
        0,
        param._0
      );
    }
    function ikfprintf(k, oc, param) {
      return CamlinternalFormat.make_iprintf(k, oc, param._0);
    }
    function fprintf(oc, fmt) {
      return kfprintf((function(prim) {
      }), oc, fmt);
    }
    function bprintf(b, fmt) {
      return kbprintf((function(prim) {
      }), b, fmt);
    }
    function ifprintf(oc, fmt) {
      return ikfprintf((function(prim) {
      }), oc, fmt);
    }
    function ibprintf(b, fmt) {
      return ikfprintf((function(prim) {
      }), b, fmt);
    }
    function printf(fmt) {
      return fprintf(Stdlib.stdout, fmt);
    }
    function eprintf(fmt) {
      return fprintf(Stdlib.stderr, fmt);
    }
    function ksprintf(k, param) {
      const k$p = function(acc) {
        const buf = Stdlib__Buffer.create(64);
        CamlinternalFormat.strput_acc(buf, acc);
        return Curry2._1(k, Stdlib__Buffer.contents(buf));
      };
      return CamlinternalFormat.make_printf(
        k$p,
        /* End_of_acc */
        0,
        param._0
      );
    }
    function sprintf(fmt) {
      return ksprintf((function(s) {
        return s;
      }), fmt);
    }
    var ikbprintf = ikfprintf;
    var kprintf = ksprintf;
    module2.exports = {
      fprintf,
      printf,
      eprintf,
      sprintf,
      bprintf,
      ifprintf,
      ibprintf,
      kfprintf,
      ikfprintf,
      ksprintf,
      kbprintf,
      ikbprintf,
      kprintf
    };
  }
});

// _build/default/tools/src/inbox/output/tools/src/inbox/inbox_lib.js
var require_inbox_lib = __commonJS({
  "_build/default/tools/src/inbox/output/tools/src/inbox/inbox_lib.js"(exports2, module2) {
    "use strict";
    var Curry2 = require_curry();
    var Stdlib__List2 = require_list();
    var Stdlib__Option2 = require_option();
    var Stdlib__Printf2 = require_printf();
    var Stdlib__String2 = require_string();
    function do_action_of_string(s) {
      if (s === "merge") {
        return (
          /* Merge */
          0
        );
      }
      const match = Stdlib__String2.split_on_char(
        /* ':' */
        58,
        s
      );
      if (!match) {
        return;
      }
      switch (match.hd) {
        case "custom":
          const match$1 = match.tl;
          if (match$1 && !match$1.tl) {
            return {
              TAG: (
                /* Custom */
                1
              ),
              _0: match$1.hd
            };
          } else {
            return;
          }
        case "reply":
          const match$2 = match.tl;
          if (match$2 && !match$2.tl) {
            return {
              TAG: (
                /* Reply */
                0
              ),
              _0: match$2.hd
            };
          } else {
            return;
          }
        default:
          return;
      }
    }
    function string_of_do_action(name) {
      if (
        /* tag */
        typeof name === "number" || typeof name === "string"
      ) {
        return "merge";
      } else if (name.TAG === /* Reply */
      0) {
        return Curry2._1(Stdlib__Printf2.sprintf({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "reply:",
            _1: {
              TAG: (
                /* String */
                2
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: (
                /* End_of_format */
                0
              )
            }
          },
          _1: "reply:%s"
        }), name._0);
      } else {
        return Curry2._1(Stdlib__Printf2.sprintf({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "custom:",
            _1: {
              TAG: (
                /* String */
                2
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: (
                /* End_of_format */
                0
              )
            }
          },
          _1: "custom:%s"
        }), name._0);
      }
    }
    function non_empty_payload(parts) {
      const payload = Stdlib__String2.concat(":", parts);
      if (payload.length !== 0) {
        return payload;
      }
    }
    function triage_of_string(s) {
      const match = Stdlib__String2.split_on_char(
        /* ':' */
        58,
        s
      );
      if (!match) {
        return;
      }
      let exit = 0;
      switch (match.hd) {
        case "d":
        case "delete":
          exit = 1;
          break;
        case "defer":
        case "f":
          exit = 2;
          break;
        case "delegate":
        case "g":
          exit = 3;
          break;
        case "do":
        case "o":
          exit = 4;
          break;
        default:
          return;
      }
      switch (exit) {
        case 1:
          return Stdlib__Option2.map((function(r) {
            return {
              TAG: (
                /* Delete */
                0
              ),
              _0: r
            };
          }), non_empty_payload(match.tl));
        case 2:
          return Stdlib__Option2.map((function(r) {
            return {
              TAG: (
                /* Defer */
                1
              ),
              _0: r
            };
          }), non_empty_payload(match.tl));
        case 3:
          return Stdlib__Option2.map((function(r) {
            return {
              TAG: (
                /* Delegate */
                2
              ),
              _0: r
            };
          }), non_empty_payload(match.tl));
        case 4:
          const match$1 = match.tl;
          if (!match$1) {
            return;
          }
          switch (match$1.hd) {
            case "custom":
              return Stdlib__Option2.map((function(d) {
                return {
                  TAG: (
                    /* Do */
                    3
                  ),
                  _0: {
                    TAG: (
                      /* Custom */
                      1
                    ),
                    _0: d
                  }
                };
              }), non_empty_payload(match$1.tl));
            case "merge":
              if (match$1.tl) {
                return;
              } else {
                return {
                  TAG: (
                    /* Do */
                    3
                  ),
                  _0: (
                    /* Merge */
                    0
                  )
                };
              }
            case "reply":
              return Stdlib__Option2.map((function(n2) {
                return {
                  TAG: (
                    /* Do */
                    3
                  ),
                  _0: {
                    TAG: (
                      /* Reply */
                      0
                    ),
                    _0: n2
                  }
                };
              }), non_empty_payload(match$1.tl));
            default:
              return;
          }
      }
    }
    function string_of_triage(reason) {
      switch (reason.TAG) {
        case /* Delete */
        0:
          return Curry2._1(Stdlib__Printf2.sprintf({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "delete:",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: (
                  /* End_of_format */
                  0
                )
              }
            },
            _1: "delete:%s"
          }), reason._0);
        case /* Defer */
        1:
          return Curry2._1(Stdlib__Printf2.sprintf({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "defer:",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: (
                  /* End_of_format */
                  0
                )
              }
            },
            _1: "defer:%s"
          }), reason._0);
        case /* Delegate */
        2:
          return Curry2._1(Stdlib__Printf2.sprintf({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "delegate:",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: (
                  /* End_of_format */
                  0
                )
              }
            },
            _1: "delegate:%s"
          }), reason._0);
        case /* Do */
        3:
          return Curry2._1(Stdlib__Printf2.sprintf({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "do:",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: (
                  /* End_of_format */
                  0
                )
              }
            },
            _1: "do:%s"
          }), string_of_do_action(reason._0));
      }
    }
    function triage_kind(param) {
      switch (param.TAG) {
        case /* Delete */
        0:
          return "delete";
        case /* Defer */
        1:
          return "defer";
        case /* Delegate */
        2:
          return "delegate";
        case /* Do */
        3:
          return "do";
      }
    }
    function triage_description(reason) {
      switch (reason.TAG) {
        case /* Delete */
        0:
          return Curry2._1(Stdlib__Printf2.sprintf({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "Remove branch (",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: {
                  TAG: (
                    /* Char_literal */
                    12
                  ),
                  _0: (
                    /* ')' */
                    41
                  ),
                  _1: (
                    /* End_of_format */
                    0
                  )
                }
              }
            },
            _1: "Remove branch (%s)"
          }), reason._0);
        case /* Defer */
        1:
          return Curry2._1(Stdlib__Printf2.sprintf({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "Defer (",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: {
                  TAG: (
                    /* Char_literal */
                    12
                  ),
                  _0: (
                    /* ')' */
                    41
                  ),
                  _1: (
                    /* End_of_format */
                    0
                  )
                }
              }
            },
            _1: "Defer (%s)"
          }), reason._0);
        case /* Delegate */
        2:
          return Curry2._1(Stdlib__Printf2.sprintf({
            TAG: (
              /* Format */
              0
            ),
            _0: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "Delegate to ",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: (
                  /* End_of_format */
                  0
                )
              }
            },
            _1: "Delegate to %s"
          }), reason._0);
        case /* Do */
        3:
          const name = reason._0;
          if (
            /* tag */
            typeof name === "number" || typeof name === "string"
          ) {
            return "Merge branch";
          } else if (name.TAG === /* Reply */
          0) {
            return Curry2._1(Stdlib__Printf2.sprintf({
              TAG: (
                /* Format */
                0
              ),
              _0: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: "Reply with branch ",
                _1: {
                  TAG: (
                    /* String */
                    2
                  ),
                  _0: (
                    /* No_padding */
                    0
                  ),
                  _1: (
                    /* End_of_format */
                    0
                  )
                }
              },
              _1: "Reply with branch %s"
            }), name._0);
          } else {
            return Curry2._1(Stdlib__Printf2.sprintf({
              TAG: (
                /* Format */
                0
              ),
              _0: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: "Action: ",
                _1: {
                  TAG: (
                    /* String */
                    2
                  ),
                  _0: (
                    /* No_padding */
                    0
                  ),
                  _1: (
                    /* End_of_format */
                    0
                  )
                }
              },
              _1: "Action: %s"
            }), name._0);
          }
      }
    }
    function format_log_entry(entry) {
      return Curry2._5(Stdlib__Printf2.sprintf({
        TAG: (
          /* Format */
          0
        ),
        _0: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: "- ",
          _1: {
            TAG: (
              /* String */
              2
            ),
            _0: (
              /* No_padding */
              0
            ),
            _1: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: " | ",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: {
                  TAG: (
                    /* String_literal */
                    11
                  ),
                  _0: " | ",
                  _1: {
                    TAG: (
                      /* String */
                      2
                    ),
                    _0: (
                      /* No_padding */
                      0
                    ),
                    _1: {
                      TAG: (
                        /* Char_literal */
                        12
                      ),
                      _0: (
                        /* '/' */
                        47
                      ),
                      _1: {
                        TAG: (
                          /* String */
                          2
                        ),
                        _0: (
                          /* No_padding */
                          0
                        ),
                        _1: {
                          TAG: (
                            /* String_literal */
                            11
                          ),
                          _0: " | ",
                          _1: {
                            TAG: (
                              /* String */
                              2
                            ),
                            _0: (
                              /* No_padding */
                              0
                            ),
                            _1: (
                              /* End_of_format */
                              0
                            )
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        _1: "- %s | %s | %s/%s | %s"
      }), entry.timestamp, entry.actor, entry.peer, entry.branch, string_of_triage(entry.decision));
    }
    function format_log_entry_human(entry) {
      return Curry2._5(Stdlib__Printf2.sprintf({
        TAG: (
          /* Format */
          0
        ),
        _0: {
          TAG: (
            /* Char_literal */
            12
          ),
          _0: (
            /* '[' */
            91
          ),
          _1: {
            TAG: (
              /* String */
              2
            ),
            _0: (
              /* No_padding */
              0
            ),
            _1: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "] ",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: {
                  TAG: (
                    /* String_literal */
                    11
                  ),
                  _0: " triaged ",
                  _1: {
                    TAG: (
                      /* String */
                      2
                    ),
                    _0: (
                      /* No_padding */
                      0
                    ),
                    _1: {
                      TAG: (
                        /* Char_literal */
                        12
                      ),
                      _0: (
                        /* '/' */
                        47
                      ),
                      _1: {
                        TAG: (
                          /* String */
                          2
                        ),
                        _0: (
                          /* No_padding */
                          0
                        ),
                        _1: {
                          TAG: (
                            /* String_literal */
                            11
                          ),
                          _0: " \xE2\x86\x92 ",
                          _1: {
                            TAG: (
                              /* String */
                              2
                            ),
                            _0: (
                              /* No_padding */
                              0
                            ),
                            _1: (
                              /* End_of_format */
                              0
                            )
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        _1: "[%s] %s triaged %s/%s \xE2\x86\x92 %s"
      }), entry.timestamp, entry.actor, entry.peer, entry.branch, triage_description(entry.decision));
    }
    function parse_log_entry(line) {
      const match = Stdlib__String2.split_on_char(
        /* '|' */
        124,
        line
      );
      if (!match) {
        return;
      }
      const match$1 = match.tl;
      if (!match$1) {
        return;
      }
      const match$2 = match$1.tl;
      if (!match$2) {
        return;
      }
      const match$3 = match$2.tl;
      if (!match$3) {
        return;
      }
      if (match$3.tl) {
        return;
      }
      const ts_trimmed = Stdlib__String2.trim(match.hd);
      const timestamp = ts_trimmed.length > 2 && Stdlib__String2.sub(ts_trimmed, 0, 2) === "- " ? Stdlib__String2.sub(ts_trimmed, 2, ts_trimmed.length - 2 | 0) : ts_trimmed;
      const actor = Stdlib__String2.trim(match$1.hd);
      const match$4 = Stdlib__String2.split_on_char(
        /* '/' */
        47,
        Stdlib__String2.trim(match$2.hd)
      );
      const match$5 = match$4 ? [
        match$4.hd,
        Stdlib__String2.concat("/", match$4.tl)
      ] : [
        "",
        ""
      ];
      const decision = triage_of_string(Stdlib__String2.trim(match$3.hd));
      if (decision !== void 0) {
        return {
          timestamp,
          branch: match$5[1],
          peer: match$5[0],
          decision,
          actor
        };
      }
    }
    var log_dir = "logs/inbox";
    function daily_log_path(date_str) {
      return Curry2._2(Stdlib__Printf2.sprintf({
        TAG: (
          /* Format */
          0
        ),
        _0: {
          TAG: (
            /* String */
            2
          ),
          _0: (
            /* No_padding */
            0
          ),
          _1: {
            TAG: (
              /* Char_literal */
              12
            ),
            _0: (
              /* '/' */
              47
            ),
            _1: {
              TAG: (
                /* String */
                2
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: ".md",
                _1: (
                  /* End_of_format */
                  0
                )
              }
            }
          }
        },
        _1: "%s/%s.md"
      }), log_dir, date_str);
    }
    function daily_log_header(date_str) {
      return Curry2._1(Stdlib__Printf2.sprintf({
        TAG: (
          /* Format */
          0
        ),
        _0: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: "# Inbox Log: ",
          _1: {
            TAG: (
              /* String */
              2
            ),
            _0: (
              /* No_padding */
              0
            ),
            _1: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "\n\n| Time | Actor | Source | Decision |\n|------|-------|--------|----------|",
              _1: (
                /* End_of_format */
                0
              )
            }
          }
        },
        _1: "# Inbox Log: %s\n\n| Time | Actor | Source | Decision |\n|------|-------|--------|----------|"
      }), Stdlib__String2.sub(date_str, 0, 4) + ("-" + (Stdlib__String2.sub(date_str, 4, 2) + ("-" + Stdlib__String2.sub(date_str, 6, 2)))));
    }
    function format_log_row(entry) {
      let time;
      try {
        time = Stdlib__String2.sub(entry.timestamp, 11, 5);
      } catch (exn) {
        time = entry.timestamp;
      }
      return Curry2._5(Stdlib__Printf2.sprintf({
        TAG: (
          /* Format */
          0
        ),
        _0: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: "| ",
          _1: {
            TAG: (
              /* String */
              2
            ),
            _0: (
              /* No_padding */
              0
            ),
            _1: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: " | ",
              _1: {
                TAG: (
                  /* String */
                  2
                ),
                _0: (
                  /* No_padding */
                  0
                ),
                _1: {
                  TAG: (
                    /* String_literal */
                    11
                  ),
                  _0: " | ",
                  _1: {
                    TAG: (
                      /* String */
                      2
                    ),
                    _0: (
                      /* No_padding */
                      0
                    ),
                    _1: {
                      TAG: (
                        /* Char_literal */
                        12
                      ),
                      _0: (
                        /* '/' */
                        47
                      ),
                      _1: {
                        TAG: (
                          /* String */
                          2
                        ),
                        _0: (
                          /* No_padding */
                          0
                        ),
                        _1: {
                          TAG: (
                            /* String_literal */
                            11
                          ),
                          _0: " | `",
                          _1: {
                            TAG: (
                              /* String */
                              2
                            ),
                            _0: (
                              /* No_padding */
                              0
                            ),
                            _1: {
                              TAG: (
                                /* String_literal */
                                11
                              ),
                              _0: "` |",
                              _1: (
                                /* End_of_format */
                                0
                              )
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        _1: "| %s | %s | %s/%s | `%s` |"
      }), time, entry.actor, entry.peer, entry.branch, string_of_triage(entry.decision));
    }
    function update_stats(stats, param) {
      switch (param.TAG) {
        case /* Delete */
        0:
          return {
            total: stats.total + 1 | 0,
            deleted: stats.deleted + 1 | 0,
            deferred: stats.deferred,
            delegated: stats.delegated,
            done_count: stats.done_count
          };
        case /* Defer */
        1:
          return {
            total: stats.total + 1 | 0,
            deleted: stats.deleted,
            deferred: stats.deferred + 1 | 0,
            delegated: stats.delegated,
            done_count: stats.done_count
          };
        case /* Delegate */
        2:
          return {
            total: stats.total + 1 | 0,
            deleted: stats.deleted,
            deferred: stats.deferred,
            delegated: stats.delegated + 1 | 0,
            done_count: stats.done_count
          };
        case /* Do */
        3:
          return {
            total: stats.total + 1 | 0,
            deleted: stats.deleted,
            deferred: stats.deferred,
            delegated: stats.delegated,
            done_count: stats.done_count + 1 | 0
          };
      }
    }
    function format_daily_summary(stats) {
      return Curry2._5(Stdlib__Printf2.sprintf({
        TAG: (
          /* Format */
          0
        ),
        _0: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: "\n## Summary\n- Processed: ",
          _1: {
            TAG: (
              /* Int */
              4
            ),
            _0: (
              /* Int_d */
              0
            ),
            _1: (
              /* No_padding */
              0
            ),
            _2: (
              /* No_precision */
              0
            ),
            _3: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "\n- Delete: ",
              _1: {
                TAG: (
                  /* Int */
                  4
                ),
                _0: (
                  /* Int_d */
                  0
                ),
                _1: (
                  /* No_padding */
                  0
                ),
                _2: (
                  /* No_precision */
                  0
                ),
                _3: {
                  TAG: (
                    /* String_literal */
                    11
                  ),
                  _0: "\n- Defer: ",
                  _1: {
                    TAG: (
                      /* Int */
                      4
                    ),
                    _0: (
                      /* Int_d */
                      0
                    ),
                    _1: (
                      /* No_padding */
                      0
                    ),
                    _2: (
                      /* No_precision */
                      0
                    ),
                    _3: {
                      TAG: (
                        /* String_literal */
                        11
                      ),
                      _0: "\n- Delegate: ",
                      _1: {
                        TAG: (
                          /* Int */
                          4
                        ),
                        _0: (
                          /* Int_d */
                          0
                        ),
                        _1: (
                          /* No_padding */
                          0
                        ),
                        _2: (
                          /* No_precision */
                          0
                        ),
                        _3: {
                          TAG: (
                            /* String_literal */
                            11
                          ),
                          _0: "\n- Do: ",
                          _1: {
                            TAG: (
                              /* Int */
                              4
                            ),
                            _0: (
                              /* Int_d */
                              0
                            ),
                            _1: (
                              /* No_padding */
                              0
                            ),
                            _2: (
                              /* No_precision */
                              0
                            ),
                            _3: (
                              /* End_of_format */
                              0
                            )
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        _1: "\n## Summary\n- Processed: %d\n- Delete: %d\n- Defer: %d\n- Delegate: %d\n- Do: %d"
      }), stats.total, stats.deleted, stats.deferred, stats.delegated, stats.done_count);
    }
    function action_of_string(param) {
      switch (param) {
        case "check":
          return (
            /* Check */
            0
          );
        case "flush":
          return (
            /* Flush */
            2
          );
        case "process":
          return (
            /* Process */
            1
          );
        default:
          return;
      }
    }
    function string_of_action(param) {
      switch (param) {
        case /* Check */
        0:
          return "check";
        case /* Process */
        1:
          return "process";
        case /* Flush */
        2:
          return "flush";
      }
    }
    function prefix(pre, s) {
      if (s.length >= pre.length) {
        return Stdlib__String2.sub(s, 0, pre.length) === pre;
      } else {
        return false;
      }
    }
    function strip_prefix(pre, s) {
      const match = prefix(pre, s);
      if (match) {
        return Stdlib__String2.sub(s, pre.length, s.length - pre.length | 0);
      }
    }
    function non_empty(s) {
      return Stdlib__String2.trim(s).length !== 0;
    }
    function parse_peers(content) {
      return Stdlib__List2.filter_map((function(line) {
        return strip_prefix("- name: ", Stdlib__String2.trim(line));
      }), Stdlib__String2.split_on_char(
        /* '\n' */
        10,
        content
      ));
    }
    function derive_name(hub_path) {
      const param = Stdlib__List2.rev(Stdlib__String2.split_on_char(
        /* '/' */
        47,
        hub_path
      ));
      if (!param) {
        return "agent";
      }
      const base = param.hd;
      return Stdlib__Option2.value(strip_prefix("cn-", base), base);
    }
    function make_peer(join, workspace, name) {
      const repo_path = name === "cn-agent" ? Curry2._2(join, workspace, "cn-agent") : Curry2._2(join, workspace, Curry2._1(Stdlib__Printf2.sprintf({
        TAG: (
          /* Format */
          0
        ),
        _0: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: "cn-",
          _1: {
            TAG: (
              /* String */
              2
            ),
            _0: (
              /* No_padding */
              0
            ),
            _1: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "-clone",
              _1: (
                /* End_of_format */
                0
              )
            }
          }
        },
        _1: "cn-%s-clone"
      }), name));
      return {
        name,
        repo_path
      };
    }
    function filter_branches(output) {
      return Stdlib__List2.filter(non_empty, Stdlib__List2.map(Stdlib__String2.trim, Stdlib__String2.split_on_char(
        /* '\n' */
        10,
        output
      )));
    }
    function report_result(param) {
      if (param.TAG !== /* Fetched */
      0) {
        return Curry2._2(Stdlib__Printf2.sprintf({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "  \xC2\xB7 ",
            _1: {
              TAG: (
                /* String */
                2
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: " (",
                _1: {
                  TAG: (
                    /* String */
                    2
                  ),
                  _0: (
                    /* No_padding */
                    0
                  ),
                  _1: {
                    TAG: (
                      /* Char_literal */
                      12
                    ),
                    _0: (
                      /* ')' */
                      41
                    ),
                    _1: (
                      /* End_of_format */
                      0
                    )
                  }
                }
              }
            }
          },
          _1: "  \xC2\xB7 %s (%s)"
        }), param._0, param._1);
      }
      const name = param._0;
      if (param._1) {
        return Curry2._2(Stdlib__Printf2.sprintf({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "  \xE2\x9A\xA1 ",
            _1: {
              TAG: (
                /* String */
                2
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: " (",
                _1: {
                  TAG: (
                    /* Int */
                    4
                  ),
                  _0: (
                    /* Int_d */
                    0
                  ),
                  _1: (
                    /* No_padding */
                    0
                  ),
                  _2: (
                    /* No_precision */
                    0
                  ),
                  _3: {
                    TAG: (
                      /* String_literal */
                      11
                    ),
                    _0: " inbound)",
                    _1: (
                      /* End_of_format */
                      0
                    )
                  }
                }
              }
            }
          },
          _1: "  \xE2\x9A\xA1 %s (%d inbound)"
        }), name, Stdlib__List2.length(param._1));
      } else {
        return Curry2._1(Stdlib__Printf2.sprintf({
          TAG: (
            /* Format */
            0
          ),
          _0: {
            TAG: (
              /* String_literal */
              11
            ),
            _0: "  \xE2\x9C\x93 ",
            _1: {
              TAG: (
                /* String */
                2
              ),
              _0: (
                /* No_padding */
                0
              ),
              _1: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: " (no inbound)",
                _1: (
                  /* End_of_format */
                  0
                )
              }
            }
          },
          _1: "  \xE2\x9C\x93 %s (no inbound)"
        }), name);
      }
    }
    function collect_alerts(results) {
      return Stdlib__List2.filter_map((function(param) {
        if (param.TAG !== /* Fetched */
        0) {
          return;
        }
        const branches = param._1;
        if (branches) {
          return [
            param._0,
            branches
          ];
        }
      }), results);
    }
    function collect_branches(results) {
      return Stdlib__List2.concat_map((function(param) {
        if (param.TAG !== /* Fetched */
        0) {
          return (
            /* [] */
            0
          );
        }
        const peer = param._0;
        return Stdlib__List2.map((function(b) {
          return {
            peer,
            branch: b,
            full_ref: Curry2._1(Stdlib__Printf2.sprintf({
              TAG: (
                /* Format */
                0
              ),
              _0: {
                TAG: (
                  /* String_literal */
                  11
                ),
                _0: "origin/",
                _1: {
                  TAG: (
                    /* String */
                    2
                  ),
                  _0: (
                    /* No_padding */
                    0
                  ),
                  _1: (
                    /* End_of_format */
                    0
                  )
                }
              },
              _1: "origin/%s"
            }), b)
          };
        }), param._1);
      }), results);
    }
    function format_alerts(alerts) {
      if (alerts) {
        return {
          hd: "=== INBOUND BRANCHES ===",
          tl: Stdlib__List2.concat_map((function(param) {
            return {
              hd: Curry2._1(Stdlib__Printf2.sprintf({
                TAG: (
                  /* Format */
                  0
                ),
                _0: {
                  TAG: (
                    /* String_literal */
                    11
                  ),
                  _0: "From ",
                  _1: {
                    TAG: (
                      /* String */
                      2
                    ),
                    _0: (
                      /* No_padding */
                      0
                    ),
                    _1: {
                      TAG: (
                        /* Char_literal */
                        12
                      ),
                      _0: (
                        /* ':' */
                        58
                      ),
                      _1: (
                        /* End_of_format */
                        0
                      )
                    }
                  }
                },
                _1: "From %s:"
              }), param[0]),
              tl: Stdlib__List2.map((function(b) {
                return Curry2._1(Stdlib__Printf2.sprintf({
                  TAG: (
                    /* Format */
                    0
                  ),
                  _0: {
                    TAG: (
                      /* String_literal */
                      11
                    ),
                    _0: "  ",
                    _1: {
                      TAG: (
                        /* String */
                        2
                      ),
                      _0: (
                        /* No_padding */
                        0
                      ),
                      _1: (
                        /* End_of_format */
                        0
                      )
                    }
                  },
                  _1: "  %s"
                }), b);
              }), param[1])
            };
          }), alerts)
        };
      } else {
        return {
          hd: "No inbound branches. All clear.",
          tl: (
            /* [] */
            0
          )
        };
      }
    }
    var empty_stats = {
      total: 0,
      deleted: 0,
      deferred: 0,
      delegated: 0,
      done_count: 0
    };
    var all_actions = {
      hd: (
        /* Check */
        0
      ),
      tl: {
        hd: (
          /* Process */
          1
        ),
        tl: {
          hd: (
            /* Flush */
            2
          ),
          tl: (
            /* [] */
            0
          )
        }
      }
    };
    module2.exports = {
      do_action_of_string,
      string_of_do_action,
      non_empty_payload,
      triage_of_string,
      string_of_triage,
      triage_kind,
      triage_description,
      format_log_entry,
      format_log_entry_human,
      parse_log_entry,
      log_dir,
      daily_log_path,
      daily_log_header,
      format_log_row,
      empty_stats,
      update_stats,
      format_daily_summary,
      action_of_string,
      string_of_action,
      all_actions,
      prefix,
      strip_prefix,
      non_empty,
      parse_peers,
      derive_name,
      make_peer,
      filter_branches,
      report_result,
      collect_alerts,
      collect_branches,
      format_alerts
    };
  }
});

// _build/default/tools/src/inbox/output/tools/src/inbox/inbox.js
var Caml_array = require_caml_array();
var Curry = require_curry();
var Inbox_lib = require_inbox_lib();
var Stdlib__List = require_list();
var Stdlib__Option = require_option();
var Stdlib__Printf = require_printf();
var Stdlib__String = require_string();
var Child_process = require("child_process");
var Fs = require("fs");
var Path = require("path");
var Process = require("process");
var Process$1 = {};
var Child_process$1 = {};
var Fs$1 = {};
var Path$1 = {};
function run_cmd(cmd) {
  try {
    return Child_process.execSync(cmd, {
      encoding: "utf8"
    });
  } catch (exn) {
    return;
  }
}
function find_inbound_branches(repo_path, my_name) {
  const cmd = Curry._2(Stdlib__Printf.sprintf({
    TAG: (
      /* Format */
      0
    ),
    _0: {
      TAG: (
        /* String_literal */
        11
      ),
      _0: "cd ",
      _1: {
        TAG: (
          /* String */
          2
        ),
        _0: (
          /* No_padding */
          0
        ),
        _1: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: " && git branch -r 2>/dev/null | grep 'origin/",
          _1: {
            TAG: (
              /* String */
              2
            ),
            _0: (
              /* No_padding */
              0
            ),
            _1: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: "/' || true",
              _1: (
                /* End_of_format */
                0
              )
            }
          }
        }
      }
    },
    _1: "cd %s && git branch -r 2>/dev/null | grep 'origin/%s/' || true"
  }), repo_path, my_name);
  return Inbox_lib.filter_branches(Stdlib__Option.value(run_cmd(cmd), ""));
}
function check_peer(my_name, peer) {
  if (!Fs.existsSync(peer.repo_path)) {
    return {
      TAG: (
        /* Skipped */
        1
      ),
      _0: peer.name,
      _1: Curry._1(Stdlib__Printf.sprintf({
        TAG: (
          /* Format */
          0
        ),
        _0: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: "not found: ",
          _1: {
            TAG: (
              /* String */
              2
            ),
            _0: (
              /* No_padding */
              0
            ),
            _1: (
              /* End_of_format */
              0
            )
          }
        },
        _1: "not found: %s"
      }), peer.repo_path)
    };
  }
  run_cmd(Curry._1(Stdlib__Printf.sprintf({
    TAG: (
      /* Format */
      0
    ),
    _0: {
      TAG: (
        /* String_literal */
        11
      ),
      _0: "cd ",
      _1: {
        TAG: (
          /* String */
          2
        ),
        _0: (
          /* No_padding */
          0
        ),
        _1: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: " && git fetch --all 2>&1",
          _1: (
            /* End_of_format */
            0
          )
        }
      }
    },
    _1: "cd %s && git fetch --all 2>&1"
  }), peer.repo_path));
  const branches = find_inbound_branches(peer.repo_path, my_name);
  return {
    TAG: (
      /* Fetched */
      0
    ),
    _0: peer.name,
    _1: branches
  };
}
function run_check(_hub_path, my_name, peers) {
  console.log(Curry._2(Stdlib__Printf.sprintf({
    TAG: (
      /* Format */
      0
    ),
    _0: {
      TAG: (
        /* String_literal */
        11
      ),
      _0: "Checking inbox for ",
      _1: {
        TAG: (
          /* String */
          2
        ),
        _0: (
          /* No_padding */
          0
        ),
        _1: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: " (",
          _1: {
            TAG: (
              /* Int */
              4
            ),
            _0: (
              /* Int_d */
              0
            ),
            _1: (
              /* No_padding */
              0
            ),
            _2: (
              /* No_precision */
              0
            ),
            _3: {
              TAG: (
                /* String_literal */
                11
              ),
              _0: " peers)...\n",
              _1: (
                /* End_of_format */
                0
              )
            }
          }
        }
      }
    },
    _1: "Checking inbox for %s (%d peers)...\n"
  }), my_name, Stdlib__List.length(peers)));
  const results = Stdlib__List.map((function(param) {
    return check_peer(my_name, param);
  }), peers);
  Stdlib__List.iter((function(r) {
    console.log(Inbox_lib.report_result(r));
  }), results);
  const alerts = Inbox_lib.collect_alerts(results);
  console.log("");
  Stdlib__List.iter((function(prim) {
    console.log(prim);
  }), Inbox_lib.format_alerts(alerts));
  if (alerts) {
    return 2;
  } else {
    return 0;
  }
}
function run_process(_hub_path, _my_name, _peers) {
  console.log("inbox process: not yet implemented");
  console.log("Will: show first inbound branch, prompt for triage action");
  return 1;
}
function run_flush(_hub_path, _my_name, _peers) {
  console.log("inbox flush: not yet implemented");
  console.log("Will: process all inbound branches in sequence");
  return 1;
}
function run_action(action, hub_path, my_name, peers) {
  switch (action) {
    case /* Check */
    0:
      return run_check(hub_path, my_name, peers);
    case /* Process */
    1:
      return run_process(hub_path, my_name, peers);
    case /* Flush */
    2:
      return run_flush(hub_path, my_name, peers);
  }
}
function usage(param) {
  console.log("Usage: node inbox.js <action> <hub-path> [agent-name]");
  console.log("");
  console.log("Actions:");
  console.log("  check   - list inbound branches");
  console.log("  process - triage one message");
  console.log("  flush   - triage all messages");
  console.log("");
  console.log("Example: node inbox.js check ./cn-sigma sigma");
}
var argv = Process.argv;
var n = argv.length;
if (n < 4) {
  usage(void 0);
  Process.exit(1);
} else {
  const action_str = Caml_array.get(argv, 2);
  const action = Inbox_lib.action_of_string(action_str);
  if (action !== void 0) {
    const hub_path = Path.resolve(Process.cwd(), Caml_array.get(argv, 3));
    const my_name = argv.length > 4 ? Caml_array.get(argv, 4) : Inbox_lib.derive_name(hub_path);
    const workspace = Path.dirname(hub_path);
    const peers_file = Path.join(hub_path, "state/peers.md");
    if (Fs.existsSync(peers_file)) {
      const peers = Stdlib__List.map((function(param) {
        return Inbox_lib.make_peer((function(prim0, prim1) {
          return Path.join(prim0, prim1);
        }), workspace, param);
      }), Inbox_lib.parse_peers(Fs.readFileSync(peers_file, "utf8")));
      const exit_code = run_action(action, hub_path, my_name, peers);
      Process.exit(exit_code);
    } else {
      console.log(Curry._1(Stdlib__Printf.sprintf({
        TAG: (
          /* Format */
          0
        ),
        _0: {
          TAG: (
            /* String_literal */
            11
          ),
          _0: "No state/peers.md at ",
          _1: {
            TAG: (
              /* String */
              2
            ),
            _0: (
              /* No_padding */
              0
            ),
            _1: (
              /* End_of_format */
              0
            )
          }
        },
        _1: "No state/peers.md at %s"
      }), peers_file));
      Process.exit(1);
    }
  } else {
    console.log(Curry._1(Stdlib__Printf.sprintf({
      TAG: (
        /* Format */
        0
      ),
      _0: {
        TAG: (
          /* String_literal */
          11
        ),
        _0: "Unknown action: ",
        _1: {
          TAG: (
            /* String */
            2
          ),
          _0: (
            /* No_padding */
            0
          ),
          _1: (
            /* End_of_format */
            0
          )
        }
      },
      _1: "Unknown action: %s"
    }), action_str));
    console.log(Curry._1(Stdlib__Printf.sprintf({
      TAG: (
        /* Format */
        0
      ),
      _0: {
        TAG: (
          /* String_literal */
          11
        ),
        _0: "Valid actions: ",
        _1: {
          TAG: (
            /* String */
            2
          ),
          _0: (
            /* No_padding */
            0
          ),
          _1: (
            /* End_of_format */
            0
          )
        }
      },
      _1: "Valid actions: %s"
    }), Stdlib__String.concat(", ", Stdlib__List.map(Inbox_lib.string_of_action, Inbox_lib.all_actions))));
    Process.exit(1);
  }
}
module.exports = {
  Process: Process$1,
  Child_process: Child_process$1,
  Fs: Fs$1,
  Path: Path$1,
  run_cmd,
  find_inbound_branches,
  check_peer,
  run_check,
  run_process,
  run_flush,
  run_action,
  usage
};
