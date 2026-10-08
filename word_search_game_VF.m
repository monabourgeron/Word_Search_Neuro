% =====================================================================
%  NEURO WORD HUNT  -  word_search_game_VF.m
% =====================================================================
%  GOAL
%    Find the 8 hidden neuroscience words in a 12x12 letter grid before
%    the countdown reaches zero. Win = all words found in time,
%    lose = the timer reaches 00:00 first.
%
%  GAME COMPONENTS
%    - Start screen: presentation, username field, level menu, Play,
%      How to play, Quit.
%    - How to play screen: detailed rules and controls.
%    - Game screen: 12x12 grid (drawn in a figure/axes with rectangles and
%      text), list of words to find, stats (words, time left, points),
%      buttons Hint, Reset, Pause, Menu.
%    - Pause screen: black screen with the pause time and a Keep going button.
%    - Results screen: "[username], you won!" or "[username], you lost!",
%      statistics, Play again, Back to start, Quit. Three dancing mice
%      celebrate a win; three dead mice appear when the time runs out.
%    - Confetti: a burst of confetti from the word every time one is found.
%
%  MAIN VARIABLES
%    state : struct with everything that changes during the game
%            (screen, username, level, running, paused, targetWords,
%             foundWords, points, letterGrid, placements, selection ...).
%    ui    : struct with the graphic handles (buttons, texts, grid cells,
%            and the list of handles of each screen).
%    fig   : handle of the figure. state and ui are stored in it with
%            setappdata / getappdata so that every callback can reach them.
%
%  MAIN LOOP
%    After the figure is built, the program loops while the window exists:
%    wait 0.04 s (pause), then call tick(). tick() (1) moves the confetti and
%    the dancing mice, (2) updates the countdown and ends the game when it
%    reaches zero, (3) updates the pause timer while the game is paused,
%    (4) clears the message (toast) and the hint highlight after their delay.
%    Everything else (mouse drag, buttons) is handled by callbacks, which
%    run while the loop waits.
%
%  ACROSS TRIALS (ROUNDS)
%    Every new round (Play, Reset, Play again) draws 8 new random words
%    from a pool of 119 words and builds a new random grid. The score,
%    found words and timer restart from zero; username and level are kept.
%    The best score of won games is saved in a small text file in the
%    home folder (.neuro_word_hunt_highscore).
%
%  RULES
%    - 8 words per round; each found word gives 10 points.
%    - A hint costs 5 points (needs at least 5 points). It highlights the
%      first letter of the longest word not found yet for 4 seconds.
%    - Levels: Easy 5 minutes, Medium 3 minutes, Hard 1 minute.
%    - Pause freezes the countdown; the time spent in pause is shown.
%
%  WAYS TO MOVE (CONTROLS)
%    - Press the mouse button on the first letter of a word, drag in a
%      straight line (across, down or diagonal) to its last letter and
%      release. You can start from either end of the word.
%    - Buttons: Hint, Reset (restart at the same level), Pause, Menu.
%
%  CONTEXT OF THIS GAME
%    University course project: write an interactive game in GNU Octave
%    and share it on GitHub. This is a word-search game on a
%    neuroscience theme.
%
%  SOURCES (AI / SOUND / IMAGES / WORD LIST)
%    - AI: the Octave code was written with the help of Claude (AI assistant
%      by Anthropic), from the authors' specifications.
%    - Game idea: adapted from the open-source web game "Word Search"
%      by Mahathi (https://github.com/Mahathi1601/Word-Search).
%    - Word list: 119 neuroscience terms proposed by the autors and Claude, checked by
%      the authors.
%    - Sound: none. Images: none inside the program. The confetti and the
%      mice are drawn by the code itself (original cartoon drawings, not taken
%      from any film). word_search_game_screenshot.png is a screenshot.
%
%  VERSIONS
%    - Code version: VF (final), 1.1 (confetti and mice added)
%    - Tested with GNU Octave 8.4.0, qt graphics toolkit.
%
%  AUTHORS AND CONTRIBUTION
%    - Philaé BOURDENET : conceptualization of the game, coding and verification
%    - Mona BOURGERON: conceptualization of the game,coding and verificaiton 
%   
%  DATE
%    2026-10-08  (format: YYYY-MM-DD, year-month-day)
% =====================================================================

function word_search_game_VF()

  % ---------------------------------------------------------------
  % 1. CONSTANTS AND INITIAL GAME STATE
  % ---------------------------------------------------------------
  % Neuroscience words: letters A-Z only, 12 letters maximum (grid is 12x12)
  state.wordPool = {"NEURON","DENDRITE","AXON","SYNAPSE","GLIA","ASTROCYTE","MICROGLIA","MYELIN", ...
            "CORTEX","CEREBELLUM","HIPPOCAMPUS","AMYGDALA","THALAMUS","HYPOTHALAMUS", ...
            "BRAINSTEM","MEDULLA","PONS","STRIATUM","DOPAMINE","SEROTONIN","GLUTAMATE", ...
            "GABA","ENDORPHIN","OXYTOCIN","CORTISOL","MELATONIN","RECEPTOR","PLASTICITY", ...
            "POTENTIATION","POTENTIAL","MEMBRANE","SODIUM","POTASSIUM","CALCIUM","CHLORIDE", ...
            "CHANNEL","NEUROGLIA","SOMA","VESICLE","EXOCYTOSIS","GANGLION","CEREBRUM", ...
            "CEREBRAL","FRONTAL","PARIETAL","TEMPORAL","OCCIPITAL","INSULA","CINGULATE", ...
            "GYRUS","SULCUS","FISSURE","LOBE","EEG","FMRI","ELECTRODE","MICE","RATS", ...
            "ZEBRAFISH","DROSOPHILA","EPILEPSY","AUTISM","ALZHEIMER","PARKINSON","DEPRESSION", ...
            "ANXIETY","DEMENTIA","STROKE","APHASIA","AMNESIA","PSYCHIATRY","NEUROLOGY", ...
            "PSYCHOLOGY","COGNITION","MEMORY","ATTENTION","PERCEPTION","LEARNING","EMOTION", ...
            "SLEEP","DREAM","REFLEX","SENSORY","MOTOR","NEUROPATHY","NEUROTOXIN","NEUROTROPHIN", ...
            "CONNECTOME","TRACTOGRAPHY","SPIKE","BRAIN","MENINGES","VENTRICLE","PUTAMEN", ...
            "CAUDATE","SUBSTANTIA","PINEAL","PITUITARY","RETINA","COCHLEA","OLFACTORY","NEURAL", ...
            "NUCLEUS","TRACT","NODE","MICROSCOPE","REFRACTORY","THRESHOLD","SALTATORY","RANVIER", ...
            "SCHWANN","PURKINJE","PYRAMIDAL","INTERNEURON","MOTONEURON","CHOLINERGIC","GABAERGIC", ...
            "AFFERENT","EFFERENT"};
  state.gridSize = 12;
  state.wordsPerRound = 8;
  state.highScore = load_high_score();

  % Levels: 1 = Easy (5 min), 2 = Medium (3 min), 3 = Hard (1 min)
  state.levelNames   = {"Easy", "Medium", "Hard"};
  state.levelSeconds = [300 180 60];

  % Colours (RGB between 0 and 1)
  state.colors.cell       = [0.996 0.976 0.910];
  state.colors.selected   = [0.812 0.914 0.875];
  state.colors.found      = [0.831 0.902 0.851];
  state.colors.hint       = [1.000 0.922 0.231];
  state.colors.primary    = [0.427 0.596 0.525];
  state.colors.listBackground = [0.973 0.976 0.980];
  state.colors.card       = [0.851 0.894 0.867];
  state.colors.danger     = [0.753 0.314 0.302];
  state.colors.text       = [0.2 0.2 0.2];
  state.colors.grey       = [0.4 0.4 0.4];

  % State of the game before the first round (a round starts with Play)
  state.screen = "start";            % start, howto, game, pause or results
  state.username = "";
  state.level = 1;
  state.running = false;             % true while a round is being played
  state.paused = false;
  state.pauseTimer = tic;            % started when the game is paused
  state.elapsedBefore = 0;           % seconds played before the last resume
  state.roundTimer = tic;            % started at the beginning / last resume
  state.timeLimit = state.levelSeconds(1);
  state.secondsLeft = state.timeLimit;
  state.dragging = false;
  state.dragStart = [];
  state.selection = zeros(0, 2);     % selected cells, one [row col] per line
  state.letterGrid = repmat(' ', state.gridSize, state.gridSize);
  state.placements = struct();
  state.targetWords = {};
  state.foundWords = {};
  state.foundMask = false(state.gridSize);
  state.points = 0;
  state.hintCell = [];
  state.hintWord = "";
  state.hintUntil = 0;
  state.toastUntil = 0;
  state.confetti = struct("t0", [], "x0", [], "y0", [], "vx", [], "vy", [], "colorId", []);
  state.resultMode = "";             % "win", "lose" or "" (no mice shown)
  state.resultStart = 0;             % time when the results were reached
  state.mouseHandles = [];           % graphic objects of the mice

  % ---------------------------------------------------------------
  % 2. FIGURE (window). Normalized units make it resizable.
  % ---------------------------------------------------------------
  fig = figure("name", "Neuro Word Hunt", "numbertitle", "off", "menubar", "none", ...
               "color", [0.88 0.91 0.96], "position", [100 100 1000 620]);
  figureColor = get(fig, "color");

  % ---------------------------------------------------------------
  % 3. START SCREEN
  % ---------------------------------------------------------------
  handles = [];
  handles(end+1) = make_text(fig, [0.10 0.86 0.80 0.09], "Neuro Word Hunt", 24, "bold", "center", state.colors.primary);
  handles(end+1) = make_text(fig, [0.10 0.78 0.80 0.05], "Eight neuroscience terms are hidden in a grid of letters.", 12, "normal", "center", state.colors.text);
  handles(end+1) = make_text(fig, [0.10 0.73 0.80 0.05], "Find them all before the clock runs out.", 12, "normal", "center", state.colors.text);
  handles(end+1) = make_text(fig, [0.10 0.64 0.80 0.045], "- Words run across, down or diagonally, and you can select them from either end.", 11, "normal", "left", state.colors.text);
  handles(end+1) = make_text(fig, [0.10 0.59 0.80 0.045], "- Each word you find is worth 10 points. A hint costs 5 points.", 11, "normal", "left", state.colors.text);
  handles(end+1) = make_text(fig, [0.10 0.54 0.80 0.045], "- Pick a level: the harder the level, the shorter the timer.", 11, "normal", "left", state.colors.text);

  handles(end+1) = make_text(fig, [0.10 0.45 0.30 0.045], "Your username", 11, "bold", "left", state.colors.text);
  ui.nameEdit = uicontrol("parent", fig, "style", "edit", "units", "normalized", ...
                          "position", [0.10 0.39 0.40 0.06], "string", "", "fontsize", 12, ...
                          "horizontalalignment", "left", "backgroundcolor", [1 1 1], "userdata", 12);
  handles(end+1) = ui.nameEdit;
  ui.nameError = make_text(fig, [0.52 0.39 0.38 0.05], "", 10, "normal", "left", state.colors.danger);
  handles(end+1) = ui.nameError;

  handles(end+1) = make_text(fig, [0.10 0.31 0.30 0.045], "Level", 11, "bold", "left", state.colors.text);
  ui.levelMenu = uicontrol("parent", fig, "style", "popupmenu", "units", "normalized", ...
                           "position", [0.10 0.25 0.40 0.06], "fontsize", 11, "value", 1, "userdata", 11, ...
                           "string", {"Level 1 - Easy (5 minutes)", ...
                                      "Level 2 - Medium (3 minutes)", ...
                                      "Level 3 - Hard (1 minute)"});
  handles(end+1) = ui.levelMenu;

  handles(end+1) = make_button(fig, [0.10 0.12 0.18 0.08], "Play", @(~, ~) on_play(fig));
  handles(end+1) = make_button(fig, [0.30 0.12 0.18 0.08], "How to play", @(~, ~) show_screen(fig, "howto"));
  handles(end+1) = make_button(fig, [0.50 0.12 0.18 0.08], "Quit", @(~, ~) on_quit(fig));
  ui.screens.start = handles;

  % ---------------------------------------------------------------
  % 4. HOW TO PLAY SCREEN (rules and controls)
  % ---------------------------------------------------------------
  handles = [];
  handles(end+1) = make_text(fig, [0.10 0.89 0.80 0.07], "How to play", 22, "bold", "left", state.colors.primary);
  % "h" = heading line, "t" = normal text line
  rulesLines = { ...
    "h", "Objective"; ...
    "t", "Find every word in the Words to Find list before the timer reaches zero."; ...
    "t", "Each round uses 8 words picked at random from a list of neuroscience terms."; ...
    "h", "Controls"; ...
    "t", "Press the mouse button on the first letter of a word, drag to its last letter, then release."; ...
    "t", "Words run across, down or diagonally. You can drag from either end of a word."; ...
    "t", "A correct word turns green and is marked [found]. A wrong selection is cleared."; ...
    "h", "Points and hints"; ...
    "t", "Each word you find gives you 10 points."; ...
    "t", "The Hint button costs 5 points and highlights the first letter of the longest word left."; ...
    "h", "Pause, reset and levels"; ...
    "t", "Pause freezes the timer. Reset restarts a new game at the same level. Menu goes back to the start."; ...
    "t", "Easy: 5 minutes.     Medium: 3 minutes.     Hard: 1 minute."; ...
    "h", "Winning and losing"; ...
    "t", "Find all the words before the timer hits 00:00 to win. If time runs out first, you lose."};
  lineY = 0.83;
  for lineIndex = 1:rows(rulesLines)
    if strcmp(rulesLines{lineIndex, 1}, "h")
      handles(end+1) = make_text(fig, [0.10 lineY 0.80 0.04], rulesLines{lineIndex, 2}, 12, "bold", "left", state.colors.primary);
    else
      handles(end+1) = make_text(fig, [0.12 lineY 0.80 0.04], rulesLines{lineIndex, 2}, 10, "normal", "left", state.colors.text);
    endif
    lineY -= 0.047;
  endfor
  handles(end+1) = make_button(fig, [0.10 0.04 0.18 0.07], "Back to start", @(~, ~) show_screen(fig, "start"));
  ui.screens.howto = handles;

  % ---------------------------------------------------------------
  % 5. GAME SCREEN
  % ---------------------------------------------------------------
  handles = [];
  handles(end+1) = make_text(fig, [0.03 0.90 0.17 0.07], "Word Search", 16, "bold", "left", state.colors.primary);
  ui.levelBadge = make_text(fig, [0.21 0.905 0.16 0.05], "", 10, "bold", "left", state.colors.grey);
  handles(end+1) = ui.levelBadge;
  ui.hintButton = make_button(fig, [0.03 0.82 0.095 0.06], "Hint (5 pts)", @(~, ~) on_hint(fig));
  handles(end+1) = ui.hintButton;
  handles(end+1) = make_button(fig, [0.135 0.82 0.075 0.06], "Reset", @(~, ~) new_game(fig));
  handles(end+1) = make_button(fig, [0.22 0.82 0.075 0.06], "Pause", @(~, ~) on_pause(fig));
  handles(end+1) = make_button(fig, [0.305 0.82 0.065 0.06], "Menu", @(~, ~) go_start(fig));

  % Stats card: Words / Time left / Points
  handles(end+1) = make_text_bg(fig, [0.03 0.71 0.34 0.09], "", 9, "normal", "center", state.colors.grey, state.colors.card);
  handles(end+1) = make_text_bg(fig, [0.04 0.755 0.10 0.03], "Words", 9, "normal", "center", state.colors.grey, state.colors.card);
  handles(end+1) = make_text_bg(fig, [0.15 0.755 0.12 0.03], "Time left", 9, "normal", "center", state.colors.grey, state.colors.card);
  handles(end+1) = make_text_bg(fig, [0.28 0.755 0.08 0.03], "Points", 9, "normal", "center", state.colors.grey, state.colors.card);
  ui.statWords  = make_text_bg(fig, [0.04 0.715 0.10 0.04], "0/8", 13, "bold", "center", state.colors.primary, state.colors.card);
  ui.statTime   = make_text_bg(fig, [0.15 0.715 0.12 0.04], "00:00", 13, "bold", "center", state.colors.primary, state.colors.card);
  ui.statPoints = make_text_bg(fig, [0.28 0.715 0.08 0.04], "0", 13, "bold", "center", state.colors.primary, state.colors.card);
  handles = [handles, ui.statWords, ui.statTime, ui.statPoints];

  % List of the words to find (one label per word)
  handles(end+1) = make_text(fig, [0.03 0.66 0.34 0.04], "Words to Find", 12, "bold", "left", state.colors.text);
  ui.wordLabels = zeros(1, state.wordsPerRound);
  for labelIndex = 1:state.wordsPerRound
    ui.wordLabels(labelIndex) = uicontrol("parent", fig, "style", "text", "units", "normalized", ...
              "position", [0.03, 0.605 - (labelIndex-1)*0.065, 0.34, 0.052], ...
              "fontsize", 11, "fontweight", "bold", "horizontalalignment", "left", ...
              "backgroundcolor", state.colors.listBackground, "userdata", 11);
  endfor
  handles = [handles, ui.wordLabels];

  ui.toast  = make_text(fig, [0.03 0.06 0.34 0.05], "", 10, "normal", "left", state.colors.text);
  ui.footer = make_text(fig, [0.40 0.01 0.58 0.04], "", 9, "normal", "left", state.colors.grey);
  handles = [handles, ui.toast, ui.footer];

  % The letter grid: one rounded rectangle + one letter per cell, in an axes
  ui.axes = axes("parent", fig, "position", [0.40 0.07 0.58 0.90]);
  hold(ui.axes, "on");
  axis(ui.axes, "equal");
  set(ui.axes, "ydir", "reverse", "xlim", [0.5 state.gridSize+0.5], "ylim", [0.5 state.gridSize+0.5], ...
               "xtick", [], "ytick", [], "box", "off", "color", figureColor, ...
               "xcolor", figureColor, "ycolor", figureColor, "clipping", "off");
  ui.cellRects = zeros(state.gridSize);
  ui.cellTexts = zeros(state.gridSize);
  for row = 1:state.gridSize
    for col = 1:state.gridSize
      ui.cellRects(row, col) = rectangle("parent", ui.axes, ...
                              "position", [col-0.46 row-0.46 0.92 0.92], ...
                              "curvature", [0.2 0.2], "facecolor", state.colors.cell, ...
                              "edgecolor", [0.92 0.92 0.92], "hittest", "off");
      ui.cellTexts(row, col) = text(col, row, " ", "parent", ui.axes, ...
                              "horizontalalignment", "center", "verticalalignment", "middle", ...
                              "fontsize", 14, "fontweight", "bold", "hittest", "off");
    endfor
  endfor
  % Confetti: one line object per colour, only markers (no line), moved by tick()
  confettiColors = [0.91 0.30 0.35; 0.99 0.78 0.20; 0.30 0.65 0.95; ...
                    0.35 0.80 0.50; 0.75 0.45 0.90; 1.00 0.55 0.15];
  confettiMarkers = {"s", "d", "s", "d", "s", "d"};
  ui.confettiLines = zeros(1, rows(confettiColors));
  for colorIndex = 1:rows(confettiColors)
    ui.confettiLines(colorIndex) = line(NaN, NaN, "parent", ui.axes, "linestyle", "none", ...
                              "marker", confettiMarkers{colorIndex}, "markersize", 8, ...
                              "markerfacecolor", confettiColors(colorIndex, :), ...
                              "markeredgecolor", confettiColors(colorIndex, :), ...
                              "clipping", "off", "hittest", "off");   % clipping "on" hides the markers in Octave
  endfor
  handles = [handles, ui.axes, ui.cellRects(:)', ui.cellTexts(:)', ui.confettiLines];
  ui.screens.game = handles;

  % ---------------------------------------------------------------
  % 6. PAUSE SCREEN (black screen, pause time, Keep going button)
  % ---------------------------------------------------------------
  handles = [];
  handles(end+1) = make_text_bg(fig, [0 0 1 1], "", 10, "normal", "center", [1 1 1], [0 0 0]);   % black background
  handles(end+1) = make_text_bg(fig, [0.10 0.62 0.80 0.12], "Paused", 30, "bold", "center", [1 1 1], [0 0 0]);
  ui.pauseTime = make_text_bg(fig, [0.10 0.52 0.80 0.07], "Pause time: 00:00", 16, "normal", "center", [0.85 0.85 0.85], [0 0 0]);
  handles(end+1) = ui.pauseTime;
  handles(end+1) = make_button(fig, [0.40 0.35 0.20 0.09], "Keep going", @(~, ~) on_resume(fig));
  ui.screens.pause = handles;

  % ---------------------------------------------------------------
  % 7. RESULTS SCREEN (victory / defeat)
  % ---------------------------------------------------------------
  handles = [];
  ui.resultTitle   = make_text(fig, [0.05 0.82 0.90 0.12], "", 28, "bold", "center", state.colors.primary);
  ui.resultMessage = make_text(fig, [0.05 0.75 0.90 0.06], "", 14, "normal", "center", state.colors.text);
  ui.resultStats   = make_text(fig, [0.05 0.68 0.90 0.05], "", 11, "normal", "center", state.colors.grey);
  handles = [handles, ui.resultTitle, ui.resultMessage, ui.resultStats];
  handles(end+1) = make_button(fig, [0.22 0.57 0.17 0.08], "Play again", @(~, ~) on_play_again(fig));
  handles(end+1) = make_button(fig, [0.41 0.57 0.19 0.08], "Back to start", @(~, ~) go_start(fig));
  handles(end+1) = make_button(fig, [0.62 0.57 0.15 0.08], "Quit", @(~, ~) on_quit(fig));

  % Stage for the mice (drawn by draw_mice): dancing if won, dead if lost
  ui.resultAxes = axes("parent", fig, "position", [0.10 0.02 0.80 0.50]);
  hold(ui.resultAxes, "on");
  set(ui.resultAxes, "xlim", [0 4.5], "ylim", [0 1.6], "dataaspectratio", [1 1 1], ...
                     "xtick", [], "ytick", [], "box", "off", "color", figureColor, ...
                     "xcolor", figureColor, "ycolor", figureColor);
  handles(end+1) = ui.resultAxes;
  ui.screens.results = handles;

  % ---------------------------------------------------------------
  % 8. MOUSE CALLBACKS (drag to select a word) AND FIRST DISPLAY
  % ---------------------------------------------------------------
  set(fig, "windowbuttondownfcn",   @(~, ~) on_mouse_down(fig));
  set(fig, "windowbuttonmotionfcn", @(~, ~) on_mouse_move(fig));
  set(fig, "windowbuttonupfcn",     @(~, ~) on_mouse_up(fig));
  try
    set(fig, "sizechangedfcn", @(~, ~) on_resize(fig));   % Octave 6 and later
  catch
    set(fig, "resizefcn", @(~, ~) on_resize(fig));        % older versions
  end_try_catch

  setappdata(fig, "state", state);
  setappdata(fig, "ui", ui);
  show_screen(fig, "start");
  on_resize(fig);

  % ---------------------------------------------------------------
  % 9. MAIN LOOP: runs while the window exists; callbacks run during pause()
  % ---------------------------------------------------------------
  while ishghandle(fig)
    pause(0.04);
    if !ishghandle(fig), break; endif
    tick(fig);
  endwhile
endfunction


% =====================================================================
%  SMALL USER-INTERFACE HELPERS
% =====================================================================

% Static text on the figure background colour
function textHandle = make_text(fig, position, message, fontSize, weight, alignment, textColor)
  textHandle = make_text_bg(fig, position, message, fontSize, weight, alignment, textColor, get(fig, "color"));
endfunction


% Static text with a chosen background colour
function textHandle = make_text_bg(fig, position, message, fontSize, weight, alignment, textColor, backColor)
  textHandle = uicontrol("parent", fig, "style", "text", "units", "normalized", ...
                         "position", position, "string", message, "fontsize", fontSize, ...
                         "fontweight", weight, "horizontalalignment", alignment, ...
                         "foregroundcolor", textColor, "backgroundcolor", backColor, ...
                         "userdata", fontSize);          % base size, used when the window is resized
endfunction


% Push button that calls callbackFunction when pressed
function buttonHandle = make_button(fig, position, label, callbackFunction)
  buttonHandle = uicontrol("parent", fig, "style", "pushbutton", "units", "normalized", ...
                           "position", position, "string", label, "fontsize", 10, ...
                           "callback", callbackFunction, "userdata", 10);
endfunction


% Window resized: layout follows (normalized units), fonts are scaled here
function on_resize(fig)
  if !ishghandle(fig) || !isappdata(fig, "ui"), return; endif
  ui = getappdata(fig, "ui");
  figurePosition = get(fig, "position");              % [left bottom width height] in pixels
  scale = min(figurePosition(3) / 1000, figurePosition(4) / 620);
  scale = max(0.5, min(scale, 1.8));
  controls = findall(fig, "type", "uicontrol");
  for controlIndex = 1:numel(controls)
    baseSize = get(controls(controlIndex), "userdata");
    if isnumeric(baseSize) && isscalar(baseSize)
      set(controls(controlIndex), "fontsize", baseSize * scale);
    endif
  endfor
  set(ui.cellTexts(:), "fontsize", 14 * scale);       % letters of the grid
endfunction


% Shows one screen and hides the others
function show_screen(fig, screenName)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  allScreens = {"start", "howto", "game", "pause", "results"};
  for screenIndex = 1:numel(allScreens)
    if !strcmp(allScreens{screenIndex}, screenName)
      set(ui.screens.(allScreens{screenIndex}), "visible", "off");
    endif
  endfor
  set(ui.screens.(screenName), "visible", "on");
  if !strcmp(screenName, "results") && !isempty(state.mouseHandles)
    delete(state.mouseHandles(ishghandle(state.mouseHandles)));   % remove the mice
    state.mouseHandles = [];
    state.resultMode = "";
  endif
  state.screen = screenName;
  setappdata(fig, "state", state);
  drawnow();
endfunction


% =====================================================================
%  START SCREEN / MENU ACTIONS
% =====================================================================

% Play button: checks the username, reads the level, starts the first round
function on_play(fig)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");

  username = strtrim(get(ui.nameEdit, "string"));
  if iscell(username), username = username{1}; endif
  if isempty(username)
    set(ui.nameError, "string", "Enter a username to start playing.");
    return;
  endif
  set(ui.nameError, "string", "");

  state.username = username(1:min(end, 20));
  state.level = get(ui.levelMenu, "value");
  setappdata(fig, "state", state);

  new_game(fig);
  show_screen(fig, "game");
endfunction


% Play again button (results screen): new round, same username and level
function on_play_again(fig)
  new_game(fig);
  show_screen(fig, "game");
endfunction


% Menu / Back to start: stops the current round and shows the start screen
function go_start(fig)
  state = getappdata(fig, "state");
  state.running = false;
  state.paused = false;
  state.dragging = false;
  setappdata(fig, "state", state);
  show_screen(fig, "start");
endfunction


% Quit button: closes the window, which also ends the main loop
function on_quit(fig)
  delete(fig);
endfunction


% =====================================================================
%  PAUSE
% =====================================================================

% Pause button: freezes the countdown and shows the black pause screen
function on_pause(fig)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  if !state.running || state.paused, return; endif

  state.elapsedBefore += toc(state.roundTimer);   % time played so far
  state.paused = true;
  state.pauseTimer = tic;
  state.dragging = false;
  setappdata(fig, "state", state);

  set_selection(fig, zeros(0, 2));
  set(ui.pauseTime, "string", "Pause time: 00:00");
  show_screen(fig, "pause");
endfunction


% Keep going button: the countdown continues where it stopped
function on_resume(fig)
  state = getappdata(fig, "state");
  if !state.paused, return; endif
  state.paused = false;
  state.roundTimer = tic;
  setappdata(fig, "state", state);
  show_screen(fig, "game");
endfunction


% Seconds left in the round (the time spent in pause is not counted)
function secondsLeft = get_seconds_left(state)
  elapsed = state.elapsedBefore;
  if !state.paused
    elapsed += toc(state.roundTimer);
  endif
  secondsLeft = max(0, ceil(state.timeLimit - elapsed));
endfunction


% =====================================================================
%  GAME LOGIC
% =====================================================================

% Starts a completely fresh round for the current level.
% Used by Play, Reset and Play again.
function new_game(fig)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");

  % keep drawing words until every one of them fits in the grid
  allPlaced = false;
  while !allPlaced
    shuffled = randperm(numel(state.wordPool));
    chosenWords = state.wordPool(shuffled(1:state.wordsPerRound));
    [letterGrid, placements, allPlaced] = create_word_grid(chosenWords, state.gridSize);
  endwhile

  state.letterGrid = letterGrid;
  state.placements = placements;
  state.targetWords = chosenWords;
  state.foundWords = {};
  state.points = 0;
  state.selection = zeros(0, 2);
  state.dragging = false;
  state.dragStart = [];
  state.foundMask = false(state.gridSize);
  state.timeLimit = state.levelSeconds(state.level);
  state.secondsLeft = state.timeLimit;
  state.elapsedBefore = 0;
  state.roundTimer = tic;
  state.paused = false;
  state.running = true;
  state.hintCell = [];
  state.hintWord = "";
  state.hintUntil = 0;
  state.toastUntil = 0;
  state.confetti = struct("t0", [], "x0", [], "y0", [], "vx", [], "vy", [], "colorId", []);
  state.resultMode = "";
  setappdata(fig, "state", state);
  set(ui.confettiLines, "xdata", NaN, "ydata", NaN);

  % show the new letters and reset the cell colours
  for row = 1:state.gridSize
    for col = 1:state.gridSize
      set(ui.cellTexts(row, col), "string", letterGrid(row, col));
      set(ui.cellRects(row, col), "facecolor", state.colors.cell);
    endfor
  endfor
  set(ui.levelBadge, "string", sprintf("Level %d: %s", state.level, state.levelNames{state.level}));
  set(ui.footer, "string", sprintf("Click and drag to select a word.   Highest Points: %d", state.highScore));
  set(ui.toast, "string", "");
  refresh_words(fig);
  refresh_stats(fig);
endfunction


% Builds a gridSize x gridSize letter grid and places the words in it.
%   letterGrid : char matrix, empty cells filled with random letters
%   placements : struct, placements.WORD = [row col] for each letter
%   allPlaced  : true only if EVERY word was placed (caller redraws otherwise)
% Directions: horizontal, vertical, diagonal (down-right). The player can
% still select a word backwards.
function [letterGrid, placements, allPlaced] = create_word_grid(words, gridSize)
  letterGrid = repmat(' ', gridSize, gridSize);
  placements = struct();
  allPlaced = true;
  directions = [0 1; 1 0; 1 1];       % [row step, column step]

  for wordIndex = 1:numel(words)
    word = words{wordIndex};
    wordLength = numel(word);
    placed = false;
    attempts = 0;

    while !placed && attempts < 100
      attempts++;
      direction = directions(randi(rows(directions)), :);
      startRow = randi(gridSize);
      startCol = randi(gridSize);

      endRow = startRow + direction(1) * (wordLength - 1);
      endCol = startCol + direction(2) * (wordLength - 1);
      if endRow > gridSize || endCol > gridSize
        continue;                      % the word would leave the grid
      endif

      rowCells = startRow + direction(1) * (0:wordLength-1);
      colCells = startCol + direction(2) * (0:wordLength-1);
      cellIndexes = sub2ind([gridSize gridSize], rowCells, colCells);
      currentLetters = letterGrid(cellIndexes);

      % each cell must be empty or already hold the same letter (crossing words)
      if all(currentLetters == ' ' | currentLetters == word)
        letterGrid(cellIndexes) = word;
        placements.(word) = [rowCells(:), colCells(:)];
        placed = true;
      endif
    endwhile

    if !placed
      allPlaced = false;               % a word did not fit: ask for a new set
      return;
    endif
  endfor

  % fill the remaining cells with random letters
  emptyCells = (letterGrid == ' ');
  letterGrid(emptyCells) = char('A' + randi(26, nnz(emptyCells), 1) - 1);
endfunction


% =====================================================================
%  MOUSE: DRAG TO SELECT A WORD
% =====================================================================

function on_mouse_down(fig)
  state = getappdata(fig, "state");
  if !strcmp(state.screen, "game") || !state.running, return; endif
  [isInside, row, col] = mouse_cell(fig);
  if !isInside, return; endif
  state.dragging = true;
  state.dragStart = [row col];
  setappdata(fig, "state", state);
  set_selection(fig, [row col]);
endfunction


function on_mouse_move(fig)
  state = getappdata(fig, "state");
  if !state.dragging, return; endif
  [isInside, row, col] = mouse_cell(fig);
  if !isInside, return; endif
  set_selection(fig, line_cells(state.dragStart, [row col]));
endfunction


function on_mouse_up(fig)
  state = getappdata(fig, "state");
  if !state.dragging, return; endif
  state.dragging = false;
  setappdata(fig, "state", state);
  check_selection(fig);
endfunction


% Grid cell under the mouse pointer
function [isInside, row, col] = mouse_cell(fig)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  pointer = get(ui.axes, "currentpoint");
  col = round(pointer(1,1));
  row = round(pointer(1,2));
  isInside = (row >= 1 && row <= state.gridSize && col >= 1 && col <= state.gridSize);
endfunction


% Cells on the straight line from startCell to endCell
% (horizontal, vertical or 45-degree diagonal; otherwise only startCell)
function cells = line_cells(startCell, endCell)
  offset = endCell - startCell;
  steps = max(abs(offset));
  if steps == 0
    cells = startCell;
  elseif offset(1) == 0 || offset(2) == 0 || abs(offset(1)) == abs(offset(2))
    cells = startCell + (0:steps)' * sign(offset);
  else
    cells = startCell;
  endif
endfunction


% Changes the selection and repaints only the cells concerned
function set_selection(fig, newSelection)
  state = getappdata(fig, "state");
  oldSelection = state.selection;
  state.selection = newSelection;
  setappdata(fig, "state", state);
  recolor(fig, [oldSelection; newSelection]);
endfunction


% Paints the given cells according to their state (hint, selected, found, normal)
function recolor(fig, cells)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  for cellIndex = 1:rows(cells)
    row = cells(cellIndex, 1);
    col = cells(cellIndex, 2);
    if !isempty(state.hintCell) && all(state.hintCell == [row col])
      cellColor = state.colors.hint;
    elseif any(state.selection(:,1) == row & state.selection(:,2) == col)
      cellColor = state.colors.selected;
    elseif state.foundMask(row, col)
      cellColor = state.colors.found;
    else
      cellColor = state.colors.cell;
    endif
    set(ui.cellRects(row, col), "facecolor", cellColor);
  endfor
endfunction


% Called when the mouse is released: is the selected line a word to find?
function check_selection(fig)
  state = getappdata(fig, "state");
  if !state.running || rows(state.selection) < 2
    set_selection(fig, zeros(0, 2));
    return;
  endif

  cellIndexes = sub2ind([state.gridSize state.gridSize], state.selection(:,1), state.selection(:,2));
  forwardWord = state.letterGrid(cellIndexes)';
  reverseWord = fliplr(forwardWord);

  foundWord = "";
  if any(strcmp(forwardWord, state.targetWords)) && !any(strcmp(forwardWord, state.foundWords))
    foundWord = forwardWord;
  elseif any(strcmp(reverseWord, state.targetWords)) && !any(strcmp(reverseWord, state.foundWords))
    foundWord = reverseWord;
  endif

  if !isempty(foundWord)
    foundCells = state.selection;
    state.foundWords{end+1} = foundWord;
    state.foundMask(cellIndexes) = true;
    state.points += 10;
    state.selection = zeros(0, 2);
    setappdata(fig, "state", state);
    start_confetti(fig, foundCells);
    recolor(fig, foundCells);
    refresh_words(fig);
    refresh_stats(fig);
    show_toast(fig, "Nice find! +10 Points");
    if numel(state.foundWords) == numel(state.targetWords)
      end_game(fig, true);
    endif
  else
    show_toast(fig, "Not a match");
    set_selection(fig, zeros(0, 2));
  endif
endfunction


% Ends the round and shows the victory / defeat screen
function end_game(fig, hasWon)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  if !state.running, return; endif

  state.running = false;
  state.dragging = false;
  state.secondsLeft = get_seconds_left(state);
  timeUsed = state.timeLimit - state.secondsLeft;
  if hasWon
    state.resultMode = "win";        % dancing mice
  else
    state.resultMode = "lose";       % dead mice
  endif
  state.resultStart = now() * 86400;

  if hasWon && state.points > state.highScore
    state.highScore = state.points;
    save_high_score(state.highScore);
  endif
  setappdata(fig, "state", state);
  set(ui.footer, "string", sprintf("Click and drag to select a word.   Highest Points: %d", state.highScore));
  refresh_stats(fig);

  % fill the results screen
  if hasWon
    set(ui.resultTitle, "string", [state.username ", you won!"], "foregroundcolor", state.colors.primary);
    set(ui.resultMessage, "string", sprintf("You found all %d words in %s.", ...
        numel(state.targetWords), format_time(timeUsed)));
  else
    set(ui.resultTitle, "string", [state.username ", you lost!"], "foregroundcolor", state.colors.danger);
    set(ui.resultMessage, "string", sprintf("Time's up! You found %d of %d words.", ...
        numel(state.foundWords), numel(state.targetWords)));
  endif
  set(ui.resultStats, "string", sprintf("Words: %d/%d      Time used: %s      Points: %d      Level: %s", ...
      numel(state.foundWords), numel(state.targetWords), format_time(timeUsed), ...
      state.points, state.levelNames{state.level}));

  % short wait so the last found word stays visible, then show the results
  drawnow();
  pause(0.6);
  stateAfterWait = getappdata(fig, "state");
  if strcmp(stateAfterWait.screen, "game") && !stateAfterWait.running
    show_screen(fig, "results");
  endif
endfunction


% Hint button: costs 5 points, highlights the first letter of the longest word left
function on_hint(fig)
  state = getappdata(fig, "state");
  if !state.running, return; endif
  if state.points < 5
    show_toast(fig, "Needs 5 points. Find more words first!");
    return;
  endif

  notFound = state.targetWords(!ismember(state.targetWords, state.foundWords));
  if isempty(notFound), return; endif

  state.points -= 5;
  [~, longestIndex] = max(cellfun(@numel, notFound));
  hintWord = notFound{longestIndex};
  wordCells = state.placements.(hintWord);

  previousHintCell = state.hintCell;
  state.hintCell = wordCells(1, :);
  state.hintWord = hintWord;
  state.hintUntil = now() * 86400 + 4;        % highlight lasts 4 seconds
  setappdata(fig, "state", state);

  if !isempty(previousHintCell), recolor(fig, previousHintCell); endif
  recolor(fig, state.hintCell);
  refresh_words(fig);
  refresh_stats(fig);
  show_toast(fig, sprintf("Hint: yellow letter starts %s", hintWord));
endfunction


% =====================================================================
%  SCREEN REFRESH HELPERS
% =====================================================================

% Word list on the left: found words in green, hinted word in yellow
function refresh_words(fig)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  for labelIndex = 1:numel(ui.wordLabels)
    if labelIndex > numel(state.targetWords)
      set(ui.wordLabels(labelIndex), "string", "", "backgroundcolor", get(fig, "color"));
      continue;
    endif
    word = state.targetWords{labelIndex};
    if any(strcmp(word, state.foundWords))
      set(ui.wordLabels(labelIndex), "string", ["  " word "   [found]"], ...
          "backgroundcolor", state.colors.found, "foregroundcolor", state.colors.primary);
    elseif strcmp(word, state.hintWord) && now()*86400 < state.hintUntil
      set(ui.wordLabels(labelIndex), "string", ["  " word], ...
          "backgroundcolor", state.colors.hint, "foregroundcolor", state.colors.text);
    else
      set(ui.wordLabels(labelIndex), "string", ["  " word], ...
          "backgroundcolor", state.colors.listBackground, "foregroundcolor", state.colors.text);
    endif
  endfor
endfunction


% Words / Time left / Points, and the Hint button state
function refresh_stats(fig)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  set(ui.statWords, "string", sprintf("%d/%d", numel(state.foundWords), numel(state.targetWords)));
  set(ui.statPoints, "string", sprintf("%d", state.points));
  set(ui.statTime, "string", format_time(state.secondsLeft));
  if state.running && state.secondsLeft <= 10
    set(ui.statTime, "foregroundcolor", state.colors.danger);   % last 10 seconds
  else
    set(ui.statTime, "foregroundcolor", state.colors.primary);
  endif
  if state.running && state.points >= 5 && numel(state.foundWords) < numel(state.targetWords)
    set(ui.hintButton, "enable", "on");
  else
    set(ui.hintButton, "enable", "off");
  endif
endfunction


% Short message at the bottom left, cleared by tick() after 1.5 seconds
function show_toast(fig, message)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  state.toastUntil = now() * 86400 + 1.5;
  setappdata(fig, "state", state);
  set(ui.toast, "string", message);
endfunction


% Called every 0.1 s by the main loop
function tick(fig)
  update_confetti(fig);              % animations use their own copy of the state
  update_result_mice(fig);
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  nowSeconds = now() * 86400;

  % while paused: only update the pause time
  if state.paused
    set(ui.pauseTime, "string", ["Pause time: " format_time(floor(toc(state.pauseTimer)))]);
    return;
  endif

  % countdown: when it reaches zero the player loses
  if state.running
    secondsLeft = get_seconds_left(state);
    if secondsLeft != state.secondsLeft
      state.secondsLeft = secondsLeft;
      setappdata(fig, "state", state);
      refresh_stats(fig);
    endif
    if secondsLeft <= 0
      end_game(fig, false);
      return;
    endif
  endif

  % clear the message after its delay
  if state.toastUntil > 0 && nowSeconds > state.toastUntil
    set(ui.toast, "string", "");
    state.toastUntil = 0;
    setappdata(fig, "state", state);
  endif

  % remove the hint highlight after its delay
  if !isempty(state.hintCell) && nowSeconds > state.hintUntil
    oldHintCell = state.hintCell;
    state.hintCell = [];
    state.hintWord = "";
    setappdata(fig, "state", state);
    recolor(fig, oldHintCell);
    refresh_words(fig);
  endif
endfunction


% =====================================================================
%  CONFETTI AND MICE (drawn by the code, no image file)
% =====================================================================

% Adds a burst of confetti starting from the middle of the found word
function start_confetti(fig, cells)
  state = getappdata(fig, "state");
  origin = mean(cells, 1);                          % [row col] of the word centre
  pieces = 70;
  angle = pi * (0.15 + 0.7 * rand(pieces, 1));      % thrown upwards, in a fan
  speed = 4 + 8 * rand(pieces, 1);                  % cells per second
  confetti = state.confetti;
  confetti.t0 = [confetti.t0; repmat(now() * 86400, pieces, 1)];
  confetti.x0 = [confetti.x0; repmat(origin(2), pieces, 1)];
  confetti.y0 = [confetti.y0; repmat(origin(1), pieces, 1)];
  confetti.vx = [confetti.vx; 1.3 * speed .* cos(angle)];
  confetti.vy = [confetti.vy; -speed .* sin(angle)];   % y axis points down
  confetti.colorId = [confetti.colorId; randi(6, pieces, 1)];
  state.confetti = confetti;
  setappdata(fig, "state", state);
endfunction


% Moves the confetti (throw + gravity) and removes the pieces after 1.6 s
function update_confetti(fig)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  confetti = state.confetti;
  if isempty(confetti.t0), return; endif

  age = now() * 86400 - confetti.t0;                % seconds since each piece was thrown
  alive = age < 1.6;
  xPosition = confetti.x0 + confetti.vx .* age;
  yPosition = confetti.y0 + confetti.vy .* age + 9 * age.^2;   % gravity
  for colorIndex = 1:numel(ui.confettiLines)
    selected = alive & confetti.colorId == colorIndex;
    if any(selected)
      set(ui.confettiLines(colorIndex), "xdata", xPosition(selected)', "ydata", yPosition(selected)');
    else
      set(ui.confettiLines(colorIndex), "xdata", NaN, "ydata", NaN);
    endif
  endfor

  if !all(alive)                                    % forget the finished pieces
    fieldNames = fieldnames(confetti);
    for fieldIndex = 1:numel(fieldNames)
      confetti.(fieldNames{fieldIndex}) = confetti.(fieldNames{fieldIndex})(alive);
    endfor
    state.confetti = confetti;
    setappdata(fig, "state", state);
  endif
endfunction


% Redraws the mice while the results screen is visible
function update_result_mice(fig)
  state = getappdata(fig, "state");
  if strcmp(state.screen, "results") && !isempty(state.resultMode)
    draw_mice(fig);
  endif
endfunction


% Draws three mice on the results stage: dancing (win) or dead (lose).
% The graphic objects are created once, then only their coordinates change.
function draw_mice(fig)
  state = getappdata(fig, "state");
  ui = getappdata(fig, "ui");
  isDead = strcmp(state.resultMode, "lose");
  if isDead && !isempty(state.mouseHandles), return; endif   % dead mice do not move

  phase = (now() * 86400 - state.resultStart) * 7;           % dance speed
  mouseX = [0.95 2.25 3.55];
  extraTilts = [0.12 -0.08 0.20];                            % dead mice lie differently
  shapes = struct("kind", {}, "x", {}, "y", {}, "color", {}, "edge", {}, "fixed", {});
  for mouseIndex = 1:3
    shapes = [shapes, mouse_shapes(mouseX(mouseIndex), 0.12, 0.78, ...
                                   phase + (mouseIndex - 1) * 1.3, isDead, extraTilts(mouseIndex))];
  endfor

  if numel(state.mouseHandles) != numel(shapes)
    % first drawing: create the objects
    newHandles = zeros(1, numel(shapes));
    for shapeIndex = 1:numel(shapes)
      shape = shapes(shapeIndex);
      if strcmp(shape.kind, "patch")
        newHandles(shapeIndex) = patch("parent", ui.resultAxes, "xdata", shape.x, "ydata", shape.y, ...
                                       "facecolor", shape.color, "edgecolor", shape.edge, ...
                                       "linewidth", 1, "hittest", "off");
      else
        newHandles(shapeIndex) = line("parent", ui.resultAxes, "xdata", shape.x, "ydata", shape.y, ...
                                      "color", shape.color, "linewidth", shape.edge, "hittest", "off");
      endif
    endfor
    state.mouseHandles = newHandles;
    setappdata(fig, "state", state);
  else
    % next frames: only move the objects
    for shapeIndex = 1:numel(shapes)
      set(state.mouseHandles(shapeIndex), "xdata", shapes(shapeIndex).x, "ydata", shapes(shapeIndex).y);
    endfor
  endif
endfunction


% Geometry of one cartoon mouse (blond fur) as a list of shapes in world coordinates.
% Drawn in a local frame (feet at y = 0, head at y = 1.2), then tilted,
% scaled and moved to (baseX, baseY). A dead mouse is turned upside down,
% with crossed eyes and the tongue out.
function shapes = mouse_shapes(baseX, baseY, scale, phase, isDead, extraTilt)
  if isDead
    fur = [0.78 0.74 0.62];  furDark = [0.55 0.50 0.40];  belly = [0.90 0.88 0.80];
    tilt = pi + extraTilt;  pivot = [0 0.6];  lift = 0.40;  bounce = 0;
    leftLift = 0;  rightLift = 0;
  else
    fur = [0.93 0.80 0.45];  furDark = [0.78 0.62 0.25];  belly = [0.99 0.93 0.75];
    tilt = 0.16 * sin(phase);  pivot = [0 0.1];  lift = 0;  bounce = 0.10 * abs(sin(phase));
    leftLift = 0.16 * max(0, sin(phase));  rightLift = 0.16 * max(0, -sin(phase));
  endif
  pink = [0.95 0.60 0.65];  dark = [0.15 0.12 0.10];  shadowColor = [0.78 0.82 0.90];
  whiskerColor = [0.35 0.30 0.25];
  shapes = struct("kind", {}, "x", {}, "y", {}, "color", {}, "edge", {}, "fixed", {});

  % shadow on the ground (does not move with the mouse)
  [x, y] = ellipse_xy(0, 0, 0.55, 0.07);
  shapes(end+1) = make_shape("patch", x, y, shadowColor, shadowColor, true);

  % tail: swings when dancing, droops when dead
  tailT = linspace(0, 1, 14)';
  if isDead
    tailY = 0.22 + 0.35 * tailT.^2;
  else
    tailY = 0.22 + 0.14 * sin(7 * tailT - 2 * phase) .* tailT + 0.05 * tailT;
  endif
  shapes(end+1) = make_shape("line", 0.30 + 0.55 * tailT, tailY, pink, 2.5, false);

  % legs and feet (they lift alternately when dancing)
  for side = [-1 1]
    if side == -1, legLift = leftLift; else, legLift = rightLift; endif
    if isDead
      footX = side * 0.24;  footY = -0.06;
    else
      footX = side * 0.20;  footY = 0.02 + legLift;
    endif
    shapes(end+1) = make_shape("line", [side * 0.17; footX], [0.14; footY], furDark, 5, false);
    [x, y] = ellipse_xy(footX, footY, 0.12, 0.055);
    shapes(end+1) = make_shape("patch", x, y, fur, furDark, false);
  endfor

  % body and belly
  [x, y] = ellipse_xy(0, 0.56, 0.36, 0.46);
  shapes(end+1) = make_shape("patch", x, y, fur, furDark, false);
  [x, y] = ellipse_xy(0, 0.52, 0.22, 0.32);
  shapes(end+1) = make_shape("patch", x, y, belly, belly * 0.85, false);

  % arms and hands (they wave alternately when dancing)
  for side = [-1 1]
    if isDead
      handX = side * 0.50;  handY = 0.46;
    else
      if side == -1, armPhase = phase; else, armPhase = phase + pi; endif
      handX = side * 0.64;  handY = 0.80 + 0.38 * sin(armPhase);
    endif
    shapes(end+1) = make_shape("line", [side * 0.31; handX], [0.80; handY], furDark, 5, false);
    [x, y] = ellipse_xy(handX, handY, 0.085, 0.085);
    shapes(end+1) = make_shape("patch", x, y, fur, furDark, false);
  endfor

  % ears (outer and inner part) and head
  for side = [-1 1]
    [x, y] = ellipse_xy(side * 0.29, 1.50, 0.19, 0.19);
    shapes(end+1) = make_shape("patch", x, y, fur, furDark, false);
    [x, y] = ellipse_xy(side * 0.29, 1.50, 0.11, 0.11);
    shapes(end+1) = make_shape("patch", x, y, pink, pink * 0.8, false);
  endfor
  [x, y] = ellipse_xy(0, 1.20, 0.36, 0.34);
  shapes(end+1) = make_shape("patch", x, y, fur, furDark, false);

  % eyes: round when dancing, crosses when dead
  for side = [-1 1]
    eyeX = side * 0.14;
    if isDead
      shapes(end+1) = make_shape("line", [eyeX - 0.07; eyeX + 0.07], [1.33; 1.19], dark, 2, false);
      shapes(end+1) = make_shape("line", [eyeX - 0.07; eyeX + 0.07], [1.19; 1.33], dark, 2, false);
    else
      [x, y] = ellipse_xy(eyeX, 1.26, 0.055, 0.075);
      shapes(end+1) = make_shape("patch", x, y, dark, dark, false);
    endif
  endfor

  % nose, mouth (smile or flat line with the tongue out) and whiskers
  [x, y] = ellipse_xy(0, 1.10, 0.055, 0.04);
  shapes(end+1) = make_shape("patch", x, y, pink, pink * 0.8, false);
  if isDead
    shapes(end+1) = make_shape("line", [-0.12; 0.12], [1.00; 1.00], dark, 1.5, false);
    [x, y] = ellipse_xy(0.04, 0.93, 0.055, 0.10);
    shapes(end+1) = make_shape("patch", x, y, [0.95 0.45 0.50], [0.75 0.30 0.35], false);
  else
    mouthX = linspace(-0.12, 0.12, 9)';
    shapes(end+1) = make_shape("line", mouthX, 1.00 - 0.06 * (1 - (mouthX / 0.12).^2), dark, 1.5, false);
  endif
  for side = [-1 1]
    shapes(end+1) = make_shape("line", [side * 0.10; side * 0.46], [1.08; 1.13], whiskerColor, 1, false);
    shapes(end+1) = make_shape("line", [side * 0.10; side * 0.46], [1.05; 1.02], whiskerColor, 1, false);
  endfor

  % tilt / bounce (not for the shadow), scale and move to the base position
  for shapeIndex = 1:numel(shapes)
    x = shapes(shapeIndex).x;
    y = shapes(shapeIndex).y;
    if shapes(shapeIndex).fixed
      shapes(shapeIndex).x = baseX + scale * x;
      shapes(shapeIndex).y = baseY + scale * y;
    else
      dx = x - pivot(1);
      dy = y - pivot(2);
      rotatedX = pivot(1) + dx * cos(tilt) - dy * sin(tilt);
      rotatedY = pivot(2) + dx * sin(tilt) + dy * cos(tilt);
      shapes(shapeIndex).x = baseX + scale * rotatedX;
      shapes(shapeIndex).y = baseY + scale * (rotatedY + bounce + lift);
    endif
  endfor
endfunction


% One drawing element. For a "patch" edgeOrWidth is the outline colour,
% for a "line" it is the line width.
function shape = make_shape(kind, x, y, color, edgeOrWidth, fixed)
  shape = struct("kind", kind, "x", x(:), "y", y(:), "color", color, ...
                 "edge", edgeOrWidth, "fixed", fixed);
endfunction


% Points of an ellipse (centre cx, cy and radii rx, ry)
function [x, y] = ellipse_xy(cx, cy, rx, ry)
  angles = linspace(0, 2 * pi, 22)';
  x = cx + rx * cos(angles);
  y = cy + ry * sin(angles);
endfunction


% 75 seconds -> "01:15"
function timeText = format_time(totalSeconds)
  timeText = sprintf("%02d:%02d", floor(totalSeconds / 60), mod(totalSeconds, 60));
endfunction


% =====================================================================
%  HIGH SCORE (plain text file in the home folder)
% =====================================================================

function filePath = high_score_file()
  homeFolder = getenv("HOME");
  if isempty(homeFolder), homeFolder = getenv("USERPROFILE"); endif
  if isempty(homeFolder), homeFolder = tempdir(); endif
  filePath = fullfile(homeFolder, ".neuro_word_hunt_highscore");
endfunction


function bestScore = load_high_score()
  bestScore = 0;
  filePath = high_score_file();
  if exist(filePath, "file")
    fileId = fopen(filePath, "r");
    storedValue = fscanf(fileId, "%d", 1);
    fclose(fileId);
    if !isempty(storedValue), bestScore = storedValue; endif
  endif
endfunction


function save_high_score(bestScore)
  fileId = fopen(high_score_file(), "w");
  if fileId > 0
    fprintf(fileId, "%d\n", bestScore);
    fclose(fileId);
  endif
endfunction
