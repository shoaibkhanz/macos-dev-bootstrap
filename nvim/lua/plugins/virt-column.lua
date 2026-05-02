return {
  'lukas-reineke/virt-column.nvim',
  event = 'BufReadPre',
  opts = {
    char = '▏',
    virtcolumn = '+1',
    highlight = 'NonText',
  },
}
