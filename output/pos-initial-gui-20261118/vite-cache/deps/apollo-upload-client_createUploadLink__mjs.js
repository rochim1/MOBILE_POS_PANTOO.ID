import {
  createSignalIfSupported,
  defaultPrinter,
  fallbackHttpConfig,
  parseAndCheckHttpResponse,
  rewriteURIForGET,
  selectHttpOptionsAndBodyInternal,
  selectURI,
  serializeFetchParameter
} from "./chunk-TNCUSYY4.js";
import {
  ApolloLink,
  Observable
} from "./chunk-4BEZVPTL.js";
import "./chunk-4C76XFJM.js";
import "./chunk-CZXMGLK4.js";
import "./chunk-7REXU52E.js";

// node_modules/is-plain-obj/index.js
function isPlainObject(value) {
  if (typeof value !== "object" || value === null) {
    return false;
  }
  const prototype = Object.getPrototypeOf(value);
  return (prototype === null || prototype === Object.prototype || Object.getPrototypeOf(prototype) === null) && !(Symbol.toStringTag in value) && !(Symbol.iterator in value);
}

// node_modules/extract-files/extractFiles.mjs
function extractFiles(value, isExtractable, path = "") {
  if (!arguments.length)
    throw new TypeError("Argument 1 `value` is required.");
  if (typeof isExtractable !== "function")
    throw new TypeError("Argument 2 `isExtractable` must be a function.");
  if (typeof path !== "string")
    throw new TypeError("Argument 3 `path` must be a string.");
  const clones = /* @__PURE__ */ new Map();
  const files = /* @__PURE__ */ new Map();
  function recurse(value2, path2, recursed) {
    if (isExtractable(value2)) {
      const filePaths = files.get(value2);
      filePaths ? filePaths.push(path2) : files.set(value2, [path2]);
      return null;
    }
    const valueIsList = Array.isArray(value2) || typeof FileList !== "undefined" && value2 instanceof FileList;
    const valueIsPlainObject = isPlainObject(value2);
    if (valueIsList || valueIsPlainObject) {
      let clone = clones.get(value2);
      const uncloned = !clone;
      if (uncloned) {
        clone = valueIsList ? [] : (
          // Replicate if the plain object is an `Object` instance.
          value2 instanceof /** @type {any} */
          Object ? {} : /* @__PURE__ */ Object.create(null)
        );
        clones.set(
          value2,
          /** @type {Clone} */
          clone
        );
      }
      if (!recursed.has(value2)) {
        const pathPrefix = path2 ? `${path2}.` : "";
        const recursedDeeper = new Set(recursed).add(value2);
        if (valueIsList) {
          let index = 0;
          for (const item of value2) {
            const itemClone = recurse(
              item,
              pathPrefix + index++,
              recursedDeeper
            );
            if (uncloned)
              clone.push(itemClone);
          }
        } else
          for (const key in value2) {
            const propertyClone = recurse(
              value2[key],
              pathPrefix + key,
              recursedDeeper
            );
            if (uncloned)
              clone[key] = propertyClone;
          }
      }
      return clone;
    }
    return value2;
  }
  return {
    clone: recurse(value, path, /* @__PURE__ */ new Set()),
    files
  };
}

// node_modules/apollo-upload-client/formDataAppendFile.mjs
function formDataAppendFile(formData, fieldName, file) {
  "name" in file ? formData.append(fieldName, file, file.name) : formData.append(fieldName, file);
}

// node_modules/extract-files/isExtractableFile.mjs
function isExtractableFile(value) {
  return typeof File !== "undefined" && value instanceof File || typeof Blob !== "undefined" && value instanceof Blob;
}

