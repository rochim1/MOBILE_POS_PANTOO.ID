import {
  script
} from "./chunk-3S3LM2QE.js";
import "./chunk-NDGVBBWC.js";
import "./chunk-QMU5P4ZK.js";
import "./chunk-KQEHREBW.js";
import "./chunk-7REXU52E.js";

// node_modules/primevue/row/row.esm.js
var script2 = {
  name: "Row",
  "extends": script,
  inject: ["$rows"],
  mounted: function mounted() {
    var _this$$rows;
    (_this$$rows = this.$rows) === null || _this$$rows === void 0 || _this$$rows.add(this.$);
  },
  unmounted: function unmounted() {
    var _this$$rows2;
    (_this$$rows2 = this.$rows) === null || _this$$rows2 === void 0 || _this$$rows2["delete"](this.$);
  },
  render: function render() {
    return null;
  }
};
export {
  script2 as default
};
//# sourceMappingURL=primevue_row.js.map
