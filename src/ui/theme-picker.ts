/**
 * Interactive Theme Picker with Live Preview
 * 
 * Provides a TUI for browsing and previewing oh-my-posh themes
 */

import {
    cursor,
    clear,
    style,
    fg,
    screen,
    write,
    writeLine,
    styled,
    getTerminalSize,
} from "./ansi.ts";
import { generatePreview } from "../preview.ts";

interface ThemePickerOptions {
    /** List of theme filenames */
    themes: string[];
    /** Base path to themes directory */
    themesPath: string;
    /** Number of items to show in list (default: 10) */
    pageSize?: number;
    /** Header message */
    message?: string;
}

interface ThemePickerResult {
    /** Selected theme filename or null if cancelled */
    selected: string | null;
    /** Whether the user cancelled */
    cancelled: boolean;
}

// Key codes for special keys
const KEY = {
    UP: ["\x1b[A", "\x1bOA"],           // Arrow up
    DOWN: ["\x1b[B", "\x1bOB"],         // Arrow down
    LEFT: ["\x1b[D", "\x1bOD"],         // Arrow left
    RIGHT: ["\x1b[C", "\x1bOC"],        // Arrow right
    ENTER: ["\r", "\n"],                // Enter
    ESCAPE: ["\x1b"],                   // Escape (but not arrow sequences)
    CTRL_C: ["\x03"],                   // Ctrl+C
    BACKSPACE: ["\x7f", "\b"],          // Backspace
    TAB: ["\t"],                        // Tab
    PAGE_UP: ["\x1b[5~"],               // Page Up
    PAGE_DOWN: ["\x1b[6~"],             // Page Down
    HOME: ["\x1b[H", "\x1b[1~"],        // Home
    END: ["\x1b[F", "\x1b[4~"],         // End
};

function isKey(input: string, keys: string[]): boolean {
    return keys.includes(input);
}

function isEscapeOnly(input: string): boolean {
    // Escape key only if it's just ESC and not part of an arrow sequence
    return input === "\x1b";
}

/**
 * Interactive theme picker with live preview
 */
