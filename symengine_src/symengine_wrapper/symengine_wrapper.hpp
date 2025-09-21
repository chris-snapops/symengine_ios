//#pragma once
//
//CFStringRef evaluate_expression_wrapper(const char* input, bool force_double, int precision);

#pragma once
#include <cstddef> // for size_t

#ifdef __cplusplus
extern "C" {
#endif

// Returns the required buffer size (including null terminator). Returns -1 on error.
int evaluate_expression_size(const char* input, bool force_double, int precision);

// Writes the evaluated expression into the provided buffer. Returns number of characters written (excluding null terminator), or -1 on error. Caller must ensure buffer has at least evaluate_expression_size() capacity.
int evaluate_expression(const char* input, bool force_double, int precision, char* outputBuffer, size_t bufferSize);

#ifdef __cplusplus
}
#endif
