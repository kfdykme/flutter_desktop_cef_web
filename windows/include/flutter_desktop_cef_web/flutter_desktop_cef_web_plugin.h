#ifndef FLUTTER_PLUGIN_FLUTTER_DESKTOP_CEF_WEB_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_DESKTOP_CEF_WEB_PLUGIN_H_

#include "flutter_plugin_registrar.h"
#include <windows.h>

#include "../cef/include/cef_sandbox_win.h"
#include "../cef/include/cef_command_line.h"
#include "../core/simple_app.h"
#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FlutterDesktopCefWebPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

    
FLUTTER_PLUGIN_EXPORT void FlutterDesktopCefWebPluginCefInit(HINSTANCE instance);
FLUTTER_PLUGIN_EXPORT void FlutterDesktopCefWebPluginCefLoopMessage();

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_FLUTTER_DESKTOP_CEF_WEB_PLUGIN_H_
