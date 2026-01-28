/**
 * ANSI Escape Code Utilities for Terminal UI
 */

// Escape sequence prefix
const ESC = "\x1b";
const CSI = `${ESC}[`;

/**
 * Cursor control sequences
 */
export const cursor = {
  /** Hide the cursor */
  hide: `${CSI}?25l`,
  /** Show the cursor */
  show: `${CSI}?25h`,
  /** Move cursor to home position (0,0) */
  home: `${CSI}H`,
  /** Move cursor to specific position (1-indexed) */
  to: (row: number, col: number = 1) => `${CSI}${row};${col}H`,
  /** Move cursor up N lines */
  up: (n: number = 1) => `${CSI}${n}A`,
  /** Move cursor down N lines */
  down: (n: number = 1) => `${CSI}${n}B`,
  /** Move cursor forward N columns */
  forward: (n: number = 1) => `${CSI}${n}C`,
  /** Move cursor backward N columns */
  backward: (n: number = 1) => `${CSI}${n}D`,
  /** Move cursor to beginning of line */
  lineStart: `${CSI}G`,
  /** Save cursor position */
  save: `${CSI}s`,
  /** Restore cursor position */
  restore: `${CSI}u`,
};

/**
 * Screen/line clearing sequences
 */
export const clear = {
  /** Clear entire screen */
  screen: `${CSI}2J`,
  /** Clear from cursor to end of screen */
  screenFromCursor: `${CSI}0J`,
  /** Clear from cursor to beginning of screen */
  screenToCursor: `${CSI}1J`,
  /** Clear entire line */
  line: `${CSI}2K`,
  /** Clear from cursor to end of line */
  lineFromCursor: `${CSI}0K`,
  /** Clear from cursor to beginning of line */
  lineToCursor: `${CSI}1K`,
  /** Clear N lines starting from current position */
  lines: (n: number) => {
    let seq = "";
    for (let i = 0; i < n; i++) {
      seq += clear.line + cursor.down(1);
    }
    return seq + cursor.up(n);
  },
};

/**
 * Text styling sequences
 */
export const style = {
  /** Reset all styles */
  reset: `${CSI}0m`,
  /** Bold text */
  bold: `${CSI}1m`,
  /** Dim text */
  dim: `${CSI}2m`,
  /** Italic text */
  italic: `${CSI}3m`,
  /** Underline text */
  underline: `${CSI}4m`,
  /** Inverse colors */
  inverse: `${CSI}7m`,
  /** Hidden text */
  hidden: `${CSI}8m`,
  /** Strikethrough text */
  strikethrough: `${CSI}9m`,
};

/**
 * Foreground colors (text colors)
 */
export const fg = {
  black: `${CSI}30m`,
  red: `${CSI}31m`,
  green: `${CSI}32m`,
  yellow: `${CSI}33m`,
  blue: `${CSI}34m`,
  magenta: `${CSI}35m`,
  cyan: `${CSI}36m`,
  white: `${CSI}37m`,
  default: `${CSI}39m`,
  // Bright variants
  brightBlack: `${CSI}90m`,
  brightRed: `${CSI}91m`,
  brightGreen: `${CSI}92m`,
  brightYellow: `${CSI}93m`,
  brightBlue: `${CSI}94m`,
  brightMagenta: `${CSI}95m`,
  brightCyan: `${CSI}96m`,
  brightWhite: `${CSI}97m`,
  /** 256 color */
  color256: (n: number) => `${CSI}38;5;${n}m`,
  /** RGB color */
  rgb: (r: number, g: number, b: number) => `${CSI}38;2;${r};${g};${b}m`,
};

/**
 * Background colors
 */
export const bg = {
  black: `${CSI}40m`,
  red: `${CSI}41m`,
  green: `${CSI}42m`,
  yellow: `${CSI}43m`,
  blue: `${CSI}44m`,
  magenta: `${CSI}45m`,
  cyan: `${CSI}46m`,
  white: `${CSI}47m`,
  default: `${CSI}49m`,
  // Bright variants
  brightBlack: `${CSI}100m`,
  brightRed: `${CSI}101m`,
  brightGreen: `${CSI}102m`,
  brightYellow: `${CSI}103m`,
  brightBlue: `${CSI}104m`,
  brightMagenta: `${CSI}105m`,
  brightCyan: `${CSI}106m`,
  brightWhite: `${CSI}107m`,
  /** 256 color */
  color256: (n: number) => `${CSI}48;5;${n}m`,
  /** RGB color */
  rgb: (r: number, g: number, b: number) => `${CSI}48;2;${r};${g};${b}m`,
};

/**
 * Alternative screen buffer (for full-screen TUI apps)
 */
export const screen = {
  /** Enter alternative screen buffer */
  enter: `${CSI}?1049h`,
  /** Leave alternative screen buffer */
  leave: `${CSI}?1049l`,
};

/**
 * Utility functions
 */

/**
 * Write directly to stdout
 */
export function write(text: string): void {
  const encoder = new TextEncoder();
  Deno.stdout.writeSync(encoder.encode(text));
}

/**
 * Write a line to stdout
 */
export function writeLine(text: string = ""): void {
  write(text + "\n");
}

/**
 * Clear a specific region and write text there
 */
export function writeAt(row: number, col: number, text: string): void {
  write(cursor.to(row, col) + text);
}

/**
 * Apply multiple styles/colors to text and reset after
 */
export function styled(text: string, ...styles: string[]): string {
  return styles.join("") + text + style.reset;
}

/**
 * Get terminal size
 */
export function getTerminalSize(): { rows: number; cols: number } {
  try {
    const { rows, columns } = Deno.consoleSize();
    return { rows, cols: columns };
  } catch {
    // Fallback if consoleSize is not available
    return { rows: 24, cols: 80 };
  }
}
