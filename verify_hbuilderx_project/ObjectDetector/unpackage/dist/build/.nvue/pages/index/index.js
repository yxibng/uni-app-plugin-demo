import { resolveComponent, openBlock, createElementBlock, createElementVNode, createVNode, normalizeStyle, createCommentVNode, withCtx, createTextVNode } from "vue";
function formatAppLog(type, filename, ...args) {
  if (uni.__log__) {
    uni.__log__(type, filename, ...args);
  } else {
    console[type].apply(console, [...args, filename]);
  }
}
const _style_0 = { "container": { "": { "position": "relative", "width": "750rpx", "height": "1334rpx" } }, "detector-view": { "": { "position": "absolute", "top": 0, "left": 0, "width": "750rpx", "height": "1334rpx" } }, "control-area": { "": { "position": "absolute", "bottom": 0, "width": "750rpx", "height": "400rpx", "backgroundColor": "rgba(0,0,0,0.7)" } }, "preview-wrapper": { "": { "height": "250rpx", "flexDirection": "row", "justifyContent": "space-around", "alignItems": "center", "paddingTop": "20rpx", "paddingRight": "20rpx", "paddingBottom": "20rpx", "paddingLeft": "20rpx" } }, "preview-img": { "": { "borderWidth": "2rpx", "borderColor": "#ffffff", "borderRadius": "16rpx", "backgroundColor": "#000000" } }, "button-wrapper": { "": { "height": "150rpx", "flexDirection": "row", "justifyContent": "space-around", "alignItems": "center", "paddingTop": 0, "paddingRight": "20rpx", "paddingBottom": 0, "paddingLeft": "20rpx" } }, "btn": { "": { "flex": 1, "height": "80rpx", "marginTop": 0, "marginRight": "10rpx", "marginBottom": 0, "marginLeft": "10rpx", "backgroundColor": "rgba(255,255,255,0.2)", "borderRadius": "40rpx", "fontSize": "28rpx", "color": "#ffffff", "textAlign": "center", "lineHeight": "80rpx" } } };
const _export_sfc = (sfc, props) => {
  const target = sfc.__vccOpts || sfc;
  for (const [key, val] of props) {
    target[key] = val;
  }
  return target;
};
const _sfc_main = {
  mounted() {
    formatAppLog("log", "at pages/index/index.nvue:98", "Camera component reference:", this.$refs.detector);
    if (this.$refs.detector) {
      formatAppLog("log", "at pages/index/index.nvue:101", "Available methods:", Object.keys(this.$refs.detector));
    }
  },
  computed: {
    imageStyle() {
      return {
        width: this.imageRatio > 1 ? "500rpx" : "300rpx",
        height: this.imageRatio > 1 ? "300rpx" : "500rpx"
      };
    }
  },
  data() {
    return {
      imageBase64: "",
      vehicleBase64: "",
      loadData: {},
      imageRatio: 1,
      // 默认宽高比
      isFlashOn: false,
      // 新增闪光灯状态标识
      zoomLevel: 0
    };
  },
  methods: {
    /**event start **/
    onCameraOpen(e) {
      formatAppLog("log", "at pages/index/index.nvue:128", "Camera opened:", e);
    },
    onCameraClose(e) {
      formatAppLog("log", "at pages/index/index.nvue:131", "Camera closed:", e);
    },
    onDetectionCapture(e) {
      this.imageBase64 = `data:image/jpeg;base64,${e.detail.base64_full}`;
      this.vehicleBase64 = `data:image/jpeg;base64,${e.detail.base64_vehicle}`;
      formatAppLog("log", "at pages/index/index.nvue:136", "Detection captured:", e.detail.base64_full);
      formatAppLog("log", "at pages/index/index.nvue:137", "Detection captured:", e.detail.base64_vehicle);
      this.writeToFile(e.detail.base64_full, "base64_full");
      this.writeToFile(e.detail.base64_vehicle, "base64_vehicle");
    },
    onCaptured(e) {
      this.imageBase64 = `data:image/jpeg;base64,${e.detail.base64_full}`;
      formatAppLog("log", "at pages/index/index.nvue:143", "Image captured:", e.detail.base64_full);
      this.writeToFile(e.detail.base64_full, "base64_captured");
    },
    onError(e) {
      formatAppLog("log", "at pages/index/index.nvue:148", "Error occurred:", e.detail);
    },
    /**func start **/
    //openCamera closeCamea 会根据cameraview的生命周期自行调用，也可以手动调用，但只能在cameraview 挂载后才能调用，其他形式的调用不保证可用性
    openCamera(e) {
      if (this.$refs.detector && typeof this.$refs.detector.openCamera === "function") {
        this.$refs.detector.openCamera(0);
      } else {
        formatAppLog("error", "at pages/index/index.nvue:156", "Method openCamera not found on camera component");
      }
    },
    closeCamera(e) {
      if (this.$refs.detector && typeof this.$refs.detector.closeCamera === "function") {
        this.$refs.detector.closeCamera();
      } else {
        formatAppLog("error", "at pages/index/index.nvue:163", "Method closeCamera not found on camera component");
      }
    },
    switchFlash(e) {
      if (this.$refs.detector && typeof this.$refs.detector.switchFlash === "function") {
        const flashMode = this.isFlashOn ? 0 : 1;
        this.$refs.detector.switchFlash(flashMode);
        this.isFlashOn = !this.isFlashOn;
      } else {
        formatAppLog("error", "at pages/index/index.nvue:172", "Method switchFlash not found on camera component");
      }
    },
    takePicture(e) {
      if (this.$refs.detector && typeof this.$refs.detector.takePicture === "function") {
        this.$refs.detector.takePicture();
      } else {
        formatAppLog("error", "at pages/index/index.nvue:179", "Method takePicture not found on camera component");
      }
    },
    zoomIn(e) {
      if (this.$refs.detector && typeof this.$refs.detector.setZoomLevel === "function") {
        if (this.zoomLevel + 1 <= 10) {
          this.zoomLevel = this.zoomLevel + 1;
        }
        this.$refs.detector.setZoomLevel(this.zoomLevel);
      } else {
        formatAppLog("error", "at pages/index/index.nvue:189", "Method takePicture not found on camera component");
      }
    },
    zoomOut(e) {
      if (this.$refs.detector && typeof this.$refs.detector.setZoomLevel === "function") {
        if (this.zoomLevel - 1 >= 0) {
          this.zoomLevel = this.zoomLevel - 1;
        }
        this.$refs.detector.setZoomLevel(this.zoomLevel);
      } else {
        formatAppLog("error", "at pages/index/index.nvue:199", "Method takePicture not found on camera component");
      }
    },
    writeToFile(content, fileName) {
      plus.io.requestFileSystem(
        plus.io.PUBLIC_DOCUMENTS,
        // 文件系统中的根目录
        (fs) => {
          let a = fs.root.toURL();
          let dirPath = a + "/ry/" + fileName + ".txt";
          fs.root.getFile(dirPath, {
            create: true
            // 文件不存在则创建
          }, (fileEntry) => {
            formatAppLog("log", "at pages/index/index.nvue:213", fileEntry.fullPath, "文件在手机中的路径");
            fileEntry.createWriter((writer) => {
              writer.write(content);
              writer.onwrite = (e) => {
                formatAppLog("log", "at pages/index/index.nvue:219", "写入数据成功");
              };
            });
          }, (e) => {
            formatAppLog("log", "at pages/index/index.nvue:223", "getFile failed: " + e.message);
          });
        },
        (e) => {
          formatAppLog("log", "at pages/index/index.nvue:227", e.message);
        }
      );
    }
  }
};
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_object_detector_view = resolveComponent("object-detector-view");
  const _component_button = resolveComponent("button");
  return openBlock(), createElementBlock("scroll-view", {
    scrollY: true,
    showScrollbar: true,
    enableBackToTop: true,
    bubble: "true",
    style: { flexDirection: "column" }
  }, [
    createElementVNode("view", { class: "container" }, [
      createVNode(_component_object_detector_view, {
        class: "detector-view",
        ref: "detector",
        load: $data.loadData,
        onOnCameraOpen: $options.onCameraOpen,
        onOnCameraClose: $options.onCameraClose,
        onOnDetectionCapture: $options.onDetectionCapture,
        onOnCaptured: $options.onCaptured,
        onOnError: $options.onError
      }, null, 8, ["load", "onOnCameraOpen", "onOnCameraClose", "onOnDetectionCapture", "onOnCaptured", "onOnError"]),
      createElementVNode("view", { class: "control-area" }, [
        createElementVNode("view", { class: "preview-wrapper" }, [
          $data.imageBase64 ? (openBlock(), createElementBlock("u-image", {
            key: 0,
            class: "preview-img",
            src: $data.imageBase64,
            mode: "aspectFit",
            style: normalizeStyle($options.imageStyle)
          }, null, 12, ["src"])) : createCommentVNode("", true),
          $data.vehicleBase64 ? (openBlock(), createElementBlock("u-image", {
            key: 1,
            class: "preview-img",
            src: $data.vehicleBase64,
            mode: "aspectFit",
            style: normalizeStyle($options.imageStyle)
          }, null, 12, ["src"])) : createCommentVNode("", true)
        ]),
        createElementVNode("view", { class: "button-wrapper" }, [
          createVNode(_component_button, {
            class: "btn",
            onClick: $options.openCamera
          }, {
            default: withCtx(() => [
              createTextVNode("开启")
            ]),
            _: 1
          }, 8, ["onClick"]),
          createVNode(_component_button, {
            class: "btn",
            onClick: $options.closeCamera
          }, {
            default: withCtx(() => [
              createTextVNode("关闭")
            ]),
            _: 1
          }, 8, ["onClick"]),
          createVNode(_component_button, {
            class: "btn",
            onClick: $options.switchFlash
          }, {
            default: withCtx(() => [
              createTextVNode("闪光灯")
            ]),
            _: 1
          }, 8, ["onClick"]),
          createVNode(_component_button, {
            class: "btn",
            onClick: $options.takePicture
          }, {
            default: withCtx(() => [
              createTextVNode("拍照")
            ]),
            _: 1
          }, 8, ["onClick"]),
          createVNode(_component_button, {
            class: "btn",
            onClick: $options.zoomIn
          }, {
            default: withCtx(() => [
              createTextVNode("zoomin")
            ]),
            _: 1
          }, 8, ["onClick"]),
          createVNode(_component_button, {
            class: "btn",
            onClick: $options.zoomOut
          }, {
            default: withCtx(() => [
              createTextVNode("zoomout")
            ]),
            _: 1
          }, 8, ["onClick"])
        ])
      ])
    ])
  ]);
}
const index = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render], ["styles", [_style_0]]]);
export {
  index as default
};
