#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 James Fisher
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# This code was taken from https://github.com/jameshfisher/nimrod-termcolor
## This module makes it easy to use ANSI escape sequences in terminal output.
## Expected usage is to call `write` or `echo` on the objects `ok`, `warning`,
## `error`, or `hint`.  The user may alternatively define her own style
## using `newAnsiStyle`.

type
  AnsiCode* = int
    ## We're giving this a type for clarity: we deal with integers below, but
    ## not all of them are ANSI codes.  (The AnsiColor type is an example).

proc write(code: AnsiCode) =
  ## Print an AnsiCode.  They are represented as decimal-formatted ASCII.
  write(cast[int](code))


## Printing a sequence of AnsiCodes
## --------------------------------

const
  CodeStart = "\27["
    ## These two characters begin an ANSI escape sequence.
    ## There is also a single-character sequence, \155.
    ## However, only the two-character sequence is recognized by
    ## devices that support just ASCII (7-bit bytes)
    ## or devices that support 8-bit bytes but use the
    ## 0x80–0x9F control character range for other purposes.

  CodeMiddle = ";"
    ## Signals another code is coming.

  CodeEnd = "m"
    ## The final byte is technically any character
    ## in the range 64 to 126.  'm' seems to be standard, though.

  InvalidCode: AnsiCode = 256
    ## Used to indicate that no code should be printed.

  Reset: AnsiCode = 0
    ## Resets all styles to their defaults.


proc writeGluedCodeSequence(f: File, codes: seq[AnsiCode]) =
  ## Given zero or more AnsiCodes `codes`, print them to `f`.
  ## They are printed using write(AnsiCode) defined above,
  ## and glued together with semicolons.

  for code in codes[0..^2]:  ## Don't append CODE_MIDDLE to the last
    if code != InvalidCode:
      write(f, code)
      write(f, CodeMiddle) ## Signal another AnsiCode is coming

  write(f, codes[^1])  ## Print the final code (no trailing semicolon)


proc writeCodeSequence(f: File, codes: seq[AnsiCode]) =
  ## Given zero or more AnsiCodes `codes`, activate them:
  ## signal a start of sequence, print the sequence, then end the sequence.

  write(f, CodeStart)  ## Begin the escape sequence.

  ## "Private mode characters" could come here,
  ## but we don't support them.

  writeGluedCodeSequence(f, codes)

  write(f, CodeEnd)    ## Terminate the escape sequence.


## ANSI-aware replacements for write() and echo()
## ----------------------------------------------

proc writeReset(f: File) =
  ## Reset output to whatever is defined to be normal
  writeCodeSequence(f, @[Reset])


proc writeANSI*[T](f: File, s: T, codes: seq[AnsiCode]) =
  ## Given `s` of writable type `T`, write it to `f`
  ## using the formatting in `codes`.

  writeCodeSequence(f, codes)  ## Specify the style with which to print `s`,
  write(f, s)                  ## write `s` in the normal fashion,
  writeReset(f)                ## then go back to default output.


proc echoANSI*[T](s: T, codes: seq[AnsiCode]) =
  ## In the same manner as the `write` vs. `echo` distinction,
  ## this does the same as `write` above, followed by a newline and flush.
  writeANSI(stdout, s, codes)
  echo("")  ## Make the normal `echo` do the hard work



################################################################################
##                          ANSI STYLE CLASSES                                ##
##----------------------------------------------------------------------------##


## Text color
## ----------

type
  TextColor* {.pure.} = enum  ## Add these to TEXT_COLOR_BASE or BG_COLOR_BASE.
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White

const
  TextColorBase = 30
    ## Add this to an COLOR to obtain a text-color code.

proc code(c: TextColor): AnsiCode = # {.noSideEffect.} 
  ## Obtain the code for text color of this color.
  return cast[AnsiCode](cast[int](c) + TEXT_COLOR_BASE)

proc default(c: TextColor): bool =
  return c == TextColor.Black


## Background color
## ----------------

type
  BackgroundColor* {.pure.} = enum  ## Add these to TEXT_COLOR_BASE or BG_COLOR_BASE.
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White

const
  BackgroundColorBase = 40
    ## Add this to an COLOR to obtain a background-color code.

proc code*(c: BackgroundColor): AnsiCode = # {.noSideEffect.} 
  ## Obtain the code for background color of this color.
  return cast[AnsiCode](cast[int](c) + BackgroundColorBase)

proc default(c: BackgroundColor): bool =
  return c == BackgroundColor.White

## Intensity
## ---------

## FEINT is not widely supported.

type
  Intensity* {.pure.} = enum Normal, Bold, Feint

proc code(c: Intensity): AnsiCode =
  case c
  of Intensity.Normal: return 22
  of Intensity.Bold: return 1
  of Intensity.Feint: return 2