export async function pickTheme(options: ThemePickerOptions): Promise<ThemePickerResult> {
    const {
        themes,
        themesPath,
        pageSize = 10,
        message = "Select a theme (↑/↓ navigate, type to filter, Enter to select, Esc to cancel):",
    } = options;

    let selectedIndex = 0;
    let scrollOffset = 0;
    let searchQuery = "";
    let filteredThemes = [...themes];
    let currentPreview = "";
    let isLoadingPreview = false;
    let lastPreviewedTheme = "";

    // Set up raw mode for keyboard input
    if (Deno.stdin.isTerminal()) {
        Deno.stdin.setRaw(true);
    }

    // Enter alternate screen and hide cursor
    write(screen.enter + cursor.hide);

    /**
     * Filter themes based on search query
     */
    function filterThemes(): void {
        const query = searchQuery.toLowerCase();
        filteredThemes = themes.filter(theme =>
            theme.toLowerCase().includes(query)
        );
        // Reset selection if out of bounds
        if (selectedIndex >= filteredThemes.length) {
            selectedIndex = Math.max(0, filteredThemes.length - 1);
        }
        // Reset scroll offset
        scrollOffset = Math.max(0, Math.min(scrollOffset, Math.max(0, filteredThemes.length - pageSize)));
        // Ensure selected item is visible
        if (selectedIndex < scrollOffset) {
            scrollOffset = selectedIndex;
        } else if (selectedIndex >= scrollOffset + pageSize) {
            scrollOffset = selectedIndex - pageSize + 1;
        }
    }

    /**
     * Update the preview for the current selection
     */
    async function updatePreview(): Promise<void> {
        if (filteredThemes.length === 0) {
            currentPreview = styled("No themes match your filter", fg.yellow);
            return;
        }

        const currentTheme = filteredThemes[selectedIndex];
        const themePath = `${themesPath}/${currentTheme}`;

        if (currentTheme === lastPreviewedTheme) {
            return; // No need to regenerate
        }

        lastPreviewedTheme = currentTheme;
        isLoadingPreview = true;
        render(); // Show loading state

        currentPreview = await generatePreview(themePath);
        isLoadingPreview = false;
    }

    /**
     * Render the UI
     */
    function render(): void {
        const { cols } = getTerminalSize();

        // Clear screen and move to top
        write(clear.screen + cursor.home);

        // Header/message
        writeLine(styled(message, fg.cyan, style.bold));
        writeLine();

        // Search box
        const searchDisplay = searchQuery || styled("Type to filter...", fg.brightBlack, style.italic);
        writeLine(`${styled("🔍 ", fg.yellow)}${searchDisplay}`);
        writeLine(styled("─".repeat(Math.min(50, cols - 2)), fg.brightBlack));

        // Show scroll indicator if needed
        if (scrollOffset > 0) {
            writeLine(styled("  ↑ more themes above", fg.brightBlack, style.italic));
        } else {
            writeLine();
        }

        for (let i = 0; i < pageSize; i++) {
            const themeIndex = scrollOffset + i;
            if (themeIndex < filteredThemes.length) {
                const theme = filteredThemes[themeIndex];
                const isSelected = themeIndex === selectedIndex;

                if (isSelected) {
                    // Highlighted selection
                    writeLine(styled(`  ❯ ${theme}`, fg.cyan, style.bold));
                } else {
                    writeLine(styled(`    ${theme}`, fg.white));
                }
            } else {
                writeLine(); // Empty line for padding
            }
        }

        // Show scroll indicator if needed
        if (scrollOffset + pageSize < filteredThemes.length) {
            writeLine(styled("  ↓ more themes below", fg.brightBlack, style.italic));
        } else {
            writeLine();
        }

        // Separator
        writeLine();
        writeLine(styled("─".repeat(Math.min(70, cols - 2)), fg.brightBlack));

        // Preview section
        writeLine(styled("Preview:", fg.magenta, style.bold));
        writeLine();

        if (isLoadingPreview) {
            writeLine(styled("  Loading preview...", fg.yellow, style.italic));
        } else if (currentPreview) {
            // Split preview into lines and render
            const previewLines = currentPreview.split("\n");
            for (const line of previewLines) {
                writeLine(`  ${line}`);
            }
        } else {
            writeLine(styled("  [No preview available]", fg.brightBlack));
        }

        // Footer with key hints
        writeLine();
        writeLine(styled("─".repeat(Math.min(70, cols - 2)), fg.brightBlack));
        writeLine(
            styled("↑↓", fg.cyan) + " Navigate  " +
            styled("Enter", fg.green) + " Select  " +
            styled("Esc", fg.red) + " Cancel  " +
            styled("Type", fg.yellow) + " Filter"
        );

        // Status
        const statusText = `${filteredThemes.length}/${themes.length} themes`;
        writeLine(styled(`  ${statusText}`, fg.brightBlack, style.italic));
    }

    /**
     * Handle keyboard input
     */
    function handleInput(input: string): "continue" | "select" | "cancel" {
        // Check for special keys first
        if (isKey(input, KEY.CTRL_C) || (isEscapeOnly(input) && !input.startsWith("\x1b["))) {
            return "cancel";
        }

        if (isKey(input, KEY.ENTER)) {
            return "select";
        }

        if (isKey(input, KEY.UP)) {
            if (selectedIndex > 0) {
                selectedIndex--;
                if (selectedIndex < scrollOffset) {
                    scrollOffset = selectedIndex;
                }
            }
            return "continue";
        }

        if (isKey(input, KEY.DOWN)) {
            if (selectedIndex < filteredThemes.length - 1) {
                selectedIndex++;
                if (selectedIndex >= scrollOffset + pageSize) {
                    scrollOffset = selectedIndex - pageSize + 1;
                }
            }
            return "continue";
        }

        if (isKey(input, KEY.PAGE_UP)) {
            selectedIndex = Math.max(0, selectedIndex - pageSize);
            scrollOffset = Math.max(0, scrollOffset - pageSize);
            return "continue";
        }

        if (isKey(input, KEY.PAGE_DOWN)) {
            selectedIndex = Math.min(filteredThemes.length - 1, selectedIndex + pageSize);
            scrollOffset = Math.min(
                Math.max(0, filteredThemes.length - pageSize),
                scrollOffset + pageSize
            );
            return "continue";
        }

        if (isKey(input, KEY.HOME)) {
            selectedIndex = 0;
            scrollOffset = 0;
            return "continue";
        }

        if (isKey(input, KEY.END)) {
            selectedIndex = filteredThemes.length - 1;
            scrollOffset = Math.max(0, filteredThemes.length - pageSize);
            return "continue";
        }

        if (isKey(input, KEY.BACKSPACE)) {
            if (searchQuery.length > 0) {
                searchQuery = searchQuery.slice(0, -1);
                filterThemes();
            }
            return "continue";
        }

        // Handle printable characters (for search)
        if (input.length === 1 && input.charCodeAt(0) >= 32 && input.charCodeAt(0) < 127) {
            searchQuery += input;
            filterThemes();
            return "continue";
        }

        return "continue";
    }

    /**
     * Cleanup and restore terminal
     */
    function cleanup(): void {
        // Restore terminal state
        write(cursor.show + screen.leave);
        if (Deno.stdin.isTerminal()) {
            Deno.stdin.setRaw(false);
        }
    }

    try {
        // Initial render and preview
        await updatePreview();
        render();

        // Main input loop
        const decoder = new TextDecoder();
        const buffer = new Uint8Array(16);

        while (true) {
            const bytesRead = await Deno.stdin.read(buffer);
            if (bytesRead === null) break;

            const input = decoder.decode(buffer.subarray(0, bytesRead));
            const action = handleInput(input);

            if (action === "cancel") {
                cleanup();
                return { selected: null, cancelled: true };
            }

            if (action === "select") {
                cleanup();
                if (filteredThemes.length > 0) {
                    return { selected: filteredThemes[selectedIndex], cancelled: false };
                }
                return { selected: null, cancelled: true };
            }

            // Update preview if selection changed
            await updatePreview();
            render();
        }

        cleanup();
        return { selected: null, cancelled: true };

    } catch (error) {
        cleanup();
        throw error;
    }
}
