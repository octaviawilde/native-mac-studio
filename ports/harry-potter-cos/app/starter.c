/* Starts the zsh launcher next to this binary (keeps the .app's main executable a real Mach-O). */
#include <mach-o/dyld.h>
#include <libgen.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int main(int argc, char **argv) {
    char exe[PATH_MAX]; uint32_t n = sizeof exe;
    if (_NSGetExecutablePath(exe, &n) != 0) return 1;
    char real[PATH_MAX]; if (!realpath(exe, real)) strcpy(real, exe);
    char script[PATH_MAX]; snprintf(script, sizeof script, "%s/%s", dirname(real), "launch-harry");
    char **args = calloc(argc + 2, sizeof *args);
    args[0] = "/bin/zsh"; args[1] = script;
    for (int i = 1; i < argc; i++) args[i + 1] = argv[i];
    execv("/bin/zsh", args);
    perror("execv"); return 1;
}
