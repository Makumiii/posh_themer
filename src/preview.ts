/**
 * Theme Preview Generator
 * Uses oh-my-posh to generate previews of themes
 */

// Cache for preview outputs to avoid re-running for the same theme
const previewCache = new Map<string, string>();

/**
 * Generate a preview for a theme using oh-my-posh
 * @param themePath Absolute path to the theme file
 * @returns The rendered preview string
 */
export async function generatePreview(themePath: string): Promise<string> {
    // Check cache first
    if (previewCache.has(themePath)) {
        return previewCache.get(themePath)!;
    }

    try {
        const command = new Deno.Command("oh-my-posh", {
            args: ["print", "preview", "-c", themePath],
            stdout: "piped",
            stderr: "piped",
        });

        const { stdout, stderr, success } = await command.output();

        if (!success) {
            const errorText = new TextDecoder().decode(stderr);
            console.error(`Preview generation failed: ${errorText}`);
            return `[Preview unavailable: ${errorText.trim()}]`;
        }

        const output = new TextDecoder().decode(stdout);

        // Cache the result
        previewCache.set(themePath, output);

        return output;
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        return `[Preview error: ${errorMessage}]`;
    }
}

/**
 * Clear the preview cache
 */
export function clearPreviewCache(): void {
    previewCache.clear();
}

/**
 * Get cache size (for debugging)
 */
export function getCacheSize(): number {
    return previewCache.size;
}
