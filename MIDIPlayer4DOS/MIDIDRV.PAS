unit MIDIDRV;

interface
const
  mtGENERAL  = 0;
  mtEXTENDED = 1;
  mtBASIC    = 2;

{$L MIDI}

const
  SBlastBase: Word = $220;

  procedure MIDIInit( MIDIType: Word);
  procedure MIDIUnInit;

  procedure MIDISetPort( Port, Device: Word);
  procedure MIDIPlay( MIDI: Pointer );
  procedure MIDIStop;

  function  MIDIStatus: Word;

implementation


procedure MIDIInit( MIDIType: Word); external;
procedure MIDIUnInit; external;

procedure MIDISetPort( Port, Device: Word); external;
procedure MIDIPlay( MIDI: Pointer ); external;
procedure MIDIStop; external;

function  MIDIStatus: Word; external;

end.
