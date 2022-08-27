// Copyright (c) 2012 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

#include "client_renderer.h"

#include <sstream>
#include <string>

#include "include/cef_crash_util.h"
#include "include/cef_dom.h"
#include "include/wrapper/cef_helpers.h"
#include "include/wrapper/cef_message_router.h"

#include <fstream>


namespace client {
  
// static
void ClientAppRenderer::CreateDelegates(DelegateSet& delegates) {
  renderer::CreateDelegates(delegates);
}
namespace renderer {
 
namespace {

// Must match the value in client_handler.cc.
const char kFocusedNodeChangedMessage[] = "ClientRenderer.FocusedNodeChanged";
const char kJsIpcRenderer[] = "ipcRenderer";
class ClientRenderDelegate : public ClientAppRenderer::Delegate {
 public:
  
class V8HandlerImpl : public CefV8Handler {
   public:
    explicit V8HandlerImpl(CefRefPtr<ClientRenderDelegate> delegate)
        : delegate_(delegate) {}

    bool Execute(const CefString& name,
                 CefRefPtr<CefV8Value> object,
                 const CefV8ValueList& arguments,
                 CefRefPtr<CefV8Value>& retval,
                 CefString& exception) override {
      const std::string& message_name = name;
      if (message_name == kJsIpcRenderer) { 

        const CefString& msg = arguments[0]->GetStringValue();
        CefRefPtr<CefV8Context> context = CefV8Context::GetCurrentContext();
        CefRefPtr<CefFrame> frame = context->GetFrame();

        CefRefPtr<CefProcessMessage> message =
            CefProcessMessage::Create(kJsIpcRenderer);
        CefRefPtr<CefListValue> args = message->GetArgumentList();
        args->SetString(0, msg);
        
        frame->SendProcessMessage(PID_BROWSER, message);
        return true;
      } 

      return true;
    }

   private:
    CefRefPtr<ClientRenderDelegate> delegate_;

    IMPLEMENT_REFCOUNTING(V8HandlerImpl);
  };

  ClientRenderDelegate() : last_node_is_editable_(false) {}

  void OnWebKitInitialized(CefRefPtr<ClientAppRenderer> app) override {
    // if (CefCrashReportingEnabled()) {
    //   // Set some crash keys for testing purposes. Keys must be defined in the
    //   // "crash_reporter.cfg" file. See cef_crash_util.h for details.
    //   CefSetCrashKeyValue("testkey_small1", "value1_small_renderer");
    //   CefSetCrashKeyValue("testkey_small2", "value2_small_renderer");
    //   CefSetCrashKeyValue("testkey_medium1", "value1_medium_renderer");
    //   CefSetCrashKeyValue("testkey_medium2", "value2_medium_renderer");
    //   CefSetCrashKeyValue("testkey_large1", "value1_large_renderer");
    //   CefSetCrashKeyValue("testkey_large2", "value2_large_renderer");
    // }

    // Create the renderer-side router for query handling.
    CefMessageRouterConfig config;
    message_router_ = CefMessageRouterRendererSide::Create(config);
  }

  void OnContextCreated(CefRefPtr<ClientAppRenderer> app,
                        CefRefPtr<CefBrowser> browser,
                        CefRefPtr<CefFrame> frame,
                        CefRefPtr<CefV8Context> context) override {
    message_router_->OnContextCreated(browser, frame, context);

     // Register function handlers with the 'window' object.
    CefRefPtr<CefV8Value> window = context->GetGlobal();

    CefRefPtr<V8HandlerImpl> handler = new V8HandlerImpl(this);
    CefV8Value::PropertyAttribute attributes =
        static_cast<CefV8Value::PropertyAttribute>(
            V8_PROPERTY_ATTRIBUTE_READONLY | V8_PROPERTY_ATTRIBUTE_DONTENUM |
            V8_PROPERTY_ATTRIBUTE_DONTDELETE);

    CefRefPtr<CefV8Value> ipcRenderer_func =
        CefV8Value::CreateFunction(kJsIpcRenderer, handler.get());
    window->SetValue(kJsIpcRenderer, ipcRenderer_func, attributes);
  }

  void OnContextReleased(CefRefPtr<ClientAppRenderer> app,
                         CefRefPtr<CefBrowser> browser,
                         CefRefPtr<CefFrame> frame,
                         CefRefPtr<CefV8Context> context) override {
    message_router_->OnContextReleased(browser, frame, context);
  }

  void OnFocusedNodeChanged(CefRefPtr<ClientAppRenderer> app,
                            CefRefPtr<CefBrowser> browser,
                            CefRefPtr<CefFrame> frame,
                            CefRefPtr<CefDOMNode> node) override {
    bool is_editable = (node.get() && node->IsEditable());
    if (is_editable != last_node_is_editable_) {
      // Notify the browser of the change in focused element type.
      last_node_is_editable_ = is_editable;
      CefRefPtr<CefProcessMessage> message =
          CefProcessMessage::Create(kFocusedNodeChangedMessage);
      message->GetArgumentList()->SetBool(0, is_editable);
      frame->SendProcessMessage(PID_BROWSER, message);
    }
  }

  bool OnProcessMessageReceived(CefRefPtr<ClientAppRenderer> app,
                                CefRefPtr<CefBrowser> browser,
                                CefRefPtr<CefFrame> frame,
                                CefProcessId source_process,
                                CefRefPtr<CefProcessMessage> message) override {

      

    std::ofstream outfile;
    outfile.open("C:\\Users\\wimkf\\Desktop\\wor\\denkuipro\\denkuitop\\build\\windows\\runner\\Debug\\logrender", std::ios::out | std::ios::trunc);

    outfile << message->GetName().ToString();
    outfile.close();
    browser->GetMainFrame()->SendProcessMessage(PID_BROWSER, message);
    return message_router_->OnProcessMessageReceived(browser, frame,
                                                     source_process, message);
  }

 private:
  bool last_node_is_editable_;

  // Handles the renderer side of query routing.
  CefRefPtr<CefMessageRouterRendererSide> message_router_;

  DISALLOW_COPY_AND_ASSIGN(ClientRenderDelegate);
  IMPLEMENT_REFCOUNTING(ClientRenderDelegate);
};

}  // namespace

void CreateDelegates(ClientAppRenderer::DelegateSet& delegates) {
  delegates.insert(new ClientRenderDelegate);
}

}  // namespace renderer


}  // namespace client