proc default(c: Intensity): bool =
  return c == Intensity.Normal


## Inversion
## ---------

## Note: YES can also mean: swap FG and BG.

type
  Inversion* {.pure.} = enum No, Yes

proc code(c: Inversion): AnsiCode =
  case c
  of Inversion.No: return 27
  of Inversion.Yes: return 7

proc default(c: Inversion): bool =
  return c == Inversion.No


## Concealment
## -----------

## Not widely supported.

type
  Concealment* {.pure.} = enum No, Yes

proc code(c: Concealment): AnsiCode =
  case c
  of Concealment.No: return 28
  of Concealment.Yes: return 8

proc default(c: Concealment): bool =
  return c == Concealment.No


## Font style
## ----------

## Italic and Fraktur are not widely supported.

type
  FontStyle* {.pure.} = enum Default, Italic, Fraktur

proc code(c: FontStyle): AnsiCode =
  case c
  of FontStyle.Default: return 23
  of FontStyle.Italic: return 3
  of FontStyle.Fraktur: return 20

proc default(c: FontStyle): bool =
  return c == FontStyle.Default


## Font
## ----

## Select the nth alternate font.

type
  Font* {.pure.} = enum
    Primary,
    Alt1,
    Alt2,
    Alt3,
    Alt4,
    Alt5,
    Alt6,
    Alt7,
    Alt8,
    Alt9

proc code(c: Font): AnsiCode =
  return cast[AnsiCode](cast[int](c)+10)

proc default(c: Font): bool =
  return c == Font.Primary


## Underlining
## -----------

type
  Underline* {.pure.} = enum No, Yes

proc code(c: Underline): AnsiCode =
  case c 
  of Underline.No: return 24
  of Underline.Yes: return 4

proc default(c: Underline): bool =
  return c == Underline.No


## Overlining
## ----------

type
  Overline* {.pure.} = enum No, Yes

proc code(c: Overline): AnsiCode =
  case c
  of Overline.No: return 55
  of Overline.Yes: return 53

proc default(c: Overline): bool =
  return c == Overline.Yes


## Crossing out
## ------------

## Marked for deletion; NWS.

type
  CrossedOut* {.pure.} = enum No, Yes

proc code(c: CrossedOut): AnsiCode =
  case c
  of CrossedOut.No: return 29
  of CrossedOut.Yes: return 9

proc default(c: CrossedOut): bool =
  return c == CrossedOut.No


## Ideogram underlining
## --------------------

## Or on right side; NWS.

type
  IdeogramUnderline* {.pure.} = enum
    No,
    Single,
    Double

proc code(c: IdeogramUnderline): AnsiCode =
  case c
  of IdeogramUnderline.No:     return InvalidCode  ## ???
  of IdeogramUnderline.Single: return 60
  of IdeogramUnderline.Double: return 61

proc default(c: IdeogramUnderline): bool =
  return c == IdeogramUnderline.No


## Ideogram overlining
## -------------------

## Or on left side; NWS.

type
  IdeogramOverline* {.pure.} = enum
    No,
    Single,
    Double

proc code(c: IdeogramOverline): AnsiCode =
  case c
  of IdeogramOverline.No: return InvalidCode  ## ???
  of IdeogramOverline.Single: return 62
  of IdeogramOverline.Double: return 63

proc default(c: IdeogramOverline): bool =
  return c == IdeogramOverline.No


## Ideogram stress
## ---------------

## NWS.

type
  IdeogramStress* {.pure.} = enum No, Yes

proc code(c: IdeogramStress): AnsiCode =
  case c
  of IdeogramStress.No: return InvalidCode
  of IdeogramStress.Yes: return 64

proc default(c: IdeogramStress): bool =
  return c == IdeogramStress.No


## Blinking
## --------

## Slow is less than 150 per minute.
## Rapid is 150 per minute or more; NWS.

type
  Blinking* {.pure.} = enum No, Slow, Rapid

proc code(c: Blinking): AnsiCode =
  case c
  of Blinking.No: return 25
  of Blinking.Slow: return 5
  of Blinking.Rapid: return 6

proc default(c: Blinking): bool =
  return c == Blinking.No


## Framing
## -------

type
  Frame* {.pure.} = enum No, Yes, Encircle

proc code(c: Frame): AnsiCode =
  case c
  of Frame.No: return 54
  of Frame.Yes: return 51
  of Frame.Encircle: return 52

proc default(c: Frame): bool =
  return c == Frame.No


## Other ANSI style codes
## ----------------------

## Codes 26, 50, and 56-59 are reserved.
## 30-37 are text color codes.
## 40-47 are background color codes.

## 38 is 256-color text-color. Dubious?
## 48 is 256-color background-color. Dubious?  

