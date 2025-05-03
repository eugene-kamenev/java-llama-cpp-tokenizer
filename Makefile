# Paths
LLAMA_CPP_DIR := llama.cpp
LLAMA_BUILD_DIR := $(LLAMA_CPP_DIR)/build
WRAPPER_DIR := wrapper
WRAPPER_BUILD_DIR := $(WRAPPER_DIR)/build
WRAPPER_SRC := $(WRAPPER_DIR)/llama_tokenizer_api.cpp
WRAPPER_LIB := libllamatokenizer.so

JAVA_SRC_DIR := src/main/java
JAVA_CLASS := llama/LlamaTokenizer
JAVA_BUILD_DIR := build/classes/java/main
RESOURCES_DIR := src/main/resources

# Compiler
CXX := g++
CXXFLAGS := -fPIC -shared -std=c++17 -I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux -I$(LLAMA_CPP_DIR) -I$(LLAMA_CPP_DIR)/include -I$(LLAMA_CPP_DIR)/ggml/include $(LLAMA_BUILD_DIR)/bin/libllama.so -pthread -ldl

.PHONY: all check-llama-clone java-headers gradle-build copy-so clean

all: check-llama-clone $(WRAPPER_BUILD_DIR)/$(WRAPPER_LIB) java-headers copy-so gradle-build

# Step 0: Check if llama.cpp exists, if not clone it
check-llama-clone:
	@if [ ! -d "$(LLAMA_CPP_DIR)" ]; then \
		echo "llama.cpp directory not found. Cloning from GitHub..."; \
		git clone https://github.com/ggerganov/llama.cpp.git $(LLAMA_CPP_DIR); \
	fi

# Step 1: Build llama.cpp as a shared library via CMake
$(LLAMA_BUILD_DIR)/libllama.so:
	@echo "Building llama.cpp with CMake..."
	@mkdir -p $(LLAMA_BUILD_DIR)
	cd $(LLAMA_BUILD_DIR) && cmake .. -DBUILD_SHARED_LIBS=ON && cmake --build . --target llama

# Step 2: Build JNI wrapper shared library (depends on llama)
$(WRAPPER_BUILD_DIR)/$(WRAPPER_LIB): $(WRAPPER_SRC) $(LLAMA_BUILD_DIR)/libllama.so
	@echo "Building JNI wrapper..."
	@mkdir -p $(WRAPPER_BUILD_DIR)
	$(CXX) $(WRAPPER_SRC) -o $(WRAPPER_BUILD_DIR)/$(WRAPPER_LIB) $(CXXFLAGS)

# Step 3: Generate JNI headers
java-headers:
	@echo "Generating JNI headers..."
	./gradlew classes
	javac -h $(WRAPPER_DIR) -cp build/classes/java/main $(JAVA_SRC_DIR)/$(JAVA_CLASS).java

# Step 4: Copy .so to resources
copy-so: $(WRAPPER_BUILD_DIR)/$(WRAPPER_LIB)
	@echo "Copying .so to resources..."
	mkdir -p $(RESOURCES_DIR)
	cp $(WRAPPER_BUILD_DIR)/$(WRAPPER_LIB) $(RESOURCES_DIR)/
	cp $(LLAMA_BUILD_DIR)/bin/libllama.so $(RESOURCES_DIR)/
	cp $(LLAMA_BUILD_DIR)/bin/libggml.so $(RESOURCES_DIR)/
	cp $(LLAMA_BUILD_DIR)/bin/libggml-cpu.so $(RESOURCES_DIR)/
	cp $(LLAMA_BUILD_DIR)/bin/libggml-base.so $(RESOURCES_DIR)/

# Step 5: Build Java library with Gradle
gradle-build:
	@echo "Building Java library with Gradle..."
	./gradlew build

clean:
	rm -rf $(WRAPPER_BUILD_DIR)
	rm -rf $(LLAMA_BUILD_DIR)