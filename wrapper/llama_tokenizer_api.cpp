#include <jni.h>
#include <string>
#include "llama.h"
#include <cstring>
#include <vector>

extern "C"
{

    llama_model *model = nullptr;
    const llama_vocab *vocab = nullptr;
    bool add_bos = false;

    std::vector<llama_token> common_tokenize(
        const struct llama_vocab * vocab,
               const std::string & text,
                            bool   add_special,
                            bool   parse_special) {
        // upper limit for the number of tokens
        int n_tokens = text.length() + 2 * add_special;
        std::vector<llama_token> result(n_tokens);
        n_tokens = llama_tokenize(vocab, text.data(), text.length(), result.data(), result.size(), add_special, parse_special);
        if (n_tokens < 0) {
            result.resize(-n_tokens);
            int check = llama_tokenize(vocab, text.data(), text.length(), result.data(), result.size(), add_special, parse_special);
            GGML_ASSERT(check == -n_tokens);
        } else {
            result.resize(n_tokens);
        }
        return result;
    }

    // Initialize the tokenizer using vocab-only mode
    int init_tokenizer(const char *model_path)
    {
        if (model != nullptr)
        {
            llama_model_free(model);
            model = nullptr;
            vocab = nullptr;
        } else {
            llama_backend_init();
        }

        llama_model_params params = llama_model_default_params();
        params.vocab_only = true;  // Load only tokenizer/vocab

        model = llama_model_load_from_file(model_path, params);
        if (!model)
            return -1;

        vocab = llama_model_get_vocab(model);
        add_bos = llama_vocab_get_add_bos(vocab);
        return 0;
    }

    // Tokenize input text and return a newly allocated array of tokens
    int* tokenize_text(const char *text, int *num_tokens)
    {
        if (!model || !vocab || !text || !num_tokens)
            return nullptr;
        std::vector<llama_token> tokens;
        tokens = common_tokenize(vocab, text, add_bos, false);
        *num_tokens = tokens.size();
        int* output_tokens = new int[*num_tokens];
        std::memcpy(output_tokens, tokens.data(), *num_tokens * sizeof(int));
        return output_tokens;
    }



    // Free tokenizer resources
    void free_tokenizer()
    {
        if (model != nullptr)
        {
            llama_model_free(model);
            model = nullptr;
            vocab = nullptr;
        }
    }
}

// JNI wrappers
extern "C"
{

    // JNIEXPORT jint JNICALL Java_{package_and_class}_initTokenizer(JNIEnv*, jobject, jstring)
    JNIEXPORT jint JNICALL Java_llama_LlamaTokenizer_initTokenizer(JNIEnv *env, jobject, jstring modelPath)
    {
        const char *nativeModelPath = env->GetStringUTFChars(modelPath, nullptr);
        int result = init_tokenizer(nativeModelPath);
        env->ReleaseStringUTFChars(modelPath, nativeModelPath);
        return result;
    }

    JNIEXPORT jintArray JNICALL Java_llama_LlamaTokenizer_tokenizeText(JNIEnv *env, jobject, jstring text)
    {
        const char *nativeText = env->GetStringUTFChars(text, nullptr);

        int num_tokens = 0;
        int* nativeTokens = tokenize_text(nativeText, &num_tokens);

        jintArray result = env->NewIntArray(num_tokens);
        if (num_tokens > 0 && nativeTokens != nullptr) {
            env->SetIntArrayRegion(result, 0, num_tokens, nativeTokens);
            delete[] nativeTokens;
        }

        env->ReleaseStringUTFChars(text, nativeText);
        return result;
    }

    JNIEXPORT void JNICALL Java_llama_LlamaTokenizer_freeTokenizer(JNIEnv *, jobject)
    {
        free_tokenizer();
    }
}