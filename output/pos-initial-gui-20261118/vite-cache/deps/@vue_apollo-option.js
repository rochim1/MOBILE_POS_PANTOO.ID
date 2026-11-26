import "./chunk-7REXU52E.js";

// node_modules/@vue/apollo-option/dist/vue-apollo-option.esm.mjs
function _iterableToArrayLimit(arr, i) {
  var _i = null == arr ? null : "undefined" != typeof Symbol && arr[Symbol.iterator] || arr["@@iterator"];
  if (null != _i) {
    var _s, _e, _x, _r, _arr = [], _n = true, _d = false;
    try {
      if (_x = (_i = _i.call(arr)).next, 0 === i) {
        if (Object(_i) !== _i)
          return;
        _n = false;
      } else
        for (; !(_n = (_s = _x.call(_i)).done) && (_arr.push(_s.value), _arr.length !== i); _n = true)
          ;
    } catch (err) {
      _d = true, _e = err;
    } finally {
      try {
        if (!_n && null != _i.return && (_r = _i.return(), Object(_r) !== _r))
          return;
      } finally {
        if (_d)
          throw _e;
      }
    }
    return _arr;
  }
}
function ownKeys(object, enumerableOnly) {
  var keys = Object.keys(object);
  if (Object.getOwnPropertySymbols) {
    var symbols = Object.getOwnPropertySymbols(object);
    enumerableOnly && (symbols = symbols.filter(function(sym) {
      return Object.getOwnPropertyDescriptor(object, sym).enumerable;
    })), keys.push.apply(keys, symbols);
  }
  return keys;
}
function _objectSpread2(target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = null != arguments[i] ? arguments[i] : {};
    i % 2 ? ownKeys(Object(source), true).forEach(function(key) {
      _defineProperty(target, key, source[key]);
    }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function(key) {
      Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key));
    });
  }
  return target;
}
function _typeof(obj) {
  "@babel/helpers - typeof";
  return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function(obj2) {
    return typeof obj2;
  } : function(obj2) {
    return obj2 && "function" == typeof Symbol && obj2.constructor === Symbol && obj2 !== Symbol.prototype ? "symbol" : typeof obj2;
  }, _typeof(obj);
}
function _classCallCheck(instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
}
function _defineProperties(target, props) {
  for (var i = 0; i < props.length; i++) {
    var descriptor = props[i];
    descriptor.enumerable = descriptor.enumerable || false;
    descriptor.configurable = true;
    if ("value" in descriptor)
      descriptor.writable = true;
    Object.defineProperty(target, _toPropertyKey(descriptor.key), descriptor);
  }
}
function _createClass(Constructor, protoProps, staticProps) {
  if (protoProps)
    _defineProperties(Constructor.prototype, protoProps);
  if (staticProps)
    _defineProperties(Constructor, staticProps);
  Object.defineProperty(Constructor, "prototype", {
    writable: false
  });
  return Constructor;
}
function _defineProperty(obj, key, value) {
  key = _toPropertyKey(key);
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }
  return obj;
}
function _inherits(subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function");
  }
  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      writable: true,
      configurable: true
    }
  });
  Object.defineProperty(subClass, "prototype", {
    writable: false
  });
  if (superClass)
    _setPrototypeOf(subClass, superClass);
}
function _getPrototypeOf(o) {
  _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function _getPrototypeOf2(o2) {
    return o2.__proto__ || Object.getPrototypeOf(o2);
  };
  return _getPrototypeOf(o);
}
function _setPrototypeOf(o, p) {
  _setPrototypeOf = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function _setPrototypeOf2(o2, p2) {
    o2.__proto__ = p2;
    return o2;
  };
  return _setPrototypeOf(o, p);
}
function _isNativeReflectConstruct() {
  if (typeof Reflect === "undefined" || !Reflect.construct)
    return false;
  if (Reflect.construct.sham)
    return false;
  if (typeof Proxy === "function")
    return true;
  try {
    Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function() {
    }));
    return true;
  } catch (e) {
    return false;
  }
}
function _assertThisInitialized(self) {
  if (self === void 0) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }
  return self;
}
function _possibleConstructorReturn(self, call) {
  if (call && (typeof call === "object" || typeof call === "function")) {
    return call;
  } else if (call !== void 0) {
    throw new TypeError("Derived constructors may only return object or undefined");
  }
  return _assertThisInitialized(self);
}
function _createSuper(Derived) {
  var hasNativeReflectConstruct = _isNativeReflectConstruct();
  return function _createSuperInternal() {
    var Super = _getPrototypeOf(Derived), result;
    if (hasNativeReflectConstruct) {
      var NewTarget = _getPrototypeOf(this).constructor;
      result = Reflect.construct(Super, arguments, NewTarget);
    } else {
      result = Super.apply(this, arguments);
    }
    return _possibleConstructorReturn(this, result);
  };
}
function _superPropBase(object, property) {
  while (!Object.prototype.hasOwnProperty.call(object, property)) {
    object = _getPrototypeOf(object);
    if (object === null)
      break;
  }
  return object;
}
function _get() {
  if (typeof Reflect !== "undefined" && Reflect.get) {
    _get = Reflect.get.bind();
  } else {
    _get = function _get2(target, property, receiver) {
      var base = _superPropBase(target, property);
      if (!base)
        return;
      var desc = Object.getOwnPropertyDescriptor(base, property);
      if (desc.get) {
        return desc.get.call(arguments.length < 3 ? target : receiver);
      }
      return desc.value;
    };
  }
  return _get.apply(this, arguments);
}
function _slicedToArray(arr, i) {
  return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest();
}
function _toConsumableArray(arr) {
  return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread();
}
function _arrayWithoutHoles(arr) {
  if (Array.isArray(arr))
    return _arrayLikeToArray(arr);
}
function _arrayWithHoles(arr) {
  if (Array.isArray(arr))
    return arr;
}
function _iterableToArray(iter) {
  if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null)
    return Array.from(iter);
}
function _unsupportedIterableToArray(o, minLen) {
  if (!o)
    return;
  if (typeof o === "string")
    return _arrayLikeToArray(o, minLen);
  var n = Object.prototype.toString.call(o).slice(8, -1);
  if (n === "Object" && o.constructor)
    n = o.constructor.name;
  if (n === "Map" || n === "Set")
    return Array.from(o);
  if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))
    return _arrayLikeToArray(o, minLen);
}
function _arrayLikeToArray(arr, len) {
  if (len == null || len > arr.length)
    len = arr.length;
  for (var i = 0, arr2 = new Array(len); i < len; i++)
    arr2[i] = arr[i];
  return arr2;
}
function _nonIterableSpread() {
  throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}
