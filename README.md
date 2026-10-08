# Neuro Word Hunt (GNU Octave)

![Game Screenshot](word_search_game_screenshot.png)

| Win | Lose |
|-----|------|
| ![Win](word_search_game_win.png) | ![Lose](word_search_game_lose.png) |

A neuroscience word search game for GNU Octave. Eight terms (neuron, dendrite, hippocampus, mice and more) are hidden in a 12x12 letter grid. Find them all before the timer runs out.

## Run it

1. Put `word_search_game_VF.m` in a folder (it is a single file).
2. In the Octave Command Window, go to that folder:
   ```octave
   >> cd "path/to/the/folder"
   ```
3. Start the game:
   ```octave
   >> word_search_game_VF
   ```

Tested with GNU Octave 8.4.0 and the `qt` graphics toolkit. The command prompt stays busy while the game window is open; close the window (or press Quit) to get it back. The window can be resized.

## How to play

1. Enter a username on the start screen and pick a level.
2. Press **Play**.
3. Press the mouse button on the first letter of a word, drag to its last letter, then release.
4. A correct word turns green and is marked `[found]`. A wrong selection is cleared.
5. Find all the words before the timer reaches 00:00 to win.

Words run across, down or diagonally. You can drag from either end, so backwards selections count too.

## Levels

| Level | Difficulty | Timer |
|-------|------------|-------|
| 1 | Easy | 5 minutes |
| 2 | Medium | 3 minutes |
| 3 | Hard | 1 minute |

## Points and hints

- Each word you find gives you 10 points.
- A hint costs 5 points. It highlights the first letter of the longest word you have not found yet for a few seconds. You need at least 5 points to use it.
- Your highest points (from won games) are saved in a small file in your home folder.

## Buttons

- **Hint**: highlights the start of a word (5 points).
- **Reset**: restarts the game from zero at the same level, with a new grid, new words, a cleared score and a fresh timer.
- **Pause**: freezes the timer and shows a black screen with the pause time. **Keep going** resumes the game.
- **Menu**: goes back to the start screen, where you can change your username or level.
- **How to play**: opens the rules from the start screen.
- **Quit**: closes the game.

## Winning and losing

When the game ends, a message screen shows "[username], you won!" if you found every word in time, or "[username], you lost!" if the timer reached zero first. Three dancing mice celebrate a win, and three dead mice appear when time runs out. From there you can play again at the same level, go back to the start screen or quit.

## Confetti

Every time you find a word, a burst of confetti is thrown from the word.

## Sources

- Game idea adapted from the web game "Word Search" by Mahathi: https://github.com/Mahathi1601/Word-Search
- Octave code and word list written with the help of Claude (Anthropic).
- No sound and no external image: the grid, the confetti and the mice are drawn by the Octave code (original cartoon drawings).