// node_modules/apollo-upload-client/createUploadLink.mjs
function createUploadLink({
  uri: fetchUri = "/graphql",
  useGETForQueries,
  isExtractableFile: customIsExtractableFile = isExtractableFile,
  FormData: CustomFormData,
  formDataAppendFile: customFormDataAppendFile = formDataAppendFile,
  print = defaultPrinter,
  fetch: customFetch,
  fetchOptions,
  credentials,
  headers,
  includeExtensions
} = {}) {
  const linkConfig = {
    http: { includeExtensions },
    options: fetchOptions,
    credentials,
    headers
  };
  return new ApolloLink((operation) => {
    const context = (
      /**
       * @type {import("@apollo/client/core/types.js").DefaultContext & {
       *   clientAwareness?: {
       *     name?: string,
       *     version?: string,
       *   },
       * }}
       */
      operation.getContext()
    );
    const {
      // Apollo Studio client awareness `name` and `version` can be configured
      // via `ApolloClient` constructor options:
      // https://www.apollographql.com/docs/graphos/metrics/client-awareness/#setup
      clientAwareness: { name, version } = {},
      headers: headers2
    } = context;
    const contextConfig = {
      http: context.http,
      options: context.fetchOptions,
      credentials: context.credentials,
      headers: {
        // Client awareness headers can be overridden by context `headers`.
        ...name && { "apollographql-client-name": name },
        ...version && { "apollographql-client-version": version },
        ...headers2
      }
    };
    const { options, body } = selectHttpOptionsAndBodyInternal(
      operation,
      print,
      fallbackHttpConfig,
      linkConfig,
      contextConfig
    );
    const { clone, files } = extractFiles(body, customIsExtractableFile, "");
    let uri = selectURI(operation, fetchUri);
    if (files.size) {
      if (options.headers)
        delete options.headers["content-type"];
      const RuntimeFormData = CustomFormData || FormData;
      const form = new RuntimeFormData();
      form.append("operations", serializeFetchParameter(clone, "Payload"));
      const map = {};
      let i = 0;
      files.forEach((paths) => {
        map[++i] = paths;
      });
      form.append("map", JSON.stringify(map));
      i = 0;
      files.forEach((_paths, file) => {
        customFormDataAppendFile(form, String(++i), file);
      });
      options.body = form;
    } else {
      if (useGETForQueries && // If the operation contains some mutations GET shouldn’t be used.
      !operation.query.definitions.some(
        (definition) => definition.kind === "OperationDefinition" && definition.operation === "mutation"
      ))
        options.method = "GET";
      if (options.method === "GET") {
        const { newURI, parseError } = rewriteURIForGET(uri, body);
        if (parseError)
          return new Observable((observer) => {
            observer.error(parseError);
          });
        uri = newURI;
      } else
        options.body = serializeFetchParameter(clone, "Payload");
    }
    const { controller } = createSignalIfSupported();
    if (typeof controller !== "boolean") {
      if (options.signal)
        options.signal.aborted ? (
          // Signal already aborted, so immediately abort.
          controller.abort()
        ) : (
          // Signal not already aborted, so setup a listener to abort when it
          // does.
          options.signal.addEventListener(
            "abort",
            () => {
              controller.abort();
            },
            {
              // Prevent a memory leak if the user configured abort controller
              // is long lasting, or controls multiple things.
              once: true
            }
          )
        );
      options.signal = controller.signal;
    }
    const runtimeFetch = customFetch || fetch;
    return new Observable((observer) => {
      let cleaningUp;
      runtimeFetch(uri, options).then((response) => {
        operation.setContext({ response });
        return response;
      }).then(parseAndCheckHttpResponse(operation)).then((result) => {
        observer.next(result);
        observer.complete();
      }).catch((error) => {
        if (!cleaningUp) {
          if (error.result && error.result.errors && error.result.data)
            observer.next(error.result);
          observer.error(error);
        }
      });
      return () => {
        cleaningUp = true;
        if (typeof controller !== "boolean")
          controller.abort();
      };
    });
  });
}
export {
  createUploadLink as default
};
//# sourceMappingURL=apollo-upload-client_createUploadLink__mjs.js.map
