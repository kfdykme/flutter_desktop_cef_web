// Copyright (c) 2013 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

#include <windows.h>

#include "include/cef_command_line.h"
#include "include/cef_sandbox_win.h"
#include "tests/cefsimple/simple_app.h"

#include "../include/flutter_desktop_cef_web/flutter_desktop_cef_web_plugin.h"
// When generating projects with CMake the CEF_USE_SANDBOX value will be defined
// automatically if using the required compiler version. Pass -DUSE_SANDBOX=OFF
// to the CMake command-line to disable use of the sandbox.
// Uncomment this line to manually enable sandbox support.
// #define CEF_USE_SANDBOX 1

#if defined(CEF_USE_SANDBOX)
// The cef_sandbox.lib static library may not link successfully with all VS
// versions.
#pragma comment(lib, "cef_sandbox.lib")
#endif
int APIENTRY wWinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance,
                      _In_ wchar_t *lpCmdLine, _In_ int nCmdShow) {

// // Entry point function for all processes.
// int APIENTRY wWinMain(HINSTANCE hInstance,
//                       HINSTANCE hPrevInstance,
//                       LPWSTR lpCmdLine,
//                       int nCmdShow) {
  UNREFERENCED_PARAMETER(hPrevInstance);
  UNREFERENCED_PARAMETER(lpCmdLine);


  FlutterDesktopCefWebPluginCefInit(hInstance);
  // Run the CEF message loop. This will block until CefQuitMessageLoop() is
  // called.
  CefRunMessageLoop();

  // Shut down CEF.
  CefShutdown();

  return 0;
}
