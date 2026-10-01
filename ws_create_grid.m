function [grid, placements] = ws_create_grid(words, gridSize)
  % WS_CREATE_GRID  Place words in a gridSize x gridSize letter grid.
  %   words      : cell array of upper-case words
  %   gridSize   : scalar, grid is gridSize x gridSize
  %   grid       : char matrix (filled with random letters where empty)
  %   placements : struct, placements.WORD = [row col] (one row per letter)
  %
  % Directions (same as the JS version): horizontal, vertical, diagonal (down-right).
  % Words are read forward in the grid, but the player may also select them backwards.

  grid = repmat(' ', gridSize, gridSize);
  placements = struct();
  dirs = [0 1; 1 0; 1 1];

  for k = 1:numel(words)
    w = words{k};
    L = numel(w);
    placed = false;
    attempts = 0;

    while !placed && attempts < 200
      attempts++;
      d = dirs(randi(rows(dirs)), :);
      r = randi(gridSize);
      c = randi(gridSize);

      endR = r + d(1) * (L - 1);
      endC = c + d(2) * (L - 1);
      if endR > gridSize || endC > gridSize
        continue;
      endif

      rr = r + d(1) * (0:L-1);
      cc = c + d(2) * (0:L-1);
      idx = sub2ind([gridSize gridSize], rr, cc);
      cur = grid(idx);

      % cell must be empty or already contain the same letter (crossing words)
      if all(cur == ' ' | cur == w)
        grid(idx) = w;
        placements.(w) = [rr(:), cc(:)];
        placed = true;
      endif
    endwhile
  endfor

  % fill the remaining cells with random letters
  mask = (grid == ' ');
  grid(mask) = char('A' + randi(26, nnz(mask), 1) - 1);
endfunction
