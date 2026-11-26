import {
  BaseStyle,
  script
} from "./chunk-3S3LM2QE.js";
import "./chunk-NDGVBBWC.js";
import "./chunk-QMU5P4ZK.js";
import {
  createBaseVNode,
  createBlock,
  createCommentVNode,
  createElementBlock,
  mergeProps,
  openBlock,
  renderSlot,
  resolveDynamicComponent,
  toDisplayString
} from "./chunk-KQEHREBW.js";
import "./chunk-7REXU52E.js";

// node_modules/primevue/tag/style/tagstyle.esm.js
var css = "\n@layer primevue {\n    .p-tag {\n        display: inline-flex;\n        align-items: center;\n        justify-content: center;\n    }\n\n    .p-tag-icon,\n    .p-tag-value,\n    .p-tag-icon.pi {\n        line-height: 1.5;\n    }\n\n    .p-tag.p-tag-rounded {\n        border-radius: 10rem;\n    }\n}\n";
var classes = {
  root: function root(_ref) {
    var props = _ref.props;
    return ["p-tag p-component", {
      "p-tag-info": props.severity === "info",
      "p-tag-success": props.severity === "success",
      "p-tag-warning": props.severity === "warning",
      "p-tag-danger": props.severity === "danger",
      "p-tag-rounded": props.rounded
    }];
  },
  icon: "p-tag-icon",
  value: "p-tag-value"
};
var TagStyle = BaseStyle.extend({
  name: "tag",
  css,
  classes
});

// node_modules/primevue/tag/tag.esm.js
var script$1 = {
  name: "BaseTag",
  "extends": script,
  props: {
    value: null,
    severity: null,
    rounded: Boolean,
    icon: String
  },
  style: TagStyle,
  provide: function provide() {
    return {
      $parentInstance: this
    };
  }
};
var script2 = {
  name: "Tag",
  "extends": script$1
};
function render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("span", mergeProps({
    "class": _ctx.cx("root")
  }, _ctx.ptm("root"), {
    "data-pc-name": "tag"
  }), [_ctx.$slots.icon ? (openBlock(), createBlock(resolveDynamicComponent(_ctx.$slots.icon), mergeProps({
    key: 0,
    "class": _ctx.cx("icon")
  }, _ctx.ptm("icon")), null, 16, ["class"])) : _ctx.icon ? (openBlock(), createElementBlock("span", mergeProps({
    key: 1,
    "class": [_ctx.cx("icon"), _ctx.icon]
  }, _ctx.ptm("icon")), null, 16)) : createCommentVNode("", true), renderSlot(_ctx.$slots, "default", {}, function() {
    return [createBaseVNode("span", mergeProps({
      "class": _ctx.cx("value")
    }, _ctx.ptm("value")), toDisplayString(_ctx.value), 17)];
  })], 16);
}
script2.render = render;
export {
  script2 as default
};
//# sourceMappingURL=primevue_tag.js.map