## 90–99: set foreground color, high intensity	aixterm (not in standard)
## 100–109: set background color, high intensity	aixterm (not in standard)

## NWS: Not Widely Supported.

const
  DefaultTextColor*:         AnsiCode = 39  ## Implementation defined
  DefaultBackgroundColor*:   AnsiCode = 49  ## Implementation defined.
  BoldOff*:                   AnsiCode = 21  ## Or double underline; NWS.



################################################################################
##                  ENCAPSULATION OF ORTHOGONAL ANSI CLASSES                  ##
## ---------------------------------------------------------------------------##

type
  Style* = object
    # This class encapsulates all of the style classes above
    # into one style that can be given a semantic association;
    # e.g. red+bold+underlined may indicate a fatal error.
    textColor:          TextColor
    backgroundColor:    BackgroundColor
    intensity*:         Intensity
    inversion*:         Inversion
    concealment*:       Concealment
    fontStyle*:         FontStyle
    font*:              Font
    underline*:         Underline
    overline*:          Overline
    crossedOut*:        CrossedOut
    ideogramUnderline*: IdeogramUnderline
    ideogramOverline*:  IdeogramOverline
    ideogramStress*:    IdeogramStress
    blinking*:             Blinking
    frame*:             Frame


proc newStyle*(
      textColor:         TextColor         = TextColor.Black,
      backgroundColor:   BackgroundColor   = BackgroundColor.White,
      intensity:         Intensity         = Intensity.Normal,
      inversion:         Inversion         = Inversion.No,
      concealment:       Concealment       = Concealment.No,
      fontStyle:         FontStyle         = FontStyle.Default,
      font:              Font              = Font.Primary,
      underline:         Underline         = Underline.No,
      overline:          Overline          = Overline.No,
      crossedOut:        CrossedOut        = CrossedOut.No,
      ideogramUnderline: IdeogramUnderline = IdeogramUnderline.No,
      ideogramOverline:  IdeogramOverline  = IdeogramOverline.No,
      ideogramStress:    IdeogramStress    = IdeogramStress.No,
      blinking:          Blinking          = Blinking.No,
      frame:             Frame             = Frame.No): ref Style =
  # Create a new AnsiStyle object.
  new(result)
  result.textColor = textColor
  result.backgroundColor = backgroundColor
  result.intensity = intensity
  result.inversion = inversion
  result.concealment = concealment
  result.fontStyle = fontStyle
  result.font = font
  result.underline = underline
  result.overline = overline
  result.crossedOut = crossedOut
  result.ideogramUnderline = ideogramUnderline
  result.ideogramOverline = ideogramOverline
  result.ideogramStress = ideogramStress
  result.blinking = blinking
  result.frame = frame


proc getCodes(style: ref Style): seq[AnsiCode] =
  # Create a list of ANSI codes that will generate the desired effect.
  # If a style is the default, we don't omit it.
  result = @[]
  if not style.textColor.default:
    result.add(style.textColor.code)

  if not style.backgroundColor.default:
    result.add(style.backgroundColor.code)

  if not style.intensity.default:
    result.add(style.intensity.code)

  if not style.inversion.default:
    result.add(style.inversion.code)

  if not style.concealment.default:
    result.add(style.concealment.code)

  if not style.fontStyle.default:
    result.add(style.fontStyle.code)

  if not style.font.default:
    result.add(style.font.code)

  if not style.underline.default:
    result.add(style.underline.code)

  if not style.overline.default:
    result.add(style.overline.code)

  if not style.crossedOut.default:
    result.add(style.crossedOut.code)

  if not style.ideogramUnderline.default:
    result.add(style.ideogramUnderline.code)

  if not style.ideogramOverline.default:
    result.add(style.ideogramOverline.code)

  if not style.ideogramStress.default:
    result.add(style.ideogramStress.code)

  if not style.blinking.default:
    result.add(style.blinking.code)

  if not style.frame.default:
    result.add(style.frame.code)


proc write*[T](style: ref Style, f: File, s: T) =
  # The same as system's write(), but prepends the ANSI style
  # and appends a reset.
  writeANSI(f, s, getCodes(style))

proc colored*[T](style: ref Style, s: T) =
  # Analogous to system's echo().
  style.write(stdout, s)
  echo("") # echo("") fails???

################################################################################
##                             SOME USEFUL STYLES                             ##
## ---------------------------------------------------------------------------##

let
  Success* = newStyle(textColor = TextColor.Yellow)
  Warning* = newStyle(textColor = TextColor.Yellow, intensity = Intensity.Bold)
  Error* = newStyle(textColor = TextColor.Red, intensity = Intensity.Bold)
  Hint* = newStyle(textColor = TextColor.Cyan)
  Fatal* = newStyle(
    textColor = TextColor.Red, 
    intensity = Intensity.Bold, 
    underline = Underline.Yes,
  )