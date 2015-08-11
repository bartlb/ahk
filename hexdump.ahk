hexdump(fileName, options="") {
  offset    := 0
  isVerbose := false
  canonical := true
  useLength := false
  
  for each, switch in StrSplit(options, "-")
  {
    switch := StrSplit(switch, " ")
    gosub % (IsLabel(switch[1]) ? switch[1] : "default")
    continue
    
    C:
      return
    s:
      offset := switch[2]
      return
    n:
      useLength := switch[2]
      return
    v:
      isVerbose := true
      return
    default:
      invalidSwitch := true
      return
  }
  
  bin_file  := FileOpen(fileName, 0)
  bin_file.Seek(offset)
  
  printf(bin_file.Tell())
  
  bin_out   := Format("{:08x}  ", bin_file.Tell())
  
  while (! bin_file.AtEOF && (! useLength || (bin_file.Tell() - offset) <= useLength))
  {
    ; The following I/O of the `bin_out` variable does not account for use-cases where
    ; the canonical `C` switch isn't utilized.
    bin_out .= Format("{1:02x}{2}", bin_file.ReadUChar()
                                  , (Mod(A_Index, 8) == 0 ? "  " : " "))
    
    if (Mod(bin_file.Tell(), 16) == 0) {
      if (! isVerbose) {
        if (p_offset == SubStr(bin_out, 9))
          p_flag ? false : (printf("*"), p_flag := true)
        else
          p_flag := false
        
        p_offset := SubStr(bin_out, 9)
      }
      
      if (! p_flag)
        printf("{1} |{2}|", bin_out, hexToStr(bin_out))
      
      bin_out := Format("{:08x}  ", bin_file.Tell())
    }
  }
}
