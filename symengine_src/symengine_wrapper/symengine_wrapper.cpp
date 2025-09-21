#include "symengine_wrapper.hpp"

#include <symengine/expression.h>
#include <symengine/symbol.h>
#include <symengine/parser/parser.h>
#include <symengine/functions.h>
//#include <symengine/evalf.h> // todo upgrade to include flint and mpfr so that I can have evalf.  will need to install two more frameworks as dependencies.

#include <sstream>
#include <string>
#include <cstring>

namespace {
std::string evaluate_internal(const char* input, bool force_double, int precision) {
    std::string cpp_input(input ? input : "");
    
    if (precision > 50) precision = 50;

    if (cpp_input.empty()) {
        return "Error: null input";
    }
    
    try {
        SymEngine::Parser parser;
        // the simulator will fail here if it can't evaluate the expression.  i haven't figured out a way around that.
        SymEngine::Expression expr = parser.parse(cpp_input);
        
        // necessary because the try/catches don't work in the simulator
        if (str(expr) == str(SymEngine::Expression(parser.parse("1/0")))) {
            return str(expr);
        }
        
        if (force_double) {
            try {
                double val = eval_double(expr);
                std::ostringstream oss;
                oss.precision(precision);
                oss << std::fixed << val;
                return oss.str();
            } catch (...) {
                return str(expr);
            }
        } else {
            return str(expr);
        }
    } catch (std::exception& e) {
        return std::string("Error: ") + e.what();
    }
}
} // namespace

int evaluate_expression_size(const char* input, bool force_double, int precision) {
    try {
        std::string result = evaluate_internal(input, force_double, precision);
        return static_cast<int>(result.size() + 1); // include null terminator
    } catch (...) {
        return -1;
    }
}

int evaluate_expression(const char* input, bool force_double, int precision, char* outputBuffer, size_t bufferSize) {
    if (!outputBuffer || bufferSize == 0) return -1;

    try {
        std::string result = evaluate_internal(input, force_double, precision);
        size_t copySize = std::min(result.size(), bufferSize - 1);
        std::memcpy(outputBuffer, result.c_str(), copySize);
        outputBuffer[copySize] = '\0';
        return static_cast<int>(copySize);
    } catch (const std::exception& e) {
        std::cerr << "exception: " << e.what() << std::endl;
        return -1;
    } catch (...) {
        std::cerr << "unknown exception" << std::endl;
        return -1;
    }
}
