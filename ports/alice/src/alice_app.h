// alice - ReXGlue Recompiled Project
//
// Customize your app by overriding virtual hooks from rex::ReXApp.

#pragma once

#include <cstdio>
#include <cstdlib>

#include <rex/rex_app.h>
#include <rex/runtime.h>
#include <rex/system/xmemory.h>

class AliceApp : public rex::ReXApp {
 public:
  using rex::ReXApp::ReXApp;

  static std::unique_ptr<rex::ui::WindowedApp> Create(
      rex::ui::WindowedAppContext& ctx) {
    return std::unique_ptr<AliceApp>(new AliceApp(ctx, "alice",
        PPCImageConfig));
  }

  // Override virtual hooks for customization:
  // void OnPostInitLogging() override {}
  void OnPreSetup(rex::RuntimeConfig& config) override {
    // Default to the Xenos GPU plugin unless one was chosen on the command line.
    if (config.gpu_plugin.empty()) config.gpu_plugin = "xenos";
  }

  void OnPostLoadXexImage() override {
    // TEMP analysis aid: ALICE_DUMP_IMAGE=path writes the decrypted, loaded
    // image (0x82000000-0x83460000) so data can be scanned for code pointers.
    if (const char* path = std::getenv("ALICE_DUMP_IMAGE"); path && runtime()) {
      constexpr uint32_t kBase = 0x82000000, kEnd = 0x83460000;
      if (FILE* f = std::fopen(path, "wb")) {
        std::fwrite(runtime()->memory()->TranslateVirtual<const uint8_t*>(kBase), 1,
                    kEnd - kBase, f);
        std::fclose(f);
      }
    }
  }
  // void OnLoadXexImage(std::string& xex_image) override {}
  // void OnPostSetup() override {}
  // void OnCreateDialogs(rex::ui::ImGuiDrawer* drawer) override {}
  // std::unique_ptr<rex::ui::ImGuiDialog> CreateAchievementsOverlay() override;
  // std::unique_ptr<rex::ui::AchievementNotificationDialog>
  // CreateAchievementNotificationDialog() override;
  // void OnShutdown() override {}
  // void OnConfigurePaths(rex::PathConfig& paths) override {}
};
