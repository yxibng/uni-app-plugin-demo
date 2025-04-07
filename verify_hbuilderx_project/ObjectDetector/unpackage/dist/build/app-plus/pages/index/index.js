"use weex:vue";

if (typeof Promise !== 'undefined' && !Promise.prototype.finally) {
  Promise.prototype.finally = function(callback) {
    const promise = this.constructor
    return this.then(
      value => promise.resolve(callback()).then(() => value),
      reason => promise.resolve(callback()).then(() => {
        throw reason
      })
    )
  }
};

if (typeof uni !== 'undefined' && uni && uni.requireGlobal) {
  const global = uni.requireGlobal()
  ArrayBuffer = global.ArrayBuffer
  Int8Array = global.Int8Array
  Uint8Array = global.Uint8Array
  Uint8ClampedArray = global.Uint8ClampedArray
  Int16Array = global.Int16Array
  Uint16Array = global.Uint16Array
  Int32Array = global.Int32Array
  Uint32Array = global.Uint32Array
  Float32Array = global.Float32Array
  Float64Array = global.Float64Array
  BigInt64Array = global.BigInt64Array
  BigUint64Array = global.BigUint64Array
};


(()=>{var h=Object.create;var u=Object.defineProperty;var g=Object.getOwnPropertyDescriptor;var x=Object.getOwnPropertyNames;var v=Object.getPrototypeOf,_=Object.prototype.hasOwnProperty;var C=(e,o)=>()=>(o||e((o={exports:{}}).exports,o),o.exports);var b=(e,o,a,s)=>{if(o&&typeof o=="object"||typeof o=="function")for(let n of x(o))!_.call(e,n)&&n!==a&&u(e,n,{get:()=>o[n],enumerable:!(s=g(o,n))||s.enumerable});return e};var w=(e,o,a)=>(a=e!=null?h(v(e)):{},b(o||!e||!e.__esModule?u(a,"default",{value:e,enumerable:!0}):a,e));var f=C((z,m)=>{m.exports=Vue});var t=w(f());function i(e,o,...a){uni.__log__?uni.__log__(e,o,...a):console[e].apply(console,[...a,o])}var y={container:{"":{position:"relative",width:"750rpx",height:"1334rpx"}},"detector-view":{"":{position:"absolute",top:0,left:0,width:"750rpx",height:"1334rpx"}},"control-area":{"":{position:"absolute",bottom:0,width:"750rpx",height:"400rpx",backgroundColor:"rgba(0,0,0,0.7)"}},"preview-wrapper":{"":{height:"250rpx",flexDirection:"row",justifyContent:"space-around",alignItems:"center",paddingTop:"20rpx",paddingRight:"20rpx",paddingBottom:"20rpx",paddingLeft:"20rpx"}},"preview-img":{"":{borderWidth:"2rpx",borderColor:"#ffffff",borderRadius:"16rpx",backgroundColor:"#000000"}},"button-wrapper":{"":{height:"150rpx",flexDirection:"row",justifyContent:"space-around",alignItems:"center",paddingTop:0,paddingRight:"20rpx",paddingBottom:0,paddingLeft:"20rpx"}},btn:{"":{flex:1,height:"80rpx",marginTop:0,marginRight:"10rpx",marginBottom:0,marginLeft:"10rpx",backgroundColor:"rgba(255,255,255,0.2)",borderRadius:"40rpx",fontSize:"28rpx",color:"#ffffff",textAlign:"center",lineHeight:"80rpx"}}},k=(e,o)=>{let a=e.__vccOpts||e;for(let[s,n]of o)a[s]=n;return a},O={mounted(){i("log","at pages/index/index.nvue:98","Camera component reference:",this.$refs.detector),this.$refs.detector&&i("log","at pages/index/index.nvue:101","Available methods:",Object.keys(this.$refs.detector))},computed:{imageStyle(){return{width:this.imageRatio>1?"500rpx":"300rpx",height:this.imageRatio>1?"300rpx":"500rpx"}}},data(){return{imageBase64:"",vehicleBase64:"",loadData:{},imageRatio:1,isFlashOn:!1,zoomLevel:0}},methods:{onCameraOpen(e){i("log","at pages/index/index.nvue:128","Camera opened:",e)},onCameraClose(e){i("log","at pages/index/index.nvue:131","Camera closed:",e)},onDetectionCapture(e){this.imageBase64=`data:image/jpeg;base64,${e.detail.base64_full}`,this.vehicleBase64=`data:image/jpeg;base64,${e.detail.base64_vehicle}`,i("log","at pages/index/index.nvue:136","Detection captured:",e.detail.base64_full),i("log","at pages/index/index.nvue:137","Detection captured:",e.detail.base64_vehicle),this.writeToFile(e.detail.base64_full,"base64_full"),this.writeToFile(e.detail.base64_vehicle,"base64_vehicle")},onCaptured(e){this.imageBase64=`data:image/jpeg;base64,${e.detail.base64_full}`,i("log","at pages/index/index.nvue:143","Image captured:",e.detail.base64_full),this.writeToFile(e.detail.base64_full,"base64_captured")},onError(e){i("log","at pages/index/index.nvue:148","Error occurred:",e.detail)},openCamera(e){this.$refs.detector&&typeof this.$refs.detector.openCamera=="function"?this.$refs.detector.openCamera(0):i("error","at pages/index/index.nvue:156","Method openCamera not found on camera component")},closeCamera(e){this.$refs.detector&&typeof this.$refs.detector.closeCamera=="function"?this.$refs.detector.closeCamera():i("error","at pages/index/index.nvue:163","Method closeCamera not found on camera component")},switchFlash(e){if(this.$refs.detector&&typeof this.$refs.detector.switchFlash=="function"){let o=this.isFlashOn?0:1;this.$refs.detector.switchFlash(o),this.isFlashOn=!this.isFlashOn}else i("error","at pages/index/index.nvue:172","Method switchFlash not found on camera component")},takePicture(e){this.$refs.detector&&typeof this.$refs.detector.takePicture=="function"?this.$refs.detector.takePicture():i("error","at pages/index/index.nvue:179","Method takePicture not found on camera component")},zoomIn(e){this.$refs.detector&&typeof this.$refs.detector.setZoomLevel=="function"?(this.zoomLevel+1<=10&&(this.zoomLevel=this.zoomLevel+1),this.$refs.detector.setZoomLevel(this.zoomLevel)):i("error","at pages/index/index.nvue:189","Method takePicture not found on camera component")},zoomOut(e){this.$refs.detector&&typeof this.$refs.detector.setZoomLevel=="function"?(this.zoomLevel-1>=0&&(this.zoomLevel=this.zoomLevel-1),this.$refs.detector.setZoomLevel(this.zoomLevel)):i("error","at pages/index/index.nvue:199","Method takePicture not found on camera component")},writeToFile(e,o){plus.io.requestFileSystem(plus.io.PUBLIC_DOCUMENTS,a=>{let n=a.root.toURL()+"/ry/"+o+".txt";a.root.getFile(n,{create:!0},r=>{i("log","at pages/index/index.nvue:213",r.fullPath,"\u6587\u4EF6\u5728\u624B\u673A\u4E2D\u7684\u8DEF\u5F84"),r.createWriter(c=>{c.write(e),c.onwrite=l=>{i("log","at pages/index/index.nvue:219","\u5199\u5165\u6570\u636E\u6210\u529F")}})},r=>{i("log","at pages/index/index.nvue:223","getFile failed: "+r.message)})},a=>{i("log","at pages/index/index.nvue:227",a.message)})}}};function L(e,o,a,s,n,r){let c=(0,t.resolveComponent)("object-detector-view"),l=(0,t.resolveComponent)("button");return(0,t.openBlock)(),(0,t.createElementBlock)("scroll-view",{scrollY:!0,showScrollbar:!0,enableBackToTop:!0,bubble:"true",style:{flexDirection:"column"}},[(0,t.createElementVNode)("view",{class:"container"},[(0,t.createVNode)(c,{class:"detector-view",ref:"detector",load:n.loadData,onOnCameraOpen:r.onCameraOpen,onOnCameraClose:r.onCameraClose,onOnDetectionCapture:r.onDetectionCapture,onOnCaptured:r.onCaptured,onOnError:r.onError},null,8,["load","onOnCameraOpen","onOnCameraClose","onOnDetectionCapture","onOnCaptured","onOnError"]),(0,t.createElementVNode)("view",{class:"control-area"},[(0,t.createElementVNode)("view",{class:"preview-wrapper"},[n.imageBase64?((0,t.openBlock)(),(0,t.createElementBlock)("u-image",{key:0,class:"preview-img",src:n.imageBase64,mode:"aspectFit",style:(0,t.normalizeStyle)(r.imageStyle)},null,12,["src"])):(0,t.createCommentVNode)("",!0),n.vehicleBase64?((0,t.openBlock)(),(0,t.createElementBlock)("u-image",{key:1,class:"preview-img",src:n.vehicleBase64,mode:"aspectFit",style:(0,t.normalizeStyle)(r.imageStyle)},null,12,["src"])):(0,t.createCommentVNode)("",!0)]),(0,t.createElementVNode)("view",{class:"button-wrapper"},[(0,t.createVNode)(l,{class:"btn",onClick:r.openCamera},{default:(0,t.withCtx)(()=>[(0,t.createTextVNode)("\u5F00\u542F")]),_:1},8,["onClick"]),(0,t.createVNode)(l,{class:"btn",onClick:r.closeCamera},{default:(0,t.withCtx)(()=>[(0,t.createTextVNode)("\u5173\u95ED")]),_:1},8,["onClick"]),(0,t.createVNode)(l,{class:"btn",onClick:r.switchFlash},{default:(0,t.withCtx)(()=>[(0,t.createTextVNode)("\u95EA\u5149\u706F")]),_:1},8,["onClick"]),(0,t.createVNode)(l,{class:"btn",onClick:r.takePicture},{default:(0,t.withCtx)(()=>[(0,t.createTextVNode)("\u62CD\u7167")]),_:1},8,["onClick"]),(0,t.createVNode)(l,{class:"btn",onClick:r.zoomIn},{default:(0,t.withCtx)(()=>[(0,t.createTextVNode)("zoomin")]),_:1},8,["onClick"]),(0,t.createVNode)(l,{class:"btn",onClick:r.zoomOut},{default:(0,t.withCtx)(()=>[(0,t.createTextVNode)("zoomout")]),_:1},8,["onClick"])])])])])}var d=k(O,[["render",L],["styles",[y]]]);var p=plus.webview.currentWebview();if(p){let e=parseInt(p.id),o="pages/index/index",a={};try{a=JSON.parse(p.__query__)}catch(n){}d.mpType="page";let s=Vue.createPageApp(d,{$store:getApp({allowDefault:!0}).$store,__pageId:e,__pagePath:o,__pageQuery:a});s.provide("__globalStyles",Vue.useCssStyles([...__uniConfig.styles,...d.styles||[]])),s.mount("#root")}})();
