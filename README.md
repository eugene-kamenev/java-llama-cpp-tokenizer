## java-llama-cpp-tokenizer

Java bindings to llama-cpp model tokenizer function for Linux. Based on example provided in: [tokenize.cpp](https://github.com/ggml-org/llama.cpp/blob/master/examples/tokenize/tokenize.cpp)

## Build
```bash
make clean && make all
```

This will build the shared library and the Java bindings and create a jar file in ./build/libs directory.

## Usage
```java
import llama.LlamaTokenizer;

public class Main {
    public static void main(String[] args) {
        var tokenizer = new LlamaTokenizer();
        tokenizer.initTokenizer("YourModel.gguf");
        String text = "Hello, world!";
        int[] tokens = tokenizer.tokenize(text);
    }
}
```
