// App entry point: runs the bundle's launch script, so macOS asks for drive access on the app's behalf.
#include <mach-o/dyld.h>
#include <libgen.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
int main(int argc, char **argv) {
  char exe[PATH_MAX]; uint32_t size = sizeof exe;
  if (_NSGetExecutablePath(exe, &size) != 0) return 1;
  char script[PATH_MAX + 32];
  snprintf(script, sizeof script, "%s/%s", dirname(exe), LAUNCH_SCRIPT);
  char *args[256]; int n = 0;
  args[n++] = "/bin/zsh"; args[n++] = script;
  for (int i = 1; i < argc && n < 255; i++) if (strncmp(argv[i], "-psn_", 5) != 0) args[n++] = argv[i];
  args[n] = NULL;
  execv("/bin/zsh", args);
  return 1;
}
