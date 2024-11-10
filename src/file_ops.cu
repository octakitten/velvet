#include "hvm.h"

#include <cuda.h>
#include <cuda_runtime.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

Port cmd(GNet* net, Port arg) {
    Str path = readback_str(net, book, arg);
    char* command = malloc(path.len);
    sprintf(command, "%s", path.buf);
    free(path.buf)

    FILE* pipe = popen(command, "r");
    if (pipe == NULL) {
        fprintf(stderr, "Command had no output or failed to run command '%s': %s\n", command, strerror(errno));
        return new_port(ERA, 0);
    }
    char buffer[512];
    Bytes output = { .buf = NULL, .len = 0 };
    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        size_t len = strlen(buffer);
        char* new_output = realloc(output.buf, output.len + len + 1);
        if (new_output == NULL) {
            fprintf(stderr, "failed to allocate space for output of '%s': %s\n", command, strerror(errno));
            free(command);
            free(output.buf);
            pclose(pipe);
            return new_port(ERA, 0);
        }
        output.buf = new_output;
        strcpy(output.buf + output.len, buffer);
        output.len += len;
    }

    Port output_port = inject_bytes(net, &output);

    free(command);
    free(output.buf);
    pclose(pipe);
    return output_port;
}
