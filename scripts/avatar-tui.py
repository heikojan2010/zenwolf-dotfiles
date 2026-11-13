#!/usr/bin/env python3
"""Zenwolf Avatar: Bubblegum Neon terminal visualizer.

A lightweight, dependency-free ANSI animation. Press q or Ctrl-C to quit.
This is a terminal visualizer, not a desktop wallpaper or compositor.
"""
import math
import os
import shutil
import sys
import time

PINK = "\033[38;5;213m"
HOT = "\033[38;5;201m"
PALE = "\033[38;5;225m"
PURPLE = "\033[38;5;141m"
DIM = "\033[38;5;97m"
RESET = "\033[0m"
HIDE = "\033[?25l"
SHOW = "\033[?25h"
CLEAR = "\033[2J\033[H"
CHARS = "·:*✦✧+"
ELEMENTS = ("AIR", "WATER", "EARTH", "FIRE")
SYMBOLS = ("༄", "≈", "◆", "✹")


def main():
    start = time.monotonic()
    try:
        sys.stdout.write(HIDE)
        while True:
            width, height = shutil.get_terminal_size((80, 24))
            t = time.monotonic() - start
            lines = [CLEAR]
            lines.append(f"{HOT}╭{'─' * max(0, width - 2)}╮{RESET}")
            title = " AVATAR // BUBBLEGUM NEON // FOUR ELEMENTS "
            lines.append(f"{HOT}│{PALE}{title:^{max(0, width - 2)}}{HOT}│{RESET}")
            lines.append(f"{HOT}├{'─' * max(0, width - 2)}┤{RESET}")
            usable = max(1, height - 8)
            for y in range(usable):
                row = []
                for x in range(max(1, width - 4)):
                    phase = (x * 0.17 + y * 0.31 + t * 1.7)
                    wave = math.sin(phase) + math.cos(phase * 0.63 + t)
                    if wave > 1.35:
                        row.append(HOT + CHARS[int(abs(phase * 3)) % len(CHARS)] + RESET)
                    elif wave > 0.75:
                        row.append(PINK + "·" + RESET)
                    elif wave < -1.55:
                        row.append(PURPLE + "✧" + RESET)
                    else:
                        row.append(" ")
                lines.append(f"{DIM}│{RESET} " + "".join(row[:max(1, width - 4)]) + f" {DIM}│{RESET}")
            idx = int(t / 2.4) % 4
            pulse = 0.5 + 0.5 * math.sin(t * 2.2)
            meter = "█" * int(pulse * min(22, max(8, width // 4)))
            lines.append(f"{HOT}├{'─' * max(0, width - 2)}┤{RESET}")
            footer = f" {SYMBOLS[idx]}  {ELEMENTS[idx]}  {PINK}{meter}{RESET}  {PALE}q: exit{RESET}"
            lines.append(f"{HOT}│{RESET}{footer:<{max(0, width - 2)}}{HOT}│{RESET}")
            lines.append(f"{HOT}╰{'─' * max(0, width - 2)}╯{RESET}")
            sys.stdout.write("\n".join(lines))
            sys.stdout.flush()
            time.sleep(1 / 12)
    except (KeyboardInterrupt, BrokenPipeError):
        pass
    finally:
        sys.stdout.write(RESET + SHOW + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
