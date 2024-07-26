; Copyright 2024 Carl Georg Biermann

.ifndef ::SONG_ENGINE_SONG_DATA_ASM
::SONG_ENGINE_SONG_DATA_ASM = 1

.scope song_data

   change_song_tempo = timing::recalculate_rhythm_values ; TODO: actually recalculate ALL time stamps (lossy for sub-1/32 values)

   ; Assumes that a file is opened for writing.
   ; Dumps all the song data into the file.
   .proc saveSong
      rts
   .endproc

   ; Assumes that a file is opened for reading
   ; Loads all song data from the file
   .proc loadSong
      rts
   .endproc

.endscope

.endif ; .ifndef SONG_ENGINE_SONG_DATA_ASM