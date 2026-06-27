require('notes').setup({
  -- Local directory where notes are stored (also the git worktree root).
  dir = vim.fn.expand('~/.notes'),

  -- SSH remote for GitHub sync.
  -- Leave empty ('') to use notes locally without any git sync.
  repo = 'git@github.com:lgick/my_notes.git',

  -- Height of the folders/notes row in rows (content rows, excluding statusline).
  list_height = 10,

  -- Width of the folders column.
  folders_width = 25,

  -- Keymaps (override individually; unset keys keep their defaults).
  keys = {
    open_file = '<CR>', -- folders: focus the notes column; notes: focus the editor
    create = 'a', -- folders: create a folder; notes: create a note
    delete = 'd', -- folders: delete the folder; notes: delete the note (confirmation)
    rename = 'r', -- folders: rename the selected folder
    move = 'x', -- notes: mark note for moving
    paste = 'p', -- folders: drop the marked note into the selected folder
    refresh = 'R', -- refresh the list
    open_github = 'O', -- open the notes repository in the browser
    scroll_down = '<C-n>', -- notes: scroll the open note down
    scroll_up = '<C-p>', -- notes: scroll the open note up
    close = 'q', -- close notes (works from any notes window)
    window_nav = '<C-w>', -- prefix; then h/j/k/l → move between windows
  },
})
