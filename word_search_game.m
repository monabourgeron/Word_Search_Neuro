function word_search_game()
  % WORD_SEARCH_GAME  Tech Word Hunt, GNU Octave port.
  %
  % Usage:  >> word_search_game
  % Click and drag on the grid to select a word (horizontal, vertical, diagonal,
  % forwards or backwards). +10 points per word, a hint costs 5 points.
  % Needs ws_create_grid.m in the same folder. Works best with the qt graphics toolkit.

  S.pool = {"JAVASCRIPT","PYTHON","REACT","ANGULAR","VUE","NODEJS","TYPESCRIPT", ...
            "GRAPHQL","DOCKER","KUBERNETES","DEVOPS","SERVERLESS","ALGORITHM", ...
            "DATABASE","FRONTEND","BACKEND","API","RUST","GO","SWIFT"};
  S.N = 12;
  S.nWords = 8;
  S.highScore = load_high_score();

  % colours
  S.col.cell     = [0.996 0.976 0.910];
  S.col.selected = [0.812 0.914 0.875];
  S.col.found    = [0.831 0.902 0.851];
  S.col.hint     = [1.000 0.922 0.231];
  S.col.primary  = [0.427 0.596 0.525];
  S.col.listbg   = [0.973 0.976 0.980];

  fig = figure("name", "Tech Word Hunt", "numbertitle", "off", "menubar", "none", ...
               "color", [0.88 0.91 0.96], "position", [100 100 1000 620]);
  H.fig = fig;

  % ---------- left panel ----------
  uicontrol("style", "text", "units", "normalized", "position", [0.03 0.90 0.25 0.07], ...
            "string", "Word Search", "fontsize", 16, "fontweight", "bold", ...
            "foregroundcolor", S.col.primary, "backgroundcolor", get(fig, "color"), ...
            "horizontalalignment", "left");
  H.hintBtn  = uicontrol("style", "pushbutton", "units", "normalized", ...
            "position", [0.03 0.82 0.11 0.06], "string", "Hint (5 pts)", ...
            "callback", @(h, e) on_hint(fig));
  uicontrol("style", "pushbutton", "units", "normalized", ...
            "position", [0.15 0.82 0.11 0.06], "string", "Reset Selection", ...
            "callback", @(h, e) on_reset(fig));
  uicontrol("style", "pushbutton", "units", "normalized", ...
            "position", [0.27 0.82 0.10 0.06], "string", "New Game", ...
            "callback", @(h, e) new_game(fig));

  H.stats = uicontrol("style", "text", "units", "normalized", ...
            "position", [0.03 0.72 0.34 0.07], "fontsize", 11, "fontweight", "bold", ...
            "backgroundcolor", [0.851 0.894 0.867]);

  uicontrol("style", "text", "units", "normalized", "position", [0.03 0.66 0.34 0.04], ...
            "string", "Words to Find", "fontsize", 12, "fontweight", "bold", ...
            "backgroundcolor", get(fig, "color"), "horizontalalignment", "left");

  H.lbl = zeros(1, S.nWords);
  for i = 1:S.nWords
    H.lbl(i) = uicontrol("style", "text", "units", "normalized", ...
              "position", [0.03, 0.605 - (i-1)*0.065, 0.34, 0.052], ...
              "fontsize", 11, "fontweight", "bold", "horizontalalignment", "left", ...
              "backgroundcolor", S.col.listbg);
  endfor

  H.toast = uicontrol("style", "text", "units", "normalized", ...
            "position", [0.03 0.06 0.34 0.05], "fontsize", 10, ...
            "backgroundcolor", get(fig, "color"), "foregroundcolor", [0.2 0.2 0.2]);
  H.footer = uicontrol("style", "text", "units", "normalized", ...
            "position", [0.40 0.01 0.58 0.04], "fontsize", 9, ...
            "backgroundcolor", get(fig, "color"), "foregroundcolor", [0.4 0.4 0.4]);

  % ---------- grid ----------
  H.ax = axes("parent", fig, "position", [0.40 0.07 0.58 0.90]);
  hold(H.ax, "on");
  axis(H.ax, "equal");
  bg = get(fig, "color");
  set(H.ax, "ydir", "reverse", "xlim", [0.5 S.N+0.5], "ylim", [0.5 S.N+0.5], ...
            "xtick", [], "ytick", [], "box", "off", "color", bg, ...
            "xcolor", bg, "ycolor", bg, "clipping", "off");
  H.rect = zeros(S.N);
  H.txt  = zeros(S.N);
  for r = 1:S.N
    for c = 1:S.N
      H.rect(r,c) = rectangle("parent", H.ax, "position", [c-0.46 r-0.46 0.92 0.92], ...
                              "curvature", [0.2 0.2], "facecolor", S.col.cell, ...
                              "edgecolor", [0.92 0.92 0.92], "hittest", "off");
      H.txt(r,c)  = text(c, r, " ", "parent", H.ax, "horizontalalignment", "center", ...
                         "verticalalignment", "middle", "fontsize", 14, ...
                         "fontweight", "bold", "hittest", "off");
    endfor
  endfor

  set(fig, "windowbuttondownfcn",   @(h, e) on_down(fig));
  set(fig, "windowbuttonmotionfcn", @(h, e) on_move(fig));
  set(fig, "windowbuttonupfcn",     @(h, e) on_up(fig));

  setappdata(fig, "S", S);
  setappdata(fig, "H", H);
  new_game(fig);
  drawnow();

  % Main loop: drives the timer display and clears toasts / hints.
  while ishghandle(fig)
    pause(0.1);
    if !ishghandle(fig), break; endif
    tick(fig);
  endwhile
