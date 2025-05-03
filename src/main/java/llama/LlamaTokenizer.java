package llama;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

public class LlamaTokenizer {
    static void loadNativeLibrary(String libName, File tempDir) throws IOException {
        InputStream in = LlamaTokenizer.class.getResourceAsStream("/" + libName);
        if (in == null) throw new IOException("Library not found: " + libName);
        File temp = new File(tempDir, libName);
        Files.copy(in, temp.toPath(), StandardCopyOption.REPLACE_EXISTING);
        temp.deleteOnExit();
        System.load(temp.getAbsolutePath());
    }

    static File getFirstWritableLdLibraryPathDir() throws IOException {
        String ldLibraryPath = System.getenv("LD_LIBRARY_PATH");
        if (ldLibraryPath != null) {
            for (String dir : ldLibraryPath.split(":")) {
                File f = new File(dir);
                if (f.isDirectory() && f.canWrite()) {
                    return f;
                }
            }
        }
        // fallback to temp dir if none found
        return Files.createTempDirectory("llama_libs").toFile();
    }

    static {
        try {
            File targetDir = getFirstWritableLdLibraryPathDir();
            loadNativeLibrary("libllama.so", targetDir);
            loadNativeLibrary("libllamatokenizer.so", targetDir);
            loadNativeLibrary("libggml.so", targetDir);
            loadNativeLibrary("libggml-cpu.so", targetDir);
            loadNativeLibrary("libggml-base.so", targetDir);
        } catch (IOException e) {
            throw new RuntimeException("Failed to load native libraries", e);
        }
    }

    public native int initTokenizer(String modelPath);
    public native int[] tokenizeText(String text);
    public native void freeTokenizer();

    public int[] tokenize(String text) {
        return tokenizeText(text);
    }
}