function _nonIterableRest() {
  throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}
function _toPrimitive(input, hint) {
  if (typeof input !== "object" || input === null)
    return input;
  var prim = input[Symbol.toPrimitive];
  if (prim !== void 0) {
    var res = prim.call(input, hint || "default");
    if (typeof res !== "object")
      return res;
    throw new TypeError("@@toPrimitive must return a primitive value.");
  }
  return (hint === "string" ? String : Number)(input);
}
function _toPropertyKey(arg) {
  var key = _toPrimitive(arg, "string");
  return typeof key === "symbol" ? key : String(key);
}
function throttle(delay, callback, options) {
  var _ref = options || {}, _ref$noTrailing = _ref.noTrailing, noTrailing = _ref$noTrailing === void 0 ? false : _ref$noTrailing, _ref$noLeading = _ref.noLeading, noLeading = _ref$noLeading === void 0 ? false : _ref$noLeading, _ref$debounceMode = _ref.debounceMode, debounceMode = _ref$debounceMode === void 0 ? void 0 : _ref$debounceMode;
  var timeoutID;
  var cancelled = false;
  var lastExec = 0;
  function clearExistingTimeout() {
    if (timeoutID) {
      clearTimeout(timeoutID);
    }
  }
  function cancel(options2) {
    var _ref2 = options2 || {}, _ref2$upcomingOnly = _ref2.upcomingOnly, upcomingOnly = _ref2$upcomingOnly === void 0 ? false : _ref2$upcomingOnly;
    clearExistingTimeout();
    cancelled = !upcomingOnly;
  }
  function wrapper() {
    for (var _len = arguments.length, arguments_ = new Array(_len), _key = 0; _key < _len; _key++) {
      arguments_[_key] = arguments[_key];
    }
    var self = this;
    var elapsed = Date.now() - lastExec;
    if (cancelled) {
      return;
    }
    function exec() {
      lastExec = Date.now();
      callback.apply(self, arguments_);
    }
    function clear() {
      timeoutID = void 0;
    }
    if (!noLeading && debounceMode && !timeoutID) {
      exec();
    }
    clearExistingTimeout();
    if (debounceMode === void 0 && elapsed > delay) {
      if (noLeading) {
        lastExec = Date.now();
        if (!noTrailing) {
          timeoutID = setTimeout(debounceMode ? clear : exec, delay);
        }
      } else {
        exec();
      }
    } else if (noTrailing !== true) {
      timeoutID = setTimeout(debounceMode ? clear : exec, debounceMode === void 0 ? delay - elapsed : delay);
    }
  }
  wrapper.cancel = cancel;
  return wrapper;
}
function debounce(delay, callback, options) {
  var _ref = options || {}, _ref$atBegin = _ref.atBegin, atBegin = _ref$atBegin === void 0 ? false : _ref$atBegin;
  return throttle(delay, callback, {
    debounceMode: atBegin !== false
  });
}
var esm = Object.freeze({
  __proto__: null,
  debounce,
  throttle
});
function factory(action) {
  return function(cb, time) {
    return action(time, cb);
  };
}
var throttle$1 = factory(esm.throttle);
var debounce$1 = factory(esm.debounce);
var reapply = function reapply2(options, context) {
  while (typeof options === "function") {
    options = options.call(context);
  }
  return options;
};
var omit = function omit2(obj, properties) {
  return Object.entries(obj).filter(function(_ref) {
    var _ref2 = _slicedToArray(_ref, 1), key = _ref2[0];
    return !properties.includes(key);
  }).reduce(function(c, _ref3) {
    var _ref4 = _slicedToArray(_ref3, 2), key = _ref4[0], val = _ref4[1];
    c[key] = val;
    return c;
  }, {});
};
var addGqlError = function addGqlError2(error) {
  if (error.graphQLErrors && error.graphQLErrors.length) {
    error.gqlError = error.graphQLErrors[0];
  }
};
var isServer = typeof window === "undefined";
var skippAllKeys = {
  query: "_skipAllQueries",
  subscription: "_skipAllSubscriptions"
};
var SmartApollo = function() {
  function SmartApollo2(vm, key, options) {
    _classCallCheck(this, SmartApollo2);
    _defineProperty(this, "type", null);
    _defineProperty(this, "vueApolloSpecialKeys", []);
    this.vm = vm;
    this.key = key;
    this.initialOptions = options;
    this.options = Object.assign({}, options);
    this._skip = false;
    this._pollInterval = null;
    this._watchers = [];
    this._destroyed = false;
    this.lastApolloOptions = null;
  }
  _createClass(SmartApollo2, [{
    key: "autostart",
    value: function autostart() {
      var _this = this;
      if (typeof this.options.skip === "function") {
        this._skipWatcher = this.vm.$watch(function() {
          return _this.options.skip.call(_this.vm, _this.vm, _this.key);
        }, this.skipChanged.bind(this), {
          immediate: true,
          deep: this.options.deep
        });
      } else if (!this.options.skip && !this.allSkip) {
        this.start();
      } else {
        this._skip = true;
      }
      if (typeof this.options.pollInterval === "function") {
        this._pollWatcher = this.vm.$watch(this.options.pollInterval.bind(this.vm), this.pollIntervalChanged.bind(this), {
          immediate: true
        });
      }
    }
  }, {
    key: "pollIntervalChanged",
    value: function pollIntervalChanged(value, oldValue) {
      if (value !== oldValue) {
        this.pollInterval = value;
        if (value == null) {
          this.stopPolling();
        } else {
          this.startPolling(value);
        }
      }
    }
  }, {
    key: "skipChanged",
    value: function skipChanged(value, oldValue) {
      if (value !== oldValue) {
        this.skip = value;
      }
    }
  }, {
    key: "pollInterval",
    get: function get() {
      return this._pollInterval;
    },
    set: function set(value) {
      this._pollInterval = value;
    }
  }, {
    key: "skip",
    get: function get() {
      return this._skip;
    },
    set: function set(value) {
      if (value || this.allSkip) {
        this.stop();
      } else {
        this.start();
      }
      this._skip = value;
    }
  }, {
    key: "allSkip",
    get: function get() {
      return this.vm.$apollo[skippAllKeys[this.type]];
    }
  }, {
    key: "refresh",
    value: function refresh() {
      if (!this._skip) {
        this.stop();
        this.start();
      }
    }
  }, {
    key: "start",
    value: function start() {
      var _this2 = this;
      this.starting = true;
      var _loop = function _loop2() {
        var prop = _ref2[_i2];
        if (typeof _this2.initialOptions[prop] === "function") {
          var queryCb = _this2.initialOptions[prop].bind(_this2.vm);
          _this2.options[prop] = queryCb();
          var cb2 = function cb3(query) {
            if (_this2._destroyed)
              return;
            _this2.options[prop] = query;
            _this2.refresh();
          };
          if (!isServer) {
            cb2 = _this2.options.throttle ? throttle$1(cb2, _this2.options.throttle) : cb2;
            cb2 = _this2.options.debounce ? debounce$1(cb2, _this2.options.debounce) : cb2;
          }
          _this2._watchers.push(_this2.vm.$watch(queryCb, cb2, {
            deep: _this2.options.deep
          }));
        }
      };
      for (var _i2 = 0, _ref2 = ["query", "document", "context"]; _i2 < _ref2.length; _i2++) {
        _loop();
      }
      if (typeof this.options.variables === "function") {
        var cb = this.executeApollo.bind(this);
        if (!isServer) {
          cb = this.options.throttle ? throttle$1(cb, this.options.throttle) : cb;
          cb = this.options.debounce ? debounce$1(cb, this.options.debounce) : cb;
        }
        this._watchers.push(this.vm.$watch(function() {
          return typeof _this2.options.variables === "function" ? _this2.options.variables.call(_this2.vm) : _this2.options.variables;
        }, cb, {
          immediate: true,
          deep: this.options.deep
        }));
      } else {
        this.executeApollo(this.options.variables);
      }
    }
  }, {
    key: "stop",
    value: function stop() {
      for (var _i4 = 0, _this$_watchers2 = this._watchers; _i4 < _this$_watchers2.length; _i4++) {
        var unwatch = _this$_watchers2[_i4];
        unwatch();
      }
      if (this.sub) {
        this.sub.unsubscribe();
        this.sub = null;
      }
    }
  }, {
    key: "generateApolloOptions",
    value: function generateApolloOptions(variables) {
      var apolloOptions = omit(this.options, this.vueApolloSpecialKeys);
      apolloOptions.variables = variables;
      this.lastApolloOptions = apolloOptions;
      return apolloOptions;
    }
  }, {
    key: "executeApollo",
    value: function executeApollo(variables) {
      this.starting = false;
    }
  }, {
    key: "nextResult",
    value: function nextResult(result) {
      var error = result.error;
      if (error)
        addGqlError(error);
    }
  }, {
    key: "callHandlers",
    value: function callHandlers(handlers) {
      var catched = false;
      for (var _len = arguments.length, args = new Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
        args[_key - 1] = arguments[_key];
      }
      for (var _i6 = 0; _i6 < handlers.length; _i6++) {
        var handler = handlers[_i6];
        if (handler) {
          catched = true;
          var result = handler.apply(this.vm, args);
          if (typeof result !== "undefined" && !result) {
            break;
          }
        }
      }
      return catched;
    }
  }, {
    key: "errorHandler",
    value: function errorHandler() {
      for (var _len2 = arguments.length, args = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
        args[_key2] = arguments[_key2];
      }
      return this.callHandlers.apply(this, [[this.options.error, this.vm.$apollo.error, this.vm.$apollo.provider.errorHandler]].concat(args));
    }
  }, {
    key: "catchError",
    value: function catchError(error) {
      addGqlError(error);
      var catched = this.errorHandler(error, this.vm, this.key, this.type, this.lastApolloOptions);
      if (catched)
        return;
      if (error.graphQLErrors && error.graphQLErrors.length !== 0) {
        console.error("GraphQL execution errors for ".concat(this.type, " '").concat(this.key, "'"));
        for (var _i8 = 0, _error$graphQLErrors2 = error.graphQLErrors; _i8 < _error$graphQLErrors2.length; _i8++) {
          var e = _error$graphQLErrors2[_i8];
          console.error(e);
        }
      } else if (error.networkError) {
        console.error("Error sending the ".concat(this.type, " '").concat(this.key, "'"), error.networkError);
      } else {
        console.error("[vue-apollo] An error has occurred for ".concat(this.type, " '").concat(this.key, "'"));
        if (Array.isArray(error)) {
          var _console;
          (_console = console).error.apply(_console, _toConsumableArray(error));
        } else {
          console.error(error);
        }
      }
    }
  }, {
    key: "destroy",
    value: function destroy2() {
      if (this._destroyed)
        return;
      this._destroyed = true;
      this.stop();
      if (this._skipWatcher) {
        this._skipWatcher();
      }
    }
  }]);
  return SmartApollo2;
}();
var VUE_APOLLO_QUERY_KEYWORDS = ["variables", "watch", "update", "result", "error", "loadingKey", "watchLoading", "skip", "throttle", "debounce", "subscribeToMore", "prefetch", "manual"];
var SmartQuery = function(_SmartApollo) {
  _inherits(SmartQuery2, _SmartApollo);
  var _super = _createSuper(SmartQuery2);
  function SmartQuery2(vm, key, options) {
    var _this;
    var autostart = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : true;
    _classCallCheck(this, SmartQuery2);
    if (vm.$data.$apolloData && !vm.$data.$apolloData.queries[key]) {
      vm.$data.$apolloData.queries[key] = {
        loading: false
      };
    }
    _this = _super.call(this, vm, key, options);
    _defineProperty(_assertThisInitialized(_this), "type", "query");
    _defineProperty(_assertThisInitialized(_this), "vueApolloSpecialKeys", VUE_APOLLO_QUERY_KEYWORDS);
    _defineProperty(_assertThisInitialized(_this), "_loading", false);
    _defineProperty(_assertThisInitialized(_this), "_linkedSubscriptions", []);
    if (isServer) {
      _this.firstRun = new Promise(function(resolve, reject) {
        _this._firstRunResolve = resolve;
        _this._firstRunReject = reject;
      });
    }
    if (isServer) {
      _this.options.fetchPolicy = "network-only";
    }
    if (!options.manual) {
      _this.hasDataField = Object.prototype.hasOwnProperty.call(_this.vm.$data, key);
      if (_this.hasDataField) {
        Object.defineProperty(_this.vm.$data.$apolloData.data, key, {
          get: function get() {
            return _this.vm.$data[key];
          },
          enumerable: true,
          configurable: true
        });
      } else {
        Object.defineProperty(_this.vm.$data, key, {
          get: function get() {
            return _this.vm.$data.$apolloData.data[key];
          },
          enumerable: true,
          configurable: true
        });
      }
    }
    if (autostart) {
      _this.autostart();
    }
    return _this;
  }
  _createClass(SmartQuery2, [{
    key: "client",
    get: function get() {
      return this.vm.$apollo.getClient(this.options);
    }
  }, {
    key: "loading",
    get: function get() {
      return this.vm.$data.$apolloData && this.vm.$data.$apolloData.queries[this.key] ? this.vm.$data.$apolloData.queries[this.key].loading : this._loading;
    },
    set: function set(value) {
      if (this._loading !== value) {
        this._loading = value;
        if (this.vm.$data.$apolloData && this.vm.$data.$apolloData.queries[this.key]) {
          this.vm.$data.$apolloData.queries[this.key].loading = value;
          this.vm.$data.$apolloData.loading += value ? 1 : -1;
        }
      }
    }
  }, {
    key: "stop",
    value: function stop() {
      _get(_getPrototypeOf(SmartQuery2.prototype), "stop", this).call(this);
      this.loadingDone();
      if (this.observer) {
        this.observer.stopPolling();
        this.observer = null;
      }
    }
  }, {
    key: "generateApolloOptions",
    value: function generateApolloOptions(variables) {
      var apolloOptions = _get(_getPrototypeOf(SmartQuery2.prototype), "generateApolloOptions", this).call(this, variables);
      if (this.vm.$isServer) {
        delete apolloOptions.pollInterval;
      }
      return apolloOptions;
    }
  }, {
    key: "executeApollo",
    value: function executeApollo(variables) {
      if (this._destroyed)
        return;
      var variablesJson = JSON.stringify(variables);
      if (this.sub) {
        if (variablesJson === this.previousVariablesJson) {
          return;
        }
        this.sub.unsubscribe();
        for (var _i2 = 0, _this$_linkedSubscrip2 = this._linkedSubscriptions; _i2 < _this$_linkedSubscrip2.length; _i2++) {
          var sub = _this$_linkedSubscrip2[_i2];
          sub.stop();
        }
      }
      this.previousVariablesJson = variablesJson;
      this.observer = this.vm.$apollo.watchQuery(this.generateApolloOptions(variables));
      this.startQuerySubscription();
      if (this.options.fetchPolicy !== "no-cache" || this.options.notifyOnNetworkStatusChange) {
        var currentResult = this.retrieveCurrentResult();
        if (this.options.notifyOnNetworkStatusChange || // Initial call of next result when it's not loading (for Apollo Client 3)
        this.observer.getCurrentResult && !currentResult.loading) {
          this.nextResult(currentResult);
        }
      }
      _get(_getPrototypeOf(SmartQuery2.prototype), "executeApollo", this).call(this, variables);
      for (var _i4 = 0, _this$_linkedSubscrip4 = this._linkedSubscriptions; _i4 < _this$_linkedSubscrip4.length; _i4++) {
        var _sub = _this$_linkedSubscrip4[_i4];
        _sub.start();
      }
    }
  }, {
    key: "startQuerySubscription",
    value: function startQuerySubscription() {
      if (this.sub && !this.sub.closed)
        return;
      this.sub = this.observer.subscribe({
        next: this.nextResult.bind(this),
        error: this.catchError.bind(this)
      });
    }
    /**
     * May update loading state
     */
  }, {
    key: "retrieveCurrentResult",
    value: function retrieveCurrentResult() {
      var force = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : false;
      var currentResult = this.observer.getCurrentResult ? this.observer.getCurrentResult() : this.observer.currentResult();
      if (force || currentResult.loading) {
        if (!this.loading) {
          this.applyLoadingModifier(1);
        }
        this.loading = true;
      }
      return currentResult;
    }
  }, {
    key: "nextResult",
    value: function nextResult(result) {
      _get(_getPrototypeOf(SmartQuery2.prototype), "nextResult", this).call(this, result);
      var data = result.data, loading = result.loading, error = result.error, errors = result.errors;
      var anyErrors = errors && errors.length;
      if (error || anyErrors) {
        this.firstRunReject(error);
      }
      if (!loading) {
        this.loadingDone();
      }
      if (!error && anyErrors) {
        var e = new Error("GraphQL error: ".concat(errors.map(function(e2) {
          return e2.message;
        }).join(" | ")));
        Object.assign(e, {
          graphQLErrors: errors,
          networkError: null
        });
        _get(_getPrototypeOf(SmartQuery2.prototype), "catchError", this).call(this, e);
      }
      if (this.observer.options.errorPolicy === "none" && (error || anyErrors)) {
        return;
      }
      var hasResultCallback = typeof this.options.result === "function";
      if (data == null)
        ;
      else if (!this.options.manual) {
        if (typeof this.options.update === "function") {
          this.setData(this.options.update.call(this.vm, data));
        } else if (typeof data[this.key] === "undefined" && Object.keys(data).length) {
          console.error("Missing ".concat(this.key, " attribute on result"), data);
        } else {
          this.setData(data[this.key]);
        }
      } else if (!hasResultCallback) {
        console.error("".concat(this.key, " query must have a 'result' hook in manual mode"));
      }
      if (hasResultCallback) {
        this.options.result.call(this.vm, result, this.key);
      }
    }
  }, {
    key: "setData",
    value: function setData(value) {
      var target = this.hasDataField ? this.vm.$data : this.vm.$data.$apolloData.data;
      target[this.key] = value;
    }
  }, {
    key: "catchError",
    value: function catchError(error) {
      _get(_getPrototypeOf(SmartQuery2.prototype), "catchError", this).call(this, error);
      this.firstRunReject(error);
      this.loadingDone(error);
      this.nextResult(this.observer.getCurrentResult ? this.observer.getCurrentResult() : this.observer.currentResult());
      this.resubscribeToQuery();
    }
  }, {
    key: "resubscribeToQuery",
    value: function resubscribeToQuery() {
      var lastError = this.observer.getLastError();
      var lastResult = this.observer.getLastResult();
      this.observer.resetLastResults();
      this.startQuerySubscription();
      Object.assign(this.observer, {
        lastError,
        lastResult
      });
    }
  }, {
    key: "loadingKey",
    get: function get() {
      return this.options.loadingKey || this.vm.$apollo.loadingKey;
    }
  }, {
    key: "watchLoading",
    value: function watchLoading() {
      for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }
      return this.callHandlers.apply(this, [[this.options.watchLoading, this.vm.$apollo.watchLoading, this.vm.$apollo.provider.watchLoading]].concat(args, [this]));
    }
  }, {
    key: "applyLoadingModifier",
    value: function applyLoadingModifier(value) {
      var loadingKey = this.loadingKey;
      if (loadingKey && typeof this.vm[loadingKey] === "number") {
        this.vm[loadingKey] += value;
      }
      this.watchLoading(value === 1, value);
    }
  }, {
    key: "loadingDone",
    value: function loadingDone() {
      var error = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : null;
      if (this.loading) {
        this.applyLoadingModifier(-1);
      }
      this.loading = false;
      if (!error) {
        this.firstRunResolve();
      }
    }
  }, {
    key: "fetchMore",
    value: function fetchMore() {
      var _this2 = this;
      if (this.observer) {
        var _this$observer;
        this.retrieveCurrentResult(true);
        return (_this$observer = this.observer).fetchMore.apply(_this$observer, arguments).then(function(result) {
          if (!result.loading) {
            _this2.loadingDone();
          }
          return result;
        });
      }
    }
  }, {
    key: "subscribeToMore",
    value: function subscribeToMore() {
      if (this.observer) {
        var _this$observer2;
        return {
          unsubscribe: (_this$observer2 = this.observer).subscribeToMore.apply(_this$observer2, arguments)
        };
      }
    }
  }, {
    key: "refetch",
    value: function refetch(variables) {
      var _this3 = this;
      variables && (this.options.variables = variables);
      if (this.observer) {
        var result = this.observer.refetch(variables).then(function(result2) {
          if (!result2.loading) {
            _this3.loadingDone();
          }
          return result2;
        });
        this.retrieveCurrentResult();
        return result;
      }
    }
  }, {
    key: "setVariables",
    value: function setVariables(variables, tryFetch) {
      this.options.variables = variables;
      if (this.observer) {
        var result = this.observer.setVariables(variables, tryFetch);
        this.retrieveCurrentResult();
        return result;
      }
    }
  }, {
    key: "setOptions",
    value: function setOptions(options) {
      Object.assign(this.options, options);
      if (this.observer) {
        var result = this.observer.setOptions(options);
        this.retrieveCurrentResult();
        return result;
      }
    }
  }, {
    key: "startPolling",
    value: function startPolling() {
      if (this.observer) {
        var _this$observer3;
        return (_this$observer3 = this.observer).startPolling.apply(_this$observer3, arguments);
      }
    }
  }, {
    key: "stopPolling",
    value: function stopPolling() {
      if (this.observer) {
        var _this$observer4;
        return (_this$observer4 = this.observer).stopPolling.apply(_this$observer4, arguments);
      }
    }
  }, {
    key: "firstRunResolve",
    value: function firstRunResolve() {
      if (this._firstRunResolve) {
        this._firstRunResolve();
        this._firstRunResolve = null;
      }
    }
  }, {
    key: "firstRunReject",
    value: function firstRunReject(error) {
      if (this._firstRunReject) {
        this._firstRunReject(error);
        this._firstRunReject = null;
      }
    }
  }, {
    key: "destroy",
    value: function destroy2() {
      _get(_getPrototypeOf(SmartQuery2.prototype), "destroy", this).call(this);
      if (this.loading) {
        this.watchLoading(false, -1);
      }
      this.loading = false;
    }
  }]);
  return SmartQuery2;
}(SmartApollo);
var MAX_RETRIES = 5;
var DELAY_MS = 500;
var SmartSubscription = function(_SmartApollo) {
  _inherits(SmartSubscription2, _SmartApollo);
  var _super = _createSuper(SmartSubscription2);
  function SmartSubscription2(vm, key, options) {
    var _this;
    var autostart = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : true;
    _classCallCheck(this, SmartSubscription2);
    _this = _super.call(this, vm, key, options);
    _defineProperty(_assertThisInitialized(_this), "type", "subscription");
    _defineProperty(_assertThisInitialized(_this), "vueApolloSpecialKeys", ["variables", "result", "error", "throttle", "debounce", "linkedQuery"]);
    _this.attempts = 0;
    if (autostart) {
      _this.autostart();
    }
    return _this;
  }
  _createClass(SmartSubscription2, [{
    key: "generateApolloOptions",
    value: function generateApolloOptions(variables) {
      var apolloOptions = _get(_getPrototypeOf(SmartSubscription2.prototype), "generateApolloOptions", this).call(this, variables);
      apolloOptions.onError = this.catchError.bind(this);
      return apolloOptions;
    }
  }, {
    key: "executeApollo",
    value: function executeApollo(variables) {
      if (this._destroyed)
        return;
      var variablesJson = JSON.stringify(variables);
      if (this.sub) {
        if (variablesJson === this.previousVariablesJson) {
          return;
        }
        this.sub.unsubscribe();
      }
      this.previousVariablesJson = variablesJson;
      var apolloOptions = this.generateApolloOptions(variables);
      if (typeof apolloOptions.updateQuery === "function") {
        apolloOptions.updateQuery = apolloOptions.updateQuery.bind(this.vm);
      }
      if (this.options.linkedQuery) {
        if (typeof this.options.result === "function") {
          var rcb = this.options.result.bind(this.vm);
          var ucb = apolloOptions.updateQuery && apolloOptions.updateQuery.bind(this.vm);
          apolloOptions.updateQuery = function() {
            rcb.apply(void 0, arguments);
            return ucb && ucb.apply(void 0, arguments);
          };
        }
        this.sub = this.options.linkedQuery.subscribeToMore(apolloOptions);
      } else {
        this.observer = this.vm.$apollo.subscribe(apolloOptions);
        this.sub = this.observer.subscribe({
          next: this.nextResult.bind(this),
          error: this.catchError.bind(this)
        });
      }
      _get(_getPrototypeOf(SmartSubscription2.prototype), "executeApollo", this).call(this, variables);
    }
  }, {
    key: "nextResult",
    value: function nextResult(data) {
      _get(_getPrototypeOf(SmartSubscription2.prototype), "nextResult", this).call(this, data);
      this.attempts = 0;
      if (typeof this.options.result === "function") {
        this.options.result.call(this.vm, data, this.key);
      }
    }
  }, {
    key: "catchError",
    value: function catchError(error) {
      _get(_getPrototypeOf(SmartSubscription2.prototype), "catchError", this).call(this, error);
      if (this.skip || this.attempts >= MAX_RETRIES) {
        return;
      }
      this.stop();
      this.retryTimeout = setTimeout(this.start.bind(this), Math.pow(2, this.attempts) * DELAY_MS);
      this.attempts++;
    }
  }, {
    key: "stop",
    value: function stop() {
      _get(_getPrototypeOf(SmartSubscription2.prototype), "stop", this).call(this);
      clearTimeout(this.retryTimeout);
    }
  }]);
  return SmartSubscription2;
}(SmartApollo);
var DollarApollo = function() {
  function DollarApollo2(vm, provider) {
    _classCallCheck(this, DollarApollo2);
    this._apolloSubscriptions = [];
    this._watchers = [];
    this.vm = vm;
    this.provider = provider;
    this.queries = {};
    this.subscriptions = {};
    this.client = void 0;
    this.loadingKey = void 0;
    this.error = void 0;
  }
  _createClass(DollarApollo2, [{
    key: "getClient",
    value: function getClient() {
      var options = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : null;
      if (!options || !options.client) {
        if (_typeof(this.client) === "object") {
          return this.client;
        }
        if (this.client) {
          if (!this.provider.clients) {
            throw new Error("[vue-apollo] Missing 'clients' options in 'apolloProvider'");
          } else {
            var _client = this.provider.clients[this.client];
            if (!_client) {
              throw new Error("[vue-apollo] Missing client '".concat(this.client, "' in 'apolloProvider'"));
            }
            return _client;
          }
        }
        return this.provider.defaultClient;
      }
      var client = this.provider.clients[options.client];
      if (!client) {
        throw new Error("[vue-apollo] Missing client '".concat(options.client, "' in 'apolloProvider'"));
      }
      return client;
    }
  }, {
    key: "query",
    value: function query(options) {
      return this.getClient(options).query(options);
    }
  }, {
    key: "watchQuery",
    value: function watchQuery(options) {
      var _this = this;
      var observable = this.getClient(options).watchQuery(options);
      var _subscribe = observable.subscribe.bind(observable);
      observable.subscribe = function(options2) {
        var sub = _subscribe(options2);
        _this._apolloSubscriptions.push(sub);
        return sub;
      };
      return observable;
    }
  }, {
    key: "mutate",
    value: function mutate(options) {
      return this.getClient(options).mutate(options);
    }
  }, {
    key: "subscribe",
    value: function subscribe(options) {
      var _this2 = this;
      if (!isServer) {
        var observable = this.getClient(options).subscribe(options);
        var _subscribe = observable.subscribe.bind(observable);
        observable.subscribe = function(options2) {
          var sub = _subscribe(options2);
          _this2._apolloSubscriptions.push(sub);
          return sub;
        };
        return observable;
      }
    }
  }, {
    key: "loading",
    get: function get() {
      return this.vm.$data.$apolloData.loading !== 0;
    }
  }, {
    key: "data",
    get: function get() {
      return this.vm.$data.$apolloData.data;
    }
  }, {
    key: "addSmartQuery",
    value: function addSmartQuery(key, options) {
      var _this3 = this;
      var finalOptions = reapply(options, this.vm);
      if (!finalOptions.query) {
        var query = finalOptions;
        finalOptions = {
          query
        };
      }
      var apollo = this.vm.$options.apollo;
      var defaultOptions = this.provider.defaultOptions;
      var $query;
      if (defaultOptions && defaultOptions.$query) {
        $query = defaultOptions.$query;
      }
      if (apollo && apollo.$query) {
        $query = _objectSpread2(_objectSpread2({}, $query || {}), apollo.$query);
      }
      if ($query) {
        for (var _key in $query) {
          if (typeof finalOptions[_key] === "undefined") {
            finalOptions[_key] = $query[_key];
          }
        }
      }
      var smart = this.queries[key] = new SmartQuery(this.vm, key, finalOptions, false);
      if (!isServer || finalOptions.prefetch !== false) {
        smart.autostart();
      }
      if (!isServer) {
        var subs = finalOptions.subscribeToMore;
        if (subs) {
          if (Array.isArray(subs)) {
            subs.forEach(function(sub, index) {
              _this3.addSmartSubscription("".concat(key).concat(index), _objectSpread2(_objectSpread2({}, sub), {}, {
                linkedQuery: smart
              }));
            });
          } else {
            this.addSmartSubscription(key, _objectSpread2(_objectSpread2({}, subs), {}, {
              linkedQuery: smart
            }));
          }
        }
      }
      return smart;
    }
  }, {
    key: "addSmartSubscription",
    value: function addSmartSubscription(key, options) {
      if (!isServer) {
        options = reapply(options, this.vm);
        var smart = this.subscriptions[key] = new SmartSubscription(this.vm, key, options, false);
        smart.autostart();
        if (options.linkedQuery) {
          var index = options.linkedQuery._linkedSubscriptions.findIndex(function(x) {
            return x.key === key;
          });
          if (index !== -1) {
            options.linkedQuery._linkedSubscriptions[index] = smart;
          } else {
            options.linkedQuery._linkedSubscriptions.push(smart);
          }
        }
        return smart;
      }
    }
  }, {
    key: "defineReactiveSetter",
    value: function defineReactiveSetter2(key, func, deep) {
      var _this4 = this;
      this._watchers.push(this.vm.$watch(func, function(value) {
        _this4[key] = value;
      }, {
        immediate: true,
        deep
      }));
    }
  }, {
    key: "skipAllQueries",
    set: function set(value) {
      this._skipAllQueries = value;
      for (var key in this.queries) {
        this.queries[key].skip = value;
      }
    }
  }, {
    key: "skipAllSubscriptions",
    set: function set(value) {
      this._skipAllSubscriptions = value;
      for (var key in this.subscriptions) {
        this.subscriptions[key].skip = value;
      }
    }
  }, {
    key: "skipAll",
    set: function set(value) {
      this.skipAllQueries = value;
      this.skipAllSubscriptions = value;
    }
  }, {
    key: "destroy",
    value: function destroy2() {
      for (var _i2 = 0, _this$_watchers2 = this._watchers; _i2 < _this$_watchers2.length; _i2++) {
        var unwatch = _this$_watchers2[_i2];
        unwatch();
      }
      for (var key in this.queries) {
        this.queries[key].destroy();
      }
      for (var _key2 in this.subscriptions) {
        this.subscriptions[_key2].destroy();
      }
      this._apolloSubscriptions.forEach(function(sub) {
        sub.unsubscribe();
      });
      this._apolloSubscriptions = null;
      this.vm = null;
    }
  }]);
  return DollarApollo2;
}();
function hasProperty(holder, key) {
  return typeof holder !== "undefined" && Object.prototype.hasOwnProperty.call(holder, key);
}
function launch() {
  var _this = this;
  var apolloProvider = this.$apolloProvider;
  if (this._apolloLaunched || !apolloProvider)
    return;
  this._apolloLaunched = true;
  var apollo = this.$options.apollo;
  if (apollo) {
    this.$_apolloPromises = [];
    if (!apollo.$init) {
      apollo.$init = true;
      if (apolloProvider.defaultOptions) {
        apollo = this.$options.apollo = Object.assign({}, apolloProvider.defaultOptions, apollo);
      }
    }
    defineReactiveSetter(this.$apollo, "skipAll", apollo.$skipAll, apollo.$deep);
    defineReactiveSetter(this.$apollo, "skipAllQueries", apollo.$skipAllQueries, apollo.$deep);
    defineReactiveSetter(this.$apollo, "skipAllSubscriptions", apollo.$skipAllSubscriptions, apollo.$deep);
    defineReactiveSetter(this.$apollo, "client", apollo.$client, apollo.$deep);
    defineReactiveSetter(this.$apollo, "loadingKey", apollo.$loadingKey, apollo.$deep);
    defineReactiveSetter(this.$apollo, "error", apollo.$error, apollo.$deep);
    defineReactiveSetter(this.$apollo, "watchLoading", apollo.$watchLoading, apollo.$deep);
    Object.defineProperty(this, "$apolloData", {
      get: function get() {
        return _this.$data.$apolloData;
      },
      enumerable: true,
      configurable: true
    });
    for (var key in apollo) {
      if (key.charAt(0) !== "$") {
        var options = apollo[key];
        var smart = this.$apollo.addSmartQuery(key, options);
        if (isServer) {
          options = reapply(options, this);
          if (apolloProvider.prefetch !== false && options.prefetch !== false && apollo.$prefetch !== false && !smart.skip) {
            this.$_apolloPromises.push(smart.firstRun);
          }
        }
      }
    }
    if (apollo.subscribe) {
      console.warn("vue-apollo -> `subscribe` option is deprecated. Use the `$subscribe` option instead.");
    }
    if (apollo.$subscribe) {
      for (var _key in apollo.$subscribe) {
        this.$apollo.addSmartSubscription(_key, apollo.$subscribe[_key]);
      }
    }
  }
}
function defineReactiveSetter($apollo, key, value, deep) {
  if (typeof value !== "undefined") {
    if (typeof value === "function") {
      $apollo.defineReactiveSetter(key, value, deep);
    } else {
      $apollo[key] = value;
    }
  }
}
function destroy() {
  if (this.$apollo) {
    this.$apollo.destroy();
    this.$apollo = null;
  }
}
function installMixin(app, provider) {
  app.mixin({
    data: function data() {
      var result = {
        $apolloData: {
          queries: {},
          loading: 0,
          data: {}
        }
      };
      var apollo = this.$options.apollo;
      if (apollo) {
        for (var key in apollo) {
          if (key.charAt(0) !== "$") {
            var options = apollo[key];
            if (!options.manual && !hasProperty(this.$options.props, key) && !hasProperty(this.$options.computed, key) && !hasProperty(this.$options.methods, key)) {
              result[key] = null;
            }
          }
        }
      }
      return result;
    },
    beforeCreate: function beforeCreate() {
      var _this2 = this;
      this.$apollo = new DollarApollo(this, provider);
      if (isServer) {
        var render = this.$options.ssrRender;
        if (!render)
          return;
        if (render.__IS_VUE_APOLLO_WRAPPED)
          return;
        this.$options.ssrRender = function(h) {
          var result = render.call(_this2, h);
          destroy.call(_this2);
          return result;
        };
        this.$options.ssrRender.__IS_VUE_APOLLO_WRAPPED = true;
      }
    },
    serverPrefetch: function serverPrefetch() {
      var _this3 = this;
      if (this.$_apolloPromises) {
        return Promise.all(this.$_apolloPromises).then(function() {
          var mocked = {
            vm: _this3,
            provider: _this3.$apollo.provider,
            loading: false,
            queries: {},
            subscriptions: {}
          };
          destroy.call(_this3);
          _this3.$apollo = mocked;
        })["catch"](function(e) {
          destroy.call(_this3);
          return Promise.reject(e);
        });
      }
    },
    created: launch,
    unmounted: destroy
  });
}
var keywords = ["$subscribe"];
var ApolloProvider = function() {
  function ApolloProvider2(options) {
    _classCallCheck(this, ApolloProvider2);
    if (!options) {
      throw new Error("Options argument required");
    }
    this.clients = options.clients || {};
    if (options.defaultClient) {
      this.clients.defaultClient = this.defaultClient = options.defaultClient;
    }
    this.defaultOptions = options.defaultOptions;
    this.watchLoading = options.watchLoading;
    this.errorHandler = options.errorHandler;
    this.prefetch = options.prefetch;
  }
  _createClass(ApolloProvider2, [{
    key: "install",
    value: function install(app) {
      app.config.optionMergeStrategies.apollo = function(toVal, fromVal, vm) {
        if (!toVal)
          return fromVal;
        if (!fromVal)
          return toVal;
        var toData = Object.assign({}, omit(toVal, keywords), toVal.data);
        var fromData = Object.assign({}, omit(fromVal, keywords), fromVal.data);
        var map = {};
        for (var i = 0; i < keywords.length; i++) {
          var key = keywords[i];
          map[key] = mergeObjectOptions(toVal[key], fromVal[key]);
        }
        return Object.assign(map, mergeObjectOptions(toData, fromData));
      };
      app.config.globalProperties.$apolloProvider = this;
      installMixin(app, this);
    }
  }]);
  return ApolloProvider2;
}();
function mergeObjectOptions(to, from) {
  return to ? Object.assign(Object.assign(/* @__PURE__ */ Object.create(null), to), from) : from;
}
function createApolloProvider(options) {
  return new ApolloProvider(options);
}
export {
  ApolloProvider,
  createApolloProvider
};
//# sourceMappingURL=@vue_apollo-option.js.map