endfunction


% =====================================================================
%  Game logic
% =====================================================================

function new_game(fig)
  S = getappdata(fig, "S");
  H = getappdata(fig, "H");

  idx = randperm(numel(S.pool));
  words = S.pool(idx(1:S.nWords));
  [grid, pl] = ws_create_grid(words, S.N);
  words = words(ismember(words, fieldnames(pl)'));   % keep only words that were placed

  S.grid = grid;
  S.pl = pl;
  S.words = words;
  S.found = {};
  S.points = 0;
  S.sel = zeros(0, 2);
  S.dragging = false;
  S.start = [];
  S.foundMask = false(S.N);
  S.t0 = tic;
  S.elapsed = 0;
  S.running = true;
  S.hintCell = [];
  S.hintWord = "";
  S.hintUntil = 0;
  S.toastUntil = 0;
  setappdata(fig, "S", S);

  for r = 1:S.N
    for c = 1:S.N
      set(H.txt(r,c), "string", grid(r,c));
      set(H.rect(r,c), "facecolor", S.col.cell);
    endfor
  endfor
  set(H.footer, "string", sprintf("Click and drag to select a word.   Highest Points: %d", S.highScore));
  set(H.toast, "string", "");
  refresh_words(fig);
  refresh_stats(fig);
endfunction


function on_down(fig)
  S = getappdata(fig, "S");
  [ok, r, c] = mouse_cell(fig);
  if !ok || !S.running, return; endif
  S.dragging = true;
  S.start = [r c];
  setappdata(fig, "S", S);
  set_selection(fig, [r c]);
endfunction


function on_move(fig)
  S = getappdata(fig, "S");
  if !S.dragging, return; endif
  [ok, r, c] = mouse_cell(fig);
  if !ok, return; endif
  set_selection(fig, line_cells(S.start, [r c]));
endfunction


function on_up(fig)
  S = getappdata(fig, "S");
  if !S.dragging, return; endif
  S.dragging = false;
  setappdata(fig, "S", S);
  check_selection(fig);
endfunction


function on_reset(fig)
  set_selection(fig, zeros(0, 2));
endfunction


function [ok, r, c] = mouse_cell(fig)
  S = getappdata(fig, "S");
  H = getappdata(fig, "H");
  cp = get(H.ax, "currentpoint");
  c = round(cp(1,1));
  r = round(cp(1,2));
  ok = (r >= 1 && r <= S.N && c >= 1 && c <= S.N);
endfunction


function cells = line_cells(a, b)
  % Cells on the straight line from a to b (horizontal / vertical / 45-degree diagonal).
  d = b - a;
  steps = max(abs(d));
  if steps == 0
    cells = a;
  elseif d(1) == 0 || d(2) == 0 || abs(d(1)) == abs(d(2))
    cells = a + (0:steps)' * sign(d);
  else
    cells = a;
  endif
endfunction


function set_selection(fig, newSel)
  S = getappdata(fig, "S");
  old = S.sel;
  S.sel = newSel;
  setappdata(fig, "S", S);
  recolor(fig, [old; newSel]);
endfunction


function recolor(fig, cells)
  S = getappdata(fig, "S");
  H = getappdata(fig, "H");
  for k = 1:rows(cells)
    r = cells(k,1);
    c = cells(k,2);
    if !isempty(S.hintCell) && all(S.hintCell == [r c])
      col = S.col.hint;
    elseif any(S.sel(:,1) == r & S.sel(:,2) == c)
      col = S.col.selected;
    elseif S.foundMask(r,c)
      col = S.col.found;
    else
      col = S.col.cell;
    endif
    set(H.rect(r,c), "facecolor", col);
  endfor
endfunction


function check_selection(fig)
  S = getappdata(fig, "S");
  if rows(S.sel) < 2
    set_selection(fig, zeros(0, 2));
    return;
  endif

  idx = sub2ind([S.N S.N], S.sel(:,1), S.sel(:,2));
  w  = S.grid(idx)';
  wr = fliplr(w);

  match = "";
  if any(strcmp(w, S.words)) && !any(strcmp(w, S.found))
    match = w;
  elseif any(strcmp(wr, S.words)) && !any(strcmp(wr, S.found))
    match = wr;
  endif

  if !isempty(match)
    cells = S.sel;
    S.found{end+1} = match;
    S.foundMask(idx) = true;
    S.points += 10;
    S.sel = zeros(0, 2);
    setappdata(fig, "S", S);
    recolor(fig, cells);
    refresh_words(fig);
    refresh_stats(fig);
    show_toast(fig, "Nice find! +10 Points");
    check_win(fig);
  else
    show_toast(fig, "Not a match");
    set_selection(fig, zeros(0, 2));
  endif
endfunction


function check_win(fig)
  S = getappdata(fig, "S");
  H = getappdata(fig, "H");
  if numel(S.found) < numel(S.words), return; endif

  S.running = false;
  S.elapsed = floor(toc(S.t0));
  if S.points > S.highScore
    S.highScore = S.points;
    save_high_score(S.highScore);
  endif
  setappdata(fig, "S", S);
  set(H.footer, "string", sprintf("Click and drag to select a word.   Highest Points: %d", S.highScore));
  refresh_stats(fig);
  msgbox(sprintf("You mastered Tech Word Hunt!\n\nFinal Points: %d\nTime: %s", ...
                 S.points, format_time(S.elapsed)), "Congratulations");
endfunction


function on_hint(fig)
  S = getappdata(fig, "S");
  H = getappdata(fig, "H");
  if !S.running, return; endif
  if S.points < 5
    show_toast(fig, "Needs 5 points. Find more words first!");
    return;
  endif

  unfound = S.words(!ismember(S.words, S.found));
  if isempty(unfound), return; endif

  S.points -= 5;
  [~, i] = max(cellfun(@numel, unfound));     % longest remaining word
  word = unfound{i};
  pos = S.pl.(word);

  old = S.hintCell;
  S.hintCell = pos(1,:);
  S.hintWord = word;
  S.hintUntil = now() * 86400 + 4;
  setappdata(fig, "S", S);

  if !isempty(old), recolor(fig, old); endif
  recolor(fig, S.hintCell);
  refresh_words(fig);
  refresh_stats(fig);
  show_toast(fig, sprintf("Hint: look for the highlighted start of \"%s\"", word));
endfunction


% =====================================================================
%  UI refresh helpers
% =====================================================================

function refresh_words(fig)
  S = getappdata(fig, "S");
  H = getappdata(fig, "H");
  for i = 1:numel(H.lbl)
    if i > numel(S.words)
      set(H.lbl(i), "string", "", "backgroundcolor", get(fig, "color"));
      continue;
    endif
    w = S.words{i};
    if any(strcmp(w, S.found))
      set(H.lbl(i), "string", ["  " w "   [found]"], ...
          "backgroundcolor", S.col.found, "foregroundcolor", S.col.primary);
    elseif strcmp(w, S.hintWord) && now()*86400 < S.hintUntil
      set(H.lbl(i), "string", ["  " w], "backgroundcolor", S.col.hint, ...
          "foregroundcolor", [0.2 0.2 0.2]);
    else
      set(H.lbl(i), "string", ["  " w], "backgroundcolor", S.col.listbg, ...
          "foregroundcolor", [0.2 0.2 0.2]);
    endif
  endfor
endfunction


function refresh_stats(fig)
  S = getappdata(fig, "S");
  H = getappdata(fig, "H");
  set(H.stats, "string", sprintf("Words %d/%d      Timer %s      Points %d", ...
      numel(S.found), numel(S.words), format_time(S.elapsed), S.points));
  if S.points >= 5 && S.running
    set(H.hintBtn, "enable", "on");
  else
    set(H.hintBtn, "enable", "off");
  endif
endfunction


function show_toast(fig, msg)
  S = getappdata(fig, "S");
  H = getappdata(fig, "H");
  S.toastUntil = now() * 86400 + 1.5;
  setappdata(fig, "S", S);
  set(H.toast, "string", msg);
endfunction


function tick(fig)
  S = getappdata(fig, "S");
  H = getappdata(fig, "H");
  t = now() * 86400;

  if S.running
    e = floor(toc(S.t0));
    if e != S.elapsed
      S.elapsed = e;
      setappdata(fig, "S", S);
      refresh_stats(fig);
    endif
  endif

  if S.toastUntil > 0 && t > S.toastUntil
    set(H.toast, "string", "");
    S.toastUntil = 0;
    setappdata(fig, "S", S);
  endif

  if !isempty(S.hintCell) && t > S.hintUntil
    old = S.hintCell;
    S.hintCell = [];
    S.hintWord = "";
    setappdata(fig, "S", S);
    recolor(fig, old);
    refresh_words(fig);
  endif
endfunction


function s = format_time(totalSeconds)
  s = sprintf("%02d:%02d", floor(totalSeconds / 60), mod(totalSeconds, 60));
endfunction


% =====================================================================
%  High score persistence (plain text file in the home folder)
% =====================================================================

function f = high_score_file()
  home = getenv("HOME");
  if isempty(home), home = getenv("USERPROFILE"); endif
  if isempty(home), home = tempdir(); endif
  f = fullfile(home, ".tech_word_hunt_highscore");
endfunction


function v = load_high_score()
  v = 0;
  f = high_score_file();
  if exist(f, "file")
    fid = fopen(f, "r");
    x = fscanf(fid, "%d", 1);
    fclose(fid);
    if !isempty(x), v = x; endif
  endif
endfunction


function save_high_score(v)
  fid = fopen(high_score_file(), "w");
  if fid > 0
    fprintf(fid, "%d\n", v);
    fclose(fid);
  endif
endfunction
